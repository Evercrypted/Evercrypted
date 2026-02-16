import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/deep_link/app_link_service.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class InviteQRScannerScreen extends StatefulWidget {
  const InviteQRScannerScreen({super.key});

  @override
  State<InviteQRScannerScreen> createState() => _InviteQRScannerScreenState();
}

class _InviteQRScannerScreenState extends State<InviteQRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ChatService _chatService = ChatService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final uri = Uri.tryParse(barcode!.rawValue!);
    if (uri == null) return;

    final token = AppLinkService.parseInviteToken(uri);
    if (token == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    await _joinChat(token);
  }

  Future<void> _joinChat(String token) async {
    // Check subscription
    if (Auth.user?.activated != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Active subscription required to join via invite link')),
      );
      setState(() => _isProcessing = false);
      _controller.start();
      return;
    }

    try {
      final Chat chat = await _chatService.joinChatViaInvite(token: token);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${chat.name ?? "Group Chat"}"')),
      );
      Navigator.pop(context, chat);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Invite QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with scanning area indicator
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _isProcessing
                      ? 'Joining chat...'
                      : 'Point camera at invite QR code',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
