// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC3LRu-hHz-ah1B287l28NSPCNP_MmK7W0',
    appId: '1:81609052281:web:39e293919d5139c323c4a8',
    messagingSenderId: '81609052281',
    projectId: 'clone-59e57',
    authDomain: 'clone-59e57.firebaseapp.com',
    storageBucket: 'clone-59e57.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6G_wKdTnFP6Z0M7qBEu7GI595dMzRel0',
    appId: '1:81609052281:android:63bc73dabcecf76d23c4a8',
    messagingSenderId: '81609052281',
    projectId: 'clone-59e57',
    storageBucket: 'clone-59e57.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbGV9VVqggnsCJtxEdnxPNyFehjb7laZg',
    appId: '1:81609052281:ios:085627040b5f4b0823c4a8',
    messagingSenderId: '81609052281',
    projectId: 'clone-59e57',
    storageBucket: 'clone-59e57.firebasestorage.app',
    iosBundleId: 'com.example.amazonClone',
  );
}
