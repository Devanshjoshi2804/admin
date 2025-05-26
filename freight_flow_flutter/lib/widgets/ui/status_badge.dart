import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Map<String, Color>? customColors;

  const StatusBadge({
    super.key,
    required this.status,
    this.customColors,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    // Normalize status string by trimming and converting to title case
    final normalizedStatus = status.trim();

    // Check if we have a custom color for this status
    if (customColors != null && customColors!.containsKey(normalizedStatus)) {
      color = customColors![normalizedStatus]!;
    } else {
      // Use default color logic
      switch (normalizedStatus) {
        // Trip statuses
        case 'Booked':
          color = Colors.blue;
          break;
        case 'In Transit':
          color = Colors.orange;
          break;
        case 'Delivered':
          color = Colors.purple;
          break;
        case 'Completed':
          color = Colors.green.shade700;
          break;
          
        // Payment statuses
        case 'Not Started':
          color = Colors.grey;
          break;
        case 'Initiated':
          color = Colors.blue.shade600;
          break;
        case 'Pending':
          color = Colors.orange.shade600;
          break;
        case 'Paid':
          color = Colors.green.shade600;
          break;
          
        default:
          color = Colors.grey.shade600;
      }
    }
    
    // Determine icon based on status
    switch (normalizedStatus) {
      // Trip statuses
      case 'Booked':
        icon = Icons.schedule;
        break;
      case 'In Transit':
        icon = Icons.local_shipping;
        break;
      case 'Delivered':
        icon = Icons.check_circle_outline;
        break;
      case 'Completed':
        icon = Icons.done_all;
        break;
        
      // Payment statuses
      case 'Not Started':
        icon = Icons.not_started_outlined;
        break;
      case 'Initiated':
        icon = Icons.pending_actions;
        break;
      case 'Pending':
        icon = Icons.hourglass_top;
        break;
      case 'Paid':
        icon = Icons.payments_outlined;
        break;
        
      default:
        icon = Icons.help_outline;
    }

    // Try to fix the RenderFlex overflow issue by controlling width
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(127)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              normalizedStatus,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 