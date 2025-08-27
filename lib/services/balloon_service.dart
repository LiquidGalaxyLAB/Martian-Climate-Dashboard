import 'package:martian_climate_dashboard/entities/balloon_entity.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';

/// A service class managing KML balloon displays on Liquid Galaxy systems.
///
/// The [BalloonService] provides a high-level interface for deploying informational
/// balloons to Liquid Galaxy installations. These balloons serve as interactive
/// information overlays that enhance Mars climate visualizations with contextual
/// data, AI-generated insights, and location-specific details.
///
/// **Balloon Types Supported:**
/// - **Visualization Balloons**: AI-generated climate analysis and insights
/// - **Location Balloons**: Geographic information about specific Mars features
/// - **Interactive Content**: Markdown-formatted text with rich styling
///
/// **Key Features:**
/// - Automatic KML generation with proper geographic positioning
/// - Color-coordinated styling matching visualization color schemes
/// - Remote deployment to specific Liquid Galaxy screen nodes
/// - Static methods for utility balloon operations
///
/// **Integration Points:**
/// - Mars climate visualizations with AI-powered analysis
/// - Location discovery from conversational AI interactions
/// - Educational content display during guided tours
/// - Research annotations for specific geographic features
///
/// Example usage:
/// ```dart
/// // Create service for visualization balloons
/// final balloonService = BalloonService(balloonEntity);
///
/// // Deploy AI-generated climate analysis
/// await balloonService.showVisBalloon(
///   lgService,
///   "Temperature patterns show...",
///   ColorMap.temperature
/// );
///
/// // Show location-specific information
/// await BalloonService.showLocationBalloon(
///   lgService,
///   "Olympus Mons is the largest volcano...",
///   "Olympus Mons",
///   [226.2, 18.65]
/// );
/// ```
class BalloonService {
  /// Configured balloon entity containing display parameters and formatting rules.
  ///
  /// This entity encapsulates balloon styling, positioning, and content formatting
  /// preferences. It includes:
  /// - Color scheme matching the current visualization
  /// - API entity reference for contextual climate data
  /// - Balloon type configuration (info, warning, etc.)
  /// - Geographic positioning parameters for Mars surface placement
  final BalloonEntity balloonEntity;

  /// Creates a balloon service with the specified configuration entity.
  ///
  /// The [balloonEntity] parameter defines the visual appearance and
  /// behavior of balloons created by this service instance. Multiple
  /// service instances can be created with different configurations
  /// for various balloon styles within the same application session.
  ///
  /// Parameters:
  /// - [balloonEntity]: Configuration object defining balloon properties,
  ///   styling, and positioning behavior for all balloons created by this service
  ///
  /// Example:
  /// ```dart
  /// final balloonConfig = BalloonEntity(
  ///   type: BalloonType.info,
  ///   colorMap: ColorMap.temperature,
  ///   apiEntity: currentVisualization,
  /// );
  /// final balloonService = BalloonService(balloonConfig);
  /// ```
  BalloonService(this.balloonEntity);

  /// Displays a climate visualization analysis balloon on Liquid Galaxy.
  ///
  /// This method creates and deploys informational balloons specifically designed
  /// for Mars climate visualization contexts. These balloons typically contain:
  /// - AI-generated analysis of climate patterns
  /// - Statistical summaries of temperature, pressure, or wind data
  /// - Temporal trends and anomalies in atmospheric conditions
  /// - Educational explanations of Mars climate phenomena
  ///
  /// **Balloon Features:**
  /// - Color-coordinated styling matching the visualization color scheme
  /// - Responsive positioning that adapts to current Mars view
  /// - Rich text formatting supporting scientific notation and units
  /// - Integration with Liquid Galaxy's KML rendering system
  ///
  /// **Deployment Process:**
  /// 1. **Content Processing**: Formats AI-generated text with proper styling
  /// 2. **KML Generation**: Creates geographic markup with balloon placemark
  /// 3. **Color Integration**: Applies color scheme matching visualization
  /// 4. **File Deployment**: Transfers KML to designated LG screen node
  /// 5. **Display Activation**: Balloon appears immediately on target screen
  ///
  /// Parameters:
  /// - [lgService]: Connected Liquid Galaxy service for file deployment
  /// - [content]: AI-generated or custom text content for balloon display
  /// - [colorMap]: Color scheme to match current visualization aesthetics
  ///
  /// The balloon is deployed to the screen designated by [lgService.balloonScreen],
  /// typically a secondary display that doesn't interfere with main visualization.
  ///
  /// Example:
  /// ```dart
  /// await balloonService.showVisBalloon(
  ///   lgService,
  ///   "Current Mars temperature analysis shows polar cooling with equatorial warming trends...",
  ///   ColorMap.bluegreenyellowred,
  /// );
  /// ```
  ///
  /// Throws:
  /// - [Exception] if LG connection fails or KML deployment errors occur
  /// - [Exception] for invalid content formatting or balloon generation issues
  Future<void> showVisBalloon(
    LgService lgService,
    String content,
    ColorMap colorMap,
  ) async {
    // Generate KML balloon with formatted content and color coordination
    String xmlContent = balloonEntity.generateVisualizationBalloon(
      colorMap,
      content,
    );

    // Deploy balloon KML to designated Liquid Galaxy screen
    // Uses balloonScreen property to target appropriate display node
    await lgService.execCommand(
      "echo '$xmlContent' > /var/www/html/kml/slave_${lgService.balloonScreen}.kml",
    );
  }

