import 'package:flutter/material.dart';
import '../vpn/vpn_connection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to VPN connection screen
    return const VpnConnectionScreen();
  }
}
