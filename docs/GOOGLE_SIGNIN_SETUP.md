# Google Sign In Setup

Complete these steps to enable Google Sign In for Prosepal.

## Prerequisites
- Access to [Google Cloud Console](https://console.cloud.google.com/)
- Access to [Firebase Console](https://console.firebase.google.com/) (project: prosepal-1a24b)

---

## Step 1: Create OAuth 2.0 Client IDs in Google Cloud Console

1. Go to [Google Cloud Console > APIs & Credentials](https://console.cloud.google.com/apis/credentials)
2. Select project **prosepal-1a24b**
3. Click **+ CREATE CREDENTIALS** > **OAuth client ID**

### Create iOS Client ID:
- Application type: **iOS**
- Name: `Prosepal iOS`
- Bundle ID: `com.prosepal.prosepal`
- Click **CREATE**
- **Copy the Client ID** (format: `530026851718-xxxxxxxxxxxx.apps.googleusercontent.com`)

### Create Web Client ID (if not exists):
- Application type: **Web application**
- Name: `Prosepal Web`
- Authorized JavaScript origins: `https://prosepal-1a24b.firebaseapp.com`
- Authorized redirect URIs: `https://prosepal-1a24b.firebaseapp.com/__/auth/handler`
- Click **CREATE**
- **Copy the Client ID** (format: `530026851718-xxxxxxxxxxxx.apps.googleusercontent.com`)

---

## Step 2: Update GoogleService-Info.plist

Open `ios/Runner/GoogleService-Info.plist` and add these keys:

```xml
<key>CLIENT_ID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
```

The REVERSED_CLIENT_ID is the CLIENT_ID with segments reversed:
- CLIENT_ID: `530026851718-abc123.apps.googleusercontent.com`
- REVERSED: `com.googleusercontent.apps.530026851718-abc123`

---

## Step 3: Update Xcode Config Files

Edit both files with your actual reversed client ID:

**ios/Flutter/Debug.xcconfig:**
```
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.YOUR_IOS_CLIENT_ID
```

**ios/Flutter/Release.xcconfig:**
```
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.YOUR_IOS_CLIENT_ID
```

---

## Step 4: Configure Supabase Google Provider

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) > Authentication > Providers
2. Enable **Google** provider
3. Enter:
   - **Client ID**: Your Web Client ID
   - **Client Secret**: From Google Cloud Console (OAuth 2.0 > Web client > Client secret)
4. Save

---

## Step 5: Build with Dart Defines

When running/building, pass the client IDs:

```bash
# Development
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID \
  --dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID

# Release build
flutter build ios \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID \
  --dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID
```

**Tip:** Add these to your IDE's run configuration or create a `.env` file for convenience.

---

## Step 6: Test

1. Run the app on a physical iOS device (simulators may have issues)
2. Tap "Continue with Google"
3. Complete the OAuth flow
4. Verify user appears in Supabase Auth dashboard

---

## Troubleshooting

### "Invalid client ID"
- Verify CLIENT_ID in GoogleService-Info.plist matches Google Cloud Console
- Ensure Bundle ID matches exactly: `com.prosepal.prosepal`

### "redirect_uri_mismatch"
- Check authorized redirect URIs in Google Cloud Console
- Must include Supabase callback URL

### Sign-in opens but immediately closes
- REVERSED_CLIENT_ID in xcconfig must match Info.plist URL scheme
- Rebuild after changing xcconfig files

### No ID token received
- Ensure Web Client ID is passed as `serverClientId` (via GOOGLE_WEB_CLIENT_ID)
- This is required for backend token validation

---

## Files Modified
- `ios/Runner/Info.plist` - URL scheme for OAuth callback
- `ios/Flutter/Debug.xcconfig` - Build variable
- `ios/Flutter/Release.xcconfig` - Build variable
- `ios/Runner/GoogleService-Info.plist` - Client IDs (you need to edit)
