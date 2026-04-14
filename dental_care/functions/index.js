const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

// ============================================================
// 1. gradeQuizAttempt — Firestore onUpdate trigger
//    Fires when an attempt document is updated.
//    Grades the attempt when isSubmitted changes to true.
// ============================================================
exports.gradeQuizAttempt = functions.firestore
    .document("attempts/{attemptId}")
    .onUpdate(async (change, context) => {
      const {attemptId} = context.params;
      const before = change.before.data();
      const after = change.after.data();

      functions.logger.log(`gradeQuizAttempt triggered for ${attemptId}`);

      // Only grade if isSubmitted just became true
      if (before.isSubmitted === true || after.isSubmitted !== true) {
        functions.logger.log("Skipping: isSubmitted did not change to true");
        return null;
      }

      // Idempotent check: skip if already graded
      if (after.gradedAt) {
        functions.logger.log("Skipping: already graded");
        return null;
      }

      try {
        const quizId = after.quizId;
        functions.logger.log(`Grading attempt ${attemptId} for quiz ${quizId}`);

        // Fetch the quiz document (contains questions with correctIndex)
        const quizDoc = await db.collection("quizzes").doc(quizId).get();
        if (!quizDoc.exists) {
          functions.logger.error(`Quiz ${quizId} not found`);
          return null;
        }

        const quizData = quizDoc.data();
        const questions = quizData.questions || [];

        // Build a lookup map: questionId -> question data
        const questionMap = {};
        for (const q of questions) {
          questionMap[q.id] = q;
        }

        // Grade each response
        const responses = after.responses || [];
        const gradedResponses = [];
        let score = 0;
        let totalMarks = 0;

        for (const response of responses) {
          const question = questionMap[response.questionId];
          if (!question) {
            functions.logger.warn(
                `Question ${response.questionId} not found in quiz`,
            );
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
            correctAnswer: question.options
              ? question.options[question.correctIndex]
              : null,
          });
        }

        // Calculate percentage
        const percentage = totalMarks > 0 ?
          Math.round((score / totalMarks) * 100) : 0;

        // Update the attempt with grading results
        await change.after.ref.update({
          score,
          totalMarks,
          percentage,
          isPassed: percentage >= 60,
          gradedAt: admin.firestore.FieldValue.serverTimestamp(),
          responses: gradedResponses,
          status: "graded",
        });

        functions.logger.log(
            `✅ Graded attempt ${attemptId}: ${score}/${totalMarks} (${percentage}%)`,
        );
        return null;
      } catch (error) {
        functions.logger.error(`❌ Error grading attempt ${attemptId}:`, error);
        return null;
      }
    });

