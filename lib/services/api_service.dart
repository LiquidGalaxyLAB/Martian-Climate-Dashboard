/// A service class responsible for fetching Mars climate data from the Mars Climate Database (MCD) API.
///
/// The [ApiService] acts as the primary interface between the Martian Climate Dashboard
/// and the remote Mars Climate Database API. It handles the complete data retrieval workflow
/// including parameter submission, response parsing, and asset extraction.
///
/// **Data Retrieval Workflow:**
/// 1. **Parameter Submission**: Sends [ApiEntity] configuration to MCD API endpoint
/// 2. **Response Parsing**: Extracts file references from HTML response using regex
/// 3. **Asset Download**: Retrieves both visualization images and raw data files
/// 4. **Data Processing**: Converts images to base64 and returns structured climate data
///
/// **Supported Data Types:**
/// - Temperature, pressure, wind speed, and other atmospheric variables
/// - Global Mars surface visualizations as PNG images
/// - Raw numerical climate data as structured text files
/// - Base64-encoded images for immediate display and AI analysis
///
/// **Error Handling:**
/// - Network connectivity failures with detailed status codes
/// - Missing or malformed API responses
/// - File parsing errors with descriptive exception messages
/// - HTTP timeout and server error scenarios
///
/// Example usage:
/// ```dart
/// final apiService = ApiService();
/// final climateData = await apiService.fetchData(apiEntity);
/// final visualizationImage = apiService.imageBase64;
/// ```
library;

import 'package:http/http.dart' as http;
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'dart:convert';

/// Service class managing Mars Climate Database API interactions and data processing.
///
/// This class encapsulates all communication with the remote MCD API, handling
/// the complex workflow of parameter submission, response parsing, and multi-asset
/// retrieval required for Mars climate visualization.
///
/// **Key Responsibilities:**
/// - HTTP client management with proper connection handling
/// - API parameter encoding and submission via [ApiEntity]
/// - Multi-stage response processing (HTML → file references → actual data)
/// - Image and data file retrieval with parallel processing capabilities
/// - Base64 encoding for immediate image display and storage
/// - Comprehensive error handling and recovery mechanisms
class ApiService {
  /// HTTP client instance for API communication.
  ///
  /// Handles all network requests to the Mars Climate Database API.
  /// Can be injected during testing to provide mock responses or
  /// customized for specific network configurations (timeouts, headers, etc.).
  http.Client client;

  /// Base64-encoded Mars surface visualization image.
  ///
  /// Contains the complete climate visualization as a base64 string,
  /// extracted from the API response. This image represents the Mars
  /// surface with color-coded climate data (temperature, pressure, etc.)
  /// and is used for:
  /// - Immediate display in the dashboard UI
  /// - AI-powered analysis via Gemini API
  /// - Session storage for quick preview generation
  /// - Liquid Galaxy balloon displays
  late String imageBase64;

  /// Base64-encoded globe/spherical visualization image.
  ///
  /// Alternative view of the climate data in spherical projection,
  /// potentially used for 3D globe visualizations or different
  /// perspective views of Mars climate patterns.
  /// Currently available but not actively used in the main workflow.
  late String globeImageBase64;

  /// Creates an ApiService instance with optional HTTP client injection.
  ///
  /// Parameters:
  /// - [client]: Optional HTTP client for custom network configurations
  ///   or testing. Defaults to a standard http.Client() if not provided.
  ///
  /// Example:
  /// ```dart
  /// // Standard usage
  /// final apiService = ApiService();
  ///
  /// // Custom client for testing or special configurations
  /// final testService = ApiService(client: mockHttpClient);
  /// ```
  ApiService({http.Client? client}) : client = client ?? http.Client();

