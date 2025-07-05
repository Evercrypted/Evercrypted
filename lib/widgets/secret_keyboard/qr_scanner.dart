import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanner extends StatelessWidget {
  const QrScanner({super.key, required this.whenScanned});
  final Function whenScanned;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultPadding * 2),
          topRight: Radius.circular(defaultPadding * 2),
        ),
      ),
      padding: EdgeInsets.all(defaultPadding * 2),
      child: SizedBox(
        height: 400,
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: MobileScanner(
                onDetect: (BarcodeCapture result) {
                  whenScanned(result.barcodes.first.rawValue);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: defaultPadding * 2),
            PrimaryButton(
              text: 'Cancel',
              press: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
