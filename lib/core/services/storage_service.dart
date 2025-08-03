import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Storage service for file uploads and downloads
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload user profile picture
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_pictures').child(fileName);

      // Upload file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Upload user profile picture from bytes (for web)
  Future<String?> uploadProfilePictureFromBytes(Uint8List imageBytes, String fileName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileNameWithTimestamp = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child('profile_pictures').child(fileNameWithTimestamp);

      // Upload bytes
      final uploadTask = ref.putData(imageBytes);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture from bytes: $e');
      rethrow;
    }
  }

  /// Upload app logs for debugging
  Future<String?> uploadLogFile(File logFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = 'logs_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final ref = _storage.ref().child('user_logs').child(fileName);

      // Upload file
      final uploadTask = ref.putFile(logFile);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading log file: $e');
      rethrow;
    }
  }

  /// Upload VPN configuration files
  Future<String?> uploadVpnConfig(File configFile, String configName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = 'vpn_config_${user.uid}_${configName}_${DateTime.now().millisecondsSinceEpoch}.ovpn';
      final ref = _storage.ref().child('vpn_configs').child(fileName);

      // Upload file
      final uploadTask = ref.putFile(configFile);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading VPN config: $e');
      rethrow;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  /// Get file metadata
  Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('Error getting file metadata: $e');
      return null;
    }
  }

  /// List user's uploaded files
  Future<List<Reference>> listUserFiles(String folder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ref = _storage.ref().child(folder);
      final result = await ref.listAll();
      
      // Filter files that belong to the current user
      return result.items.where((item) => item.name.contains(user.uid)).toList();
    } catch (e) {
      print('Error listing user files: $e');
      return [];
    }
  }

  /// Get download progress stream
  Stream<TaskSnapshot> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents;
  }

  /// Calculate upload progress percentage
  double getUploadProgressPercentage(TaskSnapshot snapshot) {
    if (snapshot.totalBytes == 0) return 0.0;
    return (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
  }

  /// Check if file exists
  Future<bool> fileExists(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  Future<int?> getFileSize(String downloadUrl) async {
    try {
      final metadata = await getFileMetadata(downloadUrl);
      return metadata?.size;
    } catch (e) {
      print('Error getting file size: $e');
      return null;
    }
  }

  /// Clean up old files (older than specified days)
  Future<void> cleanupOldFiles(String folder, int daysOld) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userFiles = await listUserFiles(folder);
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      for (final file in userFiles) {
        final metadata = await file.getMetadata();
        if (metadata.timeCreated != null && metadata.timeCreated!.isBefore(cutoffDate)) {
          await file.delete();
          print('Deleted old file: ${file.name}');
        }
      }
    } catch (e) {
      print('Error cleaning up old files: $e');
    }
  }
}
