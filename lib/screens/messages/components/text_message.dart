import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';

class TextMessage extends StatefulWidget {
  const TextMessage({super.key, required this.message});

  final ChatMessage message;

  @override
  State<TextMessage> createState() => _TextMessageState();
}

class _TextMessageState extends State<TextMessage> {
  static final _urlRegex = RegExp(
    r'https?://[^\s]+?(?=[.,!?;:)\]>]*(?:\s|$))',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _buildSpans(String text, Color textColor, Color linkColor) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () async {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        };
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
          fontWeight: FontWeight.bold,
        ),
        recognizer: recognizer,
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.message.encryptionStatus == EncryptionStatus.decrypted
        ? widget.message.decrypted!
        : widget.message.text!;

    final textColor = widget.message.isSender
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge!.color!;

    final linkColor = widget.message.isSender ? Colors.white : Colors.blue;

    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: primaryColor
            .withAlpha(((widget.message.isSender ? 1 : 0.1) * 255).round()),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: textColor),
          children: _buildSpans(text, textColor, linkColor),
        ),
      ),
    );
  }
}