  /// Displays a location-specific information balloon on Liquid Galaxy.
  ///
  /// This static utility method creates balloons for specific Mars geographic
  /// features and locations. Unlike visualization balloons, location balloons
  /// are positioned at precise Mars coordinates and provide detailed information
  /// about specific geographic features, landmarks, or points of interest.
  ///
  /// **Common Use Cases:**
  /// - **Landmark Information**: Details about Olympus Mons, Valles Marineris, polar caps
  /// - **Mission Sites**: Landing locations and rover exploration areas
  /// - **Geographic Features**: Canyon systems, impact craters, volcanic regions
  /// - **AI-Discovered Locations**: Features mentioned during conversational analysis
  ///
  /// **Balloon Characteristics:**
  /// - Precise geographic positioning at specified Mars coordinates
  /// - Prominent title display for feature identification
  /// - Detailed descriptive content with scientific and educational information
  /// - Standardized styling independent of current visualization color scheme
  /// - Persistent display that remains visible during navigation
  ///
  /// **Coordinate System:**
  /// - Longitude: -180° to +180° (West/East from prime meridian)
  /// - Latitude: -90° to +90° (South/North from equator)
  /// - Mars-specific coordinate reference system
  ///
  /// Parameters:
  /// - [lgService]: Connected Liquid Galaxy service for balloon deployment
  /// - [content]: Descriptive text about the geographic feature or location
  /// - [title]: Display name of the location (e.g., "Olympus Mons", "Gale Crater")
  /// - [coordinates]: Two-element list [longitude, latitude] in decimal degrees
  ///
  /// The method automatically handles KML formatting, geographic projection,
  /// and deployment to the appropriate Liquid Galaxy screen node.
  ///
  /// Example:
  /// ```dart
  /// // Show information about Olympus Mons
  /// await BalloonService.showLocationBalloon(
  ///   lgService,
  ///   "Olympus Mons is the largest volcano in the Solar System, standing at 21.9 km tall...",
  ///   "Olympus Mons",
  ///   [226.2, 18.65], // Longitude: 226.2°, Latitude: 18.65°
  /// );
  ///
  /// // Display mission landing site information
  /// await BalloonService.showLocationBalloon(
  ///   lgService,
  ///   "Curiosity rover landed in Gale Crater on August 5, 2012...",
  ///   "Gale Crater - Curiosity Landing Site",
  ///   [137.8, -4.6],
  /// );
  /// ```
  ///
  /// Throws:
  /// - [Exception] for invalid coordinate values or geographic projection errors
  /// - [Exception] if Liquid Galaxy connection fails during deployment
  /// - [Exception] for KML generation or file transfer issues
  static Future<void> showLocationBalloon(
    LgService lgService,
    String content,
    String title,
    List<dynamic> coordinates,
  ) async {
    // Generate location-specific KML balloon with geographic positioning
    String xmlContent = BalloonEntity.generateLocationBalloon(
      content,
      title,
      coordinates,
    );

    // Deploy balloon to designated Liquid Galaxy screen
    // Uses same balloon screen as visualization balloons for consistency
    await lgService.execCommand(
      "echo '$xmlContent' > /var/www/html/kml/slave_${lgService.balloonScreen}.kml",
    );
  }
}
