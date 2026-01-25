import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../provider/auth_provider.dart';

class MainSidebar extends StatelessWidget {
  const MainSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDentist = authProvider.userRole.toLowerCase() != 'student';

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F33),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          // Logo and Title
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'PalPath',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    isActive: navProvider.isActive('Dashboard'),
                    onTap: () => navProvider.setPage('Dashboard'),
                  ),
                  _SidebarItem(
                    icon: Icons.auto_awesome,
                    label: 'Disease Detection',
                    isActive: navProvider.isActive('Disease Detection'),
                    enabled: isDentist,
                    onTap: () => navProvider.setPage('Disease Detection'),
                  ),
                  _SidebarItem(
                    icon: Icons.people_outline,
                    label: 'Patients',
                    isActive: navProvider.isActive('Patients'),
                    enabled: isDentist,
                    onTap: () => navProvider.setPage('Patients'),
                  ),
                  _SidebarItem(
                    icon: Icons.history_outlined,
                    label: 'Scan History',
                    isActive: navProvider.isActive('Scan History'),
                    onTap: () => navProvider.setPage('Scan History'),
                  ),
                  _SidebarItem(
                    icon: Icons.quiz_outlined,
                    label: 'AI Quiz',
                    isActive: navProvider.isActive('AI Quiz'),
                    onTap: () => navProvider.setPage('AI Quiz'),
                  ),
                  _SidebarItem(
                    icon: Icons.list_alt_outlined,
                    label: 'My Quizzes',
                    isActive: navProvider.isActive('My Quizzes'),
                    onTap: () => navProvider.setPage('My Quizzes'),
                  ),
                  _SidebarItem(
                    icon: Icons.library_books_outlined,
                    label: 'Lecture Notes',
                    isActive: navProvider.isActive('Lecture Notes'),
                    enabled: isDentist,
                    onTap: () => navProvider.setPage('Lecture Notes'),
                  ),
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: navProvider.isActive('Settings'),
                    onTap: () => navProvider.setPage('Settings'),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => navProvider.setPage('Profile'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            authProvider.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                authProvider.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authProvider.userRole,
                                style: const TextStyle(
                                  color: Color(0xFF9B9B9B),
                                  fontSize: 12,
                                ),
                              ),
                              const Text(
                                'View profile',
                                style: TextStyle(
                                  color: Color(0xFF9B9B9B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool enabled;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? onTap
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access restricted to dentists'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: !enabled
                  ? const Color(0xFF9B9B9B).withOpacity(0.08)
                  : isActive
                  ? const Color(0xFF4A90E2).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: !enabled
                      ? const Color(0xFF6B7280)
                      : isActive
                      ? const Color(0xFF4A90E2)
                      : const Color(0xFF9B9B9B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: !enabled
                        ? const Color(0xFF6B7280)
                        : isActive
                        ? Colors.white
                        : const Color(0xFF9B9B9B),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
