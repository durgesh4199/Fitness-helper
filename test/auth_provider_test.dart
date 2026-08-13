import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:fitness_tracker/providers/auth_provider.dart';

void main() {
  group('AppAuthProvider (Firebase unavailable)', () {
    test('reports unavailable instead of throwing when Firebase was never initialized', () {
      // Constructed with no injected auth in a plain `flutter test` process,
      // FirebaseAuth.instance throws (no default app) — the provider must
      // swallow that, not crash.
      final provider = AppAuthProvider();
      expect(provider.isAvailable, isFalse);
      expect(provider.isSignedIn, isFalse);
    });

    test('every action throws a friendly AuthException instead of a platform error', () async {
      final provider = AppAuthProvider();
      await expectLater(provider.signInWithEmail('a@b.com', 'password123'), throwsA(isA<AuthException>()));
      await expectLater(provider.signUpWithEmail('a@b.com', 'password123'), throwsA(isA<AuthException>()));
      await expectLater(provider.signOut(), throwsA(isA<AuthException>()));
    });
  });

  group('AppAuthProvider (mocked Firebase)', () {
    late MockFirebaseAuth mockAuth;
    late AppAuthProvider provider;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      provider = AppAuthProvider(auth: mockAuth);
    });

    test('reports available and starts signed out', () {
      expect(provider.isAvailable, isTrue);
      expect(provider.isSignedIn, isFalse);
      expect(provider.user, isNull);
    });

    test('signUpWithEmail signs the user in and updates isSignedIn/email', () async {
      await provider.signUpWithEmail('new@example.com', 'password123');
      // authStateChanges is delivered async — let it flush.
      await Future<void>.delayed(Duration.zero);

      expect(provider.isSignedIn, isTrue);
      expect(provider.email, 'new@example.com');
    });

    test('signOut clears the signed-in user', () async {
      await provider.signUpWithEmail('new@example.com', 'password123');
      await Future<void>.delayed(Duration.zero);
      expect(provider.isSignedIn, isTrue);

      await provider.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(provider.isSignedIn, isFalse);
    });

    test('maps a wrong-password FirebaseAuthException to a friendly message', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));

      await expectLater(
        provider.signInWithEmail('existing@example.com', 'wrongpass'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Incorrect email or password'))),
      );
    });

    test('maps an email-already-in-use FirebaseAuthException to a friendly message', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await expectLater(
        provider.signUpWithEmail('existing@example.com', 'password123'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('account already exists'))),
      );
    });

    test('falls back to the FirebaseAuthException message for an unmapped code', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'some-unmapped-code', message: 'Very specific backend detail.'));

      await expectLater(
        provider.signInWithEmail('a@b.com', 'password123'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Very specific backend detail.')),
      );
    });
  });
}
