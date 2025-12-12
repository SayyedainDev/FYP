# PalPath Quick Reference Guide

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- Firebase project configured
- Firebase credentials in `lib/firebase_options.dart`

### Installation
```bash
cd /home/bao/Pictures/FYP/dental_care
flutter pub get
flutter run -d linux
```

## 📱 App Structure

### Main Entry Point
- `lib/main.dart` - App initialization with Firebase and Providers

### Authentication
- Email/Password login required
- Firebase Auth integration
- Session stored in AuthProvider

### Three Main Flows

#### 1. Patient Management
```
Patients Screen
├─ View all patients (real-time list)
├─ Add new patient (dialog form)
└─ View patient details (expandable dialog)
```

**Key File**: `lib/view/patients_screen.dart`
**Provider**: `PatientProvider`

#### 2. Case Creation
```
Create Case Screen
├─ Select patient from dropdown
├─ Fill case details (title, teeth, symptoms)
├─ Upload X-ray images (multi-select)
├─ Analyze (3 second dummy analysis)
└─ View AI results
```

**Key File**: `lib/view/create_case_screen.dart`
**Storage**: Firebase Storage (Firebase/cases path)
**Results**: Dummy cavity detection data

#### 3. View History
```
History Screen
├─ Real-time case list
├─ Filter by patient/status/date
├─ View case details
└─ View X-ray gallery
```

**Key File**: `lib/view/history_screen.dart`
**Provider**: `CaseProvider`

## 🔧 Key Configuration

### Firebase Setup
1. Create Firebase project at https://firebase.google.com
2. Create Firestore database
3. Enable Storage
4. Set authentication providers (Email/Password)
5. Download `google-services.json`

### Collections & Indexes
```
/patients
  - Index: dentistUid, createdAt
  - Subcollection: cases

/cases
  - Index: dentistUid, createdAt
  - Index: patientId, createdAt

/users
  - No special indexes needed
```

## 📊 Data Models

### Patient
```dart
Patient {
  id: String,
  dentistUid: String,
  name: String,
  dob: DateTime,
  gender: String,
  contactPhone: String,
  contactEmail: String,
  notes: String,
  createdAt: DateTime,
  age: int (calculated)
}
```

### Case
```dart
Case {
  id: String,
  dentistUid: String,
  patientId: String,
  patientName: String,
  caseTitle: String,
  toothNumbers: String,
  symptoms: String,
  imageUrls: List<String>,
  aiAnalysis: Map {
    status: String,
    hasCavity: bool,
    confidence: double,
    toothAnalysis: Map,
    recommendation: String
  },
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

## 🎨 UI Components

### Color Scheme
- Primary: `Color(0xFF4A90E2)` (Blue)
- Background: `Color(0xFFF8F9FA)` (Light Gray)
- Text: `Color(0xFF212121)` (Dark Gray)
- Success: `Color(0xFF4CAF50)` (Green)
- Error: `Color(0xFFFF5252)` (Red)
- Warning: `Colors.orange`

### Card Styling
```dart
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.grey.shade300, width: 1),
  boxShadow: [BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 20,
    spreadRadius: 1,
    offset: Offset(0, 6),
  )]
)
```

## 🔄 State Management

### Provider Pattern
```
AuthProvider
├─ currentUserId (getter)
├─ uid (getter)
└─ signIn/signUp/signOut methods

PatientProvider
├─ patients (list)
├─ fetchPatients(uid)
├─ listenToPatients(uid)
├─ addPatient(patient, uid)
└─ getRecentPatients(limit)

