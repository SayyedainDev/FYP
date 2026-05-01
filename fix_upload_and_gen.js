const fs = require('fs');

let content = fs.readFileSync('fy_dental_backend/server.js', 'utf-8');

// 1. Pagerender function and skip first 3 pages
content = content.replace(
  "const data = await pdfParse(req.file.buffer, { max: 50 });",
  `function render_page(pageData) {
        if (pageData.pageIndex < 3) return ''; 
        return pageData.getTextContent().then(function(textContent) {
            let lastY, text = '';
            for (let item of textContent.items) {
                if (lastY == item.transform[5] || !lastY) text += item.str;
                else text += '\\n' + item.str;
                lastY = item.transform[5];
            }
            return text;
        });
      }
      const data = await pdfParse(req.file.buffer, { max: 50, pagerender: render_page });`
);

// 2. Change chunk size and overlap
content = content.replace("const chunkSize = 1200;", "const chunkSize = 1500;");
content = content.replace("const chunkOverlap = 150;", "const chunkOverlap = 100;");

// 3. Make uploading synchronous (removing setImmediate and the early res.status)
const uploadPatternOriginal = `await db.collection('knowledge_docs').doc(documentId).set({ chunksCount: chunks.length, status: 'indexing' });

    res.status(200).json({ message: 'PDF processed. Embedding in background.', documentId, chunksCount: chunks.length });

    // --- Background Processing ---
    setImmediate(async () => {
      try {
        console.log(\`Generating embeddings for \${chunks.length} chunks in background...\`);
        const extractor = await getExtractor();
        const knowledgeBaseRef = db.collection('knowledge_base');

        const batchSize = 10;
        for (let i = 0; i < chunks.length; i += batchSize) {
          const batchChunks = chunks.slice(i, i + batchSize);
          const promises = batchChunks.map(async (chunk) => {
            const out = await extractor(chunk, { pooling: 'mean', normalize: true });
            const embedding = Array.from(out.data);
            await knowledgeBaseRef.add({
              documentId,
              text: chunk,
              embedding,
              uploadedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          });
          await Promise.all(promises);
          console.log(\`Processed batch \${Math.floor(i/batchSize) + 1} for \${documentId}\`);
        }
        await db.collection('knowledge_docs').doc(documentId).update({ status: 'ready' });
        console.log(\`✅ Fully embedded document \${documentId}\`);
      } catch (embErr) {
        console.error(\`❌ Background embedding failed for \${documentId}:\`, embErr);
      }
    });`;

const synchronousUpload = `console.log(\`Generating embeddings for \${chunks.length} chunks synchronously...\`);
    const extractor = await getExtractor();
    const knowledgeBaseRef = db.collection('knowledge_base');

    const batchSize = 10;
    for (let i = 0; i < chunks.length; i += batchSize) {
      const batchChunks = chunks.slice(i, i + batchSize);
      const promises = batchChunks.map(async (chunk) => {
        const out = await extractor(chunk, { pooling: 'mean', normalize: true });
        const embedding = Array.from(out.data);
        await knowledgeBaseRef.add({
          documentId,
          text: chunk,
          embedding,
          uploadedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      await Promise.all(promises);
      console.log(\`Processed batch \${Math.floor(i/batchSize) + 1} for \${documentId}\`);
    }
    
    // Set to ready immediately
    await db.collection('knowledge_docs').doc(documentId).set({ status: 'ready', chunksCount: chunks.length });
    console.log(\`✅ Fully embedded document \${documentId}\`);
    
    res.status(200).json({ message: 'PDF processed and embedded.', documentId, chunksCount: chunks.length });`;

content = content.replace(uploadPatternOriginal, synchronousUpload);

// 4. Remove wait loops in generate-rag-quiz 
const generateWaitOriginal = `let docMeta = await db.collection('knowledge_docs').doc(documentId).get();
    let retries = 0;
    while ((!docMeta.exists || docMeta.data().status === 'indexing') && retries < 120) {
      console.log('Waiting for background indexing to complete...');
      await new Promise(r => setTimeout(r, 1000));
      docMeta = await db.collection('knowledge_docs').doc(documentId).get();
      retries++;
    }
    
    console.log('Indexing complete! fetching chunks...');`;

