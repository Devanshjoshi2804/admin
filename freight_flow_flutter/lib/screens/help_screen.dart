import 'package:flutter/material.dart';
import 'package:freight_flow_flutter/widgets/layout/top_navbar_layout.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TopNavbarLayout(
      title: 'Help & Support',
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
                const Text('Help & Support'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'Help & Support Center',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find answers to frequently asked questions and get support.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for help topics',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick help
            const Text(
              'Quick Help',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    'User Guide',
                    'Learn how to use the system',
                    Icons.menu_book_outlined,
                    () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickHelpCard(
                    'Video Tutorials',
                    'Watch step-by-step guides',
                    Icons.play_circle_outline,
                    () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    'Contact Support',
                    'Get help from our team',
                    Icons.support_agent_outlined,
                    () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickHelpCard(
                    'Report Issue',
                    'Submit a bug report',
                    Icons.bug_report_outlined,
                    () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // FAQ
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How do I create a new booking?',
              'To create a new booking, navigate to the FTL Booking page from the main menu and fill in the required details in the booking form.',
            ),
            _buildFaqItem(
              'How do I track a shipment?',
              'You can track a shipment by going to the FTL Trips page and clicking on the specific trip you want to track. The trip details page shows the current status and location of the shipment.',
            ),
            _buildFaqItem(
              'How do I update payment information?',
              'Payment information can be updated from the Payment Dashboard. Select the trip you want to update and click on the payment details tab.',
            ),
            _buildFaqItem(
              'How do I upload documents?',
              'Documents can be uploaded from the trip details page. Navigate to the Documents tab and click on the "Upload New Document" button.',
            ),
            _buildFaqItem(
              'How do I add a new client or supplier?',
              'New clients and suppliers can be added from their respective management pages. Click on the "Add New" button and fill in the required information.',
            ),
            const SizedBox(height: 24),
            
            // Contact info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need More Help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      'Email',
                      'support@freightflow.com',
                      Icons.email_outlined,
                    ),
                    _buildContactItem(
                      'Phone',
                      '+91 1234567890',
                      Icons.phone_outlined,
                    ),
                    _buildContactItem(
                      'Live Chat',
                      'Available 9 AM - 6 PM IST',
                      Icons.chat_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blue, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 