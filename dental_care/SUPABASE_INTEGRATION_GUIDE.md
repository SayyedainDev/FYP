# Supabase Storage Integration Guide

## Current State
The application currently uses Firebase Storage for image uploads in the create_case_screen.dart file. We'll migrate this to Supabase Storage.

## Step 1: Add Supabase Package

Add to `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^1.10.0
  supabase: ^1.10.0
```

Then run:
```bash
flutter pub get
```

## Step 2: Initialize Supabase

Update `lib/main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // ... rest of initialization
}
```

Get your credentials from: https://app.supabase.com/project/[project-ref]/settings/api

## Step 3: Create Supabase Storage Bucket

1. Go to Supabase dashboard → Storage
2. Create new bucket: `dental-xrays`
3. Set to Private (restrict access)
4. Enable bucket for authenticated users

## Step 4: Create Supabase Service

Create `lib/service/supabase_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Upload image to Supabase Storage
  /// Returns download URL if successful, null otherwise
  static Future<String?> uploadImage({
    required String fileName,
    required List<int> fileBytes,
    required String bucketName,
    required String folderPath,
  }) async {
    try {
      final path = '$folderPath/$fileName';

      // Upload file
      await _client.storage
          .from(bucketName)
          .uploadBinary(path, fileBytes);

      // Get public URL
      final url = _client.storage
          .from(bucketName)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      debugPrint('Error uploading to Supabase: $e');
      return null;
    }
  }

  /// Delete image from Supabase Storage
  static Future<bool> deleteImage({
    required String imagePath,
    required String bucketName,
  }) async {
    try {
      await _client.storage
          .from(bucketName)
          .remove([imagePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting from Supabase: $e');
      return false;
    }
  }

  /// List images in a folder
  static Future<List<FileObject>> listImages({
    required String folderPath,
    required String bucketName,
  }) async {
    try {
      final files = await _client.storage
          .from(bucketName)
          .list(path: folderPath);
      return files;
    } catch (e) {
      debugPrint('Error listing Supabase files: $e');
      return [];
    }
  }
}
```

## Step 5: Update create_case_screen.dart

Replace Firebase Storage upload with Supabase:

```dart
// In _diagnoseCase() method, replace image upload section:

// OLD CODE (Firebase Storage):
/*
final uploadTask = await storageRef.putData(file.bytes!);
final downloadUrl = await uploadTask.ref.getDownloadURL();
imageUrls.add(downloadUrl);
*/

// NEW CODE (Supabase Storage):
try {
  final fileName = '${timestamp}_image_$i.${file.extension ?? 'jpg'}';
  final folderPath = 'dentists/$dentistId/patients/${_selectedPatient!.id}/cases';

  final downloadUrl = await SupabaseService.uploadImage(
    fileName: fileName,
    fileBytes: file.bytes!,
    bucketName: 'dental-xrays',
    folderPath: folderPath,
  );

  if (downloadUrl != null) {
    imageUrls.add(downloadUrl);
  } else {
    debugPrint('Failed to upload image $i');
  }
} catch (e) {
  debugPrint('Error uploading image: $e');
  // Continue with other images
}
```

## Step 6: Update Imports

Add to `create_case_screen.dart`:
```dart
import '../service/supabase_service.dart';
```

## Step 7: Storage Path Structure

Recommended Supabase bucket structure:
```
dental-xrays/
  ├── dentists/
  │   └── {dentistUid}/
  │       └── patients/
  │           └── {patientId}/
  │               └── cases/
  │                   └── {caseId}_image_0.jpg
  │                   └── {caseId}_image_1.jpg
  │                   └── ...
```

## Step 8: Supabase Storage Policies

Add row-level security policy for authenticated dentists:

```sql
-- Allow dentists to upload images
CREATE POLICY "Dentists can upload their own images"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'dental-xrays' AND
  auth.uid() = (storage.foldername(name))[1]::uuid
);

-- Allow dentists to read their own images
CREATE POLICY "Dentists can read their own images"
ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'dental-xrays' AND
  auth.uid() = (storage.foldername(name))[1]::uuid
);

-- Allow dentists to delete their own images
CREATE POLICY "Dentists can delete their own images"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'dental-xrays' AND
  auth.uid() = (storage.foldername(name))[1]::uuid
);
```

## Step 9: Error Handling

The SupabaseService includes error handling. For additional error handling in create_case_screen:

```dart
try {
  // Image upload
} catch (e) {
  debugPrint('Supabase upload error: $e');
  if (e.toString().contains('401')) {
    _showSnackBar('Authentication failed. Please re-login.', Colors.red);
  } else if (e.toString().contains('413')) {
    _showSnackBar('Image file too large. Maximum 10MB.', Colors.red);
  } else {
    _showSnackBar('Upload failed: ${e.toString()}', Colors.red);
  }
}
```

## Step 10: Testing

Test the Supabase integration:

1. Add a new patient
2. Go to Create Case screen
3. Select the patient
4. Upload X-ray images
5. Click "Diagnose Case"
6. Verify images appear in Supabase Storage dashboard
7. Verify image URLs are stored in Firestore

## Fallback to Firebase (if needed)

If Supabase has issues, the app will:
1. Log the error
2. Show user-friendly error message
3. Fail gracefully without crashing

## Environment Variables (Optional)

For production, use .env file (add flutter_dotenv package):

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Load in main.dart:
```dart
await dotenv.load();
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

## Troubleshooting

### Issue: 401 Unauthorized
- Check Supabase authentication token
- Ensure user is logged in to Firebase
- Verify Supabase policies

### Issue: 403 Forbidden
- Check storage bucket policies
- Verify bucket name is correct
- Ensure folder path matches policies

### Issue: Slow uploads
- Consider compression before upload
- Upload images in background
- Show progress indicator

### Issue: Network timeout
- Increase timeout duration
- Implement retry logic
- Show retry UI to user

---

**Status**: Ready to implement
**Timeline**: 1-2 hours for full integration
