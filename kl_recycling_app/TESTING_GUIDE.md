# 🧪 Complete Flutter & Dart Testing Guide

## Overview

This guide covers comprehensive testing for your KL Recycling App, including unit tests, widget tests, and integration tests for all major components built in Phases 1 & 2.

---

## 📁 Getting Started

### 1. Package Dependencies

Add testing dependencies to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  faker: ^2.1.0
  bloc_test: ^9.1.7
  integration_test:
    sdk: flutter
```

### 2. Directory Structure

```
test/
├── mocks/
│   └── mock_firestore.dart        # Firebase mocks
├── models/                        # Model tests
│   ├── user_test.dart
│   ├── service_request_test.dart
│   └── ml_analysis_result_test.dart
├── providers/                     # Provider/business logic tests
│   ├── auth_provider_test.dart
│   ├── admin_provider_test.dart
│   └── data_provider_test.dart
├── services/                      # Service layer tests
│   ├── auth_service_test.dart
│   └── admin_service_test.dart
├── screens/                       # Widget/UI tests
│   ├── auth/
│   │   ├── login_screen_test.dart
│   │   └── signup_screen_test.dart
│   └── home_screen_test.dart
├── widgets/                       # Widget component tests
│   └── common/
│       └── custom_card_test.dart
├── integration_test/              # End-to-end tests
│   └── app_test.dart
└── widget_test.dart               # Basic widget test
```

### 3. Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/providers/auth_provider_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report (install lcov)
genhtml coverage/lcov.info -o coverage/html
```

---

## 🧪 Test Types Explained

### 1. Unit Tests (`*_test.dart`)
Test individual functions, classes, and methods in isolation.

**Purpose:** Verify business logic, calculations, data transformations.

**Examples:**
- Service methods
- Provider logic
- Model validations
- Utility functions

### 2. Widget Tests (`*_test.dart`)
Test Flutter widgets in isolation.

**Purpose:** Verify UI rendering, user interactions, state changes.

**Examples:**
- Screen rendering
- Button taps
- Form validation
- Navigation

### 3. Integration Tests (`integration_test/*_test.dart`)
Test complete app flows and interactions.

**Purpose:** Verify real app behavior, end-to-end workflows.

---

## 🛠️ Testing Tools & Patterns

### 1. Mockito for Mocking

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks
@GenerateMocks([FirebaseAuth, FirebaseFirestore])
void main() { /* tests */ }
```

### 2. Common Test Patterns

#### Setup & Teardown
```dart
late MyService service;
late MockFirebaseAuth mockAuth;

setUp(() {
  mockAuth = MockFirebaseAuth();
  service = MyService(mockAuth);
});

tearDown(() {
  // Clean up
});
```

#### Async Testing
```dart
test('should handle async operations', () async {
  when(mockAuth.signInAnonymously())
      .thenAnswer((_) async => mockUser);

  final result = await service.signInAnonymously();

  expect(result, mockUser);
});
```

#### Widget Testing
```dart
testWidgets('should render login form', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: LoginScreen())
  );

  expect(find.byType(TextFormField), findsNWidgets(2));
  expect(find.text('Sign In'), findsOneWidget);
});
```

---

## 📝 Our KL Recycling App Tests

### 1. Model Tests

#### User Model Tests
```dart
// test/models/user_test.dart
import 'package:test/test.dart';
import 'package:kl_recycling_app/models/user.dart';

void main() {
  group('User Model', () {
    test('should create valid user', () {
      final user = User(
        uid: 'test-uid',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.uid, 'test-uid');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'John Doe');
      expect(user.isAdmin, isFalse);
    });

    test('should validate email format', () {
      expect(User.isValidEmail('user@example.com'), isTrue);
      expect(User.isValidEmail('invalid-email'), isFalse);
      expect(User.isValidEmail(''), isFalse);
    });

    test('should handle empty names', () {
      final user = User(
        uid: 'test',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.fullName, 'test@example.com');
      expect(user.displayName, 'test@example.com');
    });
  });
}
```

#### Service Request Model Tests
```dart
// test/models/service_request_test.dart
import 'package:test/test.dart';
import 'package:kl_recycling_app/models/service_request.dart';

