import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  static const routeName = '/delete-account';

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;
  bool _confirmationChecked = false;

  Future<void> _clearAllLocalData() async {
    // Clear all ObjectBox boxes
    ObxInit.obx.messages.removeAll();
    ObxInit.obx.chats.removeAll();
    ObxInit.obx.contacts.removeAll();
    ObxInit.obx.profiles.removeAll();
    ObxInit.obx.contactRequests.removeAll();
    ObxInit.obx.actionQueues.removeAll();
    ObxInit.obx.settings.removeAll();

    // Clear files and cache directories
    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = await getTemporaryDirectory();

    // Delete all files in documents directory
    if (await directory.exists()) {
      await directory.list(recursive: true).forEach((entity) async {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory && entity.path != directory.path) {
          await entity.delete(recursive: true);
        }
      });
    }

    // Delete all files in cache/temp directory
    if (await cacheDirectory.exists()) {
      await cacheDirectory.list(recursive: true).forEach((entity) async {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory && entity.path != cacheDirectory.path) {
          await entity.delete(recursive: true);
        }
      });
    }
  }

  Future<void> _deleteAccount() async {
    if (!_confirmationChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you understand the consequences'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      // Send delete account request to server
      await AppHttpClient.message(
        channel: 'profile',
        type: 'delete-account',
        payload: {},
      );

      // Clear all local data
      await _clearAllLocalData();

      // Clear authentication
      await Auth.clearAuth();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        elevation: 0,
      ),
      body: _isDeleting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Deleting your account...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.1).round()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 64,
                        color: Colors.red[700],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Warning Title
                  Text(
                    'Permanent Account Deletion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Warning Description
                  Text(
                    'This action cannot be undone. Once you delete your account, there is no going back.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // What will be deleted section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withAlpha((255 * 0.3).round()),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What will be permanently deleted:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDeleteItem(
                          icon: Icons.person_outline,
                          text: 'Your account and profile information',
                        ),
                        _buildDeleteItem(
                          icon: Icons.message_outlined,
                          text: 'All your messages and conversations',
                        ),
                        _buildDeleteItem(
                          icon: Icons.contacts_outlined,
                          text: 'All your contacts and contact requests',
                        ),
                        _buildDeleteItem(
                          icon: Icons.attach_file_outlined,
                          text: 'All uploaded files and media',
                        ),
                        _buildDeleteItem(
                          icon: Icons.settings_outlined,
                          text: 'All settings and preferences',
                        ),
                        _buildDeleteItem(
                          icon: Icons.storage_outlined,
                          text: 'All local data on this device',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Confirmation Checkbox
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      value: _confirmationChecked,
                      onChanged: (value) {
                        setState(() {
                          _confirmationChecked = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.red,
                      title: Text(
                        'I understand that this action is permanent and cannot be undone',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmationChecked ? _deleteAccount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete My Account Permanently',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDeleteItem({required IconData icon, required String text}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.red[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
