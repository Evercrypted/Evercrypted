# Evercrypted

Evercrypted is a high-security, privacy-focused messaging application built with Flutter. It provides a seamless and secure communication experience with end-to-end encryption for all messages and calls.

## Key Features

- **Secure Messaging**: End-to-end encrypted text, voice, and file sharing.
- **Privacy First**: No tracking, no data collection, and screenshot protection.
- **Biometric Security**: Protect your chats with FaceID, TouchID, or fingerprint.
- **Custom Keyboard**: Integrated secure keyboard for sensitive data entry.
- **Contact Management**: Secure sharing and adding of contacts via QR codes and deep links.
- **Rich Media Support**: Send photos, voice messages, and files;

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (iOS & Android)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Database**: [ObjectBox](https://objectbox.io) for high-performance local storage.
- **Cryptography**: Custom implementation via `flutter_ever_crypto`.
- **Backend**: Integration with Firebase for messaging and authentication.
- **Networking**: [RHTTP](https://pub.dev/packages/rhttp) and Socket.IO for real-time communication.

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.0)
- CocoaPods (for iOS development)
- Android Studio / VS Code

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/evercrypted.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Security Disclosure

Privacy and security are our top priorities. If you discover any security vulnerabilities, please refer to our [Security Policy](SECURITY.md) (coming soon) or contact the maintainers directly.

## Contributing

We welcome contributions! Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before getting started.

## Cryptography Notice

This distribution includes cryptographic software. The country in which you currently reside may have restrictions on the import, possession, use, and/or re-export to another country, of encryption software. BEFORE using any encryption software, please check your country's laws, regulations and policies concerning the import, possession, or use, and re-export of encryption software, to see if this is permitted. See http://www.wassenaar.org/ for more information.

## License

Copyright 2013-2025 Evercrypted LLC

Licensed under the GNU AGPLv3: https://www.gnu.org/licenses/agpl-3.0.html
