# Profile-Hub Frontend Flutter Application

This document explains how to set up, build, and run the Flutter application for Android, iOS, and Web platforms.

---

## Clone the Repository

Start by cloning the repository from GitHub:

```bash
git clone https://github.com/Profile-Hub/profile-fe.git
cd profile-fe
```

---

## Prerequisites

Ensure that the following tools are installed on your machine:

### 1. Flutter SDK
- Install Flutter by following the official documentation: [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
- Verify installation:

```bash
flutter doctor
```

### 2. Other Tools
- Android Studio or Xcode (for Android/iOS development)
- Chrome or any modern browser (for web development)
- Ensure you have the necessary platform-specific dependencies installed (e.g., Android SDK, iOS tools).

---

## Install Dependencies

Run the following command to install required Flutter packages:

```bash
flutter pub get
```

---

## Running the Application

### 1. Android

#### Prerequisites:
- Ensure an Android device or emulator is connected and running.
- Enable USB debugging for physical devices.

#### Command:
```bash
flutter run -d android
```

### 2. iOS

#### Prerequisites:
- macOS with Xcode installed.
- Set up your development environment for iOS as per the [Flutter iOS setup guide](https://docs.flutter.dev/get-started/install/macos#ios-setup).

#### Command:
```bash
flutter run -d ios
```

### 3. Web

#### Prerequisites:
- A modern web browser (e.g., Chrome).

#### Command:
```bash
flutter run -d web
```

---

## Additional Tips

### Build Commands:
- **Android APK:**

  ```bash
  flutter build apk --release
  ```

- **iOS Release Build:**

  ```bash
  flutter build ios --release
  ```

- **Web Release Build:**

  ```bash
  flutter build web
  ```

### Run Specific Device:
- List available devices:

  ```bash
  flutter devices
  ```

- Run with a specific device:

  ```bash
  flutter run -d <device-id>
  ```

### Debugging:
- For debugging and hot reload, use:

  ```bash
  flutter run
  ```

---

## Folder Structure

- `lib/`: Main application code.
- `assets/`: Static assets such as images and fonts.
- `test/`: Automated test cases.

---

## Troubleshooting

### Common Issues:
1. **Dependencies not installed:** Run `flutter pub get`.
2. **Device not detected:** Ensure your emulator or device is properly set up.
3. **Permission issues on macOS:** Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.

---

You're all set! Happy coding! 🚀
