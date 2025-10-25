import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:kl_recycling_app/providers/auth_provider.dart';
import 'package:kl_recycling_app/services/auth_service.dart';
import 'package:kl_recycling_app/models/user.dart';
import '../mocks/mock_firestore.dart';

// Mock AuthService
class MockAuthService extends Mock implements AuthService {
  @override
  User? get currentUser => _mockUser;

  @override
  Stream<User?> get userStream => Stream.value(_mockUser);

  User? _mockUser;
}

void main() {
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    authProvider = AuthProvider()..authService = mockAuthService;
  });

  group('AuthProvider initialization', () {
    test('should initialize with loading state', () {
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.currentUser, isNull);
    });

    test('should be authenticated when user is present', () {
      // Setup mock user
      final mockUser = User(
        uid: 'test-uid',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockAuthService.currentUser).thenReturn(mockUser);

      final authProviderWithUser = AuthProvider()..authService = mockAuthService;

      expect(authProviderWithUser.isAuthenticated, true);
      expect(authProviderWithUser.currentUser, mockUser);
    });
  });

  group('Sign in functionality', () {
    test('should sign in successfully and update user', () async {
      // Setup successful sign in
      final mockUser = User(
        uid: 'test-uid',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockAuthService.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUser);

      final result = await authProvider.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, true);
      expect(authProvider.errorMessage, isNull);
    });

    test('should handle sign in failure', () async {
      when(mockAuthService.signInWithEmailPassword(
        email: 'wrong@example.com',
        password: 'wrongpass',
      )).thenThrow(Exception('Invalid credentials'));

      final result = await authProvider.signInWithEmail(
        email: 'wrong@example.com',
        password: 'wrongpass',
      );

      expect(result, false);
      expect(authProvider.errorMessage, 'Invalid credentials');
    });

    test('should validate email format', () {
      expect(authProvider._isValidEmail('valid@email.com'), true);
      expect(authProvider._isValidEmail('invalid-email'), false);
      expect(authProvider._isValidEmail(''), false);
      expect(authProvider._isValidEmail('user@.com'), false);
    });

    test('should validate password strength', () {
      expect(authProvider._isValidPassword('WeakPass'), false); // No number
      expect(authProvider._isValidPassword('weak123'), false); // No uppercase
      expect(authProvider._isValidPassword('ab'), false); // Too short
      expect(authProvider._isValidPassword('StrongPass123'), true); // Valid
    });

    test('should handle network errors', () async {
      when(mockAuthService.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenThrow(Exception('Network error'));

      final result = await authProvider.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, false);
      expect(authProvider.errorMessage, contains('Network error'));
    });
  });

  group('Sign up functionality', () {
    test('should sign up successfully with valid data', () async {
      final mockUser = User(
        uid: 'new-user-uid',
        email: 'new@example.com',
        firstName: 'New',
        lastName: 'User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockAuthService.signUpWithEmailPassword(
        email: 'new@example.com',
        password: 'ValidPass123',
        firstName: 'New',
        lastName: 'User',
        phone: '123-456-7890',
      )).thenAnswer((_) async => mockUser);

      final result = await authProvider.signUp(
        email: 'new@example.com',
        password: 'ValidPass123',
        firstName: 'New',
        lastName: 'User',
        phone: '123-456-7890',
      );

      expect(result, true);
      expect(authProvider.errorMessage, isNull);
    });

    test('should handle sign up with weak password', () async {
      // Provider should validate password before making auth call
      final result = await authProvider.signUp(
        email: 'test@example.com',
        password: 'weak',
        firstName: 'Test',
        lastName: 'User',
      );

      expect(result, false);
      expect(authProvider.errorMessage, isNotNull);
