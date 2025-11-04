import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivationTokensScreen extends ConsumerStatefulWidget {
  final Profile profile;

  const ActivationTokensScreen({
    super.key,
    required this.profile,
  });

  static const routeName = '/activation-tokens';

  @override
  ActivationTokensScreenState createState() => ActivationTokensScreenState();
}

class ActivationTokensScreenState
    extends ConsumerState<ActivationTokensScreen> {
  final EvercryptedTextController activationCodeController =
      EvercryptedTextController();
  bool isLoading = false;

  @override
  void dispose() {
    activationCodeController.dispose();
    super.dispose();
  }

  void _redeemActivationCode() async {
    final activationCode = activationCodeController.text.trim();

    if (activationCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activation code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Send activation code redemption request through socket
      final response = await AppHttpClient.message(
        channel: SocketChannelTypes.settings,
        type: SettingsEventTypes.redeemActivationCode,
        payload: {'activationCode': activationCode},
      );

      if (mounted) {
        if (response['success'] == true) {
          // Update the local profile with new activation token quantity
          final currentProfile = ref.read(profileProvider);
          if (currentProfile != null &&
              response['activationTokenQuantity'] != null) {
            final updatedProfile = currentProfile.copyWith(
              activationTokenQuantity: response['activationTokenQuantity'],
            );

            // Sync the updated profile
            final profileService = ProfileService();
            profileService.syncProfile(updatedProfile);
          }

          // Clear the input field
          activationCodeController.clear();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ??
                  'Activation code redeemed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['error'] ?? 'Failed to redeem activation code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        // Show error message for network/other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider) ?? widget.profile;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Activation Tokens',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activation Tokens',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Share premium licenses with friends',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Token Count Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha((255 * 0.05).round()),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withAlpha((255 * 0.2).round()),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${profile.activationTokenQuantity}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    profile.activationTokenQuantity == 1
                        ? 'Activation Token Available'
                        : 'Activation Tokens Available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Use activation tokens to give premium licenses to your friends and family. Each token activates one user permanently.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Activation Code Input Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have an activation code?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your code to redeem activation tokens',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  EvercryptedTextField(
                    controller: activationCodeController,
                    enabled: !isLoading,
                    hintText: 'Enter activation code',
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _redeemActivationCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Redeem Code',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
