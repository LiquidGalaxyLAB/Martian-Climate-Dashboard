import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/entities/saved_session.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/widgets/circular_globe.dart';

/// A compact, tappable card summarizing a previously saved visualization.
///
/// RecentVisualizationCard displays:
/// - The human-readable parameter name (via [parameterMap] from the ApiEntity.variable)
/// - The run date (formatted as "Mon DD, YYYY")
/// - The scenario label (ApiEntity.atomsScenario) with ellipsis if too long
/// - A globe preview generated from a base64-encoded equirectangular projection
///
/// Intended use:
/// - As an item in a "Recent visualizations" list/grid
/// - To restore a session when tapped (handled via [onTap])
class RecentVisualizationCard extends StatelessWidget {
  /// The saved visualization/session to summarize and preview.
  ///
  /// Expected fields used:
  /// - [SavedSession.apiEntity.variable] to resolve a title from [parameterMap]
  /// - [SavedSession.apiEntity.date] for the subtitle
  /// - [SavedSession.apiEntity.atomsScenario] for the scenario description
  /// - [SavedSession.imageBase64] for the globe preview image
  final SavedSession item;

  /// Invoked when the card is tapped.
  ///
  /// Typically navigates to a detail screen or restores the session.
  final VoidCallback onTap;

  /// Creates a recent visualization summary card.
  const RecentVisualizationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  /// Builds the styled card with text metadata on the left and a globe preview on the right.
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
              // Textual metadata (title, date, scenario)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parameter title resolved from the variable key.
                    Text(
                      parameterMap[item.apiEntity.variable] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Human-readable date line.
                    Text(
                      _formatDate(item.apiEntity.date),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    // Scenario description, truncated for long content.
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
              // Right-side globe preview rendered from an equirectangular base64 image.
              // Note: Adjust crop rect according to your image’s projection/size.
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

  /// Formats a [DateTime] as "Mon DD, YYYY".
  ///
  /// Returns "No date" when [dt] is null.
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