// ============================================================
// 2. recordCheatingViolation — HTTPS Callable
//    Records anti-cheating violations during a quiz attempt.
// ============================================================
exports.recordCheatingViolation = functions.https.onCall(async (data, context) => {
  // Auth check
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to record violations.",
    );
  }

  const {attemptId, violationType, timestamp, metadata} = data;
  const uid = context.auth.uid;

  functions.logger.log(
      `recordCheatingViolation: ${violationType} for attempt ${attemptId} by ${uid}`,
  );

  // Validate inputs
  const validTypes = [
    "tab_switch", "fullscreen_exit", "right_click",
    "copy_attempt", "inactivity",
  ];
  if (!attemptId || !validTypes.includes(violationType)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid violation type: ${violationType}. Must be one of: ${validTypes.join(", ")}`,
    );
  }

  try {
    // Fetch the attempt
    const attemptRef = db.collection("attempts").doc(attemptId);
    const attemptDoc = await attemptRef.get();

    if (!attemptDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Attempt not found");
    }

    const attemptData = attemptDoc.data();

    // Verify ownership
    if (attemptData.studentId !== uid) {
      throw new functions.https.HttpsError(
          "permission-denied",
          "You can only update your own attempts",
      );
    }

    // Ignore violations on completed attempts
    if (attemptData.isSubmitted === true) {
      functions.logger.log("Ignoring violation on submitted attempt");
      return {shouldAutoSubmit: false, violationCount: 0, warning: "Attempt already submitted"};
    }

    // Build the update
    const update = {};
    let counterField;
    switch (violationType) {
      case "tab_switch":
        counterField = "tabSwitchCount";
        break;
      case "fullscreen_exit":
        counterField = "fullscreenExitCount";
        break;
      case "inactivity":
        counterField = "inactivityCount";
        break;
      default:
        counterField = "otherViolationCount";
    }

    const currentCount = (attemptData[counterField] || 0) + 1;
    update[counterField] = currentCount;

    // Append to violation log
    update.violationLog = admin.firestore.FieldValue.arrayUnion({
      type: violationType,
      timestamp: timestamp || new Date().toISOString(),
      metadata: metadata || {},
      recordedAt: new Date().toISOString(),
    });

    // Check auto-submit threshold
    const tabCount = violationType === "tab_switch" ?
      currentCount : (attemptData.tabSwitchCount || 0);
    const fsCount = violationType === "fullscreen_exit" ?
      currentCount : (attemptData.fullscreenExitCount || 0);

    const shouldAutoSubmit = tabCount >= 3 || fsCount >= 3;

    if (shouldAutoSubmit) {
      update.autoSubmitTriggered = true;
      update.isSubmitted = true;
      update.endTime = admin.firestore.FieldValue.serverTimestamp();
      functions.logger.log(`⚠️ Auto-submit triggered for ${attemptId}`);
    }

    await attemptRef.update(update);

    // Build warning message
    let warning = "";
    if (violationType === "tab_switch") {
      warning = `Tab switch recorded (${currentCount}/3). `;
      if (currentCount >= 2 && !shouldAutoSubmit) {
        warning += "One more will auto-submit your quiz!";
      }
    } else if (violationType === "fullscreen_exit") {
      warning = `Fullscreen exit recorded (${currentCount}/3).`;
    }

    functions.logger.log(
        `✅ Violation recorded: ${violationType} (count: ${currentCount}), autoSubmit: ${shouldAutoSubmit}`,
    );

    return {
      shouldAutoSubmit,
      violationCount: currentCount,
      warning,
    };
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    functions.logger.error("❌ Error recording violation:", error);
    throw new functions.https.HttpsError("internal", "Failed to record violation");
  }
});

// ============================================================
// 3. generateQuestionsSecure — HTTPS Callable
//    Calls Groq API server-side so the API key stays off clients.
// ============================================================
exports.generateQuestionsSecure = functions
    .runWith({timeoutSeconds: 60, memory: "256MB"})
    .https.onCall(async (data, context) => {
      // Auth check
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in.",
        );
      }

      const uid = context.auth.uid;
      functions.logger.log(`generateQuestionsSecure called by ${uid}`);

      // Verify user is a professor/dentist
      try {
        const userDoc = await db.collection("users").doc(uid).get();
        if (!userDoc.exists) {
          throw new functions.https.HttpsError("not-found", "User profile not found");
        }
        const role = (userDoc.data().role || "").toLowerCase();
        if (role !== "dentist" && role !== "professor") {
          throw new functions.https.HttpsError(
              "permission-denied",
              "Only professors/dentists can generate quiz questions",
          );
        }
      } catch (error) {
        if (error instanceof functions.https.HttpsError) throw error;
        functions.logger.error("Error checking user role:", error);
        throw new functions.https.HttpsError("internal", "Failed to verify user role");
      }

      // Validate inputs
      let {sourceText, questionCount, difficulty, topic, cognitiveLevel} = data;

      if (!sourceText || sourceText.length < 50) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Source text must be at least 50 characters",
        );
      }

      // Trim to Groq context limit
      if (sourceText.length > 32000) {
        functions.logger.log(
            `Trimming source text from ${sourceText.length} to 32000 chars`,
        );
        sourceText = sourceText.substring(0, 32000);
      }

      questionCount = questionCount || 10;
      difficulty = difficulty || "medium";
      topic = topic || "Dental Education";

      // Build the prompt
      const prompt = buildPrompt(sourceText, questionCount, difficulty, topic, cognitiveLevel);

      // Get Groq API key from environment (.env)
      const apiKey = process.env.GROQ_API_KEY;

      if (!apiKey) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "Groq API key is empty or not configured in .env",
        );
      }

      // Call Groq API with retry
      let responseContent;
      for (let attempt = 0; attempt < 2; attempt++) {
        try {
          functions.logger.log(`Calling Groq API (attempt ${attempt + 1}/2)...`);

          const response = await axios.post(
              "https://api.groq.com/openai/v1/chat/completions",
              {
                model: "mixtral-8x7b-32768",
                messages: [
                  {
                    role: "system",
                    content: "You are an expert dental education professor creating MCQ exam questions. " +
                      "Generate high-quality questions in valid JSON format. " +
                      "Always respond ONLY with a valid JSON array, no markdown, no explanation.",
                  },
                  {role: "user", content: prompt},
                ],
                max_tokens: 4096,
                temperature: 0.7,
              },
              {
                headers: {Authorization: `Bearer ${apiKey}`},
                timeout: 30000,
              },
          );

          responseContent = response.data.choices[0].message.content;
          break; // Success, exit retry loop
        } catch (error) {
          functions.logger.error(`Groq API attempt ${attempt + 1} failed:`, error.message);
          if (attempt === 1) {
            const status = error.response?.status;
            if (status === 429) {
              throw new functions.https.HttpsError(
                  "resource-exhausted",
                  "Groq API rate limit exceeded. Please wait and try again.",
              );
            }
            if (status === 401) {
              throw new functions.https.HttpsError(
                  "unauthenticated",
                  "Invalid Groq API key",
              );
            }
            throw new functions.https.HttpsError(
                "internal",
                `Failed to generate questions: ${error.message}`,
            );
          }
          // Wait 1s before retry
          await new Promise((r) => setTimeout(r, 1000));
        }
      }

      // Parse the response
      try {
        let jsonStr = responseContent.trim();

        // Strip markdown code fences
        if (jsonStr.includes("```")) {
          jsonStr = jsonStr.replace(/```\w*\n?/g, "");
          jsonStr = jsonStr.replace(/\n?```/g, "");
          jsonStr = jsonStr.trim();
        }

        const startIdx = jsonStr.indexOf("[");
        const endIdx = jsonStr.lastIndexOf("]");
        if (startIdx >= 0 && endIdx > startIdx) {
          jsonStr = jsonStr.substring(startIdx, endIdx + 1);
        }

        const questions = JSON.parse(jsonStr);

        // Validate each question
        const validated = questions.map((q, i) => {
          const options = Array.isArray(q.options) ? q.options : [];
          while (options.length < 4) options.push(`Option ${options.length + 1}`);
          if (options.length > 4) options.length = 4;

          return {
            questionText: q.questionText || `Question ${i + 1}`,
            options,
            correctIndex: Math.min(Math.max(parseInt(q.correctIndex) || 0, 0), 3),
            explanation: q.explanation || "",
            difficulty: q.difficulty || difficulty,
          };
        });

        functions.logger.log(`✅ Generated and validated ${validated.length} questions`);
        return {questions: validated};
      } catch (parseError) {
        functions.logger.error("Failed to parse Groq response:", parseError);
        functions.logger.error("Raw response:", responseContent);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to parse AI response. Please try again.",
        );
      }
    });

// ─── Helper: Build Groq prompt ───────────────────────────────

function buildPrompt(sourceText, questionCount, difficulty, topic, cognitiveLevel) {
  const difficultyDesc = {
    easy: "Easy - basic recall and recognition",
    medium: "Medium - understanding and application",
    hard: "Hard - analysis, synthesis, and critical thinking",
    mixed: "Mixed - blend of easy, medium, and hard",
  }[difficulty] || difficulty;

  const cognitiveDesc = cognitiveLevel ?
    `Cognitive Level: ${cognitiveLevel}` : "";

  return `Generate exactly ${questionCount} multiple-choice questions based on the following dental/medical content.

Requirements:
- Difficulty: ${difficultyDesc}
${cognitiveDesc ? `- ${cognitiveDesc}` : ""}
- Topic: ${topic}
- Each question must have exactly 4 options
- correctIndex must be 0, 1, 2, or 3
- Include a brief explanation for each correct answer
- All options must be plausible

STRICT JSON RULES:
- Respond ONLY with a valid JSON array, no markdown
- Each object: { "questionText", "options" (array of 4), "correctIndex" (0-3), "explanation", "difficulty" }

SOURCE CONTENT:
${sourceText}`;
}
