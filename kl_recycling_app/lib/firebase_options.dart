import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Android configuration - Updated with correct Firebase project details
    return const FirebaseOptions(
      apiKey: 'AIzaSyBrE_Z_1HlaTV_nzSFiDwdqTw4U5SN_pOM',
      appId: '1:671957589313:android:a210ed222ebec19600d5c0',
      messagingSenderId: '671957589313',
      projectId: 'gen-lang-client-0541313854',
      storageBucket: 'gen-lang-client-0541313854.firebasestorage.app',
      measurementId: 'G-509728182',
      iosBundleId: null,
    );
  }
}
