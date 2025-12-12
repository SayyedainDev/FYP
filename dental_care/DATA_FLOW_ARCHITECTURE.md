# PalPath - Data Flow and Architecture

## Complete Application Flow

### 1. User Authentication Flow
```
Login Screen
    ↓
Firebase Auth (Email/Password)
    ↓
AuthProvider stores: uid, email, currentUserId
    ↓
Navigate to Main Layout
    ↓
Dashboard Loaded
```

### 2. Patient Management Flow
```
Dashboard / Patients Screen
    ↓
User clicks "Add New Patient"
    ↓
Add Patient Dialog opens
    ↓
User fills: Name, DOB, Gender, Phone, Email, Notes
    ↓
Firebase Firestore creates document in /patients collection
    ↓
PatientProvider.addPatient() called
    ↓
Sets dentistUid: currentUser.uid
    ↓
Updates user document: patientIds array
    ↓
StreamBuilder detects change
    ↓
Patient list updates in real-time
```

### 3. Case Creation Flow
```
Create Case Screen (Upload New Scan)
    ↓
User selects Patient from dropdown
    ↓
Dropdown StreamBuilder queries:
    /patients?where(dentistUid == currentUserId)
    ↓
User fills: Case Title, Tooth Numbers, Symptoms
    ↓
User selects X-ray images (file picker)
    ↓
User clicks "Diagnose Case"
    ↓
┌─────────────────────────────────────────┐
│ Image Upload Process                     │
│ ├─ Upload each image to Storage          │
│ ├─ Get download URLs                     │
│ └─ Store in case document                │
└─────────────────────────────────────────┘
    ↓
AI Analysis (simulated for now)
    ├─ Random cavity detection
    ├─ Confidence score 85-95%
    └─ Per-tooth analysis
    ↓
┌─────────────────────────────────────────┐
│ Save to Firestore (Dual Structure)      │
│ ├─ Subcollection:                        │
│ │  /patients/{id}/cases/{caseId}        │
│ └─ Main collection:                      │
│    /cases/{caseId}                       │
└─────────────────────────────────────────┘
    ↓
Display AI Analysis Results
    ├─ Show cavity detection
    ├─ Display confidence %
    ├─ Show tooth analysis
    └─ Show recommendations
    ↓
Success Message & Clear Form
```

### 4. Case History Flow
```
History / Scan History Screen
    ↓
StreamBuilder queries:
    /cases?orderBy(caseDate, desc)
    ↓
Cases displayed in list
    ↓
User can:
    ├─ Click case to view details
    ├─ Click images to view gallery
    └─ Filter by date/status
    ↓
Real-time updates when new cases added
```

### 5. Dashboard Flow
```
Dashboard Screen
    ↓
Initialize data:
    ├─ PatientProvider.fetchPatients()
    ├─ CaseProvider.fetchCases()
    └─ Load recent patients
    ↓
Display Statistics:
    ├─ Total Patients (StreamBuilder)
    ├─ Total Cases (StreamBuilder)
    ├─ Cavities Detected (StreamBuilder)
    └─ Healthy Cases (StreamBuilder)
    ↓
Display Recent Patients
    ├─ Query: /patients
    │         ?orderBy(createdAt, desc)
    │         ?limit(3)
    └─ Show patient cards
    ↓
Real-time updates when:
    ├─ New patient added
    ├─ New case created
    └─ Case analysis updated
```

## Database Schema

### Collections

#### /patients
```json
{
  "id": "patient_abc123",
  "dentistUid": "dentist_uid_123",
  "name": "John Doe",
  "dob": "1990-05-15",
  "gender": "Male",
  "contactPhone": "555-1234",
  "contactEmail": "john@example.com",
  "notes": "Regular patient, routine checkup",
  "createdAt": "2025-11-09T10:30:00Z"
}
```

#### /patients/{patientId}/cases (Subcollection)
```json
{
  "id": "case_xyz789",
  "dentistUid": "dentist_uid_123",
  "caseTitle": "Annual Checkup",
  "toothNumbers": "14, 15",
  "symptoms": "Slight sensitivity in tooth 14",
  "imageUrls": [
    "https://storage.googleapis.com/...",
    "https://storage.googleapis.com/..."
  ],
  "aiAnalysis": {
    "status": "Analysis Complete",
    "hasCavity": true,
    "confidence": 0.87,
    "toothAnalysis": {
      "tooth_14": {
        "condition": "Cavity Detected",
        "confidence": 0.92
      },
      "tooth_15": {
        "condition": "Healthy",
        "confidence": 0.88
      }
    },
    "recommendation": "Schedule filling for tooth 14",
    "analyzedAt": "2025-11-09T10:35:00Z"
  },
  "createdAt": "2025-11-09T10:34:00Z",
  "updatedAt": "2025-11-09T10:35:00Z"
}
```

