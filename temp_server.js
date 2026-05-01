require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const axios = require('axios');
const multer = require('multer');
const pdfParse = require('pdf-parse');

const upload = multer({ storage: multer.memoryStorage() });

let extractorPipeline = null;
async function getExtractor() {
  if (!extractorPipeline) {
    const { pipeline, env } = await import('@xenova/transformers');
    env.localModelPath = './models';
    env.allowLocalModels = true;
    extractorPipeline = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');
  }
  return extractorPipeline;
}

// Initialize Express App
const app = express();

// Pre-load embedding model to avoid cold-start penalty on first request
getExtractor().then(() => console.log("Embedding model pre-loaded")).catch(console.error);

app.use(cors({ origin: true }));

// Health Check Endpoint for Keep-Alive
app.get("/health", (req, res) => res.status(200).json({ status: "ok" }));

app.use(express.json());

// Initialize Firebase Admin SDK
// Render allows adding a base64 or JSON environment variable for credentials.
// For local testing, we look for a serviceAccountKey.json, or process.env.FIREBASE_SERVICE_ACCOUNT
try {
  let cert;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    cert = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    // Fallback to local file for development
    cert = require('./serviceAccountKey.json');
  }

  admin.initializeApp({
    credential: admin.credential.cert(cert),
  });
  console.log('✅ Firebase Admin Initialized Successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error.message);
  console.log('Make sure FIREBASE_SERVICE_ACCOUNT env variable is set or serviceAccountKey.json exists.');
}

const db = admin.firestore();

// Health Check Endpoint
app.get('/', (req, res) => {
  res.send('Dental Quiz API is running securely!');
});

