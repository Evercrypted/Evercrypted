import 'dart:convert';
import 'dart:typed_data';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';
import '../../../screens/messages/components/image_preview.dart';

class ImageMessage extends StatefulWidget {
  final ChatMessage message;
  final Function(EncryptionStatus?) encryptionStatusCallback;

  const ImageMessage(
      {super.key,
      required this.message,
      required this.encryptionStatusCallback});

  @override
  State<ImageMessage> createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  Uint8List? imageData;
  bool needDownload = false;
  bool downloadInProgress = false;
  EncryptionStatus? decryptionStatus;

  MessageService messageService = MessageService();

  @override
  void initState() {
    super.initState();
    setImage();
  }

  @override
  didUpdateWidget(ImageMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    setImage(oldWidget: oldWidget);
  }

  setImage({ImageMessage? oldWidget}) async {
    if (widget.message.pass == oldWidget?.message.pass) {
      return;
    }
    // print(widget.message.toJson());

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
              widget.message.iv != null) {
        if (widget.message.pass != null) {
          late dynamic decrypted;
          try {
            decrypted = await decodePayload(
              downloaded,
              widget.message.iv,
              widget.message.pass,
              true,
            );
          } catch (e) {
            decrypted = null;
          }

          if (decrypted != null) {
            List<int> intList = decrypted['bytes'].cast<int>().toList();
            Uint8List data = Uint8List.fromList(intList);
            if (mounted) {
              setState(() {
                imageData = data;
                decryptionStatus = EncryptionStatus.decrypted;
              });
            }
            widget.encryptionStatusCallback(decryptionStatus);
          } else {
            if (mounted) {
              setState(() {
                decryptionStatus = EncryptionStatus.failed;
              });
            }
            widget.encryptionStatusCallback(decryptionStatus);
          }
        } else {
          if (mounted) {
            setState(() {
              decryptionStatus = EncryptionStatus.encrypted;
            });
          }
          widget.encryptionStatusCallback(decryptionStatus);
        }
      } else if (decryptionStatus == null) {
        setState(() {
          decryptionStatus = EncryptionStatus.notEncrypted;
          imageData = downloaded = base64.decode(downloaded);
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
                              position: Position(
                                top: 7,
                                left: 7,
                              ),
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
                  (decryptionStatus == EncryptionStatus.decrypted ||
                      decryptionStatus == EncryptionStatus.notEncrypted))
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
                              color: primaryColor,
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