#### /cases (Main collection for querying)
```json
{
  "id": "case_xyz789",
  "dentistUid": "dentist_uid_123",
  "patientId": "patient_abc123",
  "patientName": "John Doe",
  "caseTitle": "Annual Checkup",
  "toothNumbers": "14, 15",
  "symptoms": "Slight sensitivity in tooth 14",
  "imageUrls": [...],
  "aiAnalysis": {...},
  "createdAt": "2025-11-09T10:34:00Z",
  "updatedAt": "2025-11-09T10:35:00Z"
}
```

#### /users
```json
{
  "id": "dentist_uid_123",
  "email": "dentist@example.com",
  "displayName": "Dr. Test",
  "photoURL": "https://...",
  "patientIds": ["patient_abc123", "patient_def456"],
  "createdAt": "2025-11-01T00:00:00Z"
}
```

## Storage Structure

### Firebase Storage (Current)
```
dentists/
  └── {dentistUid}/
      └── patients/
          └── {patientId}/
              └── cases/
                  ├── {timestamp}_image_0.jpg
                  ├── {timestamp}_image_1.jpg
                  └── ...
```

### Supabase Storage (Target)
```
dental-xrays/
  └── dentists/
      └── {dentistUid}/
          └── patients/
              └── {patientId}/
                  └── cases/
                      ├── {timestamp}_image_0.jpg
                      ├── {timestamp}_image_1.jpg
                      └── ...
```

## API Integration Points

### 1. AI Analysis API (Future)
```
POST /api/analyze
Headers:
  - Content-Type: application/json
  - Authorization: Bearer {token}

Request Body:
{
  "imageUrls": ["url1", "url2", ...],
  "patientId": "patient_abc123",
  "toothNumbers": "14, 15"
}

Response:
{
  "status": "Analysis Complete",
  "hasCavity": true,
  "confidence": 0.87,
  "toothAnalysis": {
    "tooth_14": {
      "condition": "Cavity Detected",
      "confidence": 0.92
    }
  },
  "recommendation": "Schedule filling"
}
```

### 2. User Management (Firebase Auth)
```
POST /sign-up
Body:
  - email: string
  - password: string
  - displayName: string

POST /sign-in
Body:
  - email: string
  - password: string

GET /user (authenticated)
Returns:
  - uid, email, displayName, etc.

POST /sign-out
```

## State Management (Provider Pattern)

### AuthProvider
```dart
- currentUserId: String?
- uid: String?
- email: String?
- displayName: String?
- signIn(email, password)
- signUp(email, password, name)
- signOut()
- getCurrentUser()
```

### PatientProvider
```dart
- _patients: List<Patient>
- patients: List<Patient> (getter)
- fetchPatients(dentistUid)
- listenToPatients(dentistUid)
- addPatient(patient, dentistUid)
- updatePatient(patient, dentistUid)
- deletePatient(patientId, dentistUid)
- getPatientById(id)
- getRecentPatients(limit)
```

### CaseProvider
```dart
- _cases: List<Case>
- cases: List<Case> (getter with filters)
- fetchCases()
- listenToCases()
- createCase(...)
- updateCaseAnalysis(caseId, analysisData)
- fetchCasesForPatient(patientId)
- setFilters(patientId, status, dateRange)
- cavitiesDetected: int
- healthyCases: int
```

## Real-time Update Flow

### StreamBuilder Pattern
```
Widget: History Screen
    ↓
StreamBuilder<QuerySnapshot>
    ↓
stream: FirebaseFirestore.instance
        .collection('cases')
        .orderBy('caseDate', descending: true)
        .snapshots()
    ↓
Listen for changes
    ↓
Automatically rebuild when:
    ├─ New case added
    ├─ Case updated
    └─ Case deleted
    ↓
No manual refresh needed
```

### Listeners
```
PatientProvider.listenToPatients(uid):
  - Listens to /patients?where(dentistUid == uid)
  - Notifies listeners when patients change
  - Automatic UI refresh

CaseProvider.listenToCases():
  - Listens to /cases
  - Notifies listeners when cases change
  - Automatic UI refresh
```

## Performance Considerations

### Queries Optimized
- `patients?where(dentistUid == uid)` → Indexed
- `cases?where(dentistUid == uid)` → Indexed
- `cases?orderBy(caseDate)` → Indexed
- `patients?orderBy(createdAt)?limit(3)` → Indexed

### Caching
- Patient list cached in _CreateCaseScreenState
- Recent patients cached for 5 minutes
- Images lazy-loaded in gallery view

### Pagination
- History screen: No pagination (small dataset)
- Patient list: No pagination (usually < 100 patients)
- Dashboard: Shows only recent items

## Error Handling

### Firebase Errors
```
- 401 Unauthorized → Redirect to login
- 403 Forbidden → Show permission error
- 404 Not Found → Show "No data" message
- 500 Server Error → Show generic error
```

### Network Errors
```
- No internet → Show offline message
- Timeout → Show retry button
- Connection error → Show reconnect UI
```

### Validation Errors
```
- Empty patient name → Show field error
- Invalid date → Show format error
- No images → Show upload prompt
```

---

**Last Updated**: November 9, 2025
**Version**: 1.0
**Status**: Ready for testing
