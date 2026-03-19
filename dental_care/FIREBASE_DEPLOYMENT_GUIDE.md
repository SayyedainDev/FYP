# Firebase Hosting & GitHub Actions CI/CD Setup Guide

This guide will help you deploy your Flutter web app to Firebase with automatic builds and deployment on every GitHub push.

## Step 1: Create Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **dental-care-6daf8**
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Save the JSON file securely (you'll use it next)

## Step 2: Add Secret to GitHub Repository

1. Go to your GitHub repository: **Your Repo → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Create a secret named: `FIREBASE_SERVICE_ACCOUNT`
4. Paste the entire contents of the JSON file from Step 1
5. Click **Add secret**

## Step 3: Verify Firebase Hosting is Enabled

1. In [Firebase Console](https://console.firebase.google.com/), select **dental-care-6daf8**
2. Go to **Hosting** in the left menu
3. If not enabled, click **Get Started** and follow the setup
4. Note the Hosting URL (looks like: `dental-care-6daf8.web.app`)

## Step 4: Verify Workflow Configuration

The workflow file is already created at `.github/workflows/deploy.yml` and will:
- ✅ Trigger on every push to `main` branch
- ✅ Build your Flutter web app
- ✅ Deploy to Firebase Hosting automatically

## Step 5: Update Flutter Version (if needed)

Check your current Flutter version:
```bash
flutter --version
```

Update the version in `.github/workflows/deploy.yml` if needed:
```yaml
flutter-version: '3.27.0'  # Change this to your version
```

## Step 6: Test the Deployment

### Option A: Manual Deploy (Before First Push)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy manually (test)
flutter build web --release --web-renderer html
firebase deploy
```

### Option B: Let GitHub Actions Deploy
1. Commit and push your changes to the main branch
2. Go to **GitHub → Your Repo → Actions**
3. Watch your workflow run in real-time
4. Once complete, your app will be live at: `https://dental-care-6daf8.web.app`

## Step 7: Verify Deployment

After the workflow completes:
1. Visit your hosting URL
2. Check [Firebase Console → Hosting](https://console.firebase.google.com/project/dental-care-6daf8/hosting/main) for deployment history

## File Structure Created

```
.github/
└── workflows/
    └── deploy.yml          # GitHub Actions workflow (auto-triggers on push)

.firebaserc                 # Firebase project configuration
```

## Troubleshooting

### Build Fails
- Check Flutter version matches your local setup
- Run `flutter pub get` locally and commit `pubspec.lock`
- Check for any build errors: `flutter build web --release`

### Deployment Fails
- Verify `FIREBASE_SERVICE_ACCOUNT` secret is set correctly
- Check Firebase Hosting is enabled in your Firebase project
- Ensure your Firebase project ID is correct: `dental-care-6daf8`

### Secret Not Found
- Re-add the secret: GitHub → Settings → Secrets → FIREBASE_SERVICE_ACCOUNT
- Verify the entire JSON content is pasted correctly

## Next Deployments

After initial setup, **every push to main branch will automatically**:
1. Build your web app
2. Test the build
3. Deploy to Firebase Hosting
4. Update your live site at `https://dental-care-6daf8.web.app`

You can monitor progress in the **GitHub Actions** tab of your repository.

## Quick Links

- [Firebase Console](https://console.firebase.google.com/project/dental-care-6daf8)
- [GitHub Actions Logs](https://github.com/YOUR_USERNAME/YOUR_REPO/actions)
- [Hosting URL](https://dental-care-6daf8.web.app)
