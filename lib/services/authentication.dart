//authentication.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add Google User to Firestore
  Future<String> addGoogleUser(User user) async {
    String res = "Some error occurred";
    try {
      // Check if user already exists
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(user.uid).get();

      if (!userDoc.exists) {
        // Add user to firestore
        await _firestore.collection("users").doc(user.uid).set({
          'name': user.displayName ?? '',
          'uid': user.uid,
          'email': user.email ?? '',
        });
      } else {
        // Update last login time for existing users
        await _firestore.collection("users").doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // SignUp User with Email and Password
  Future<String> signupUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        // Create user in Firebase Auth
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Add user to Firestore
        await _firestore.collection("users").doc(cred.user!.uid).set({
          'name': name,
          'uid': cred.user!.uid,
          'email': email,
        });

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } on FirebaseAuthException catch (e) {
      res = _handleFirebaseAuthError(e);
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Login User with Email and Password
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Sign in user
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update last login time
        await _firestore.collection("users").doc(cred.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } on FirebaseAuthException catch (e) {
      res = _handleFirebaseAuthError(e);
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Handle Firebase Auth Errors
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'Incorrect Detail';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Reset Password
  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Password reset email sent";
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }
}
