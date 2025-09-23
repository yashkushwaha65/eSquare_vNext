import 'package:flutter/material.dart';

import 'badge.dart';

class RecentSurveyCard extends StatelessWidget {
  final String containerNo;
  final String line;
  final String sizeType;
  final String status;
  final bool needsRepair;
  final DateTime date;

  const RecentSurveyCard({
    super.key,
    required this.containerNo,
    required this.line,
    required this.sizeType,
    required this.status,
    required this.needsRepair,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      "completed" => Colors.green,
      "gate-out" => Colors.purple,
      "repair" => Colors.orange,
      _ => Colors.grey,
    };

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(Icons.inventory, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    containerNo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "$line • $sizeType",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (needsRepair)
                    Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Needs Repair",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BadgeWidget(label: status, color: statusColor),
                Text(
                  "${date.day}/${date.month}/${date.year}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