CaseProvider
├─ cases (list with filters)
├─ fetchCases()
├─ listenToCases()
├─ createCase(...)
└─ cavitiesDetected (count)
```

## 📡 API Integration Points

### Current APIs
- Firebase Auth (authentication)
- Firestore (database)
- Firebase Storage (image storage)

### Future APIs to Integrate
1. **ML Model API**
   - Endpoint: POST /api/analyze
   - Input: Image URLs, patient ID, tooth numbers
   - Output: Cavity detection, confidence, recommendations

2. **Supabase Storage**
   - Replace Firebase Storage
   - Follow SUPABASE_INTEGRATION_GUIDE.md

## 🧪 Common Testing Scenarios

### Add Patient Flow
```
1. Patients Screen
2. Click "Add New Patient"
3. Fill form
4. Click "Add Patient"
5. Verify in list (should appear immediately)
```

### Create Case Flow
```
1. Create Case Screen
2. Select patient from dropdown
3. Fill case details
4. Upload X-ray images
5. Click "Diagnose Case"
6. View AI analysis (appears after 3 seconds)
7. Check Firestore for saved data
```

### Verify Real-time Update
```
1. History Screen on Browser 1
2. Create Case on Browser 2
3. Case should appear on Browser 1 automatically
4. (No manual refresh needed)
```

## 🐛 Debugging Tips

### Check Console Logs
```bash
# In terminal
flutter run -d linux

# Logs will show:
# - Provider notifications
# - Firebase operations
# - Image upload progress
```

### Firebase Console Debugging
1. Go to Firebase Console
2. Firestore → Data
3. Verify documents are created correctly
4. Check Storage → See uploaded images
5. Authentication → View user sessions

### Dart DevTools
```bash
flutter pub global activate devtools
devtools
# Then open browser and connect to your Flutter app
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App initialization |
| `lib/provider/auth_provider.dart` | Authentication state |
| `lib/providers/patient_provider.dart` | Patient management |
| `lib/providers/case_provider.dart` | Case management |
| `lib/models/patient.dart` | Patient data model |
| `lib/models/case.dart` | Case data model |
| `lib/view/patients_screen.dart` | Patient list screen |
| `lib/view/create_case_screen.dart` | Case creation screen |
| `lib/view/history_screen.dart` | Case history screen |
| `lib/view/dashboard_screen.dart` | Dashboard screen |

## ⚙️ Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies |
| `analysis_options.yaml` | Linting rules |
| `android/app/google-services.json` | Firebase config |
| `lib/firebase_options.dart` | Firebase credentials |

## 📚 Documentation

Read these in order:
1. `COMPLETION_SUMMARY.md` - Overview of what's done
2. `DATA_FLOW_ARCHITECTURE.md` - Understanding data flow
3. `IMPLEMENTATION_SUMMARY.md` - Implementation details
4. `TESTING_GUIDE.md` - How to test
5. `SUPABASE_INTEGRATION_GUIDE.md` - Next steps

## 🚨 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| App crashes on launch | Check Firebase config in firebase_options.dart |
| "No patients found" in dropdown | Add patient first on Patients screen |
| Images not uploading | Check Firebase Storage permissions |
| Dashboard shows 0 patients | Check if patients have correct dentistUid |
| History not updating | Restart app to reinitialize StreamBuilder |
| Patient dropdown stuck | Check Patient model equality operator |

## 📞 Contact & Support

For issues or questions:
1. Check the documentation files
2. Review TESTING_GUIDE.md for known issues
3. Check Firebase Console for error messages
4. Review console logs in Flutter terminal

## ✅ Pre-launch Checklist

Before going live:
- [ ] Test all flows end-to-end
- [ ] Check Firebase quotas
- [ ] Verify Firestore security rules
- [ ] Test on real device
- [ ] Check network error handling
- [ ] Verify image upload limits
- [ ] Test with multiple users
- [ ] Load test the app
- [ ] Security audit

## 🎯 Version

**Current Version**: 1.0
**Last Updated**: November 9, 2025
**Status**: Ready for Testing

## 📝 Future Roadmap

**Phase 1** (Current)
- [x] Core CRUD operations
- [x] Real-time updates
- [x] Dummy AI analysis

**Phase 2** (Next)
- [ ] Real ML model integration
- [ ] Supabase Storage migration
- [ ] Patient edit/delete functionality

**Phase 3** (Later)
- [ ] Patient messaging
- [ ] Appointment scheduling
- [ ] Treatment plan tracking

---

**Last Updated**: November 9, 2025
**Quick Reference Version**: 1.0
