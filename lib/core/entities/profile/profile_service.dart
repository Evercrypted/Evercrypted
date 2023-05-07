import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:evercrypted/core/http.dart';

import 'profile_model.dart';

class ProfileService {
  final _profileCollection = FirebaseFirestore.instance.collection('profiles');

  Future<Response> checkProfileExists(String token) {
    return dio.post('/users/checkUserExists', data: {});
  }

  Future<void> updateUserProfile(Profile profile) {
    return _profileCollection.doc(profile.uid).update(profile.toJson()).then(
      (_) {
        print('Profile updated');
      },
    );
  }

  Future<void> deleteUserProfile(Profile profile) {
    return _profileCollection.doc(profile.uid).delete().then(
      (_) {
        print('Profile deleted');
      },
    );
  }
}
