import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/api_models.dart';
import '../services/profile_api_service.dart';
import 'api_client.dart';

/// Where the signed-in user currently sits in the auth/onboarding funnel.
/// main.dart's AuthGate switches screens purely off this enum.
enum AuthStatus {
  /// Still resolving Firebase's persisted session on cold start.
  unknown,
  signedOut,

  /// Account exists (email/password) but Firebase's verification link
  /// hasn't been clicked yet. Google sign-in skips this — Google already
  /// verifies the email.
  emailUnverified,

  /// Verified/Google-authenticated, but no Firestore users/ profile yet —
  /// the signup form's fields haven't been submitted to the backend.
  profileIncomplete,
  signedIn,
}

class _PendingProfile {
  const _PendingProfile({
    required this.fullName,
    required this.username,
    this.phoneNumber,
    this.jurisdiction,
    this.nationalId,
  });

  final String fullName;
  final String username;
  final String? phoneNumber;
  final String? jurisdiction;
  final String? nationalId;
}

/// Coordinates Firebase Authentication (email/password + Google) with the
/// backend's users/ profile. FastAPI is the only thing allowed to touch
/// Firestore, so profile reads/writes always go through ProfileApiService,
/// never a Firestore SDK call from the client.
class AuthController extends ChangeNotifier {
  AuthController({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn, ProfileApiService? profileApi})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _profileApi = profileApi ?? ProfileApiService(ApiClient()) {
    _auth.authStateChanges().listen((_) => refresh());
  }

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final ProfileApiService _profileApi;
  bool _googleSignInReady = false;
  _PendingProfile? _pendingProfile;

  AuthStatus status = AuthStatus.unknown;
  UserProfile? profile;
  String? errorMessage;
  bool isBusy = false;

  User? get firebaseUser => _auth.currentUser;

  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) return;
    await _googleSignIn.initialize();
    _googleSignInReady = true;
  }

  bool get _signedInViaGoogle =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  /// Re-derives [status] from Firebase's current session plus the backend
  /// profile. Called after every sign-in/out and whenever the caller wants
  /// to re-check email-verification state (e.g. "I've verified, continue").
  Future<void> refresh() async {
    final user = _auth.currentUser;
    if (user == null) {
      status = AuthStatus.signedOut;
      profile = null;
      notifyListeners();
      return;
    }

    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    if (!_signedInViaGoogle && !refreshed.emailVerified) {
      status = AuthStatus.emailUnverified;
      notifyListeners();
      return;
    }

    try {
      profile = await _profileApi.getMyProfile();
      status = AuthStatus.signedIn;
    } on ApiException catch (e) {
      status = AuthStatus.profileIncomplete;
      if (e.statusCode != 404) errorMessage = e.message;
    }
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? e.code;
      return false;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Creates the Firebase account, fires off Firebase's own verification
  /// email, and stashes the rest of the signup form so it can be submitted
  /// to the backend automatically once [confirmEmailVerified] succeeds.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String? phoneNumber,
    String? jurisdiction,
    String? nationalId,
  }) {
    return _run(() async {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.sendEmailVerification();
      _pendingProfile = _PendingProfile(
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        jurisdiction: jurisdiction,
        nationalId: nationalId,
      );
      await refresh();
    });
  }

  Future<bool> signInWithEmail({required String email, required String password}) {
    return _run(() async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await refresh();
    });
  }

  Future<bool> signInWithGoogle() {
    return _run(() async {
      await _ensureGoogleSignInReady();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google did not return an ID token.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      await refresh();
    });
  }

  Future<bool> resendVerificationEmail() {
    return _run(() async {
      await _auth.currentUser?.sendEmailVerification();
    });
  }

  /// Called from the "I've verified my email — Continue" button. Re-checks
  /// Firebase, and if verification succeeded, submits whatever profile
  /// fields were captured at signup so the user lands straight in the app.
  Future<bool> confirmEmailVerified() {
    return _run(() async {
      await refresh();
      if (status == AuthStatus.emailUnverified) {
        throw StateError("Still not verified — check your inbox (and spam folder) for the link.");
      }
      final pending = _pendingProfile;
      if (status == AuthStatus.profileIncomplete && pending != null) {
        profile = await _profileApi.createMyProfile(
          fullName: pending.fullName,
          username: pending.username,
          phoneNumber: pending.phoneNumber,
          jurisdiction: pending.jurisdiction,
          nationalId: pending.nationalId,
        );
        _pendingProfile = null;
        status = AuthStatus.signedIn;
      }
    });
  }

  /// Used by CompleteProfileScreen — the fallback path when there's no
  /// pending signup data to auto-submit (e.g. Google sign-in, or the app
  /// was restarted mid-flow).
  Future<bool> completeProfile({
    required String fullName,
    required String username,
    String? phoneNumber,
    String? jurisdiction,
    String? nationalId,
  }) {
    return _run(() async {
      profile = await _profileApi.createMyProfile(
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        jurisdiction: jurisdiction,
        nationalId: nationalId,
      );
      status = AuthStatus.signedIn;
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInReady) {
      await _googleSignIn.signOut();
    }
    _pendingProfile = null;
    profile = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
