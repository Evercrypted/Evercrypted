import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:pinput/pinput.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/entities/profile/profile_model.dart';
import '../../core/entities/profile/profile_riverpod.dart';
import '../../core/services/settings_service.dart';
import '../../core/socket/chat_socket.dart';
import '../../core/socket/event_types/settings_event_types.dart';
import '../../core/socket/socket_channels.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({Key? key}) : super(key: key);
  static const String routeName = "/2FA";

  @override
  OtpScreenState createState() => OtpScreenState();
}

class OtpScreenState extends ConsumerState<OtpScreen> {
  SettingsService settingsService = SettingsService();

  String? gAuthURI;
  String? gAuthCode;
  final pinController = TextEditingController();
  String? errorMessage;

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(gAuthURI!);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void initState() {
    super.initState();
    ChatSocket.instance.emitWAck(SocketChannelTypes.settings,
        SettingsEventTypes.getActivate2FA, {}).then((resp) {
      print('resp $resp');
      setState(() {
        gAuthURI = resp['URI'];
        gAuthCode = resp['code'];
      });
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  activate2FA(String code) {
    ChatSocket.instance.emitWAck(SocketChannelTypes.settings,
        SettingsEventTypes.activate2FA, {'code': code}).then((resp) async {
      if (resp['activated'] == true && resp['otpToken'] != null) {
        Profile? profile = ref.read(profileProvider);
        profile?.otpActive = true;
        ref.read(profileProvider.notifier).setProfile(profile!);
        await settingsService.updateOtpToken(resp['otpToken']);
        if (context.mounted) Navigator.pop(context);
        showSimpleNotification(
            const Text(
              "Successfully activated 2FA",
              style: TextStyle(color: Colors.white),
            ),
            background: Colors.blue);
      } else {
        pinController.clear();
        setState(() {
          errorMessage = 'Incorrect code';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Profile? profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            profile?.otpActive == true ? "Deactivate 2FA" : "Activate 2FA"),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'To activate 2FA, scan the QR code below with Google Authenticator or Authy mobile apps',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Center(
              child: QrImageView(
                data: gAuthURI ?? 'test',
                version: QrVersions.auto,
                size: 150.0,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              '- OR - ',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              'Enter this code into your 2FA app',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              gAuthCode ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _launchUrl(),
              child: const Text('Open with Google Authenticator'),
            ),
            const SizedBox(height: 10),
            const Divider(
              height: 20,
              thickness: 1,
              color: primaryColor,
            ),
            const SizedBox(height: 10),
            const Text(
                'After you have scanned the QR code or entered the code, enter the 6-digit code from the app below to activate 2FA',
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Pinput(
              length: 6,
              controller: pinController,
              onCompleted: (pin) => activate2FA(pin),
            ),
            const SizedBox(height: 10),
            if (errorMessage != null)
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
