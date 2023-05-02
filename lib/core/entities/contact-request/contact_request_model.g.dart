// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_request_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetContactRequestCollection on Isar {
  IsarCollection<ContactRequest> get contactRequests => this.collection();
}

const ContactRequestSchema = CollectionSchema(
  name: r'ContactRequest',
  id: -3325729714646560811,
  properties: {
    r'authorEmail': PropertySchema(
      id: 0,
      name: r'authorEmail',
      type: IsarType.string,
    ),
    r'authorId': PropertySchema(
      id: 1,
      name: r'authorId',
      type: IsarType.string,
    ),
    r'message': PropertySchema(
      id: 2,
      name: r'message',
      type: IsarType.string,
    ),
    r'queueId': PropertySchema(
      id: 3,
      name: r'queueId',
      type: IsarType.long,
    ),
    r'recipientEmail': PropertySchema(
      id: 4,
      name: r'recipientEmail',
      type: IsarType.string,
    ),
    r'timeSent': PropertySchema(
      id: 5,
      name: r'timeSent',
      type: IsarType.dateTime,
    ),
    r'uid': PropertySchema(
      id: 6,
      name: r'uid',
      type: IsarType.string,
    )
  },
  estimateSize: _contactRequestEstimateSize,
  serialize: _contactRequestSerialize,
  deserialize: _contactRequestDeserialize,
  deserializeProp: _contactRequestDeserializeProp,
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
  embeddedSchemas: {},
  getId: _contactRequestGetId,
  getLinks: _contactRequestGetLinks,
  attach: _contactRequestAttach,
  version: '3.0.5',
);

int _contactRequestEstimateSize(
  ContactRequest object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.authorEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.authorId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.message;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recipientEmail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
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

void _contactRequestSerialize(
  ContactRequest object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.authorEmail);
  writer.writeString(offsets[1], object.authorId);
  writer.writeString(offsets[2], object.message);
  writer.writeLong(offsets[3], object.queueId);
  writer.writeString(offsets[4], object.recipientEmail);
  writer.writeDateTime(offsets[5], object.timeSent);
  writer.writeString(offsets[6], object.uid);
}

ContactRequest _contactRequestDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ContactRequest(
    authorEmail: reader.readStringOrNull(offsets[0]),
    authorId: reader.readStringOrNull(offsets[1]),
    message: reader.readStringOrNull(offsets[2]),
    queueId: reader.readLongOrNull(offsets[3]),
    recipientEmail: reader.readStringOrNull(offsets[4]),
    timeSent: reader.readDateTimeOrNull(offsets[5]),
    uid: reader.readStringOrNull(offsets[6]),
  );
  object.id = id;
  return object;
}

P _contactRequestDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _contactRequestGetId(ContactRequest object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _contactRequestGetLinks(ContactRequest object) {
  return [];
}

void _contactRequestAttach(
    IsarCollection<dynamic> col, Id id, ContactRequest object) {
  object.id = id;
}

extension ContactRequestByIndex on IsarCollection<ContactRequest> {
  Future<ContactRequest?> getByUid(String? uid) {
    return getByIndex(r'uid', [uid]);
  }

  ContactRequest? getByUidSync(String? uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String? uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String? uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<ContactRequest?>> getAllByUid(List<String?> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<ContactRequest?> getAllByUidSync(List<String?> uidValues) {
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

  Future<Id> putByUid(ContactRequest object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(ContactRequest object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<ContactRequest> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(List<ContactRequest> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension ContactRequestQueryWhereSort
    on QueryBuilder<ContactRequest, ContactRequest, QWhere> {
  QueryBuilder<ContactRequest, ContactRequest, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ContactRequestQueryWhere
    on QueryBuilder<ContactRequest, ContactRequest, QWhereClause> {
  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> idBetween(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [null],
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause>
      uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> uidEqualTo(
      String? uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [uid],
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterWhereClause> uidNotEqualTo(
      String? uid) {
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

extension ContactRequestQueryFilter
    on QueryBuilder<ContactRequest, ContactRequest, QFilterCondition> {
  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'authorEmail',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'authorEmail',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'authorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'authorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'authorEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'authorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'authorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'authorEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'authorEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authorEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'authorEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'authorId',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'authorId',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'authorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'authorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'authorId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'authorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'authorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'authorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'authorId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authorId',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      authorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'authorId',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'message',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'message',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      queueIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'queueId',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      queueIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'queueId',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      queueIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queueId',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      queueIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'queueId',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      queueIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'queueId',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      queueIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'queueId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recipientEmail',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recipientEmail',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipientEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recipientEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recipientEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recipientEmail',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recipientEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recipientEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recipientEmail',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recipientEmail',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipientEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      recipientEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recipientEmail',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      timeSentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timeSent',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      timeSentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timeSent',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      timeSentEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeSent',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      timeSentGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeSent',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      timeSentLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeSent',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      timeSentBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeSent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uid',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidEqualTo(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidGreaterThan(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidLessThan(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidBetween(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidStartsWith(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidEndsWith(
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

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterFilterCondition>
      uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }
}

extension ContactRequestQueryObject
    on QueryBuilder<ContactRequest, ContactRequest, QFilterCondition> {}

extension ContactRequestQueryLinks
    on QueryBuilder<ContactRequest, ContactRequest, QFilterCondition> {}

extension ContactRequestQuerySortBy
    on QueryBuilder<ContactRequest, ContactRequest, QSortBy> {
  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByAuthorEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorEmail', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByAuthorEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorEmail', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> sortByAuthorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorId', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByAuthorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorId', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> sortByQueueId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueId', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByQueueIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueId', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByRecipientEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientEmail', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByRecipientEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientEmail', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> sortByTimeSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeSent', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      sortByTimeSentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeSent', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension ContactRequestQuerySortThenBy
    on QueryBuilder<ContactRequest, ContactRequest, QSortThenBy> {
  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByAuthorEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorEmail', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByAuthorEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorEmail', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenByAuthorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorId', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByAuthorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorId', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenByQueueId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueId', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByQueueIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queueId', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByRecipientEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientEmail', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByRecipientEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientEmail', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenByTimeSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeSent', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy>
      thenByTimeSentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeSent', Sort.desc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension ContactRequestQueryWhereDistinct
    on QueryBuilder<ContactRequest, ContactRequest, QDistinct> {
  QueryBuilder<ContactRequest, ContactRequest, QDistinct> distinctByAuthorEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authorEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QDistinct> distinctByAuthorId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authorId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QDistinct> distinctByMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QDistinct> distinctByQueueId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queueId');
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QDistinct>
      distinctByRecipientEmail({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recipientEmail',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QDistinct> distinctByTimeSent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeSent');
    });
  }

  QueryBuilder<ContactRequest, ContactRequest, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension ContactRequestQueryProperty
    on QueryBuilder<ContactRequest, ContactRequest, QQueryProperty> {
  QueryBuilder<ContactRequest, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ContactRequest, String?, QQueryOperations>
      authorEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authorEmail');
    });
  }

  QueryBuilder<ContactRequest, String?, QQueryOperations> authorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authorId');
    });
  }

  QueryBuilder<ContactRequest, String?, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<ContactRequest, int?, QQueryOperations> queueIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queueId');
    });
  }

  QueryBuilder<ContactRequest, String?, QQueryOperations>
      recipientEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recipientEmail');
    });
  }

  QueryBuilder<ContactRequest, DateTime?, QQueryOperations> timeSentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeSent');
    });
  }

  QueryBuilder<ContactRequest, String?, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}
