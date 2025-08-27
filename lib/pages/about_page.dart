import 'package:flutter/material.dart';

/// A comprehensive information page displaying details about the Martian Climate Dashboard application.
///
/// This page provides a modern, responsive interface showcasing project information including:
/// - Application branding with styled logo presentation
/// - Author and contributor acknowledgments in organized sections
/// - Project description and objectives
/// - Organizational logos and affiliations
///
/// The page features a card-based layout with Material Design 3 theming support,
/// responsive design constraints, and proper dark/light mode adaptation. Content
/// is organized into distinct sections for optimal readability and visual hierarchy.
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const AboutPage()),
/// );
/// ```
class AboutPage extends StatelessWidget {
  /// Creates an AboutPage widget with responsive design and Material 3 theming.
  ///
  /// This stateless widget adapts to different screen sizes and theme modes,
  /// providing a consistent and professional information display.
  const AboutPage({super.key});

  /// Horizontal padding constant for consistent spacing throughout the page.
  ///
  /// Applied to the main content container to ensure proper margins
  /// on both sides of the screen across different device sizes.
  static const double _hPad = 24.0;

  /// Vertical padding constant for consistent spacing throughout the page.
  ///
  /// Applied to the main content container to provide appropriate
  /// top and bottom margins for comfortable reading.
  static const double _vPad = 20.0;

