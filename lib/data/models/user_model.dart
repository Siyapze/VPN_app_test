import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for STRESSLESS VPN
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  // VPN-specific fields
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final DateTime? trialStartedAt;
  final DateTime? trialExpiresAt;
  final bool hasUsedTrial;
  final int connectionCount;
  final String? preferredServer;
  
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.trialStartedAt,
    this.trialExpiresAt,
    this.hasUsedTrial = false,
    this.connectionCount = 0,
    this.preferredServer,
  });

  /// Check if user is currently in trial period
  bool get isInTrial {
    if (!hasUsedTrial || trialExpiresAt == null) return false;
    return DateTime.now().isBefore(trialExpiresAt!);
  }

  /// Check if user has active premium or trial access
  bool get hasActiveAccess {
    if (isInTrial) return true;
    if (!isPremium || premiumExpiresAt == null) return false;
    return DateTime.now().isBefore(premiumExpiresAt!);
  }

  /// Check if trial has expired
  bool get isTrialExpired {
    if (!hasUsedTrial || trialExpiresAt == null) return false;
    return DateTime.now().isAfter(trialExpiresAt!);
  }

  /// Check if premium has expired
  bool get isPremiumExpired {
    if (!isPremium || premiumExpiresAt == null) return false;
    return DateTime.now().isAfter(premiumExpiresAt!);
  }

  /// Days remaining in trial
  int get trialDaysRemaining {
    if (!isInTrial) return 0;
    final difference = trialExpiresAt!.difference(DateTime.now());
    return difference.inDays + 1; // +1 to include current day
  }

  /// Days remaining in premium
  int get premiumDaysRemaining {
    if (!isPremium || premiumExpiresAt == null) return 0;
    if (isPremiumExpired) return 0;
    final difference = premiumExpiresAt!.difference(DateTime.now());
    return difference.inDays + 1;
  }

  /// Create UserModel from Firebase User and Firestore data
  factory UserModel.fromFirestore(DocumentSnapshot doc, String uid, String email) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return UserModel(
      uid: uid,
      email: email,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isPremium: data['isPremium'] as bool? ?? false,
      premiumExpiresAt: (data['premiumExpiresAt'] as Timestamp?)?.toDate(),
      trialStartedAt: (data['trialStartedAt'] as Timestamp?)?.toDate(),
      trialExpiresAt: (data['trialExpiresAt'] as Timestamp?)?.toDate(),
      hasUsedTrial: data['hasUsedTrial'] as bool? ?? false,
      connectionCount: data['connectionCount'] as int? ?? 0,
      preferredServer: data['preferredServer'] as String?,
    );
  }

  /// Convert UserModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null ? Timestamp.fromDate(premiumExpiresAt!) : null,
      'trialStartedAt': trialStartedAt != null ? Timestamp.fromDate(trialStartedAt!) : null,
      'trialExpiresAt': trialExpiresAt != null ? Timestamp.fromDate(trialExpiresAt!) : null,
      'hasUsedTrial': hasUsedTrial,
      'connectionCount': connectionCount,
      'preferredServer': preferredServer,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    DateTime? lastLoginAt,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    DateTime? trialStartedAt,
    DateTime? trialExpiresAt,
    bool? hasUsedTrial,
    int? connectionCount,
    String? preferredServer,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
      connectionCount: connectionCount ?? this.connectionCount,
      preferredServer: preferredServer ?? this.preferredServer,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, isPremium: $isPremium, hasActiveAccess: $hasActiveAccess)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
