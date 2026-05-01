# GastoMigo

GastoMigo is a daily expenses tracker application built with Flutter. It helps users manage their personal finances by tracking income and expenditures with a modern and intuitive interface.

## 🚀 Features

- **Passwordless Authentication**: Securely sign in using email links via Firebase Authentication.
- **PIN Enrollment**: Enhanced security with a custom PIN for app access.
- **Transaction Tracking**: Add and categorize daily transactions with ease.
- **Profile Management**: Personalized user profiles and verified accounts.
- **Modern UI**: Clean and responsive design following Material Design principles.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Core) & Custom REST API
- **Local Security**: [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- **Networking**: [http](https://pub.dev/packages/http)
- **Cryptography**: [crypto](https://pub.dev/packages/crypto)

## 📁 Project Structure

The project follows a feature-based architecture:

- `lib/app`: App-level configuration and main entry points.
- `lib/core`: Shared widgets, constants, themes, and network utilities.
- `lib/features`: Modules grouped by functionality (Auth, Home, Transactions, etc.).
- `lib/repositories`: Data abstraction layer for Firebase and API interactions.

## 🏁 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase account and project setup

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/gastomigo.git
    cd gastomigo
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Firebase:**
    - Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective directories, or use the Firebase CLI to configure:
    ```bash
    flutterfire configure
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

---

*Made with ❤️ for better financial management.*