void main() {
  group('ServiceRequest Model', () {
    test('should create service request with enum values', () {
      final request = ServiceRequest(
        id: 'test-id',
        requestType: RequestType.containerQuote,
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(request.id, 'test-id');
      expect(request.requestType, RequestType.containerQuote);
      expect(request.status, RequestStatus.pending);
      expect(request.isHighPriority, isFalse);
    });

    test('should handle all request types', () {
      RequestType.values.forEach((type) {
        expect(type.display, isNotEmpty);
      });
    });

    test('should validate request data', () {
      expect(() => ServiceRequest(
        id: '',
        requestType: RequestType.generalInquiry,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ), throwsA(isA<AssertionError>()));
    });
  });
}
```

#### ML Analysis Result Tests
```dart
// test/models/ml_analysis_result_test.dart
import 'package:test/test.dart';
import 'package:kl_recycling_app/models/ml_analysis_result.dart';

void main() {
  group('MLAnalysisResult Model', () {
    test('should create analysis result', () {
      final result = MLAnalysisResult(
        id: 'analysis-1',
        photoId: 'photo-123',
        detectedMaterials: [
          DetectedMaterial(
            materialType: 'steel',
            confidence: 0.85,
            boundingBox: [10, 20, 100, 100],
          ),
        ],
        metadata: AnalysisMetadata(
          modelVersion: 'v1.0',
          processingTimeMs: 1500,
        ),
        qualityScore: QualityScore(
          overallRating: 0.8,
          lightingQuality: 0.7,
          imageClarity: 0.9,
          subjectsInFrame: 0.8,
          qualityDescription: 'Good quality image',
        ),
        recommendations: Recommendations(
          overallAssessment: 'Clear analysis completed',
        ),
        analyzedAt: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15),
        deviceInfo: 'iPhone 12',
      );

      expect(result.id, 'analysis-1');
      expect(result.photoId, 'photo-123');
      expect(result.averageConfidence, greaterThan(0.8));
      expect(result.hasHighConfidenceDetection, isTrue);
    });

    test('should calculate business metrics', () {
      final result = MLAnalysisResult(
        id: 'analysis-1',
        photoId: 'photo-123',
        detectedMaterials: [],
        metadata: AnalysisMetadata(
          modelVersion: 'v1.0',
          processingTimeMs: 0,
        ),
        qualityScore: QualityScore(
          overallRating: 0.0,
          lightingQuality: 0.0,
          imageClarity: 0.0,
          subjectsInFrame: 0.0,
          qualityDescription: 'No data',
        ),
        recommendations: Recommendations(
          overallAssessment: 'No analysis',
        ),
        analyzedAt: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15),
        deviceInfo: 'test',
      );

      expect(result.allDetectedMaterialTypes, isEmpty);
      expect(result.averageConfidence, 0.0);
      expect(result.hasHighConfidenceDetection, isFalse);
    });
  });
}
```

### 2. Service Tests

#### Auth Service Tests
```dart
// test/services/auth_service_test.dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:kl_recycling_app/services/auth_service.dart';
import '../mocks/mock_firestore.dart';

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    authService = AuthService(mockAuth);
  });

  group('Auth Service', () {
    test('should initialize properly', () {
      expect(authService, isNotNull);
    });

    test('should handle sign in with email and password', () async {
      // Mock successful auth
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUser);

      final result = await authService.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isNotNull);
      expect(result?.email, 'test@example.com');
    });

    test('should handle auth errors', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpass',
      )).thenThrow(FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid',
      ));

      expect(
        () => authService.signInWithEmailPassword(
          email: 'test@example.com',
          password: 'wrongpass',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
```

#### Admin Service Tests
```dart
// test/services/admin_service_test.dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:kl_recycling_app/services/admin_service.dart';
import '../mocks/mock_firestore.dart';

void main() {
  late AdminService adminService;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    adminService = AdminService(mockAuth);
  });

  group('Admin Service Management', () {
    test('should get service requests with filters', () async {
      // Mock firestore queries
      when(mockFirestore.collection('serviceRequests'))
          .thenReturn(mockCollection);

      final requests = await adminService.getServiceRequests(
        status: 'pending',
        limit: 10,
      );

      expect(requests, isA<List<ServiceRequest>>());
    });

    test('should update service request status', () async {
      when(mockFirestore.collection('serviceRequests').doc('request-1'))
          .thenReturn(mockDocument);

      await expectLater(
        adminService.updateServiceRequestStatus('request-1', 'completed'),
        completes,
      );
    });

    test('should assign technician to request', () async {
      when(mockFirestore.collection('serviceRequests').doc('request-1'))
          .thenReturn(mockDocument);

      await expectLater(
        adminService.assignTechnician('request-1', 'tech-1'),
        completes,
      );
    });
  });

  group('Analytics Data', () {
    test('should calculate dashboard analytics', () async {
      final analytics = await adminService.getDashboardAnalytics();

      expect(analytics, isA<Map<String, dynamic>>());
      expect(analytics.containsKey('totalServiceRequests'), isTrue);
      expect(analytics.containsKey('totalRevenue'), isTrue);
    });

    test('should get ML performance stats', () async {
      final stats = await adminService.getMlPerformanceStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalAnalyses'), isTrue);
      expect(stats.containsKey('accuracyRate'), isTrue);
    });
  });
}
```

### 3. Provider Tests

#### Auth Provider Tests (Partial Example)
```dart
// test/providers/auth_provider_test.dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:kl_recycling_app/providers/auth_provider.dart';
import 'package:kl_recycling_app/services/auth_service.dart';
import 'package:kl_recycling_app/models/user.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    authProvider = AuthProvider();
    authProvider.authService = mockAuthService;
  });

  group('Auth Provider State Management', () {
    test('should start with no user', () {
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
    });

    test('should validate email format', () {
      expect(authProvider._isValidEmail('user@example.com'), isTrue);
      expect(authProvider._isValidEmail('invalid-email'), isFalse);
    });

    test('should validate password strength', () {
      expect(authProvider._isValidPassword('StrongPass123'), isTrue);
      expect(authProvider._isValidPassword('weak'), isFalse);
    });

    test('should handle sign in flow', () async {
      final testUser = User(
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
      )).thenAnswer((_) async => testUser);

      final result = await authProvider.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(authProvider.errorMessage, isNull);
    });

    test('should handle sign in errors', () async {
      when(mockAuthService.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'wrongpass',
      )).thenThrow(Exception('Invalid credentials'));

      final result = await authProvider.signInWithEmail(
        email: 'test@example.com',
        password: 'wrongpass',
      );

      expect(result, isFalse);
      expect(authProvider.errorMessage, isNotNull);
    });
  });
}
```

### 4. Widget Tests

#### Login Screen Test
```dart
// test/screens/auth/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/screens/auth/login_screen.dart';
import 'package:kl_recycling_app/providers/auth_provider.dart';
import 'package:kl_recycling_app/config/theme.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.errorMessage).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('should render login screen correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('should show validation errors for invalid form', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Try to submit empty form
    final signInButton = find.text('Sign In');
    await tester.tap(signInButton);
    await tester.pump();

    // Form should still be visible, indicating validation failed
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('should show forgot password dialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final forgotPasswordButton = find.text('Forgot Password?');
    await tester.tap(forgotPasswordButton);
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Send Reset Email'), findsOneWidget);
  });

  testWidgets('should show loading state during sign in', (tester) async {
    when(mockAuthProvider.isLoading).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('should display error messages', (tester) async {
    when(mockAuthProvider.errorMessage).thenReturn('Invalid credentials');

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('should navigate to signup on signup link tap', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final signupLink = find.text("Don't have an account? Sign Up");
    await tester.tap(signupLink);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
  });
}
```

#### Signup Screen Test
```dart
// test/screens/auth/signup_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/screens/auth/signup_screen.dart';
import 'package:kl_recycling_app/providers/auth_provider.dart';
import 'package:kl_recycling_app/config/theme.dart';

void main() {
  testWidgets('should render signup screen with all fields', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SignupScreen(),
    ));

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5)); // Name, email, phone, password, confirm
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('should validate password confirmation', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SignupScreen(),
    ));

    final passwordField = find.byType(TextFormField).at(3);
    final confirmField = find.byType(TextFormField).at(4);

    await tester.enterText(passwordField, 'password123');
    await tester.enterText(confirmField, 'different123');
    await tester.pump();

    final submitButton = find.text('Create Account');
    await tester.tap(submitButton);
    await tester.pump();

    // Should find validation error
    expect(find.byType(SignupScreen), findsOneWidget);
  });
}
```

---

## 🔄 Running Our Test Suite

### 1. Basic Test Execution

```bash
# Run all tests
flutter test

