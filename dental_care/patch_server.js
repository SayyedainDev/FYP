const fs = require('fs');
let file = fs.readFileSync('../fy_dental_backend/server.js', 'utf8');

// Update pdfParse max options
file = file.replace(/const data = await pdfParse\(req.file.buffer\);/g, 'const data = await pdfParse(req.file.buffer, { max: 50 });');

// Update chunk sizes
file = file.replace(/const chunkSize = 800;/g, 'const chunkSize = 1200;\n    const chunkOverlap = 150;');

// Update chunk overlap logic
let overlapRegex = /const words = currentChunk\.split\(' '\);\s*const overlapWords = words\.slice\(-25\)\.join\(' '\); \/\/ roughly 100-150 chars overlap\s*currentChunk = overlapWords \+ ' ' \+ cleanP \+ ' ';/g;
file = file.replace(overlapRegex, `const overlapText = currentChunk.trim().slice(-chunkOverlap);\n          currentChunk = overlapText + ' ' + cleanP + ' ';`);

// Replace top 4 to top 5
file = file.replace(/const topChunks = chunks\.slice\(0, 4\);/g, 'const topChunks = chunks.slice(0, 5);');
file = file.replace(/Retrieved context length: \$\{contextText\.length\} characters \(k=4\)/g, 'Retrieved context length: ${contextText.length} characters (k=5)');

// Replace Groq call params
file = file.replace(/model: 'llama3-8b-8192', \/\/ Fast model/g, 'model: \'llama-3.1-8b-instant\', // Fastest available model');
file = file.replace(/max_tokens: 3000,/g, 'max_tokens: 2500,');

// Replace Groq call system prompt
let systemPromptOld = "'You are an expert quiz generator. Generate questions ONLY from the provided context. Return ONLY valid JSON that strictly matches the expected structure. No conversational filler or markdown code blocks around the JSON.'";
let systemPromptNew = "'You are an expert quiz generator. Generate questions ONLY from the provided context. Return ONLY valid JSON matching the exact requested structure. Return ONLY valid JSON, no markdown, no explanation outside JSON.'";
file = file.replace(systemPromptOld, systemPromptNew);

// Since we want to eliminate the exact 3000ms delay in Flutter, we will provide an endpoint /api/upload-status/:docId which handles chunks Count.
// Let's modify the indexing status logic. We already have background processing. We'll set a totalChunks field on knowledge_docs.
// Actually, earlier we couldn't insert document_docs easily. Let's do it using regex.
let backgroundRegex = /res\.status\(200\)\.json\(\{ message: 'PDF processed\. Embedding in background\.', documentId, chunksCount: chunks\.length \}\);\s*\/\/ --- Background Processing ---/;

let newBackground = `await db.collection('knowledge_docs').doc(documentId).set({ chunksCount: chunks.length, status: 'indexing' });

    res.status(200).json({ message: 'PDF processed. Embedding in background.', documentId, chunksCount: chunks.length });

    // --- Background Processing ---`;

file = file.replace(backgroundRegex, newBackground);

// Change background processing to set ready status
let embeddingDoneRegex = /console\.log\(\`✅ Fully embedded document \$\{documentId\}\`\);/g;
let embeddingDoneNew = `await db.collection('knowledge_docs').doc(documentId).update({ status: 'ready' });\n        console.log(\`✅ Fully embedded document \$\{documentId\}\`);`;
file = file.replace(embeddingDoneRegex, embeddingDoneNew);

// Also in /api/generate-rag-quiz wait properly
let snapshotWait = /let snapshot = await db\.collection\('knowledge_base'\)\.where\('documentId', '==', documentId\)\.get\(\);\s*\/\/ Wait for at least some chunks to be ready \(if background processing is still running\)\s*let retries = 0;\s*while \(snapshot\.empty && retries < 10\) \{\s*console\.log\('Chunks not found yet, waiting 1s\.\.\.'\);\s*await new Promise\(r => setTimeout\(r, 1000\)\);\s*snapshot = await db\.collection\('knowledge_base'\)\.where\('documentId', '==', documentId\)\.get\(\);\s*retries\+\+;\s*\}/;

let newSnapshotWait = `let docMeta = await db.collection('knowledge_docs').doc(documentId).get();
    let retries = 0;
    while ((!docMeta.exists || docMeta.data().status === 'indexing') && retries < 120) {
      console.log('Waiting for background indexing to complete...');
      await new Promise(r => setTimeout(r, 1000));
      docMeta = await db.collection('knowledge_docs').doc(documentId).get();
      retries++;
    }
    
    console.log('Indexing complete! fetching chunks...');
    let snapshot = await db.collection('knowledge_base').where('documentId', '==', documentId).get();`;

file = file.replace(snapshotWait, newSnapshotWait);

// Update status endpoint to read from knowledge_docs
let statusEndpoint = /app\.get\('\/api\/upload-status\/:docId', async \(req, res\) => \{\s*const \{ docId \} = req\.params;\s*const snapshot = await db\.collection\('knowledge_base'\)\.where\('documentId', '==', docId\)\.limit\(1\)\.get\(\);\s*if \(\!snapshot\.empty\) \{\s*return res\.status\(200\)\.json\(\{ status: 'ready' \}\);\s*\}\s*res\.status\(200\)\.json\(\{ status: 'processing' \}\);\s*\}\);/;

let newStatusEndpoint = `app.get('/api/upload-status/:docId', async (req, res) => {
  const { docId } = req.params;
  const docMeta = await db.collection('knowledge_docs').doc(docId).get();
  if (docMeta.exists && docMeta.data().status === 'ready') {
    return res.status(200).json({ status: 'ready' });
  }
  res.status(200).json({ status: 'processing' });
});`;

file = file.replace(statusEndpoint, newStatusEndpoint);


fs.writeFileSync('../fy_dental_backend/server.js', file, 'utf8');
console.log("Done patching server.js");
