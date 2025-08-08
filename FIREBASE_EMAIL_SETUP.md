# Firebase Email Setup Guide

## Issues with Email Verification and Password Reset

If email verification and password reset emails are not being sent, follow these steps:

### 1. Enable Email/Password Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `utkarsh-8cf54`
3. Go to **Authentication** → **Sign-in method**
4. Enable **Email/Password** provider
5. Make sure **Email link (passwordless sign-in)** is enabled if needed

### 2. Configure Email Templates

1. In Firebase Console, go to **Authentication** → **Templates**
2. Configure the following templates:
   - **Email verification**
   - **Password reset**
   - **Email change**

### 3. Check Firebase Project Settings

1. Go to **Project Settings** → **General**
2. Make sure your app is properly configured
3. Check that the package name matches: `com.example.utkarsh` or `com.utkarshapp`

### 4. Test Email Functionality

The app now includes a debug button "Test Email (Debug)" to test if Firebase email functionality is working.

### 5. Common Issues

- **Emails going to spam**: Check spam folder
- **Firebase not configured**: Make sure Authentication is enabled
- **Network issues**: Check internet connection
- **Rate limiting**: Wait a few minutes between attempts

### 6. Debug Information

The app now includes debug prints to help identify issues:
- Registration: `Email verification sent successfully to: [email]`
- Password reset: `Password reset email sent successfully`
- Resend verification: `Verification email resent successfully`

### 7. Firebase Rules

Make sure your Firestore rules allow user creation:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /enrollments/{enrollmentId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Testing Steps

1. **Register a new account** with a real email address
2. **Check your email** for verification link
3. **Click the verification link** in the email
4. **Try logging in** - should work after verification
5. **Test forgot password** - should send reset email
6. **Use debug button** to test email functionality

## Remove Debug Button

After confirming email functionality works, remove the debug button from `lib/screens/login_screen.dart`. 