// ============================================================
// 1. POST /api/grade-attempt
//    Grades the attempt securely on the server.
// ============================================================
app.post('/api/grade-attempt', async (req, res) => {
  const { attemptId } = req.body;

  if (!attemptId) {
    return res.status(400).json({ error: 'attemptId is required' });
  }

  try {
    const attemptRef = db.collection('attempts').doc(attemptId);
    const attemptDoc = await attemptRef.get();

    if (!attemptDoc.exists) {
      return res.status(404).json({ error: 'Attempt not found' });
    }

    const attemptData = attemptDoc.data();

    // Idempotent check
    if (attemptData.gradedAt) {
      return res.status(200).json({ message: 'Already graded', attempt: attemptData });
    }

    const quizId = attemptData.quizId;
    const quizDoc = await db.collection('quizzes').doc(quizId).get();

    if (!quizDoc.exists) {
      return res.status(404).json({ error: 'Quiz not found' });
    }

    const quizData = quizDoc.data();
    const questions = quizData.questions || [];

    // Map questions for quick lookup
    const questionMap = {};
    for (const q of questions) {
      questionMap[q.id] = q;
    }

    const responses = attemptData.responses || [];
    const gradedResponses = [];
    let score = 0;
    let totalMarks = 0;

    for (const response of responses) {
      const question = questionMap[response.questionId];
      if (!question) {
        gradedResponses.push({
          ...response,
          isCorrect: false,
          correctAnswer: null,
        });
        continue;
      }

      const isCorrect = response.selectedOption === question.correctIndex;
      const marks = question.marks || 1;
      totalMarks += marks;

      if (isCorrect) {
        score += marks;
      }

      gradedResponses.push({
        ...response,
        isCorrect,
        correctAnswer: question.options ? question.options[question.correctIndex] : null,
      });
    }

    const percentage = totalMarks > 0 ? Math.round((score / totalMarks) * 100) : 0;

    const updateData = {
      score,
      totalMarks,
      percentage,
      isPassed: percentage >= 60,
      gradedAt: admin.firestore.FieldValue.serverTimestamp(),
      responses: gradedResponses,
      status: 'graded',
      isSubmitted: true // ensure it's marked as submitted
    };

    await attemptRef.update(updateData);

    console.log(`✅ Graded attempt ${attemptId}: ${score}/${totalMarks} (${percentage}%)`);
    res.status(200).json({ message: 'Successfully graded', result: updateData });

  } catch (error) {
    console.error(`❌ Error grading attempt ${attemptId}:`, error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================
// 2. POST /api/record-violation
// ============================================================
app.post('/api/record-violation', async (req, res) => {
  const { attemptId, violationType, timestamp, metadata, uid } = req.body;

  if (!attemptId || !violationType || !uid) {
    return res.status(400).json({ error: 'attemptId, violationType, and uid are required' });
  }

  const validTypes = ['tab_switch', 'fullscreen_exit', 'right_click', 'copy_attempt', 'inactivity'];
  if (!validTypes.includes(violationType)) {
    return res.status(400).json({ error: `Invalid violation type. Must be one of: ${validTypes.join(', ')}` });
  }

  try {
    const attemptRef = db.collection('attempts').doc(attemptId);
    const attemptDoc = await attemptRef.get();

    if (!attemptDoc.exists) {
      return res.status(404).json({ error: 'Attempt not found' });
    }

    const attemptData = attemptDoc.data();

    if (attemptData.studentId !== uid) {
      return res.status(403).json({ error: 'Permission denied: Not your attempt' });
    }

    if (attemptData.isSubmitted === true) {
      return res.status(200).json({ shouldAutoSubmit: false, violationCount: 0, warning: 'Attempt already submitted' });
    }

    const update = {};
    let counterField;
    switch (violationType) {
      case 'tab_switch': counterField = 'tabSwitchCount'; break;
      case 'fullscreen_exit': counterField = 'fullscreenExitCount'; break;
      case 'inactivity': counterField = 'inactivityCount'; break;
      default: counterField = 'otherViolationCount';
    }

    const currentCount = (attemptData[counterField] || 0) + 1;
    update[counterField] = currentCount;

    update.violationLog = admin.firestore.FieldValue.arrayUnion({
      type: violationType,
      timestamp: timestamp || new Date().toISOString(),
      metadata: metadata || {},
      recordedAt: new Date().toISOString(),
    });

    const tabCount = violationType === 'tab_switch' ? currentCount : (attemptData.tabSwitchCount || 0);
    const fsCount = violationType === 'fullscreen_exit' ? currentCount : (attemptData.fullscreenExitCount || 0);
    const shouldAutoSubmit = tabCount >= 3 || fsCount >= 3;

    if (shouldAutoSubmit) {
      update.autoSubmitTriggered = true;
      update.isSubmitted = true;
      update.endTime = admin.firestore.FieldValue.serverTimestamp();
      console.log(`⚠️ Auto-submit triggered for ${attemptId}`);
    }

    await attemptRef.update(update);

    let warning = '';
    if (violationType === 'tab_switch') {
      warning = `Tab switch recorded (${currentCount}/3). `;
      if (currentCount >= 2 && !shouldAutoSubmit) warning += 'One more will auto-submit your quiz!';
    } else if (violationType === 'fullscreen_exit') {
      warning = `Fullscreen exit recorded (${currentCount}/3).`;
    }

    res.status(200).json({
      shouldAutoSubmit,
      violationCount: currentCount,
      warning,
    });
  } catch (error) {
    console.error('❌ Error recording violation:', error);
    res.status(500).json({ error: 'Failed to record violation' });
  }
});

// ============================================================
// 3. POST /api/generate-questions
// ============================================================
app.post('/api/generate-questions', async (req, res) => {
  let { sourceText, questionCount, difficulty, topic, cognitiveLevel, uid } = req.body;

  if (!uid) {
    return res.status(401).json({ error: 'You must be logged in (provide uid)' });
  }

  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User profile not found' });
    }
    const role = (userDoc.data().role || '').toLowerCase();
    if (role !== 'dentist' && role !== 'professor') {
      return res.status(403).json({ error: 'Only professors/dentists can generate quiz questions' });
    }
  } catch (error) {
    console.error('Error checking user role:', error);
    return res.status(500).json({ error: 'Failed to verify user role' });
  }

  if (!sourceText || sourceText.length < 50) {
    return res.status(400).json({ error: 'Source text must be at least 50 characters' });
  }

  if (sourceText.length > 32000) {
    sourceText = sourceText.substring(0, 32000);
  }

  questionCount = questionCount || 10;
  difficulty = difficulty || 'medium';
  topic = topic || 'Dental Education';

  const prompt = buildPrompt(sourceText, questionCount, difficulty, topic, cognitiveLevel);
  const apiKey = process.env.GROQ_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'Groq API key not configured on server (.env)' });
  }

  let responseContent;
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      console.log(`Calling Groq API (attempt ${attempt + 1}/2)...`);
      const response = await axios.post(
        'https://api.groq.com/openai/v1/chat/completions',
        {
          model: 'llama-3.3-70b-versatile',
          messages: [
            {
              role: 'system',
              content: 'You are an expert dental education professor creating MCQ exam questions. Generate high-quality questions in valid JSON format. Always respond ONLY with a valid JSON array, no markdown, no explanation.'
            },
            { role: 'user', content: prompt },
          ],
          max_tokens: 2000,
          temperature: 0.7,
        },
        {
          headers: { Authorization: `Bearer ${apiKey}` },
          timeout: 30000,
        }
      );

      responseContent = response.data.choices[0].message.content;
      break;
    } catch (error) {
      console.error(`Groq API attempt ${attempt + 1} failed:`, error.message);
      if (attempt === 1) {
        const status = error.response?.status;
        if (status === 429) return res.status(429).json({ error: 'Groq API rate limit exceeded.' });
        if (status === 401) return res.status(401).json({ error: 'Invalid Groq API key configured on server.' });
        return res.status(500).json({ error: `Failed to generate questions: ${error.message}` });
      }
      await new Promise(r => setTimeout(r, 1000));
    }
  }

  try {
    let jsonStr = responseContent.trim();
    if (jsonStr.includes('```')) {
      jsonStr = jsonStr.replace(/```\w*\n?/g, '');
      jsonStr = jsonStr.replace(/\n?```/g, '');
      jsonStr = jsonStr.trim();
    }
    const startIdx = jsonStr.indexOf('[');
    const endIdx = jsonStr.lastIndexOf(']');
    if (startIdx >= 0 && endIdx > startIdx) {
      jsonStr = jsonStr.substring(startIdx, endIdx + 1);
    }

    const questions = JSON.parse(jsonStr);
    const validated = questions.map((q, i) => {
      const options = Array.isArray(q.options) ? q.options : [];
      while (options.length < 4) options.push(`Option ${options.length + 1}`);
      if (options.length > 4) options.length = 4;
      return {
        questionText: q.questionText || `Question ${i + 1}`,
        options,
        correctIndex: Math.min(Math.max(parseInt(q.correctIndex) || 0, 0), 3),
        explanation: q.explanation || '',
        difficulty: q.difficulty || difficulty,
      };
    });

    console.log(`✅ Generated and validated ${validated.length} questions`);
    res.status(200).json({ questions: validated });
  } catch (parseError) {
    console.error('Failed to parse Groq response:', parseError);
    res.status(500).json({ error: 'Failed to parse AI response. Please try again.' });
  }
});

