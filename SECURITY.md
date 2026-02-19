# Security Policy

## Security Overview

Evercrypted is designed with a "Security First" philosophy. We prioritize user privacy and data integrity through rigorous cryptographic protocols and proactive protection measures.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it to us immediately. Your effort helps us keep our users safe.

- **Email**: team@evercrypted.com

Please do not report security vulnerabilities through public GitHub issues. We will acknowledge receipt of your report and aim to provide a resolution or mitigation strategy within a reasonable timeframe.

## Security Protocols

### End-to-End Encryption (E2EE)

All communications in Evercrypted are end-to-end encrypted:
- **Messages**: Individual and group messages use modern key exchange protocols to ensure only the intended recipients can read them.
- **Password-Encryption**: E2E encryption keys can be modified with passwords for each individual message.
- **Media & Files**: Photos, voice-messages and files are encrypted before being uploaded to any service.

### Local Storage Security

- **Database Encryption**: We use [ObjectBox](https://objectbox.io) with custom database encryption for certain fields to protect data on your device.
- **Secure Key Storage**: All sensitive cryptographic keys and authentication tokens are stored using [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), which utilizes the device's secure enclave (iOS Keychain / Android Keystore).

### Protection Measures

- **Custom Secure Keyboard**: Evercrypted includes an integrated keyboard to prevent sensitive data (like passwords or private keys) from being captured by 3rd-party keyboards or OS-level logging.
- **Screenshot Protection**: Sensitive screens (like the chat view or settings) have built-in protection to prevent unauthorized screenshots or screen recordings.
- **Biometric Lock**: Users can enable FaceID, TouchID, or biometric authentication to prevent unauthorized physical access to the app.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: |
| < 1.1.0 | :x:                |

We only provide security updates for the latest stable major version.