const generateWaitNew = `console.log('Fetching chunks...');`;

content = content.replace(generateWaitOriginal, generateWaitNew);

// 5. Add TOC Filter
const checkChunksOriginal = `const chunks = [];
    snapshot.forEach(doc => {
      chunks.push(doc.data());
    });

    // 3. Compute cosine similarity`;

const addTOCFilter = `let chunks = [];
    snapshot.forEach(doc => {
      chunks.push(doc.data());
    });
    
    // --- TOC FILTERING (PROBLEM 1) ---
    function filterOutTOCChunks(chunksArray) {
      return chunksArray.filter(chunk => {
        const cT = chunk.text || '';
        // Contains more than 5 occurrences of "page"
        const pageCount = (cT.match(/page/gi) || []).length;
        if (pageCount > 5) return false;
        
        // Dot leaders or Chapter headers 
        if (/\\.([^\\w]){3,}/.test(cT) || /\\.{3,}/.test(cT)) return false;
        if (/Chapter\\s+\\d+\\.+/i.test(cT)) return false;
        
        // Lines that are just "Title .... Page Number"
        const lines = cT.split('\\n');
        let tocLines = 0;
        for (let l of lines) {
           if (/.*?\\s+\\d+$/.test(l.trim()) && l.trim().length < 60) tocLines++;
        }
        if (tocLines > 3) return false;
        
        // Mostly numbers / short titles (< 200 chars valid content)
        if (cT.length < 200) return false;
        return true;
      });
    }
    
    const originalCount = chunks.length;
    chunks = filterOutTOCChunks(chunks);
    console.log(\`Filtered out \${originalCount - chunks.length} TOC/Noise chunks.\`);

    // 3. Compute cosine similarity`;

content = content.replace(checkChunksOriginal, addTOCFilter);

// 6. Update k=4
content = content.replace(
  "const topChunks = chunks.slice(0, 5);",
  "const topChunks = chunks.slice(0, 4);"
);
content = content.replace(
  "(k=5)",
  "(k=4)"
);

// 7. Update Groq limits
content = content.replace(
  "max_tokens: 2500,",
  "max_tokens: 2000,"
);
content = content.replace(
  "temperature: 0.3,",
  "temperature: 0.2,"
);

// 8. Add Strict System Prompt
const oldSystemStr = "You are an expert quiz generator. Generate questions ONLY from the provided context. Return ONLY valid JSON matching the exact requested structure. Return ONLY valid JSON, no markdown, no explanation outside JSON.";
const newSystemStr = oldSystemStr + " CRITICAL RULES - You must follow these without exception:\\n- Do NOT generate questions about page numbers, chapter numbers, or table of contents\\n- Do NOT ask 'What is on page X?' or 'What chapter is Y?'\\n- Do NOT reference any page numbers or chapter numbers in your questions\\n- ONLY generate questions about actual concepts, facts, definitions, techniques, processes, or knowledge from the content\\n- Every question must test understanding of a concept, not memory of a location\\n- If the context only contains table of contents or index, say ERROR:TOC_ONLY and do not generate questions";
content = content.replace(oldSystemStr, newSystemStr);

// 9. Add Verification of Quiz output
const oldFinalResponse = `res.status(200).json(JSON.parse(jsonStr));`;
const newFinalResponse = `let parsed = JSON.parse(jsonStr);
    if (parsed.questions) {
      const initQ = parsed.questions.length;
      parsed.questions = parsed.questions.filter(q => {
         const txt = ((q.question || '') + ' ' + (q.questionText || '')).toLowerCase();
         if (txt.includes('page NUMBER') || txt.includes('chapter number') || txt.includes('what is on page') || txt.match(/page \\d+/)) {
            return false;
         }
         return true;
      });
      if (parsed.questions.length < initQ) {
         console.warn(\`⚠️ Filtered \${initQ - parsed.questions.length} invalid TOC questions during validation.\`);
      }
    }
    res.status(200).json(parsed);`;
content = content.replace(oldFinalResponse, newFinalResponse);


fs.writeFileSync('fy_dental_backend/server.js', content, 'utf-8');
console.log('Backend edits applied successfully!');
