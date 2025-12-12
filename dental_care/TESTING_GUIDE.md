# PalPath Testing Guide

## Quick Start Testing

### Test 1: User Authentication ✅
**Objective**: Verify login and user session management

**Steps**:
1. Launch app
2. Enter credentials (or register new account)
3. Click "Sign In"
4. Should navigate to Dashboard

**Expected Results**:
- ✅ User logged in successfully
- ✅ Dashboard displays welcome message
- ✅ Sidebar shows user info
- ✅ Can navigate to other screens

**Common Issues**:
- Firebase not initialized → Check Firebase config in main.dart
- Wrong credentials → Check Firebase Console users list
- Network error → Check internet connection

---

### Test 2: Add Patient ✅
**Objective**: Verify patient creation and real-time display

**Steps**:
1. On Patients screen, click "Add New Patient"
2. Fill in:
   - Name: "John Doe"
   - DOB: "1990-05-15"
   - Gender: "Male"
   - Phone: "555-1234"
   - Email: "john@example.com"
   - Notes: "Regular patient"
3. Click "Add Patient"

**Expected Results**:
- ✅ Success message appears
- ✅ Patient appears in grid immediately (no refresh needed)
- ✅ Patient shows name, age, gender, phone, email
- ✅ Patient card displays initials in avatar

**Firestore Verification**:
- Go to Firebase Console → Firestore
- Check `/patients` collection
- Verify document contains all fields
- Verify `dentistUid` matches logged-in user

**Common Issues**:
- Dropdown validation error → Check date format (YYYY-MM-DD)
- Empty field error → Fill all required fields
- Patient not appearing → Check StreamBuilder initialization

---

### Test 3: View Patient Details ✅
**Objective**: Verify patient information display

**Steps**:
1. On Patients screen, click on patient card
2. Dialog should open showing all patient information

**Expected Results**:
- ✅ Dialog shows: Name, Age, Gender, DOB, Phone, Email, Notes, Created Date
- ✅ All fields display correct values
- ✅ Close button works

**Common Issues**:
- Dialog not appearing → Check patient card onTap callback
- Missing fields → Verify Patient model has all getters

---

### Test 4: Create Case (Diagnose) ✅
**Objective**: Verify case creation with images and AI analysis

**Steps**:
1. Navigate to "Upload New Scan"
2. Select patient from dropdown
3. Fill in:
   - Case Title: "Annual Checkup"
   - Tooth Numbers: "14, 15"
   - Symptoms: "Slight sensitivity"
4. Click image upload area
5. Select 1-3 X-ray images
6. Click "Diagnose Case"

**Expected Results**:
- ✅ Dropdown shows available patients
- ✅ Image thumbnails appear after selection
- ✅ Loading spinner shows during analysis
- ✅ AI analysis results appear on right side:
  - Cavity detection status
  - Confidence percentage
  - Per-tooth analysis
  - Recommendation
- ✅ Success message appears
- ✅ Form clears after submission

**Firestore Verification**:
- Check `/patients/{patientId}/cases` - should see new case
- Check `/cases` - should see case document
- Verify `aiAnalysis` object contains analysis data

**Storage Verification**:
- Firebase Console → Storage
- Check: `dentists/{uid}/patients/{patientId}/cases/`
- Verify image files are uploaded

**Common Issues**:
- Patient not showing in dropdown → Check if patient is linked to user
- "Analyze" button not working → Check if patient and images selected
- Images not uploading → Check Firebase Storage permissions
- Analysis not showing → Check if dummy analysis logic ran

---

### Test 5: View Case History ✅
**Objective**: Verify case list display with real-time updates

**Steps**:
1. Navigate to "Scan History"
2. Should see created cases in list
3. Add another case from different patient
4. History should update in real-time

**Expected Results**:
- ✅ All created cases appear in list
- ✅ Cases show: Patient name, date, tooth numbers, cavity status
- ✅ Cases ordered by date (newest first)
- ✅ Status badges show "Pending" or "Cavity Detected" or "Healthy"
- ✅ New cases appear without refresh

**Real-time Test**:
- Open History on phone 1
- Create case on phone 2 (or different tab)
- History on phone 1 should update automatically

**Common Issues**:
- Cases not appearing → Check CaseProvider loading
- Old cases missing → Check orderBy query
- Not updating in real-time → Check StreamBuilder implementation
- "Error loading" message → Check Firestore permissions

---

### Test 6: View Case Details ✅
**Objective**: Verify detailed case information and image gallery

**Steps**:
1. In History screen, click case card
2. View case details dialog
3. Click image icon to view images
4. Gallery should show all X-ray images