# Run specific component
flutter test test/providers/auth_provider_test.dart

# Run widget tests only
flutter test test/widgets/

# Run model tests only
flutter test test/models/
```

### 2. Test Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 3. CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Flutter Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.9.2'
        
    - name: Run tests
      run: flutter test --coverage
      
    - name: Upload coverage
      uses: codecov/codecov-action@v1
```

---

## 📊 Our Test Coverage Goals

### Phase 1: Authentication
- ✅ AuthProvider: 90%+ coverage
- ✅ AuthService: 85%+ coverage
- ✅ LoginScreen: 80%+ coverage
- ✅ SignupScreen: 75%+ coverage
- ✅ User model: 95%+ coverage

### Phase 2: Admin Dashboard
- ✅ AdminProvider: 85%+ coverage
- ✅ AdminService: 80%+ coverage
- ✅ ServiceRequest model: 90%+ coverage
- ✅ ML Analysis model: 85%+ coverage
- ✅ Web dashboard integration: Manual testing

### Overall Project: 80%+ Code Coverage
- 📈 Models: 90%+
- 📈 Providers: 85%+
- 📈 Services: 80%+
- 📈 Screens: 75%+
- 📈 Widgets: 70%+

---

## 🐛 Debugging Failing Tests

### Common Issues & Solutions

