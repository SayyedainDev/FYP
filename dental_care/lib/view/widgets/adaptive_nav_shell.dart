import 'package:flutter/material.dart';
import '../../core/responsive/app_breakpoints.dart';
import '../../core/theme/app_tokens.dart';

class NavDestination {
  final String label;
  final IconData icon;

  const NavDestination({
    required this.label,
    required this.icon,
  });
}

class AdaptiveNavShell extends StatelessWidget {
  final String currentPage;
  final List<NavDestination> destinations;
  final ValueChanged<String> onSelect;
  final Widget child;
  final String title;
  final List<Widget> actions;

  const AdaptiveNavShell({
    super.key,
    required this.currentPage,
    required this.destinations,
    required this.onSelect,
    required this.child,
    required this.title,
    this.actions = const [],
  });

  int get _currentIndex {
    final index = destinations.indexWhere((item) => item.label == currentPage);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final isDesktop = AppBreakpoints.isDesktop(context);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => onSelect(destinations[index].label),
          destinations: destinations
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 280,
              color: AppColors.sidebarDark,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            color: AppColors.sidebarAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'PalPath',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.sidebarOnDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: destinations.length,
                        itemBuilder: (context, index) {
                          final destination = destinations[index];
                          final selected = destination.label == currentPage;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              selected: selected,
                              tileColor: selected
                                  ? AppColors.sidebarDarkSoft
                                  : Colors.transparent,
                              selectedTileColor: AppColors.sidebarDarkSoft,
                              iconColor: selected
                                  ? AppColors.sidebarAccent
                                  : AppColors.sidebarOnDark
                                      .withValues(alpha: 0.78),
                              textColor: selected
                                  ? AppColors.sidebarOnDark
                                  : AppColors.sidebarOnDark
                                      .withValues(alpha: 0.9),
                              selectedColor: AppColors.sidebarAccent,
                              leading: Icon(destination.icon),
                              title: Text(destination.label),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () => onSelect(destination.label),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Material(
                    elevation: 1,
                    child: SizedBox(
                      height: 64,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            ...actions,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                onSelect(destinations[index].label),
            labelType: NavigationRailLabelType.all,
            destinations: destinations
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
