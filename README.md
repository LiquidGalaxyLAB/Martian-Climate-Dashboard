# Martian Climate Dashboard

<p align="center">
  <img alt="Martian Climate Dashboard" src="./assets/Martian Climate Dashboard-nobg.png" height="320">
</p>

<p align="center">
  <img alt="License" src="https://img.shields.io/github/license/LiquidGalaxyLAB/Martian-Climate-Dashboard?color=%23FFC857">
  <img alt="Top language" src="https://img.shields.io/github/languages/top/LiquidGalaxyLAB/Martian-Climate-Dashboard?color=%230090C1">
  <img alt="Languages" src="https://img.shields.io/github/languages/count/LiquidGalaxyLAB/Martian-Climate-Dashboard?color=%234CFA72">
  <img alt="Repository size" src="https://img.shields.io/github/repo-size/LiquidGalaxyLAB/Martian-Climate-Dashboard?color=%2375DEFF">
</p>

## Summary

- [About](#about)
- [Getting Started](#getting-started)
- [Building the App](#building-the-app)
- [Testing](#testing)
- [Features](#features)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## About

Martian Climate Dashboard is a Flutter application for visualizing Martian climate data, including temperature, pressure, and other atmospheric parameters. The app supports data interpolation, AI insights, and interactive visualizations.

## Getting Started

## Prerequisites

Before running the app, ensure the following are installed:

- Flutter (latest stable version recommended)
- Dart SDK (comes with Flutter)
- Android Studio or VS Code with Flutter plugin
- An Android emulator or physical device

## Common Issues

- If `flutter run` fails, ensure Flutter is added to your system PATH.
- Run `flutter doctor` to check for missing dependencies.
- Make sure an emulator or device is connected before running the app.


Before you begin, ensure you have [Git](https://git-scm.com/) and [Flutter](https://flutter.dev) installed. See the [Flutter documentation](https://docs.flutter.dev) for setup instructions.

Clone the repository:

```bash
git clone https://github.com/LiquidGalaxyLAB/Martian-Climate-Dashboard.git
cd Martian-Climate-Dashboard
```

To run the app on a connected device or emulator:

```bash
flutter run
```

## Building the App

To build a release APK:

```bash
flutter build apk
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## Testing

To run all unit and widget tests:

```bash
flutter test
```

## Features

- Visualize Martian climate data (temperature, pressure, etc.)
- Interpolate and grid data for smooth visualizations
- AI-powered insights for summary generation and answering user queries
- Interactive UI for selecting parameters and date ranges

## Usage

1. Launch the app on your device or emulator.
2. Select the climate variable and date range you want to visualize.
3. Toggle grid lines and other visualization options as needed.
4. Press "Visualize Data" to generate the visualization.
5. Use the AI Insights feature to generate summaries or get answers to questions about the Martian climate.

## Contributing

Contributions are welcome! Please open issues or pull requests for bug fixes, features, or documentation improvements.

1. Fork the repository.
2. Create your feature branch: `git checkout -b feature/YourFeature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/YourFeature`
5. Open a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