**Expected Results**:
- ✅ Details dialog shows all case information
- ✅ Images load correctly in gallery
- ✅ Can scroll through multiple images
- ✅ Image loading indicator appears while loading
- ✅ Error placeholder for failed images

**Common Issues**:
- Details not showing → Check dialog implementation
- Images not loading → Check URLs in Firestore
- Gallery grid broken → Check GridView configuration

---

### Test 7: Dashboard Statistics ✅
**Objective**: Verify real-time stat display and patient count

**Steps**:
1. Go to Dashboard
2. Verify statistics show:
   - Total Patients
   - Total Scans
   - Cavities Detected
   - Healthy Scans
3. Add new patient
4. Statistics should update

**Expected Results**:
- ✅ All stats display correct counts
- ✅ Recent patients section shows up to 3 patients
- ✅ Stats update in real-time when new data added
- ✅ Empty state shows if no data

**Calculation Verification**:
- Total Patients = number of patient documents
- Total Scans = number of case documents
- Cavities Detected = cases with `hasCavity: true`
- Healthy Scans = cases with `hasCavity: false`

**Common Issues**:
- Stats showing 0 → Check if patients/cases linked to user
- Stats not updating → Check StreamBuilder in dashboard
- Recent patients missing → Check patient ordering

---

### Test 8: End-to-End Complete Flow ✅
**Objective**: Verify entire workflow from patient add to history view

**Steps**:
1. Start on Dashboard
2. Navigate to Patients
3. Add new patient "Alice Smith"
4. Verify appears in patient list
5. Navigate to Create Case
6. Select "Alice Smith" from dropdown
7. Upload 2 X-ray images
8. Click "Diagnose Case"
9. View AI analysis results
10. Navigate to History
11. Find case in history list
12. View case details
13. View images in gallery

**Expected Results**:
- ✅ Patient appears immediately after creation
- ✅ Patient selectable in Create Case dropdown
- ✅ Images upload without error
- ✅ AI analysis shows with dummy data
- ✅ Case appears in history immediately
- ✅ All details accessible
- ✅ Dashboard patient count increases

**Data Verification**:
- Firestore: Patient doc created
- Firestore: Case doc in subcollection
- Firestore: Case also in main collection
- Storage: Images uploaded
- Dashboard: Patient count +1
- Dashboard: Case count +1

---

## Troubleshooting Matrix

| Issue | Possible Cause | Solution |
|-------|---|---|
| Patient dropdown empty | No patients created | Create patient first |
| Patient not in dropdown | Patient has different dentistUid | Check user authentication |
| Images not uploading | Firebase Storage not configured | Check Storage rules |
| Analyze button frozen | Network issue | Check internet, restart app |
| Case not saving | Firestore permissions | Check Firestore rules |
| History not updating | StreamBuilder not listening | Restart app |
| AI results not showing | Dummy analysis logic error | Check console logs |
| App crashes on patient add | Validation error | Check Patient model |

---

## Performance Benchmarks

**Target Performance**:
- Patient add: < 2 seconds (including upload)
- Case creation: < 5 seconds (including image upload and analysis)
- History load: < 1 second
- Real-time update: < 500ms

**Measurement**:
1. Open Dart DevTools → Timeline
2. Perform action
3. Check duration in timeline
4. Compare with targets

---

## Debug Tips

### Enable Debug Logs
Add to each provider:
```dart
debugPrint('Event: $data');
```

### Firebase Console Monitoring
1. Go to Firebase Console
2. Check Firestore usage
3. Monitor read/write operations
4. Check authentication logs

### Storage Inspector
1. Firebase Console → Storage
2. Browse file structure
3. Check file sizes
4. Verify download URLs

### Dart DevTools
```bash
flutter pub global activate devtools
devtools
# In browser, click "Dart & Flutter" dropdown
# Select your Flutter app
```

---

## Regression Testing Checklist

Before deployment, verify:

- [ ] Login/logout works
- [ ] Add patient successful
- [ ] Patient displays immediately
- [ ] Create case successful
- [ ] Images upload and display
- [ ] AI analysis shows
- [ ] Case saves to Firestore (both locations)
- [ ] History updates in real-time
- [ ] Dashboard stats correct
- [ ] No console errors
- [ ] No unhandled exceptions
- [ ] Network errors handled gracefully
- [ ] Empty states display correctly
- [ ] Loading indicators show
- [ ] Error messages clear

---

## Test Data

### Sample Patient
```
Name: Dr. Test Patient
DOB: 1985-03-20
Gender: Female
Phone: 555-0123
Email: patient@example.com
Notes: Test patient for verification
```

### Sample Case
```
Title: Routine Checkup
Teeth: 14, 15, 16
Symptoms: Regular 6-month checkup
```

---

**Last Updated**: November 9, 2025
**Created**: November 9, 2025