function buildPrompt(sourceText, questionCount, difficulty, topic, cognitiveLevel) {
  const difficultyDesc = {
    easy: 'Easy - basic recall',
    medium: 'Medium - understanding',
    hard: 'Hard - synthesis',
  }[difficulty] || difficulty;
  const cognitiveDesc = cognitiveLevel ? `Cognitive Level: ${cognitiveLevel}` : '';

  return `Generate exactly ${questionCount} multiple-choice questions based on the following dental/medical content.
Requirements:
- Difficulty: ${difficultyDesc}
${cognitiveDesc ? `- ${cognitiveDesc}` : ''}
- Topic: ${topic}
- Each question must have exactly 4 options
- correctIndex must be 0, 1, 2, or 3
- Include a brief explanation for each correct answer
STRICT JSON RULES:
- Respond ONLY with a valid JSON array, no markdown
- Each object: { "questionText", "options" (array of 4), "correctIndex" (0-3), "explanation", "difficulty" }
SOURCE CONTENT:
${sourceText}`;
}



// ============================================================
// 4. POST /api/upload-pdf (RAG Ingestion)
// ============================================================
app.post('/api/upload-pdf', upload.single('file'), async (req, res) => {
  try {
    let text = '';
    if (req.file) {
      console.log('Extracting text from PDF...');
      function render_page(pageData) {
        if (pageData.pageIndex < 3) return ''; 
        return pageData.getTextContent().then(function(textContent) {
            let lastY, text = '';
            for (let item of textContent.items) {
                if (lastY == item.transform[5] || !lastY) text += item.str;
                else text += '\n' + item.str;
                lastY = item.transform[5];
            }
            return text;
        });
      }
      const data = await pdfParse(req.file.buffer, { max: 50, pagerender: render_page });
      text = data.text;
    } else if (req.body.text) {
      console.log('Using provided raw text for RAG...');
      text = req.body.text;
    } else {
      return res.status(400).json({ error: 'No PDF file or text provided' });
    }

    console.log('Cleaning and chunking text...');
    // Basic text cleanup: remove standalone numbers, excessive newlines, form feeds
    text = text.replace(/\r\n/g, '\n').replace(/\n\s*\d+\s*\n/g, '\n').replace(/\f/g, '');

    // Chunking parameters based on requirements:
    const chunkSize = 1500;
    const chunkOverlap = 100;
    const Math = global.Math; // Ensure Math is available
    const chunks = [];

    // Split into paragraphs first, then chunk if too big, or group if too small
    const paragraphs = text.split(/\n\s*\n/);
    let currentChunk = '';

    for (const p of paragraphs) {
      const cleanP = p.trim();
      if (!cleanP) continue;

      if (currentChunk.length + cleanP.length > chunkSize) {
        if (currentChunk) {
          chunks.push(currentChunk.trim());
          // Create overlap dynamically by keeping the last 100-200 chars of the previous chunk
          const overlapText = currentChunk.trim().slice(-chunkOverlap);
          currentChunk = overlapText + ' ' + cleanP + ' ';
        } else {
          chunks.push(cleanP.substring(0, chunkSize));
          currentChunk = cleanP.substring(chunkSize);
        }
      } else {
        currentChunk += cleanP + '\n\n';
      }
    }
    if (currentChunk.trim()) {
      chunks.push(currentChunk.trim());
    }

    const documentId = req.body.documentId || `doc_${Date.now()}`;
    console.log(`Generated ${chunks.length} chunks. Ready for background embedding...`);

    // Return early to the client so UI doesn't freeze waiting for Xenova
    console.log(`Generating embeddings for ${chunks.length} chunks synchronously...`);
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
      console.log(`Processed batch ${Math.floor(i/batchSize) + 1} for ${documentId}`);
    }
    
    // Set to ready immediately
    await db.collection('knowledge_docs').doc(documentId).set({ status: 'ready', chunksCount: chunks.length });
    console.log(`✅ Fully embedded document ${documentId}`);
    
    res.status(200).json({ message: 'PDF processed and embedded.', documentId, chunksCount: chunks.length });

  } catch (err) {
    console.error('Error processing PDF:', err);
    res.status(500).json({ error: 'Failed to process PDF' });
  }
});

