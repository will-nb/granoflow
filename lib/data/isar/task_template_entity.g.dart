// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_template_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTaskTemplateEntityCollection on Isar {
  IsarCollection<TaskTemplateEntity> get taskTemplateEntitys =>
      this.collection();
}

const TaskTemplateEntitySchema = CollectionSchema(
  name: r'TaskTemplateEntity',
  id: -4378599829495653226,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'defaultTags': PropertySchema(
      id: 1,
      name: r'defaultTags',
      type: IsarType.stringList,
    ),
    r'lastUsedAt': PropertySchema(
      id: 2,
      name: r'lastUsedAt',
      type: IsarType.dateTime,
    ),
    r'parentTaskId': PropertySchema(
      id: 3,
      name: r'parentTaskId',
      type: IsarType.long,
    ),
    r'seedSlug': PropertySchema(
      id: 4,
      name: r'seedSlug',
      type: IsarType.string,
    ),
    r'suggestedEstimateMinutes': PropertySchema(
      id: 5,
      name: r'suggestedEstimateMinutes',
      type: IsarType.long,
    ),
    r'title': PropertySchema(id: 6, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _taskTemplateEntityEstimateSize,
  serialize: _taskTemplateEntitySerialize,
  deserialize: _taskTemplateEntityDeserialize,
  deserializeProp: _taskTemplateEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _taskTemplateEntityGetId,
  getLinks: _taskTemplateEntityGetLinks,
  attach: _taskTemplateEntityAttach,
  version: '3.1.0+1',
);

int _taskTemplateEntityEstimateSize(
  TaskTemplateEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.defaultTags.length * 3;
  {
    for (var i = 0; i < object.defaultTags.length; i++) {
      final value = object.defaultTags[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.seedSlug;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _taskTemplateEntitySerialize(
  TaskTemplateEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeStringList(offsets[1], object.defaultTags);
  writer.writeDateTime(offsets[2], object.lastUsedAt);
  writer.writeLong(offsets[3], object.parentTaskId);
  writer.writeString(offsets[4], object.seedSlug);
  writer.writeLong(offsets[5], object.suggestedEstimateMinutes);
  writer.writeString(offsets[6], object.title);
  writer.writeDateTime(offsets[7], object.updatedAt);
}

TaskTemplateEntity _taskTemplateEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TaskTemplateEntity();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.defaultTags = reader.readStringList(offsets[1]) ?? [];
  object.id = id;
  object.lastUsedAt = reader.readDateTimeOrNull(offsets[2]);
  object.parentTaskId = reader.readLongOrNull(offsets[3]);
  object.seedSlug = reader.readStringOrNull(offsets[4]);
  object.suggestedEstimateMinutes = reader.readLongOrNull(offsets[5]);
  object.title = reader.readString(offsets[6]);
  object.updatedAt = reader.readDateTime(offsets[7]);
  return object;
}

P _taskTemplateEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _taskTemplateEntityGetId(TaskTemplateEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _taskTemplateEntityGetLinks(
  TaskTemplateEntity object,
) {
  return [];
}

void _taskTemplateEntityAttach(
  IsarCollection<dynamic> col,
  Id id,
  TaskTemplateEntity object,
) {
  object.id = id;
}

extension TaskTemplateEntityQueryWhereSort
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QWhere> {
  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TaskTemplateEntityQueryWhere
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QWhereClause> {
  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterWhereClause>
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

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension TaskTemplateEntityQueryFilter
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QFilterCondition> {
  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'defaultTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'defaultTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'defaultTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'defaultTags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'defaultTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'defaultTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'defaultTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'defaultTags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'defaultTags', value: ''),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'defaultTags', value: ''),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'defaultTags', length, true, length, true);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'defaultTags', 0, true, 0, true);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'defaultTags', 0, false, 999999, true);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'defaultTags', 0, true, length, include);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'defaultTags', length, include, 999999, true);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  defaultTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'defaultTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  lastUsedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUsedAt'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  lastUsedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUsedAt'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  lastUsedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUsedAt', value: value),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  lastUsedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUsedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  lastUsedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUsedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  lastUsedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUsedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  parentTaskIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'parentTaskId'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  parentTaskIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'parentTaskId'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  parentTaskIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'parentTaskId', value: value),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  parentTaskIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'parentTaskId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  parentTaskIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'parentTaskId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  parentTaskIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'parentTaskId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'seedSlug'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'seedSlug'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'seedSlug',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'seedSlug',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'seedSlug',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'seedSlug',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'seedSlug',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'seedSlug',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'seedSlug',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'seedSlug',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'seedSlug', value: ''),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  seedSlugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'seedSlug', value: ''),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  suggestedEstimateMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'suggestedEstimateMinutes'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  suggestedEstimateMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'suggestedEstimateMinutes'),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  suggestedEstimateMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'suggestedEstimateMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  suggestedEstimateMinutesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'suggestedEstimateMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  suggestedEstimateMinutesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'suggestedEstimateMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  suggestedEstimateMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'suggestedEstimateMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension TaskTemplateEntityQueryObject
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QFilterCondition> {}

extension TaskTemplateEntityQueryLinks
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QFilterCondition> {}

extension TaskTemplateEntityQuerySortBy
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QSortBy> {
  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByParentTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentTaskId', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByParentTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentTaskId', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortBySeedSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortBySeedSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortBySuggestedEstimateMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedEstimateMinutes', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortBySuggestedEstimateMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedEstimateMinutes', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TaskTemplateEntityQuerySortThenBy
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QSortThenBy> {
  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByLastUsedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedAt', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByParentTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentTaskId', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByParentTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentTaskId', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenBySeedSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenBySeedSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenBySuggestedEstimateMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedEstimateMinutes', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenBySuggestedEstimateMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedEstimateMinutes', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TaskTemplateEntityQueryWhereDistinct
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct> {
  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctByDefaultTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultTags');
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctByLastUsedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsedAt');
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctByParentTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentTaskId');
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctBySeedSlug({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seedSlug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctBySuggestedEstimateMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'suggestedEstimateMinutes');
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension TaskTemplateEntityQueryProperty
    on QueryBuilder<TaskTemplateEntity, TaskTemplateEntity, QQueryProperty> {
  QueryBuilder<TaskTemplateEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TaskTemplateEntity, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TaskTemplateEntity, List<String>, QQueryOperations>
  defaultTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultTags');
    });
  }

  QueryBuilder<TaskTemplateEntity, DateTime?, QQueryOperations>
  lastUsedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsedAt');
    });
  }

  QueryBuilder<TaskTemplateEntity, int?, QQueryOperations>
  parentTaskIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentTaskId');
    });
  }

  QueryBuilder<TaskTemplateEntity, String?, QQueryOperations>
  seedSlugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seedSlug');
    });
  }

  QueryBuilder<TaskTemplateEntity, int?, QQueryOperations>
  suggestedEstimateMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'suggestedEstimateMinutes');
    });
  }

  QueryBuilder<TaskTemplateEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<TaskTemplateEntity, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
