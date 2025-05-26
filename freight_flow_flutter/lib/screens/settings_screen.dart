import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                ),
                const Text('Settings'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'System Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Settings sections
            _buildSettingsCard(
              'Account Settings',
              [
                _buildSettingsItem(
                  'Profile Information',
                  'Update your name, email, and profile picture',
                  Icons.person_outline,
                  () {},
                ),
                _buildSettingsItem(
                  'Password',
                  'Change your password',
                  Icons.lock_outline,
                  () {},
                ),
                _buildSettingsItem(
                  'Two-Factor Authentication',
                  'Add an extra layer of security',
                  Icons.security_outlined,
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              'Appearance',
              [
                _buildSettingsItem(
                  'Theme',
                  'Light or Dark mode',
                  Icons.dark_mode_outlined,
                  () {},
                ),
                _buildSettingsItem(
                  'Language',
                  'Change application language',
                  Icons.language_outlined,
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              'Notifications',
              [
                _buildSettingsItem(
                  'Email Notifications',
                  'Configure email alerts',
                  Icons.email_outlined,
                  () {},
                ),
                _buildSettingsItem(
                  'Push Notifications',
                  'Configure mobile app notifications',
                  Icons.notifications_outlined,
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              'System',
              [
                _buildSettingsItem(
                  'API Keys',
                  'Manage API access keys',
                  Icons.vpn_key_outlined,
                  () {},
                ),
                _buildSettingsItem(
                  'Export Data',
                  'Export system data',
                  Icons.download_outlined,
                  () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> items) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 