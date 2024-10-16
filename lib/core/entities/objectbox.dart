import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ObjectBox {
  /// The Store of this app.
  late final Store store;
  late final Box<Chat> chats;
  late final Box<Message> messages;
  late final Box<Profile> profiles;
  late final Box<Contact> contacts;
  late final Box<ContactRequest> contactRequests;
  late final Box<ActionQueue> actionQueues;

  ObjectBox._create(this.store) {
    // Add any additional setup code, e.g. build queries.
    chats = store.box<Chat>();
    messages = store.box<Message>();
    profiles = store.box<Profile>();
    contacts = store.box<Contact>();
    contactRequests = store.box<ContactRequest>();
    actionQueues = store.box<ActionQueue>();
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store = await openStore(directory: p.join(docsDir.path, "obx"));
    return ObjectBox._create(store);
  }
}
