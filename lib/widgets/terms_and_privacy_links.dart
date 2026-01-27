import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndPrivacyLinks extends StatelessWidget {
  const TermsAndPrivacyLinks({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $urlString'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: () =>
              _launchUrl(context, 'https://evercrypted.com/terms-of-service'),
          child: Text(
            'Terms of Service',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Text(
          ' and ',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .color!
                    .withAlpha((255 * 0.5).round()),
              ),
        ),
        GestureDetector(
          onTap: () =>
              _launchUrl(context, 'https://evercrypted.com/privacy-policy'),
          child: Text(
            'Privacy Policy',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
