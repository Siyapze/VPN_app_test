/// VPN Server model
class VpnServer {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String city;
  final String ipAddress;
  final int port;
  final String protocol;
  final bool isPremium;
  final int ping;
  final double load; // Server load percentage (0.0 to 1.0)
  final bool isOnline;
  final String flagUrl;

  const VpnServer({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.city,
    required this.ipAddress,
    required this.port,
    this.protocol = 'OpenVPN',
    this.isPremium = false,
    this.ping = 0,
    this.load = 0.0,
    this.isOnline = true,
    this.flagUrl = '',
  });

  /// Get server quality based on ping and load
  ServerQuality get quality {
    if (!isOnline) return ServerQuality.offline;
    if (ping > 200 || load > 0.8) return ServerQuality.poor;
    if (ping > 100 || load > 0.6) return ServerQuality.fair;
    if (ping > 50 || load > 0.4) return ServerQuality.good;
    return ServerQuality.excellent;
  }

  /// Get quality color
  String get qualityColor {
    switch (quality) {
      case ServerQuality.excellent:
        return '#4CAF50'; // Green
      case ServerQuality.good:
        return '#8BC34A'; // Light Green
      case ServerQuality.fair:
        return '#FF9800'; // Orange
      case ServerQuality.poor:
        return '#F44336'; // Red
      case ServerQuality.offline:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get quality text
  String get qualityText {
    switch (quality) {
      case ServerQuality.excellent:
        return 'Excellent';
      case ServerQuality.good:
        return 'Good';
      case ServerQuality.fair:
        return 'Fair';
      case ServerQuality.poor:
        return 'Poor';
      case ServerQuality.offline:
        return 'Offline';
    }
  }

  /// Create from JSON
  factory VpnServer.fromJson(Map<String, dynamic> json) {
    return VpnServer(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      countryCode: json['countryCode'] as String,
      city: json['city'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      protocol: json['protocol'] as String? ?? 'OpenVPN',
      isPremium: json['isPremium'] as bool? ?? false,
      ping: json['ping'] as int? ?? 0,
      load: (json['load'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['isOnline'] as bool? ?? true,
      flagUrl: json['flagUrl'] as String? ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'countryCode': countryCode,
      'city': city,
      'ipAddress': ipAddress,
      'port': port,
      'protocol': protocol,
      'isPremium': isPremium,
      'ping': ping,
      'load': load,
      'isOnline': isOnline,
      'flagUrl': flagUrl,
    };
  }

  /// Create a copy with updated fields
  VpnServer copyWith({
    String? name,
    String? country,
    String? countryCode,
    String? city,
    String? ipAddress,
    int? port,
    String? protocol,
    bool? isPremium,
    int? ping,
    double? load,
    bool? isOnline,
    String? flagUrl,
  }) {
    return VpnServer(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      isPremium: isPremium ?? this.isPremium,
      ping: ping ?? this.ping,
      load: load ?? this.load,
      isOnline: isOnline ?? this.isOnline,
      flagUrl: flagUrl ?? this.flagUrl,
    );
  }

  @override
  String toString() {
    return 'VpnServer(id: $id, name: $name, country: $country, quality: $qualityText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VpnServer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Server quality enum
enum ServerQuality {
  excellent,
  good,
  fair,
  poor,
  offline,
}

/// VPN Connection Status
enum VpnStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// VPN Connection Statistics
class VpnStats {
  final Duration connectionTime;
  final int bytesReceived;
  final int bytesSent;
  final String downloadSpeed;
  final String uploadSpeed;

  const VpnStats({
    this.connectionTime = Duration.zero,
    this.bytesReceived = 0,
    this.bytesSent = 0,
    this.downloadSpeed = '0 KB/s',
    this.uploadSpeed = '0 KB/s',
  });

  /// Format bytes to human readable format
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get formatted received data
  String get formattedBytesReceived => formatBytes(bytesReceived);

  /// Get formatted sent data
  String get formattedBytesSent => formatBytes(bytesSent);

  /// Get total data usage
  String get totalDataUsage => formatBytes(bytesReceived + bytesSent);

  /// Format connection time
  String get formattedConnectionTime {
    final hours = connectionTime.inHours;
    final minutes = connectionTime.inMinutes % 60;
    final seconds = connectionTime.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  VpnStats copyWith({
    Duration? connectionTime,
    int? bytesReceived,
    int? bytesSent,
    String? downloadSpeed,
    String? uploadSpeed,
  }) {
    return VpnStats(
      connectionTime: connectionTime ?? this.connectionTime,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      bytesSent: bytesSent ?? this.bytesSent,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
    );
  }
}
