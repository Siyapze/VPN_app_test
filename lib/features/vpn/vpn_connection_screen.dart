import 'package:flutter/material.dart';
import '../../core/services/vpn_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/vpn_server.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_constants.dart';

class VpnConnectionScreen extends StatefulWidget {
  const VpnConnectionScreen({super.key});

  @override
  State<VpnConnectionScreen> createState() => _VpnConnectionScreenState();
}

class _VpnConnectionScreenState extends State<VpnConnectionScreen>
    with TickerProviderStateMixin {
  final VpnService _vpnService = VpnService();
  final AuthService _authService = AuthService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _vpnService.addListener(_onVpnStateChanged);
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserData();
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  void _onVpnStateChanged() {
    if (_vpnService.isConnected) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _vpnService.removeListener(_onVpnStateChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleConnection() async {
    if (_vpnService.isConnected || _vpnService.isConnecting) {
      await _vpnService.disconnect();
    } else {
      // Check if user has access
      if (_currentUser == null || !_currentUser!.hasActiveAccess) {
        _showAccessDeniedDialog();
        return;
      }

      // Get best server for user
      final server = _vpnService.getBestServer(
        isPremiumUser: _currentUser!.isPremium,
      );

      await _vpnService.connect(server);
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Access Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You need an active subscription or trial to use the VPN.',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Start free trial
                    if (_currentUser != null) {
                      await _authService.startFreeTrial(_currentUser!.uid);
                      await _loadUserData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enable Demo Access'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              // Premium upgrade option removed for demo
            ],
          ),
    );
  }

  void _showServerSelection() {
    if (_currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              final availableServers = _vpnService.getAvailableServers(
                isPremiumUser: _currentUser!.isPremium,
              );

              return Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Select Server',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: availableServers.length,
                        itemBuilder: (context, index) {
                          final server = availableServers[index];
                          final isSelected =
                              _vpnService.currentServer?.id == server.id;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(
                                int.parse(
                                  '0xFF${server.qualityColor.substring(1)}',
                                ),
                              ),
                              child: Text(
                                server.countryCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(server.name),
                            subtitle: Text(
                              '${server.city} • ${server.qualityText} • ${server.ping}ms',
                            ),
                            trailing:
                                isSelected
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                    )
                                    : server.isPremium
                                    ? const Icon(
                                      Icons.star,
                                      color: Color(0xFFFF9800),
                                    )
                                    : null,
                            onTap: () async {
                              Navigator.of(context).pop();
                              if (_vpnService.isConnected) {
                                await _vpnService.disconnect();
                              }
                              await _vpnService.connect(server);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vpnService,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // User status card
                if (_currentUser != null) _buildUserStatusCard(),
                const SizedBox(height: 32),

                // Connection button
                _buildConnectionButton(),

                const SizedBox(height: 24),

                // Connection status
                _buildConnectionStatus(),

                const SizedBox(height: 32),

                // Server selection
                _buildServerSelection(),

                const SizedBox(height: 32),

                // Statistics (only when connected)
                if (_vpnService.isConnected) _buildStatistics(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _currentUser!.hasActiveAccess
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF9800),
            _currentUser!.hasActiveAccess
                ? const Color(0xFF66BB6A)
                : const Color(0xFFFFA726),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentUser!.isPremium
                ? 'Premium User'
                : _currentUser!.isInTrial
                ? 'Free Trial Active'
                : 'Free User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_currentUser!.isInTrial)
            Text(
              '${_currentUser!.trialDaysRemaining} days remaining',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            )
          else if (_currentUser!.isPremium)
            Text(
              '${_currentUser!.premiumDaysRemaining} days remaining',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            )
          else
            const Text(
              'Start your free trial to access VPN',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _vpnService.isConnected ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _toggleConnection,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getConnectionColor().withValues(alpha: 0.3),
                    _getConnectionColor(),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getConnectionColor().withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child:
                    _vpnService.isConnecting
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                        : Icon(
                          _vpnService.isConnected
                              ? Icons.power_off
                              : Icons.power,
                          size: 80,
                          color: Colors.white,
                        ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    String statusText;
    Color statusColor;

    switch (_vpnService.status) {
      case VpnStatus.connected:
        statusText = 'Connected';
        statusColor = const Color(0xFF4CAF50);
        break;
      case VpnStatus.connecting:
        statusText = 'Connecting...';
        statusColor = const Color(0xFFFF9800);
        break;
      case VpnStatus.disconnecting:
        statusText = 'Disconnecting...';
        statusColor = const Color(0xFFFF9800);
        break;
      case VpnStatus.error:
        statusText = 'Connection Error';
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusText = 'Disconnected';
        statusColor = Colors.grey;
    }

    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        if (_vpnService.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _vpnService.errorMessage!,
              style: const TextStyle(color: Color(0xFFF44336)),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildServerSelection() {
    final currentServer = _vpnService.currentServer;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.public, color: Color(0xFF1565C0)),
        title: Text(currentServer?.name ?? 'Select Server'),
        subtitle:
            currentServer != null
                ? Text('${currentServer.city} • ${currentServer.qualityText}')
                : const Text('Tap to choose a server'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _showServerSelection,
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _vpnService.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Duration', stats.formattedConnectionTime),
                _buildStatItem('Download', stats.downloadSpeed),
                _buildStatItem('Upload', stats.uploadSpeed),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Downloaded', stats.formattedBytesReceived),
                _buildStatItem('Uploaded', stats.formattedBytesSent),
                _buildStatItem('Total', stats.totalDataUsage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getConnectionColor() {
    switch (_vpnService.status) {
      case VpnStatus.connected:
        return const Color(0xFF4CAF50);
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return const Color(0xFFFF9800);
      case VpnStatus.error:
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF1565C0);
    }
  }
}
