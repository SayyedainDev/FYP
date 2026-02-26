# Dental Care - AI-Powered Dental Disease Detection System

## Final Year Project Documentation

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Module Descriptions](#4-module-descriptions)
5. [Data Models](#5-data-models)
6. [API Documentation](#6-api-documentation)
7. [Database Schema](#7-database-schema)
8. [User Interface Design](#8-user-interface-design)
9. [Installation & Setup](#9-installation--setup)
10. [Testing](#10-testing)
11. [Future Enhancements](#11-future-enhancements)

---

## 1. Project Overview

### 1.1 Project Title
**Dental Care: AI-Powered Dental Disease Detection and Practice Management System**

### 1.2 Project Description
Dental Care is a comprehensive Flutter-based application designed for dental professionals (dentists and dental students) to detect dental diseases using AI-powered image analysis, manage patient records, schedule appointments, create treatment plans, and enhance learning through quiz generation from lecture materials.

### 1.3 Problem Statement
Dental professionals face challenges in:
- Early detection of dental diseases from X-rays and intraoral images
- Managing patient records and treatment histories efficiently
- Tracking appointments and follow-ups
- Creating educational materials for dental students
- Maintaining consistent diagnostic accuracy

### 1.4 Proposed Solution
An integrated platform that combines:
- **AI-powered dental disease detection** using YOLO (You Only Look Once) deep learning model
- **Patient management system** with complete medical history tracking
- **Appointment scheduling** and management
- **Treatment planning** with progress tracking
- **Educational tools** including quiz generation from lecture notes
- **Analytics dashboard** for practice insights

### 1.5 Objectives
1. Develop an AI model to detect dental diseases (Cavity, Gingivitis, Calculus, Caries, etc.)
2. Create a user-friendly cross-platform application using Flutter
3. Implement secure patient data management using Firebase
4. Provide educational tools for dental students
5. Generate comprehensive analytics for practice management

### 1.6 Scope
- **Target Users:** Dentists, Dental Students, Dental Clinics
- **Platforms:** Web, Android, iOS, Windows, macOS, Linux
- **Diseases Detected:** Cavity, Gingivitis, Tooth Discoloration, Ulcer, Calculus, Hypodontia, Caries

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DENTAL CARE SYSTEM                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     PRESENTATION LAYER (Flutter)                     │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │   │
│  │  │Dashboard │ │ Patients │ │Detection │ │  Quiz    │ │ Settings │   │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────▼───────────────────────────────────┐   │
│  │                     STATE MANAGEMENT (Provider)                      │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                 │   │
│  │  │AuthProvider  │ │PatientProvider│ │CaseProvider │  ...           │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────▼───────────────────────────────────┐   │
│  │                        SERVICE LAYER                                 │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                 │   │
│  │  │FirebaseService│ │AIAnalysis   │ │FileParser    │                 │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
├────────────────────────────────────┼────────────────────────────────────────┤
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        BACKEND SERVICES                              │   │
│  │                                                                      │   │
│  │  ┌───────────────────────┐    ┌───────────────────────┐            │   │
│  │  │    FIREBASE SUITE     │    │   FLASK AI API        │            │   │
│  │  │  ┌─────────────────┐  │    │  ┌─────────────────┐  │            │   │
│  │  │  │ Authentication  │  │    │  │   YOLO Model    │  │            │   │
│  │  │  ├─────────────────┤  │    │  │   (best.pt)     │  │            │   │
│  │  │  │ Cloud Firestore │  │    │  ├─────────────────┤  │            │   │
│  │  │  ├─────────────────┤  │    │  │ /coordinates    │  │            │   │
│  │  │  │ Firebase Storage│  │    │  │ /analyze        │  │            │   │
│  │  │  └─────────────────┘  │    │  └─────────────────┘  │            │   │
│  │  └───────────────────────┘    └───────────────────────┘            │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APPLICATION                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Views      │  │   Models     │  │  Providers   │  │  Services    │ │
│  │              │  │              │  │              │  │              │ │
│  │ • Login      │  │ • Patient    │  │ • Auth       │  │ • Firebase   │ │
│  │ • Register   │  │ • Case       │  │ • Patient    │  │ • AI Analysis│ │
│  │ • Dashboard  │  │ • Quiz       │  │ • Case       │  │ • File Parser│ │
│  │ • Detection  │  │ • Appointment│  │ • Quiz       │  │ • Report Gen │ │
│  │ • Patients   │  │ • Treatment  │  │ • Lecture    │  │ • Notification│
│  │ • Quiz       │  │ • LectureNote│  │ • Analytics  │  │ • Backup     │ │
│  │ • Settings   │  │ • Analytics  │  │ • Appointment│  │              │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Data Flow Diagram

```
                    ┌─────────────────┐
                    │     Dentist     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
      ┌───────────┐  ┌───────────┐  ┌───────────┐
      │  Upload   │  │  Manage   │  │  Create   │
      │  X-Ray    │  │ Patients  │  │   Quiz    │
      └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
            │              │              │
            ▼              ▼              ▼
      ┌───────────┐  ┌───────────┐  ┌───────────┐
      │ YOLO API  │  │ Firestore │  │ Lecture   │
      │ Detection │  │ Database  │  │ Notes     │
      └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
            │              │              │
            ▼              ▼              ▼
      ┌───────────┐  ┌───────────┐  ┌───────────┐
      │ Annotated │  │ Patient   │  │   Quiz    │
      │  Image    │  │ Records   │  │ Generated │
      └───────────┘  └───────────┘  └───────────┘
```

---

## 3. Technology Stack

### 3.1 Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.8.1+ | Cross-platform UI framework |
| Dart | 3.8.1+ | Programming language |
| Provider | 6.1.5+ | State management |
| Material Design 3 | - | UI components |

### 3.2 Backend Services

| Technology | Purpose |
|------------|---------|
| Firebase Authentication | User authentication & authorization |
| Cloud Firestore | NoSQL database for data storage |
| Firebase Storage | File storage (images, documents) |
| Flask | Python backend for AI API |
| Supabase (Optional) | Alternative storage for lecture notes |

### 3.3 AI/ML Components

| Technology | Version | Purpose |
|------------|---------|---------|
| YOLOv8 (Ultralytics) | 8.0+ | Object detection model |
| OpenCV | 4.5+ | Image processing |
| NumPy | 1.20+ | Numerical computing |
| Pillow | 8.0+ | Image manipulation |

### 3.4 Development Tools

| Tool | Purpose |
|------|---------|
| VS Code | Primary IDE |
| Android Studio | Android development |
| Xcode | iOS development |
| Git | Version control |
| Firebase CLI | Firebase deployment |

---

## 4. Module Descriptions

### 4.1 Authentication Module

**Location:** `lib/controller/auth_controller.dart`, `lib/provider/auth_provider.dart`

**Features:**
- Email/Password registration and login
- User profile management
- Role-based access (Dentist/Student)
- Secure session management

**Key Components:**
- `AuthController` - Business logic for authentication
- `AuthProvider` - State management for auth status
- `FirebaseService` - Firebase Auth integration

**User Model Attributes:**
```dart
- uid: String (Firebase UID)
- userId: String (Custom user ID)
- firstName: String
- lastName: String
- cnic: String
- address: String
- highestEducation: String
- email: String
- role: String (Student | Dentist)
```

### 4.2 Patient Management Module

**Location:** `lib/view/patients_screen.dart`, `lib/providers/patient_provider.dart`

**Features:**
- Add, edit, delete patients
- Patient search and filtering
- Medical history tracking
- Patient-case association

**Data Fields:**
```dart
- id: String
- dentistUid: String
- name: String
- dob: DateTime
- gender: String
- contactPhone: String
- contactEmail: String
- notes: String
- createdAt: DateTime
```

### 4.3 Dental Disease Detection Module

**Location:** `lib/view/dental_detection_screen.dart`, `model/Dental-Disease-Detection/app.py`

**Features:**
- Image upload (JPG, JPEG, PNG)
- Multi-angle detection support
- Real-time AI analysis
- Annotated image display
- Detection confidence scores

**Supported Diseases:**
1. Cavity
2. Gingivitis
3. Tooth Discoloration
4. Ulcer
5. Calculus
6. Hypodontia
7. Caries

**API Endpoints:**
- `POST /coordinates` - Returns annotated image
- `POST /analyze` - Returns JSON analysis data

### 4.4 Case Management Module

**Location:** `lib/view/create_case_screen.dart`, `lib/providers/case_provider.dart`

**Features:**
- Create dental cases with images
- AI analysis integration
- Case status tracking (Uploaded → Under Review → Completed)
- Case comparison
- Review notes

**Case Status Flow:**
```
Uploaded → Under Review → Completed
    │           │
    └───────────┴──→ Analysis Complete
```

### 4.5 Appointment Management Module

**Location:** `lib/view/appointment_management_screen.dart`, `lib/providers/appointment_provider.dart`

**Features:**
- Schedule appointments
- Appointment types (Consultation, Treatment, Follow-up, Checkup)
- Status tracking (Scheduled, Completed, Cancelled, No-show)
- Duration management
- Location tracking

### 4.6 Treatment Plan Module

**Location:** `lib/view/treatment_plan_screen.dart`, `lib/providers/treatment_plan_provider.dart`

**Features:**
- Multi-phase treatment planning
- Progress tracking (0-100%)
- Cost estimation
- Priority levels (Low, Medium, High, Urgent)
- Completion dates

### 4.7 Quiz Generation Module

**Location:** `lib/view/ai_quiz_screen.dart`, `lib/providers/quiz_provider.dart`

**Features:**
- AI-powered quiz generation from lecture notes
- Multiple question types:
  - MCQ (Multiple Choice)
  - True/False
  - Short Answer
  - Long Answer
  - Fill in the Blanks
  - Scenario-Based
- Difficulty levels (Easy, Medium, Hard, Mixed)
- Cognitive levels (Knowledge, Understanding, Application, Analysis)
- PDF export capability
- Time limits

### 4.8 Lecture Notes Module

**Location:** `lib/view/lecture_notes_screen.dart`, `lib/providers/lecture_notes_provider.dart`

**Features:**
- Upload various file types (PDF, DOC, DOCX, PPTX, TXT, Images)
- Custom note creation
- Tagging system
- View tracking
- Quiz generation from notes

### 4.9 Analytics Module

**Location:** `lib/view/advanced_analytics_screen.dart`, `lib/providers/analytics_provider.dart`

**Features:**
- Dashboard statistics
- Monthly trends
- Tooth-wise analysis
- Case resolution time
- Patient retention rate
- Detection accuracy metrics

### 4.10 Settings Module

**Location:** `lib/view/settings_screen.dart`

**Features:**
- Profile management
- App preferences
- Data backup
- Account settings
- Logout functionality

---

## 5. Data Models

### 5.1 Patient Model

```dart
class Patient {
  final String id;
  final String dentistUid;
  final String name;
  final DateTime dob;
  final String gender;
  final String contactPhone;
  final String contactEmail;
  final String notes;
  final DateTime createdAt;
  
  // Computed property
  int get age => calculateAge();
  String get initials => getInitials();
}
```

### 5.2 Case Model

```dart
class Case {
  final String id;
  final String patientId;
  final String patientName;
  final String toothNumber;
  final DateTime caseDate;
  final DateTime updatedAt;
  final String caseTitle;
  final String caseStatus; // Uploaded | Under Review | Completed
  final List<String> imageUrls;
  final Map<String, dynamic> analysisResults;
  final String notes;
  final String reviewNotes;
  
  // Computed properties
  bool get isAnalysisComplete;
  String get analysisStatus;
  bool get hasCavity;
}
```

### 5.3 Quiz Model

```dart
class Quiz {
  final String id;
  final String dentistUid;
  final String title;
  final DateTime createdAt;
  final QuizConfig config;
  final List<Question> questions;
  final int timeLimitMinutes;
  final bool isPublished;
}

class QuizConfig {
  final DifficultyLevel difficulty;
  final int totalQuestions;
  final List<QuestionType> questionTypes;
  final CognitiveLevel cognitiveLevel;
  final bool includeAnswerKey;
  final String explanationLevel;
}
```

### 5.4 Appointment Model

```dart
class Appointment {
  final String id;
  final String patientId;
  final String dentistUid;
  final DateTime appointmentDate;
  final Duration duration;
  final String status; // scheduled, completed, cancelled, no-show
  final String appointmentType; // consultation, treatment, follow-up, checkup
  final String notes;
  final String? location;
  final bool reminderSent;
}
```

### 5.5 Treatment Plan Model

```dart
class TreatmentPlan {
  final String id;
  final String patientId;
  final String dentistUid;
  final String title;
  final String description;
  final List<TreatmentPhase> phases;
  final String status; // draft, active, completed, on-hold
  final DateTime startDate;
  final DateTime? completionDate;
  final double estimatedCost;
  final String priority; // low, medium, high, urgent
  final int progressPercentage;
}
```

### 5.6 Lecture Note Model

```dart
class LectureNote {
  final String id;
  final String dentistUid;
  final String title;
  final String description;
  final NoteType type; // pdf, doc, docx, pptx, txt, image, video, custom
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? customNotes;
  final List<String> tags;
  final DateTime createdAt;
  final int views;
  final bool isPublished;
}
```

---

## 6. API Documentation

### 6.1 Flask AI Detection API

**Base URL:** `http://127.0.0.1:5000`

#### Health Check
```
GET /

Response:
{
  "status": "running",
  "model_loaded": true/false,
  "endpoints": ["/coordinates", "/analyze"],
  "mode": "production" | "demo"
}
```

#### Detect with Annotations
```
POST /coordinates

Request:
- Content-Type: multipart/form-data
- Body:
  - image: File (JPG, JPEG, PNG)
  - multi_angle: "true" | "false"

Response:
- Content-Type: image/jpeg
- Body: Annotated image with bounding boxes
```

#### Analyze Image (JSON)
```
POST /analyze

Request:
- Content-Type: multipart/form-data
- Body:
  - image: File (JPG, JPEG, PNG)
  - multi_angle: "true" | "false"

Response:
{
  "success": true,
  "detections": [
    {
      "class": "Cavity",
      "confidence": 0.87,
      "bbox": [x1, y1, x2, y2]
    }
  ],
  "total_detections": 2,
  "image_size": {"width": 1920, "height": 1080},
  "diseases_found": ["Cavity", "Calculus"],
  "model_mode": "production" | "demo",
  "summary": {
    "highest_confidence": 0.87,
    "average_confidence": 0.79,
    "disease_counts": {"Cavity": 1, "Calculus": 1}
  }
}
```

### 6.2 Firebase Collections

#### Users Collection
```
Collection: users/{uid}
{
  "uid": "string",
  "userId": "string",
  "firstName": "string",
  "lastName": "string",
  "cnic": "string",
  "address": "string",
  "highestEducation": "string",
  "email": "string",
  "role": "Student" | "Dentist"
}
```

#### Patients Collection
```
Collection: patients/{patientId}
{
  "dentistUid": "string",
  "name": "string",
  "dob": Timestamp,
  "gender": "string",
  "contactPhone": "string",
  "contactEmail": "string",
  "notes": "string",
  "createdAt": Timestamp
}
```

#### Cases Collection
```
Collection: cases/{caseId}
{
  "patientId": "string",
  "patientName": "string",
  "dentistUid": "string",
  "toothNumber": "string",
  "caseDate": Timestamp,
  "caseStatus": "string",
  "imageUrls": ["string"],
  "analysisResults": {...},
  "notes": "string"
}
```

---

## 7. Database Schema

### 7.1 Firestore Collections Structure

```
dental_care_db/
├── users/
│   └── {userId}/
│       ├── uid
│       ├── firstName
│       ├── lastName
│       ├── email
│       └── role
│
├── patients/
│   └── {patientId}/
│       ├── dentistUid
│       ├── name
│       ├── dob
│       ├── gender
│       ├── contactPhone
│       ├── contactEmail
│       └── notes
│
├── cases/
│   └── {caseId}/
│       ├── patientId
│       ├── dentistUid
│       ├── toothNumber
│       ├── caseStatus
│       ├── imageUrls[]
│       ├── analysisResults{}
│       └── notes
│
├── appointments/
│   └── {appointmentId}/
│       ├── patientId
│       ├── dentistUid
│       ├── appointmentDate
│       ├── duration
│       ├── status
│       └── notes
│
├── treatment_plans/
│   └── {planId}/
│       ├── patientId
│       ├── dentistUid
│       ├── phases[]
│       ├── status
│       └── progressPercentage
│
├── quizzes/
│   └── {quizId}/
│       ├── dentistUid
│       ├── title
│       ├── config{}
│       └── questions[]
│
└── lecture_notes/
    └── {noteId}/
        ├── dentistUid
        ├── title
        ├── type
        ├── fileUrl
        └── tags[]
```

### 7.2 Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isDentist(dentistUid) {
      return isAuthenticated() && request.auth.uid == dentistUid;
    }
    
    // Users - own data only
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Patients - dentist's patients only
    match /patients/{patientId} {
      allow read, write: if isDentist(resource.data.dentistUid);
    }
    
    // Cases - dentist's cases only
    match /cases/{caseId} {
      allow read, write: if isDentist(resource.data.dentistUid);
    }
    
    // Similar rules for other collections...
  }
}
```

---

## 8. User Interface Design

### 8.1 Screen Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         LOGIN SCREEN                            │
│                              │                                  │
│              ┌───────────────┼───────────────┐                  │
│              ▼               │               ▼                  │
│     ┌─────────────┐          │      ┌─────────────┐            │
│     │  REGISTER   │          │      │   FORGOT    │            │
│     │   SCREEN    │          │      │  PASSWORD   │            │
│     └─────────────┘          │      └─────────────┘            │
│                              ▼                                  │
│                     ┌─────────────────┐                         │
│                     │  MAIN LAYOUT    │                         │
│                     │  (With Sidebar) │                         │
│                     └────────┬────────┘                         │
│                              │                                  │
│    ┌──────────┬──────────┬───┴───┬──────────┬──────────┐       │
│    ▼          ▼          ▼       ▼          ▼          ▼       │
│ ┌──────┐ ┌──────┐ ┌──────────┐ ┌─────┐ ┌─────────┐ ┌──────┐   │
│ │Dash- │ │Patie-│ │Detection │ │Cases│ │Lecture  │ │Setti-│   │
│ │board │ │nts   │ │  Screen  │ │     │ │Notes    │ │ngs   │   │
│ └──────┘ └──────┘ └──────────┘ └─────┘ └─────────┘ └──────┘   │
│                                                                 │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │               ADDITIONAL SCREENS                          │   │
│ │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │   │
│ │  │Treatment │ │Appoint-  │ │Analytics │ │  Quiz    │     │   │
│ │  │  Plans   │ │  ments   │ │          │ │Generator │     │   │
│ │  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │   │
│ └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Main Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                         MAIN LAYOUT                             │
├─────────┬───────────────────────────────────────────────────────┤
│         │                                                       │
│  SIDE   │                    CONTENT AREA                       │
│  BAR    │                                                       │
│         │   ┌───────────────────────────────────────────────┐  │
│ ┌─────┐ │   │                                               │  │
│ │Logo │ │   │             DYNAMIC SCREEN                    │  │
│ └─────┘ │   │                                               │  │
│         │   │   (Dashboard / Patients / Detection / etc.)   │  │
│ ┌─────┐ │   │                                               │  │
│ │Nav  │ │   │                                               │  │
│ │Items│ │   │                                               │  │
│ │     │ │   │                                               │  │
│ │  •  │ │   │                                               │  │
│ │  •  │ │   │                                               │  │
│ │  •  │ │   │                                               │  │
│ └─────┘ │   │                                               │  │
│         │   │                                               │  │
│ ┌─────┐ │   └───────────────────────────────────────────────┘  │
│ │User │ │                                                       │
│ │Info │ │                                                       │
│ └─────┘ │                                                       │
│         │                                                       │
└─────────┴───────────────────────────────────────────────────────┘
```

### 8.3 Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  Welcome back, Dr. [Name]!                                      │
│  Here's your summary for today.                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │  Total   │ │  Total   │ │ Cavities │ │ Healthy  │           │
│  │ Patients │ │  Scans   │ │ Detected │ │  Scans   │           │
│  │    12    │ │    45    │ │    23    │ │    22    │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
│                                                                 │
├────────────────────────────┬────────────────────────────────────┤
│     RECENT SCANS           │         PATIENTS                   │
│  ┌──────────────────────┐  │  ┌──────────────────────────────┐ │
│  │ Case #1 - Uploaded   │  │  │ John Doe - 45 yrs - Male     │ │
│  │ Case #2 - Completed  │  │  │ Jane Smith - 32 yrs - Female │ │
│  │ Case #3 - Under Rev  │  │  │ ...                          │ │
│  └──────────────────────┘  │  └──────────────────────────────┘ │
│                            │                                    │
└────────────────────────────┴────────────────────────────────────┘
```

### 8.4 Detection Screen Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                    DENTAL DETECTION                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │              IMAGE UPLOAD AREA                           │   │
│  │                                                          │   │
│  │    ┌────────────────────────────────────────────────┐   │   │
│  │    │                                                 │   │   │
│  │    │    Drop images here or click to upload         │   │   │
│  │    │           (JPG, JPEG, PNG - Max 15MB)          │   │   │
│  │    │                                                 │   │   │
│  │    └────────────────────────────────────────────────┘   │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────┐  ┌────────────────────────────────┐  │
│  │                      │  │                                 │  │
│  │   ORIGINAL IMAGE     │  │     DETECTED RESULT            │  │
│  │                      │  │                                 │  │
│  │   [Image Preview]    │  │   [Annotated Image]            │  │
│  │                      │  │                                 │  │
│  └──────────────────────┘  └────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  [🔍 Run Detection]      [📊 Analyze]     [💾 Save]     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Installation & Setup

### 9.1 Prerequisites

- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Python 3.8+
- Firebase Account
- Node.js (for Firebase CLI)
- Android Studio / Xcode (for mobile development)

### 9.2 Flutter App Setup

```bash
# 1. Clone the repository
git clone <repository-url>
cd dental_care

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase
# - Create a new Firebase project
# - Enable Authentication (Email/Password)
# - Enable Cloud Firestore
# - Enable Firebase Storage
# - Download google-services.json (Android)
# - Download GoogleService-Info.plist (iOS)
# - Run: flutterfire configure

# 4. Run the app
flutter run -d chrome  # For web
flutter run            # For mobile/desktop
```

### 9.3 AI Backend Setup

```bash
# 1. Navigate to AI folder
cd model/Dental-Disease-Detection

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
.\venv\Scripts\activate  # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. (Optional) Add YOLO model
# Place your trained model as 'best.pt' in the same directory

# 5. Run the API
python app.py
```

### 9.4 Environment Variables

Create a `.env` file (if needed):
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FLASK_API_URL=http://127.0.0.1:5000
```

---

## 10. Testing

### 10.1 Unit Tests

Location: `test/`

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### 10.2 Integration Tests

Location: `integration_test/`

```bash
# Run integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/app_navigation_test.dart
```

### 10.3 API Testing

```bash
# Test health endpoint
curl http://127.0.0.1:5000/

# Test detection endpoint
curl -X POST -F "image=@test_image.jpg" http://127.0.0.1:5000/coordinates

# Test analysis endpoint
curl -X POST -F "image=@test_image.jpg" http://127.0.0.1:5000/analyze
```

---

## 11. Future Enhancements

### 11.1 Planned Features

1. **Real-time Collaboration**
   - Multiple dentists can collaborate on cases
   - Share cases and get second opinions

2. **Mobile App Optimization**
   - Offline mode support
   - Push notifications
   - Camera integration for direct capture

3. **Advanced AI Features**
   - Treatment recommendation engine
   - Prognosis prediction
   - 3D tooth visualization

4. **Reporting & Export**
   - Comprehensive PDF reports
   - Insurance claim integration
   - Patient portal

5. **Telemedicine Integration**
   - Video consultations
   - Remote diagnosis

6. **Multi-language Support**
   - Urdu, Arabic, Spanish translations

### 11.2 Model Improvements

1. Train model on larger dental X-ray dataset
2. Add more disease categories
3. Implement severity classification
4. Add tooth segmentation
5. Panoramic X-ray support

---

## Appendix A: File Structure

```
dental_care/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase configuration
│   ├── controller/
│   │   └── auth_controller.dart     # Authentication logic
│   ├── models/
│   │   ├── analytics.dart
│   │   ├── app_user.dart
│   │   ├── appointment.dart
│   │   ├── case.dart
│   │   ├── lecture_note.dart
│   │   ├── patient.dart
│   │   ├── quiz.dart
│   │   ├── treatment_plan.dart
│   │   └── user_model.dart
│   ├── provider/
│   │   └── auth_provider.dart
│   ├── providers/
│   │   ├── analytics_provider.dart
│   │   ├── appointment_provider.dart
│   │   ├── case_provider.dart
│   │   ├── lecture_notes_provider.dart
│   │   ├── patient_provider.dart
│   │   ├── quiz_provider.dart
│   │   └── treatment_plan_provider.dart
│   ├── service/
│   │   ├── ai_analysis_service.dart
│   │   ├── firebase_service.dart
│   │   ├── file_parser_service.dart
│   │   └── report_generator.dart
│   ├── utils/
│   │   └── firebase_test.dart
│   └── view/
│       ├── dashboard_screen.dart
│       ├── dental_detection_screen.dart
│       ├── login.dart
│       ├── register.dart
│       ├── patients_screen.dart
│       ├── ai_quiz_screen.dart
│       ├── lecture_notes_screen.dart
│       ├── treatment_plan_screen.dart
│       ├── appointment_management_screen.dart
│       ├── settings_screen.dart
│       └── widgets/
├── model/
│   └── Dental-Disease-Detection/
│       ├── app.py                    # Flask API
│       ├── requirements.txt
│       └── best.pt                   # YOLO model (when available)
├── android/
├── ios/
├── web/
├── pubspec.yaml
├── firestore.rules
└── firebase.json
```

---

## Appendix B: Dependencies

### Flutter Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^4.2.1
  provider: ^6.1.5+1
  firebase_auth: ^6.1.2
  cloud_firestore: ^6.1.0
  firebase_storage: ^13.0.4
  supabase_flutter: ^2.5.1
  image_picker: ^1.2.0
  file_picker: ^8.1.6
  path_provider: ^2.1.4
  http: ^1.5.0
  dotted_border: ^3.1.0
  carousel_slider: ^5.1.1
  pdf: ^3.11.1
  printing: ^5.13.3
  share_plus: ^10.1.2
  archive: ^3.4.10
```

### Python Dependencies (requirements.txt)

```
flask>=2.0.0
flask-cors>=3.0.0
opencv-python>=4.5.0
numpy>=1.20.0
Pillow>=8.0.0
ultralytics>=8.0.0
```

---

## Appendix C: Contact & Support

**Project:** Dental Care - AI-Powered Dental Disease Detection System

**Version:** 1.0.0

**Last Updated:** February 2026

---

*This documentation is generated for Final Year Project submission purposes.*
