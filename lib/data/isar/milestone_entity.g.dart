// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMilestoneEntityCollection on Isar {
  IsarCollection<MilestoneEntity> get milestoneEntitys => this.collection();
}

const MilestoneEntitySchema = CollectionSchema(
  name: r'MilestoneEntity',
  id: 8298319388352617126,
  properties: {
    r'allowInstantComplete': PropertySchema(
      id: 0,
      name: r'allowInstantComplete',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'dueAt': PropertySchema(
      id: 3,
      name: r'dueAt',
      type: IsarType.dateTime,
    ),
    r'endedAt': PropertySchema(
      id: 4,
      name: r'endedAt',
      type: IsarType.dateTime,
    ),
    r'logs': PropertySchema(
      id: 5,
      name: r'logs',
      type: IsarType.objectList,
      target: r'MilestoneLogEntryEntity',
    ),
    r'milestoneId': PropertySchema(
      id: 6,
      name: r'milestoneId',
      type: IsarType.string,
    ),
    r'projectId': PropertySchema(
      id: 7,
      name: r'projectId',
      type: IsarType.string,
    ),
    r'projectIsarId': PropertySchema(
      id: 8,
      name: r'projectIsarId',
      type: IsarType.long,
    ),
    r'seedSlug': PropertySchema(
      id: 9,
      name: r'seedSlug',
      type: IsarType.string,
    ),
    r'sortIndex': PropertySchema(
      id: 10,
      name: r'sortIndex',
      type: IsarType.double,
    ),
    r'startedAt': PropertySchema(
      id: 11,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.byte,
      enumMap: _MilestoneEntitystatusEnumValueMap,
    ),
    r'tags': PropertySchema(
      id: 13,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'templateLockCount': PropertySchema(
      id: 14,
      name: r'templateLockCount',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 15,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 16,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _milestoneEntityEstimateSize,
  serialize: _milestoneEntitySerialize,
  deserialize: _milestoneEntityDeserialize,
  deserializeProp: _milestoneEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'projectIsarId': IndexSchema(
      id: 5677975367602273851,
      name: r'projectIsarId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectIsarId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'projectId': IndexSchema(
      id: 3305656282123791113,
      name: r'projectId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'dueAt': IndexSchema(
      id: 3701044435752459706,
      name: r'dueAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dueAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'sortIndex': IndexSchema(
      id: -1914576846740722168,
      name: r'sortIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sortIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'MilestoneLogEntryEntity': MilestoneLogEntryEntitySchema},
  getId: _milestoneEntityGetId,
  getLinks: _milestoneEntityGetLinks,
  attach: _milestoneEntityAttach,
  version: '3.1.0+1',
);

int _milestoneEntityEstimateSize(
  MilestoneEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.logs.length * 3;
  {
    final offsets = allOffsets[MilestoneLogEntryEntity]!;
    for (var i = 0; i < object.logs.length; i++) {
      final value = object.logs[i];
      bytesCount += MilestoneLogEntryEntitySchema.estimateSize(
          value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.milestoneId.length * 3;
  bytesCount += 3 + object.projectId.length * 3;
  {
    final value = object.seedSlug;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _milestoneEntitySerialize(
  MilestoneEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.allowInstantComplete);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.description);
  writer.writeDateTime(offsets[3], object.dueAt);
  writer.writeDateTime(offsets[4], object.endedAt);
  writer.writeObjectList<MilestoneLogEntryEntity>(
    offsets[5],
    allOffsets,
    MilestoneLogEntryEntitySchema.serialize,
    object.logs,
  );
  writer.writeString(offsets[6], object.milestoneId);
  writer.writeString(offsets[7], object.projectId);
  writer.writeLong(offsets[8], object.projectIsarId);
  writer.writeString(offsets[9], object.seedSlug);
  writer.writeDouble(offsets[10], object.sortIndex);
  writer.writeDateTime(offsets[11], object.startedAt);
  writer.writeByte(offsets[12], object.status.index);
  writer.writeStringList(offsets[13], object.tags);
  writer.writeLong(offsets[14], object.templateLockCount);
  writer.writeString(offsets[15], object.title);
  writer.writeDateTime(offsets[16], object.updatedAt);
}

MilestoneEntity _milestoneEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MilestoneEntity();
  object.allowInstantComplete = reader.readBool(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.description = reader.readStringOrNull(offsets[2]);
  object.dueAt = reader.readDateTimeOrNull(offsets[3]);
  object.endedAt = reader.readDateTimeOrNull(offsets[4]);
  object.id = id;
  object.logs = reader.readObjectList<MilestoneLogEntryEntity>(
        offsets[5],
        MilestoneLogEntryEntitySchema.deserialize,
        allOffsets,
        MilestoneLogEntryEntity(),
      ) ??
      [];
  object.milestoneId = reader.readString(offsets[6]);
  object.projectId = reader.readString(offsets[7]);
  object.projectIsarId = reader.readLongOrNull(offsets[8]);
  object.seedSlug = reader.readStringOrNull(offsets[9]);
  object.sortIndex = reader.readDouble(offsets[10]);
  object.startedAt = reader.readDateTimeOrNull(offsets[11]);
  object.status =
      _MilestoneEntitystatusValueEnumMap[reader.readByteOrNull(offsets[12])] ??
          TaskStatus.inbox;
  object.tags = reader.readStringList(offsets[13]) ?? [];
  object.templateLockCount = reader.readLong(offsets[14]);
  object.title = reader.readString(offsets[15]);
  object.updatedAt = reader.readDateTime(offsets[16]);
  return object;
}

P _milestoneEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readObjectList<MilestoneLogEntryEntity>(
            offset,
            MilestoneLogEntryEntitySchema.deserialize,
            allOffsets,
            MilestoneLogEntryEntity(),
          ) ??
          []) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (_MilestoneEntitystatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          TaskStatus.inbox) as P;
    case 13:
      return (reader.readStringList(offset) ?? []) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MilestoneEntitystatusEnumValueMap = {
  'inbox': 0,
  'pending': 1,
  'doing': 2,
  'completedActive': 3,
  'archived': 4,
  'trashed': 5,
  'pseudoDeleted': 6,
};
const _MilestoneEntitystatusValueEnumMap = {
  0: TaskStatus.inbox,
  1: TaskStatus.pending,
  2: TaskStatus.doing,
  3: TaskStatus.completedActive,
  4: TaskStatus.archived,
  5: TaskStatus.trashed,
  6: TaskStatus.pseudoDeleted,
};

Id _milestoneEntityGetId(MilestoneEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _milestoneEntityGetLinks(MilestoneEntity object) {
  return [];
}

void _milestoneEntityAttach(
    IsarCollection<dynamic> col, Id id, MilestoneEntity object) {
  object.id = id;
}

extension MilestoneEntityQueryWhereSort
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QWhere> {
  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhere>
      anyProjectIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'projectIsarId'),
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhere> anyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'status'),
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhere> anyDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dueAt'),
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhere> anySortIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sortIndex'),
      );
    });
  }
}

extension MilestoneEntityQueryWhere
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QWhereClause> {
  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIsarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectIsarId',
        value: [null],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIsarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectIsarId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIsarIdEqualTo(int? projectIsarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectIsarId',
        value: [projectIsarId],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIsarIdNotEqualTo(int? projectIsarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectIsarId',
              lower: [],
              upper: [projectIsarId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectIsarId',
              lower: [projectIsarId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectIsarId',
              lower: [projectIsarId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectIsarId',
              lower: [],
              upper: [projectIsarId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIsarIdGreaterThan(
    int? projectIsarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectIsarId',
        lower: [projectIsarId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIsarIdLessThan(
    int? projectIsarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectIsarId',
        lower: [],
        upper: [projectIsarId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIsarIdBetween(
    int? lowerProjectIsarId,
    int? upperProjectIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectIsarId',
        lower: [lowerProjectIsarId],
        includeLower: includeLower,
        upper: [upperProjectIsarId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIdEqualTo(String projectId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectId',
        value: [projectId],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      projectIdNotEqualTo(String projectId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      statusEqualTo(TaskStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      statusNotEqualTo(TaskStatus status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      statusGreaterThan(
    TaskStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [status],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      statusLessThan(
    TaskStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [],
        upper: [status],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      statusBetween(
    TaskStatus lowerStatus,
    TaskStatus upperStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [lowerStatus],
        includeLower: includeLower,
        upper: [upperStatus],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      dueAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dueAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      dueAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      dueAtEqualTo(DateTime? dueAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dueAt',
        value: [dueAt],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      dueAtNotEqualTo(DateTime? dueAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueAt',
              lower: [],
              upper: [dueAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueAt',
              lower: [dueAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueAt',
              lower: [dueAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueAt',
              lower: [],
              upper: [dueAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      dueAtGreaterThan(
    DateTime? dueAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueAt',
        lower: [dueAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      dueAtLessThan(
    DateTime? dueAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueAt',
        lower: [],
        upper: [dueAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      dueAtBetween(
    DateTime? lowerDueAt,
    DateTime? upperDueAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueAt',
        lower: [lowerDueAt],
        includeLower: includeLower,
        upper: [upperDueAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      sortIndexEqualTo(double sortIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sortIndex',
        value: [sortIndex],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      sortIndexNotEqualTo(double sortIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sortIndex',
              lower: [],
              upper: [sortIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sortIndex',
              lower: [sortIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sortIndex',
              lower: [sortIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sortIndex',
              lower: [],
              upper: [sortIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      sortIndexGreaterThan(
    double sortIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sortIndex',
        lower: [sortIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      sortIndexLessThan(
    double sortIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sortIndex',
        lower: [],
        upper: [sortIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterWhereClause>
      sortIndexBetween(
    double lowerSortIndex,
    double upperSortIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sortIndex',
        lower: [lowerSortIndex],
        includeLower: includeLower,
        upper: [upperSortIndex],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MilestoneEntityQueryFilter
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QFilterCondition> {
  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      allowInstantCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allowInstantComplete',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      dueAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dueAt',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      dueAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dueAt',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      dueAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      dueAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      dueAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      dueAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      endedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      endedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endedAt',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      endedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      logsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'logs',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      logsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'logs',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      logsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'logs',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      logsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'logs',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      logsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'logs',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      logsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'logs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'milestoneId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'milestoneId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'milestoneId',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      milestoneIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'milestoneId',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'projectId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'projectId',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIsarIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'projectIsarId',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIsarIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'projectIsarId',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIsarIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectIsarId',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIsarIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectIsarId',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIsarIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectIsarId',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      projectIsarIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectIsarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'seedSlug',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'seedSlug',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seedSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seedSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seedSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seedSlug',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'seedSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'seedSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'seedSlug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'seedSlug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seedSlug',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      seedSlugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'seedSlug',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      sortIndexEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      sortIndexGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sortIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      sortIndexLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sortIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      sortIndexBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sortIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      startedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      startedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      startedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime? value, {
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      startedAtLessThan(
    DateTime? value, {
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      startedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      statusEqualTo(TaskStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      statusGreaterThan(
    TaskStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      statusLessThan(
    TaskStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      statusBetween(
    TaskStatus lower,
    TaskStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      templateLockCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateLockCount',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      templateLockCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'templateLockCount',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      templateLockCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'templateLockCount',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      templateLockCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'templateLockCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MilestoneEntityQueryObject
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QFilterCondition> {
  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterFilterCondition>
      logsElement(FilterQuery<MilestoneLogEntryEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'logs');
    });
  }
}

extension MilestoneEntityQueryLinks
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QFilterCondition> {}

extension MilestoneEntityQuerySortBy
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QSortBy> {
  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByAllowInstantComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowInstantComplete', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByAllowInstantCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowInstantComplete', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> sortByDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByDueAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> sortByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByMilestoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByMilestoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByProjectIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectIsarId', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByProjectIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectIsarId', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortBySeedSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortBySeedSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortBySortIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortIndex', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortBySortIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortIndex', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByTemplateLockCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateLockCount', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByTemplateLockCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateLockCount', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension MilestoneEntityQuerySortThenBy
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QSortThenBy> {
  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByAllowInstantComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowInstantComplete', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByAllowInstantCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowInstantComplete', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> thenByDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByDueAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> thenByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByMilestoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByMilestoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByProjectIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectIsarId', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByProjectIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectIsarId', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenBySeedSlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenBySeedSlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedSlug', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenBySortIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortIndex', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenBySortIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sortIndex', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByTemplateLockCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateLockCount', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByTemplateLockCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateLockCount', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension MilestoneEntityQueryWhereDistinct
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct> {
  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByAllowInstantComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowInstantComplete');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct> distinctByDueAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueAt');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endedAt');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByMilestoneId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'milestoneId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct> distinctByProjectId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByProjectIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectIsarId');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct> distinctBySeedSlug(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seedSlug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctBySortIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sortIndex');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByTemplateLockCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'templateLockCount');
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MilestoneEntity, MilestoneEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension MilestoneEntityQueryProperty
    on QueryBuilder<MilestoneEntity, MilestoneEntity, QQueryProperty> {
  QueryBuilder<MilestoneEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MilestoneEntity, bool, QQueryOperations>
      allowInstantCompleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowInstantComplete');
    });
  }

  QueryBuilder<MilestoneEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MilestoneEntity, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<MilestoneEntity, DateTime?, QQueryOperations> dueAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueAt');
    });
  }

  QueryBuilder<MilestoneEntity, DateTime?, QQueryOperations> endedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endedAt');
    });
  }

  QueryBuilder<MilestoneEntity, List<MilestoneLogEntryEntity>, QQueryOperations>
      logsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logs');
    });
  }

  QueryBuilder<MilestoneEntity, String, QQueryOperations>
      milestoneIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'milestoneId');
    });
  }

  QueryBuilder<MilestoneEntity, String, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }

  QueryBuilder<MilestoneEntity, int?, QQueryOperations>
      projectIsarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectIsarId');
    });
  }

  QueryBuilder<MilestoneEntity, String?, QQueryOperations> seedSlugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seedSlug');
    });
  }

  QueryBuilder<MilestoneEntity, double, QQueryOperations> sortIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sortIndex');
    });
  }

  QueryBuilder<MilestoneEntity, DateTime?, QQueryOperations>
      startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<MilestoneEntity, TaskStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<MilestoneEntity, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<MilestoneEntity, int, QQueryOperations>
      templateLockCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateLockCount');
    });
  }

  QueryBuilder<MilestoneEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<MilestoneEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MilestoneLogEntryEntitySchema = Schema(
  name: r'MilestoneLogEntryEntity',
  id: 5230906667355323257,
  properties: {
    r'action': PropertySchema(
      id: 0,
      name: r'action',
      type: IsarType.string,
    ),
    r'actor': PropertySchema(
      id: 1,
      name: r'actor',
      type: IsarType.string,
    ),
    r'next': PropertySchema(
      id: 2,
      name: r'next',
      type: IsarType.string,
    ),
    r'previous': PropertySchema(
      id: 3,
      name: r'previous',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 4,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _milestoneLogEntryEntityEstimateSize,
  serialize: _milestoneLogEntryEntitySerialize,
  deserialize: _milestoneLogEntryEntityDeserialize,
  deserializeProp: _milestoneLogEntryEntityDeserializeProp,
);

int _milestoneLogEntryEntityEstimateSize(
  MilestoneLogEntryEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.action.length * 3;
  {
    final value = object.actor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.next;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.previous;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _milestoneLogEntryEntitySerialize(
  MilestoneLogEntryEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.action);
  writer.writeString(offsets[1], object.actor);
  writer.writeString(offsets[2], object.next);
  writer.writeString(offsets[3], object.previous);
  writer.writeDateTime(offsets[4], object.timestamp);
}

MilestoneLogEntryEntity _milestoneLogEntryEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MilestoneLogEntryEntity();
  object.action = reader.readString(offsets[0]);
  object.actor = reader.readStringOrNull(offsets[1]);
  object.next = reader.readStringOrNull(offsets[2]);
  object.previous = reader.readStringOrNull(offsets[3]);
  object.timestamp = reader.readDateTime(offsets[4]);
  return object;
}

P _milestoneLogEntryEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MilestoneLogEntryEntityQueryFilter on QueryBuilder<
    MilestoneLogEntryEntity, MilestoneLogEntryEntity, QFilterCondition> {
  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'action',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      actionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'action',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      actionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'action',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'action',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actor',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actor',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'actor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'actor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      actorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'actor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      actorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'actor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actor',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> actorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'actor',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'next',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'next',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'next',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'next',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'next',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'next',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'next',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'next',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      nextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'next',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      nextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'next',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'next',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> nextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'next',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'previous',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'previous',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'previous',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'previous',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'previous',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'previous',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'previous',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'previous',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      previousContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'previous',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
          QAfterFilterCondition>
      previousMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'previous',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'previous',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> previousIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'previous',
        value: '',
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MilestoneLogEntryEntity, MilestoneLogEntryEntity,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MilestoneLogEntryEntityQueryObject on QueryBuilder<
    MilestoneLogEntryEntity, MilestoneLogEntryEntity, QFilterCondition> {}
