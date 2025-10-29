import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';

  /// Firebase Storage service for AI model hosting and user photo management
class FirebaseStorageService {
  final FirebaseStorage _storage;
  final FirebaseService _firebaseService;

  FirebaseStorageService(this._firebaseService) : _storage = FirebaseStorage.instance;

  /// Upload user photo for weight estimation
  Future<String> uploadUserPhoto(File photoFile, String userId, String photoId) async {
    try {
      final String fileName = 'user_photos/$userId/$photoId.jpg';
      final Reference ref = _storage.ref().child(fileName);

      // Upload file
      final UploadTask uploadTask = ref.putFile(photoFile);
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save metadata to Firestore
      await _firebaseService.firestore.collection('user_photos').doc(photoId).set({
        'userId': userId,
        'photoId': photoId,
        'url': downloadUrl,
        'fileName': fileName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'size': await photoFile.length(),
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload user photo: $e');
    }
  }

  /// Download AI model from Firebase Storage
  Future<File> downloadAIModel(String modelName, String destinationPath) async {
    try {
      final String modelPath = 'ai_models/$modelName';
      final Reference ref = _storage.ref().child(modelPath);

      // Get download URL and check if model exists
      final String downloadUrl = await ref.getDownloadURL();

      // For now, return the URL for the TensorFlow Lite integration
      // In production, this would download the model file
      throw UnsupportedError('Model downloading requires platform-specific implementation');

    } catch (e) {
      throw Exception('Failed to download AI model $modelName: $e');
    }
  }

  /// Check if newer AI model version is available
  Future<Map<String, dynamic>?> checkForModelUpdates(String currentVersion, String modelName) async {
    try {
      final docSnapshot = await _firebaseService.firestore
          .collection('ai_models')
          .doc(modelName)
          .get();

      if (!docSnapshot.exists) return null;

      final modelData = docSnapshot.data();
      if (modelData == null) return null;

      final serverVersion = modelData['version'] as String;
      final currentVersionParsed = currentVersion.split('.').map(int.parse).toList();
      final serverVersionParsed = serverVersion.split('.').map(int.parse).toList();

      // Simple version comparison
      final isNewer = _isVersionNewer(serverVersionParsed, currentVersionParsed);

      if (isNewer) {
        return {
          'version': serverVersion,
          'size': modelData['size'],
          'downloadUrl': modelData['downloadUrl'],
          'lastUpdated': modelData['lastUpdated'],
          'changelog': modelData['changelog'],
        };
      }

      return null;
    } catch (e) {
      throw Exception('Failed to check for model updates: $e');
    }
  }

  /// Upload batch processing results
  Future<String> uploadBatchResults(String batchId, Map<String, dynamic> results, String userId) async {
    try {
      final String fileName = 'batch_results/$userId/$batchId.json';
      final Reference ref = _storage.ref().child(fileName);

      // Convert results to JSON string
      final String jsonString = jsonEncode(results);
      final List<int> bytes = utf8.encode(jsonString);

      // Upload as bytes
      final UploadTask uploadTask = ref.putData(Uint8List.fromList(bytes),
          SettableMetadata(contentType: 'application/json'));

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save batch metadata
      await _firebaseService.firestore.collection('batch_processes').doc(batchId).set({
        'batchId': batchId,
        'userId': userId,
        'resultUrl': downloadUrl,
        'fileName': fileName,
        'processedAt': FieldValue.serverTimestamp(),
        'resultCount': results['results']?.length ?? 0,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload batch results: $e');
    }
  }

  /// Delete user photo
  Future<void> deleteUserPhoto(String photoId, String userId) async {
    try {
      // Delete from Storage
      final String fileName = 'user_photos/$userId/$photoId.jpg';
      final Reference ref = _storage.ref().child(fileName);
      await ref.delete();


      // Delete from Firestore
      await _firebaseService.firestore.collection('user_photos').doc(photoId).delete();
    } catch (e) {
      throw Exception('Failed to delete user photo: $e');
    }
  }

  /// Get storage usage statistics for user
  Future<Map<String, dynamic>> getUserStorageStats(String userId) async {
    try {
      final QuerySnapshot userPhotos = await _firebaseService.firestore
          .collection('user_photos')
          .where('userId', isEqualTo: userId)
          .get();

      int totalFiles = userPhotos.docs.length;
      int totalSizeBytes = 0;

      for (final doc in userPhotos.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalSizeBytes += data['size'] as int? ?? 0;
      }

      return {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSizeBytes,
        'totalSizeMB': totalSizeBytes / (1024 * 1024),
      };
    } catch (e) {
      throw Exception('Failed to get storage stats: $e');
    }
  }

  /// Cleanup old photos (older than specified days)
  Future<int> cleanupOldPhotos(String userId, int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final QuerySnapshot oldPhotos = await _firebaseService.firestore
          .collection('user_photos')
          .where('userId', isEqualTo: userId)
          .where('uploadedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int deletedCount = 0;
      for (final doc in oldPhotos.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final photoId = data['photoId'] as String;

        // Delete from both Storage and Firestore
        await deleteUserPhoto(photoId, userId);
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      throw Exception('Failed to cleanup old photos: $e');
    }
  }

  /// Upload training data for AI model improvement
  Future<String> uploadTrainingData(Map<String, dynamic> trainingData, String sessionId) async {
    try {
      final String fileName = 'training_data/$sessionId.json';
      final Reference ref = _storage.ref().child(fileName);

      final String jsonString = jsonEncode(trainingData);
      final List<int> bytes = utf8.encode(jsonString);

      final UploadTask uploadTask = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(
          contentType: 'application/json',
          customMetadata: {
            'sessionId': sessionId,
            'trainingType': trainingData['type'] ?? 'weight_estimation',
            'timestamp': DateTime.now().toIso8601String(),
          }
        )
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload training data: $e');
    }
  }

  /// Helper method to compare versions
  bool _isVersionNewer(List<int> serverVersion, List<int> currentVersion) {
    for (int i = 0; i < serverVersion.length; i++) {
      if (i >= currentVersion.length) return true;
      if (serverVersion[i] > currentVersion[i]) return true;
      if (serverVersion[i] < currentVersion[i]) return false;
    }
    return false;
  }
}
