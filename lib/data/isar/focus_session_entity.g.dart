// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFocusSessionEntityCollection on Isar {
  IsarCollection<FocusSessionEntity> get focusSessionEntitys =>
      this.collection();
}

const FocusSessionEntitySchema = CollectionSchema(
  name: r'FocusSessionEntity',
  id: -9139471333371116198,
  properties: {
    r'actualMinutes': PropertySchema(
      id: 0,
      name: r'actualMinutes',
      type: IsarType.long,
    ),
    r'alarmEnabled': PropertySchema(
      id: 1,
      name: r'alarmEnabled',
      type: IsarType.bool,
    ),
    r'endedAt': PropertySchema(
      id: 2,
      name: r'endedAt',
      type: IsarType.dateTime,
    ),
    r'estimateMinutes': PropertySchema(
      id: 3,
      name: r'estimateMinutes',
      type: IsarType.long,
    ),
    r'reflectionNote': PropertySchema(
      id: 4,
      name: r'reflectionNote',
      type: IsarType.string,
    ),
    r'startedAt': PropertySchema(
      id: 5,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'taskId': PropertySchema(
      id: 6,
      name: r'taskId',
      type: IsarType.long,
    ),
    r'transferredToTaskId': PropertySchema(
      id: 7,
      name: r'transferredToTaskId',
      type: IsarType.long,
    )
  },
  estimateSize: _focusSessionEntityEstimateSize,
  serialize: _focusSessionEntitySerialize,
  deserialize: _focusSessionEntityDeserialize,
  deserializeProp: _focusSessionEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _focusSessionEntityGetId,
  getLinks: _focusSessionEntityGetLinks,
  attach: _focusSessionEntityAttach,
  version: '3.1.0+1',
);

int _focusSessionEntityEstimateSize(
  FocusSessionEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.reflectionNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _focusSessionEntitySerialize(
  FocusSessionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.actualMinutes);
  writer.writeBool(offsets[1], object.alarmEnabled);
  writer.writeDateTime(offsets[2], object.endedAt);
  writer.writeLong(offsets[3], object.estimateMinutes);
  writer.writeString(offsets[4], object.reflectionNote);
  writer.writeDateTime(offsets[5], object.startedAt);
  writer.writeLong(offsets[6], object.taskId);
  writer.writeLong(offsets[7], object.transferredToTaskId);
}

FocusSessionEntity _focusSessionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FocusSessionEntity();
  object.actualMinutes = reader.readLong(offsets[0]);
  object.alarmEnabled = reader.readBool(offsets[1]);
  object.endedAt = reader.readDateTimeOrNull(offsets[2]);
  object.estimateMinutes = reader.readLongOrNull(offsets[3]);
  object.id = id;
  object.reflectionNote = reader.readStringOrNull(offsets[4]);
  object.startedAt = reader.readDateTime(offsets[5]);
  object.taskId = reader.readLong(offsets[6]);
  object.transferredToTaskId = reader.readLongOrNull(offsets[7]);
  return object;
}

P _focusSessionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _focusSessionEntityGetId(FocusSessionEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _focusSessionEntityGetLinks(
    FocusSessionEntity object) {
  return [];
}

void _focusSessionEntityAttach(
    IsarCollection<dynamic> col, Id id, FocusSessionEntity object) {
  object.id = id;
}

extension FocusSessionEntityQueryWhereSort
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QWhere> {
  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FocusSessionEntityQueryWhere
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QWhereClause> {
  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterWhereClause>
      idBetween(
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
}

extension FocusSessionEntityQueryFilter
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QFilterCondition> {
  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      actualMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      actualMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      actualMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      actualMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      alarmEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alarmEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      endedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      endedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      endedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      endedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      endedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      endedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      estimateMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'estimateMinutes',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      estimateMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'estimateMinutes',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      estimateMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estimateMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      estimateMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estimateMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      estimateMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estimateMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      estimateMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estimateMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
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

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
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

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reflectionNote',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reflectionNote',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reflectionNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reflectionNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reflectionNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reflectionNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reflectionNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reflectionNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reflectionNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reflectionNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reflectionNote',
        value: '',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      reflectionNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reflectionNote',
        value: '',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      startedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      taskIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      taskIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      taskIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      taskIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      transferredToTaskIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transferredToTaskId',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      transferredToTaskIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transferredToTaskId',
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      transferredToTaskIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transferredToTaskId',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      transferredToTaskIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transferredToTaskId',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      transferredToTaskIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transferredToTaskId',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterFilterCondition>
      transferredToTaskIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transferredToTaskId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FocusSessionEntityQueryObject
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QFilterCondition> {}

extension FocusSessionEntityQueryLinks
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QFilterCondition> {}

extension FocusSessionEntityQuerySortBy
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QSortBy> {
  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByActualMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualMinutes', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByActualMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualMinutes', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByAlarmEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmEnabled', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByAlarmEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmEnabled', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByEstimateMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimateMinutes', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByEstimateMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimateMinutes', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByReflectionNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reflectionNote', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByReflectionNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reflectionNote', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByTransferredToTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferredToTaskId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      sortByTransferredToTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferredToTaskId', Sort.desc);
    });
  }
}

extension FocusSessionEntityQuerySortThenBy
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QSortThenBy> {
  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByActualMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualMinutes', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByActualMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualMinutes', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByAlarmEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmEnabled', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByAlarmEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alarmEnabled', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByEstimateMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimateMinutes', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByEstimateMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimateMinutes', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByReflectionNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reflectionNote', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByReflectionNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reflectionNote', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByTransferredToTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferredToTaskId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QAfterSortBy>
      thenByTransferredToTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferredToTaskId', Sort.desc);
    });
  }
}

extension FocusSessionEntityQueryWhereDistinct
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct> {
  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByActualMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualMinutes');
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByAlarmEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alarmEnabled');
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endedAt');
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByEstimateMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimateMinutes');
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByReflectionNote({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reflectionNote',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskId');
    });
  }

  QueryBuilder<FocusSessionEntity, FocusSessionEntity, QDistinct>
      distinctByTransferredToTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transferredToTaskId');
    });
  }
}

extension FocusSessionEntityQueryProperty
    on QueryBuilder<FocusSessionEntity, FocusSessionEntity, QQueryProperty> {
  QueryBuilder<FocusSessionEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FocusSessionEntity, int, QQueryOperations>
      actualMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualMinutes');
    });
  }

  QueryBuilder<FocusSessionEntity, bool, QQueryOperations>
      alarmEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alarmEnabled');
    });
  }

  QueryBuilder<FocusSessionEntity, DateTime?, QQueryOperations>
      endedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endedAt');
    });
  }

  QueryBuilder<FocusSessionEntity, int?, QQueryOperations>
      estimateMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimateMinutes');
    });
  }

  QueryBuilder<FocusSessionEntity, String?, QQueryOperations>
      reflectionNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reflectionNote');
    });
  }

  QueryBuilder<FocusSessionEntity, DateTime, QQueryOperations>
      startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<FocusSessionEntity, int, QQueryOperations> taskIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskId');
    });
  }

  QueryBuilder<FocusSessionEntity, int?, QQueryOperations>
      transferredToTaskIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transferredToTaskId');
    });
  }
}