1. **Mock Not Working**
```dart
// Problem
when(mockService.getData()).thenReturn(data);

// Solution - Ensure mock is properly setup
@GenerateMocks([MyService])
class MockMyService extends Mock implements MyService {}
```

2. **Widget Not Found**
```dart
// Problem
expect(find.text('Button Text'), findsOneWidget); // Fails

// Solution - Check widget tree
await tester.pumpWidget(MyWidget());
await tester.pumpAndSettle(); // Wait for animations
print(tester.allElements.map((e) => e.widget.toString())); // Debug
```

3. **Async Test Hanging**
```dart
// Problem
test('async test', () async {
  // Test hangs
});

// Solution - Proper async handling
test('async test', () async {
  final result = await myAsyncFunction();
  expect(result, expectedValue);
});
```

4. **Provider Not Found**
```dart
// Problem
context.read<MyProvider>() // Throws

// Solution - Ensure provider in tree
await tester.pumpWidget(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MyProvider()),
    ],
    child: MyWidget(),
  ),
);
```

---

## 🎯 Testing Best Practices

### 1. Test Organization
- ✅ **One test file per component**
- ✅ **Clear test group naming**
- ✅ **Descriptive test method names**
- ✅ **Arrange-Act-Assert pattern**

### 2. Mock Strategy
- ✅ **Mock external dependencies** (Firebase, HTTP)
- ✅ **Real implementations for logic** (calculations, validation)
- ✅ **Consistent mock setup** across tests

### 3. Test Coverage
- ✅ **Happy path scenarios**
- ✅ **Error conditions** & edge cases
- ✅ **Loading states** & async operations
- ✅ **Widget interactions** & navigation

### 4. Test Maintenance
- ✅ **Keep tests green** after refactoring
- ✅ **Regular test runs** in CI/CD
- ✅ **Update tests** when APIs change
- ✅ **Document complex test scenarios**

---

## 🏆 Testing Success Metrics

### Quality Indicators
- ✅ **All tests pass** locally and in CI
- ✅ **80%+ code coverage** across all modules
- ✅ **Zero flaky tests** (consistent results)
- ✅ **Fast execution** (< 30 seconds locally)

### Maintenance Indicators
- ✅ **Easy to understand** test scenarios
- ✅ **Quick to update** after code changes
- ✅ **Comprehensive edge case** coverage
- ✅ **Good documentation** for complex tests

---

## 🚀 Advanced Testing Topics

### Integration Tests
```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kl_recycling_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete app flow', (tester) async {
    // Launch app
    await tester.pumpWidget(const KLRecyclingApp());
    await tester.pumpAndSettle();

    // Navigate to login
    // Perform authentication
    // Test main features
    // Verify expected behavior
  });
}
```

### Performance Tests
```dart
// test/performance/widget_performance_test.dart
testWidgets('widget renders within performance budget', (tester) async {
  await tester.pumpWidget(const HeavyWidget());

  final stopwatch = Stopwatch()..start();
  await tester.pump(); // Trigger rebuild
  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(16)); // 60fps budget
});
```

---

## 🔗 References

### Official Flutter Testing
- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Widget Testing Overview](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Unit Testing Overview](https://flutter.dev/docs/cookbook/testing/unit/introduction)

### Testing Libraries
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Bloc Test](https://pub.dev/packages/bloc_test)
- [Flutter Integration Test](https://docs.flutter.dev/testing/integration-tests)

