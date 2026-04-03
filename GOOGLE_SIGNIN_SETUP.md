# Google Sign-In Setup Guide for DailyAP

## Overview
This guide explains how to use the Firebase Google/Gmail Sign-In authentication system that has been implemented in your DailyAP Flutter application.

## Features Implemented
✅ Google Sign-In with Firebase Authentication
✅ Gmail Sign-In (uses Google Sign-In)
✅ User Profile Management
✅ Sign Out Functionality
✅ Persistent Authentication State
✅ Error Handling and Loading States

## File Structure

### New Files Created:
```
lib/
├── providers/
│   └── auth_provider.dart          (Authentication state management)
├── screens/
│   ├── sign_in_screen.dart         (Google/Gmail Sign-In page)
│   └── profile_screen.dart         (User Profile & Sign Out)
```

### Updated Files:
```
lib/
├── main.dart                       (Firebase initialization + Auth Provider)
├── screens/
│   └── main_navigation_screen.dart (Added Profile tab)
pubspec.yaml                        (Added google_sign_in dependency)
```

## Prerequisites

Your Firebase project is already configured with:
- ✅ Google Services JSON (android/app/google-services.json)
- ✅ Firebase Console configured
- ✅ Firebase Core and Auth dependencies

## Installation Steps

### 1. Update Dependencies
The `google_sign_in: ^6.2.0` dependency has been added to `pubspec.yaml`.

Run the following command:
```bash
cd c:\vaishnavi\dailyap
flutter pub get
```

### 2. iOS Setup (If Building for iOS)

Add this to `ios/Podfile` (after `target 'Runner' do` line):
```ruby
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
    end
  end
```

In `ios/Runner/Info.plist`, add:
```xml
<key>GIDClientID</key>
<string>594233306135-qi0m48sgtl5udt7scaj5krmi4norfaum.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.dailyap</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.594233306135-qi0m48sgtl5udt7scaj5krmi4norfaum</string>
    </array>
  </dict>
</array>
```

### 3. Android Setup (Already Configured)
Your `android/app/google-services.json` is already properly configured with:
- Package Name: `com.example.dailyap`
- OAuth Client ID: `594233306135-ff57007f0upchqlo08qd6bckc0v1v0mq.apps.googleusercontent.com`

## How to Use

### Sign-In Flow

1. **App Launch**: When the app starts, users see the `SignInScreen` if not authenticated
2. **Google Sign-In Button**: Click "Sign in with Google" to open Google's authentication dialog
3. **Gmail Sign-In Button**: Click "Sign in with Gmail" (both buttons use the same Google Sign-In flow)
4. **After Sign-In**: User is automatically logged in and sees the main app

### Accessing User Information

The authenticated user's information is available through the `AuthProvider`:

```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    final user = authProvider.user;
    print('User Email: ${user?.email}');
    print('User Name: ${user?.displayName}');
    print('User Photo: ${user?.photoURL}');
  },
);
```

### Profile Screen

Users can access their profile by tapping the "Profile" tab in the bottom navigation:
- View their Google account information
- See email, user ID, phone number
- Verify email status
- Sign out with confirmation dialog

### Sign Out

Users can sign out from the Profile screen:
1. Tap the "Profile" tab
2. Scroll to the bottom
3. Tap the red "Sign Out" button
4. Confirm the sign-out action

## Code Structure

### AuthProvider (lib/providers/auth_provider.dart)

Main authentication manager using Provider pattern:

```dart
class AuthProvider extends ChangeNotifier {
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> signInWithGoogle() async { ... }
  Future<void> signOut() async { ... }
  void clearError() { ... }
}
```

### SignInScreen (lib/screens/sign_in_screen.dart)

Beautiful sign-in interface with:
- App branding
- Google Sign-In button
- Gmail Sign-In button
- Error message display
- Loading state handling
- Terms of Service/Privacy Policy links

### ProfileScreen (lib/screens/profile_screen.dart)

User profile management with:
- Profile picture from Google account
- User name and email display
- Account details (ID, phone, verification status)
- Sign-out button with confirmation

## State Management Flow

```
Firebase Auth State Changes
        ↓
    AuthProvider Listens
        ↓
    User Objects Updated
        ↓
    Consumer Widgets Rebuild
        ↓
    UI Updates / Navigation
```

## Error Handling

The app handles various authentication scenarios:
- ✅ Network errors
- ✅ Cancelled sign-in
- ✅ Firebase authentication errors
- ✅ Invalid credentials

Error messages are displayed at the top of the sign-in screen in a red error banner.

## Security Notes

⚠️ **Important Security Practices**:
1. Never commit `google-services.json` with sensitive data
2. Use Firebase Security Rules for Firestore access
3. Implement proper error handling for user data
4. Always verify email before sensitive operations
5. Use HTTPS for API calls

## Troubleshooting

### "Sign-in cancelled" Error
- User clicked "Cancel" on Google Sign-In dialog
- This is a normal flow, just try signing in again

### "Authentication failed" Error
- Check internet connection
- Verify Firebase Console settings
- Check `google-services.json` is proper

### Photo URL Not Loading
- User's Google account may not have a profile picture
- The app displays a default icon as fallback

## Testing

To test the authentication:

1. **First Run**: You'll see the SignInScreen
2. **Sign In**: Click "Sign in with Google" or "Sign in with Gmail"
3. **Device Popup**: Complete Google authentication on your device
4. **Auto Login**: You'll be automatically signed in on next app restart
5. **Sign Out**: Use the Profile screen to sign out

## Next Steps

You can extend this authentication system:
- Add Email/Password authentication
- Implement phone number verification
- Add biometric authentication
- Create user preferences storage
- Implement social linking (Facebook, Apple, etc.)

## Support

For Firebase issues, check:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication](https://firebase.flutter.dev/docs/auth/overview)

---

**Last Updated**: March 27, 2026
**Firebase Project**: allinoneapp-45
**App Name**: DailyAP
