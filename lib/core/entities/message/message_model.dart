import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:objectbox/objectbox.dart';

class MessageTypes {
  MessageTypes._();
  static const text = 'text';
  static const audio = 'audio';
  static const file = 'file';
  static const image = 'image';
  static const video = 'video';
  static const system = 'system';
}

@Entity()
class Message {
  @Id()
  int id = 0;

  @Index()
  String? uid;

  String authorId;

  String? text;
  String? iv;
  String? mac;
  String messageType;
  bool isEncrypted;

  String? error;

  @Index()
  int createdAtMSE;

  @Index()
  String chatUid;

  @Unique()
  String? uniqueId;

  @Index()
  int? queueId;

  bool successfullySent;

  bool couldNotSend;

  String? pinnedByUid;

  String? pinLabel;

  String? localPinLabel;

  String? playbackDurationMicroSeconds;
  String? durationIV;
  String? durationMAC;

  List<double>? waveData;
  String? waveDataIV;
  String? waveDataMAC;

  String? filepath;
  bool? withBaseKey;

  @Index()
  final chat = ToOne<Chat>();

  Message(
      {this.uid,
      required this.authorId,
      this.text,
      this.messageType = MessageTypes.text,
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
      this.durationIV,
      this.durationMAC,
      this.waveData,
      this.waveDataIV,
      this.waveDataMAC,
      this.filepath,
      this.error,
      this.withBaseKey});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        uid: json['uid'] as String,
        authorId: json['authorId'] as String,
        text: json['text'] as String?,
        createdAtMSE: DateTime.parse(json['createdAt']).millisecondsSinceEpoch,
        chatUid: json['chatUid'] as String,
        uniqueId: json['chatUid'] + json['uid'],
        successfullySent: true,
        iv: json['iv'] as String?,
        mac: json['mac'] as String?,
        messageType: json['messageType'] as String,
        pinnedByUid: json['pinnedByUid'] as String?,
        pinLabel: json['pinLabel'] as String?,
        playbackDurationMicroSeconds:
            json['playbackDurationMicroSeconds'] as String?,
        durationIV: json['durationIV'] as String?,
        durationMAC: json['durationMAC'] as String?,
        waveData: (json['waveData'] as List<dynamic>)
            .map((e) => e as double)
            .toList(),
        waveDataIV: json['waveDataIV'] as String?,
        waveDataMAC: json['waveDataMAC'] as String?,
        withBaseKey: json['withBaseKey'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'authorId': authorId,
        'text': text,
        'createdAt': createdAtMSE,
        'chatUid': chatUid,
        'isEncrypted': isEncrypted,
        'iv': iv,
        'mac': mac,
        'messageType': messageType,
        'pinnedByUid': pinnedByUid,
        'pinLabel': pinLabel,
        'playbackDurationMicroSeconds': playbackDurationMicroSeconds,
        'durationIV': durationIV,
        'durationMAC': durationMAC,
        'waveData': waveData,
        'waveDataIV': waveDataIV,
        'waveDataMAC': waveDataMAC,
        'withBaseKey': withBaseKey,
      };
}
