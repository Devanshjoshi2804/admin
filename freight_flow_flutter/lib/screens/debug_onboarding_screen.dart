import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';

class DebugOnboardingScreen extends StatelessWidget {
  const DebugOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Debug Onboarding',
      actions: [],
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onboarding System Debug',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test all onboarding flows with improved validation',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildOnboardingCard(
                    context,
                    title: 'Client Onboarding',
                    subtitle: '4-step process with validation',
                    icon: Icons.business_rounded,
                    color: Colors.green,
                    route: '/clients/onboarding',
                  ),
                  _buildOnboardingCard(
                    context,
                    title: 'Supplier Onboarding',
                    subtitle: '6-step process with documents',
                    icon: Icons.local_shipping_rounded,
                    color: Colors.blue,
                    route: '/suppliers/onboarding',
                  ),
                  _buildOnboardingCard(
                    context,
                    title: 'Vehicle Onboarding',
                    subtitle: '5-step process with compliance',
                    icon: Icons.directions_car_rounded,
                    color: Colors.orange,
                    route: '/vehicles/onboarding',
                  ),
                  _buildOnboardingCard(
                    context,
                    title: 'Management Screens',
                    subtitle: 'View all entities',
                    icon: Icons.dashboard_rounded,
                    color: Colors.purple,
                    onTap: () => _showManagementOptions(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Validation Improvements',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Next button is now disabled when validation fails\n'
                    '• Clear error messages show exactly what\'s missing\n'
                    '• Visual indicators show validation status\n'
                    '• Field-specific validation with proper length checks',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? route,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? (route != null ? () => context.push(route) : null),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagementOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Management Screens'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.business_rounded, color: Colors.green.shade600),
              title: const Text('Clients'),
              onTap: () {
                Navigator.pop(context);
                context.go('/clients');
              },
            ),
            ListTile(
              leading: Icon(Icons.local_shipping_rounded, color: Colors.blue.shade600),
              title: const Text('Suppliers'),
              onTap: () {
                Navigator.pop(context);
                context.go('/suppliers');
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_car_rounded, color: Colors.orange.shade600),
              title: const Text('Vehicles'),
              onTap: () {
                Navigator.pop(context);
                context.go('/vehicles');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 