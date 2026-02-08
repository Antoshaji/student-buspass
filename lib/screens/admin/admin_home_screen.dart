import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'add_route_screen.dart';
import 'pass_approval_screen.dart';
import 'automated_bus_pass_screen.dart';
import 'view_routes_screen.dart';
import 'map_nfc_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Light clean background
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              size: 32,
              color: Color(0xFF64748B),
            ),
            onPressed: () {
              // Future: Profile or just logout
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Hello Admin ${user.name}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 50),
            // Grid Layout
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine crossAxisCount based on width (responsive)
                int crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                // For the specific look in screenshot (2x2 centered),
                // we'll stick to a max width container if screen is very wide

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: GridView.count(
                      crossAxisCount:
                          crossAxisCount, // 2 columns for wider screens, 1 for mobile
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 2.2, // Rectangular cards
                      children: [
                        _buildMenuCard(
                          context,
                          title: 'Add New Route',
                          icon: Icons.add_location_alt_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddRouteScreen(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Pass Approvals',
                          icon: Icons.how_to_reg,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PassApprovalScreen(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Automated Bus Pass',
                          icon: Icons.confirmation_number_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AutomatedBusPassScreen(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'View Active Routes',
                          icon: Icons.map_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewRoutesScreen(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Map NFC Card',
                          icon: Icons.nfc_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MapNfcScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Light shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: const Color(0xFF475569)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
