# Hyzer - Disc Golf Scorecard App

A Flutter application for tracking disc golf scores. Built with Flutter and Firebase.

## Features

- Create and manage scorecards for disc golf games
- Track scores for multiple players
- View previous scorecards
- Edit course names
- Real-time score updates
- Clean, modern UI

## Prerequisites

- Flutter SDK (latest stable version)
- Xcode (for iOS development)
- CocoaPods
- Firebase account

## Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/hyzer-app.git
cd hyzer-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Firebase Setup:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add an iOS app to your Firebase project
   - Download the `GoogleService-Info.plist` file
   - Place it in the `ios/Runner` directory
   - Enable Authentication and Firestore in your Firebase project

4. Generate Firebase configuration:
   - Install the Firebase CLI
   - Run `flutterfire configure` to generate the `firebase_options.dart` file
   - The generated file will be automatically added to `.gitignore`

5. Run the app:
```bash
flutter run
```

## Important Notes

### Sensitive Information
The following files contain sensitive information and should never be committed to version control:
- `lib/firebase_options.dart`
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

These files are automatically added to `.gitignore`. If you need to set up the project on a new machine, you'll need to:
1. Generate new Firebase configuration files
2. Place them in the appropriate directories
3. Run `flutterfire configure` to generate the `firebase_options.dart` file

### Development
- The app is currently configured for iOS only
- Make sure to run `pod install` in the `ios` directory after cloning

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend services
- The disc golf community for inspiration