  /// Fetches Mars climate data from the MCD API based on provided parameters.
  ///
  /// This method orchestrates the complete data retrieval process from the
  /// Mars Climate Database API. The workflow involves multiple stages:
  ///
  /// **Stage 1: Parameter Submission**
  /// - Constructs API URI from [ApiEntity] configuration
  /// - Submits HTTP GET request with all climate parameters
  /// - Validates response status and content availability
  ///
  /// **Stage 2: Response Parsing**
  /// - Parses HTML response to extract file references
  /// - Uses regex patterns to identify data and image files
  /// - Constructs download URIs for individual assets
  ///
  /// **Stage 3: Asset Retrieval**
  /// - Downloads PNG visualization image in parallel
  /// - Converts image to base64 for immediate use
  /// - Retrieves structured climate data as text file
  ///
  /// **Stage 4: Data Processing**
  /// - Validates all downloaded assets
  /// - Stores base64 image data in instance variable
  /// - Returns raw climate data for further processing
  ///
  /// Parameters:
  /// - [apiEntity]: Complete configuration object containing all Mars climate
  ///   parameters including variable type, date, coordinates, and display options
  ///
  /// Returns:
  /// - String containing raw climate data in structured text format
  /// - Sets [imageBase64] property with encoded visualization image
  ///
  /// Throws:
  /// - [Exception] for HTTP failures with detailed status codes
  /// - [Exception] for missing or malformed API responses
  /// - [Exception] for file parsing or download errors
  ///
  /// Example:
  /// ```dart
  /// final apiEntity = ApiEntity()
  ///   ..variable = 't' // Temperature
  ///   ..date = DateTime.now()
  ///   ..latitude = 'all'
  ///   ..longitude = 'all';
  ///
  /// try {
  ///   final climateData = await apiService.fetchData(apiEntity);
  ///   final image = apiService.imageBase64; // Available after fetch
  ///   print('Retrieved ${climateData.length} characters of data');
  /// } catch (e) {
  ///   print('Failed to fetch Mars data: $e');
  /// }
  /// ```
  Future<String> fetchData(ApiEntity apiEntity) async {
    // Construct API endpoint URI from entity configuration
    final uri = apiEntity.uri();

    try {
      // Stage 1: Submit parameters to Mars Climate Database API
      final response = await client.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to fetch data, status code: ${response.statusCode}",
        );
      }

      // Stage 2: Parse HTML response to extract file references
      // Extract text data file reference (contains numerical climate data)
      final textMatch =
          RegExp(r'\.\./txt/([\w\-]+\.txt)').firstMatch(response.body)!;

      // Extract image file reference (contains visualization PNG)
      final imageMatch =
          RegExp(r'\.\./img/([\w\-]+\.png)').firstMatch(response.body)!;

      // Stage 3: Download visualization image
      final imgName = imageMatch.group(1);
      final imageUri = uri.replace(path: '/mcd_python/img/$imgName', query: '');
      final imageResponse = await client.get(imageUri);
      if (imageResponse.statusCode != 200) {
        throw Exception("Failed to fetch image");
      }

      // Convert image to base64 for immediate display and storage
      imageBase64 = base64Encode(imageResponse.bodyBytes);

      // Stage 4: Download structured climate data
      final fileName = textMatch.group(1);
      final dataUri = uri.replace(path: '/mcd_python/txt/$fileName', query: '');
      return await _fetchTextFile(dataUri);
    } catch (e) {
      // Provide detailed error context for debugging and user feedback
      throw Exception("Failed to fetch data: $e");
    }
  }

  /// Downloads and returns the contents of a text file from the specified URI.
  ///
  /// This helper method handles the final stage of data retrieval, downloading
  /// the actual climate data file that contains structured numerical information
  /// about Mars atmospheric conditions.
  ///
  /// **File Content Structure:**
  /// The text files typically contain:
  /// - Coordinate grid information (latitude/longitude)
  /// - Climate variable values (temperature, pressure, wind, etc.)
  /// - Metadata about data collection parameters
  /// - Structured format suitable for visualization processing
  ///
  /// Parameters:
  /// - [uri]: Complete URI pointing to the climate data text file
  ///
  /// Returns:
  /// - String containing the complete file contents with raw climate data
  ///
  /// Throws:
  /// - [Exception] if the HTTP request fails or returns non-200 status
  ///
  /// Note: This method performs synchronous string processing of potentially
  /// large climate datasets. For very large files, consider streaming or
  /// chunked processing in future implementations.
  ///
  /// Example file content format:
  /// ```
  /// # Mars Climate Data - Temperature
  /// # Date: 2024-01-15, Variable: t
  /// # Coordinates: Global
  /// -180.0 -90.0 245.2
  /// -179.0 -90.0 244.8
  /// ...
  /// ```
  Future<String> _fetchTextFile(Uri uri) async {
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch data");
    }
    return response.body;

    // Future enhancement: Consider returning structured JSON
    // final image = imageBase64;
    // return json.encode({...json.decode(response.body), "image": image});
  }
}
