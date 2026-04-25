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
    final isStudent = authProvider.userRole.toLowerCase() == 'student';
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
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
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PalPath',
                  style: TextStyle(
                    color: colorScheme.onSurface,
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
                  // Common items
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Overview',
                    isActive: navProvider.isActive('Overview'),
                    onTap: () => navProvider.setPage('Overview'),
                  ),

                  // Professor/Dentist-only items
                  if (!isStudent) ...[
                    _SidebarItem(
                      icon: Icons.auto_awesome,
                      label: 'Disease Detection',
                      isActive: navProvider.isActive('Disease Detection'),
                      onTap: () => navProvider.setPage('Disease Detection'),
                    ),
                    _SidebarItem(
                      icon: Icons.people_outline,
                      label: 'Patients',
                      isActive: navProvider.isActive('Patients'),
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
                      label: 'Create Quiz',
                      isActive: navProvider.isActive('Create Quiz'),
                      onTap: () => navProvider.setPage('Create Quiz'),
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
                      onTap: () => navProvider.setPage('Lecture Notes'),
                    ),
                  ],

                  // Student-specific items
                  if (isStudent) ...[
                    _SidebarItem(
                      icon: Icons.quiz_outlined,
                      label: 'Available Quizzes',
                      isActive: navProvider.isActive('Available Quizzes'),
                      onTap: () => navProvider.setPage('Available Quizzes'),
                    ),
                    _SidebarItem(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'My Results',
                      isActive: navProvider.isActive('My Results'),
                      onTap: () => navProvider.setPage('My Results'),
                    ),
                    _SidebarItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      isActive: navProvider.isActive('Notifications'),
                      onTap: () => navProvider.setPage('Notifications'),
                    ),
                  ],

                  // Common items
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: navProvider.isActive('Settings'),
                    onTap: () => navProvider.setPage('Settings'),
                  ),
                  // Ensure Assignments is visible for both roles
                  _SidebarItem(
                    icon: Icons.assignment_outlined,
                    label: 'Assignments',
                    isActive: navProvider.isActive('Assignments'),
                    onTap: () => navProvider.setPage('Assignments'),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
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
                          backgroundColor:
                              colorScheme.onSurface.withValues(alpha: 0.2),
                          child: Text(
                            authProvider.initials,
                            style: TextStyle(
                              color: colorScheme.onSurface,
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
                                isStudent
                                    ? authProvider.userName ?? 'Student'
                                    : authProvider.displayName,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authProvider.userRole,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'View profile',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
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
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (route) => false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.7),
                      ),
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

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
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
