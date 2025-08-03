import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Firestore service for database operations
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get vpnServersCollection => _firestore.collection('vpn_servers');
  CollectionReference get connectionLogsCollection => _firestore.collection('connection_logs');
  CollectionReference get feedbackCollection => _firestore.collection('feedback');
  CollectionReference get announcementsCollection => _firestore.collection('announcements');

  /// Get current user document reference
  DocumentReference? get currentUserDoc {
    final user = _auth.currentUser;
    return user != null ? usersCollection.doc(user.uid) : null;
  }

  /// Create or update user document
  Future<void> createOrUpdateUser(UserModel userModel) async {
    try {
      final userDoc = currentUserDoc;
      if (userDoc == null) throw Exception('User not authenticated');

      await userDoc.set(userModel.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc, uid, doc.data() as Map<String, dynamic>?);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final userDoc = currentUserDoc;
      if (userDoc == null) throw Exception('User not authenticated');

      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await userDoc.update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Log VPN connection
  Future<void> logVpnConnection({
    required String serverId,
    required String serverLocation,
    required DateTime connectedAt,
    DateTime? disconnectedAt,
    int? bytesTransferred,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final logData = {
        'userId': user.uid,
        'serverId': serverId,
        'serverLocation': serverLocation,
        'connectedAt': Timestamp.fromDate(connectedAt),
        'disconnectedAt': disconnectedAt != null ? Timestamp.fromDate(disconnectedAt) : null,
        'bytesTransferred': bytesTransferred,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      await connectionLogsCollection.add(logData);

      // Update user's connection count
      await currentUserDoc?.update({
        'connectionCount': FieldValue.increment(1),
        'lastConnectionAt': Timestamp.fromDate(connectedAt),
      });
    } catch (e) {
      print('Error logging VPN connection: $e');
      rethrow;
    }
  }

  /// Get user's connection history
  Future<List<Map<String, dynamic>>> getUserConnectionHistory({int limit = 50}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = connectionLogsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('connectedAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting connection history: $e');
      return [];
    }
  }

  /// Get available VPN servers
  Future<List<Map<String, dynamic>>> getVpnServers() async {
    try {
      final snapshot = await vpnServersCollection
          .where('isActive', isEqualTo: true)
          .orderBy('priority')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting VPN servers: $e');
      return [];
    }
  }

  /// Submit user feedback
  Future<void> submitFeedback({
    required String message,
    required String type, // 'bug', 'feature', 'general'
    int? rating,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final feedbackData = {
        'userId': user.uid,
        'userEmail': user.email,
        'message': message,
        'type': type,
        'rating': rating,
        'metadata': metadata,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      await feedbackCollection.add(feedbackData);
    } catch (e) {
      print('Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Get app announcements
  Future<List<Map<String, dynamic>>> getAnnouncements({int limit = 10}) async {
    try {
      final snapshot = await announcementsCollection
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt')
          .orderBy('priority', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting announcements: $e');
      return [];
    }
  }

  /// Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final userDoc = currentUserDoc;
      if (userDoc == null) throw Exception('User not authenticated');

      await userDoc.update({
        'settings': settings,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating user settings: $e');
      rethrow;
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final userDoc = currentUserDoc;
      if (userDoc == null) throw Exception('User not authenticated');

      final doc = await userDoc.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['settings'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user settings: $e');
      return null;
    }
  }

  /// Stream user data changes
  Stream<DocumentSnapshot> streamUserData() {
    final userDoc = currentUserDoc;
    if (userDoc == null) throw Exception('User not authenticated');
    return userDoc.snapshots();
  }

  /// Stream VPN servers
  Stream<QuerySnapshot> streamVpnServers() {
    return vpnServersCollection
        .where('isActive', isEqualTo: true)
        .orderBy('priority')
        .snapshots();
  }

  /// Stream announcements
  Stream<QuerySnapshot> streamAnnouncements() {
    return announcementsCollection
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('expiresAt')
        .orderBy('priority', descending: true)
        .snapshots();
  }

  /// Batch write operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final data = operation['data'] as Map<String, dynamic>;

        switch (type) {
          case 'set':
            final docId = operation['docId'] as String?;
            final docRef = docId != null 
                ? _firestore.collection(collection).doc(docId)
                : _firestore.collection(collection).doc();
            batch.set(docRef, data);
            break;
          case 'update':
            final docId = operation['docId'] as String;
            final docRef = _firestore.collection(collection).doc(docId);
            batch.update(docRef, data);
            break;
          case 'delete':
            final docId = operation['docId'] as String;
            final docRef = _firestore.collection(collection).doc(docId);
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error in batch write: $e');
      rethrow;
    }
  }

  /// Delete user data (for account deletion)
  Future<void> deleteUserData(String uid) async {
    try {
      // Delete user document
      await usersCollection.doc(uid).delete();

      // Delete user's connection logs
      final connectionLogs = await connectionLogsCollection
          .where('userId', isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in connectionLogs.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's feedback
      final feedback = await feedbackCollection
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in feedback.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
