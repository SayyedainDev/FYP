# Dental Care Quiz Backend API

Express.js backend server for the Dental Care Flutter application. Provides endpoints for quiz proctoring, PDF uploads, and AI-powered question generation.

## Features

- **Quiz Proctoring**: Record and enforce exam integrity violations (tab switches, fullscreen exits, inactivity)
- **PDF Upload**: Handle document uploads for RAG integration
- **AI Question Generation**: Generate quiz questions using Groq's Mixtral model
- **Firebase Integration**: Secure data storage and validation
- **CORS Enabled**: Supports cross-origin requests from Flutter web

## Prerequisites

- Node.js 18.x or higher
- Firebase Project (with service account credentials)
- Groq API key (for question generation)
- Render account (for deployment)

## Installation

### Local Development

1. Clone the repository:
```bash
cd fy_dental_backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file from `.env.example`:
```bash
cp .env.example .env
```

4. Add your configuration to `.env`:
```env
FIREBASE_SERVICE_ACCOUNT="your_firebase_service_account_key"
GROQ_API_KEY="your_groq_api_key"
PORT=5000
NODE_ENV=development
```

5. (Optional) For Firebase, you can place `serviceAccountKey.json` in the root directory instead of using environment variables.

6. Start the development server:
```bash
npm run dev
```

The server will run on `http://localhost:5000`

## Deployment to Render

### Step 1: Push to GitHub

Ensure your code is committed and pushed to a GitHub repository:

```bash
git add .
git commit -m "Add backend API server"
git push origin main
```

### Step 2: Create Render Service

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Configure the service:
   - **Name**: `fyp-groq` (or your preferred name)
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Region**: Choose closest to your users
   - **Instance Type**: Free (for development) or Starter+ (for production)

### Step 3: Set Environment Variables

In Render dashboard:

1. Go to your service → **Environment**
2. Add these environment variables:

```
PORT=5000
NODE_ENV=production
GROQ_API_KEY=<your_groq_api_key>
FIREBASE_SERVICE_ACCOUNT=<base64_encoded_firebase_key>
```

#### Encoding Firebase Service Account

To encode your Firebase service account key:

**Option A: Using Node.js**
```javascript
const fs = require('fs');
const key = fs.readFileSync('./serviceAccountKey.json', 'utf8');
const encoded = Buffer.from(key).toString('base64');
console.log(encoded);
```

**Option B: Using bash**
```bash
cat serviceAccountKey.json | base64
```

#### Getting Groq API Key

1. Visit https://console.groq.com
2. Sign up or log in
3. Create an API key
4. Copy the key and paste it into Render environment variables

### Step 4: Deploy

1. Click **Deploy** button in Render
2. Wait for deployment to complete (usually 2-5 minutes)
3. Your service URL will be like: `https://fyp-groq.onrender.com`
4. Test health endpoint: `https://fyp-groq.onrender.com/health`

### Step 5: Update Flutter App

Update the backend URL in your Flutter app's `quiz_attempt_provider.dart`:

```dart
final String backendUrl = 'https://fyp-groq.onrender.com';
```

(This should already be set in the environment variable)

## API Endpoints