// Cosine Similarity Utility
function cosineSimilarity(vecA, vecB) {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < vecA.length; i++) {
    dotProduct += vecA[i] * vecB[i];
    normA += vecA[i] * vecA[i];
    normB += vecB[i] * vecB[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// ============================================================
// 5. POST /api/generate-rag-quiz
// ============================================================
app.post('/api/generate-rag-quiz', async (req, res) => {
  let { topic, documentId, questionCount, difficulty, cognitiveLevel, questionTypes, quizMode, explanationStyle, uid } = req.body;

  if (!documentId || !uid) {
    return res.status(400).json({ error: 'documentId and uid are required' });
  }

  try {
    topic = topic || 'General Topic';
    // 1. Embed the topic Query
    console.log(`Generating embedding for topic: ${topic}`);
    const extractor = await getExtractor();
    const queryOut = await extractor(topic, { pooling: 'mean', normalize: true });
    const queryEmbedding = Array.from(queryOut.data);

    // 2. Fetch chunks for the document
    console.log(`Fetching chunks for document: ${documentId}`);
    console.log('Fetching chunks...');
    let snapshot = await db.collection('knowledge_base').where('documentId', '==', documentId).get();

    if (snapshot.empty) {
      return res.status(404).json({ error: 'No knowledge base found for this documentId. Please upload first.' });
    }

    let chunks = [];
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
        if (/\.([^\w]){3,}/.test(cT) || /\.{3,}/.test(cT)) return false;
        if (/Chapter\s+\d+\.+/i.test(cT)) return false;
        
        // Lines that are just "Title .... Page Number"
        const lines = cT.split('\n');
        let tocLines = 0;
        for (let l of lines) {
           if (/.*?\s+\d+$/.test(l.trim()) && l.trim().length < 60) tocLines++;
        }
        if (tocLines > 3) return false;
        
        // Mostly numbers / short titles (< 200 chars valid content)
        if (cT.length < 200) return false;
        return true;
      });
    }
    
    const originalCount = chunks.length;
    chunks = filterOutTOCChunks(chunks);
    console.log(`Filtered out ${originalCount - chunks.length} TOC/Noise chunks.`);

    // 3. Compute cosine similarity
    for (const chunk of chunks) {
      if (chunk.embedding && chunk.embedding.length > 0) {
        chunk.score = cosineSimilarity(queryEmbedding, chunk.embedding);
      } else {
        chunk.score = -1;
      }
    }

    // Sort descending by score
    chunks.sort((a, b) => b.score - a.score);

    // 4. Retrieve strictly top 4 chunks (k=4)
    const topChunks = chunks.slice(0, 4);
    const contextText = topChunks.map(c => c.text).join('\n\n');
    console.log(`Retrieved context length: ${contextText.length} characters (k=4)`);

    questionCount = questionCount || 5;
    difficulty = difficulty || 'medium';

    const prompt = buildRAGPrompt(contextText, {
       questionCount, difficulty, topic, cognitiveLevel, questionTypes, quizMode, explanationStyle
    });

    const apiKey = process.env.GROQ_API_KEY;

    let responseContent;
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        console.log(`Calling Groq API (llama3-8b-8192) for RAG (attempt ${attempt + 1}/2)...`);
        const response = await axios.post(
          'https://api.groq.com/openai/v1/chat/completions',
          {
            model: 'llama-3.1-8b-instant', // Fastest available model
            messages: [
              {
                role: 'system',
                content: 'You are an expert quiz generator. Generate questions ONLY from the provided context. Return ONLY valid JSON matching the exact requested structure. Return ONLY valid JSON, no markdown, no explanation outside JSON. CRITICAL RULES - You must follow these without exception:\n- Do NOT generate questions about page numbers, chapter numbers, or table of contents\n- Do NOT ask "What is on page X?" or "What chapter is Y?"\n- Do NOT reference any page numbers or chapter numbers in your questions\n- ONLY generate questions about actual concepts, facts, definitions, techniques, processes, or knowledge from the content\n- Every question must test understanding of a concept, not memory of a location\n- If the context only contains table of contents or index, say ERROR:TOC_ONLY and do not generate questions'
              },
              { role: 'user', content: prompt },
            ],
            max_tokens: 2000,
            temperature: 0.2, // Consistent output
            response_format: { type: 'json_object' } // Groq JSON mode
          },
          {
            headers: { Authorization: `Bearer ${apiKey}` },
            timeout: 30000,
          }
        );

        responseContent = response.data.choices[0].message.content;
        break; // Success
      } catch (error) {
        const errorMsg = error.response ? JSON.stringify(error.response.data) : error.message;
        console.error(`Groq API attempt ${attempt + 1} failed: ${errorMsg}`);
        if (attempt === 1) throw new Error('Groq API failed');
        await new Promise(r => setTimeout(r, 1000));
      }
    }

    let jsonStr = responseContent.trim();
    if (jsonStr.startsWith('```json')) jsonStr = jsonStr.substring(7);
    if (jsonStr.endsWith('```')) jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    jsonStr = jsonStr.trim();

    let quizData;
    try {
      quizData = JSON.parse(jsonStr);
    } catch (e) {
      console.error("Failed to parse JSON:", jsonStr);
      throw new Error("Invalid format from LLM");
    }

    // Default to the original frontend expected structure if they didn't implement full JSON parsing:
    // The frontend currently expects { questions: [ Question ] }
    const questionsArray = Array.isArray(quizData.questions) ? quizData.questions : (Array.isArray(quizData) ? quizData : Object.values(quizData));

    // Map to frontend structure precisely to not break the app
    const validatedQuestions = questionsArray.map((q, i) => {
      const options = Array.isArray(q.options) && q.options.length === 4 ? q.options : ["A", "B", "C", "D"];
      let cIdx = typeof q.correctIndex === 'number' ? q.correctIndex : 0;
      if (typeof q.correct_answer === 'string') {
        const letterToIndex = { "A": 0, "B": 1, "C": 2, "D": 3 };
        cIdx = letterToIndex[q.correct_answer] ?? 0;
      }
      return {
        questionText: q.question || q.questionText || `Question ${i+1}`,
        options: options,
        correctIndex: Math.min(Math.max(cIdx, 0), 3),
        explanation: q.explanation || q.hint || '',
        difficulty: q.difficulty || difficulty,
        // new fields to support the requirements
        topic: q.topic || topic,
        type: q.type || 'MCQ',
      };
    });

    res.status(200).json({
      questions: validatedQuestions,
      documentId,
      contextUsedPreview: contextText.substring(0, 150) + '...'
    });

  } catch (err) {
    console.error('RAG Generation Error:', err);
    res.status(500).json({ error: 'Failed to generate quiz using RAG' });
  }
});

