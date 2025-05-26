import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

class TopNavbarLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const TopNavbarLayout({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  State<TopNavbarLayout> createState() => _TopNavbarLayoutState();
}

class _TopNavbarLayoutState extends State<TopNavbarLayout>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDarkMode = false;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Column(
            children: [
              _buildModernNavBar(context),
              Expanded(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernNavBar(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: Border(
                bottom: BorderSide(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildModernLogo(context, currentPath),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildNavigationItems(context, currentPath),
                ),
                _buildSearchAndActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernLogo(BuildContext context, String currentPath) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: InkWell(
            onTap: () {
              if (currentPath != '/') {
                context.go('/');
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.blue.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CargoDham',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationItems(BuildContext context, String currentPath) {
    final navItems = [
      _NavItem('Dashboard', Icons.dashboard_rounded, '/'),
      _NavItem('Book', Icons.add_box_rounded, '/booking'),
      _NavItem('Trips', Icons.local_shipping_rounded, '/trips', badgeCount: 3),
      _NavItem('Payments', Icons.payments_rounded, '/payments', badgeCount: 2),
      _NavItem('Clients', Icons.business_rounded, '/clients'),
      _NavItem('Suppliers', Icons.factory_rounded, '/suppliers'),
      _NavItem('Fleet', Icons.directions_bus_rounded, '/vehicles'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: navItems.map((item) {
          return _buildNavItem(context, item, currentPath);
        }).toList(),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item, String currentPath) {
    final isSelected = _isPathSelected(currentPath, item.route);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (navItems.indexOf(item) * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (currentPath != item.route) {
                      context.go(item.route);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.blue.shade500,
                                Colors.blue.shade600,
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            item.icon,
                            color: isSelected ? Colors.white : Colors.grey[700],
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        if (item.badgeCount != null && item.badgeCount! > 0) ...[
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.red.shade500,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              item.badgeCount.toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.blue.shade600 : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isSearchExpanded ? 280 : 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isSearchExpanded ? Colors.blue.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                      if (!_isSearchExpanded) {
                        _searchController.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                    color: Colors.grey[600],
                  ),
                  iconSize: 20,
                ),
              ),
              if (_isSearchExpanded)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search trips, clients, vehicles...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Notifications
        _buildActionButton(
          icon: Icons.notifications_rounded,
          onPressed: () {},
          badgeCount: 3,
          tooltip: 'Notifications',
        ),
        
        const SizedBox(width: 8),
        
        // Dark mode toggle
        _buildActionButton(
          icon: _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          tooltip: 'Toggle theme',
        ),
        
        const SizedBox(width: 8),
        
        // Profile menu
        _buildProfileMenu(),
        
        // Custom actions
        if (widget.actions != null) ...[
          const SizedBox(width: 16),
          ...widget.actions!,
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    int? badgeCount,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              color: Colors.grey[700],
              padding: EdgeInsets.zero,
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 12),
              const Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 16, color: Colors.red[600]),
              const SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            // Handle profile
            break;
          case 'settings':
            context.go('/settings');
            break;
          case 'logout':
            // Handle logout
            break;
        }
      },
    );
  }

  bool _isPathSelected(String currentPath, String route) {
    if (route == '/') {
      return currentPath == '/';
    }
    return currentPath.startsWith(route);
  }

  // Navigation items data (moved outside build for performance)
  static final navItems = [
    _NavItem('Dashboard', Icons.dashboard_rounded, '/'),
    _NavItem('Book', Icons.add_box_rounded, '/booking'),
    _NavItem('Trips', Icons.local_shipping_rounded, '/trips', badgeCount: 3),
    _NavItem('Payments', Icons.payments_rounded, '/payments', badgeCount: 2),
    _NavItem('Clients', Icons.business_rounded, '/clients'),
    _NavItem('Suppliers', Icons.factory_rounded, '/suppliers'),
    _NavItem('Fleet', Icons.directions_bus_rounded, '/vehicles'),
  ];
}

class _NavItem {
  final String title;
  final IconData icon;
  final String route;
  final int? badgeCount;

  const _NavItem(this.title, this.icon, this.route, {this.badgeCount});
} 