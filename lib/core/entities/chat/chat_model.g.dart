// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatCollection on Isar {
  IsarCollection<Chat> get chats => this.collection();
}

const ChatSchema = CollectionSchema(
  name: r'Chat',
  id: -4292359458225261721,
  properties: {
    r'avatar': PropertySchema(
      id: 0,
      name: r'avatar',
      type: IsarType.object,
      target: r'Avatar',
    ),
    r'lastMessageTime': PropertySchema(
      id: 1,
      name: r'lastMessageTime',
      type: IsarType.dateTime,
    ),
    r'messageLongevitySeconds': PropertySchema(
      id: 2,
      name: r'messageLongevitySeconds',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'participants': PropertySchema(
      id: 4,
      name: r'participants',
      type: IsarType.stringList,
    ),
    r'uid': PropertySchema(
      id: 5,
      name: r'uid',
      type: IsarType.string,
    )
  },
  estimateSize: _chatEstimateSize,
  serialize: _chatSerialize,
  deserialize: _chatDeserialize,
  deserializeProp: _chatDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'Avatar': AvatarSchema},
  getId: _chatGetId,
  getLinks: _chatGetLinks,
  attach: _chatAttach,
  version: '3.1.0+1',
);

int _chatEstimateSize(
  Chat object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatar;
    if (value != null) {
      bytesCount +=
          3 + AvatarSchema.estimateSize(value, allOffsets[Avatar]!, allOffsets);
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final list = object.participants;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final value = object.uid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _chatSerialize(
  Chat object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<Avatar>(
    offsets[0],
    allOffsets,
    AvatarSchema.serialize,
    object.avatar,
  );
  writer.writeDateTime(offsets[1], object.lastMessageTime);
  writer.writeLong(offsets[2], object.messageLongevitySeconds);
  writer.writeString(offsets[3], object.name);
  writer.writeStringList(offsets[4], object.participants);
  writer.writeString(offsets[5], object.uid);
}

Chat _chatDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Chat(
    avatar: reader.readObjectOrNull<Avatar>(
      offsets[0],
      AvatarSchema.deserialize,
      allOffsets,
    ),
    lastMessageTime: reader.readDateTime(offsets[1]),
    messageLongevitySeconds: reader.readLongOrNull(offsets[2]),
    name: reader.readString(offsets[3]),
    participants: reader.readStringList(offsets[4]),
    uid: reader.readStringOrNull(offsets[5]),
  );
  object.id = id;
  return object;
}

P _chatDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<Avatar>(
        offset,
        AvatarSchema.deserialize,
        allOffsets,
      )) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringList(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _chatGetId(Chat object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _chatGetLinks(Chat object) {
  return [];
}

void _chatAttach(IsarCollection<dynamic> col, Id id, Chat object) {
  object.id = id;
}

extension ChatByIndex on IsarCollection<Chat> {
  Future<Chat?> getByUid(String? uid) {
    return getByIndex(r'uid', [uid]);
  }

  Chat? getByUidSync(String? uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String? uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String? uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<Chat?>> getAllByUid(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<Chat?> getAllByUidSync(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(Chat object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(Chat object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<Chat> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(List<Chat> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension ChatQueryWhereSort on QueryBuilder<Chat, Chat, QWhere> {
  QueryBuilder<Chat, Chat, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatQueryWhere on QueryBuilder<Chat, Chat, QWhereClause> {
  QueryBuilder<Chat, Chat, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [null],
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> uidEqualTo(String? uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [uid],
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> uidNotEqualTo(String? uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ChatQueryFilter on QueryBuilder<Chat, Chat, QFilterCondition> {
  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatar',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatar',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> lastMessageTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      messageLongevitySecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'messageLongevitySeconds',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      messageLongevitySecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'messageLongevitySeconds',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      messageLongevitySecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageLongevitySeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      messageLongevitySecondsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageLongevitySeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      messageLongevitySecondsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageLongevitySeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      messageLongevitySecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageLongevitySeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'participants',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'participants',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'participants',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      participantsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'participants',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'participants',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'participants',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'participants',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'participants',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'participants',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'participants',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'participants',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      participantsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'participants',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> participantsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }
}

extension ChatQueryObject on QueryBuilder<Chat, Chat, QFilterCondition> {
  QueryBuilder<Chat, Chat, QAfterFilterCondition> avatar(
      FilterQuery<Avatar> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'avatar');
    });
  }
}

extension ChatQueryLinks on QueryBuilder<Chat, Chat, QFilterCondition> {}

extension ChatQuerySortBy on QueryBuilder<Chat, Chat, QSortBy> {
  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByMessageLongevitySeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageLongevitySeconds', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByMessageLongevitySecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageLongevitySeconds', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension ChatQuerySortThenBy on QueryBuilder<Chat, Chat, QSortThenBy> {
  QueryBuilder<Chat, Chat, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByLastMessageTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageTime', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByMessageLongevitySeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageLongevitySeconds', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByMessageLongevitySecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageLongevitySeconds', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension ChatQueryWhereDistinct on QueryBuilder<Chat, Chat, QDistinct> {
  QueryBuilder<Chat, Chat, QDistinct> distinctByLastMessageTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageTime');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByMessageLongevitySeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageLongevitySeconds');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByParticipants() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'participants');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension ChatQueryProperty on QueryBuilder<Chat, Chat, QQueryProperty> {
  QueryBuilder<Chat, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Chat, Avatar?, QQueryOperations> avatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatar');
    });
  }

  QueryBuilder<Chat, DateTime, QQueryOperations> lastMessageTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageTime');
    });
  }

  QueryBuilder<Chat, int?, QQueryOperations> messageLongevitySecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageLongevitySeconds');
    });
  }

  QueryBuilder<Chat, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Chat, List<String>?, QQueryOperations> participantsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participants');
    });
  }

  QueryBuilder<Chat, String?, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}
