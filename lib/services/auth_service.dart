import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signUp({required String nome, required String email, required String senha, required String role}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: senha);
    await _db.collection('users').doc(cred.user!.uid).set({
      'nome': nome.trim(), 'email': email.trim(), 'role': role,
      'photoAsset': 'assets/images/logo.png', 'notificacoesAtivas': true,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signIn({required String email, required String senha}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
  }
  Future<void> signOut() async => _auth.signOut();
}