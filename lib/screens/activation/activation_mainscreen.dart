import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboards.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/widgets/terms_and_privacy_links.dart';
import 'package:evercrypted/core/services/apple_iap_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivationMainScreen extends ConsumerStatefulWidget {
  const ActivationMainScreen({super.key});
  static const routeName = '/activation-main-screen';

  @override
  ConsumerState<ActivationMainScreen> createState() =>
      _ActivationMainScreenState();
}

class _ActivationMainScreenState extends ConsumerState<ActivationMainScreen> {
  final AppleIAPService _iapService = AppleIAPService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    await _iapService.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    try {
      final success = await _iapService.purchaseSubscription();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate purchase')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking for previous purchases...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final foundPurchases = await _iapService.restorePurchases();

      if (mounted) {
        if (foundPurchases) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription restored successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No previous purchases found'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLanguagesBottomSheet() {
    final languages = Keyboards.availableKeyboards;
    final abbreviations = Keyboards.abbreviations;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: defaultPadding),
              Center(
                child: Text(
                  'Available Languages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: defaultPadding / 2),
              ...languages.map(
                (lang) => ListTile(
                  leading: Text(
                    abbreviations[lang] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  title: Text(lang),
                ),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        );
      },
    );
  }

  void _showActivationCodeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (BuildContext context) {
        return _ActivationCodeBottomSheet(
          onSuccess: (ProfileSubscription subscription) {
            // Update profile through Auth.setAuth to sync ObjectBox, Auth.user, and listeners
            final profileService = ProfileService();
            final profile = profileService.getProfile();
            if (profile != null) {
              final updatedProfile = profile.copyWith(subscription: subscription);
              Auth.setAuth(profile: updatedProfile);
            }
          },
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _iapService.getSubscriptionProduct();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(defaultPadding),
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
                "Premium Subscription",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(
                "Subscribe to password encrypted messages and access all premium features.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: defaultPadding * 1.5),

              // Features list
              _buildFeatureItem(
                icon: Icons.message,
                title: 'Password Encrypted Messages',
                description:
                    'Add optional password protection to modify encryption keys',
              ),
              const SizedBox(height: defaultPadding),

              _buildFeatureItem(
                icon: Icons.file_present,
                title: 'Password Encrypted File, Photo & Voice Messages',
                description:
                    'Share files, photos and voice messages with full encryption',
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
                title: 'Additional Language Keyboards',
                descriptionWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type in multiple languages with built-in encrypted keyboards',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withAlpha((255 * 0.7).round()),
                          ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _showLanguagesBottomSheet,
                      child: Text(
                        'Check which languages',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),

              _buildFeatureItem(
                icon: Icons.share,
                title: 'Chat Sharing',
                description:
                    'Share chats with one-time invite links or QR codes',
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
                          'Monthly Premium',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Show subscription details if active, otherwise show price and CTA
                    Builder(
                      builder: (context) {
                        final profile = ref.watch(profileProvider);
                        final hasActiveSubscription =
                            profile?.subscription?.isActive == true;

                        if (hasActiveSubscription) {
                          final subscription = profile!.subscription!;
                          return Column(
                            children: [
                              // Active subscription badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Active Subscription',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: defaultPadding),

                              // Subscription details
                              _buildSubscriptionDetail(
                                'Type',
                                subscription.type ?? 'Monthly',
                              ),
                              const SizedBox(height: 8),
                              _buildSubscriptionDetail(
                                subscription.autoRenew ?? true
                                    ? 'Renews on'
                                    : 'Expires on',
                                _formatDate(subscription.endDate),
                              ),
                              const SizedBox(height: 8),
                              _buildSubscriptionDetail(
                                'Auto-renew',
                                subscription.autoRenew ?? true
                                    ? 'Enabled'
                                    : 'Disabled',
                              ),
                              if (subscription.startDate != null)
                                const SizedBox(height: 8),
                              if (subscription.startDate != null)
                                _buildSubscriptionDetail(
                                  'Started on',
                                  _formatDate(subscription.startDate),
                                ),
                            ],
                          );
                        } else {
                          // Show price and subscribe button for non-subscribers
                          return Column(
                            children: [
                              Text(
                                product?.price ?? 'Loading...',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'per month • Cancel anytime',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                        ?..withAlpha((255 * 0.7).round()),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: defaultPadding),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding:
                                        const EdgeInsets.all(defaultPadding),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      _isLoading ? null : () => _subscribe(),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Subscribe',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _restorePurchases(),
                                child: Text(
                                  'Restore Purchases',
                                  style: TextStyle(
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => _showActivationCodeSheet(),
                                icon: Icon(
                                  Icons.card_giftcard,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                label: Text(
                                  'Use Activation Code',
                                  style: TextStyle(
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
              const TermsAndPrivacyLinks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    String? description,
    Widget? descriptionWidget,
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
              if (descriptionWidget != null)
                descriptionWidget
              else if (description != null)
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withAlpha((255 * 0.7).round()),
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha((255 * 0.7).round()),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
        ),
      ],
    );
  }
}

class _ActivationCodeBottomSheet extends StatefulWidget {
  final Function(ProfileSubscription subscription) onSuccess;

  const _ActivationCodeBottomSheet({required this.onSuccess});

  @override
  State<_ActivationCodeBottomSheet> createState() =>
      _ActivationCodeBottomSheetState();
}

class _ActivationCodeBottomSheetState
    extends State<_ActivationCodeBottomSheet> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activation code'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await AppHttpClient.message(
        channel: 'settings',
        type: 'redeemActivationCode',
        payload: {'activationCode': code},
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (result != null && result['subscription'] != null) {
          widget.onSuccess(
            ProfileSubscription.fromJson(
              Map<String, dynamic>.from(result['subscription']),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(defaultPadding * 2),
              topRight: Radius.circular(defaultPadding * 2),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
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
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 60,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
                const SizedBox(height: defaultPadding / 2),
                Text(
                  'Activation Code',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: defaultPadding / 2),
                Text(
                  'Enter your activation code to activate your premium subscription.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: defaultPadding),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.vpn_key),
                    hintText: 'Enter activation code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.all(defaultPadding),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
