import 'dart:convert';
import 'dart:typed_data';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';
import '../../../screens/messages/components/image_preview.dart';

enum ImageStatus {
  unencrypted,
  encrypted,
  decryptionFailed,
  decrypted,
}

class ImageMessage extends StatefulWidget {
  final ChatMessage message;

  const ImageMessage({super.key, required this.message});

  @override
  State<ImageMessage> createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  Uint8List? imageData;
  bool needDownload = false;
  bool downloadInProgress = false;
  late ImageStatus decryptionStatus;

  MessageService messageService = MessageService();

  @override
  void initState() {
    super.initState();
    setImage();
  }

  @override
  didUpdateWidget(ImageMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    setImage();
  }

  setImage() async {
    print(widget.message.toJson());
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
      if (widget.message.encryptionStatus == EncryptionStatus.encrypted ||
          widget.message.encryptionStatus == EncryptionStatus.decrypted &&
              widget.message.iv != null &&
              widget.message.mac != null) {
        if (widget.message.pass != null) {
          late dynamic decrypted;
          try {
            decrypted = await decodePayload(
              downloaded,
              widget.message.iv,
              widget.message.mac,
              widget.message.pass,
              true,
            );
          } catch (e) {
            decrypted = null;
          }

          if (decrypted != null) {
            List<int> intList = decrypted['bytes'].cast<int>().toList();
            Uint8List data = Uint8List.fromList(intList);
            setState(() {
              imageData = data;
              decryptionStatus = ImageStatus.decrypted;
            });
          } else {
            setState(() {
              decryptionStatus = ImageStatus.decryptionFailed;
            });
          }
        } else {
          setState(() {
            decryptionStatus = ImageStatus.encrypted;
          });
        }
      } else {
        setState(() {
          decryptionStatus = ImageStatus.unencrypted;
          imageData = downloaded = base64.decode(downloaded);
        });
      }
    }
    print(decryptionStatus.name);
  }

  downloadFile(context) {
    setState(() {
      downloadInProgress = true;
    });
    if (widget.message.uid == null) {
      return;
    }
    messageService
        .downloadFile(widget.message.chatUid, widget.message.uid!)
        .then((resp) {
      imageData = base64.decode(resp);
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
          content: Text('Could not download image',
              style: TextStyle(color: Colors.white)),
          backgroundColor: errorColor,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.55,
        maxHeight: MediaQuery.of(context).size.width * 0.55,
      ),
      child: needDownload
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: primaryColor,
                ),
              ),
              child: GestureDetector(
                onTap: () => downloadFile(context),
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding * 0.75,
                  ),
                  child: Row(
                    children: [
                      downloadInProgress
                          ? FadeIcon(
                              icon: Icon(
                              Icons.download,
                              color: widget.message.isSender
                                  ? Colors.white
                                  : primaryColor,
                            ))
                          : Icon(
                              Icons.download,
                              color: widget.message.isSender
                                  ? Colors.white
                                  : primaryColor,
                            ),
                      Expanded(
                        child: Center(
                          child: Text(
                            downloadInProgress
                                ? 'Downloading...'
                                : 'Download Image',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : (imageData != null &&
                  (decryptionStatus == ImageStatus.decrypted ||
                      decryptionStatus == ImageStatus.unencrypted))
              ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ImagePreview(imageData: imageData!),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.memory(
                      imageData!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding * 0.75,
                    vertical: defaultPadding / 2.5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: primaryColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: primaryColor,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Encrypted Image',
                            style: TextStyle(
                              color: widget.message.isSender
                                  ? Colors.white
                                  : primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
