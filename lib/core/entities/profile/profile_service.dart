import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evercrypted/core/http.dart';

import 'profile_model.dart';

class ProfileService {
  final _profileCollection = FirebaseFirestore.instance.collection('profiles');

  checkProfileExists(String token) {
    dio.post('/users/checkUserExists', data: {});
  }

//firebase

  // Future<void> setProfile(Profile profile) {
  //   return _profileCollection
  //       .doc(profile.fbUid)
  //       .set(profile.toJson(), SetOptions(merge: true));
  // }

  Future<void> updateUserProfile(Profile profile) {
    return _profileCollection.doc(profile.fbUid).update(profile.toJson()).then(
      (_) {
        print('Profile updated');
      },
    );
  }

  Future<void> deleteUserProfile(Profile profile) {
    return _profileCollection.doc(profile.fbUid).delete().then(
      (_) {
        print('Profile deleted');
      },
    );
  }

  Future<Profile?> getUserProfile(String userId) async {
    var userProfile =
        _profileCollection.where('userId', isEqualTo: userId).limit(1);
    return userProfile.get().then(
      (resp) {
        if (resp.docs.isNotEmpty) {
          try {
            final doc = resp.docs.first;
            return Profile.fromJson(doc.id, doc.data());
          } catch (e) {
            return null;
          }
        } else {
          return null;
        }
      },
    );
  }
}
