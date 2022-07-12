import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_model.dart';

class ProfileService {
  var _profileCollection = FirebaseFirestore.instance.collection('profiles');

  Future<void> createUserProfile(Profile profile) {
    return _profileCollection.add(profile.toJson()).then(
      (resp) {
        resp.get().then((doc) {
          print('saved');
          print(doc.data());
        });
      },
    );
  }

  Future getUserProfile(String userId) async {
    var _userProfile =
        _profileCollection.where('userId', isEqualTo: userId).limit(1);
    return _userProfile.get().then(
      (resp) {
        try {
          return resp.docs
              .map((e) => Profile.fromJson(e.id, e.data()))
              .toList()
              .first;
        } catch (e) {
          return null;
        }
      },
    );
  }
}