  /// Maximum content width constraint for optimal readability.
  ///
  /// Prevents content from becoming too wide on large screens,
  /// maintaining comfortable line lengths and visual balance.
  /// Content is centered when screen width exceeds this limit.
  static const double _maxContentWidth = 900.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      /// Standard app bar with simple title and back navigation
      appBar: AppBar(title: const Text('About')),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              /// Responsive width constraint for optimal viewing on all devices
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: _hPad,
                  vertical: _vPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Header section with application branding and logo
                    /// Features themed container with adaptive opacity
                    _CardSection(
                      child: Column(
                        children: [
                          /// Logo container with adaptive theming
                          /// Opacity adjusts based on dark/light mode for optimal contrast
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                              // ignore: deprecated_member_use
                              .withOpacity(isDark ? 0.25 : 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Image.asset(
                                'assets/Martian Climate Dashboard-nobg.png',
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// Main application title with enhanced typography
                          Text(
                            'Martian Climate Dashboard',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Author information section
                    /// Displays the primary developer in a dedicated card
                    _CardSection(child: _AuthorBlock()),

                    const SizedBox(height: 16),

                    /// Main mentor recognition section
                    /// Highlights the primary project mentor in a styled container
                    _CardSection(child: _MainMentorBlock()),

                    /// Mentors and contributors acknowledgment section
                    /// Comprehensive recognition of all project supporters
                    const SizedBox(height: 0),
                    _CardSection(child: _MentorsBlock()),

                    const SizedBox(height: 16),

                    /// Project description section with informational content
                    /// Explains the application's purpose and technical approach
                    _CardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _SectionTitle(
                            icon: Icons.info_outline,
                            title: 'About the Project',
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The project aims to provide real-time and historical climate data visualization from Mars on Liquid Galaxy through an engaging and interactive experience. A Flutter-based mobile app will retrieve and process atmospheric data from the Mars Climate Database (MCD), presenting it with compelling visualizations on Liquid Galaxy.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Organizational logos section
                    /// Displays partner and sponsor logos with rounded corners
                    _CardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/Logos.png',
                              height: 320,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A widget displaying author information in a formatted section.
///
/// Presents the primary developer's name with consistent styling
/// and proper section labeling using an icon and title combination.
/// The author name is displayed with enhanced typography for emphasis.
class _AuthorBlock extends StatelessWidget {
  /// Creates an author information block widget.
  const _AuthorBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// Section header with person icon and "Author" label
        const _SectionTitle(icon: Icons.person_outline, title: 'Author'),
        const SizedBox(height: 8),

        /// Author name container with padding for visual separation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

          child: const Text(
            'Mohit Sharma',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// A widget displaying main mentor information in a highlighted section.
///
/// Presents the primary project mentor with enhanced visual emphasis
/// through a themed background container. The styling adapts to the
/// current theme's dark/light mode for optimal contrast and readability.
class _MainMentorBlock extends StatelessWidget {
  /// Creates a main mentor information block widget.
  const _MainMentorBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// Section header with premium icon emphasizing importance
        const _SectionTitle(
          icon: Icons.workspace_premium_outlined,
          title: 'Main Mentor',
        ),
        const SizedBox(height: 8),

        /// Styled container with adaptive theming for mentor name
        /// Background opacity adjusts based on theme brightness
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(
              theme.brightness == Brightness.dark ? 0.20 : 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Victor Carreras',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// A widget displaying comprehensive mentor and contributor acknowledgments.
///
/// Presents detailed recognition of all project mentors, team members,
/// and contributors in a styled container with adaptive theming. Includes
/// the complete acknowledgment text with proper formatting and reference
/// to the Liquid Galaxy project website.
class _MentorsBlock extends StatelessWidget {
  /// Creates a mentors and contributors acknowledgment block widget.
  const _MentorsBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// Section header with groups icon representing team collaboration
        const _SectionTitle(
          icon: Icons.groups_outlined,
          title: 'Mentors and Contributors',
        ),
        const SizedBox(height: 8),

        /// Comprehensive acknowledgment text in styled container
        /// Features adaptive background theming and proper text formatting
        Container(
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(
              theme.brightness == Brightness.dark ? 0.20 : 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(14),
          child: const Text(
            'Thanks to my main mentor Victor Carreras and secondary mentor Víctor Pérez. And thanks to the team of the Liquid Galaxy LAB Lleida, Headquarters of the Liquid Galaxy project: Alba, Paula, Josep, Jordi, Oriol, Sharon, Alejandro, Marc, and admin Andreu, for their continuous support on my project. Info in www.liquidgalaxy.eu',
            style: TextStyle(fontSize: 16, height: 1.35),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }
}

/// A reusable widget for creating section titles with consistent styling.
///
/// Combines an icon with title text to create visually appealing section
/// headers throughout the about page. Supports both left-aligned and
/// centered layouts with proper spacing and typography.
///
/// The title uses enhanced typography with appropriate font weight and
/// letter spacing for improved readability and visual hierarchy.
class _SectionTitle extends StatelessWidget {
  /// The icon displayed alongside the section title.
  ///
  /// Provides visual context and helps users quickly identify section content.
  final IconData icon;

  /// The text content of the section title.
  ///
  /// Should be concise and descriptive of the section's content.
  final String title;

  /// Whether to center the title and icon horizontally.
  ///
  /// Defaults to false for left alignment. When true, centers the
  /// entire title row within its container.
  final bool center;

  /// Creates a section title widget with icon and text.
  ///
  /// Parameters:
  /// - [icon]: The icon to display before the title text
  /// - [title]: The title text content
  /// - [center]: Whether to center the title (defaults to false)
  const _SectionTitle({
    required this.icon,
    required this.title,
    // ignore: unused_element_parameter
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        /// Icon with consistent sizing across all section titles
        Icon(icon, size: 20),
        const SizedBox(width: 8),

        /// Title text with enhanced typography for visual hierarchy
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
      ],
    );
  }
}

/// A wrapper widget providing consistent card styling throughout the about page.
///
/// Creates Material Design 3 compatible cards with consistent elevation,
/// shadow styling, rounded corners, and padding. The card appearance
/// adapts to the current theme with appropriate shadow colors and opacity.
///
/// This widget ensures visual consistency across all content sections
/// while providing proper content separation and depth perception.
class _CardSection extends StatelessWidget {
  /// The child widget to be contained within the styled card.
  ///
  /// Typically contains section content such as text, images, or
  /// other widgets that benefit from card-style presentation.
  final Widget child;

  /// Creates a card section wrapper with consistent styling.
  ///
  /// Parameters:
  /// - [child]: The widget to be wrapped in the styled card
  const _CardSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      /// Subtle elevation for depth without overwhelming the content
      elevation: 2,

      /// Adaptive shadow color with reduced opacity for subtle effect
      // ignore: deprecated_member_use
      shadowColor: theme.shadowColor.withOpacity(0.15),

      /// Rounded corners for modern, friendly appearance
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: Padding(
        /// Consistent internal padding for all card content
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: child,
      ),
    );
  }
}
