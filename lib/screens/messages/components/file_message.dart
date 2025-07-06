import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';

class FileMessage extends StatefulWidget {
  final ChatMessage message;

  const FileMessage({super.key, required this.message});

  @override
  State<FileMessage> createState() => _FileMessageState();
}

class _FileMessageState extends State<FileMessage>
    with SingleTickerProviderStateMixin {
  dynamic file;
  bool needDownload = false;
  bool downloadInProgress = false;

  MessageService messageService = MessageService();

  @override
  void initState() {
    super.initState();

    setFile();
  }

  @override
  didUpdateWidget(FileMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    setFile();
  }

  setFile() async {
    late dynamic downloaded;
    if (widget.message.queueId != null) {
      downloaded =
          await messageService.getMessageFile(queueId: widget.message.queueId);
    } else {
      downloaded = await messageService.getMessageFile(
          chatUid: widget.message.chatUid, msgUid: widget.message.uid);
      if (downloaded == null) {
        setState(() {
          needDownload = true;
        });
      }
    }

    if (downloaded != null) {
      if (widget.message.pass != null || widget.message.baseKey != null) {
        late dynamic decrypted;
        try {
          // Use the same SHA256-based key derivation as encryption
          String? inputForHashing;

          if (widget.message.baseKey != null) {
            if (widget.message.pass != null) {
              // Combine baseKey and pass
              inputForHashing = widget.message.baseKey! + widget.message.pass!;
            } else {
              // Use baseKey only
              inputForHashing = widget.message.baseKey!;
            }
          } else if (widget.message.pass != null) {
            // Use pass only
            inputForHashing = widget.message.pass!;
          }

          if (inputForHashing != null) {
            // Hash the input to ensure exactly 32 bytes (same as encryption)
            final hash = sha256.convert(utf8.encode(inputForHashing));
            final hashedKey = base64Encode(hash.bytes);

            decrypted = await decodePayload(
              downloaded,
              widget.message.iv,
              hashedKey,
              true,
            );
          }
        } catch (e) {
          decrypted = null;
        }

        if (decrypted != null) {
          setState(() {
            file = decrypted;
          });
        }
      } else {
        setState(() {
          file = downloaded;
        });
      }
    }
  }

  downloadFile(context) {
    setState(() {
      downloadInProgress = true;
    });
    if (widget.message.uid == null) {
      return;
    }
    messageService
        .downloadFile(widget.message.chatUid, widget.message.uid!,
            widget.message.fileKey!)
        .then((resp) {
      file = resp;
      setState(() {
        downloadInProgress = false;
        needDownload = false;
      });
    }).catchError((error) {
      setState(() {
        downloadInProgress = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not download file',
              style: TextStyle(color: Colors.white)),
          backgroundColor: errorColor,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
        ));
      }
    });
  }

  saveFile(context) async {
    await FilePicker.platform
        .saveFile(
      dialogTitle: 'Please select where to save the file:',
      fileName: file['name'],
      bytes: Uint8List.fromList(file['bytes'].cast<int>().toList()),
    )
        .catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save file',
              style: TextStyle(color: Colors.white)),
          backgroundColor: errorColor,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
        ));
      }
      return 'Could not save the file';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.55,
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding * 0.75,
        vertical: defaultPadding / 2.5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: primaryColor
            .withAlpha((widget.message.isSender ? 255 : (255 * 0.1).round())),
      ),
      child: Row(
        children: [
          if (needDownload)
            if (downloadInProgress)
              FadeIcon(
                  icon: Container(
                margin: const EdgeInsets.all(7.5),
                child: Icon(
                  Icons.download,
                  color: widget.message.isSender ? Colors.white : primaryColor,
                ),
              ))
            else
              IconButton(
                onPressed: () {
                  downloadFile(context);
                },
                icon: Icon(
                  Icons.download,
                  color: widget.message.isSender ? Colors.white : primaryColor,
                ),
              )
          else
            IconButton(
              onPressed: () {
                if (file != null && file['name'] != null) {
                  saveFile(context);
                }
              },
              icon: Icon(
                Icons.attach_file,
                color: widget.message.isSender ? Colors.white : primaryColor,
              ),
            ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
              child: InkWell(
                onTap: () {
                  if (file != null && file['name'] != null) {
                    saveFile(context);
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    needDownload
                        ? downloadInProgress
                            ? 'Downloading...'
                            : 'Download'
                        : file == null
                            ? 'Encrypted File'
                            : file['name'] ?? 'Encrypted File',
                    style: TextStyle(
                        color: widget.message.isSender
                            ? Colors.white
                            : primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
