class ChatEventTypes {
  ChatEventTypes._();
  static const createChat = 'createChat';
  static const createGroupChat = 'createGroupChat';
  static const deleteChat = 'deleteChat';
  static const chatCreated = 'chatCreated';
  static const chatDeleted = 'chatDeleted';
  static const updateChatLastSeen = 'updateChatLastSeen';
  static const updateChat = 'updateChat';
  static const addParticipants = 'addParticipants';
  static const participantsAdded = 'participantsAdded';
  static const addedToChat = 'addedToChat';
  static const removeParticipant = 'removeParticipant';
  static const participantRemoved = 'participantRemoved';
  static const removedFromChat = 'removedFromChat';
  static const leaveChat = 'leaveChat';
  static const leftChat = 'leftChat';
  static const updatePubKey = 'updatePubKey';
  static const chatUpdated = 'chatUpdated';
  static const keyExchange = 'keyExchange';
  static const generateInviteLink = 'generateInviteLink';
  static const revokeInviteLink = 'revokeInviteLink';
  static const joinViaInvite = 'joinViaInvite';
  static const joinedViaInvite = 'joinedViaInvite';
}
