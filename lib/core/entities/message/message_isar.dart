import 'package:isar/isar.dart';

part 'message_isar.g.dart';

class MessageTypes {
  MessageTypes._();
  static const text = 'text';
  static const audio = 'audio';
  static const file = 'file';
  static const image = 'image';
  static const video = 'video';
  static const system = 'system';
}

@collection
class Message {
  Id id = Isar.autoIncrement;

  @Index()
  String? uid;

  String authorId;

  String? text;
  String? iv;
  String? mac;
  String messageType;
  bool isEncrypted;

  List<String>? fileIds;

  @Index()
  int createdAtMSE;

  @Index()
  String chatUid;

  @Index(unique: true)
  String? uniqueId;

  @Index()
  int? queueId;

  bool successfullySent;

  bool couldNotSend;

  String? pinnedByUid;

  String? pinLabel;

  String? localPinLabel;

  int? playbackDurationMicroSeconds;

  List<double>? waveData;

  Message(
      {this.uid,
      required this.authorId,
      this.text,
      this.messageType = MessageTypes.text,
      this.fileIds,
      required this.createdAtMSE,
      this.iv,
      this.mac,
      this.isEncrypted = false,
      required this.chatUid,
      this.uniqueId,
      this.successfullySent = true,
      this.couldNotSend = false,
      this.queueId,
      this.pinnedByUid,
      this.pinLabel,
      this.localPinLabel,
      this.playbackDurationMicroSeconds,
      this.waveData});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        uid: json['uid'] as String,
        authorId: json['authorId'] as String,
        text: json['text'] as String?,
        fileIds:
            (json['fileIds'] as List<dynamic>).map((e) => e as String).toList(),
        createdAtMSE: DateTime.parse(json['createdAt']).millisecondsSinceEpoch,
        chatUid: json['chatUid'] as String,
        uniqueId: json['chatUid'] + json['uid'],
        successfullySent: true,
        iv: json['iv'] as String?,
        mac: json['mac'] as String?,
        messageType: json['messageType'] as String,
        pinnedByUid: json['pinnedByUid'] as String?,
        pinLabel: json['pinLabel'] as String?,
        playbackDurationMicroSeconds: json['playbackDuration'] as int?,
        waveData: (json['waveData'] as List<dynamic>)
            .map((e) => e as double)
            .toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'authorId': authorId,
        'text': text,
        'fileIds': fileIds,
        'createdAt': createdAtMSE,
        'chatUid': chatUid,
        'isEncrypted': isEncrypted,
        'iv': iv,
        'mac': mac,
        'messageType': messageType,
        'pinnedByUid': pinnedByUid,
        'pinLabel': pinLabel,
        'playbackDuration': playbackDurationMicroSeconds,
        'waveData': waveData,
      };
}
