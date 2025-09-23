import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/authPdr.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // 🔹 Enhanced confirmation dialog with better UX
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Confirm Logout",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            "Are you sure you want to log out? You'll need to sign in again to access your account.",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    auth.logout(context);
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final String userName = auth.user?.userName.toString() ?? "Inspector";
    final String buid = auth.user?.buid.toString() ?? "N/A";
    final String companyName = auth.user?.companyName.toString() ?? "N/A";
    final String locationName = auth.user?.locationName.toString() ?? "N/A";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildEnhancedHeader(
                  context,
                  userName,
                  buid,
                  companyName,
                  locationName,
                  auth,
                ),
              ),
              const SizedBox(height: 20),
              // Summary Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Inspection Summary",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Review your recent inspection activities",
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 24),

                    // Summary Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: "Pre-Gate Summary",
                            subtitle: "View initial inspections",
                            icon: Icons.input_rounded,
                            color: const Color(0xFF3B82F6),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/pre-gate-summary',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: "Post-Gate Summary",
                            subtitle: "View detailed reports",
                            icon: Icons.output_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/post-gate-summary',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Main Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Inspection Process",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Complete your inspection in 3 simple steps",
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 32),
                    _buildCleanActionsList(context),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Enhanced header with company & location info
  Widget _buildEnhancedHeader(
    BuildContext context,
    String userName,
    String buid,
    String companyName,
    String locationName,
    AuthProvider auth,
  ) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                // Name + ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome,", style: TextStyle(color: Colors.white70)),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "ID: $buid",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Company & Location
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.business, companyName),
                _infoChip(Icons.location_on, locationName),
              ],
            ),
          ],
        ),
        // Logout (top-right)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => _confirmLogout(context, auth),
              tooltip: "Logout",
              icon: const Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white,
                size: 24,
              ),
              style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Summary Cards for PreGate and PostGate summaries
  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),

            // Arrow indicator
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean actions list with connectors
  Widget _buildCleanActionsList(BuildContext context) {
    final actions = [
      {
        'step': '1',
        'title': 'Pre-Gate IN Survey',
        'subtitle': 'Start container inspection',
        'icon': Icons.play_circle_outline_rounded,
        'color': const Color(0xFF3B82F6),
        'route': '/pre-gate-in',
      },
      {
        'step': '2',
        'title': 'Post-Gate IN Survey',
        'subtitle': 'Continue detailed inspection',
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFFF59E0B),
        'route': '/post-gate-in',
      },
      {
        'step': '3',
        'title': 'Final Out Confirmation',
        'subtitle': 'Complete and confirm exit',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF10B981),
        'route': '/final-out',
      },
    ];

    return Column(
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        final isLast = index == actions.length - 1;

        return Stack(
          children: [
            // Connector line
            if (!isLast)
              Positioned(
                left: 24,
                top: 60,
                bottom: 0,
                child: Container(width: 2, color: const Color(0xFFE5E7EB)),
              ),

            // Action Card
            _buildSimpleActionCard(
              context,
              step: action['step'] as String,
              title: action['title'] as String,
              subtitle: action['subtitle'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: () =>
                  Navigator.pushNamed(context, action['route'] as String),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSimpleActionCard(
    BuildContext context, {
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Step Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Icon and Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 12),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFFD1D5DB),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
