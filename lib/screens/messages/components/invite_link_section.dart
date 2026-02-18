import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/deep_link/app_link_service.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/screens/messages/components/invite_qr_bottom_sheet.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class InviteLinkSection extends StatefulWidget {
  final Chat chat;
  final VoidCallback onChatUpdated;

  const InviteLinkSection({
    super.key,
    required this.chat,
    required this.onChatUpdated,
  });

  @override
  State<InviteLinkSection> createState() => _InviteLinkSectionState();
}

class _InviteLinkSectionState extends State<InviteLinkSection> {
  final ChatService _chatService = ChatService();
  bool _isGenerating = false;
  bool _isOneTime = true; // Default to one-time

  bool get _isCreatorOrAdmin {
    final userId = Auth.user?.uid;
    if (userId == null) return false;
    final participant =
        widget.chat.participants.where((p) => p.uid == userId).firstOrNull;
    return participant != null &&
        (participant.isCreator == true || participant.isAdmin == true);
  }

  bool get _isSubscribed => Auth.user?.activated == true;

  bool get _hasPermanentLink =>
      widget.chat.inviteLinks.any((l) => l.isPermanent);

  Future<void> _generateLink() async {
    if (_isGenerating) return;

    if (!_isOneTime && _hasPermanentLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A permanent invite link already exists')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final inviteLink = await _chatService.generateInviteLink(
        chatUid: widget.chat.uid,
        type: _isOneTime ? 'one_time' : 'permanent',
      );

      if (!mounted) return;

      // Update local chat model so the list reflects the new link
      widget.chat.inviteLinks = [...widget.chat.inviteLinks, inviteLink];

      final url = AppLinkService.buildJoinChatLink(inviteLink.token).toString();

      // Show options: share, copy, or show QR
      _showLinkActions(url, inviteLink.token);
      widget.onChatUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate invite link: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _isOneTime = true;
        });
      }
    }
  }

  void _showLinkActions(String url, String token) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => InviteQRBottomSheet(
        url: url,
        token: token,
        chatName: widget.chat.name ?? 'Group Chat',
      ),
    );
  }

  Future<void> _revokeLink(InviteLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invite Link'),
        content: const Text(
            'This link will stop working. Anyone with it won\'t be able to join.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatService.revokeInviteLink(
        chatUid: widget.chat.uid,
        token: link.token,
      );
      // Update local chat model so the list reflects the removal
      widget.chat.inviteLinks =
          widget.chat.inviteLinks.where((l) => l.token != link.token).toList();
      widget.onChatUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite link revoked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show for group chats, creators/admins, subscribed users
    if (widget.chat.isOneToOne || !_isCreatorOrAdmin || !_isSubscribed) {
      return const SizedBox.shrink();
    }

    final inviteLinks = [...widget.chat.inviteLinks]
      ..sort((a, b) => a.isPermanent == b.isPermanent
          ? 0
          : a.isPermanent
              ? -1
              : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.link, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Invite Links',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Toggle between one-time and permanent (hide if permanent link already exists)
              if (!_hasPermanentLink)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('One-time', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Permanent', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_isOneTime},
                  onSelectionChanged: (v) =>
                      setState(() => _isOneTime = v.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return primaryColor.withAlpha((255 * 0.15).round());
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return primaryColor;
                      }
                      return null;
                    }),
                    side: WidgetStateProperty.all(
                      BorderSide(
                          color: primaryColor.withAlpha((255 * 0.3).round())),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Generate button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGenerating ? null : _generateLink,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_link),
              label: Text(
                _isGenerating
                    ? 'Generating...'
                    : _hasPermanentLink
                        ? 'Generate One-time Link'
                        : 'Generate ${_isOneTime ? "One-time" : "Permanent"} Link',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(
                    color: primaryColor.withAlpha((255 * 0.5).round())),
              ),
            ),
          ),
        ),

        // List of active invite links
        if (inviteLinks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Active Links (${inviteLinks.length})',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...() {
            int oneTimeIndex = 0;
            return inviteLinks.map((link) {
              if (!link.isPermanent) oneTimeIndex++;
              return _buildLinkTile(link, oneTimeIndex);
            });
          }(),
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLinkTile(InviteLink link, int oneTimeNumber) {
    final url = AppLinkService.buildJoinChatLink(link.token).toString();

    return ListTile(
      dense: true,
      leading: link.isPermanent
          ? const Icon(Icons.all_inclusive, color: Colors.blue, size: 20)
          : CircleAvatar(
              radius: 12,
              backgroundColor: Colors.orange.withAlpha((255 * 0.15).round()),
              child: Text(
                '$oneTimeNumber',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
      title: Text(
        link.isPermanent ? 'Permanent link' : 'One-time link #$oneTimeNumber',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        'Created ${timeago.format(link.createdAt)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.qr_code, size: 20),
            onPressed: () => _showLinkActions(url, link.token),
            tooltip: 'Show QR code',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: 'Join my encrypted group chat: $url'),
            ),
            tooltip: 'Share',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            tooltip: 'Copy',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
            onPressed: () => _revokeLink(link),
            tooltip: 'Revoke',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
