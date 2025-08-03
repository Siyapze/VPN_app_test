import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/vpn_server.dart';

/// VPN Service for managing connections
class VpnService extends ChangeNotifier {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  // Connection state
  VpnStatus _status = VpnStatus.disconnected;
  VpnServer? _currentServer;
  VpnStats _stats = const VpnStats();
  String? _errorMessage;
  
  // Timers for simulation
  Timer? _connectionTimer;
  Timer? _statsTimer;
  DateTime? _connectionStartTime;

  // Available servers (mock data for now)
  final List<VpnServer> _servers = [
    // Free servers
    VpnServer(
      id: 'us-free-1',
      name: 'United States (Free)',
      country: 'United States',
      countryCode: 'US',
      city: 'New York',
      ipAddress: '192.168.1.1',
      port: 1194,
      isPremium: false,
      ping: 45,
      load: 0.3,
    ),
    VpnServer(
      id: 'uk-free-1',
      name: 'United Kingdom (Free)',
      country: 'United Kingdom',
      countryCode: 'GB',
      city: 'London',
      ipAddress: '192.168.1.2',
      port: 1194,
      isPremium: false,
      ping: 65,
      load: 0.5,
    ),
    VpnServer(
      id: 'de-free-1',
      name: 'Germany (Free)',
      country: 'Germany',
      countryCode: 'DE',
      city: 'Berlin',
      ipAddress: '192.168.1.3',
      port: 1194,
      isPremium: false,
      ping: 55,
      load: 0.4,
    ),
    
    // Premium servers
    VpnServer(
      id: 'jp-premium-1',
      name: 'Japan (Premium)',
      country: 'Japan',
      countryCode: 'JP',
      city: 'Tokyo',
      ipAddress: '192.168.2.1',
      port: 1194,
      isPremium: true,
      ping: 25,
      load: 0.2,
    ),
    VpnServer(
      id: 'sg-premium-1',
      name: 'Singapore (Premium)',
      country: 'Singapore',
      countryCode: 'SG',
      city: 'Singapore',
      ipAddress: '192.168.2.2',
      port: 1194,
      isPremium: true,
      ping: 30,
      load: 0.1,
    ),
    VpnServer(
      id: 'au-premium-1',
      name: 'Australia (Premium)',
      country: 'Australia',
      countryCode: 'AU',
      city: 'Sydney',
      ipAddress: '192.168.2.3',
      port: 1194,
      isPremium: true,
      ping: 35,
      load: 0.15,
    ),
    VpnServer(
      id: 'ca-premium-1',
      name: 'Canada (Premium)',
      country: 'Canada',
      countryCode: 'CA',
      city: 'Toronto',
      ipAddress: '192.168.2.4',
      port: 1194,
      isPremium: true,
      ping: 40,
      load: 0.25,
    ),
  ];

  // Getters
  VpnStatus get status => _status;
  VpnServer? get currentServer => _currentServer;
  VpnStats get stats => _stats;
  String? get errorMessage => _errorMessage;
  List<VpnServer> get servers => List.unmodifiable(_servers);
  
  bool get isConnected => _status == VpnStatus.connected;
  bool get isConnecting => _status == VpnStatus.connecting;
  bool get isDisconnected => _status == VpnStatus.disconnected;

  /// Get servers available for user (based on premium status)
  List<VpnServer> getAvailableServers({required bool isPremiumUser}) {
    if (isPremiumUser) {
      return _servers; // All servers
    } else {
      return _servers.where((server) => !server.isPremium).toList(); // Free servers only
    }
  }

  /// Get best server for user
  VpnServer getBestServer({required bool isPremiumUser}) {
    final availableServers = getAvailableServers(isPremiumUser: isPremiumUser);
    if (availableServers.isEmpty) return _servers.first;
    
    // Sort by quality (ping + load)
    availableServers.sort((a, b) {
      final aScore = a.ping + (a.load * 100);
      final bScore = b.ping + (b.load * 100);
      return aScore.compareTo(bScore);
    });
    
    return availableServers.first;
  }

  /// Connect to VPN server
  Future<void> connect(VpnServer server) async {
    if (_status == VpnStatus.connecting || _status == VpnStatus.connected) {
      return;
    }

    _status = VpnStatus.connecting;
    _currentServer = server;
    _errorMessage = null;
    _connectionStartTime = DateTime.now();
    notifyListeners();

    try {
      // Simulate connection process
      await _simulateConnection();
      
      _status = VpnStatus.connected;
      _startStatsTimer();
      notifyListeners();
      
      print('Connected to VPN server: ${server.name}');
    } catch (e) {
      _status = VpnStatus.error;
      _errorMessage = e.toString();
      _currentServer = null;
      notifyListeners();
      print('VPN connection failed: $e');
    }
  }

  /// Disconnect from VPN
  Future<void> disconnect() async {
    if (_status == VpnStatus.disconnected || _status == VpnStatus.disconnecting) {
      return;
    }

    _status = VpnStatus.disconnecting;
    notifyListeners();

    try {
      // Simulate disconnection process
      await Future.delayed(const Duration(seconds: 2));
      
      _status = VpnStatus.disconnected;
      _currentServer = null;
      _errorMessage = null;
      _stopTimers();
      _resetStats();
      notifyListeners();
      
      print('Disconnected from VPN');
    } catch (e) {
      _status = VpnStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      print('VPN disconnection failed: $e');
    }
  }

  /// Simulate connection process
  Future<void> _simulateConnection() async {
    // Simulate connection steps
    await Future.delayed(const Duration(seconds: 1));
    
    // Random chance of connection failure (5%)
    if (Random().nextInt(100) < 5) {
      throw Exception('Connection failed: Server unreachable');
    }
    
    await Future.delayed(const Duration(seconds: 2));
  }

  /// Start statistics timer
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateStats();
    });
  }

  /// Update connection statistics
  void _updateStats() {
    if (_status != VpnStatus.connected || _connectionStartTime == null) return;

    final connectionTime = DateTime.now().difference(_connectionStartTime!);
    final random = Random();
    
    // Simulate data transfer
    final newBytesReceived = _stats.bytesReceived + random.nextInt(50000) + 10000;
    final newBytesSent = _stats.bytesSent + random.nextInt(20000) + 5000;
    
    // Simulate speeds
    final downloadSpeed = '${(random.nextInt(800) + 200)} KB/s';
    final uploadSpeed = '${(random.nextInt(400) + 100)} KB/s';

    _stats = VpnStats(
      connectionTime: connectionTime,
      bytesReceived: newBytesReceived,
      bytesSent: newBytesSent,
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
    );

    notifyListeners();
  }

  /// Stop all timers
  void _stopTimers() {
    _connectionTimer?.cancel();
    _statsTimer?.cancel();
    _connectionTimer = null;
    _statsTimer = null;
  }

  /// Reset statistics
  void _resetStats() {
    _stats = const VpnStats();
    _connectionStartTime = null;
  }

  /// Update server ping (for testing)
  void updateServerPing(String serverId, int ping) {
    final serverIndex = _servers.indexWhere((s) => s.id == serverId);
    if (serverIndex != -1) {
      _servers[serverIndex] = _servers[serverIndex].copyWith(ping: ping);
      notifyListeners();
    }
  }

  /// Refresh server list (simulate API call)
  Future<void> refreshServers() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Update server stats randomly
    final random = Random();
    for (int i = 0; i < _servers.length; i++) {
      _servers[i] = _servers[i].copyWith(
        ping: random.nextInt(100) + 20,
        load: random.nextDouble() * 0.8,
        isOnline: random.nextBool() || random.nextBool(), // 75% chance online
      );
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
