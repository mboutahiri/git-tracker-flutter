import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;

  Future<void> login(String email, String password) async {
    await _runAuthAction(
      () => _authService.login(email: email, password: password),
    );
  }

  Future<void> register(String email, String password) async {
    await _runAuthAction(
      () => _authService.register(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> _runAuthAction(Future<Object?> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message ?? 'Authentication error';
    } catch (_) {
      errorMessage = 'Unexpected error. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
