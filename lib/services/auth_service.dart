import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInAnonymously() async {
    try {
      User? user = _auth.currentUser;

      // ถ้ายังไม่มีผู้ใช้ ให้สร้าง Anonymous Account
      if (user == null) {
        UserCredential credential =
            await _auth.signInAnonymously();

        user = credential.user;
      }

      return user;
    } catch (e) {
      print('Anonymous Auth Error: $e');
      return null;
    }
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  String? get uid {
    return _auth.currentUser?.uid;
  }
}