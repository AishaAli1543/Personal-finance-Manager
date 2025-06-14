import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
