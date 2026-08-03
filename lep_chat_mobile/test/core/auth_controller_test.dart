import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lep_app/core/api_client.dart';
import 'package:lep_app/core/auth_controller.dart';
import 'package:lep_app/models/api_models.dart';
import 'package:lep_app/services/profile_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockProfileApiService extends Mock implements ProfileApiService {}

const _existingProfile = UserProfile(uid: 'uid-1', fullName: 'Jean-Luc', username: 'jeanluc', email: 'jean@example.com');

void main() {
  late MockGoogleSignIn googleSignIn;
  late MockProfileApiService profileApi;

  setUp(() {
    googleSignIn = MockGoogleSignIn();
    profileApi = MockProfileApiService();
  });

  AuthController buildController(FirebaseAuth auth) {
    return AuthController(firebaseAuth: auth, googleSignIn: googleSignIn, profileApi: profileApi);
  }

  group('initial state', () {
    test('becomes signedOut when no user is signed in', () async {
      final auth = MockFirebaseAuth(signedIn: false);
      final controller = buildController(auth);

      await controller.refresh();

      expect(controller.status, AuthStatus.signedOut);
      expect(controller.firebaseUser, isNull);
    });
  });

  group('signUpWithEmail', () {
    test('creates the account, sends verification, and moves to emailUnverified', () async {
      final auth = MockFirebaseAuth(signedIn: false, verifyEmailAutomatically: false);
      final controller = buildController(auth);

      final ok = await controller.signUpWithEmail(
        email: 'new.user@example.com',
        password: 'super-secret',
        fullName: 'New User',
        username: 'newuser',
        jurisdiction: 'Rwanda',
      );

      expect(ok, isTrue);
      expect(controller.status, AuthStatus.emailUnverified);
      expect(controller.firebaseUser?.email, 'new.user@example.com');
    });
  });

  group('confirmEmailVerified', () {
    test('reports still-unverified without touching the backend', () async {
      final auth = MockFirebaseAuth(signedIn: false, verifyEmailAutomatically: false);
      final controller = buildController(auth);
      await controller.signUpWithEmail(
        email: 'new.user@example.com',
        password: 'super-secret',
        fullName: 'New User',
        username: 'newuser',
      );

      final ok = await controller.confirmEmailVerified();

      expect(ok, isFalse);
      expect(controller.status, AuthStatus.emailUnverified);
      expect(controller.errorMessage, contains('not verified'));
      verifyNever(() => profileApi.createMyProfile(
            fullName: any(named: 'fullName'),
            username: any(named: 'username'),
            phoneNumber: any(named: 'phoneNumber'),
            jurisdiction: any(named: 'jurisdiction'),
            nationalId: any(named: 'nationalId'),
          ));
    });

    test('submits the pending signup profile once verified, landing on signedIn', () async {
      final auth = MockFirebaseAuth(signedIn: false); // verifyEmailAutomatically defaults true
      when(() => profileApi.getMyProfile()).thenThrow(ApiException(404, 'Profile not found'));
      when(() => profileApi.createMyProfile(
            fullName: any(named: 'fullName'),
            username: any(named: 'username'),
            phoneNumber: any(named: 'phoneNumber'),
            jurisdiction: any(named: 'jurisdiction'),
            nationalId: any(named: 'nationalId'),
          )).thenAnswer((_) async => _existingProfile);

      final controller = buildController(auth);
      await controller.signUpWithEmail(
        email: 'new.user@example.com',
        password: 'super-secret',
        fullName: 'Jean-Luc',
        username: 'jeanluc',
        jurisdiction: 'Rwanda',
      );

      final ok = await controller.confirmEmailVerified();

      expect(ok, isTrue);
      expect(controller.status, AuthStatus.signedIn);
      expect(controller.profile, _existingProfile);
      final captured = verify(() => profileApi.createMyProfile(
            fullName: captureAny(named: 'fullName'),
            username: any(named: 'username'),
            phoneNumber: any(named: 'phoneNumber'),
            jurisdiction: any(named: 'jurisdiction'),
            nationalId: any(named: 'nationalId'),
          )).captured;
      expect(captured.single, 'Jean-Luc');
    });
  });

  group('signInWithEmail', () {
    test('loads an existing profile and lands on signedIn', () async {
      final auth = MockFirebaseAuth(
        signedIn: false,
        mockUser: MockUser(uid: 'uid-1', email: 'jean@example.com', isEmailVerified: true),
      );
      when(() => profileApi.getMyProfile()).thenAnswer((_) async => _existingProfile);

      final controller = buildController(auth);
      final ok = await controller.signInWithEmail(email: 'jean@example.com', password: 'whatever');

      expect(ok, isTrue);
      expect(controller.status, AuthStatus.signedIn);
      expect(controller.profile, _existingProfile);
    });

    test('lands on profileIncomplete when the backend has no profile yet', () async {
      final auth = MockFirebaseAuth(
        signedIn: false,
        mockUser: MockUser(uid: 'uid-2', email: 'new@example.com', isEmailVerified: true),
      );
      when(() => profileApi.getMyProfile()).thenThrow(ApiException(404, 'Profile not found'));

      final controller = buildController(auth);
      await controller.signInWithEmail(email: 'new@example.com', password: 'whatever');

      expect(controller.status, AuthStatus.profileIncomplete);
    });
  });

  group('completeProfile', () {
    test('submits fields directly and lands on signedIn', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid-3', email: 'g@example.com', isEmailVerified: true),
      );
      when(() => profileApi.getMyProfile()).thenThrow(ApiException(404, 'Profile not found'));
      when(() => profileApi.createMyProfile(
            fullName: any(named: 'fullName'),
            username: any(named: 'username'),
            phoneNumber: any(named: 'phoneNumber'),
            jurisdiction: any(named: 'jurisdiction'),
            nationalId: any(named: 'nationalId'),
          )).thenAnswer((_) async => _existingProfile);

      final controller = buildController(auth);
      await controller.refresh();
      expect(controller.status, AuthStatus.profileIncomplete);

      final ok = await controller.completeProfile(fullName: 'Jean-Luc', username: 'jeanluc');

      expect(ok, isTrue);
      expect(controller.status, AuthStatus.signedIn);
      expect(controller.profile, _existingProfile);
    });
  });

  group('signOut', () {
    test('resets status to signedOut and clears the profile', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid-4', email: 'g@example.com', isEmailVerified: true),
      );
      when(() => profileApi.getMyProfile()).thenAnswer((_) async => _existingProfile);
      final controller = buildController(auth);
      await controller.refresh();
      expect(controller.status, AuthStatus.signedIn);

      await controller.signOut();

      expect(controller.status, AuthStatus.signedOut);
      expect(controller.profile, isNull);
    });
  });
}
