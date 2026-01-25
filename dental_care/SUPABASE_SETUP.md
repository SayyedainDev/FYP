# Supabase Setup for Lecture Notes Storage

## Step 1: Create Supabase Account
1. Go to [supabase.com](https://supabase.com)
2. Sign up (free)
3. Create a new project (choose free tier)
4. Wait for project to initialize

## Step 2: Get Supabase Credentials
1. Go to Project Settings → API
2. Copy:
   - **Supabase URL** (looks like: `https://xxxxx.supabase.co`)
   - **Anon Key** (public key for client)

## Step 3: Create Storage Bucket
1. In Supabase console → Storage
2. Click "Create a new bucket"
3. Name it: `lecture_notes`
4. Make it **Public** (important!)
5. Create

## Step 4: Set Bucket Policies
1. Click the bucket → Policies tab
2. Add policy:
   - **Name**: `Enable reads for authenticated users`
   - **Choose**: `Authenticated users` can `SELECT`
   - Apply to: `Objects`

3. Add another policy:
   - **Name**: `Enable writes for authenticated users`
   - **Choose**: `Authenticated users` can `INSERT`, `UPDATE`, `DELETE`
   - Apply to: `Objects`

## Step 5: Update pubspec.yaml
Add to dependencies:
```yaml
supabase_flutter: ^2.5.1
```

Then run: `flutter pub get`

## Step 6: Initialize Supabase in main.dart
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // from Step 2
    anonKey: 'YOUR_ANON_KEY',  // from Step 2
  );
  
  runApp(const MyApp());
}
```

## Done!
The updated `lecture_notes_provider.dart` will now use Supabase Storage instead of Firebase Storage.
