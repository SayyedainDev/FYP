# Permissions & Access Control Documentation

**Last Updated:** Current Session  
**System:** Dental Care Application (Firebase + Flutter)  
**Authentication:** Email/Password with Role-Based Access Control (RBAC)

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Role Definitions](#role-definitions)
3. [Permission Matrix](#permission-matrix)
4. [Feature Access by Role](#feature-access-by-role)
5. [Database Collection Access](#database-collection-access)
6. [Security Rules](#security-rules)
7. [Frontend Route Protection](#frontend-route-protection)
8. [Recommendations](#recommendations)

---

## System Overview

The application uses a **two-tier role-based access control system**:

- **Frontend Access Control** - Navigation/UI restrictions based on user role
- **Backend Access Control** - Firestore security rules enforcing creator-based permissions

### Current Architecture

```
User Authentication
        ↓
Role Assignment (Doctor/Student)
        ↓
Frontend Navigation Gate
        ↓
Firestore Security Rules
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `AuthProvider` | Manages role state and session persistence |
| `Firestore Rules` | Enforces backend access control |
| `MainLayout` | Controls screen visibility based on role |
| `Users Collection` | Stores user profile with role field |

---

## Role Definitions

### 👨‍⚕️ Doctor / Dentist Role

**Identifier:** `'Dentist'` (stored in `role` field)

**Use Cases:**
- Manage patient records and medical histories
- Upload and analyze dental scans
- Create and conduct quizzes for students
- Track student performance and provide feedback
- Create lecture notes and course materials
- Manage prescriptions
- Create and grade assignments

**Example Users:**
- Dental educators/instructors
- Practicing dentists using the platform for teaching
- Course administrators

### 👨‍🎓 Student Role

**Identifier:** `'Student'` (stored in `role` field)

**Use Cases:**
- Take and complete quizzes
- View quiz results and analytics
- Access lecture materials
- Submit assignments
- Track personal progress

**Example Users:**
- Dental students
- Undergraduate students learning dentistry
- Course participants

---

## Permission Matrix

### Quick Reference Table

| Operation | Doctor | Student | Notes |
|-----------|--------|---------|-------|
| **Create Cases** | ✅ | ❌ | Only doctors manage patient cases |
| **Create Patients** | ✅ | ❌ | Only doctors manage patient records |
| **Create Quizzes** | ✅ | ❌ | Only doctors create assessments |
| **Take Quizzes** | ❌ | ✅ | Only students take quizzes |
| **View Quiz Results** | ✅ (all) | ✅ (own) | Doctors see all, students see own |
| **Create Lecture Notes** | ✅ | ❌ | Content creation by doctors |
| **View Lecture Notes** | ✅ | ✅ | Both can read |
| **Create Assignments** | ✅ | ❌ | Doctors create assignments |
| **Submit Assignments** | ❌ | ✅ | Students submit work |
| **Grade Assignments** | ✅ | ❌ | Teachers grade submissions |
| **Write Prescriptions** | ✅ | ❌ | Medical records only |
| **View Analytics** | ✅ (class) | ✅ (personal) | Different views by role |
| **Access Disease Detection** | ✅ | ❌ | AI analysis tool for doctors |
| **Manage Students** | ✅ | ❌ | View class roster and performance |
| **Delete Own Records** | ✅ | ✅ (limited) | Creator-based deletion |

---

## Feature Access by Role

### 🏥 Doctor/Dentist Features

#### Navigation & Screens

| Screen | Access | Purpose |
|--------|--------|---------|
| **Overview** | ✅ | Dashboard with summary stats |
| **Disease Detection** | ✅ | AI-powered cavity/lesion detection |
| **Patients** | ✅ | Patient CRUD and management |
| **Scan History** | ✅ | Upload, manage, and archive cases |
| **Create Quiz** | ✅ | Generate quizzes from lecture notes |
| **My Quizzes** | ✅ | View and manage created quizzes |
| **Lecture Notes** | ✅ | Create and manage course materials |
| **Quiz Results** | ✅ | View all student attempt results |
| **Doctor Analytics** | ✅ | View class/student performance |
| **Doctor LMS Dashboard** | ✅ | Teaching dashboard with quick actions |
| **My Students** | ✅ | View enrolled students and performance |
| **Create Assignment** | ✅ | Create student homework/assignments |
| **Manage Assignments** | ✅ | Grade and review submissions |
| **Settings** | ✅ | Account and app settings |
| **Profile** | ✅ | View/edit "Dr. [Name]" profile |

#### Data Permissions

| Data Type | Create | Read | Update | Delete |
|-----------|--------|------|--------|--------|
| Cases | ✅ | ✅ all | ✅ own | ✅ own |
| Patients | ✅ | ✅ all | ✅ own | ✅ own |
| Quizzes | ✅ | ✅ all | ✅ own | ✅ own |
| Attempts | ❌ | ✅ all | ❌ | ❌ |
| Lecture Notes | ✅ | ✅ all | ✅ own | ✅ own |
| Prescriptions | ✅ | ✅ all | ✅ own | ✅ own |
| Scans | ✅ | ✅ all | ✅ own | ✅ own |
| Assignments | ✅ | ✅ all | ✅ own | ✅ own |
| Student Profiles | ❌ | ✅ all | ❌ | ❌ |

---

### 👨‍🎓 Student Features

#### Navigation & Screens

| Screen | Access | Purpose |
|--------|--------|---------|
| **Overview** | ✅ | Student LMS dashboard |
| **Available Quizzes** | ✅ | Browse and start quizzes |
| **My Results** | ✅ | View personal quiz attempts |
| **My Analytics** | ✅ | Personal performance tracking |
| **Assignments** | ✅ | View and submit assignments |
| **Notifications** | ✅ | Course notifications |
| **Settings** | ✅ | Account preferences |
| **Profile** | ✅ | View "[Name]" profile |
| **Lecture Notes** | ✅ | Access course materials |
| **Leaderboard** | ✅ | Peer performance comparison |
| **Lecture Notes (Details)** | ✅ | View learning materials |

#### Blocked Screens (Returns to Dashboard)

| Screen | Reason |
|--------|--------|
| Disease Detection | Doctor-only AI analysis tool |
| Patients | Doctor-only management |
| Scan History | Doctor-only case management |
| Create Quiz | Teacher/Doctor role required |
| My Quizzes | Teacher role required |
| Quiz Results | Teacher analytics only |
| Doctor Analytics | Instructor-level analytics |
| Doctor LMS Dashboard | Teaching features |
| Create Assignment | Teacher role required |
| Manage Assignments | Grading requires teacher role |

#### Data Permissions

| Data Type | Create | Read | Update | Delete |
|-----------|--------|------|--------|--------|
| Cases | ❌ | ❌ | ❌ | ❌ |
| Patients | ❌ | ❌ | ❌ | ❌ |
| Quizzes | ❌ | ✅ all | ❌ | ❌ |
| Attempts | ✅ | ✅ own | ✅ own | ✅ own |
| Lecture Notes | ❌ | ✅ all | ❌ | ❌ |
| Prescriptions | ❌ | ❌ | ❌ | ❌ |
| Scans | ❌ | ❌ | ❌ | ❌ |
| Assignments | ❌ | ✅ all | ✅ own | ❌ |
| Student Profile | ❌ | ✅ own | ✅ own | ❌ |

---

## Database Collection Access

### Current Firestore Structure with Permissions

```
Collection: users
├─ Document: {userId}
│  └─ Role: 'Dentist' | 'Student'
│  └─ FirstName, LastName, Email, etc.
│
├─ users/{userId}
│  ├─ read: Any authenticated user
│  ├─ write: Self only
│
── cases/{caseId}
│  ├─ dentistUid: Doctor creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Doctor who created (dentistUid match)
│  ├─ delete: Doctor who created (dentistUid match)
│
── patients/{patientId}
│  ├─ dentistUid: Doctor creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Doctor who created (dentistUid match)
│  ├─ delete: Doctor who created (dentistUid match)
│
── quizzes/{quizId}
│  ├─ dentistUid: Doctor creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Doctor who created (dentistUid match)
│  ├─ delete: Doctor who created (dentistUid match)
│
── attempts/{attemptId}
│  ├─ studentId: Student creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Student who created (studentId match)
│  ├─ delete: Student who created (studentId match)
│
── lectureNotes/{noteId}
│  ├─ dentistUid: Doctor creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Doctor who created (dentistUid match)
│  ├─ delete: Doctor who created (dentistUid match)
│
── prescriptions/{prescriptionId}
│  ├─ dentistUid: Doctor creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Doctor who created (dentistUid match)
│  ├─ delete: Doctor who created (dentistUid match)
│
── scans/{scanId}
│  ├─ dentistUid: Doctor creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Doctor who created (dentistUid match)
│  ├─ delete: Doctor who created (dentistUid match)
│
── assignments/{assignmentId}
│  ├─ dentistUid: Doctor creator ID
│  ├─ read: Any authenticated user
│  ├─ create: Any authenticated user
│  ├─ update: Doctor who created (dentistUid match)
│  ├─ delete: Doctor who created (dentistUid match)
```

---

## Security Rules

### Current Firestore Rules (`firestore.rules`)

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can read all user profiles, write only their own
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Cases: All auth can read, only creator (dentistUid) can write
    match /cases/{caseId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              request.auth.uid == resource.data.dentistUid;
    }

    // Patients: All auth can read, only creator can write
    match /patients/{patientId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              request.auth.uid == resource.data.dentistUid;
    }

    // Quizzes: All auth can read, only creator can write
    match /quizzes/{quizId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              request.auth.uid == resource.data.dentistUid;
    }

    // Attempts: All auth can read, only creator can write
    match /attempts/{attemptId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              request.auth.uid == resource.data.studentId;
    }

    // Lecture Notes: All auth can read, only creator can write
    match /lectureNotes/{noteId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              request.auth.uid == resource.data.dentistUid;
    }

    // Prescriptions: All auth can read, only creator can write
    match /prescriptions/{prescriptionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              request.auth.uid == resource.data.dentistUid;
    }

    // Scans: All auth can read, only creator can write
    match /scans/{scanId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              request.auth.uid == resource.data.dentistUid;
    }
  }
}
```

### Current Implementation Status

✅ **Implemented:**
- Creator-based access control (using `dentistUid` and `studentId`)
- Read access restricted to authenticated users only
- Write/Update/Delete restricted to resource creator
- Role field stored in Firestore users collection

⚠️ **Current Limitation:**
- Rules don't explicitly check user role from Firestore (no role-based filters)
- All authenticated users can CREATE resources in any collection
- Rules rely on UID matching rather than role matching

---

## Frontend Route Protection

### Navigation Gate in `MainLayout`

The application enforces role-based navigation on the frontend:

```dart
// Doctor-only pages
if (!isStudent)
  const NavDestination(label: 'Disease Detection', icon: Icons.auto_awesome),
if (!isStudent)
  const NavDestination(label: 'Patients', icon: Icons.people_outline),
if (!isStudent)
  const NavDestination(label: 'Scan History', icon: Icons.history_outlined),

// Student-only pages
const NavDestination(label: 'Available Quizzes', icon: Icons.quiz),
const NavDestination(label: 'My Results', icon: Icons.bar_chart),
```

### Screen Access Validation

```dart
// Block students from accessing doctor screens
if (isStudent && !_studentPages.contains(page)) {
  return const StudentLMSDashboard(); // Default to student dashboard
}
```

### Role Detection

```dart
final isStudent = auth.userRole.toLowerCase() == 'student';
```

---

## Recommendations

### 🔒 Security Enhancements

#### 1. **Enhance Firestore Rules with Explicit Role Checks**

**Current Issue:** Rules don't validate user role, allowing ANY authenticated user to create resources.

**Recommended Fix:**
```firestore
// Helper function to get user role from Firestore
function getUserRole() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid))
         .data.role;
}

// Apply role-based restrictions
match /quizzes/{quizId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && getUserRole() == 'Dentist';
  allow update, delete: if request.auth != null && 
                           request.auth.uid == resource.data.dentistUid &&
                           getUserRole() == 'Dentist';
}
```

#### 2. **Implement Custom Claims (Firebase Auth)**

**Benefit:** Faster role checking without Firestore reads

```javascript
// In Firebase Functions (backend)
admin.auth().setCustomUserClaims(uid, { role: 'Dentist' })
  .then(() => {
    console.log('Custom claims set for user', uid);
  });
```

#### 3. **Add Field-Level Security**

Restrict sensitive fields per role:
```firestore
match /patients/{patientId} {
  allow read: if request.auth != null;
  
  // Students can't see medical history or prescriptions
  allow read: if getUserRole() == 'Dentist';
  
  // Doctors can update patient records
  allow update: if request.auth.uid == resource.data.dentistUid &&
                   getUserRole() == 'Dentist';
}
```

#### 4. **Implement Audit Logging**

Create an audit collection to track sensitive operations:
```firestore
collection: /audit_logs/{logId}
- timestamp: operation time
- userId: who performed it
- userRole: their role
- operation: create/update/delete
- collection: which collection
- documentId: which document
```

---

### 📋 Feature-Based Permissions

#### Doctor/Dentist Additional Permissions (Future)

```
✅ Export student data as CSV
✅ Export analytics reports (PDF)
✅ Set quiz deadlines
✅ View student screen time/engagement
✅ Create class announcements
✅ Archive/restore old cases
✅ Issue certifications
✅ Access audit logs
```

#### Student Additional Permissions (Future)

```
✅ Download own reports
✅ Request assignment extensions
✅ Submit peer feedback
✅ View discussion forums
✅ Schedule office hours
✅ Delete own quiz attempts (soft delete with timestamp)
```

---

### 🛡️ Data Protection

#### Sensitive Fields by Role

| Field | Doctor | Student |
|-------|--------|---------|
| `medicalHistory` | ✅ R/W | ❌ |
| `prescriptions` | ✅ R/W | ❌ |
| `diagnoses` | ✅ R/W | ❌ |
| `analysisNotes` | ✅ R/W | ❌ |
| `studentId` | ✅ R | ✅ R (own) |
| `email` | ✅ R | ✅ R (own) |
| `quizAnswers` | ✅ R | ✅ R (own) |

---

### 📝 Compliance & Audit

#### Recommendations

1. **Regular Permission Audits**
   - Review access logs quarterly
   - Audit role assignments
   - Check for orphaned records (creator deleted, data remains)

2. **Data Retention Policy**
   - Archive old cases after 2 years
   - Auto-delete quiz attempts after course completion
   - Retain audit logs for 7 years (legal requirement)

3. **Access Request Logging**
   - Log all Create/Read/Update/Delete operations
   - Track failed access attempts
   - Monitor for suspicious patterns

4. **Role Transition Handling**
   - When user changes roles, audit all data access
   - Archive doctor-created content if doctor role revoked
   - Prevent students from accessing previous doctor permissions

---

## Summary

### Current State ✅
- Role-based navigation working correctly
- Creator-based data access implemented
- Two distinct role types (Doctor/Student) with clear separation
- Session persistence with role recovery

### Need Improvement ⚠️
- Add explicit role checks to Firestore rules
- Implement custom auth claims for performance
- Add audit logging system
- Implement field-level security for sensitive data
- Create role transition procedures

### Architecture Score: 7/10
- Clean role separation at frontend
- Functional creator-based backend permissions
- Missing explicit role validation at Firestore level
- No audit trail for compliance

---

## Quick Reference

### For Developers

**Check user role:**
```dart
final isDoctor = context.read<AuthProvider>().userRole.toLowerCase() == 'dentist';
final isStudent = context.read<AuthProvider>().userRole.toLowerCase() == 'student';
```

**Grant create permission (Firestore):**
```firestore
allow create: if request.auth != null && 
              get(/databases/$(database)/documents/users/$(request.auth.uid))
              .data.role == 'Dentist';
```

**Protect a screen:**
```dart
if (isStudent) {
  return const StudentDashboard(); // Redirect if student tries to access doctor screen
}
```

---

## Contact & Updates

For permission-related questions or to request feature access:
1. Review this document
2. Check Firestore rules implementation
3. Verify role assignment in user profile
4. Contact system administrator

**Document Version:** 1.0  
**Last Reviewed:** [Current Session]  
**Next Review:** Post-deployment review
