import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/entities/saved_session.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/widgets/circular_globe.dart';

class RecentVisualizationCard extends StatelessWidget {
  final SavedSession item;
  final VoidCallback onTap;

  const RecentVisualizationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parameterMap[item.apiEntity.variable] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item.apiEntity.date),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.apiEntity.atomsScenario ?? 'Default Scenario',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SphereProjectionImage(
                base64Image: item.imageBase64,
                crop: const Rect.fromLTRB(160, 88, 179, 81),
                size: const Size(130, 130),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'No date';
    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return '${monthNames[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
