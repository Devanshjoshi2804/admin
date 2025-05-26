import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Builder(
              builder: (context) {
                try {
                  return Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  );
                } catch (e) {
                  // Fallback if asset loading fails
                  return Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Search',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () {},
            tooltip: 'Toggle theme',
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: ClipOval(
              child: Builder(
                builder: (context) {
                  try {
                    return Image.asset(
                      'assets/images/avatar.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.person, size: 18, color: Colors.blue),
                    );
                  } catch (e) {
                    return const Icon(Icons.person, size: 18, color: Colors.blue);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (actions != null) ...actions!,
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      try {
                        return Image.asset(
                          'assets/images/logo_white.png',
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CARGODHAM',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                        );
                      } catch (e) {
                        // Fallback if asset loading fails
                        return Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CARGODHAM',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Freight Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildNavItem(
              context,
              'Dashboard',
              Icons.dashboard_outlined,
              '/',
              highlightIfPathStartsWith: '/',
            ),
            _buildNavItem(
              context,
              'FTL Booking',
              Icons.add_box_outlined,
              '/booking',
              highlightIfPathStartsWith: '/booking',
            ),
            _buildNavItem(
              context,
              'FTL Trips',
              Icons.local_shipping_outlined,
              '/trips',
              highlightIfPathStartsWith: '/trips',
              badgeCount: 1,
            ),
            _buildNavItem(
              context,
              'Payment Dashboard',
              Icons.payments_outlined,
              '/payments',
              highlightIfPathStartsWith: '/payments',
              badgeCount: 1,
            ),
            _buildNavItem(
              context,
              'Client Management',
              Icons.business_outlined,
              '/clients',
              highlightIfPathStartsWith: '/clients',
            ),
            _buildNavItem(
              context,
              'Supplier Management',
              Icons.factory_outlined,
              '/suppliers',
              highlightIfPathStartsWith: '/suppliers',
            ),
            _buildNavItem(
              context,
              'Vehicle Management',
              Icons.directions_bus_outlined,
              '/vehicles',
              highlightIfPathStartsWith: '/vehicles',
            ),
            const Divider(),
            _buildNavItem(
              context,
              'Settings',
              Icons.settings_outlined,
              '/settings',
            ),
            _buildNavItem(
              context,
              'Help & Support',
              Icons.help_outline,
              '/help',
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route, {
    String? highlightIfPathStartsWith,
    int? badgeCount,
  }) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isSelected = highlightIfPathStartsWith != null
        ? currentPath.startsWith(highlightIfPathStartsWith)
        : currentPath == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: badgeCount != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            )
          : null,
      selected: isSelected,
      onTap: () {
        if (currentPath != route) {
          context.go(route);
          Navigator.pop(context); // Close the drawer
        }
      },
    );
  }
} 