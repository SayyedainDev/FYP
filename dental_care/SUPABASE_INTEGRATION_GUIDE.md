# Supabase Integration Guide for Lecture Notes Storage

## Overview
This guide walks you through setting up Supabase Storage to replace Firebase Storage for lecture notes file uploads. Supabase offers **1GB free storage** and is much more cost-effective.

## Step 1: Create Supabase Account
1. Visit [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up with email or GitHub account
4. Create a new project:
   - Project name: `dental-care` (or your preferred name)
   - Database password: Create a strong password (save it!)
   - Region: Choose closest to you
   - Pricing plan: **Free** (required for 1GB storage)
5. Wait 5-10 minutes for project initialization

## Step 2: Get Supabase Credentials

1. Go to your project dashboard
2. Click **Settings** (gear icon) in the left sidebar
3. Select **API** from the submenu
4. Copy the following:
   - **Project URL**: `https://xxxxxxxxxxxx.supabase.co`
   - **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (long string)
5. **Keep these values safe!** You'll need them in the next step.

## Step 3: Create Storage Bucket

1. In your Supabase project, click **Storage** in the left sidebar
2. Click **Create a new bucket**
3. Configure:
   - **Bucket name**: `lecture_notes` (important: must be exactly this)
   - **Public bucket**: ✅ **YES** (required for public URLs)
   - Click **Create bucket**
4. Your bucket is now ready!

## Step 4: Set Bucket Policies (Authentication)

1. In the Storage section, click the `lecture_notes` bucket
2. Click **Policies** tab
3. Click **+ New Policy** and select **CREATE a policy**
4. Choose **CREATE** for the operation
5. Configure:
   - **Policy name**: `Allow authenticated users to create`
   - **Apply to**: All users
   - **Expression**: Leave as default (`true`)
   - Click **Review**
   - Click **Save policy**

6. Repeat to create **SELECT** policy:
   - Operation: SELECT
   - Policy name: `Allow authenticated users to read`
   - Expression: `true`

7. Repeat to create **UPDATE** policy:
   - Operation: UPDATE
   - Policy name: `Allow authenticated users to update`
   - Expression: `true`

8. Repeat to create **DELETE** policy:
   - Operation: DELETE
   - Policy name: `Allow authenticated users to delete`
   - Expression: `true`

## Step 5: Update Flutter Configuration

### 5.1 Update pubspec.yaml

The `supabase_flutter: ^2.5.1` dependency has already been added to your `pubspec.yaml`.

Run:
```bash
flutter pub get
```

### 5.2 Initialize Supabase in main.dart

Open `lib/main.dart` and uncomment the Supabase initialization code. Replace the placeholders with your actual credentials:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase Initialized Successfully');

    // Initialize Supabase for lecture notes storage
    await Supabase.initialize(
      url: 'https://your-project.supabase.co',  // ← Replace with your URL
      anonKey: 'your-anon-key',                  // ← Replace with your Anon Key
      authCallbackUrlScheme: 'io.supabase.flutter-examples',
    );
    debugPrint('✅ Supabase Initialized Successfully');
    
    // ... rest of initialization
```

**Important:** Replace `https://your-project.supabase.co` and `your-anon-key` with the values from Step 2.

## Step 6: Replace Lecture Notes Provider

Your new provider is ready at: `lib/providers/lecture_notes_provider_supabase.dart`

To activate it:

1. **Option A - Gradual Migration (Recommended)**:
   - Keep both providers during testing
   - Switch import in screens when ready

2. **Option B - Direct Replacement**:
   - Backup old provider: `git checkout lib/providers/lecture_notes_provider.dart`
   - Replace:
     ```bash
     cp lib/providers/lecture_notes_provider_supabase.dart lib/providers/lecture_notes_provider.dart
     ```
   - Update `lib/main.dart` imports if needed

3. **What Changed**:
   - Files now upload to Supabase Storage instead of Firebase Storage
   - File paths: `lecture_notes/{dentistUid}/{noteId}/{fileName}`
   - Metadata still stored in Firestore (no changes)
   - All methods (`createLectureNoteWithFile`, `createLectureNoteWithFileBytes`, etc.) work identically

## Step 7: Test Upload Flow

1. **Start the app**: `flutter run`
2. **Login** with your dentist account
3. **Navigate to Lecture Notes** → Upload Notes
4. **Select a file** (PDF, DOCX, PPTX, image, or video)
5. **Enter title and details**
6. **Click "Upload Lecture Note"**
7. **Verify**:
   - Progress bar shows upload progress
   - Success toast appears
   - File appears in "My Library" tab
   - File is downloadable and opens correctly

## Troubleshooting

### "Supabase not initialized" Error
- ✅ Did you uncomment and update the Supabase initialization in `main.dart`?
- ✅ Did you replace URL and Anon Key with actual values?
- ✅ Did you run `flutter pub get`?

### "Upload fails with 403 Forbidden"
- ✅ Is the bucket PUBLIC? (Check Storage → Bucket settings)
- ✅ Are the policies created? (Must have CREATE, SELECT, UPDATE, DELETE)
- ✅ Is the file path correct? (Should be `{dentistUid}/{noteId}/{fileName}`)

### "File uploaded but doesn't appear in library"
- ✅ Check Firestore: Document should be in `lecture_notes` collection
- ✅ Check file URL: Should start with `https://xxxxx.supabase.co/storage/v1/object/public/lecture_notes/...`
- ✅ Check timestamps: `createdAt` should be recent

### Upload Stuck at 0%
- ✅ Check file size: Each file should be < 100MB
- ✅ Check network: Ensure connection is stable
- ✅ Check Supabase status: Visit status.supabase.com
- ✅ Check bucket name: Must be exactly `lecture_notes` (lowercase, underscore)

## File Size Limits

- **Per file**: No per-file limit in Supabase (practical limit ~100MB over HTTP)
- **Per project (Free tier)**: 1GB total
- **Supported formats**:
  - Documents: PDF, DOCX, DOC, PPTX, PPT, TXT
  - Images: JPG, JPEG, PNG, GIF
  - Videos: MP4, AVI, MOV, MKV

## Security

- ✅ Bucket is PUBLIC (files are accessible via URL)
- ✅ File paths include `dentistUid` for organization
- ✅ Firestore rules prevent unauthorized access to metadata
- ✅ Files are organized by user and note ID

## Cost Comparison

| Provider | Storage | Cost | Notes |
|----------|---------|------|-------|
| Firebase Storage | 5GB | Free |  Monthly egress cost after free tier |
| **Supabase** | **1GB** | **Free** | **No egress costs, perfect for MVP** |
| Backblaze B2 | Unlimited | $0.006/GB | Requires monthly $ |

## Next Steps

1. ✅ Create Supabase account
2. ✅ Get credentials (URL + Anon Key)
3. ✅ Create and configure bucket
4. ✅ Update `main.dart` with credentials
5. ✅ Test upload flow
6. ✅ Delete test files from Supabase if needed

## Support

If you encounter issues:
1. Check Supabase logs: Project Settings → Logs
2. Check Flutter console: `flutter run` output
3. Verify bucket permissions: Storage → Policies
4. Verify bucket is public: Storage → Bucket settings → Visibility

---

**Setup Time**: ~10 minutes  
**When Ready**: Uncomment Supabase code in `main.dart` and you're done! 🚀
