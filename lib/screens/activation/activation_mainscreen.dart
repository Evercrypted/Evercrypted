import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class ActivationMainScreen extends StatefulWidget {
  const ActivationMainScreen({super.key});
  static const routeName = '/activation-main-screen';

  @override
  State<ActivationMainScreen> createState() => _ActivationMainScreenState();
}

class _ActivationMainScreenState extends State<ActivationMainScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(defaultPadding * 2),
            topRight: Radius.circular(defaultPadding * 2),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(defaultPadding),
          padding: const EdgeInsets.fromLTRB(
            defaultPadding,
            0,
            defaultPadding,
            defaultPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 60,
                color: Theme.of(context).textTheme.titleMedium!.color,
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(
                "Premium License Required",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(
                "You need a premium license to send end-to-end encrypted or password-protected messages.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: defaultPadding * 1.5),

              // Features list
              _buildFeatureItem(
                icon: Icons.enhanced_encryption,
                title: 'Quantum-Safe End-to-End Encryption',
                description: 'XChaCha20-Poly1305 with Kyber1024 key exchange',
              ),
              const SizedBox(height: defaultPadding),

              _buildFeatureItem(
                icon: Icons.message,
                title: 'Password Encrypted Messages',
                description:
                    'Add optional password protection to modify encryption keys - messages get unreadable without the appropriate password',
              ),
              const SizedBox(height: defaultPadding),

              _buildFeatureItem(
                icon: Icons.file_present,
                title: 'Encrypted File & Voice Messages',
                description:
                    'Share files and voice messages with full encryption',
              ),
              const SizedBox(height: defaultPadding),

              _buildFeatureItem(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                description: 'Extra security layer for your account',
              ),
              const SizedBox(height: defaultPadding),

              _buildFeatureItem(
                icon: Icons.keyboard,
                title: 'Secure In-App Keyboard',
                description: 'Prevent keylogging and data leaks',
              ),

              const SizedBox(height: defaultPadding * 1.5),

              // CTA
              Container(
                padding: const EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withAlpha((255 * 0.3).round()),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified,
                          color: primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lifetime License',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One-time payment for lifetime access',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
