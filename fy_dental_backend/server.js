require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const axios = require('axios');
const multer = require('multer');

// ============================================================
// Configuration
// ============================================================
const PORT = process.env.PORT || 5000;
const upload = multer({ storage: multer.memoryStorage() });

// ============================================================
// Initialize Express App
// ============================================================
const app = express();

app.use(cors({ origin: true }));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// ============================================================
// Initialize Firebase Admin SDK
// ============================================================
try {
  let cert;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // For Render: provide as base64 or JSON string
    const accountStr = process.env.FIREBASE_SERVICE_ACCOUNT;
    try {
      // Try parsing as JSON first
      cert = JSON.parse(accountStr);
    } catch (_) {
      // If it's base64, decode it
      cert = JSON.parse(Buffer.from(accountStr, 'base64').toString());
    }
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
  console.error('Make sure FIREBASE_SERVICE_ACCOUNT env variable is set or serviceAccountKey.json exists.');
  process.exit(1);
}

const db = admin.firestore();

// ============================================================
// Health Check Endpoints
// ============================================================
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/', (req, res) => {
  res.status(200).json({ message: 'Dental Care Quiz API is running!' });
});

// ============================================================
// POST /api/record-violation
// Records quiz proctoring violations (tab switches, fullscreen exits, inactivity)
// ============================================================
app.post('/api/record-violation', async (req, res) => {
  const { attemptId, violationType, timestamp, uid } = req.body;

  if (!attemptId || !violationType || !uid) {
    return res.status(400).json({
      error: 'attemptId, violationType, and uid are required',
      statusCode: 400,
    });
  }

  const validTypes = ['tab_switch', 'fullscreen_exit', 'right_click', 'inactivity', 'other'];
  if (!validTypes.includes(violationType)) {
    return res.status(400).json({
      error: `Invalid violation type. Must be one of: ${validTypes.join(', ')}`,
      statusCode: 400,
    });
  }

  try {
    const attemptRef = db.collection('attempts').doc(attemptId);
    const attemptDoc = await attemptRef.get();

    if (!attemptDoc.exists) {
      return res.status(404).json({
        error: 'Attempt not found',
        statusCode: 404,
      });
    }

    const attemptData = attemptDoc.data();

    // Verify ownership
    if (attemptData.studentId !== uid) {
      return res.status(403).json({
        error: 'Permission denied: Not your attempt',
        statusCode: 403,
      });
    }

    // Already submitted, skip recording
    if (attemptData.isSubmitted === true) {
      return res.status(200).json({
        shouldAutoSubmit: false,
        violationCount: 0,
        warning: 'Attempt already submitted',
      });
    }

    // Determine counter field
    let counterField;
    switch (violationType) {
      case 'tab_switch':
        counterField = 'tabSwitchCount';
        break;
      case 'fullscreen_exit':
        counterField = 'fullscreenExitCount';
        break;
      case 'inactivity':
        counterField = 'inactivityCount';
        break;
      default:
        counterField = 'otherViolationCount';
    }

    const currentCount = (attemptData[counterField] || 0) + 1;
    const update = {
      [counterField]: currentCount,
      violationLog: admin.firestore.FieldValue.arrayUnion({
        type: violationType,
        timestamp: timestamp || new Date().toISOString(),
        recordedAt: new Date().toISOString(),
      }),
    };

    // Check auto-submit thresholds
    const tabCount =
      violationType === 'tab_switch' ? currentCount : (attemptData.tabSwitchCount || 0);
    const fsCount =
      violationType === 'fullscreen_exit'
        ? currentCount
        : (attemptData.fullscreenExitCount || 0);
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
      if (currentCount >= 2 && !shouldAutoSubmit) {
        warning += 'One more will auto-submit your quiz!';
      }
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
    res.status(500).json({
      error: 'Failed to record violation',
      details: error.message,
    });
  }
});

