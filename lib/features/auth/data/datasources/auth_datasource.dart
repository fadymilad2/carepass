import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_models.dart';

abstract class AuthDataSource {
  Future<String> sendOtp(String phoneNumber);
  Future<AppUserModel> verifyOtp({
    required String verificationId,
    required String otp,
  });
  Future<AppUserModel> createProfile({
    required String uid,
    required String username,
    required String phoneNumber,
    // ✅ New optional fields
    String? email,
    String? dateOfBirth,
    String? city,
    String? emergencyContact,
    String? bloodType,
  });
  Future<AppUserModel?> getCurrentUser();
  Future<void> signOut();
}

class AuthDataSourceImpl implements AuthDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
  }) : _auth = auth,
       _db = db;

  // ── FCM Token ────────────────────────────────────────────────────────────
  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _db.collection(AppConstants.usersCollection).doc(uid).update({
        'fcmToken': token,
      });
    } catch (_) {}
  }

  // ── Send OTP ─────────────────────────────────────────────────────────────
  @override
  Future<String> sendOtp(String phoneNumber) async {
    if (kDebugMode && const bool.fromEnvironment('FIREBASE_TEST_PHONE_AUTH')) {
      await _auth.setSettings(appVerificationDisabledForTesting: true);
    }

    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(ServerException(_mapError(e.code)));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 70),
      onTimeout: () => throw const ServerException(
        'OTP request timed out. Please try again.',
      ),
    );
  }

  // ── Verify OTP ───────────────────────────────────────────────────────────
  @override
  Future<AppUserModel> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) throw const ServerException('Sign in failed');

      final isNew = result.additionalUserInfo?.isNewUser ?? false;

      if (isNew) {
        return AppUserModel(
          uid: user.uid,
          phoneNumber: user.phoneNumber ?? '',
          username: '',
          email: '',
          isSubscribed: false,
          subscriptionStatus: 'none',
          isNewUser: true,
        );
      }

      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return AppUserModel(
          uid: user.uid,
          phoneNumber: user.phoneNumber ?? '',
          username: '',
          email: '',
          isSubscribed: false,
          subscriptionStatus: 'none',
          isNewUser: true,
        );
      }

      await _saveFcmToken(user.uid);

      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        await _db.collection(AppConstants.usersCollection).doc(user.uid).set({
          'phoneNumber': user.phoneNumber,
        }, SetOptions(merge: true));
      }

      return AppUserModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_mapError(e.code));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Verification failed: $e');
    }
  }

  // ── Create Profile ───────────────────────────────────────────────────────
  @override
  Future<AppUserModel> createProfile({
    required String uid,
    required String username,
    required String phoneNumber,
    String? email,
    String? dateOfBirth,
    String? city,
    String? emergencyContact,
    String? bloodType,
  }) async {
    try {
      String fcmToken = '';
      try {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (_) {}

      final authPhone = _auth.currentUser?.phoneNumber;
      final finalPhone = (authPhone != null && authPhone.isNotEmpty)
          ? authPhone
          : phoneNumber;

      final now = DateTime.now().toIso8601String();
      final data = {
        'username': username,
        'email': email ?? '',
        'phoneNumber': finalPhone,
        'subscriptionStatus': 'none',
        'planName': '',
        'memberId': '',
        'cardExpiryDate': '',
        'selectedArea': city ?? '',
        'subscriptionType': 'individual',
        'bpChecksUsedThisMonth': 0,
        'sugarChecksUsedThisMonth': 0,
        'checksResetMonth': '',
        'fcmToken': fcmToken,
        // ✅ New fields
        'dateOfBirth': dateOfBirth ?? '',
        'city': city ?? '',
        'emergencyContact': emergencyContact ?? '',
        'bloodType': bloodType ?? '',
        'createdAt': now,
        'isNewUser': false,
      };

      await _db.collection(AppConstants.usersCollection).doc(uid).set(data);

      return AppUserModel(
        uid: uid,
        phoneNumber: finalPhone,
        username: username,
        email: email ?? '',
        isSubscribed: false,
        subscriptionStatus: 'none',
        isNewUser: false,
      );
    } catch (e) {
      throw ServerException('Failed to create profile: $e');
    }
  }

  // ── Get Current User ─────────────────────────────────────────────────────
  @override
  Future<AppUserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return AppUserModel(
          uid: user.uid,
          phoneNumber: user.phoneNumber ?? '',
          username: '',
          email: '',
          isSubscribed: false,
          subscriptionStatus: 'none',
          isNewUser: true,
        );
      }

      _saveFcmToken(user.uid);
      return AppUserModel.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection(AppConstants.usersCollection).doc(uid).update({
          'fcmToken': '',
        });
      } catch (_) {}
    }
    await _auth.signOut();
  }

  // ── Error Mapping ────────────────────────────────────────────────────────
  String _mapError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number';
      case 'invalid-verification-code':
        return 'Incorrect OTP code';
      case 'session-expired':
        return 'OTP expired. Please try again';
      case 'too-many-requests':
        return 'Too many attempts. Please wait';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try later';
      case 'network-request-failed':
        return 'No internet connection';
      case 'missing-client-identifier':
        return 'SHA-1 fingerprint missing';
      case 'app-not-authorized':
        return 'App not authorized';
      case 'billing-not-enabled':
        return 'Firebase Blaze plan required';
      default:
        return 'Something went wrong. Try again';
    }
  }
}
