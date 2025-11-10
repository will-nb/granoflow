// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _milestoneIdMeta = const VerificationMeta(
    'milestoneId',
  );
  @override
  late final GeneratedColumn<String> milestoneId = GeneratedColumn<String>(
    'milestone_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<double> sortIndex = GeneratedColumn<double>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($TasksTable.$convertertags);
  static const VerificationMeta _templateLockCountMeta = const VerificationMeta(
    'templateLockCount',
  );
  @override
  late final GeneratedColumn<int> templateLockCount = GeneratedColumn<int>(
    'template_lock_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedSlugMeta = const VerificationMeta(
    'seedSlug',
  );
  @override
  late final GeneratedColumn<String> seedSlug = GeneratedColumn<String>(
    'seed_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowInstantCompleteMeta =
      const VerificationMeta('allowInstantComplete');
  @override
  late final GeneratedColumn<bool> allowInstantComplete = GeneratedColumn<bool>(
    'allow_instant_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_instant_complete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    archivedAt,
    createdAt,
    updatedAt,
    parentId,
    projectId,
    milestoneId,
    sortIndex,
    tags,
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('milestone_id')) {
      context.handle(
        _milestoneIdMeta,
        milestoneId.isAcceptableOrUnknown(
          data['milestone_id']!,
          _milestoneIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('template_lock_count')) {
      context.handle(
        _templateLockCountMeta,
        templateLockCount.isAcceptableOrUnknown(
          data['template_lock_count']!,
          _templateLockCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateLockCountMeta);
    }
    if (data.containsKey('seed_slug')) {
      context.handle(
        _seedSlugMeta,
        seedSlug.isAcceptableOrUnknown(data['seed_slug']!, _seedSlugMeta),
      );
    }
    if (data.containsKey('allow_instant_complete')) {
      context.handle(
        _allowInstantCompleteMeta,
        allowInstantComplete.isAcceptableOrUnknown(
          data['allow_instant_complete']!,
          _allowInstantCompleteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowInstantCompleteMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      milestoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestone_id'],
      ),
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sort_index'],
      )!,
      tags: $TasksTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      templateLockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_lock_count'],
      )!,
      seedSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_slug'],
      ),
      allowInstantComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_instant_complete'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<TaskStatus>(TaskStatus.values);
  static TypeConverter<List<String>, String> $convertertags =
      const ListStringTypeConverter();
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentId;
  final String? projectId;
  final String? milestoneId;
  final double sortIndex;
  final List<String> tags;
  final int templateLockCount;
  final String? seedSlug;
  final bool allowInstantComplete;
  final String? description;
  const Task({
    required this.id,
    required this.title,
    required this.status,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.projectId,
    this.milestoneId,
    required this.sortIndex,
    required this.tags,
    required this.templateLockCount,
    this.seedSlug,
    required this.allowInstantComplete,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    {
      map['status'] = Variable<int>($TasksTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || milestoneId != null) {
      map['milestone_id'] = Variable<String>(milestoneId);
    }
    map['sort_index'] = Variable<double>(sortIndex);
    {
      map['tags'] = Variable<String>($TasksTable.$convertertags.toSql(tags));
    }
    map['template_lock_count'] = Variable<int>(templateLockCount);
    if (!nullToAbsent || seedSlug != null) {
      map['seed_slug'] = Variable<String>(seedSlug);
    }
    map['allow_instant_complete'] = Variable<bool>(allowInstantComplete);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      status: Value(status),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      milestoneId: milestoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(milestoneId),
      sortIndex: Value(sortIndex),
      tags: Value(tags),
      templateLockCount: Value(templateLockCount),
      seedSlug: seedSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(seedSlug),
      allowInstantComplete: Value(allowInstantComplete),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      milestoneId: serializer.fromJson<String?>(json['milestoneId']),
      sortIndex: serializer.fromJson<double>(json['sortIndex']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      templateLockCount: serializer.fromJson<int>(json['templateLockCount']),
      seedSlug: serializer.fromJson<String?>(json['seedSlug']),
      allowInstantComplete: serializer.fromJson<bool>(
        json['allowInstantComplete'],
      ),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<int>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'parentId': serializer.toJson<String?>(parentId),
      'projectId': serializer.toJson<String?>(projectId),
      'milestoneId': serializer.toJson<String?>(milestoneId),
      'sortIndex': serializer.toJson<double>(sortIndex),
      'tags': serializer.toJson<List<String>>(tags),
      'templateLockCount': serializer.toJson<int>(templateLockCount),
      'seedSlug': serializer.toJson<String?>(seedSlug),
      'allowInstantComplete': serializer.toJson<bool>(allowInstantComplete),
      'description': serializer.toJson<String?>(description),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    TaskStatus? status,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> parentId = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    Value<String?> milestoneId = const Value.absent(),
    double? sortIndex,
    List<String>? tags,
    int? templateLockCount,
    Value<String?> seedSlug = const Value.absent(),
    bool? allowInstantComplete,
    Value<String?> description = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    status: status ?? this.status,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    parentId: parentId.present ? parentId.value : this.parentId,
    projectId: projectId.present ? projectId.value : this.projectId,
    milestoneId: milestoneId.present ? milestoneId.value : this.milestoneId,
    sortIndex: sortIndex ?? this.sortIndex,
    tags: tags ?? this.tags,
    templateLockCount: templateLockCount ?? this.templateLockCount,
    seedSlug: seedSlug.present ? seedSlug.value : this.seedSlug,
    allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
    description: description.present ? description.value : this.description,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      milestoneId: data.milestoneId.present
          ? data.milestoneId.value
          : this.milestoneId,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      tags: data.tags.present ? data.tags.value : this.tags,
      templateLockCount: data.templateLockCount.present
          ? data.templateLockCount.value
          : this.templateLockCount,
      seedSlug: data.seedSlug.present ? data.seedSlug.value : this.seedSlug,
      allowInstantComplete: data.allowInstantComplete.present
          ? data.allowInstantComplete.value
          : this.allowInstantComplete,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('parentId: $parentId, ')
          ..write('projectId: $projectId, ')
          ..write('milestoneId: $milestoneId, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('tags: $tags, ')
          ..write('templateLockCount: $templateLockCount, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('allowInstantComplete: $allowInstantComplete, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    archivedAt,
    createdAt,
    updatedAt,
    parentId,
    projectId,
    milestoneId,
    sortIndex,
    tags,
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.status == this.status &&
          other.dueAt == this.dueAt &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.parentId == this.parentId &&
          other.projectId == this.projectId &&
          other.milestoneId == this.milestoneId &&
          other.sortIndex == this.sortIndex &&
          other.tags == this.tags &&
          other.templateLockCount == this.templateLockCount &&
          other.seedSlug == this.seedSlug &&
          other.allowInstantComplete == this.allowInstantComplete &&
          other.description == this.description);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<TaskStatus> status;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> parentId;
  final Value<String?> projectId;
  final Value<String?> milestoneId;
  final Value<double> sortIndex;
  final Value<List<String>> tags;
  final Value<int> templateLockCount;
  final Value<String?> seedSlug;
  final Value<bool> allowInstantComplete;
  final Value<String?> description;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.parentId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.milestoneId = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.tags = const Value.absent(),
    this.templateLockCount = const Value.absent(),
    this.seedSlug = const Value.absent(),
    this.allowInstantComplete = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    required TaskStatus status,
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.parentId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.milestoneId = const Value.absent(),
    required double sortIndex,
    required List<String> tags,
    required int templateLockCount,
    this.seedSlug = const Value.absent(),
    required bool allowInstantComplete,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       sortIndex = Value(sortIndex),
       tags = Value(tags),
       templateLockCount = Value(templateLockCount),
       allowInstantComplete = Value(allowInstantComplete);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? status,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? parentId,
    Expression<String>? projectId,
    Expression<String>? milestoneId,
    Expression<double>? sortIndex,
    Expression<String>? tags,
    Expression<int>? templateLockCount,
    Expression<String>? seedSlug,
    Expression<bool>? allowInstantComplete,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (dueAt != null) 'due_at': dueAt,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (parentId != null) 'parent_id': parentId,
      if (projectId != null) 'project_id': projectId,
      if (milestoneId != null) 'milestone_id': milestoneId,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (tags != null) 'tags': tags,
      if (templateLockCount != null) 'template_lock_count': templateLockCount,
      if (seedSlug != null) 'seed_slug': seedSlug,
      if (allowInstantComplete != null)
        'allow_instant_complete': allowInstantComplete,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<TaskStatus>? status,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? parentId,
    Value<String?>? projectId,
    Value<String?>? milestoneId,
    Value<double>? sortIndex,
    Value<List<String>>? tags,
    Value<int>? templateLockCount,
    Value<String?>? seedSlug,
    Value<bool>? allowInstantComplete,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      projectId: projectId ?? this.projectId,
      milestoneId: milestoneId ?? this.milestoneId,
      sortIndex: sortIndex ?? this.sortIndex,
      tags: tags ?? this.tags,
      templateLockCount: templateLockCount ?? this.templateLockCount,
      seedSlug: seedSlug ?? this.seedSlug,
      allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (milestoneId.present) {
      map['milestone_id'] = Variable<String>(milestoneId.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<double>(sortIndex.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $TasksTable.$convertertags.toSql(tags.value),
      );
    }
    if (templateLockCount.present) {
      map['template_lock_count'] = Variable<int>(templateLockCount.value);
    }
    if (seedSlug.present) {
      map['seed_slug'] = Variable<String>(seedSlug.value);
    }
    if (allowInstantComplete.present) {
      map['allow_instant_complete'] = Variable<bool>(
        allowInstantComplete.value,
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('parentId: $parentId, ')
          ..write('projectId: $projectId, ')
          ..write('milestoneId: $milestoneId, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('tags: $tags, ')
          ..write('templateLockCount: $templateLockCount, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('allowInstantComplete: $allowInstantComplete, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskStatus>($ProjectsTable.$converterstatus);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<double> sortIndex = GeneratedColumn<double>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ProjectsTable.$convertertags);
  static const VerificationMeta _templateLockCountMeta = const VerificationMeta(
    'templateLockCount',
  );
  @override
  late final GeneratedColumn<int> templateLockCount = GeneratedColumn<int>(
    'template_lock_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedSlugMeta = const VerificationMeta(
    'seedSlug',
  );
  @override
  late final GeneratedColumn<String> seedSlug = GeneratedColumn<String>(
    'seed_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowInstantCompleteMeta =
      const VerificationMeta('allowInstantComplete');
  @override
  late final GeneratedColumn<bool> allowInstantComplete = GeneratedColumn<bool>(
    'allow_instant_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_instant_complete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    sortIndex,
    tags,
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('template_lock_count')) {
      context.handle(
        _templateLockCountMeta,
        templateLockCount.isAcceptableOrUnknown(
          data['template_lock_count']!,
          _templateLockCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateLockCountMeta);
    }
    if (data.containsKey('seed_slug')) {
      context.handle(
        _seedSlugMeta,
        seedSlug.isAcceptableOrUnknown(data['seed_slug']!, _seedSlugMeta),
      );
    }
    if (data.containsKey('allow_instant_complete')) {
      context.handle(
        _allowInstantCompleteMeta,
        allowInstantComplete.isAcceptableOrUnknown(
          data['allow_instant_complete']!,
          _allowInstantCompleteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowInstantCompleteMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: $ProjectsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sort_index'],
      )!,
      tags: $ProjectsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      templateLockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_lock_count'],
      )!,
      seedSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_slug'],
      ),
      allowInstantComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_instant_complete'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<TaskStatus>(TaskStatus.values);
  static TypeConverter<List<String>, String> $convertertags =
      const ListStringTypeConverter();
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double sortIndex;
  final List<String> tags;
  final int templateLockCount;
  final String? seedSlug;
  final bool allowInstantComplete;
  final String? description;
  const Project({
    required this.id,
    required this.title,
    required this.status,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.sortIndex,
    required this.tags,
    required this.templateLockCount,
    this.seedSlug,
    required this.allowInstantComplete,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    {
      map['status'] = Variable<int>(
        $ProjectsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sort_index'] = Variable<double>(sortIndex);
    {
      map['tags'] = Variable<String>($ProjectsTable.$convertertags.toSql(tags));
    }
    map['template_lock_count'] = Variable<int>(templateLockCount);
    if (!nullToAbsent || seedSlug != null) {
      map['seed_slug'] = Variable<String>(seedSlug);
    }
    map['allow_instant_complete'] = Variable<bool>(allowInstantComplete);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      title: Value(title),
      status: Value(status),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sortIndex: Value(sortIndex),
      tags: Value(tags),
      templateLockCount: Value(templateLockCount),
      seedSlug: seedSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(seedSlug),
      allowInstantComplete: Value(allowInstantComplete),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      status: $ProjectsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sortIndex: serializer.fromJson<double>(json['sortIndex']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      templateLockCount: serializer.fromJson<int>(json['templateLockCount']),
      seedSlug: serializer.fromJson<String?>(json['seedSlug']),
      allowInstantComplete: serializer.fromJson<bool>(
        json['allowInstantComplete'],
      ),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<int>(
        $ProjectsTable.$converterstatus.toJson(status),
      ),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sortIndex': serializer.toJson<double>(sortIndex),
      'tags': serializer.toJson<List<String>>(tags),
      'templateLockCount': serializer.toJson<int>(templateLockCount),
      'seedSlug': serializer.toJson<String?>(seedSlug),
      'allowInstantComplete': serializer.toJson<bool>(allowInstantComplete),
      'description': serializer.toJson<String?>(description),
    };
  }

  Project copyWith({
    String? id,
    String? title,
    TaskStatus? status,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    double? sortIndex,
    List<String>? tags,
    int? templateLockCount,
    Value<String?> seedSlug = const Value.absent(),
    bool? allowInstantComplete,
    Value<String?> description = const Value.absent(),
  }) => Project(
    id: id ?? this.id,
    title: title ?? this.title,
    status: status ?? this.status,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sortIndex: sortIndex ?? this.sortIndex,
    tags: tags ?? this.tags,
    templateLockCount: templateLockCount ?? this.templateLockCount,
    seedSlug: seedSlug.present ? seedSlug.value : this.seedSlug,
    allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
    description: description.present ? description.value : this.description,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      tags: data.tags.present ? data.tags.value : this.tags,
      templateLockCount: data.templateLockCount.present
          ? data.templateLockCount.value
          : this.templateLockCount,
      seedSlug: data.seedSlug.present ? data.seedSlug.value : this.seedSlug,
      allowInstantComplete: data.allowInstantComplete.present
          ? data.allowInstantComplete.value
          : this.allowInstantComplete,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('tags: $tags, ')
          ..write('templateLockCount: $templateLockCount, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('allowInstantComplete: $allowInstantComplete, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    sortIndex,
    tags,
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.title == this.title &&
          other.status == this.status &&
          other.dueAt == this.dueAt &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sortIndex == this.sortIndex &&
          other.tags == this.tags &&
          other.templateLockCount == this.templateLockCount &&
          other.seedSlug == this.seedSlug &&
          other.allowInstantComplete == this.allowInstantComplete &&
          other.description == this.description);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> title;
  final Value<TaskStatus> status;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<double> sortIndex;
  final Value<List<String>> tags;
  final Value<int> templateLockCount;
  final Value<String?> seedSlug;
  final Value<bool> allowInstantComplete;
  final Value<String?> description;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.tags = const Value.absent(),
    this.templateLockCount = const Value.absent(),
    this.seedSlug = const Value.absent(),
    this.allowInstantComplete = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String title,
    required TaskStatus status,
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required double sortIndex,
    required List<String> tags,
    required int templateLockCount,
    this.seedSlug = const Value.absent(),
    required bool allowInstantComplete,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       sortIndex = Value(sortIndex),
       tags = Value(tags),
       templateLockCount = Value(templateLockCount),
       allowInstantComplete = Value(allowInstantComplete);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? status,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<double>? sortIndex,
    Expression<String>? tags,
    Expression<int>? templateLockCount,
    Expression<String>? seedSlug,
    Expression<bool>? allowInstantComplete,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (dueAt != null) 'due_at': dueAt,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (tags != null) 'tags': tags,
      if (templateLockCount != null) 'template_lock_count': templateLockCount,
      if (seedSlug != null) 'seed_slug': seedSlug,
      if (allowInstantComplete != null)
        'allow_instant_complete': allowInstantComplete,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<TaskStatus>? status,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<double>? sortIndex,
    Value<List<String>>? tags,
    Value<int>? templateLockCount,
    Value<String?>? seedSlug,
    Value<bool>? allowInstantComplete,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortIndex: sortIndex ?? this.sortIndex,
      tags: tags ?? this.tags,
      templateLockCount: templateLockCount ?? this.templateLockCount,
      seedSlug: seedSlug ?? this.seedSlug,
      allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $ProjectsTable.$converterstatus.toSql(status.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<double>(sortIndex.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $ProjectsTable.$convertertags.toSql(tags.value),
      );
    }
    if (templateLockCount.present) {
      map['template_lock_count'] = Variable<int>(templateLockCount.value);
    }
    if (seedSlug.present) {
      map['seed_slug'] = Variable<String>(seedSlug.value);
    }
    if (allowInstantComplete.present) {
      map['allow_instant_complete'] = Variable<bool>(
        allowInstantComplete.value,
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('tags: $tags, ')
          ..write('templateLockCount: $templateLockCount, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('allowInstantComplete: $allowInstantComplete, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MilestonesTable extends Milestones
    with TableInfo<$MilestonesTable, Milestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskStatus>($MilestonesTable.$converterstatus);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<double> sortIndex = GeneratedColumn<double>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($MilestonesTable.$convertertags);
  static const VerificationMeta _templateLockCountMeta = const VerificationMeta(
    'templateLockCount',
  );
  @override
  late final GeneratedColumn<int> templateLockCount = GeneratedColumn<int>(
    'template_lock_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedSlugMeta = const VerificationMeta(
    'seedSlug',
  );
  @override
  late final GeneratedColumn<String> seedSlug = GeneratedColumn<String>(
    'seed_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowInstantCompleteMeta =
      const VerificationMeta('allowInstantComplete');
  @override
  late final GeneratedColumn<bool> allowInstantComplete = GeneratedColumn<bool>(
    'allow_instant_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_instant_complete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    sortIndex,
    tags,
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Milestone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    if (data.containsKey('template_lock_count')) {
      context.handle(
        _templateLockCountMeta,
        templateLockCount.isAcceptableOrUnknown(
          data['template_lock_count']!,
          _templateLockCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateLockCountMeta);
    }
    if (data.containsKey('seed_slug')) {
      context.handle(
        _seedSlugMeta,
        seedSlug.isAcceptableOrUnknown(data['seed_slug']!, _seedSlugMeta),
      );
    }
    if (data.containsKey('allow_instant_complete')) {
      context.handle(
        _allowInstantCompleteMeta,
        allowInstantComplete.isAcceptableOrUnknown(
          data['allow_instant_complete']!,
          _allowInstantCompleteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowInstantCompleteMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Milestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Milestone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: $MilestonesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sort_index'],
      )!,
      tags: $MilestonesTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      templateLockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_lock_count'],
      )!,
      seedSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_slug'],
      ),
      allowInstantComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_instant_complete'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $MilestonesTable createAlias(String alias) {
    return $MilestonesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<TaskStatus>(TaskStatus.values);
  static TypeConverter<List<String>, String> $convertertags =
      const ListStringTypeConverter();
}

class Milestone extends DataClass implements Insertable<Milestone> {
  final String id;
  final String? projectId;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double sortIndex;
  final List<String> tags;
  final int templateLockCount;
  final String? seedSlug;
  final bool allowInstantComplete;
  final String? description;
  const Milestone({
    required this.id,
    this.projectId,
    required this.title,
    required this.status,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.sortIndex,
    required this.tags,
    required this.templateLockCount,
    this.seedSlug,
    required this.allowInstantComplete,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['title'] = Variable<String>(title);
    {
      map['status'] = Variable<int>(
        $MilestonesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sort_index'] = Variable<double>(sortIndex);
    {
      map['tags'] = Variable<String>(
        $MilestonesTable.$convertertags.toSql(tags),
      );
    }
    map['template_lock_count'] = Variable<int>(templateLockCount);
    if (!nullToAbsent || seedSlug != null) {
      map['seed_slug'] = Variable<String>(seedSlug);
    }
    map['allow_instant_complete'] = Variable<bool>(allowInstantComplete);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  MilestonesCompanion toCompanion(bool nullToAbsent) {
    return MilestonesCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      title: Value(title),
      status: Value(status),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sortIndex: Value(sortIndex),
      tags: Value(tags),
      templateLockCount: Value(templateLockCount),
      seedSlug: seedSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(seedSlug),
      allowInstantComplete: Value(allowInstantComplete),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Milestone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Milestone(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      status: $MilestonesTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sortIndex: serializer.fromJson<double>(json['sortIndex']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      templateLockCount: serializer.fromJson<int>(json['templateLockCount']),
      seedSlug: serializer.fromJson<String?>(json['seedSlug']),
      allowInstantComplete: serializer.fromJson<bool>(
        json['allowInstantComplete'],
      ),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String?>(projectId),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<int>(
        $MilestonesTable.$converterstatus.toJson(status),
      ),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sortIndex': serializer.toJson<double>(sortIndex),
      'tags': serializer.toJson<List<String>>(tags),
      'templateLockCount': serializer.toJson<int>(templateLockCount),
      'seedSlug': serializer.toJson<String?>(seedSlug),
      'allowInstantComplete': serializer.toJson<bool>(allowInstantComplete),
      'description': serializer.toJson<String?>(description),
    };
  }

  Milestone copyWith({
    String? id,
    Value<String?> projectId = const Value.absent(),
    String? title,
    TaskStatus? status,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    double? sortIndex,
    List<String>? tags,
    int? templateLockCount,
    Value<String?> seedSlug = const Value.absent(),
    bool? allowInstantComplete,
    Value<String?> description = const Value.absent(),
  }) => Milestone(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    title: title ?? this.title,
    status: status ?? this.status,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sortIndex: sortIndex ?? this.sortIndex,
    tags: tags ?? this.tags,
    templateLockCount: templateLockCount ?? this.templateLockCount,
    seedSlug: seedSlug.present ? seedSlug.value : this.seedSlug,
    allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
    description: description.present ? description.value : this.description,
  );
  Milestone copyWithCompanion(MilestonesCompanion data) {
    return Milestone(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      tags: data.tags.present ? data.tags.value : this.tags,
      templateLockCount: data.templateLockCount.present
          ? data.templateLockCount.value
          : this.templateLockCount,
      seedSlug: data.seedSlug.present ? data.seedSlug.value : this.seedSlug,
      allowInstantComplete: data.allowInstantComplete.present
          ? data.allowInstantComplete.value
          : this.allowInstantComplete,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Milestone(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('tags: $tags, ')
          ..write('templateLockCount: $templateLockCount, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('allowInstantComplete: $allowInstantComplete, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    sortIndex,
    tags,
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Milestone &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.status == this.status &&
          other.dueAt == this.dueAt &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sortIndex == this.sortIndex &&
          other.tags == this.tags &&
          other.templateLockCount == this.templateLockCount &&
          other.seedSlug == this.seedSlug &&
          other.allowInstantComplete == this.allowInstantComplete &&
          other.description == this.description);
}

class MilestonesCompanion extends UpdateCompanion<Milestone> {
  final Value<String> id;
  final Value<String?> projectId;
  final Value<String> title;
  final Value<TaskStatus> status;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<double> sortIndex;
  final Value<List<String>> tags;
  final Value<int> templateLockCount;
  final Value<String?> seedSlug;
  final Value<bool> allowInstantComplete;
  final Value<String?> description;
  final Value<int> rowid;
  const MilestonesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.tags = const Value.absent(),
    this.templateLockCount = const Value.absent(),
    this.seedSlug = const Value.absent(),
    this.allowInstantComplete = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilestonesCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required String title,
    required TaskStatus status,
    this.dueAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required double sortIndex,
    required List<String> tags,
    required int templateLockCount,
    this.seedSlug = const Value.absent(),
    required bool allowInstantComplete,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       sortIndex = Value(sortIndex),
       tags = Value(tags),
       templateLockCount = Value(templateLockCount),
       allowInstantComplete = Value(allowInstantComplete);
  static Insertable<Milestone> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? title,
    Expression<int>? status,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<double>? sortIndex,
    Expression<String>? tags,
    Expression<int>? templateLockCount,
    Expression<String>? seedSlug,
    Expression<bool>? allowInstantComplete,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (dueAt != null) 'due_at': dueAt,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (tags != null) 'tags': tags,
      if (templateLockCount != null) 'template_lock_count': templateLockCount,
      if (seedSlug != null) 'seed_slug': seedSlug,
      if (allowInstantComplete != null)
        'allow_instant_complete': allowInstantComplete,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilestonesCompanion copyWith({
    Value<String>? id,
    Value<String?>? projectId,
    Value<String>? title,
    Value<TaskStatus>? status,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<double>? sortIndex,
    Value<List<String>>? tags,
    Value<int>? templateLockCount,
    Value<String?>? seedSlug,
    Value<bool>? allowInstantComplete,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return MilestonesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortIndex: sortIndex ?? this.sortIndex,
      tags: tags ?? this.tags,
      templateLockCount: templateLockCount ?? this.templateLockCount,
      seedSlug: seedSlug ?? this.seedSlug,
      allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $MilestonesTable.$converterstatus.toSql(status.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<double>(sortIndex.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $MilestonesTable.$convertertags.toSql(tags.value),
      );
    }
    if (templateLockCount.present) {
      map['template_lock_count'] = Variable<int>(templateLockCount.value);
    }
    if (seedSlug.present) {
      map['seed_slug'] = Variable<String>(seedSlug.value);
    }
    if (allowInstantComplete.present) {
      map['allow_instant_complete'] = Variable<bool>(
        allowInstantComplete.value,
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilestonesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('tags: $tags, ')
          ..write('templateLockCount: $templateLockCount, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('allowInstantComplete: $allowInstantComplete, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskLogsTable extends TaskLogs with TableInfo<$TaskLogsTable, TaskLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousMeta = const VerificationMeta(
    'previous',
  );
  @override
  late final GeneratedColumn<String> previous = GeneratedColumn<String>(
    'previous',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextMeta = const VerificationMeta('next');
  @override
  late final GeneratedColumn<String> next = GeneratedColumn<String>(
    'next',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    timestamp,
    action,
    previous,
    next,
    actor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('previous')) {
      context.handle(
        _previousMeta,
        previous.isAcceptableOrUnknown(data['previous']!, _previousMeta),
      );
    }
    if (data.containsKey('next')) {
      context.handle(
        _nextMeta,
        next.isAcceptableOrUnknown(data['next']!, _nextMeta),
      );
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      previous: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous'],
      ),
      next: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next'],
      ),
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      ),
    );
  }

  @override
  $TaskLogsTable createAlias(String alias) {
    return $TaskLogsTable(attachedDatabase, alias);
  }
}

class TaskLog extends DataClass implements Insertable<TaskLog> {
  final String id;
  final String? taskId;
  final DateTime timestamp;
  final String action;
  final String? previous;
  final String? next;
  final String? actor;
  const TaskLog({
    required this.id,
    this.taskId,
    required this.timestamp,
    required this.action,
    this.previous,
    this.next,
    this.actor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || previous != null) {
      map['previous'] = Variable<String>(previous);
    }
    if (!nullToAbsent || next != null) {
      map['next'] = Variable<String>(next);
    }
    if (!nullToAbsent || actor != null) {
      map['actor'] = Variable<String>(actor);
    }
    return map;
  }

  TaskLogsCompanion toCompanion(bool nullToAbsent) {
    return TaskLogsCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      timestamp: Value(timestamp),
      action: Value(action),
      previous: previous == null && nullToAbsent
          ? const Value.absent()
          : Value(previous),
      next: next == null && nullToAbsent ? const Value.absent() : Value(next),
      actor: actor == null && nullToAbsent
          ? const Value.absent()
          : Value(actor),
    );
  }

  factory TaskLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskLog(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      action: serializer.fromJson<String>(json['action']),
      previous: serializer.fromJson<String?>(json['previous']),
      next: serializer.fromJson<String?>(json['next']),
      actor: serializer.fromJson<String?>(json['actor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String?>(taskId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'action': serializer.toJson<String>(action),
      'previous': serializer.toJson<String?>(previous),
      'next': serializer.toJson<String?>(next),
      'actor': serializer.toJson<String?>(actor),
    };
  }

  TaskLog copyWith({
    String? id,
    Value<String?> taskId = const Value.absent(),
    DateTime? timestamp,
    String? action,
    Value<String?> previous = const Value.absent(),
    Value<String?> next = const Value.absent(),
    Value<String?> actor = const Value.absent(),
  }) => TaskLog(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    timestamp: timestamp ?? this.timestamp,
    action: action ?? this.action,
    previous: previous.present ? previous.value : this.previous,
    next: next.present ? next.value : this.next,
    actor: actor.present ? actor.value : this.actor,
  );
  TaskLog copyWithCompanion(TaskLogsCompanion data) {
    return TaskLog(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      action: data.action.present ? data.action.value : this.action,
      previous: data.previous.present ? data.previous.value : this.previous,
      next: data.next.present ? data.next.value : this.next,
      actor: data.actor.present ? data.actor.value : this.actor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskLog(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('previous: $previous, ')
          ..write('next: $next, ')
          ..write('actor: $actor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, timestamp, action, previous, next, actor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskLog &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.timestamp == this.timestamp &&
          other.action == this.action &&
          other.previous == this.previous &&
          other.next == this.next &&
          other.actor == this.actor);
}

class TaskLogsCompanion extends UpdateCompanion<TaskLog> {
  final Value<String> id;
  final Value<String?> taskId;
  final Value<DateTime> timestamp;
  final Value<String> action;
  final Value<String?> previous;
  final Value<String?> next;
  final Value<String?> actor;
  final Value<int> rowid;
  const TaskLogsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.action = const Value.absent(),
    this.previous = const Value.absent(),
    this.next = const Value.absent(),
    this.actor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskLogsCompanion.insert({
    required String id,
    this.taskId = const Value.absent(),
    required DateTime timestamp,
    required String action,
    this.previous = const Value.absent(),
    this.next = const Value.absent(),
    this.actor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       action = Value(action);
  static Insertable<TaskLog> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<DateTime>? timestamp,
    Expression<String>? action,
    Expression<String>? previous,
    Expression<String>? next,
    Expression<String>? actor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (timestamp != null) 'timestamp': timestamp,
      if (action != null) 'action': action,
      if (previous != null) 'previous': previous,
      if (next != null) 'next': next,
      if (actor != null) 'actor': actor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskLogsCompanion copyWith({
    Value<String>? id,
    Value<String?>? taskId,
    Value<DateTime>? timestamp,
    Value<String>? action,
    Value<String?>? previous,
    Value<String?>? next,
    Value<String?>? actor,
    Value<int>? rowid,
  }) {
    return TaskLogsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      actor: actor ?? this.actor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (previous.present) {
      map['previous'] = Variable<String>(previous.value);
    }
    if (next.present) {
      map['next'] = Variable<String>(next.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskLogsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('previous: $previous, ')
          ..write('next: $next, ')
          ..write('actor: $actor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectLogsTable extends ProjectLogs
    with TableInfo<$ProjectLogsTable, ProjectLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousMeta = const VerificationMeta(
    'previous',
  );
  @override
  late final GeneratedColumn<String> previous = GeneratedColumn<String>(
    'previous',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextMeta = const VerificationMeta('next');
  @override
  late final GeneratedColumn<String> next = GeneratedColumn<String>(
    'next',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    timestamp,
    action,
    previous,
    next,
    actor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('previous')) {
      context.handle(
        _previousMeta,
        previous.isAcceptableOrUnknown(data['previous']!, _previousMeta),
      );
    }
    if (data.containsKey('next')) {
      context.handle(
        _nextMeta,
        next.isAcceptableOrUnknown(data['next']!, _nextMeta),
      );
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      previous: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous'],
      ),
      next: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next'],
      ),
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      ),
    );
  }

  @override
  $ProjectLogsTable createAlias(String alias) {
    return $ProjectLogsTable(attachedDatabase, alias);
  }
}

class ProjectLog extends DataClass implements Insertable<ProjectLog> {
  final String id;
  final String? projectId;
  final DateTime timestamp;
  final String action;
  final String? previous;
  final String? next;
  final String? actor;
  const ProjectLog({
    required this.id,
    this.projectId,
    required this.timestamp,
    required this.action,
    this.previous,
    this.next,
    this.actor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || previous != null) {
      map['previous'] = Variable<String>(previous);
    }
    if (!nullToAbsent || next != null) {
      map['next'] = Variable<String>(next);
    }
    if (!nullToAbsent || actor != null) {
      map['actor'] = Variable<String>(actor);
    }
    return map;
  }

  ProjectLogsCompanion toCompanion(bool nullToAbsent) {
    return ProjectLogsCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      timestamp: Value(timestamp),
      action: Value(action),
      previous: previous == null && nullToAbsent
          ? const Value.absent()
          : Value(previous),
      next: next == null && nullToAbsent ? const Value.absent() : Value(next),
      actor: actor == null && nullToAbsent
          ? const Value.absent()
          : Value(actor),
    );
  }

  factory ProjectLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectLog(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      action: serializer.fromJson<String>(json['action']),
      previous: serializer.fromJson<String?>(json['previous']),
      next: serializer.fromJson<String?>(json['next']),
      actor: serializer.fromJson<String?>(json['actor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String?>(projectId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'action': serializer.toJson<String>(action),
      'previous': serializer.toJson<String?>(previous),
      'next': serializer.toJson<String?>(next),
      'actor': serializer.toJson<String?>(actor),
    };
  }

  ProjectLog copyWith({
    String? id,
    Value<String?> projectId = const Value.absent(),
    DateTime? timestamp,
    String? action,
    Value<String?> previous = const Value.absent(),
    Value<String?> next = const Value.absent(),
    Value<String?> actor = const Value.absent(),
  }) => ProjectLog(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    timestamp: timestamp ?? this.timestamp,
    action: action ?? this.action,
    previous: previous.present ? previous.value : this.previous,
    next: next.present ? next.value : this.next,
    actor: actor.present ? actor.value : this.actor,
  );
  ProjectLog copyWithCompanion(ProjectLogsCompanion data) {
    return ProjectLog(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      action: data.action.present ? data.action.value : this.action,
      previous: data.previous.present ? data.previous.value : this.previous,
      next: data.next.present ? data.next.value : this.next,
      actor: data.actor.present ? data.actor.value : this.actor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectLog(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('previous: $previous, ')
          ..write('next: $next, ')
          ..write('actor: $actor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, timestamp, action, previous, next, actor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectLog &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.timestamp == this.timestamp &&
          other.action == this.action &&
          other.previous == this.previous &&
          other.next == this.next &&
          other.actor == this.actor);
}

class ProjectLogsCompanion extends UpdateCompanion<ProjectLog> {
  final Value<String> id;
  final Value<String?> projectId;
  final Value<DateTime> timestamp;
  final Value<String> action;
  final Value<String?> previous;
  final Value<String?> next;
  final Value<String?> actor;
  final Value<int> rowid;
  const ProjectLogsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.action = const Value.absent(),
    this.previous = const Value.absent(),
    this.next = const Value.absent(),
    this.actor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectLogsCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required DateTime timestamp,
    required String action,
    this.previous = const Value.absent(),
    this.next = const Value.absent(),
    this.actor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       action = Value(action);
  static Insertable<ProjectLog> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<DateTime>? timestamp,
    Expression<String>? action,
    Expression<String>? previous,
    Expression<String>? next,
    Expression<String>? actor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (timestamp != null) 'timestamp': timestamp,
      if (action != null) 'action': action,
      if (previous != null) 'previous': previous,
      if (next != null) 'next': next,
      if (actor != null) 'actor': actor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectLogsCompanion copyWith({
    Value<String>? id,
    Value<String?>? projectId,
    Value<DateTime>? timestamp,
    Value<String>? action,
    Value<String?>? previous,
    Value<String?>? next,
    Value<String?>? actor,
    Value<int>? rowid,
  }) {
    return ProjectLogsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      actor: actor ?? this.actor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (previous.present) {
      map['previous'] = Variable<String>(previous.value);
    }
    if (next.present) {
      map['next'] = Variable<String>(next.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectLogsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('previous: $previous, ')
          ..write('next: $next, ')
          ..write('actor: $actor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MilestoneLogsTable extends MilestoneLogs
    with TableInfo<$MilestoneLogsTable, MilestoneLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MilestoneLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _milestoneIdMeta = const VerificationMeta(
    'milestoneId',
  );
  @override
  late final GeneratedColumn<String> milestoneId = GeneratedColumn<String>(
    'milestone_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousMeta = const VerificationMeta(
    'previous',
  );
  @override
  late final GeneratedColumn<String> previous = GeneratedColumn<String>(
    'previous',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextMeta = const VerificationMeta('next');
  @override
  late final GeneratedColumn<String> next = GeneratedColumn<String>(
    'next',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    milestoneId,
    timestamp,
    action,
    previous,
    next,
    actor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'milestone_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MilestoneLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('milestone_id')) {
      context.handle(
        _milestoneIdMeta,
        milestoneId.isAcceptableOrUnknown(
          data['milestone_id']!,
          _milestoneIdMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('previous')) {
      context.handle(
        _previousMeta,
        previous.isAcceptableOrUnknown(data['previous']!, _previousMeta),
      );
    }
    if (data.containsKey('next')) {
      context.handle(
        _nextMeta,
        next.isAcceptableOrUnknown(data['next']!, _nextMeta),
      );
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MilestoneLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MilestoneLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      milestoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestone_id'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      previous: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous'],
      ),
      next: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next'],
      ),
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      ),
    );
  }

  @override
  $MilestoneLogsTable createAlias(String alias) {
    return $MilestoneLogsTable(attachedDatabase, alias);
  }
}

class MilestoneLog extends DataClass implements Insertable<MilestoneLog> {
  final String id;
  final String? milestoneId;
  final DateTime timestamp;
  final String action;
  final String? previous;
  final String? next;
  final String? actor;
  const MilestoneLog({
    required this.id,
    this.milestoneId,
    required this.timestamp,
    required this.action,
    this.previous,
    this.next,
    this.actor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || milestoneId != null) {
      map['milestone_id'] = Variable<String>(milestoneId);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || previous != null) {
      map['previous'] = Variable<String>(previous);
    }
    if (!nullToAbsent || next != null) {
      map['next'] = Variable<String>(next);
    }
    if (!nullToAbsent || actor != null) {
      map['actor'] = Variable<String>(actor);
    }
    return map;
  }

  MilestoneLogsCompanion toCompanion(bool nullToAbsent) {
    return MilestoneLogsCompanion(
      id: Value(id),
      milestoneId: milestoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(milestoneId),
      timestamp: Value(timestamp),
      action: Value(action),
      previous: previous == null && nullToAbsent
          ? const Value.absent()
          : Value(previous),
      next: next == null && nullToAbsent ? const Value.absent() : Value(next),
      actor: actor == null && nullToAbsent
          ? const Value.absent()
          : Value(actor),
    );
  }

  factory MilestoneLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MilestoneLog(
      id: serializer.fromJson<String>(json['id']),
      milestoneId: serializer.fromJson<String?>(json['milestoneId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      action: serializer.fromJson<String>(json['action']),
      previous: serializer.fromJson<String?>(json['previous']),
      next: serializer.fromJson<String?>(json['next']),
      actor: serializer.fromJson<String?>(json['actor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'milestoneId': serializer.toJson<String?>(milestoneId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'action': serializer.toJson<String>(action),
      'previous': serializer.toJson<String?>(previous),
      'next': serializer.toJson<String?>(next),
      'actor': serializer.toJson<String?>(actor),
    };
  }

  MilestoneLog copyWith({
    String? id,
    Value<String?> milestoneId = const Value.absent(),
    DateTime? timestamp,
    String? action,
    Value<String?> previous = const Value.absent(),
    Value<String?> next = const Value.absent(),
    Value<String?> actor = const Value.absent(),
  }) => MilestoneLog(
    id: id ?? this.id,
    milestoneId: milestoneId.present ? milestoneId.value : this.milestoneId,
    timestamp: timestamp ?? this.timestamp,
    action: action ?? this.action,
    previous: previous.present ? previous.value : this.previous,
    next: next.present ? next.value : this.next,
    actor: actor.present ? actor.value : this.actor,
  );
  MilestoneLog copyWithCompanion(MilestoneLogsCompanion data) {
    return MilestoneLog(
      id: data.id.present ? data.id.value : this.id,
      milestoneId: data.milestoneId.present
          ? data.milestoneId.value
          : this.milestoneId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      action: data.action.present ? data.action.value : this.action,
      previous: data.previous.present ? data.previous.value : this.previous,
      next: data.next.present ? data.next.value : this.next,
      actor: data.actor.present ? data.actor.value : this.actor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MilestoneLog(')
          ..write('id: $id, ')
          ..write('milestoneId: $milestoneId, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('previous: $previous, ')
          ..write('next: $next, ')
          ..write('actor: $actor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, milestoneId, timestamp, action, previous, next, actor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MilestoneLog &&
          other.id == this.id &&
          other.milestoneId == this.milestoneId &&
          other.timestamp == this.timestamp &&
          other.action == this.action &&
          other.previous == this.previous &&
          other.next == this.next &&
          other.actor == this.actor);
}

class MilestoneLogsCompanion extends UpdateCompanion<MilestoneLog> {
  final Value<String> id;
  final Value<String?> milestoneId;
  final Value<DateTime> timestamp;
  final Value<String> action;
  final Value<String?> previous;
  final Value<String?> next;
  final Value<String?> actor;
  final Value<int> rowid;
  const MilestoneLogsCompanion({
    this.id = const Value.absent(),
    this.milestoneId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.action = const Value.absent(),
    this.previous = const Value.absent(),
    this.next = const Value.absent(),
    this.actor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilestoneLogsCompanion.insert({
    required String id,
    this.milestoneId = const Value.absent(),
    required DateTime timestamp,
    required String action,
    this.previous = const Value.absent(),
    this.next = const Value.absent(),
    this.actor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       action = Value(action);
  static Insertable<MilestoneLog> custom({
    Expression<String>? id,
    Expression<String>? milestoneId,
    Expression<DateTime>? timestamp,
    Expression<String>? action,
    Expression<String>? previous,
    Expression<String>? next,
    Expression<String>? actor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (milestoneId != null) 'milestone_id': milestoneId,
      if (timestamp != null) 'timestamp': timestamp,
      if (action != null) 'action': action,
      if (previous != null) 'previous': previous,
      if (next != null) 'next': next,
      if (actor != null) 'actor': actor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilestoneLogsCompanion copyWith({
    Value<String>? id,
    Value<String?>? milestoneId,
    Value<DateTime>? timestamp,
    Value<String>? action,
    Value<String?>? previous,
    Value<String?>? next,
    Value<String?>? actor,
    Value<int>? rowid,
  }) {
    return MilestoneLogsCompanion(
      id: id ?? this.id,
      milestoneId: milestoneId ?? this.milestoneId,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      actor: actor ?? this.actor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (milestoneId.present) {
      map['milestone_id'] = Variable<String>(milestoneId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (previous.present) {
      map['previous'] = Variable<String>(previous.value);
    }
    if (next.present) {
      map['next'] = Variable<String>(next.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilestoneLogsCompanion(')
          ..write('id: $id, ')
          ..write('milestoneId: $milestoneId, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('previous: $previous, ')
          ..write('next: $next, ')
          ..write('actor: $actor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindIndexMeta = const VerificationMeta(
    'kindIndex',
  );
  @override
  late final GeneratedColumn<int> kindIndex = GeneratedColumn<int>(
    'kind_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, String>, String>
  localizedLabelsJson =
      GeneratedColumn<String>(
        'localized_labels_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Map<String, String>>(
        $TagsTable.$converterlocalizedLabelsJson,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slug,
    kindIndex,
    localizedLabelsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('kind_index')) {
      context.handle(
        _kindIndexMeta,
        kindIndex.isAcceptableOrUnknown(data['kind_index']!, _kindIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_kindIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {slug},
  ];
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      kindIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind_index'],
      )!,
      localizedLabelsJson: $TagsTable.$converterlocalizedLabelsJson.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}localized_labels_json'],
        )!,
      ),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, String>, String>
  $converterlocalizedLabelsJson = const MapStringStringTypeConverter();
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String slug;
  final int kindIndex;
  final Map<String, String> localizedLabelsJson;
  const Tag({
    required this.id,
    required this.slug,
    required this.kindIndex,
    required this.localizedLabelsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slug'] = Variable<String>(slug);
    map['kind_index'] = Variable<int>(kindIndex);
    {
      map['localized_labels_json'] = Variable<String>(
        $TagsTable.$converterlocalizedLabelsJson.toSql(localizedLabelsJson),
      );
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      slug: Value(slug),
      kindIndex: Value(kindIndex),
      localizedLabelsJson: Value(localizedLabelsJson),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      kindIndex: serializer.fromJson<int>(json['kindIndex']),
      localizedLabelsJson: serializer.fromJson<Map<String, String>>(
        json['localizedLabelsJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slug': serializer.toJson<String>(slug),
      'kindIndex': serializer.toJson<int>(kindIndex),
      'localizedLabelsJson': serializer.toJson<Map<String, String>>(
        localizedLabelsJson,
      ),
    };
  }

  Tag copyWith({
    String? id,
    String? slug,
    int? kindIndex,
    Map<String, String>? localizedLabelsJson,
  }) => Tag(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    kindIndex: kindIndex ?? this.kindIndex,
    localizedLabelsJson: localizedLabelsJson ?? this.localizedLabelsJson,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      kindIndex: data.kindIndex.present ? data.kindIndex.value : this.kindIndex,
      localizedLabelsJson: data.localizedLabelsJson.present
          ? data.localizedLabelsJson.value
          : this.localizedLabelsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('kindIndex: $kindIndex, ')
          ..write('localizedLabelsJson: $localizedLabelsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug, kindIndex, localizedLabelsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.kindIndex == this.kindIndex &&
          other.localizedLabelsJson == this.localizedLabelsJson);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> slug;
  final Value<int> kindIndex;
  final Value<Map<String, String>> localizedLabelsJson;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.kindIndex = const Value.absent(),
    this.localizedLabelsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String slug,
    required int kindIndex,
    required Map<String, String> localizedLabelsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slug = Value(slug),
       kindIndex = Value(kindIndex),
       localizedLabelsJson = Value(localizedLabelsJson);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? slug,
    Expression<int>? kindIndex,
    Expression<String>? localizedLabelsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (kindIndex != null) 'kind_index': kindIndex,
      if (localizedLabelsJson != null)
        'localized_labels_json': localizedLabelsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? slug,
    Value<int>? kindIndex,
    Value<Map<String, String>>? localizedLabelsJson,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      kindIndex: kindIndex ?? this.kindIndex,
      localizedLabelsJson: localizedLabelsJson ?? this.localizedLabelsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (kindIndex.present) {
      map['kind_index'] = Variable<int>(kindIndex.value);
    }
    if (localizedLabelsJson.present) {
      map['localized_labels_json'] = Variable<String>(
        $TagsTable.$converterlocalizedLabelsJson.toSql(
          localizedLabelsJson.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('kindIndex: $kindIndex, ')
          ..write('localizedLabelsJson: $localizedLabelsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTemplatesTable extends TaskTemplates
    with TableInfo<$TaskTemplatesTable, TaskTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  @override
  late final GeneratedColumn<String> parentTaskId = GeneratedColumn<String>(
    'parent_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  defaultTags = GeneratedColumn<String>(
    'default_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($TaskTemplatesTable.$converterdefaultTags);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seedSlugMeta = const VerificationMeta(
    'seedSlug',
  );
  @override
  late final GeneratedColumn<String> seedSlug = GeneratedColumn<String>(
    'seed_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suggestedEstimateMinutesMeta =
      const VerificationMeta('suggestedEstimateMinutes');
  @override
  late final GeneratedColumn<int> suggestedEstimateMinutes =
      GeneratedColumn<int>(
        'suggested_estimate_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    parentTaskId,
    defaultTags,
    createdAt,
    updatedAt,
    lastUsedAt,
    seedSlug,
    suggestedEstimateMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('parent_task_id')) {
      context.handle(
        _parentTaskIdMeta,
        parentTaskId.isAcceptableOrUnknown(
          data['parent_task_id']!,
          _parentTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('seed_slug')) {
      context.handle(
        _seedSlugMeta,
        seedSlug.isAcceptableOrUnknown(data['seed_slug']!, _seedSlugMeta),
      );
    }
    if (data.containsKey('suggested_estimate_minutes')) {
      context.handle(
        _suggestedEstimateMinutesMeta,
        suggestedEstimateMinutes.isAcceptableOrUnknown(
          data['suggested_estimate_minutes']!,
          _suggestedEstimateMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      defaultTags: $TaskTemplatesTable.$converterdefaultTags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}default_tags'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
      seedSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_slug'],
      ),
      suggestedEstimateMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}suggested_estimate_minutes'],
      ),
    );
  }

  @override
  $TaskTemplatesTable createAlias(String alias) {
    return $TaskTemplatesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterdefaultTags =
      const ListStringTypeConverter();
}

class TaskTemplate extends DataClass implements Insertable<TaskTemplate> {
  final String id;
  final String title;
  final String? parentTaskId;
  final List<String> defaultTags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final String? seedSlug;
  final int? suggestedEstimateMinutes;
  const TaskTemplate({
    required this.id,
    required this.title,
    this.parentTaskId,
    required this.defaultTags,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.seedSlug,
    this.suggestedEstimateMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    {
      map['default_tags'] = Variable<String>(
        $TaskTemplatesTable.$converterdefaultTags.toSql(defaultTags),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    if (!nullToAbsent || seedSlug != null) {
      map['seed_slug'] = Variable<String>(seedSlug);
    }
    if (!nullToAbsent || suggestedEstimateMinutes != null) {
      map['suggested_estimate_minutes'] = Variable<int>(
        suggestedEstimateMinutes,
      );
    }
    return map;
  }

  TaskTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TaskTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      defaultTags: Value(defaultTags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      seedSlug: seedSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(seedSlug),
      suggestedEstimateMinutes: suggestedEstimateMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedEstimateMinutes),
    );
  }

  factory TaskTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTemplate(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      parentTaskId: serializer.fromJson<String?>(json['parentTaskId']),
      defaultTags: serializer.fromJson<List<String>>(json['defaultTags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      seedSlug: serializer.fromJson<String?>(json['seedSlug']),
      suggestedEstimateMinutes: serializer.fromJson<int?>(
        json['suggestedEstimateMinutes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'parentTaskId': serializer.toJson<String?>(parentTaskId),
      'defaultTags': serializer.toJson<List<String>>(defaultTags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'seedSlug': serializer.toJson<String?>(seedSlug),
      'suggestedEstimateMinutes': serializer.toJson<int?>(
        suggestedEstimateMinutes,
      ),
    };
  }

  TaskTemplate copyWith({
    String? id,
    String? title,
    Value<String?> parentTaskId = const Value.absent(),
    List<String>? defaultTags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastUsedAt = const Value.absent(),
    Value<String?> seedSlug = const Value.absent(),
    Value<int?> suggestedEstimateMinutes = const Value.absent(),
  }) => TaskTemplate(
    id: id ?? this.id,
    title: title ?? this.title,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    defaultTags: defaultTags ?? this.defaultTags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    seedSlug: seedSlug.present ? seedSlug.value : this.seedSlug,
    suggestedEstimateMinutes: suggestedEstimateMinutes.present
        ? suggestedEstimateMinutes.value
        : this.suggestedEstimateMinutes,
  );
  TaskTemplate copyWithCompanion(TaskTemplatesCompanion data) {
    return TaskTemplate(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      defaultTags: data.defaultTags.present
          ? data.defaultTags.value
          : this.defaultTags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      seedSlug: data.seedSlug.present ? data.seedSlug.value : this.seedSlug,
      suggestedEstimateMinutes: data.suggestedEstimateMinutes.present
          ? data.suggestedEstimateMinutes.value
          : this.suggestedEstimateMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplate(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('defaultTags: $defaultTags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('suggestedEstimateMinutes: $suggestedEstimateMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    parentTaskId,
    defaultTags,
    createdAt,
    updatedAt,
    lastUsedAt,
    seedSlug,
    suggestedEstimateMinutes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTemplate &&
          other.id == this.id &&
          other.title == this.title &&
          other.parentTaskId == this.parentTaskId &&
          other.defaultTags == this.defaultTags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastUsedAt == this.lastUsedAt &&
          other.seedSlug == this.seedSlug &&
          other.suggestedEstimateMinutes == this.suggestedEstimateMinutes);
}

class TaskTemplatesCompanion extends UpdateCompanion<TaskTemplate> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> parentTaskId;
  final Value<List<String>> defaultTags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastUsedAt;
  final Value<String?> seedSlug;
  final Value<int?> suggestedEstimateMinutes;
  final Value<int> rowid;
  const TaskTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.defaultTags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.seedSlug = const Value.absent(),
    this.suggestedEstimateMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTemplatesCompanion.insert({
    required String id,
    required String title,
    this.parentTaskId = const Value.absent(),
    required List<String> defaultTags,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastUsedAt = const Value.absent(),
    this.seedSlug = const Value.absent(),
    this.suggestedEstimateMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       defaultTags = Value(defaultTags),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskTemplate> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? parentTaskId,
    Expression<String>? defaultTags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastUsedAt,
    Expression<String>? seedSlug,
    Expression<int>? suggestedEstimateMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (defaultTags != null) 'default_tags': defaultTags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (seedSlug != null) 'seed_slug': seedSlug,
      if (suggestedEstimateMinutes != null)
        'suggested_estimate_minutes': suggestedEstimateMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? parentTaskId,
    Value<List<String>>? defaultTags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastUsedAt,
    Value<String?>? seedSlug,
    Value<int?>? suggestedEstimateMinutes,
    Value<int>? rowid,
  }) {
    return TaskTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      defaultTags: defaultTags ?? this.defaultTags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      seedSlug: seedSlug ?? this.seedSlug,
      suggestedEstimateMinutes:
          suggestedEstimateMinutes ?? this.suggestedEstimateMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
    }
    if (defaultTags.present) {
      map['default_tags'] = Variable<String>(
        $TaskTemplatesTable.$converterdefaultTags.toSql(defaultTags.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (seedSlug.present) {
      map['seed_slug'] = Variable<String>(seedSlug.value);
    }
    if (suggestedEstimateMinutes.present) {
      map['suggested_estimate_minutes'] = Variable<int>(
        suggestedEstimateMinutes.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('defaultTags: $defaultTags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('seedSlug: $seedSlug, ')
          ..write('suggestedEstimateMinutes: $suggestedEstimateMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMinutesMeta = const VerificationMeta(
    'actualMinutes',
  );
  @override
  late final GeneratedColumn<int> actualMinutes = GeneratedColumn<int>(
    'actual_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimateMinutesMeta = const VerificationMeta(
    'estimateMinutes',
  );
  @override
  late final GeneratedColumn<int> estimateMinutes = GeneratedColumn<int>(
    'estimate_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmEnabledMeta = const VerificationMeta(
    'alarmEnabled',
  );
  @override
  late final GeneratedColumn<bool> alarmEnabled = GeneratedColumn<bool>(
    'alarm_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alarm_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _transferredToTaskIdMeta =
      const VerificationMeta('transferredToTaskId');
  @override
  late final GeneratedColumn<String> transferredToTaskId =
      GeneratedColumn<String>(
        'transferred_to_task_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reflectionNoteMeta = const VerificationMeta(
    'reflectionNote',
  );
  @override
  late final GeneratedColumn<String> reflectionNote = GeneratedColumn<String>(
    'reflection_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    startedAt,
    endedAt,
    actualMinutes,
    estimateMinutes,
    alarmEnabled,
    transferredToTaskId,
    reflectionNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('actual_minutes')) {
      context.handle(
        _actualMinutesMeta,
        actualMinutes.isAcceptableOrUnknown(
          data['actual_minutes']!,
          _actualMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualMinutesMeta);
    }
    if (data.containsKey('estimate_minutes')) {
      context.handle(
        _estimateMinutesMeta,
        estimateMinutes.isAcceptableOrUnknown(
          data['estimate_minutes']!,
          _estimateMinutesMeta,
        ),
      );
    }
    if (data.containsKey('alarm_enabled')) {
      context.handle(
        _alarmEnabledMeta,
        alarmEnabled.isAcceptableOrUnknown(
          data['alarm_enabled']!,
          _alarmEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_alarmEnabledMeta);
    }
    if (data.containsKey('transferred_to_task_id')) {
      context.handle(
        _transferredToTaskIdMeta,
        transferredToTaskId.isAcceptableOrUnknown(
          data['transferred_to_task_id']!,
          _transferredToTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('reflection_note')) {
      context.handle(
        _reflectionNoteMeta,
        reflectionNote.isAcceptableOrUnknown(
          data['reflection_note']!,
          _reflectionNoteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      actualMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minutes'],
      )!,
      estimateMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_minutes'],
      ),
      alarmEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alarm_enabled'],
      )!,
      transferredToTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transferred_to_task_id'],
      ),
      reflectionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reflection_note'],
      ),
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }
}

class FocusSession extends DataClass implements Insertable<FocusSession> {
  final String id;
  final String? taskId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int actualMinutes;
  final int? estimateMinutes;
  final bool alarmEnabled;
  final String? transferredToTaskId;
  final String? reflectionNote;
  const FocusSession({
    required this.id,
    this.taskId,
    required this.startedAt,
    this.endedAt,
    required this.actualMinutes,
    this.estimateMinutes,
    required this.alarmEnabled,
    this.transferredToTaskId,
    this.reflectionNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['actual_minutes'] = Variable<int>(actualMinutes);
    if (!nullToAbsent || estimateMinutes != null) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes);
    }
    map['alarm_enabled'] = Variable<bool>(alarmEnabled);
    if (!nullToAbsent || transferredToTaskId != null) {
      map['transferred_to_task_id'] = Variable<String>(transferredToTaskId);
    }
    if (!nullToAbsent || reflectionNote != null) {
      map['reflection_note'] = Variable<String>(reflectionNote);
    }
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      actualMinutes: Value(actualMinutes),
      estimateMinutes: estimateMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateMinutes),
      alarmEnabled: Value(alarmEnabled),
      transferredToTaskId: transferredToTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferredToTaskId),
      reflectionNote: reflectionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(reflectionNote),
    );
  }

  factory FocusSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSession(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      actualMinutes: serializer.fromJson<int>(json['actualMinutes']),
      estimateMinutes: serializer.fromJson<int?>(json['estimateMinutes']),
      alarmEnabled: serializer.fromJson<bool>(json['alarmEnabled']),
      transferredToTaskId: serializer.fromJson<String?>(
        json['transferredToTaskId'],
      ),
      reflectionNote: serializer.fromJson<String?>(json['reflectionNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String?>(taskId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'actualMinutes': serializer.toJson<int>(actualMinutes),
      'estimateMinutes': serializer.toJson<int?>(estimateMinutes),
      'alarmEnabled': serializer.toJson<bool>(alarmEnabled),
      'transferredToTaskId': serializer.toJson<String?>(transferredToTaskId),
      'reflectionNote': serializer.toJson<String?>(reflectionNote),
    };
  }

  FocusSession copyWith({
    String? id,
    Value<String?> taskId = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? actualMinutes,
    Value<int?> estimateMinutes = const Value.absent(),
    bool? alarmEnabled,
    Value<String?> transferredToTaskId = const Value.absent(),
    Value<String?> reflectionNote = const Value.absent(),
  }) => FocusSession(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    actualMinutes: actualMinutes ?? this.actualMinutes,
    estimateMinutes: estimateMinutes.present
        ? estimateMinutes.value
        : this.estimateMinutes,
    alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    transferredToTaskId: transferredToTaskId.present
        ? transferredToTaskId.value
        : this.transferredToTaskId,
    reflectionNote: reflectionNote.present
        ? reflectionNote.value
        : this.reflectionNote,
  );
  FocusSession copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSession(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      actualMinutes: data.actualMinutes.present
          ? data.actualMinutes.value
          : this.actualMinutes,
      estimateMinutes: data.estimateMinutes.present
          ? data.estimateMinutes.value
          : this.estimateMinutes,
      alarmEnabled: data.alarmEnabled.present
          ? data.alarmEnabled.value
          : this.alarmEnabled,
      transferredToTaskId: data.transferredToTaskId.present
          ? data.transferredToTaskId.value
          : this.transferredToTaskId,
      reflectionNote: data.reflectionNote.present
          ? data.reflectionNote.value
          : this.reflectionNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSession(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('transferredToTaskId: $transferredToTaskId, ')
          ..write('reflectionNote: $reflectionNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    startedAt,
    endedAt,
    actualMinutes,
    estimateMinutes,
    alarmEnabled,
    transferredToTaskId,
    reflectionNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSession &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.actualMinutes == this.actualMinutes &&
          other.estimateMinutes == this.estimateMinutes &&
          other.alarmEnabled == this.alarmEnabled &&
          other.transferredToTaskId == this.transferredToTaskId &&
          other.reflectionNote == this.reflectionNote);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSession> {
  final Value<String> id;
  final Value<String?> taskId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> actualMinutes;
  final Value<int?> estimateMinutes;
  final Value<bool> alarmEnabled;
  final Value<String?> transferredToTaskId;
  final Value<String?> reflectionNote;
  final Value<int> rowid;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.estimateMinutes = const Value.absent(),
    this.alarmEnabled = const Value.absent(),
    this.transferredToTaskId = const Value.absent(),
    this.reflectionNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    required String id,
    this.taskId = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required int actualMinutes,
    this.estimateMinutes = const Value.absent(),
    required bool alarmEnabled,
    this.transferredToTaskId = const Value.absent(),
    this.reflectionNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       actualMinutes = Value(actualMinutes),
       alarmEnabled = Value(alarmEnabled);
  static Insertable<FocusSession> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? actualMinutes,
    Expression<int>? estimateMinutes,
    Expression<bool>? alarmEnabled,
    Expression<String>? transferredToTaskId,
    Expression<String>? reflectionNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
      if (estimateMinutes != null) 'estimate_minutes': estimateMinutes,
      if (alarmEnabled != null) 'alarm_enabled': alarmEnabled,
      if (transferredToTaskId != null)
        'transferred_to_task_id': transferredToTaskId,
      if (reflectionNote != null) 'reflection_note': reflectionNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? taskId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? actualMinutes,
    Value<int?>? estimateMinutes,
    Value<bool>? alarmEnabled,
    Value<String?>? transferredToTaskId,
    Value<String?>? reflectionNote,
    Value<int>? rowid,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      transferredToTaskId: transferredToTaskId ?? this.transferredToTaskId,
      reflectionNote: reflectionNote ?? this.reflectionNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (actualMinutes.present) {
      map['actual_minutes'] = Variable<int>(actualMinutes.value);
    }
    if (estimateMinutes.present) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes.value);
    }
    if (alarmEnabled.present) {
      map['alarm_enabled'] = Variable<bool>(alarmEnabled.value);
    }
    if (transferredToTaskId.present) {
      map['transferred_to_task_id'] = Variable<String>(
        transferredToTaskId.value,
      );
    }
    if (reflectionNote.present) {
      map['reflection_note'] = Variable<String>(reflectionNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('alarmEnabled: $alarmEnabled, ')
          ..write('transferredToTaskId: $transferredToTaskId, ')
          ..write('reflectionNote: $reflectionNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _localeCodeMeta = const VerificationMeta(
    'localeCode',
  );
  @override
  late final GeneratedColumn<String> localeCode = GeneratedColumn<String>(
    'locale_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeModeIndexMeta = const VerificationMeta(
    'themeModeIndex',
  );
  @override
  late final GeneratedColumn<int> themeModeIndex = GeneratedColumn<int>(
    'theme_mode_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fontScaleLevelMeta = const VerificationMeta(
    'fontScaleLevel',
  );
  @override
  late final GeneratedColumn<String> fontScaleLevel = GeneratedColumn<String>(
    'font_scale_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clockTickSoundEnabledMeta =
      const VerificationMeta('clockTickSoundEnabled');
  @override
  late final GeneratedColumn<bool> clockTickSoundEnabled =
      GeneratedColumn<bool>(
        'clock_tick_sound_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("clock_tick_sound_enabled" IN (0, 1))',
        ),
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localeCode,
    themeModeIndex,
    fontScaleLevel,
    clockTickSoundEnabled,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('locale_code')) {
      context.handle(
        _localeCodeMeta,
        localeCode.isAcceptableOrUnknown(data['locale_code']!, _localeCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeCodeMeta);
    }
    if (data.containsKey('theme_mode_index')) {
      context.handle(
        _themeModeIndexMeta,
        themeModeIndex.isAcceptableOrUnknown(
          data['theme_mode_index']!,
          _themeModeIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_themeModeIndexMeta);
    }
    if (data.containsKey('font_scale_level')) {
      context.handle(
        _fontScaleLevelMeta,
        fontScaleLevel.isAcceptableOrUnknown(
          data['font_scale_level']!,
          _fontScaleLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fontScaleLevelMeta);
    }
    if (data.containsKey('clock_tick_sound_enabled')) {
      context.handle(
        _clockTickSoundEnabledMeta,
        clockTickSoundEnabled.isAcceptableOrUnknown(
          data['clock_tick_sound_enabled']!,
          _clockTickSoundEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clockTickSoundEnabledMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_code'],
      )!,
      themeModeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}theme_mode_index'],
      )!,
      fontScaleLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_scale_level'],
      )!,
      clockTickSoundEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}clock_tick_sound_enabled'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String id;
  final String localeCode;
  final int themeModeIndex;
  final String fontScaleLevel;
  final bool clockTickSoundEnabled;
  final DateTime updatedAt;
  const Preference({
    required this.id,
    required this.localeCode,
    required this.themeModeIndex,
    required this.fontScaleLevel,
    required this.clockTickSoundEnabled,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['locale_code'] = Variable<String>(localeCode);
    map['theme_mode_index'] = Variable<int>(themeModeIndex);
    map['font_scale_level'] = Variable<String>(fontScaleLevel);
    map['clock_tick_sound_enabled'] = Variable<bool>(clockTickSoundEnabled);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      id: Value(id),
      localeCode: Value(localeCode),
      themeModeIndex: Value(themeModeIndex),
      fontScaleLevel: Value(fontScaleLevel),
      clockTickSoundEnabled: Value(clockTickSoundEnabled),
      updatedAt: Value(updatedAt),
    );
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      id: serializer.fromJson<String>(json['id']),
      localeCode: serializer.fromJson<String>(json['localeCode']),
      themeModeIndex: serializer.fromJson<int>(json['themeModeIndex']),
      fontScaleLevel: serializer.fromJson<String>(json['fontScaleLevel']),
      clockTickSoundEnabled: serializer.fromJson<bool>(
        json['clockTickSoundEnabled'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localeCode': serializer.toJson<String>(localeCode),
      'themeModeIndex': serializer.toJson<int>(themeModeIndex),
      'fontScaleLevel': serializer.toJson<String>(fontScaleLevel),
      'clockTickSoundEnabled': serializer.toJson<bool>(clockTickSoundEnabled),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Preference copyWith({
    String? id,
    String? localeCode,
    int? themeModeIndex,
    String? fontScaleLevel,
    bool? clockTickSoundEnabled,
    DateTime? updatedAt,
  }) => Preference(
    id: id ?? this.id,
    localeCode: localeCode ?? this.localeCode,
    themeModeIndex: themeModeIndex ?? this.themeModeIndex,
    fontScaleLevel: fontScaleLevel ?? this.fontScaleLevel,
    clockTickSoundEnabled: clockTickSoundEnabled ?? this.clockTickSoundEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      id: data.id.present ? data.id.value : this.id,
      localeCode: data.localeCode.present
          ? data.localeCode.value
          : this.localeCode,
      themeModeIndex: data.themeModeIndex.present
          ? data.themeModeIndex.value
          : this.themeModeIndex,
      fontScaleLevel: data.fontScaleLevel.present
          ? data.fontScaleLevel.value
          : this.fontScaleLevel,
      clockTickSoundEnabled: data.clockTickSoundEnabled.present
          ? data.clockTickSoundEnabled.value
          : this.clockTickSoundEnabled,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('id: $id, ')
          ..write('localeCode: $localeCode, ')
          ..write('themeModeIndex: $themeModeIndex, ')
          ..write('fontScaleLevel: $fontScaleLevel, ')
          ..write('clockTickSoundEnabled: $clockTickSoundEnabled, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localeCode,
    themeModeIndex,
    fontScaleLevel,
    clockTickSoundEnabled,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.id == this.id &&
          other.localeCode == this.localeCode &&
          other.themeModeIndex == this.themeModeIndex &&
          other.fontScaleLevel == this.fontScaleLevel &&
          other.clockTickSoundEnabled == this.clockTickSoundEnabled &&
          other.updatedAt == this.updatedAt);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> id;
  final Value<String> localeCode;
  final Value<int> themeModeIndex;
  final Value<String> fontScaleLevel;
  final Value<bool> clockTickSoundEnabled;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.id = const Value.absent(),
    this.localeCode = const Value.absent(),
    this.themeModeIndex = const Value.absent(),
    this.fontScaleLevel = const Value.absent(),
    this.clockTickSoundEnabled = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    this.id = const Value.absent(),
    required String localeCode,
    required int themeModeIndex,
    required String fontScaleLevel,
    required bool clockTickSoundEnabled,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localeCode = Value(localeCode),
       themeModeIndex = Value(themeModeIndex),
       fontScaleLevel = Value(fontScaleLevel),
       clockTickSoundEnabled = Value(clockTickSoundEnabled),
       updatedAt = Value(updatedAt);
  static Insertable<Preference> custom({
    Expression<String>? id,
    Expression<String>? localeCode,
    Expression<int>? themeModeIndex,
    Expression<String>? fontScaleLevel,
    Expression<bool>? clockTickSoundEnabled,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localeCode != null) 'locale_code': localeCode,
      if (themeModeIndex != null) 'theme_mode_index': themeModeIndex,
      if (fontScaleLevel != null) 'font_scale_level': fontScaleLevel,
      if (clockTickSoundEnabled != null)
        'clock_tick_sound_enabled': clockTickSoundEnabled,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? localeCode,
    Value<int>? themeModeIndex,
    Value<String>? fontScaleLevel,
    Value<bool>? clockTickSoundEnabled,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      id: id ?? this.id,
      localeCode: localeCode ?? this.localeCode,
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      fontScaleLevel: fontScaleLevel ?? this.fontScaleLevel,
      clockTickSoundEnabled:
          clockTickSoundEnabled ?? this.clockTickSoundEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localeCode.present) {
      map['locale_code'] = Variable<String>(localeCode.value);
    }
    if (themeModeIndex.present) {
      map['theme_mode_index'] = Variable<int>(themeModeIndex.value);
    }
    if (fontScaleLevel.present) {
      map['font_scale_level'] = Variable<String>(fontScaleLevel.value);
    }
    if (clockTickSoundEnabled.present) {
      map['clock_tick_sound_enabled'] = Variable<bool>(
        clockTickSoundEnabled.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('id: $id, ')
          ..write('localeCode: $localeCode, ')
          ..write('themeModeIndex: $themeModeIndex, ')
          ..write('fontScaleLevel: $fontScaleLevel, ')
          ..write('clockTickSoundEnabled: $clockTickSoundEnabled, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeedImportLogsTable extends SeedImportLogs
    with TableInfo<$SeedImportLogsTable, SeedImportLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeedImportLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, importedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seed_import_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeedImportLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeedImportLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeedImportLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $SeedImportLogsTable createAlias(String alias) {
    return $SeedImportLogsTable(attachedDatabase, alias);
  }
}

class SeedImportLog extends DataClass implements Insertable<SeedImportLog> {
  final String id;
  final String version;
  final DateTime importedAt;
  const SeedImportLog({
    required this.id,
    required this.version,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<String>(version);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  SeedImportLogsCompanion toCompanion(bool nullToAbsent) {
    return SeedImportLogsCompanion(
      id: Value(id),
      version: Value(version),
      importedAt: Value(importedAt),
    );
  }

  factory SeedImportLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeedImportLog(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<String>(json['version']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<String>(version),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  SeedImportLog copyWith({String? id, String? version, DateTime? importedAt}) =>
      SeedImportLog(
        id: id ?? this.id,
        version: version ?? this.version,
        importedAt: importedAt ?? this.importedAt,
      );
  SeedImportLog copyWithCompanion(SeedImportLogsCompanion data) {
    return SeedImportLog(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeedImportLog(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeedImportLog &&
          other.id == this.id &&
          other.version == this.version &&
          other.importedAt == this.importedAt);
}

class SeedImportLogsCompanion extends UpdateCompanion<SeedImportLog> {
  final Value<String> id;
  final Value<String> version;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const SeedImportLogsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeedImportLogsCompanion.insert({
    required String id,
    required String version,
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       importedAt = Value(importedAt);
  static Insertable<SeedImportLog> custom({
    Expression<String>? id,
    Expression<String>? version,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeedImportLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? version,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return SeedImportLogsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeedImportLogsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $MilestonesTable milestones = $MilestonesTable(this);
  late final $TaskLogsTable taskLogs = $TaskLogsTable(this);
  late final $ProjectLogsTable projectLogs = $ProjectLogsTable(this);
  late final $MilestoneLogsTable milestoneLogs = $MilestoneLogsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TaskTemplatesTable taskTemplates = $TaskTemplatesTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $SeedImportLogsTable seedImportLogs = $SeedImportLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    projects,
    milestones,
    taskLogs,
    projectLogs,
    milestoneLogs,
    tags,
    taskTemplates,
    focusSessions,
    preferences,
    seedImportLogs,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      required TaskStatus status,
      Value<DateTime?> dueAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime?> archivedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> parentId,
      Value<String?> projectId,
      Value<String?> milestoneId,
      required double sortIndex,
      required List<String> tags,
      required int templateLockCount,
      Value<String?> seedSlug,
      required bool allowInstantComplete,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<TaskStatus> status,
      Value<DateTime?> dueAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> parentId,
      Value<String?> projectId,
      Value<String?> milestoneId,
      Value<double> sortIndex,
      Value<List<String>> tags,
      Value<int> templateLockCount,
      Value<String?> seedSlug,
      Value<bool> allowInstantComplete,
      Value<String?> description,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, int> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seedSlug =>
      $composableBuilder(column: $table.seedSlug, builder: (column) => column);

  GeneratedColumn<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> milestoneId = const Value.absent(),
                Value<double> sortIndex = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<int> templateLockCount = const Value.absent(),
                Value<String?> seedSlug = const Value.absent(),
                Value<bool> allowInstantComplete = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                status: status,
                dueAt: dueAt,
                startedAt: startedAt,
                endedAt: endedAt,
                archivedAt: archivedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                parentId: parentId,
                projectId: projectId,
                milestoneId: milestoneId,
                sortIndex: sortIndex,
                tags: tags,
                templateLockCount: templateLockCount,
                seedSlug: seedSlug,
                allowInstantComplete: allowInstantComplete,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required TaskStatus status,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> parentId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> milestoneId = const Value.absent(),
                required double sortIndex,
                required List<String> tags,
                required int templateLockCount,
                Value<String?> seedSlug = const Value.absent(),
                required bool allowInstantComplete,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                status: status,
                dueAt: dueAt,
                startedAt: startedAt,
                endedAt: endedAt,
                archivedAt: archivedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                parentId: parentId,
                projectId: projectId,
                milestoneId: milestoneId,
                sortIndex: sortIndex,
                tags: tags,
                templateLockCount: templateLockCount,
                seedSlug: seedSlug,
                allowInstantComplete: allowInstantComplete,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      required String title,
      required TaskStatus status,
      Value<DateTime?> dueAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      required double sortIndex,
      required List<String> tags,
      required int templateLockCount,
      Value<String?> seedSlug,
      required bool allowInstantComplete,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<TaskStatus> status,
      Value<DateTime?> dueAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<double> sortIndex,
      Value<List<String>> tags,
      Value<int> templateLockCount,
      Value<String?> seedSlug,
      Value<bool> allowInstantComplete,
      Value<String?> description,
      Value<int> rowid,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, int> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seedSlug =>
      $composableBuilder(column: $table.seedSlug, builder: (column) => column);

  GeneratedColumn<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double> sortIndex = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<int> templateLockCount = const Value.absent(),
                Value<String?> seedSlug = const Value.absent(),
                Value<bool> allowInstantComplete = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                title: title,
                status: status,
                dueAt: dueAt,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortIndex: sortIndex,
                tags: tags,
                templateLockCount: templateLockCount,
                seedSlug: seedSlug,
                allowInstantComplete: allowInstantComplete,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required TaskStatus status,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required double sortIndex,
                required List<String> tags,
                required int templateLockCount,
                Value<String?> seedSlug = const Value.absent(),
                required bool allowInstantComplete,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                title: title,
                status: status,
                dueAt: dueAt,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortIndex: sortIndex,
                tags: tags,
                templateLockCount: templateLockCount,
                seedSlug: seedSlug,
                allowInstantComplete: allowInstantComplete,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$MilestonesTableCreateCompanionBuilder =
    MilestonesCompanion Function({
      required String id,
      Value<String?> projectId,
      required String title,
      required TaskStatus status,
      Value<DateTime?> dueAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      required double sortIndex,
      required List<String> tags,
      required int templateLockCount,
      Value<String?> seedSlug,
      required bool allowInstantComplete,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$MilestonesTableUpdateCompanionBuilder =
    MilestonesCompanion Function({
      Value<String> id,
      Value<String?> projectId,
      Value<String> title,
      Value<TaskStatus> status,
      Value<DateTime?> dueAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<double> sortIndex,
      Value<List<String>> tags,
      Value<int> templateLockCount,
      Value<String?> seedSlug,
      Value<bool> allowInstantComplete,
      Value<String?> description,
      Value<int> rowid,
    });

class $$MilestonesTableFilterComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, int> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MilestonesTableOrderingComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MilestonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get templateLockCount => $composableBuilder(
    column: $table.templateLockCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seedSlug =>
      $composableBuilder(column: $table.seedSlug, builder: (column) => column);

  GeneratedColumn<bool> get allowInstantComplete => $composableBuilder(
    column: $table.allowInstantComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$MilestonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MilestonesTable,
          Milestone,
          $$MilestonesTableFilterComposer,
          $$MilestonesTableOrderingComposer,
          $$MilestonesTableAnnotationComposer,
          $$MilestonesTableCreateCompanionBuilder,
          $$MilestonesTableUpdateCompanionBuilder,
          (
            Milestone,
            BaseReferences<_$AppDatabase, $MilestonesTable, Milestone>,
          ),
          Milestone,
          PrefetchHooks Function()
        > {
  $$MilestonesTableTableManager(_$AppDatabase db, $MilestonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double> sortIndex = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<int> templateLockCount = const Value.absent(),
                Value<String?> seedSlug = const Value.absent(),
                Value<bool> allowInstantComplete = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion(
                id: id,
                projectId: projectId,
                title: title,
                status: status,
                dueAt: dueAt,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortIndex: sortIndex,
                tags: tags,
                templateLockCount: templateLockCount,
                seedSlug: seedSlug,
                allowInstantComplete: allowInstantComplete,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> projectId = const Value.absent(),
                required String title,
                required TaskStatus status,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required double sortIndex,
                required List<String> tags,
                required int templateLockCount,
                Value<String?> seedSlug = const Value.absent(),
                required bool allowInstantComplete,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                status: status,
                dueAt: dueAt,
                startedAt: startedAt,
                endedAt: endedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortIndex: sortIndex,
                tags: tags,
                templateLockCount: templateLockCount,
                seedSlug: seedSlug,
                allowInstantComplete: allowInstantComplete,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MilestonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MilestonesTable,
      Milestone,
      $$MilestonesTableFilterComposer,
      $$MilestonesTableOrderingComposer,
      $$MilestonesTableAnnotationComposer,
      $$MilestonesTableCreateCompanionBuilder,
      $$MilestonesTableUpdateCompanionBuilder,
      (Milestone, BaseReferences<_$AppDatabase, $MilestonesTable, Milestone>),
      Milestone,
      PrefetchHooks Function()
    >;
typedef $$TaskLogsTableCreateCompanionBuilder =
    TaskLogsCompanion Function({
      required String id,
      Value<String?> taskId,
      required DateTime timestamp,
      required String action,
      Value<String?> previous,
      Value<String?> next,
      Value<String?> actor,
      Value<int> rowid,
    });
typedef $$TaskLogsTableUpdateCompanionBuilder =
    TaskLogsCompanion Function({
      Value<String> id,
      Value<String?> taskId,
      Value<DateTime> timestamp,
      Value<String> action,
      Value<String?> previous,
      Value<String?> next,
      Value<String?> actor,
      Value<int> rowid,
    });

class $$TaskLogsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskLogsTable> {
  $$TaskLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get next => $composableBuilder(
    column: $table.next,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskLogsTable> {
  $$TaskLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get next => $composableBuilder(
    column: $table.next,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskLogsTable> {
  $$TaskLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get previous =>
      $composableBuilder(column: $table.previous, builder: (column) => column);

  GeneratedColumn<String> get next =>
      $composableBuilder(column: $table.next, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);
}

class $$TaskLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskLogsTable,
          TaskLog,
          $$TaskLogsTableFilterComposer,
          $$TaskLogsTableOrderingComposer,
          $$TaskLogsTableAnnotationComposer,
          $$TaskLogsTableCreateCompanionBuilder,
          $$TaskLogsTableUpdateCompanionBuilder,
          (TaskLog, BaseReferences<_$AppDatabase, $TaskLogsTable, TaskLog>),
          TaskLog,
          PrefetchHooks Function()
        > {
  $$TaskLogsTableTableManager(_$AppDatabase db, $TaskLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> previous = const Value.absent(),
                Value<String?> next = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskLogsCompanion(
                id: id,
                taskId: taskId,
                timestamp: timestamp,
                action: action,
                previous: previous,
                next: next,
                actor: actor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> taskId = const Value.absent(),
                required DateTime timestamp,
                required String action,
                Value<String?> previous = const Value.absent(),
                Value<String?> next = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskLogsCompanion.insert(
                id: id,
                taskId: taskId,
                timestamp: timestamp,
                action: action,
                previous: previous,
                next: next,
                actor: actor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskLogsTable,
      TaskLog,
      $$TaskLogsTableFilterComposer,
      $$TaskLogsTableOrderingComposer,
      $$TaskLogsTableAnnotationComposer,
      $$TaskLogsTableCreateCompanionBuilder,
      $$TaskLogsTableUpdateCompanionBuilder,
      (TaskLog, BaseReferences<_$AppDatabase, $TaskLogsTable, TaskLog>),
      TaskLog,
      PrefetchHooks Function()
    >;
typedef $$ProjectLogsTableCreateCompanionBuilder =
    ProjectLogsCompanion Function({
      required String id,
      Value<String?> projectId,
      required DateTime timestamp,
      required String action,
      Value<String?> previous,
      Value<String?> next,
      Value<String?> actor,
      Value<int> rowid,
    });
typedef $$ProjectLogsTableUpdateCompanionBuilder =
    ProjectLogsCompanion Function({
      Value<String> id,
      Value<String?> projectId,
      Value<DateTime> timestamp,
      Value<String> action,
      Value<String?> previous,
      Value<String?> next,
      Value<String?> actor,
      Value<int> rowid,
    });

class $$ProjectLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectLogsTable> {
  $$ProjectLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get next => $composableBuilder(
    column: $table.next,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectLogsTable> {
  $$ProjectLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get next => $composableBuilder(
    column: $table.next,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectLogsTable> {
  $$ProjectLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get previous =>
      $composableBuilder(column: $table.previous, builder: (column) => column);

  GeneratedColumn<String> get next =>
      $composableBuilder(column: $table.next, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);
}

class $$ProjectLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectLogsTable,
          ProjectLog,
          $$ProjectLogsTableFilterComposer,
          $$ProjectLogsTableOrderingComposer,
          $$ProjectLogsTableAnnotationComposer,
          $$ProjectLogsTableCreateCompanionBuilder,
          $$ProjectLogsTableUpdateCompanionBuilder,
          (
            ProjectLog,
            BaseReferences<_$AppDatabase, $ProjectLogsTable, ProjectLog>,
          ),
          ProjectLog,
          PrefetchHooks Function()
        > {
  $$ProjectLogsTableTableManager(_$AppDatabase db, $ProjectLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> previous = const Value.absent(),
                Value<String?> next = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectLogsCompanion(
                id: id,
                projectId: projectId,
                timestamp: timestamp,
                action: action,
                previous: previous,
                next: next,
                actor: actor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> projectId = const Value.absent(),
                required DateTime timestamp,
                required String action,
                Value<String?> previous = const Value.absent(),
                Value<String?> next = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectLogsCompanion.insert(
                id: id,
                projectId: projectId,
                timestamp: timestamp,
                action: action,
                previous: previous,
                next: next,
                actor: actor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectLogsTable,
      ProjectLog,
      $$ProjectLogsTableFilterComposer,
      $$ProjectLogsTableOrderingComposer,
      $$ProjectLogsTableAnnotationComposer,
      $$ProjectLogsTableCreateCompanionBuilder,
      $$ProjectLogsTableUpdateCompanionBuilder,
      (
        ProjectLog,
        BaseReferences<_$AppDatabase, $ProjectLogsTable, ProjectLog>,
      ),
      ProjectLog,
      PrefetchHooks Function()
    >;
typedef $$MilestoneLogsTableCreateCompanionBuilder =
    MilestoneLogsCompanion Function({
      required String id,
      Value<String?> milestoneId,
      required DateTime timestamp,
      required String action,
      Value<String?> previous,
      Value<String?> next,
      Value<String?> actor,
      Value<int> rowid,
    });
typedef $$MilestoneLogsTableUpdateCompanionBuilder =
    MilestoneLogsCompanion Function({
      Value<String> id,
      Value<String?> milestoneId,
      Value<DateTime> timestamp,
      Value<String> action,
      Value<String?> previous,
      Value<String?> next,
      Value<String?> actor,
      Value<int> rowid,
    });

class $$MilestoneLogsTableFilterComposer
    extends Composer<_$AppDatabase, $MilestoneLogsTable> {
  $$MilestoneLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get next => $composableBuilder(
    column: $table.next,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MilestoneLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $MilestoneLogsTable> {
  $$MilestoneLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previous => $composableBuilder(
    column: $table.previous,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get next => $composableBuilder(
    column: $table.next,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MilestoneLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MilestoneLogsTable> {
  $$MilestoneLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get milestoneId => $composableBuilder(
    column: $table.milestoneId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get previous =>
      $composableBuilder(column: $table.previous, builder: (column) => column);

  GeneratedColumn<String> get next =>
      $composableBuilder(column: $table.next, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);
}

class $$MilestoneLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MilestoneLogsTable,
          MilestoneLog,
          $$MilestoneLogsTableFilterComposer,
          $$MilestoneLogsTableOrderingComposer,
          $$MilestoneLogsTableAnnotationComposer,
          $$MilestoneLogsTableCreateCompanionBuilder,
          $$MilestoneLogsTableUpdateCompanionBuilder,
          (
            MilestoneLog,
            BaseReferences<_$AppDatabase, $MilestoneLogsTable, MilestoneLog>,
          ),
          MilestoneLog,
          PrefetchHooks Function()
        > {
  $$MilestoneLogsTableTableManager(_$AppDatabase db, $MilestoneLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MilestoneLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MilestoneLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MilestoneLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> milestoneId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> previous = const Value.absent(),
                Value<String?> next = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestoneLogsCompanion(
                id: id,
                milestoneId: milestoneId,
                timestamp: timestamp,
                action: action,
                previous: previous,
                next: next,
                actor: actor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> milestoneId = const Value.absent(),
                required DateTime timestamp,
                required String action,
                Value<String?> previous = const Value.absent(),
                Value<String?> next = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestoneLogsCompanion.insert(
                id: id,
                milestoneId: milestoneId,
                timestamp: timestamp,
                action: action,
                previous: previous,
                next: next,
                actor: actor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MilestoneLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MilestoneLogsTable,
      MilestoneLog,
      $$MilestoneLogsTableFilterComposer,
      $$MilestoneLogsTableOrderingComposer,
      $$MilestoneLogsTableAnnotationComposer,
      $$MilestoneLogsTableCreateCompanionBuilder,
      $$MilestoneLogsTableUpdateCompanionBuilder,
      (
        MilestoneLog,
        BaseReferences<_$AppDatabase, $MilestoneLogsTable, MilestoneLog>,
      ),
      MilestoneLog,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String slug,
      required int kindIndex,
      required Map<String, String> localizedLabelsJson,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> slug,
      Value<int> kindIndex,
      Value<Map<String, String>> localizedLabelsJson,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kindIndex => $composableBuilder(
    column: $table.kindIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, String>,
    Map<String, String>,
    String
  >
  get localizedLabelsJson => $composableBuilder(
    column: $table.localizedLabelsJson,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kindIndex => $composableBuilder(
    column: $table.kindIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localizedLabelsJson => $composableBuilder(
    column: $table.localizedLabelsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<int> get kindIndex =>
      $composableBuilder(column: $table.kindIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, String>, String>
  get localizedLabelsJson => $composableBuilder(
    column: $table.localizedLabelsJson,
    builder: (column) => column,
  );
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<int> kindIndex = const Value.absent(),
                Value<Map<String, String>> localizedLabelsJson =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                slug: slug,
                kindIndex: kindIndex,
                localizedLabelsJson: localizedLabelsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String slug,
                required int kindIndex,
                required Map<String, String> localizedLabelsJson,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                slug: slug,
                kindIndex: kindIndex,
                localizedLabelsJson: localizedLabelsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$TaskTemplatesTableCreateCompanionBuilder =
    TaskTemplatesCompanion Function({
      required String id,
      required String title,
      Value<String?> parentTaskId,
      required List<String> defaultTags,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastUsedAt,
      Value<String?> seedSlug,
      Value<int?> suggestedEstimateMinutes,
      Value<int> rowid,
    });
typedef $$TaskTemplatesTableUpdateCompanionBuilder =
    TaskTemplatesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> parentTaskId,
      Value<List<String>> defaultTags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastUsedAt,
      Value<String?> seedSlug,
      Value<int?> suggestedEstimateMinutes,
      Value<int> rowid,
    });

class $$TaskTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get defaultTags => $composableBuilder(
    column: $table.defaultTags,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get suggestedEstimateMinutes => $composableBuilder(
    column: $table.suggestedEstimateMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultTags => $composableBuilder(
    column: $table.defaultTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedSlug => $composableBuilder(
    column: $table.seedSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get suggestedEstimateMinutes => $composableBuilder(
    column: $table.suggestedEstimateMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get defaultTags =>
      $composableBuilder(
        column: $table.defaultTags,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seedSlug =>
      $composableBuilder(column: $table.seedSlug, builder: (column) => column);

  GeneratedColumn<int> get suggestedEstimateMinutes => $composableBuilder(
    column: $table.suggestedEstimateMinutes,
    builder: (column) => column,
  );
}

class $$TaskTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTemplatesTable,
          TaskTemplate,
          $$TaskTemplatesTableFilterComposer,
          $$TaskTemplatesTableOrderingComposer,
          $$TaskTemplatesTableAnnotationComposer,
          $$TaskTemplatesTableCreateCompanionBuilder,
          $$TaskTemplatesTableUpdateCompanionBuilder,
          (
            TaskTemplate,
            BaseReferences<_$AppDatabase, $TaskTemplatesTable, TaskTemplate>,
          ),
          TaskTemplate,
          PrefetchHooks Function()
        > {
  $$TaskTemplatesTableTableManager(_$AppDatabase db, $TaskTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<List<String>> defaultTags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<String?> seedSlug = const Value.absent(),
                Value<int?> suggestedEstimateMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplatesCompanion(
                id: id,
                title: title,
                parentTaskId: parentTaskId,
                defaultTags: defaultTags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastUsedAt: lastUsedAt,
                seedSlug: seedSlug,
                suggestedEstimateMinutes: suggestedEstimateMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> parentTaskId = const Value.absent(),
                required List<String> defaultTags,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<String?> seedSlug = const Value.absent(),
                Value<int?> suggestedEstimateMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplatesCompanion.insert(
                id: id,
                title: title,
                parentTaskId: parentTaskId,
                defaultTags: defaultTags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastUsedAt: lastUsedAt,
                seedSlug: seedSlug,
                suggestedEstimateMinutes: suggestedEstimateMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTemplatesTable,
      TaskTemplate,
      $$TaskTemplatesTableFilterComposer,
      $$TaskTemplatesTableOrderingComposer,
      $$TaskTemplatesTableAnnotationComposer,
      $$TaskTemplatesTableCreateCompanionBuilder,
      $$TaskTemplatesTableUpdateCompanionBuilder,
      (
        TaskTemplate,
        BaseReferences<_$AppDatabase, $TaskTemplatesTable, TaskTemplate>,
      ),
      TaskTemplate,
      PrefetchHooks Function()
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      required String id,
      Value<String?> taskId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required int actualMinutes,
      Value<int?> estimateMinutes,
      required bool alarmEnabled,
      Value<String?> transferredToTaskId,
      Value<String?> reflectionNote,
      Value<int> rowid,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      Value<String?> taskId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> actualMinutes,
      Value<int?> estimateMinutes,
      Value<bool> alarmEnabled,
      Value<String?> transferredToTaskId,
      Value<String?> reflectionNote,
      Value<int> rowid,
    });

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferredToTaskId => $composableBuilder(
    column: $table.transferredToTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reflectionNote => $composableBuilder(
    column: $table.reflectionNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferredToTaskId => $composableBuilder(
    column: $table.transferredToTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflectionNote => $composableBuilder(
    column: $table.reflectionNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get alarmEnabled => $composableBuilder(
    column: $table.alarmEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferredToTaskId => $composableBuilder(
    column: $table.transferredToTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reflectionNote => $composableBuilder(
    column: $table.reflectionNote,
    builder: (column) => column,
  );
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSession,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (
            FocusSession,
            BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
          ),
          FocusSession,
          PrefetchHooks Function()
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> actualMinutes = const Value.absent(),
                Value<int?> estimateMinutes = const Value.absent(),
                Value<bool> alarmEnabled = const Value.absent(),
                Value<String?> transferredToTaskId = const Value.absent(),
                Value<String?> reflectionNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                taskId: taskId,
                startedAt: startedAt,
                endedAt: endedAt,
                actualMinutes: actualMinutes,
                estimateMinutes: estimateMinutes,
                alarmEnabled: alarmEnabled,
                transferredToTaskId: transferredToTaskId,
                reflectionNote: reflectionNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> taskId = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required int actualMinutes,
                Value<int?> estimateMinutes = const Value.absent(),
                required bool alarmEnabled,
                Value<String?> transferredToTaskId = const Value.absent(),
                Value<String?> reflectionNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                taskId: taskId,
                startedAt: startedAt,
                endedAt: endedAt,
                actualMinutes: actualMinutes,
                estimateMinutes: estimateMinutes,
                alarmEnabled: alarmEnabled,
                transferredToTaskId: transferredToTaskId,
                reflectionNote: reflectionNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSession,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (
        FocusSession,
        BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
      ),
      FocusSession,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> id,
      required String localeCode,
      required int themeModeIndex,
      required String fontScaleLevel,
      required bool clockTickSoundEnabled,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> id,
      Value<String> localeCode,
      Value<int> themeModeIndex,
      Value<String> fontScaleLevel,
      Value<bool> clockTickSoundEnabled,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get themeModeIndex => $composableBuilder(
    column: $table.themeModeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fontScaleLevel => $composableBuilder(
    column: $table.fontScaleLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get clockTickSoundEnabled => $composableBuilder(
    column: $table.clockTickSoundEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get themeModeIndex => $composableBuilder(
    column: $table.themeModeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontScaleLevel => $composableBuilder(
    column: $table.fontScaleLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get clockTickSoundEnabled => $composableBuilder(
    column: $table.clockTickSoundEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get themeModeIndex => $composableBuilder(
    column: $table.themeModeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fontScaleLevel => $composableBuilder(
    column: $table.fontScaleLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get clockTickSoundEnabled => $composableBuilder(
    column: $table.clockTickSoundEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localeCode = const Value.absent(),
                Value<int> themeModeIndex = const Value.absent(),
                Value<String> fontScaleLevel = const Value.absent(),
                Value<bool> clockTickSoundEnabled = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(
                id: id,
                localeCode: localeCode,
                themeModeIndex: themeModeIndex,
                fontScaleLevel: fontScaleLevel,
                clockTickSoundEnabled: clockTickSoundEnabled,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String localeCode,
                required int themeModeIndex,
                required String fontScaleLevel,
                required bool clockTickSoundEnabled,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                id: id,
                localeCode: localeCode,
                themeModeIndex: themeModeIndex,
                fontScaleLevel: fontScaleLevel,
                clockTickSoundEnabled: clockTickSoundEnabled,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$SeedImportLogsTableCreateCompanionBuilder =
    SeedImportLogsCompanion Function({
      required String id,
      required String version,
      required DateTime importedAt,
      Value<int> rowid,
    });
typedef $$SeedImportLogsTableUpdateCompanionBuilder =
    SeedImportLogsCompanion Function({
      Value<String> id,
      Value<String> version,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

class $$SeedImportLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SeedImportLogsTable> {
  $$SeedImportLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeedImportLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeedImportLogsTable> {
  $$SeedImportLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeedImportLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeedImportLogsTable> {
  $$SeedImportLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $$SeedImportLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeedImportLogsTable,
          SeedImportLog,
          $$SeedImportLogsTableFilterComposer,
          $$SeedImportLogsTableOrderingComposer,
          $$SeedImportLogsTableAnnotationComposer,
          $$SeedImportLogsTableCreateCompanionBuilder,
          $$SeedImportLogsTableUpdateCompanionBuilder,
          (
            SeedImportLog,
            BaseReferences<_$AppDatabase, $SeedImportLogsTable, SeedImportLog>,
          ),
          SeedImportLog,
          PrefetchHooks Function()
        > {
  $$SeedImportLogsTableTableManager(
    _$AppDatabase db,
    $SeedImportLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeedImportLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeedImportLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeedImportLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeedImportLogsCompanion(
                id: id,
                version: version,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String version,
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => SeedImportLogsCompanion.insert(
                id: id,
                version: version,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeedImportLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeedImportLogsTable,
      SeedImportLog,
      $$SeedImportLogsTableFilterComposer,
      $$SeedImportLogsTableOrderingComposer,
      $$SeedImportLogsTableAnnotationComposer,
      $$SeedImportLogsTableCreateCompanionBuilder,
      $$SeedImportLogsTableUpdateCompanionBuilder,
      (
        SeedImportLog,
        BaseReferences<_$AppDatabase, $SeedImportLogsTable, SeedImportLog>,
      ),
      SeedImportLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db, _db.milestones);
  $$TaskLogsTableTableManager get taskLogs =>
      $$TaskLogsTableTableManager(_db, _db.taskLogs);
  $$ProjectLogsTableTableManager get projectLogs =>
      $$ProjectLogsTableTableManager(_db, _db.projectLogs);
  $$MilestoneLogsTableTableManager get milestoneLogs =>
      $$MilestoneLogsTableTableManager(_db, _db.milestoneLogs);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TaskTemplatesTableTableManager get taskTemplates =>
      $$TaskTemplatesTableTableManager(_db, _db.taskTemplates);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$SeedImportLogsTableTableManager get seedImportLogs =>
      $$SeedImportLogsTableTableManager(_db, _db.seedImportLogs);
}