// ============================================================
// POST /api/upload-pdf
// Uploads PDF files for RAG / document processing
// ============================================================
app.post('/api/upload-pdf', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      error: 'No file provided',
      statusCode: 400,
    });
  }

  const file = req.file;
  const maxSize = 10 * 1024 * 1024; // 10 MB

  if (file.size > maxSize) {
    return res.status(413).json({
      error: 'File too large. Maximum size is 10MB.',
      statusCode: 413,
    });
  }

  try {
    // For now, store file metadata and generate a document ID
    // In a real implementation, you might upload to cloud storage (GCS, S3, etc.)
    const documentId = `doc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Log file upload (optional: save metadata to Firestore)
    console.log(`📄 PDF uploaded: ${file.originalname} (${file.size} bytes) -> ${documentId}`);

    // Store metadata in Firestore for later retrieval
    try {
      await db.collection('documents').doc(documentId).set({
        filename: file.originalname,
        size: file.size,
        mimeType: file.mimetype,
        uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
        buffer: file.buffer.toString('base64'), // Store as base64 for now
      });
    } catch (dbError) {
      console.warn('⚠️ Could not store PDF metadata in Firestore:', dbError.message);
      // Continue anyway, return documentId with warning
    }

    res.status(200).json({
      documentId,
      filename: file.originalname,
      size: file.size,
      message: 'PDF uploaded successfully',
    });
  } catch (error) {
    console.error('❌ Error uploading PDF:', error);
    res.status(500).json({
      error: 'Failed to upload PDF',
      details: error.message,
    });
  }
});

// ============================================================
// POST /api/generate-questions
// Generates quiz questions using Groq AI API
// ============================================================
app.post('/api/generate-questions', async (req, res) => {
  let { sourceText, questionCount, difficulty, topic, cognitiveLevel, uid } = req.body;

  // Verify user is authenticated and has permission
  if (!uid) {
    return res.status(401).json({
      error: 'You must be logged in (provide uid)',
      statusCode: 401,
    });
  }

  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        error: 'User profile not found',
        statusCode: 404,
      });
    }
    const role = (userDoc.data().role || '').toLowerCase();
    if (role !== 'dentist' && role !== 'professor' && role !== 'teacher') {
      return res.status(403).json({
        error: 'Only professors/dentists can generate quiz questions',
        statusCode: 403,
      });
    }
  } catch (error) {
    console.error('Error checking user role:', error);
    return res.status(500).json({
      error: 'Failed to verify user role',
      details: error.message,
    });
  }

  if (!sourceText || sourceText.length < 50) {
    return res.status(400).json({
      error: 'Source text must be at least 50 characters',
      statusCode: 400,
    });
  }

  // Cap source text
  if (sourceText.length > 32000) {
    sourceText = sourceText.substring(0, 32000);
  }

  questionCount = questionCount || 10;
  difficulty = difficulty || 'medium';
  topic = topic || 'Dental Education';

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    return res.status(500).json({
      error: 'Groq API key not configured on server',
      statusCode: 500,
    });
  }

  const prompt = buildQuizPrompt(sourceText, questionCount, difficulty, topic, cognitiveLevel);

  try {
    console.log(
      `🤖 Generating ${questionCount} questions using Groq API (difficulty: ${difficulty})...`
    );

    const response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        model: 'mixtral-8x7b-32768',
        messages: [
          {
            role: 'system',
            content:
              'You are an expert dental education professor creating high-quality MCQ exam questions. Always respond ONLY with a valid JSON array, no markdown, no explanation.',
          },
          { role: 'user', content: prompt },
        ],
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 4000,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 90000,
      }
    );

    const content = response.data.choices[0].message.content.trim();
    let questions = parseQuestionsFromResponse(content);

    if (!Array.isArray(questions)) {
      questions = [];
    }

    // If no questions generated, create fallback
    if (questions.length === 0) {
      questions = generateFallbackQuestions(questionCount, topic);
    }

    console.log(`✅ Generated ${questions.length} questions`);

    res.status(200).json({
      questions,
      model: 'mixtral-8x7b-32768',
      tokensUsed: response.data.usage?.total_tokens || 0,
    });
  } catch (error) {
    console.error('❌ Error generating questions:', error.message);
    const statusCode = error.response?.status || 500;
    res.status(statusCode).json({
      error: 'Failed to generate questions',
      details: error.message,
      statusCode,
    });
  }
});

// ============================================================
// POST /api/generate-rag-quiz
// Generates quiz questions from uploaded documents using RAG
// ============================================================
app.post('/api/generate-rag-quiz', async (req, res) => {
  const { documentId, topic, questionCount, difficulty, cognitiveLevel, uid } = req.body;

  if (!documentId || !topic || !uid) {
    return res.status(400).json({
      error: 'documentId, topic, and uid are required',
      statusCode: 400,
    });
  }

  try {
    // Verify user exists and has permission
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        error: 'User profile not found',
        statusCode: 404,
      });
    }
    const role = (userDoc.data().role || '').toLowerCase();
    if (role !== 'dentist' && role !== 'professor' && role !== 'teacher') {
      return res.status(403).json({
        error: 'Only professors/dentists can generate quizzes',
        statusCode: 403,
      });
    }

    // Retrieve document from Firestore
    const docSnapshot = await db.collection('documents').doc(documentId).get();
    if (!docSnapshot.exists) {
      return res.status(404).json({
        error: 'Document not found. Please upload a PDF first.',
        statusCode: 404,
      });
    }

    const docData = docSnapshot.data();
    let sourceText = '';

    try {
      // Decode base64 buffer if stored
      if (docData.buffer) {
        sourceText = Buffer.from(docData.buffer, 'base64').toString('utf8');
      }
    } catch (_) {
      sourceText = docData.extractedText || '';
    }

    if (!sourceText || sourceText.trim().length < 50) {
      return res.status(400).json({
        error: 'Document does not contain sufficient text for quiz generation',
        statusCode: 400,
      });
    }

    // Cap text size
    if (sourceText.length > 32000) {
      sourceText = sourceText.substring(0, 32000);
    }

    const count = questionCount || 10;
    const level = difficulty || 'medium';

    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) {
      return res.status(500).json({
        error: 'Groq API key not configured',
        statusCode: 500,
      });
    }

    const prompt = buildQuizPrompt(sourceText, count, level, topic, cognitiveLevel);

    console.log(`🤖 Generating RAG quiz from document ${documentId} (${count} questions)...`);

    const response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        model: 'mixtral-8x7b-32768',
        messages: [
          {
            role: 'system',
            content:
              'You are an expert dental education professor. Generate high-quality MCQ questions based on the provided document. Always respond ONLY with a valid JSON array of question objects.',
          },
          { role: 'user', content: prompt },
        ],
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 4000,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: 90000,
      }
    );

    const content = response.data.choices[0].message.content.trim();
    let questions = parseQuestionsFromResponse(content);

    if (!Array.isArray(questions) || questions.length === 0) {
      // Generate fallback questions if parsing fails
      questions = generateFallbackQuestions(count, topic);
    }

    console.log(`✅ Generated ${questions.length} RAG quiz questions from document ${documentId}`);

    res.status(200).json({
      questions,
      documentId,
      model: 'mixtral-8x7b-32768',
      tokensUsed: response.data.usage?.total_tokens || 0,
    });
  } catch (error) {
    console.error('❌ Error generating RAG quiz:', error.message);
    const statusCode = error.response?.status || 500;
    res.status(statusCode).json({
      error: 'Failed to generate quiz from document',
      details: error.message,
      statusCode,
    });
  }
});

// ============================================================
// Utility: Parse Questions from Groq Response
// ============================================================
function parseQuestionsFromResponse(content) {
  try {
    // Try to extract JSON array from content
    const jsonMatch = content.match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    return JSON.parse(content);
  } catch (e) {
    console.error('Failed to parse questions:', e);
    return [];
  }
}

// ============================================================
// Utility: Build Quiz Generation Prompt
// ============================================================
function buildQuizPrompt(sourceText, questionCount, difficulty, topic, cognitiveLevel) {
  const levelGuidance =
    cognitiveLevel === 'analysis'
      ? 'Focus on analysis and critical thinking questions.'
      : cognitiveLevel === 'synthesis'
        ? 'Focus on synthesis and higher-order thinking questions.'
        : 'Mix of recall, understanding, and application questions.';

  const difficultyGuidance =
    difficulty === 'hard'
      ? 'Create challenging questions with nuanced options.'
      : difficulty === 'easy'
        ? 'Create beginner-friendly questions with clear distinctions.'
        : 'Create moderate difficulty questions balancing clarity and challenge.';

  return `You are creating Multiple Choice Questions (MCQs) for a dental education quiz.

Topic: ${topic}
Question Count: ${questionCount}
Difficulty: ${difficulty}
${levelGuidance}
${difficultyGuidance}

Based on this source material:
"${sourceText}"

Generate exactly ${questionCount} MCQ questions in JSON format. Each question object must have:
- id: unique identifier (e.g., "q1", "q2")
- text: the question text
- options: array of 4 answer options
- correctIndex: index of the correct answer (0-3)
- marks: points for correct answer (default 1)
- explanation: brief explanation of why the answer is correct

Return ONLY a valid JSON array of question objects. No markdown, no extra text.`;
}

// ============================================================
// Utility: Generate Fallback Questions (if AI fails)
// ============================================================
function generateFallbackQuestions(count, topic) {
  const questions = [];
  const fallbackQuestions = [
    {
      text: `What is the primary focus of ${topic}?`,
      options: [
        `Understanding the fundamentals of ${topic}`,
        'General dental knowledge',
        'Clinical procedures',
        'Patient care management',
      ],
      correctIndex: 0,
      explanation: `The primary focus of studying ${topic} is to understand its fundamental concepts and principles.`,
    },
    {
      text: `Which of the following is essential in ${topic}?`,
      options: [
        'Proper knowledge and understanding',
        'Basic equipment only',
        'Minimal training',
        'Standard procedures alone',
      ],
      correctIndex: 0,
      explanation:
        'Proper knowledge and understanding are essential foundations for any dental practice area.',
    },
    {
      text: `How does ${topic} impact patient care?`,
      options: [
        'Significantly improves treatment outcomes',
        'Has minimal effect',
        'Only affects specific cases',
        'Depends solely on equipment',
      ],
      correctIndex: 0,
      explanation: `Proper ${topic} significantly improves overall patient care and treatment outcomes.`,
    },
    {
      text: `What should be prioritized when studying ${topic}?`,
      options: [
        'Comprehensive understanding and practice',
        'Memorization only',
        'Equipment familiarization only',
        'Speed of execution',
      ],
      correctIndex: 0,
      explanation: `Comprehensive understanding combined with regular practice is key to mastering ${topic}.`,
    },
    {
      text: `Which competency is most important for ${topic}?`,
      options: [
        'Clinical knowledge and skill development',
        'Administrative tasks',
        'Record keeping alone',
        'Cost management only',
      ],
      correctIndex: 0,
      explanation: `Clinical knowledge and skill development are the most critical competencies in ${topic}.`,
    },
  ];

  for (let i = 0; i < Math.min(count, fallbackQuestions.length); i++) {
    const q = fallbackQuestions[i];
    questions.push({
      id: `q_fallback_${i}`,
      questionText: q.text,
      options: q.options,
      correctIndex: q.correctIndex,
      explanation: q.explanation,
      marks: 1,
      difficulty: 'medium',
    });
  }

  // If more questions are needed, repeat with variations
  while (questions.length < count) {
    const q = fallbackQuestions[questions.length % fallbackQuestions.length];
    questions.push({
      id: `q_fallback_${questions.length}`,
      questionText: `(Review) ${q.text}`,
      options: q.options,
      correctIndex: q.correctIndex,
      explanation: q.explanation,
      marks: 1,
      difficulty: Math.random() > 0.5 ? 'medium' : 'easy',
    });
  }

  return questions;
}

// ============================================================
// Error Handling Middleware
// ============================================================
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
});

// ============================================================
// 404 Handler
// ============================================================
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
    method: req.method,
  });
});

// ============================================================
// Start Server
// ============================================================
app.listen(PORT, () => {
  console.log(`🚀 Dental Care API Server running on port ${PORT}`);
  console.log(`📍 Base URL: http://localhost:${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});
