import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> sendEmailVerificationLink({
    required String email,
  }) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://gastomigo.firebaseapp.com/finishSignUp',
      handleCodeInApp: true,
      androidPackageName: 'com.app.gastomigo',
      androidInstallApp: true,
      androidMinimumVersion: '23',
      iOSBundleId: 'com.app.gastomigo',
    );

    await _firebaseAuth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  bool isSignInWithEmailLink(String link) {
    return _firebaseAuth.isSignInWithEmailLink(link);
  }

  Future<UserCredential> completeEmailLinkSignIn({
    required String email,
    required String emailLink,
  }) async {
    return await _firebaseAuth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
  }

  Future<Map<String, dynamic>> saveVerifiedProfile({
    required String fullName,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('Firebase user is not signed in.');
    }

    final idToken = await user.getIdToken(true);

    final response = await http.post(
      ApiClient.uri('/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'full_name': fullName,
      }),
    );

    return _handleResponse(response);
  }

  Future<void> completePinEnrollmentOnServer() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('Firebase user is not signed in.');
    }

    final idToken = await user.getIdToken(true);

    final response = await http.post(
      ApiClient.uri('/users/pin-enrolled'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'Something went wrong.');
  }
}