### 1. Health Check
```
GET /health
```
Returns server status.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-05-03T10:30:00Z"
}
```

---

### 2. Record Violation
```
POST /api/record-violation
```
Records exam integrity violations during quiz attempts.

**Request Body:**
```json
{
  "attemptId": "DOdhYlyMi1bUmdXFZu8y",
  "uid": "student_user_id",
  "violationType": "tab_switch",
  "timestamp": "2024-05-03T10:30:00Z"
}
```

**violationType Options:**
- `tab_switch` - Student switched browser tabs
- `fullscreen_exit` - Student exited fullscreen mode
- `inactivity` - Student inactive for 3+ minutes
- `right_click` - Right-click attempt detected
- `other` - Other violation types

**Response:**
```json
{
  "shouldAutoSubmit": false,
  "violationCount": 1,
  "warning": "Tab switch recorded (1/3). Two more will auto-submit your quiz!"
}
```

**Auto-submit Thresholds:**
- 3 tab switches → auto-submit
- 3 fullscreen exits → auto-submit

---

### 3. Upload PDF
```
POST /api/upload-pdf
```
Uploads PDF files for document processing and RAG.

**Request:**
- Multipart form-data
- File field: `file`
- Max size: 10MB

**Response:**
```json
{
  "documentId": "doc_1715000000_abc123def",
  "filename": "lecture_notes.pdf",
  "size": 2048576,
  "message": "PDF uploaded successfully"
}
```

---

### 4. Generate Quiz Questions
```
POST /api/generate-questions
```
Generates AI-powered quiz questions using Groq API.

**Request Body:**
```json
{
  "uid": "teacher_user_id",
  "sourceText": "Dental anatomy covers the structure and classification of teeth...",
  "questionCount": 10,
  "difficulty": "medium",
  "topic": "Dental Anatomy",
  "cognitiveLevel": "application"
}
```

**Parameters:**
- `uid`: Teacher/professor user ID (authenticated user)
- `sourceText`: Source material (50+ characters, max 32KB)
- `questionCount`: 1-50 questions (default: 10)
- `difficulty`: `easy`, `medium`, `hard` (default: `medium`)
- `topic`: Quiz topic (default: `Dental Education`)
- `cognitiveLevel`: `recall`, `application`, `analysis`, `synthesis`

**Response:**
```json
{
  "questions": [
    {
      "id": "q1",
      "text": "What type of teeth are primarily used for cutting?",
      "options": [
        "Incisors",
        "Canines",
        "Molars",
        "Premolars"
      ],
      "correctIndex": 0,
      "marks": 1,
      "explanation": "Incisors are flat teeth at the front of the mouth designed for cutting and biting food."
    }
  ],
  "model": "mixtral-8x7b-32768",
  "tokensUsed": 1234
}
```

---

### 4. Generate RAG Quiz
```
POST /api/generate-rag-quiz
```
Generates AI-powered quiz questions from uploaded PDF documents using RAG (Retrieval-Augmented Generation).

**Request Body:**
```json
{
  "uid": "teacher_user_id",
  "documentId": "doc_1715000000_abc123def",
  "topic": "Dental Anatomy",
  "questionCount": 10,
  "difficulty": "medium",
  "cognitiveLevel": "application"
}
```

**Parameters:**
- `uid`: Teacher/professor user ID (authenticated user)
- `documentId`: Document ID returned from `/api/upload-pdf`
- `topic`: Quiz topic derived from the document
- `questionCount`: 1-50 questions (default: 10)
- `difficulty`: `easy`, `medium`, `hard` (default: `medium`)
- `cognitiveLevel`: `recall`, `application`, `analysis`, `synthesis`

**Response:**
```json
{
  "questions": [
    {
      "id": "q_1715000123_0",
      "questionText": "Based on the document, what is the primary structure discussed?",
      "options": [
        "Dental anatomy",
        "Biological systems",
        "Chemical properties",
        "Physical measurements"
      ],
      "correctIndex": 0,
      "explanation": "The document primarily focuses on dental anatomy and tooth structure.",
      "marks": 1
    }
  ],
  "documentId": "doc_1715000000_abc123def",
  "model": "mixtral-8x7b-32768",
  "tokensUsed": 1234
}
```

---

### Flow: Upload PDF → Generate Quiz
1. Teacher uploads PDF → `/api/upload-pdf` returns `documentId`
2. Teacher requests quiz generation with `documentId` → `/api/generate-rag-quiz` returns questions
3. Questions are saved to quiz collection in Firestore
4. Students can attempt the quiz

---

## Quiz Generation Models

### 1. `/api/generate-questions` — Direct Text Input
- Input: Plain text, lecture notes, or source material
- Ideal for: Quick quiz creation from written content
- No PDF required

### 2. `/api/generate-rag-quiz` — Document-Based (RAG)
- Input: Uploaded PDF file
- Ideal for: Creating quizzes from textbooks, papers, or reference materials
- Automatic content extraction and question generation
- More contextually relevant questions

---

## Troubleshooting

### Service won't start
- Check environment variables are set correctly
- Verify Firebase credentials are valid base64-encoded JSON
- Check Render logs: **Service** → **Logs** tab

### "Groq API key not configured"
- Ensure `GROQ_API_KEY` is set in Render environment
- Get key from https://console.groq.com
- Redeploy after adding the key

### Firebase connection errors
- Verify `FIREBASE_SERVICE_ACCOUNT` is valid
- Test locally with `serviceAccountKey.json` first
- Check Firebase project is active and has Firestore enabled

### PDF upload fails
- Check file size (max 10MB)
- Verify Firebase can write to `documents` collection
- Check storage quota in Firestore

## Development

### Run locally with hot reload:
```bash
npm run dev
```

### Run tests (if added):
```bash
npm test
```

## Production Recommendations

1. **Enable Persistence**: Upgrade to Paid Instance on Render
2. **Monitor Requests**: Use Render Logs API for monitoring
3. **Cache Responses**: Add Redis for high-traffic endpoints
4. **Rate Limiting**: Implement request rate limiting
5. **Database Backups**: Enable Firestore automated backups
6. **Environment Secrets**: Use Render's built-in secret management
7. **SSL/TLS**: Enabled by default on Render

## License

MIT

## Support

For issues or questions, contact: sabeeh@example.com
