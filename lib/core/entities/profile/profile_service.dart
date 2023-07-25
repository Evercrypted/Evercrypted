import 'package:evercrypted/core/http.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../cryptography/payload.dart';
import 'profile_model.dart';

class ProfileService {
  Future<bool?> checkIfOtpIsNeeded(WidgetRef ref, String token) async {
    final String key = await getHttpEncKey(ref);
    return dio.post('/users/isOtpNeeded', data: {}).then((resp) async {
      final payload = await decodePayload(
        resp.data,
        key,
      );
      return payload['needOtp'];
    });
  }

  void syncProfile(Profile profile) async {
    final isar = Isar.getInstance();
    return await isar?.writeTxn(() async {
      return isar.profiles.clear().then((value) async {
        await isar.profiles.put(profile);
      });
    });
  }
}
