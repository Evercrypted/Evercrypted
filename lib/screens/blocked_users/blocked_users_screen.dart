import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/services/block_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  void _loadBlockedUsers() {
    setState(() {
      _blockedUsers = BlockService.getBlockedUsers();
    });
  }

  Future<void> _unblockUser(BlockedUser user) async {
    final shouldUnblock = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (shouldUnblock == true) {
      setState(() => _isLoading = true);

      final success = await BlockService.unblockUser(user.uid);

      setState(() => _isLoading = false);

      if (success) {
        _loadBlockedUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} has been unblocked'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to unblock user. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : _buildBlockedUsersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No blocked users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Users you block will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        return _buildBlockedUserTile(user);
      },
    );
  }

  Widget _buildBlockedUserTile(BlockedUser user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatarWithActiveIndicator(
        name: user.name,
        image: null,
        radius: 24,
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        user.email,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: TextButton(
        onPressed: () => _unblockUser(user),
        child: const Text('Unblock'),
      ),
    );
  }
}