function buildRAGPrompt(contextText, config) {
  const { questionCount, difficulty, topic, cognitiveLevel, questionTypes, quizMode, explanationStyle } = config;
  const qTypesStr = questionTypes ? JSON.stringify(questionTypes) : '["MCQ"]';

  return `Extract educationally important content (key definitions, core concepts, clinical applications) from the context provided below. IGNORE page numbers, references, header/footers, and filler text. Use this filtered content to generate exactly ${questionCount} varied questions.

QUIZ CONFIGURATION:
- Topic: ${topic}
- Difficulty: ${difficulty}
- Cognitive Level: ${cognitiveLevel || 'mixed'}
- Allowed Question Types: ${qTypesStr}
- Quiz Mode: ${quizMode || 'practice'}
- Explanation Style: ${explanationStyle || 'brief'}

RULES for GENERATION:
1. ONLY use the provided context. DO NOT make up answers using outside knowledge.
2. Distribute questions across different topics mentioned in the context. NO repetitive questions.
3. Every question must have an ID and Topic.
4. For MCQs (if allowed), provide exactly 4 options and the correctOption index (0-3).
5. If Practice Mode, provide a concise "hint".

OUTPUT FORMAT (STRICT JSON):
{
  "quiz_title": "Quiz Title Here",
  "difficulty": "${difficulty}",
  "total_questions": ${questionCount},
  "questions": [
    {
      "id": 1,
      "type": "MCQ",
      "topic": "${topic}",
      "question": "Question text here",
      "hint": "Hint if applicable",
      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
      "correctIndex": 0,
      "explanation": "Detailed explanation based on the text."
    }
  ]
}

CONTEXT TO USE:
${contextText}`;
}

app.get('/api/upload-status/:docId', async (req, res) => {
  const { docId } = req.params;
  const docMeta = await db.collection('knowledge_docs').doc(docId).get();
  if (docMeta.exists && docMeta.data().status === 'ready') {
    return res.status(200).json({ status: 'ready' });
  }
  res.status(200).json({ status: 'processing' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
