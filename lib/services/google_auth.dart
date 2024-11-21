import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'authentication.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthMethod _authMethod = AuthMethod();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<String> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web Platform Sign-In (existing implementation)
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.setCustomParameters({
          'prompt': 'select_account consent',
          'auth_type': 'reauthenticate',
        });
        authProvider.addScope('profile');
        authProvider.addScope('email');

        await _auth.setPersistence(Persistence.NONE);
        UserCredential userCredential =
            await _auth.signInWithPopup(authProvider);

        if (userCredential.user != null) {
          return await _authMethod.addGoogleUser(userCredential.user!);
        }
        return "No user data found";
      } else {
        // Mobile Platform (Android & iOS) Sign-In
        try {
          // Ensure any previous sign-in is completely cleared
          await _googleSignIn.signOut();
          await _auth.signOut();
        } catch (e) {
          // Ignore errors during sign-out as they might occur if no previous session exists
        }

        // Perform Google Sign-In
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return "Sign in cancelled by user";
        }

        // Get authentication details
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        // Add or update user in Firestore
        if (userCredential.user != null) {
          return await _authMethod.addGoogleUser(userCredential.user!);
        }

        return "No user data found";
      }
    } catch (e) {
      // Improved error handling
      if (e is FirebaseAuthException) {
        return _handleFirebaseAuthError(e);
      }
      return "An unexpected error occurred: ${e.toString()}";
    }
  }

  Future<void> googleSignOut() async {
    try {
      // Comprehensive sign-out process for all platforms
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  // Existing error handling method remains the same
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'Error occurred while accessing credentials. Try again.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled. Please contact support.';
      case 'user-disabled':
        return 'Your account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'popup-closed-by-user':
        return 'Sign in cancelled by user.';
      case 'network-request-failed':
        return 'A network error occurred. Please check your connection.';
      case 'timeout':
        return 'The operation has timed out. Please try again.';
      default:
        return 'Incorrect detail';
    }
  }

  // Existing methods remain the same
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
}
