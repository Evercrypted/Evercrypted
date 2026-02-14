import 'package:flutter/material.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SocialProvider { google, apple }

class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: provider == SocialProvider.apple && isDark
              ? Colors.white
              : Colors.transparent,
          side: BorderSide(
            color: isDark ? Colors.white30 : Colors.grey.shade300,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    provider == SocialProvider.apple && isDark
                        ? Colors.black
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(isDark),
                  const SizedBox(width: 12),
                  Text(
                    provider == SocialProvider.google
                        ? 'Continue with Google'
                        : 'Continue with Apple',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: provider == SocialProvider.apple && isDark
                          ? Colors.black
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    if (provider == SocialProvider.google) {
      return SvgPicture.asset(
        'assets/icons/Google_Favicon_2025.svg',
        width: 20,
        height: 20,
      );
    } else {
      // Apple logo
      return Icon(
        Icons.apple,
        size: 22,
        color: isDark ? Colors.black : Colors.black87,
      );
    }
  }
}

/// Compact icon-only social login button
class SocialLoginIconButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool disabled;
  final VoidCallback? onDisabledTap;

  const SocialLoginIconButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: disabled ? onDisabledTap : null,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: OutlinedButton(
            onPressed: (isLoading || disabled) ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isDark ? Colors.white30 : Colors.grey.shade300,
                width: 1,
              ),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        provider == SocialProvider.apple && isDark
                            ? Colors.black
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  )
                : _buildIcon(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    if (provider == SocialProvider.google) {
      return SvgPicture.asset(
        'assets/icons/Google_Favicon_2025.svg',
        width: 28,
        height: 28,
      );
    } else {
      return Icon(
        Icons.apple,
        size: 32,
        color: isDark ? Colors.black : Colors.black87,
      );
    }
  }
}

/// Divider with "or" text for separating social login from email login
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final textColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding * 1.5),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'or',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor)),
        ],
      ),
    );
  }
}
