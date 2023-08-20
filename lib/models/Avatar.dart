import 'package:isar/isar.dart';

@embedded
class Avatar {
  final String? color;
  final String? icon;
  final String? pic;

  Avatar({this.icon, this.color, this.pic});

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      pic: json['pic'] as String?);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'color': color,
        'icon': icon,
        'pic': pic,
      };
}
