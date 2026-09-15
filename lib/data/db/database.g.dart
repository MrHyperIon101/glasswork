// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, Workspace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workspace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workspace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workspace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }
}

class Workspace extends DataClass implements Insertable<Workspace> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String name;
  const Workspace({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['name'] = Variable<String>(name);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      name: Value(name),
    );
  }

  factory Workspace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workspace(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'name': serializer.toJson<String>(name),
    };
  }

  Workspace copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? name,
  }) => Workspace(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    name: name ?? this.name,
  );
  Workspace copyWithCompanion(WorkspacesCompanion data) {
    return Workspace(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workspace(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    name,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workspace &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.name == this.name);
}

class WorkspacesCompanion extends UpdateCompanion<Workspace> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> name;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Workspace> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardsTable extends Boards with TableInfo<$BoardsTable, Board> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<int> colour = GeneratedColumn<int>(
    'colour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BoardView, String> viewDefault =
      GeneratedColumn<String>(
        'view_default',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('list'),
      ).withConverter<BoardView>($BoardsTable.$converterviewDefault);
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    name,
    purpose,
    icon,
    colour,
    archived,
    viewDefault,
    orderKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Board> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('colour')) {
      context.handle(
        _colourMeta,
        colour.isAcceptableOrUnknown(data['colour']!, _colourMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Board map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Board(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      colour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}colour'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      viewDefault: $BoardsTable.$converterviewDefault.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}view_default'],
        )!,
      ),
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
    );
  }

  @override
  $BoardsTable createAlias(String alias) {
    return $BoardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BoardView, String, String> $converterviewDefault =
      const EnumNameConverter<BoardView>(BoardView.values);
}

class Board extends DataClass implements Insertable<Board> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String name;

  /// One-line statement of what the project is for. Shown under its title, because a
  /// project name alone rarely says enough six weeks later.
  final String? purpose;
  final String? icon;
  final int? colour;

  /// Archived projects stay queryable but leave the sidebar.
  final bool archived;
  final BoardView viewDefault;

  /// Fractional index. Never an int, never a reindex loop.
  final String orderKey;
  const Board({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.name,
    this.purpose,
    this.icon,
    this.colour,
    required this.archived,
    required this.viewDefault,
    required this.orderKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || purpose != null) {
      map['purpose'] = Variable<String>(purpose);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<int>(colour);
    }
    map['archived'] = Variable<bool>(archived);
    {
      map['view_default'] = Variable<String>(
        $BoardsTable.$converterviewDefault.toSql(viewDefault),
      );
    }
    map['order_key'] = Variable<String>(orderKey);
    return map;
  }

  BoardsCompanion toCompanion(bool nullToAbsent) {
    return BoardsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      name: Value(name),
      purpose: purpose == null && nullToAbsent
          ? const Value.absent()
          : Value(purpose),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      colour: colour == null && nullToAbsent
          ? const Value.absent()
          : Value(colour),
      archived: Value(archived),
      viewDefault: Value(viewDefault),
      orderKey: Value(orderKey),
    );
  }

  factory Board.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Board(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      purpose: serializer.fromJson<String?>(json['purpose']),
      icon: serializer.fromJson<String?>(json['icon']),
      colour: serializer.fromJson<int?>(json['colour']),
      archived: serializer.fromJson<bool>(json['archived']),
      viewDefault: $BoardsTable.$converterviewDefault.fromJson(
        serializer.fromJson<String>(json['viewDefault']),
      ),
      orderKey: serializer.fromJson<String>(json['orderKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'purpose': serializer.toJson<String?>(purpose),
      'icon': serializer.toJson<String?>(icon),
      'colour': serializer.toJson<int?>(colour),
      'archived': serializer.toJson<bool>(archived),
      'viewDefault': serializer.toJson<String>(
        $BoardsTable.$converterviewDefault.toJson(viewDefault),
      ),
      'orderKey': serializer.toJson<String>(orderKey),
    };
  }

  Board copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? name,
    Value<String?> purpose = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<int?> colour = const Value.absent(),
    bool? archived,
    BoardView? viewDefault,
    String? orderKey,
  }) => Board(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    purpose: purpose.present ? purpose.value : this.purpose,
    icon: icon.present ? icon.value : this.icon,
    colour: colour.present ? colour.value : this.colour,
    archived: archived ?? this.archived,
    viewDefault: viewDefault ?? this.viewDefault,
    orderKey: orderKey ?? this.orderKey,
  );
  Board copyWithCompanion(BoardsCompanion data) {
    return Board(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      icon: data.icon.present ? data.icon.value : this.icon,
      colour: data.colour.present ? data.colour.value : this.colour,
      archived: data.archived.present ? data.archived.value : this.archived,
      viewDefault: data.viewDefault.present
          ? data.viewDefault.value
          : this.viewDefault,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Board(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('purpose: $purpose, ')
          ..write('icon: $icon, ')
          ..write('colour: $colour, ')
          ..write('archived: $archived, ')
          ..write('viewDefault: $viewDefault, ')
          ..write('orderKey: $orderKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    name,
    purpose,
    icon,
    colour,
    archived,
    viewDefault,
    orderKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Board &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.purpose == this.purpose &&
          other.icon == this.icon &&
          other.colour == this.colour &&
          other.archived == this.archived &&
          other.viewDefault == this.viewDefault &&
          other.orderKey == this.orderKey);
}

class BoardsCompanion extends UpdateCompanion<Board> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String?> purpose;
  final Value<String?> icon;
  final Value<int?> colour;
  final Value<bool> archived;
  final Value<BoardView> viewDefault;
  final Value<String> orderKey;
  final Value<int> rowid;
  const BoardsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.purpose = const Value.absent(),
    this.icon = const Value.absent(),
    this.colour = const Value.absent(),
    this.archived = const Value.absent(),
    this.viewDefault = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardsCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String name,
    this.purpose = const Value.absent(),
    this.icon = const Value.absent(),
    this.colour = const Value.absent(),
    this.archived = const Value.absent(),
    this.viewDefault = const Value.absent(),
    required String orderKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name),
       orderKey = Value(orderKey);
  static Insertable<Board> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? purpose,
    Expression<String>? icon,
    Expression<int>? colour,
    Expression<bool>? archived,
    Expression<String>? viewDefault,
    Expression<String>? orderKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (purpose != null) 'purpose': purpose,
      if (icon != null) 'icon': icon,
      if (colour != null) 'colour': colour,
      if (archived != null) 'archived': archived,
      if (viewDefault != null) 'view_default': viewDefault,
      if (orderKey != null) 'order_key': orderKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String?>? purpose,
    Value<String?>? icon,
    Value<int?>? colour,
    Value<bool>? archived,
    Value<BoardView>? viewDefault,
    Value<String>? orderKey,
    Value<int>? rowid,
  }) {
    return BoardsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      icon: icon ?? this.icon,
      colour: colour ?? this.colour,
      archived: archived ?? this.archived,
      viewDefault: viewDefault ?? this.viewDefault,
      orderKey: orderKey ?? this.orderKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colour.present) {
      map['colour'] = Variable<int>(colour.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (viewDefault.present) {
      map['view_default'] = Variable<String>(
        $BoardsTable.$converterviewDefault.toSql(viewDefault.value),
      );
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('purpose: $purpose, ')
          ..write('icon: $icon, ')
          ..write('colour: $colour, ')
          ..write('archived: $archived, ')
          ..write('viewDefault: $viewDefault, ')
          ..write('orderKey: $orderKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListsTable extends Lists with TableInfo<$ListsTable, BoardList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wipLimitMeta = const VerificationMeta(
    'wipLimit',
  );
  @override
  late final GeneratedColumn<int> wipLimit = GeneratedColumn<int>(
    'wip_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDoneColumnMeta = const VerificationMeta(
    'isDoneColumn',
  );
  @override
  late final GeneratedColumn<bool> isDoneColumn = GeneratedColumn<bool>(
    'is_done_column',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done_column" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    boardId,
    name,
    orderKey,
    wipLimit,
    isDoneColumn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('wip_limit')) {
      context.handle(
        _wipLimitMeta,
        wipLimit.isAcceptableOrUnknown(data['wip_limit']!, _wipLimitMeta),
      );
    }
    if (data.containsKey('is_done_column')) {
      context.handle(
        _isDoneColumnMeta,
        isDoneColumn.isAcceptableOrUnknown(
          data['is_done_column']!,
          _isDoneColumnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
      wipLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wip_limit'],
      ),
      isDoneColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done_column'],
      )!,
    );
  }

  @override
  $ListsTable createAlias(String alias) {
    return $ListsTable(attachedDatabase, alias);
  }
}

class BoardList extends DataClass implements Insertable<BoardList> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String boardId;
  final String name;
  final String orderKey;
  final int? wipLimit;
  final bool isDoneColumn;
  const BoardList({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.boardId,
    required this.name,
    required this.orderKey,
    this.wipLimit,
    required this.isDoneColumn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['board_id'] = Variable<String>(boardId);
    map['name'] = Variable<String>(name);
    map['order_key'] = Variable<String>(orderKey);
    if (!nullToAbsent || wipLimit != null) {
      map['wip_limit'] = Variable<int>(wipLimit);
    }
    map['is_done_column'] = Variable<bool>(isDoneColumn);
    return map;
  }

  ListsCompanion toCompanion(bool nullToAbsent) {
    return ListsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      boardId: Value(boardId),
      name: Value(name),
      orderKey: Value(orderKey),
      wipLimit: wipLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(wipLimit),
      isDoneColumn: Value(isDoneColumn),
    );
  }

  factory BoardList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardList(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      boardId: serializer.fromJson<String>(json['boardId']),
      name: serializer.fromJson<String>(json['name']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
      wipLimit: serializer.fromJson<int?>(json['wipLimit']),
      isDoneColumn: serializer.fromJson<bool>(json['isDoneColumn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'boardId': serializer.toJson<String>(boardId),
      'name': serializer.toJson<String>(name),
      'orderKey': serializer.toJson<String>(orderKey),
      'wipLimit': serializer.toJson<int?>(wipLimit),
      'isDoneColumn': serializer.toJson<bool>(isDoneColumn),
    };
  }

  BoardList copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? boardId,
    String? name,
    String? orderKey,
    Value<int?> wipLimit = const Value.absent(),
    bool? isDoneColumn,
  }) => BoardList(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    boardId: boardId ?? this.boardId,
    name: name ?? this.name,
    orderKey: orderKey ?? this.orderKey,
    wipLimit: wipLimit.present ? wipLimit.value : this.wipLimit,
    isDoneColumn: isDoneColumn ?? this.isDoneColumn,
  );
  BoardList copyWithCompanion(ListsCompanion data) {
    return BoardList(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      name: data.name.present ? data.name.value : this.name,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      wipLimit: data.wipLimit.present ? data.wipLimit.value : this.wipLimit,
      isDoneColumn: data.isDoneColumn.present
          ? data.isDoneColumn.value
          : this.isDoneColumn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardList(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('orderKey: $orderKey, ')
          ..write('wipLimit: $wipLimit, ')
          ..write('isDoneColumn: $isDoneColumn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    boardId,
    name,
    orderKey,
    wipLimit,
    isDoneColumn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardList &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.boardId == this.boardId &&
          other.name == this.name &&
          other.orderKey == this.orderKey &&
          other.wipLimit == this.wipLimit &&
          other.isDoneColumn == this.isDoneColumn);
}

class ListsCompanion extends UpdateCompanion<BoardList> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> boardId;
  final Value<String> name;
  final Value<String> orderKey;
  final Value<int?> wipLimit;
  final Value<bool> isDoneColumn;
  final Value<int> rowid;
  const ListsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.name = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.wipLimit = const Value.absent(),
    this.isDoneColumn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListsCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String boardId,
    required String name,
    required String orderKey,
    this.wipLimit = const Value.absent(),
    this.isDoneColumn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       boardId = Value(boardId),
       name = Value(name),
       orderKey = Value(orderKey);
  static Insertable<BoardList> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? boardId,
    Expression<String>? name,
    Expression<String>? orderKey,
    Expression<int>? wipLimit,
    Expression<bool>? isDoneColumn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (boardId != null) 'board_id': boardId,
      if (name != null) 'name': name,
      if (orderKey != null) 'order_key': orderKey,
      if (wipLimit != null) 'wip_limit': wipLimit,
      if (isDoneColumn != null) 'is_done_column': isDoneColumn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? boardId,
    Value<String>? name,
    Value<String>? orderKey,
    Value<int?>? wipLimit,
    Value<bool>? isDoneColumn,
    Value<int>? rowid,
  }) {
    return ListsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      orderKey: orderKey ?? this.orderKey,
      wipLimit: wipLimit ?? this.wipLimit,
      isDoneColumn: isDoneColumn ?? this.isDoneColumn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (wipLimit.present) {
      map['wip_limit'] = Variable<int>(wipLimit.value);
    }
    if (isDoneColumn.present) {
      map['is_done_column'] = Variable<bool>(isDoneColumn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('orderKey: $orderKey, ')
          ..write('wipLimit: $wipLimit, ')
          ..write('isDoneColumn: $isDoneColumn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lists (id)',
    ),
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
  static const VerificationMeta _notesMdMeta = const VerificationMeta(
    'notesMd',
  );
  @override
  late final GeneratedColumn<String> notesMd = GeneratedColumn<String>(
    'notes_md',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('open'),
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _estimateMinMeta = const VerificationMeta(
    'estimateMin',
  );
  @override
  late final GeneratedColumn<int> estimateMin = GeneratedColumn<int>(
    'estimate_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMinMeta = const VerificationMeta(
    'actualMin',
  );
  @override
  late final GeneratedColumn<int> actualMin = GeneratedColumn<int>(
    'actual_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledForMeta = const VerificationMeta(
    'scheduledFor',
  );
  @override
  late final GeneratedColumn<String> scheduledFor = GeneratedColumn<String>(
    'scheduled_for',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _slipCountMeta = const VerificationMeta(
    'slipCount',
  );
  @override
  late final GeneratedColumn<int> slipCount = GeneratedColumn<int>(
    'slip_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastDeferredAtMeta = const VerificationMeta(
    'lastDeferredAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastDeferredAt =
      GeneratedColumn<DateTime>(
        'last_deferred_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<DateTime> remindAt = GeneratedColumn<DateTime>(
    'remind_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    listId,
    title,
    notesMd,
    orderKey,
    status,
    priority,
    dueAt,
    dueDate,
    startAt,
    completedAt,
    rrule,
    parentTaskId,
    estimateMin,
    actualMin,
    scheduledFor,
    slipCount,
    lastDeferredAt,
    remindAt,
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes_md')) {
      context.handle(
        _notesMdMeta,
        notesMd.isAcceptableOrUnknown(data['notes_md']!, _notesMdMeta),
      );
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
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
    if (data.containsKey('estimate_min')) {
      context.handle(
        _estimateMinMeta,
        estimateMin.isAcceptableOrUnknown(
          data['estimate_min']!,
          _estimateMinMeta,
        ),
      );
    }
    if (data.containsKey('actual_min')) {
      context.handle(
        _actualMinMeta,
        actualMin.isAcceptableOrUnknown(data['actual_min']!, _actualMinMeta),
      );
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
        _scheduledForMeta,
        scheduledFor.isAcceptableOrUnknown(
          data['scheduled_for']!,
          _scheduledForMeta,
        ),
      );
    }
    if (data.containsKey('slip_count')) {
      context.handle(
        _slipCountMeta,
        slipCount.isAcceptableOrUnknown(data['slip_count']!, _slipCountMeta),
      );
    }
    if (data.containsKey('last_deferred_at')) {
      context.handle(
        _lastDeferredAtMeta,
        lastDeferredAt.isAcceptableOrUnknown(
          data['last_deferred_at']!,
          _lastDeferredAtMeta,
        ),
      );
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notesMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes_md'],
      ),
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      ),
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      estimateMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_min'],
      ),
      actualMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_min'],
      ),
      scheduledFor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_for'],
      ),
      slipCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slip_count'],
      )!,
      lastDeferredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_deferred_at'],
      ),
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remind_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String listId;
  final String title;
  final String? notesMd;
  final String orderKey;
  final TaskStatus status;
  final int priority;

  /// Timed due date, stored UTC.
  final DateTime? dueAt;

  /// All-day due date as 'YYYY-MM-DD'. Deliberately text, not a timestamp: an all-day
  /// task has no instant and no timezone, and storing one breaks "due today" the moment
  /// you travel or the server is UTC. At most one of [dueAt] / [dueDate] is set.
  final String? dueDate;
  final DateTime? startAt;
  final DateTime? completedAt;

  /// RRULE string, expanded client-side only.
  final String? rrule;
  final String? parentTaskId;
  final int? estimateMin;
  final int? actualMin;

  /// 'YYYY-MM-DD', same reasoning as [dueDate].
  final String? scheduledFor;

  /// Three slips means something is wrong with the task, not with your discipline.
  final int slipCount;
  final DateTime? lastDeferredAt;

  /// When to be reminded, stored UTC. Null for no reminder. Every device with the task
  /// raises it, so the reminder reaches whichever one is at hand.
  final DateTime? remindAt;
  const Task({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.listId,
    required this.title,
    this.notesMd,
    required this.orderKey,
    required this.status,
    required this.priority,
    this.dueAt,
    this.dueDate,
    this.startAt,
    this.completedAt,
    this.rrule,
    this.parentTaskId,
    this.estimateMin,
    this.actualMin,
    this.scheduledFor,
    required this.slipCount,
    this.lastDeferredAt,
    this.remindAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['list_id'] = Variable<String>(listId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notesMd != null) {
      map['notes_md'] = Variable<String>(notesMd);
    }
    map['order_key'] = Variable<String>(orderKey);
    {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status),
      );
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<DateTime>(startAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    if (!nullToAbsent || estimateMin != null) {
      map['estimate_min'] = Variable<int>(estimateMin);
    }
    if (!nullToAbsent || actualMin != null) {
      map['actual_min'] = Variable<int>(actualMin);
    }
    if (!nullToAbsent || scheduledFor != null) {
      map['scheduled_for'] = Variable<String>(scheduledFor);
    }
    map['slip_count'] = Variable<int>(slipCount);
    if (!nullToAbsent || lastDeferredAt != null) {
      map['last_deferred_at'] = Variable<DateTime>(lastDeferredAt);
    }
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<DateTime>(remindAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      listId: Value(listId),
      title: Value(title),
      notesMd: notesMd == null && nullToAbsent
          ? const Value.absent()
          : Value(notesMd),
      orderKey: Value(orderKey),
      status: Value(status),
      priority: Value(priority),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      rrule: rrule == null && nullToAbsent
          ? const Value.absent()
          : Value(rrule),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      estimateMin: estimateMin == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateMin),
      actualMin: actualMin == null && nullToAbsent
          ? const Value.absent()
          : Value(actualMin),
      scheduledFor: scheduledFor == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledFor),
      slipCount: Value(slipCount),
      lastDeferredAt: lastDeferredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDeferredAt),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      listId: serializer.fromJson<String>(json['listId']),
      title: serializer.fromJson<String>(json['title']),
      notesMd: serializer.fromJson<String?>(json['notesMd']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      priority: serializer.fromJson<int>(json['priority']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      startAt: serializer.fromJson<DateTime?>(json['startAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      parentTaskId: serializer.fromJson<String?>(json['parentTaskId']),
      estimateMin: serializer.fromJson<int?>(json['estimateMin']),
      actualMin: serializer.fromJson<int?>(json['actualMin']),
      scheduledFor: serializer.fromJson<String?>(json['scheduledFor']),
      slipCount: serializer.fromJson<int>(json['slipCount']),
      lastDeferredAt: serializer.fromJson<DateTime?>(json['lastDeferredAt']),
      remindAt: serializer.fromJson<DateTime?>(json['remindAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'listId': serializer.toJson<String>(listId),
      'title': serializer.toJson<String>(title),
      'notesMd': serializer.toJson<String?>(notesMd),
      'orderKey': serializer.toJson<String>(orderKey),
      'status': serializer.toJson<String>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'priority': serializer.toJson<int>(priority),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'dueDate': serializer.toJson<String?>(dueDate),
      'startAt': serializer.toJson<DateTime?>(startAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'rrule': serializer.toJson<String?>(rrule),
      'parentTaskId': serializer.toJson<String?>(parentTaskId),
      'estimateMin': serializer.toJson<int?>(estimateMin),
      'actualMin': serializer.toJson<int?>(actualMin),
      'scheduledFor': serializer.toJson<String?>(scheduledFor),
      'slipCount': serializer.toJson<int>(slipCount),
      'lastDeferredAt': serializer.toJson<DateTime?>(lastDeferredAt),
      'remindAt': serializer.toJson<DateTime?>(remindAt),
    };
  }

  Task copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? listId,
    String? title,
    Value<String?> notesMd = const Value.absent(),
    String? orderKey,
    TaskStatus? status,
    int? priority,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    Value<DateTime?> startAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> rrule = const Value.absent(),
    Value<String?> parentTaskId = const Value.absent(),
    Value<int?> estimateMin = const Value.absent(),
    Value<int?> actualMin = const Value.absent(),
    Value<String?> scheduledFor = const Value.absent(),
    int? slipCount,
    Value<DateTime?> lastDeferredAt = const Value.absent(),
    Value<DateTime?> remindAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    listId: listId ?? this.listId,
    title: title ?? this.title,
    notesMd: notesMd.present ? notesMd.value : this.notesMd,
    orderKey: orderKey ?? this.orderKey,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    startAt: startAt.present ? startAt.value : this.startAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    rrule: rrule.present ? rrule.value : this.rrule,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    estimateMin: estimateMin.present ? estimateMin.value : this.estimateMin,
    actualMin: actualMin.present ? actualMin.value : this.actualMin,
    scheduledFor: scheduledFor.present ? scheduledFor.value : this.scheduledFor,
    slipCount: slipCount ?? this.slipCount,
    lastDeferredAt: lastDeferredAt.present
        ? lastDeferredAt.value
        : this.lastDeferredAt,
    remindAt: remindAt.present ? remindAt.value : this.remindAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      listId: data.listId.present ? data.listId.value : this.listId,
      title: data.title.present ? data.title.value : this.title,
      notesMd: data.notesMd.present ? data.notesMd.value : this.notesMd,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      estimateMin: data.estimateMin.present
          ? data.estimateMin.value
          : this.estimateMin,
      actualMin: data.actualMin.present ? data.actualMin.value : this.actualMin,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      slipCount: data.slipCount.present ? data.slipCount.value : this.slipCount,
      lastDeferredAt: data.lastDeferredAt.present
          ? data.lastDeferredAt.value
          : this.lastDeferredAt,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('listId: $listId, ')
          ..write('title: $title, ')
          ..write('notesMd: $notesMd, ')
          ..write('orderKey: $orderKey, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('startAt: $startAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rrule: $rrule, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('estimateMin: $estimateMin, ')
          ..write('actualMin: $actualMin, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('slipCount: $slipCount, ')
          ..write('lastDeferredAt: $lastDeferredAt, ')
          ..write('remindAt: $remindAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    listId,
    title,
    notesMd,
    orderKey,
    status,
    priority,
    dueAt,
    dueDate,
    startAt,
    completedAt,
    rrule,
    parentTaskId,
    estimateMin,
    actualMin,
    scheduledFor,
    slipCount,
    lastDeferredAt,
    remindAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.listId == this.listId &&
          other.title == this.title &&
          other.notesMd == this.notesMd &&
          other.orderKey == this.orderKey &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.dueAt == this.dueAt &&
          other.dueDate == this.dueDate &&
          other.startAt == this.startAt &&
          other.completedAt == this.completedAt &&
          other.rrule == this.rrule &&
          other.parentTaskId == this.parentTaskId &&
          other.estimateMin == this.estimateMin &&
          other.actualMin == this.actualMin &&
          other.scheduledFor == this.scheduledFor &&
          other.slipCount == this.slipCount &&
          other.lastDeferredAt == this.lastDeferredAt &&
          other.remindAt == this.remindAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> listId;
  final Value<String> title;
  final Value<String?> notesMd;
  final Value<String> orderKey;
  final Value<TaskStatus> status;
  final Value<int> priority;
  final Value<DateTime?> dueAt;
  final Value<String?> dueDate;
  final Value<DateTime?> startAt;
  final Value<DateTime?> completedAt;
  final Value<String?> rrule;
  final Value<String?> parentTaskId;
  final Value<int?> estimateMin;
  final Value<int?> actualMin;
  final Value<String?> scheduledFor;
  final Value<int> slipCount;
  final Value<DateTime?> lastDeferredAt;
  final Value<DateTime?> remindAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.listId = const Value.absent(),
    this.title = const Value.absent(),
    this.notesMd = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.startAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rrule = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.estimateMin = const Value.absent(),
    this.actualMin = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.slipCount = const Value.absent(),
    this.lastDeferredAt = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String listId,
    required String title,
    this.notesMd = const Value.absent(),
    required String orderKey,
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.startAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rrule = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.estimateMin = const Value.absent(),
    this.actualMin = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.slipCount = const Value.absent(),
    this.lastDeferredAt = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       listId = Value(listId),
       title = Value(title),
       orderKey = Value(orderKey);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? listId,
    Expression<String>? title,
    Expression<String>? notesMd,
    Expression<String>? orderKey,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<DateTime>? dueAt,
    Expression<String>? dueDate,
    Expression<DateTime>? startAt,
    Expression<DateTime>? completedAt,
    Expression<String>? rrule,
    Expression<String>? parentTaskId,
    Expression<int>? estimateMin,
    Expression<int>? actualMin,
    Expression<String>? scheduledFor,
    Expression<int>? slipCount,
    Expression<DateTime>? lastDeferredAt,
    Expression<DateTime>? remindAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (listId != null) 'list_id': listId,
      if (title != null) 'title': title,
      if (notesMd != null) 'notes_md': notesMd,
      if (orderKey != null) 'order_key': orderKey,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (dueAt != null) 'due_at': dueAt,
      if (dueDate != null) 'due_date': dueDate,
      if (startAt != null) 'start_at': startAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rrule != null) 'rrule': rrule,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (estimateMin != null) 'estimate_min': estimateMin,
      if (actualMin != null) 'actual_min': actualMin,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (slipCount != null) 'slip_count': slipCount,
      if (lastDeferredAt != null) 'last_deferred_at': lastDeferredAt,
      if (remindAt != null) 'remind_at': remindAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? listId,
    Value<String>? title,
    Value<String?>? notesMd,
    Value<String>? orderKey,
    Value<TaskStatus>? status,
    Value<int>? priority,
    Value<DateTime?>? dueAt,
    Value<String?>? dueDate,
    Value<DateTime?>? startAt,
    Value<DateTime?>? completedAt,
    Value<String?>? rrule,
    Value<String?>? parentTaskId,
    Value<int?>? estimateMin,
    Value<int?>? actualMin,
    Value<String?>? scheduledFor,
    Value<int>? slipCount,
    Value<DateTime?>? lastDeferredAt,
    Value<DateTime?>? remindAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      notesMd: notesMd ?? this.notesMd,
      orderKey: orderKey ?? this.orderKey,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      dueDate: dueDate ?? this.dueDate,
      startAt: startAt ?? this.startAt,
      completedAt: completedAt ?? this.completedAt,
      rrule: rrule ?? this.rrule,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      estimateMin: estimateMin ?? this.estimateMin,
      actualMin: actualMin ?? this.actualMin,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      slipCount: slipCount ?? this.slipCount,
      lastDeferredAt: lastDeferredAt ?? this.lastDeferredAt,
      remindAt: remindAt ?? this.remindAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notesMd.present) {
      map['notes_md'] = Variable<String>(notesMd.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
    }
    if (estimateMin.present) {
      map['estimate_min'] = Variable<int>(estimateMin.value);
    }
    if (actualMin.present) {
      map['actual_min'] = Variable<int>(actualMin.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<String>(scheduledFor.value);
    }
    if (slipCount.present) {
      map['slip_count'] = Variable<int>(slipCount.value);
    }
    if (lastDeferredAt.present) {
      map['last_deferred_at'] = Variable<DateTime>(lastDeferredAt.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<DateTime>(remindAt.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('listId: $listId, ')
          ..write('title: $title, ')
          ..write('notesMd: $notesMd, ')
          ..write('orderKey: $orderKey, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueAt: $dueAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('startAt: $startAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rrule: $rrule, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('estimateMin: $estimateMin, ')
          ..write('actualMin: $actualMin, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('slipCount: $slipCount, ')
          ..write('lastDeferredAt: $lastDeferredAt, ')
          ..write('remindAt: $remindAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks with TableInfo<$SubtasksTable, Subtask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
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
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    taskId,
    title,
    done,
    orderKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subtask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subtask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class Subtask extends DataClass implements Insertable<Subtask> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String taskId;
  final String title;
  final bool done;
  final String orderKey;
  const Subtask({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.taskId,
    required this.title,
    required this.done,
    required this.orderKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['task_id'] = Variable<String>(taskId);
    map['title'] = Variable<String>(title);
    map['done'] = Variable<bool>(done);
    map['order_key'] = Variable<String>(orderKey);
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      taskId: Value(taskId),
      title: Value(title),
      done: Value(done),
      orderKey: Value(orderKey),
    );
  }

  factory Subtask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtask(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      done: serializer.fromJson<bool>(json['done']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'taskId': serializer.toJson<String>(taskId),
      'title': serializer.toJson<String>(title),
      'done': serializer.toJson<bool>(done),
      'orderKey': serializer.toJson<String>(orderKey),
    };
  }

  Subtask copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? taskId,
    String? title,
    bool? done,
    String? orderKey,
  }) => Subtask(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    done: done ?? this.done,
    orderKey: orderKey ?? this.orderKey,
  );
  Subtask copyWithCompanion(SubtasksCompanion data) {
    return Subtask(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      done: data.done.present ? data.done.value : this.done,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtask(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('orderKey: $orderKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    taskId,
    title,
    done,
    orderKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtask &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.done == this.done &&
          other.orderKey == this.orderKey);
}

class SubtasksCompanion extends UpdateCompanion<Subtask> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> taskId;
  final Value<String> title;
  final Value<bool> done;
  final Value<String> orderKey;
  final Value<int> rowid;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.done = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubtasksCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String taskId,
    required String title,
    this.done = const Value.absent(),
    required String orderKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       taskId = Value(taskId),
       title = Value(title),
       orderKey = Value(orderKey);
  static Insertable<Subtask> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<bool>? done,
    Expression<String>? orderKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (done != null) 'done': done,
      if (orderKey != null) 'order_key': orderKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubtasksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? taskId,
    Value<String>? title,
    Value<bool>? done,
    Value<String>? orderKey,
    Value<int>? rowid,
  }) {
    return SubtasksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      done: done ?? this.done,
      orderKey: orderKey ?? this.orderKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('orderKey: $orderKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabelsTable extends Labels with TableInfo<$LabelsTable, Label> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<int> colour = GeneratedColumn<int>(
    'colour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    name,
    colour,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Label> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('colour')) {
      context.handle(
        _colourMeta,
        colour.isAcceptableOrUnknown(data['colour']!, _colourMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Label map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Label(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}colour'],
      ),
    );
  }

  @override
  $LabelsTable createAlias(String alias) {
    return $LabelsTable(attachedDatabase, alias);
  }
}

class Label extends DataClass implements Insertable<Label> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String name;
  final int? colour;
  const Label({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.name,
    this.colour,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<int>(colour);
    }
    return map;
  }

  LabelsCompanion toCompanion(bool nullToAbsent) {
    return LabelsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      name: Value(name),
      colour: colour == null && nullToAbsent
          ? const Value.absent()
          : Value(colour),
    );
  }

  factory Label.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Label(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      colour: serializer.fromJson<int?>(json['colour']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'colour': serializer.toJson<int?>(colour),
    };
  }

  Label copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? name,
    Value<int?> colour = const Value.absent(),
  }) => Label(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    colour: colour.present ? colour.value : this.colour,
  );
  Label copyWithCompanion(LabelsCompanion data) {
    return Label(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      colour: data.colour.present ? data.colour.value : this.colour,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Label(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('colour: $colour')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    name,
    colour,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Label &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.colour == this.colour);
}

class LabelsCompanion extends UpdateCompanion<Label> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<int?> colour;
  final Value<int> rowid;
  const LabelsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.colour = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabelsCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String name,
    this.colour = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name);
  static Insertable<Label> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<int>? colour,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (colour != null) 'colour': colour,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabelsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<int?>? colour,
    Value<int>? rowid,
  }) {
    return LabelsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      colour: colour ?? this.colour,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colour.present) {
      map['colour'] = Variable<int>(colour.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabelsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('colour: $colour, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskLabelsTable extends TaskLabels
    with TableInfo<$TaskLabelsTable, TaskLabel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskLabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _labelIdMeta = const VerificationMeta(
    'labelId',
  );
  @override
  late final GeneratedColumn<String> labelId = GeneratedColumn<String>(
    'label_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES labels (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    taskId,
    labelId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskLabel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('label_id')) {
      context.handle(
        _labelIdMeta,
        labelId.isAcceptableOrUnknown(data['label_id']!, _labelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_labelIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskLabel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskLabel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      labelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_id'],
      )!,
    );
  }

  @override
  $TaskLabelsTable createAlias(String alias) {
    return $TaskLabelsTable(attachedDatabase, alias);
  }
}

class TaskLabel extends DataClass implements Insertable<TaskLabel> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String taskId;
  final String labelId;
  const TaskLabel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.taskId,
    required this.labelId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['task_id'] = Variable<String>(taskId);
    map['label_id'] = Variable<String>(labelId);
    return map;
  }

  TaskLabelsCompanion toCompanion(bool nullToAbsent) {
    return TaskLabelsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      taskId: Value(taskId),
      labelId: Value(labelId),
    );
  }

  factory TaskLabel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskLabel(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      labelId: serializer.fromJson<String>(json['labelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'taskId': serializer.toJson<String>(taskId),
      'labelId': serializer.toJson<String>(labelId),
    };
  }

  TaskLabel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? taskId,
    String? labelId,
  }) => TaskLabel(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    taskId: taskId ?? this.taskId,
    labelId: labelId ?? this.labelId,
  );
  TaskLabel copyWithCompanion(TaskLabelsCompanion data) {
    return TaskLabel(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      labelId: data.labelId.present ? data.labelId.value : this.labelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskLabel(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('labelId: $labelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    taskId,
    labelId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskLabel &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.taskId == this.taskId &&
          other.labelId == this.labelId);
}

class TaskLabelsCompanion extends UpdateCompanion<TaskLabel> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> taskId;
  final Value<String> labelId;
  final Value<int> rowid;
  const TaskLabelsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.labelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskLabelsCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String taskId,
    required String labelId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       taskId = Value(taskId),
       labelId = Value(labelId);
  static Insertable<TaskLabel> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? taskId,
    Expression<String>? labelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (taskId != null) 'task_id': taskId,
      if (labelId != null) 'label_id': labelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskLabelsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? taskId,
    Value<String>? labelId,
    Value<int>? rowid,
  }) {
    return TaskLabelsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      taskId: taskId ?? this.taskId,
      labelId: labelId ?? this.labelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (labelId.present) {
      map['label_id'] = Variable<String>(labelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskLabelsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('labelId: $labelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
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
  static const VerificationMeta _bodyMdMeta = const VerificationMeta('bodyMd');
  @override
  late final GeneratedColumn<String> bodyMd = GeneratedColumn<String>(
    'body_md',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    title,
    bodyMd,
    pinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body_md')) {
      context.handle(
        _bodyMdMeta,
        bodyMd.isAcceptableOrUnknown(data['body_md']!, _bodyMdMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      bodyMd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_md'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String title;
  final String bodyMd;
  final bool pinned;
  const Note({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.title,
    required this.bodyMd,
    required this.pinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    map['body_md'] = Variable<String>(bodyMd);
    map['pinned'] = Variable<bool>(pinned);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      title: Value(title),
      bodyMd: Value(bodyMd),
      pinned: Value(pinned),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      title: serializer.fromJson<String>(json['title']),
      bodyMd: serializer.fromJson<String>(json['bodyMd']),
      pinned: serializer.fromJson<bool>(json['pinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'bodyMd': serializer.toJson<String>(bodyMd),
      'pinned': serializer.toJson<bool>(pinned),
    };
  }

  Note copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? title,
    String? bodyMd,
    bool? pinned,
  }) => Note(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    bodyMd: bodyMd ?? this.bodyMd,
    pinned: pinned ?? this.pinned,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      bodyMd: data.bodyMd.present ? data.bodyMd.value : this.bodyMd,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('bodyMd: $bodyMd, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    title,
    bodyMd,
    pinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.bodyMd == this.bodyMd &&
          other.pinned == this.pinned);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String> bodyMd;
  final Value<bool> pinned;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.bodyMd = const Value.absent(),
    this.pinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String title,
    this.bodyMd = const Value.absent(),
    this.pinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? bodyMd,
    Expression<bool>? pinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (bodyMd != null) 'body_md': bodyMd,
      if (pinned != null) 'pinned': pinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String>? bodyMd,
    Value<bool>? pinned,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      bodyMd: bodyMd ?? this.bodyMd,
      pinned: pinned ?? this.pinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (bodyMd.present) {
      map['body_md'] = Variable<String>(bodyMd.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('bodyMd: $bodyMd, ')
          ..write('pinned: $pinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedFieldsMeta = const VerificationMeta(
    'changedFields',
  );
  @override
  late final GeneratedColumn<String> changedFields = GeneratedColumn<String>(
    'changed_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    targetTable,
    rowId,
    changedFields,
    hlc,
    queuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('changed_fields')) {
      context.handle(
        _changedFieldsMeta,
        changedFields.isAcceptableOrUnknown(
          data['changed_fields']!,
          _changedFieldsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedFieldsMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      changedFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_fields'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int seq;
  final String targetTable;
  final String rowId;

  /// JSON array of the dirty column names, e.g. `["priority","title"]`.
  ///
  /// Names, not values. Values are read from the row at push time together with their
  /// real per-field clocks in `field_versions`, which is what lets repeated edits to one
  /// row coalesce into a single entry without misstating when each field was written.
  /// See `SyncWriter`.
  final String changedFields;

  /// The newest clock that touched this entry, as an encoded `Hlc`.
  ///
  /// Replaced on every coalesce. A push removes an entry only if this is unchanged since
  /// it read it, so an edit landing mid-push is never lost.
  final String hlc;
  final DateTime queuedAt;
  const OutboxData({
    required this.seq,
    required this.targetTable,
    required this.rowId,
    required this.changedFields,
    required this.hlc,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['target_table'] = Variable<String>(targetTable);
    map['row_id'] = Variable<String>(rowId);
    map['changed_fields'] = Variable<String>(changedFields);
    map['hlc'] = Variable<String>(hlc);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      targetTable: Value(targetTable),
      rowId: Value(rowId),
      changedFields: Value(changedFields),
      hlc: Value(hlc),
      queuedAt: Value(queuedAt),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      rowId: serializer.fromJson<String>(json['rowId']),
      changedFields: serializer.fromJson<String>(json['changedFields']),
      hlc: serializer.fromJson<String>(json['hlc']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'targetTable': serializer.toJson<String>(targetTable),
      'rowId': serializer.toJson<String>(rowId),
      'changedFields': serializer.toJson<String>(changedFields),
      'hlc': serializer.toJson<String>(hlc),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? targetTable,
    String? rowId,
    String? changedFields,
    String? hlc,
    DateTime? queuedAt,
  }) => OutboxData(
    seq: seq ?? this.seq,
    targetTable: targetTable ?? this.targetTable,
    rowId: rowId ?? this.rowId,
    changedFields: changedFields ?? this.changedFields,
    hlc: hlc ?? this.hlc,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      changedFields: data.changedFields.present
          ? data.changedFields.value
          : this.changedFields,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('changedFields: $changedFields, ')
          ..write('hlc: $hlc, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, targetTable, rowId, changedFields, hlc, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.targetTable == this.targetTable &&
          other.rowId == this.rowId &&
          other.changedFields == this.changedFields &&
          other.hlc == this.hlc &&
          other.queuedAt == this.queuedAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> targetTable;
  final Value<String> rowId;
  final Value<String> changedFields;
  final Value<String> hlc;
  final Value<DateTime> queuedAt;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.rowId = const Value.absent(),
    this.changedFields = const Value.absent(),
    this.hlc = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String targetTable,
    required String rowId,
    required String changedFields,
    required String hlc,
    this.queuedAt = const Value.absent(),
  }) : targetTable = Value(targetTable),
       rowId = Value(rowId),
       changedFields = Value(changedFields),
       hlc = Value(hlc);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? targetTable,
    Expression<String>? rowId,
    Expression<String>? changedFields,
    Expression<String>? hlc,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (targetTable != null) 'target_table': targetTable,
      if (rowId != null) 'row_id': rowId,
      if (changedFields != null) 'changed_fields': changedFields,
      if (hlc != null) 'hlc': hlc,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? targetTable,
    Value<String>? rowId,
    Value<String>? changedFields,
    Value<String>? hlc,
    Value<DateTime>? queuedAt,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      targetTable: targetTable ?? this.targetTable,
      rowId: rowId ?? this.rowId,
      changedFields: changedFields ?? this.changedFields,
      hlc: hlc ?? this.hlc,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (changedFields.present) {
      map['changed_fields'] = Variable<String>(changedFields.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('changedFields: $changedFields, ')
          ..write('hlc: $hlc, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CapacityProfilesTable extends CapacityProfiles
    with TableInfo<$CapacityProfilesTable, CapacityProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapacityProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sleepTargetMinMeta = const VerificationMeta(
    'sleepTargetMin',
  );
  @override
  late final GeneratedColumn<int> sleepTargetMin = GeneratedColumn<int>(
    'sleep_target_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(450),
  );
  static const VerificationMeta _sleepStartMinMeta = const VerificationMeta(
    'sleepStartMin',
  );
  @override
  late final GeneratedColumn<int> sleepStartMin = GeneratedColumn<int>(
    'sleep_start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(23 * 60 + 30),
  );
  static const VerificationMeta _wakeMonMinMeta = const VerificationMeta(
    'wakeMonMin',
  );
  @override
  late final GeneratedColumn<int> wakeMonMin = GeneratedColumn<int>(
    'wake_mon_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _bedtimeMonMinMeta = const VerificationMeta(
    'bedtimeMonMin',
  );
  @override
  late final GeneratedColumn<int> bedtimeMonMin = GeneratedColumn<int>(
    'bedtime_mon_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1410),
  );
  static const VerificationMeta _wakeTueMinMeta = const VerificationMeta(
    'wakeTueMin',
  );
  @override
  late final GeneratedColumn<int> wakeTueMin = GeneratedColumn<int>(
    'wake_tue_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _bedtimeTueMinMeta = const VerificationMeta(
    'bedtimeTueMin',
  );
  @override
  late final GeneratedColumn<int> bedtimeTueMin = GeneratedColumn<int>(
    'bedtime_tue_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1410),
  );
  static const VerificationMeta _wakeWedMinMeta = const VerificationMeta(
    'wakeWedMin',
  );
  @override
  late final GeneratedColumn<int> wakeWedMin = GeneratedColumn<int>(
    'wake_wed_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _bedtimeWedMinMeta = const VerificationMeta(
    'bedtimeWedMin',
  );
  @override
  late final GeneratedColumn<int> bedtimeWedMin = GeneratedColumn<int>(
    'bedtime_wed_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1410),
  );
  static const VerificationMeta _wakeThuMinMeta = const VerificationMeta(
    'wakeThuMin',
  );
  @override
  late final GeneratedColumn<int> wakeThuMin = GeneratedColumn<int>(
    'wake_thu_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _bedtimeThuMinMeta = const VerificationMeta(
    'bedtimeThuMin',
  );
  @override
  late final GeneratedColumn<int> bedtimeThuMin = GeneratedColumn<int>(
    'bedtime_thu_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1410),
  );
  static const VerificationMeta _wakeFriMinMeta = const VerificationMeta(
    'wakeFriMin',
  );
  @override
  late final GeneratedColumn<int> wakeFriMin = GeneratedColumn<int>(
    'wake_fri_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _bedtimeFriMinMeta = const VerificationMeta(
    'bedtimeFriMin',
  );
  @override
  late final GeneratedColumn<int> bedtimeFriMin = GeneratedColumn<int>(
    'bedtime_fri_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1410),
  );
  static const VerificationMeta _wakeSatMinMeta = const VerificationMeta(
    'wakeSatMin',
  );
  @override
  late final GeneratedColumn<int> wakeSatMin = GeneratedColumn<int>(
    'wake_sat_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _bedtimeSatMinMeta = const VerificationMeta(
    'bedtimeSatMin',
  );
  @override
  late final GeneratedColumn<int> bedtimeSatMin = GeneratedColumn<int>(
    'bedtime_sat_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1410),
  );
  static const VerificationMeta _wakeSunMinMeta = const VerificationMeta(
    'wakeSunMin',
  );
  @override
  late final GeneratedColumn<int> wakeSunMin = GeneratedColumn<int>(
    'wake_sun_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(420),
  );
  static const VerificationMeta _bedtimeSunMinMeta = const VerificationMeta(
    'bedtimeSunMin',
  );
  @override
  late final GeneratedColumn<int> bedtimeSunMin = GeneratedColumn<int>(
    'bedtime_sun_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1410),
  );
  static const VerificationMeta _mealsMinMeta = const VerificationMeta(
    'mealsMin',
  );
  @override
  late final GeneratedColumn<int> mealsMin = GeneratedColumn<int>(
    'meals_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _bufferMinMeta = const VerificationMeta(
    'bufferMin',
  );
  @override
  late final GeneratedColumn<int> bufferMin = GeneratedColumn<int>(
    'buffer_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _focusFactorMeta = const VerificationMeta(
    'focusFactor',
  );
  @override
  late final GeneratedColumn<double> focusFactor = GeneratedColumn<double>(
    'focus_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.65),
  );
  static const VerificationMeta _minGapMinMeta = const VerificationMeta(
    'minGapMin',
  );
  @override
  late final GeneratedColumn<int> minGapMin = GeneratedColumn<int>(
    'min_gap_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    sleepTargetMin,
    sleepStartMin,
    wakeMonMin,
    bedtimeMonMin,
    wakeTueMin,
    bedtimeTueMin,
    wakeWedMin,
    bedtimeWedMin,
    wakeThuMin,
    bedtimeThuMin,
    wakeFriMin,
    bedtimeFriMin,
    wakeSatMin,
    bedtimeSatMin,
    wakeSunMin,
    bedtimeSunMin,
    mealsMin,
    bufferMin,
    focusFactor,
    minGapMin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'capacity_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CapacityProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('sleep_target_min')) {
      context.handle(
        _sleepTargetMinMeta,
        sleepTargetMin.isAcceptableOrUnknown(
          data['sleep_target_min']!,
          _sleepTargetMinMeta,
        ),
      );
    }
    if (data.containsKey('sleep_start_min')) {
      context.handle(
        _sleepStartMinMeta,
        sleepStartMin.isAcceptableOrUnknown(
          data['sleep_start_min']!,
          _sleepStartMinMeta,
        ),
      );
    }
    if (data.containsKey('wake_mon_min')) {
      context.handle(
        _wakeMonMinMeta,
        wakeMonMin.isAcceptableOrUnknown(
          data['wake_mon_min']!,
          _wakeMonMinMeta,
        ),
      );
    }
    if (data.containsKey('bedtime_mon_min')) {
      context.handle(
        _bedtimeMonMinMeta,
        bedtimeMonMin.isAcceptableOrUnknown(
          data['bedtime_mon_min']!,
          _bedtimeMonMinMeta,
        ),
      );
    }
    if (data.containsKey('wake_tue_min')) {
      context.handle(
        _wakeTueMinMeta,
        wakeTueMin.isAcceptableOrUnknown(
          data['wake_tue_min']!,
          _wakeTueMinMeta,
        ),
      );
    }
    if (data.containsKey('bedtime_tue_min')) {
      context.handle(
        _bedtimeTueMinMeta,
        bedtimeTueMin.isAcceptableOrUnknown(
          data['bedtime_tue_min']!,
          _bedtimeTueMinMeta,
        ),
      );
    }
    if (data.containsKey('wake_wed_min')) {
      context.handle(
        _wakeWedMinMeta,
        wakeWedMin.isAcceptableOrUnknown(
          data['wake_wed_min']!,
          _wakeWedMinMeta,
        ),
      );
    }
    if (data.containsKey('bedtime_wed_min')) {
      context.handle(
        _bedtimeWedMinMeta,
        bedtimeWedMin.isAcceptableOrUnknown(
          data['bedtime_wed_min']!,
          _bedtimeWedMinMeta,
        ),
      );
    }
    if (data.containsKey('wake_thu_min')) {
      context.handle(
        _wakeThuMinMeta,
        wakeThuMin.isAcceptableOrUnknown(
          data['wake_thu_min']!,
          _wakeThuMinMeta,
        ),
      );
    }
    if (data.containsKey('bedtime_thu_min')) {
      context.handle(
        _bedtimeThuMinMeta,
        bedtimeThuMin.isAcceptableOrUnknown(
          data['bedtime_thu_min']!,
          _bedtimeThuMinMeta,
        ),
      );
    }
    if (data.containsKey('wake_fri_min')) {
      context.handle(
        _wakeFriMinMeta,
        wakeFriMin.isAcceptableOrUnknown(
          data['wake_fri_min']!,
          _wakeFriMinMeta,
        ),
      );
    }
    if (data.containsKey('bedtime_fri_min')) {
      context.handle(
        _bedtimeFriMinMeta,
        bedtimeFriMin.isAcceptableOrUnknown(
          data['bedtime_fri_min']!,
          _bedtimeFriMinMeta,
        ),
      );
    }
    if (data.containsKey('wake_sat_min')) {
      context.handle(
        _wakeSatMinMeta,
        wakeSatMin.isAcceptableOrUnknown(
          data['wake_sat_min']!,
          _wakeSatMinMeta,
        ),
      );
    }
    if (data.containsKey('bedtime_sat_min')) {
      context.handle(
        _bedtimeSatMinMeta,
        bedtimeSatMin.isAcceptableOrUnknown(
          data['bedtime_sat_min']!,
          _bedtimeSatMinMeta,
        ),
      );
    }
    if (data.containsKey('wake_sun_min')) {
      context.handle(
        _wakeSunMinMeta,
        wakeSunMin.isAcceptableOrUnknown(
          data['wake_sun_min']!,
          _wakeSunMinMeta,
        ),
      );
    }
    if (data.containsKey('bedtime_sun_min')) {
      context.handle(
        _bedtimeSunMinMeta,
        bedtimeSunMin.isAcceptableOrUnknown(
          data['bedtime_sun_min']!,
          _bedtimeSunMinMeta,
        ),
      );
    }
    if (data.containsKey('meals_min')) {
      context.handle(
        _mealsMinMeta,
        mealsMin.isAcceptableOrUnknown(data['meals_min']!, _mealsMinMeta),
      );
    }
    if (data.containsKey('buffer_min')) {
      context.handle(
        _bufferMinMeta,
        bufferMin.isAcceptableOrUnknown(data['buffer_min']!, _bufferMinMeta),
      );
    }
    if (data.containsKey('focus_factor')) {
      context.handle(
        _focusFactorMeta,
        focusFactor.isAcceptableOrUnknown(
          data['focus_factor']!,
          _focusFactorMeta,
        ),
      );
    }
    if (data.containsKey('min_gap_min')) {
      context.handle(
        _minGapMinMeta,
        minGapMin.isAcceptableOrUnknown(data['min_gap_min']!, _minGapMinMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CapacityProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CapacityProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      sleepTargetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_target_min'],
      )!,
      sleepStartMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_start_min'],
      )!,
      wakeMonMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_mon_min'],
      )!,
      bedtimeMonMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_mon_min'],
      )!,
      wakeTueMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_tue_min'],
      )!,
      bedtimeTueMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_tue_min'],
      )!,
      wakeWedMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_wed_min'],
      )!,
      bedtimeWedMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_wed_min'],
      )!,
      wakeThuMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_thu_min'],
      )!,
      bedtimeThuMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_thu_min'],
      )!,
      wakeFriMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_fri_min'],
      )!,
      bedtimeFriMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_fri_min'],
      )!,
      wakeSatMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_sat_min'],
      )!,
      bedtimeSatMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_sat_min'],
      )!,
      wakeSunMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_sun_min'],
      )!,
      bedtimeSunMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bedtime_sun_min'],
      )!,
      mealsMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}meals_min'],
      )!,
      bufferMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buffer_min'],
      )!,
      focusFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}focus_factor'],
      )!,
      minGapMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_gap_min'],
      )!,
    );
  }

  @override
  $CapacityProfilesTable createAlias(String alias) {
    return $CapacityProfilesTable(attachedDatabase, alias);
  }
}

class CapacityProfile extends DataClass implements Insertable<CapacityProfile> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;

  /// The least sleep wanted in a night. Protected floor, not a resource: no code path may
  /// schedule into sleep or offer it as a way to make something fit, and nights shorter
  /// than this are reported.
  final int sleepTargetMin;

  /// When sleep began, before sleep was set per day. Kept so a version of the app from
  /// before then, still syncing, reads a sensible value; nothing current reads it.
  final int sleepStartMin;
  final int wakeMonMin;
  final int bedtimeMonMin;
  final int wakeTueMin;
  final int bedtimeTueMin;
  final int wakeWedMin;
  final int bedtimeWedMin;
  final int wakeThuMin;
  final int bedtimeThuMin;
  final int wakeFriMin;
  final int bedtimeFriMin;
  final int wakeSatMin;
  final int bedtimeSatMin;
  final int wakeSunMin;
  final int bedtimeSunMin;
  final int mealsMin;

  /// Transit, admin, life.
  final int bufferMin;

  /// Six free hours is not six hours of assignment. Tuned from completion data later.
  final double focusFactor;

  /// A gap shorter than this yields nothing usable. Fragmentation costs more than the
  /// raw minutes suggest, and pretending otherwise is how a day looks fine on paper and
  /// isn't.
  final int minGapMin;
  const CapacityProfile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.sleepTargetMin,
    required this.sleepStartMin,
    required this.wakeMonMin,
    required this.bedtimeMonMin,
    required this.wakeTueMin,
    required this.bedtimeTueMin,
    required this.wakeWedMin,
    required this.bedtimeWedMin,
    required this.wakeThuMin,
    required this.bedtimeThuMin,
    required this.wakeFriMin,
    required this.bedtimeFriMin,
    required this.wakeSatMin,
    required this.bedtimeSatMin,
    required this.wakeSunMin,
    required this.bedtimeSunMin,
    required this.mealsMin,
    required this.bufferMin,
    required this.focusFactor,
    required this.minGapMin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['sleep_target_min'] = Variable<int>(sleepTargetMin);
    map['sleep_start_min'] = Variable<int>(sleepStartMin);
    map['wake_mon_min'] = Variable<int>(wakeMonMin);
    map['bedtime_mon_min'] = Variable<int>(bedtimeMonMin);
    map['wake_tue_min'] = Variable<int>(wakeTueMin);
    map['bedtime_tue_min'] = Variable<int>(bedtimeTueMin);
    map['wake_wed_min'] = Variable<int>(wakeWedMin);
    map['bedtime_wed_min'] = Variable<int>(bedtimeWedMin);
    map['wake_thu_min'] = Variable<int>(wakeThuMin);
    map['bedtime_thu_min'] = Variable<int>(bedtimeThuMin);
    map['wake_fri_min'] = Variable<int>(wakeFriMin);
    map['bedtime_fri_min'] = Variable<int>(bedtimeFriMin);
    map['wake_sat_min'] = Variable<int>(wakeSatMin);
    map['bedtime_sat_min'] = Variable<int>(bedtimeSatMin);
    map['wake_sun_min'] = Variable<int>(wakeSunMin);
    map['bedtime_sun_min'] = Variable<int>(bedtimeSunMin);
    map['meals_min'] = Variable<int>(mealsMin);
    map['buffer_min'] = Variable<int>(bufferMin);
    map['focus_factor'] = Variable<double>(focusFactor);
    map['min_gap_min'] = Variable<int>(minGapMin);
    return map;
  }

  CapacityProfilesCompanion toCompanion(bool nullToAbsent) {
    return CapacityProfilesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      sleepTargetMin: Value(sleepTargetMin),
      sleepStartMin: Value(sleepStartMin),
      wakeMonMin: Value(wakeMonMin),
      bedtimeMonMin: Value(bedtimeMonMin),
      wakeTueMin: Value(wakeTueMin),
      bedtimeTueMin: Value(bedtimeTueMin),
      wakeWedMin: Value(wakeWedMin),
      bedtimeWedMin: Value(bedtimeWedMin),
      wakeThuMin: Value(wakeThuMin),
      bedtimeThuMin: Value(bedtimeThuMin),
      wakeFriMin: Value(wakeFriMin),
      bedtimeFriMin: Value(bedtimeFriMin),
      wakeSatMin: Value(wakeSatMin),
      bedtimeSatMin: Value(bedtimeSatMin),
      wakeSunMin: Value(wakeSunMin),
      bedtimeSunMin: Value(bedtimeSunMin),
      mealsMin: Value(mealsMin),
      bufferMin: Value(bufferMin),
      focusFactor: Value(focusFactor),
      minGapMin: Value(minGapMin),
    );
  }

  factory CapacityProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CapacityProfile(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      sleepTargetMin: serializer.fromJson<int>(json['sleepTargetMin']),
      sleepStartMin: serializer.fromJson<int>(json['sleepStartMin']),
      wakeMonMin: serializer.fromJson<int>(json['wakeMonMin']),
      bedtimeMonMin: serializer.fromJson<int>(json['bedtimeMonMin']),
      wakeTueMin: serializer.fromJson<int>(json['wakeTueMin']),
      bedtimeTueMin: serializer.fromJson<int>(json['bedtimeTueMin']),
      wakeWedMin: serializer.fromJson<int>(json['wakeWedMin']),
      bedtimeWedMin: serializer.fromJson<int>(json['bedtimeWedMin']),
      wakeThuMin: serializer.fromJson<int>(json['wakeThuMin']),
      bedtimeThuMin: serializer.fromJson<int>(json['bedtimeThuMin']),
      wakeFriMin: serializer.fromJson<int>(json['wakeFriMin']),
      bedtimeFriMin: serializer.fromJson<int>(json['bedtimeFriMin']),
      wakeSatMin: serializer.fromJson<int>(json['wakeSatMin']),
      bedtimeSatMin: serializer.fromJson<int>(json['bedtimeSatMin']),
      wakeSunMin: serializer.fromJson<int>(json['wakeSunMin']),
      bedtimeSunMin: serializer.fromJson<int>(json['bedtimeSunMin']),
      mealsMin: serializer.fromJson<int>(json['mealsMin']),
      bufferMin: serializer.fromJson<int>(json['bufferMin']),
      focusFactor: serializer.fromJson<double>(json['focusFactor']),
      minGapMin: serializer.fromJson<int>(json['minGapMin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'sleepTargetMin': serializer.toJson<int>(sleepTargetMin),
      'sleepStartMin': serializer.toJson<int>(sleepStartMin),
      'wakeMonMin': serializer.toJson<int>(wakeMonMin),
      'bedtimeMonMin': serializer.toJson<int>(bedtimeMonMin),
      'wakeTueMin': serializer.toJson<int>(wakeTueMin),
      'bedtimeTueMin': serializer.toJson<int>(bedtimeTueMin),
      'wakeWedMin': serializer.toJson<int>(wakeWedMin),
      'bedtimeWedMin': serializer.toJson<int>(bedtimeWedMin),
      'wakeThuMin': serializer.toJson<int>(wakeThuMin),
      'bedtimeThuMin': serializer.toJson<int>(bedtimeThuMin),
      'wakeFriMin': serializer.toJson<int>(wakeFriMin),
      'bedtimeFriMin': serializer.toJson<int>(bedtimeFriMin),
      'wakeSatMin': serializer.toJson<int>(wakeSatMin),
      'bedtimeSatMin': serializer.toJson<int>(bedtimeSatMin),
      'wakeSunMin': serializer.toJson<int>(wakeSunMin),
      'bedtimeSunMin': serializer.toJson<int>(bedtimeSunMin),
      'mealsMin': serializer.toJson<int>(mealsMin),
      'bufferMin': serializer.toJson<int>(bufferMin),
      'focusFactor': serializer.toJson<double>(focusFactor),
      'minGapMin': serializer.toJson<int>(minGapMin),
    };
  }

  CapacityProfile copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    int? sleepTargetMin,
    int? sleepStartMin,
    int? wakeMonMin,
    int? bedtimeMonMin,
    int? wakeTueMin,
    int? bedtimeTueMin,
    int? wakeWedMin,
    int? bedtimeWedMin,
    int? wakeThuMin,
    int? bedtimeThuMin,
    int? wakeFriMin,
    int? bedtimeFriMin,
    int? wakeSatMin,
    int? bedtimeSatMin,
    int? wakeSunMin,
    int? bedtimeSunMin,
    int? mealsMin,
    int? bufferMin,
    double? focusFactor,
    int? minGapMin,
  }) => CapacityProfile(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    sleepTargetMin: sleepTargetMin ?? this.sleepTargetMin,
    sleepStartMin: sleepStartMin ?? this.sleepStartMin,
    wakeMonMin: wakeMonMin ?? this.wakeMonMin,
    bedtimeMonMin: bedtimeMonMin ?? this.bedtimeMonMin,
    wakeTueMin: wakeTueMin ?? this.wakeTueMin,
    bedtimeTueMin: bedtimeTueMin ?? this.bedtimeTueMin,
    wakeWedMin: wakeWedMin ?? this.wakeWedMin,
    bedtimeWedMin: bedtimeWedMin ?? this.bedtimeWedMin,
    wakeThuMin: wakeThuMin ?? this.wakeThuMin,
    bedtimeThuMin: bedtimeThuMin ?? this.bedtimeThuMin,
    wakeFriMin: wakeFriMin ?? this.wakeFriMin,
    bedtimeFriMin: bedtimeFriMin ?? this.bedtimeFriMin,
    wakeSatMin: wakeSatMin ?? this.wakeSatMin,
    bedtimeSatMin: bedtimeSatMin ?? this.bedtimeSatMin,
    wakeSunMin: wakeSunMin ?? this.wakeSunMin,
    bedtimeSunMin: bedtimeSunMin ?? this.bedtimeSunMin,
    mealsMin: mealsMin ?? this.mealsMin,
    bufferMin: bufferMin ?? this.bufferMin,
    focusFactor: focusFactor ?? this.focusFactor,
    minGapMin: minGapMin ?? this.minGapMin,
  );
  CapacityProfile copyWithCompanion(CapacityProfilesCompanion data) {
    return CapacityProfile(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      sleepTargetMin: data.sleepTargetMin.present
          ? data.sleepTargetMin.value
          : this.sleepTargetMin,
      sleepStartMin: data.sleepStartMin.present
          ? data.sleepStartMin.value
          : this.sleepStartMin,
      wakeMonMin: data.wakeMonMin.present
          ? data.wakeMonMin.value
          : this.wakeMonMin,
      bedtimeMonMin: data.bedtimeMonMin.present
          ? data.bedtimeMonMin.value
          : this.bedtimeMonMin,
      wakeTueMin: data.wakeTueMin.present
          ? data.wakeTueMin.value
          : this.wakeTueMin,
      bedtimeTueMin: data.bedtimeTueMin.present
          ? data.bedtimeTueMin.value
          : this.bedtimeTueMin,
      wakeWedMin: data.wakeWedMin.present
          ? data.wakeWedMin.value
          : this.wakeWedMin,
      bedtimeWedMin: data.bedtimeWedMin.present
          ? data.bedtimeWedMin.value
          : this.bedtimeWedMin,
      wakeThuMin: data.wakeThuMin.present
          ? data.wakeThuMin.value
          : this.wakeThuMin,
      bedtimeThuMin: data.bedtimeThuMin.present
          ? data.bedtimeThuMin.value
          : this.bedtimeThuMin,
      wakeFriMin: data.wakeFriMin.present
          ? data.wakeFriMin.value
          : this.wakeFriMin,
      bedtimeFriMin: data.bedtimeFriMin.present
          ? data.bedtimeFriMin.value
          : this.bedtimeFriMin,
      wakeSatMin: data.wakeSatMin.present
          ? data.wakeSatMin.value
          : this.wakeSatMin,
      bedtimeSatMin: data.bedtimeSatMin.present
          ? data.bedtimeSatMin.value
          : this.bedtimeSatMin,
      wakeSunMin: data.wakeSunMin.present
          ? data.wakeSunMin.value
          : this.wakeSunMin,
      bedtimeSunMin: data.bedtimeSunMin.present
          ? data.bedtimeSunMin.value
          : this.bedtimeSunMin,
      mealsMin: data.mealsMin.present ? data.mealsMin.value : this.mealsMin,
      bufferMin: data.bufferMin.present ? data.bufferMin.value : this.bufferMin,
      focusFactor: data.focusFactor.present
          ? data.focusFactor.value
          : this.focusFactor,
      minGapMin: data.minGapMin.present ? data.minGapMin.value : this.minGapMin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CapacityProfile(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('sleepTargetMin: $sleepTargetMin, ')
          ..write('sleepStartMin: $sleepStartMin, ')
          ..write('wakeMonMin: $wakeMonMin, ')
          ..write('bedtimeMonMin: $bedtimeMonMin, ')
          ..write('wakeTueMin: $wakeTueMin, ')
          ..write('bedtimeTueMin: $bedtimeTueMin, ')
          ..write('wakeWedMin: $wakeWedMin, ')
          ..write('bedtimeWedMin: $bedtimeWedMin, ')
          ..write('wakeThuMin: $wakeThuMin, ')
          ..write('bedtimeThuMin: $bedtimeThuMin, ')
          ..write('wakeFriMin: $wakeFriMin, ')
          ..write('bedtimeFriMin: $bedtimeFriMin, ')
          ..write('wakeSatMin: $wakeSatMin, ')
          ..write('bedtimeSatMin: $bedtimeSatMin, ')
          ..write('wakeSunMin: $wakeSunMin, ')
          ..write('bedtimeSunMin: $bedtimeSunMin, ')
          ..write('mealsMin: $mealsMin, ')
          ..write('bufferMin: $bufferMin, ')
          ..write('focusFactor: $focusFactor, ')
          ..write('minGapMin: $minGapMin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    sleepTargetMin,
    sleepStartMin,
    wakeMonMin,
    bedtimeMonMin,
    wakeTueMin,
    bedtimeTueMin,
    wakeWedMin,
    bedtimeWedMin,
    wakeThuMin,
    bedtimeThuMin,
    wakeFriMin,
    bedtimeFriMin,
    wakeSatMin,
    bedtimeSatMin,
    wakeSunMin,
    bedtimeSunMin,
    mealsMin,
    bufferMin,
    focusFactor,
    minGapMin,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CapacityProfile &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.sleepTargetMin == this.sleepTargetMin &&
          other.sleepStartMin == this.sleepStartMin &&
          other.wakeMonMin == this.wakeMonMin &&
          other.bedtimeMonMin == this.bedtimeMonMin &&
          other.wakeTueMin == this.wakeTueMin &&
          other.bedtimeTueMin == this.bedtimeTueMin &&
          other.wakeWedMin == this.wakeWedMin &&
          other.bedtimeWedMin == this.bedtimeWedMin &&
          other.wakeThuMin == this.wakeThuMin &&
          other.bedtimeThuMin == this.bedtimeThuMin &&
          other.wakeFriMin == this.wakeFriMin &&
          other.bedtimeFriMin == this.bedtimeFriMin &&
          other.wakeSatMin == this.wakeSatMin &&
          other.bedtimeSatMin == this.bedtimeSatMin &&
          other.wakeSunMin == this.wakeSunMin &&
          other.bedtimeSunMin == this.bedtimeSunMin &&
          other.mealsMin == this.mealsMin &&
          other.bufferMin == this.bufferMin &&
          other.focusFactor == this.focusFactor &&
          other.minGapMin == this.minGapMin);
}

class CapacityProfilesCompanion extends UpdateCompanion<CapacityProfile> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<int> sleepTargetMin;
  final Value<int> sleepStartMin;
  final Value<int> wakeMonMin;
  final Value<int> bedtimeMonMin;
  final Value<int> wakeTueMin;
  final Value<int> bedtimeTueMin;
  final Value<int> wakeWedMin;
  final Value<int> bedtimeWedMin;
  final Value<int> wakeThuMin;
  final Value<int> bedtimeThuMin;
  final Value<int> wakeFriMin;
  final Value<int> bedtimeFriMin;
  final Value<int> wakeSatMin;
  final Value<int> bedtimeSatMin;
  final Value<int> wakeSunMin;
  final Value<int> bedtimeSunMin;
  final Value<int> mealsMin;
  final Value<int> bufferMin;
  final Value<double> focusFactor;
  final Value<int> minGapMin;
  final Value<int> rowid;
  const CapacityProfilesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.sleepTargetMin = const Value.absent(),
    this.sleepStartMin = const Value.absent(),
    this.wakeMonMin = const Value.absent(),
    this.bedtimeMonMin = const Value.absent(),
    this.wakeTueMin = const Value.absent(),
    this.bedtimeTueMin = const Value.absent(),
    this.wakeWedMin = const Value.absent(),
    this.bedtimeWedMin = const Value.absent(),
    this.wakeThuMin = const Value.absent(),
    this.bedtimeThuMin = const Value.absent(),
    this.wakeFriMin = const Value.absent(),
    this.bedtimeFriMin = const Value.absent(),
    this.wakeSatMin = const Value.absent(),
    this.bedtimeSatMin = const Value.absent(),
    this.wakeSunMin = const Value.absent(),
    this.bedtimeSunMin = const Value.absent(),
    this.mealsMin = const Value.absent(),
    this.bufferMin = const Value.absent(),
    this.focusFactor = const Value.absent(),
    this.minGapMin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CapacityProfilesCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    this.sleepTargetMin = const Value.absent(),
    this.sleepStartMin = const Value.absent(),
    this.wakeMonMin = const Value.absent(),
    this.bedtimeMonMin = const Value.absent(),
    this.wakeTueMin = const Value.absent(),
    this.bedtimeTueMin = const Value.absent(),
    this.wakeWedMin = const Value.absent(),
    this.bedtimeWedMin = const Value.absent(),
    this.wakeThuMin = const Value.absent(),
    this.bedtimeThuMin = const Value.absent(),
    this.wakeFriMin = const Value.absent(),
    this.bedtimeFriMin = const Value.absent(),
    this.wakeSatMin = const Value.absent(),
    this.bedtimeSatMin = const Value.absent(),
    this.wakeSunMin = const Value.absent(),
    this.bedtimeSunMin = const Value.absent(),
    this.mealsMin = const Value.absent(),
    this.bufferMin = const Value.absent(),
    this.focusFactor = const Value.absent(),
    this.minGapMin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId);
  static Insertable<CapacityProfile> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<int>? sleepTargetMin,
    Expression<int>? sleepStartMin,
    Expression<int>? wakeMonMin,
    Expression<int>? bedtimeMonMin,
    Expression<int>? wakeTueMin,
    Expression<int>? bedtimeTueMin,
    Expression<int>? wakeWedMin,
    Expression<int>? bedtimeWedMin,
    Expression<int>? wakeThuMin,
    Expression<int>? bedtimeThuMin,
    Expression<int>? wakeFriMin,
    Expression<int>? bedtimeFriMin,
    Expression<int>? wakeSatMin,
    Expression<int>? bedtimeSatMin,
    Expression<int>? wakeSunMin,
    Expression<int>? bedtimeSunMin,
    Expression<int>? mealsMin,
    Expression<int>? bufferMin,
    Expression<double>? focusFactor,
    Expression<int>? minGapMin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (sleepTargetMin != null) 'sleep_target_min': sleepTargetMin,
      if (sleepStartMin != null) 'sleep_start_min': sleepStartMin,
      if (wakeMonMin != null) 'wake_mon_min': wakeMonMin,
      if (bedtimeMonMin != null) 'bedtime_mon_min': bedtimeMonMin,
      if (wakeTueMin != null) 'wake_tue_min': wakeTueMin,
      if (bedtimeTueMin != null) 'bedtime_tue_min': bedtimeTueMin,
      if (wakeWedMin != null) 'wake_wed_min': wakeWedMin,
      if (bedtimeWedMin != null) 'bedtime_wed_min': bedtimeWedMin,
      if (wakeThuMin != null) 'wake_thu_min': wakeThuMin,
      if (bedtimeThuMin != null) 'bedtime_thu_min': bedtimeThuMin,
      if (wakeFriMin != null) 'wake_fri_min': wakeFriMin,
      if (bedtimeFriMin != null) 'bedtime_fri_min': bedtimeFriMin,
      if (wakeSatMin != null) 'wake_sat_min': wakeSatMin,
      if (bedtimeSatMin != null) 'bedtime_sat_min': bedtimeSatMin,
      if (wakeSunMin != null) 'wake_sun_min': wakeSunMin,
      if (bedtimeSunMin != null) 'bedtime_sun_min': bedtimeSunMin,
      if (mealsMin != null) 'meals_min': mealsMin,
      if (bufferMin != null) 'buffer_min': bufferMin,
      if (focusFactor != null) 'focus_factor': focusFactor,
      if (minGapMin != null) 'min_gap_min': minGapMin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CapacityProfilesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<int>? sleepTargetMin,
    Value<int>? sleepStartMin,
    Value<int>? wakeMonMin,
    Value<int>? bedtimeMonMin,
    Value<int>? wakeTueMin,
    Value<int>? bedtimeTueMin,
    Value<int>? wakeWedMin,
    Value<int>? bedtimeWedMin,
    Value<int>? wakeThuMin,
    Value<int>? bedtimeThuMin,
    Value<int>? wakeFriMin,
    Value<int>? bedtimeFriMin,
    Value<int>? wakeSatMin,
    Value<int>? bedtimeSatMin,
    Value<int>? wakeSunMin,
    Value<int>? bedtimeSunMin,
    Value<int>? mealsMin,
    Value<int>? bufferMin,
    Value<double>? focusFactor,
    Value<int>? minGapMin,
    Value<int>? rowid,
  }) {
    return CapacityProfilesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      sleepTargetMin: sleepTargetMin ?? this.sleepTargetMin,
      sleepStartMin: sleepStartMin ?? this.sleepStartMin,
      wakeMonMin: wakeMonMin ?? this.wakeMonMin,
      bedtimeMonMin: bedtimeMonMin ?? this.bedtimeMonMin,
      wakeTueMin: wakeTueMin ?? this.wakeTueMin,
      bedtimeTueMin: bedtimeTueMin ?? this.bedtimeTueMin,
      wakeWedMin: wakeWedMin ?? this.wakeWedMin,
      bedtimeWedMin: bedtimeWedMin ?? this.bedtimeWedMin,
      wakeThuMin: wakeThuMin ?? this.wakeThuMin,
      bedtimeThuMin: bedtimeThuMin ?? this.bedtimeThuMin,
      wakeFriMin: wakeFriMin ?? this.wakeFriMin,
      bedtimeFriMin: bedtimeFriMin ?? this.bedtimeFriMin,
      wakeSatMin: wakeSatMin ?? this.wakeSatMin,
      bedtimeSatMin: bedtimeSatMin ?? this.bedtimeSatMin,
      wakeSunMin: wakeSunMin ?? this.wakeSunMin,
      bedtimeSunMin: bedtimeSunMin ?? this.bedtimeSunMin,
      mealsMin: mealsMin ?? this.mealsMin,
      bufferMin: bufferMin ?? this.bufferMin,
      focusFactor: focusFactor ?? this.focusFactor,
      minGapMin: minGapMin ?? this.minGapMin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (sleepTargetMin.present) {
      map['sleep_target_min'] = Variable<int>(sleepTargetMin.value);
    }
    if (sleepStartMin.present) {
      map['sleep_start_min'] = Variable<int>(sleepStartMin.value);
    }
    if (wakeMonMin.present) {
      map['wake_mon_min'] = Variable<int>(wakeMonMin.value);
    }
    if (bedtimeMonMin.present) {
      map['bedtime_mon_min'] = Variable<int>(bedtimeMonMin.value);
    }
    if (wakeTueMin.present) {
      map['wake_tue_min'] = Variable<int>(wakeTueMin.value);
    }
    if (bedtimeTueMin.present) {
      map['bedtime_tue_min'] = Variable<int>(bedtimeTueMin.value);
    }
    if (wakeWedMin.present) {
      map['wake_wed_min'] = Variable<int>(wakeWedMin.value);
    }
    if (bedtimeWedMin.present) {
      map['bedtime_wed_min'] = Variable<int>(bedtimeWedMin.value);
    }
    if (wakeThuMin.present) {
      map['wake_thu_min'] = Variable<int>(wakeThuMin.value);
    }
    if (bedtimeThuMin.present) {
      map['bedtime_thu_min'] = Variable<int>(bedtimeThuMin.value);
    }
    if (wakeFriMin.present) {
      map['wake_fri_min'] = Variable<int>(wakeFriMin.value);
    }
    if (bedtimeFriMin.present) {
      map['bedtime_fri_min'] = Variable<int>(bedtimeFriMin.value);
    }
    if (wakeSatMin.present) {
      map['wake_sat_min'] = Variable<int>(wakeSatMin.value);
    }
    if (bedtimeSatMin.present) {
      map['bedtime_sat_min'] = Variable<int>(bedtimeSatMin.value);
    }
    if (wakeSunMin.present) {
      map['wake_sun_min'] = Variable<int>(wakeSunMin.value);
    }
    if (bedtimeSunMin.present) {
      map['bedtime_sun_min'] = Variable<int>(bedtimeSunMin.value);
    }
    if (mealsMin.present) {
      map['meals_min'] = Variable<int>(mealsMin.value);
    }
    if (bufferMin.present) {
      map['buffer_min'] = Variable<int>(bufferMin.value);
    }
    if (focusFactor.present) {
      map['focus_factor'] = Variable<double>(focusFactor.value);
    }
    if (minGapMin.present) {
      map['min_gap_min'] = Variable<int>(minGapMin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapacityProfilesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('sleepTargetMin: $sleepTargetMin, ')
          ..write('sleepStartMin: $sleepStartMin, ')
          ..write('wakeMonMin: $wakeMonMin, ')
          ..write('bedtimeMonMin: $bedtimeMonMin, ')
          ..write('wakeTueMin: $wakeTueMin, ')
          ..write('bedtimeTueMin: $bedtimeTueMin, ')
          ..write('wakeWedMin: $wakeWedMin, ')
          ..write('bedtimeWedMin: $bedtimeWedMin, ')
          ..write('wakeThuMin: $wakeThuMin, ')
          ..write('bedtimeThuMin: $bedtimeThuMin, ')
          ..write('wakeFriMin: $wakeFriMin, ')
          ..write('bedtimeFriMin: $bedtimeFriMin, ')
          ..write('wakeSatMin: $wakeSatMin, ')
          ..write('bedtimeSatMin: $bedtimeSatMin, ')
          ..write('wakeSunMin: $wakeSunMin, ')
          ..write('bedtimeSunMin: $bedtimeSunMin, ')
          ..write('mealsMin: $mealsMin, ')
          ..write('bufferMin: $bufferMin, ')
          ..write('focusFactor: $focusFactor, ')
          ..write('minGapMin: $minGapMin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommitmentsTable extends Commitments
    with TableInfo<$CommitmentsTable, Commitment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommitmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
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
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CommitmentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('classes'),
      ).withConverter<CommitmentKind>($CommitmentsTable.$converterkind);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    scheduleId,
    title,
    rrule,
    startMin,
    durationMin,
    location,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commitments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Commitment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
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
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    } else if (isInserting) {
      context.missing(_rruleMeta);
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    } else if (isInserting) {
      context.missing(_startMinMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Commitment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Commitment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      kind: $CommitmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
    );
  }

  @override
  $CommitmentsTable createAlias(String alias) {
    return $CommitmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CommitmentKind, String, String> $converterkind =
      const EnumNameConverter<CommitmentKind>(CommitmentKind.values);
}

class Commitment extends DataClass implements Insertable<Commitment> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;

  /// Which named set this block belongs to. Null means it predates schedules and is
  /// treated as belonging to the fallback.
  final String? scheduleId;
  final String title;

  /// Recurrence. Only `FREQ=WEEKLY` with `BYDAY` is understood today; see
  /// `capacity/recurrence.dart`, which rejects anything else rather than guessing.
  final String rrule;

  /// Minutes past midnight.
  final int startMin;
  final int durationMin;
  final String? location;
  final CommitmentKind kind;
  const Commitment({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    this.scheduleId,
    required this.title,
    required this.rrule,
    required this.startMin,
    required this.durationMin,
    this.location,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || scheduleId != null) {
      map['schedule_id'] = Variable<String>(scheduleId);
    }
    map['title'] = Variable<String>(title);
    map['rrule'] = Variable<String>(rrule);
    map['start_min'] = Variable<int>(startMin);
    map['duration_min'] = Variable<int>(durationMin);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    {
      map['kind'] = Variable<String>(
        $CommitmentsTable.$converterkind.toSql(kind),
      );
    }
    return map;
  }

  CommitmentsCompanion toCompanion(bool nullToAbsent) {
    return CommitmentsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      scheduleId: scheduleId == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleId),
      title: Value(title),
      rrule: Value(rrule),
      startMin: Value(startMin),
      durationMin: Value(durationMin),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      kind: Value(kind),
    );
  }

  factory Commitment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Commitment(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      scheduleId: serializer.fromJson<String?>(json['scheduleId']),
      title: serializer.fromJson<String>(json['title']),
      rrule: serializer.fromJson<String>(json['rrule']),
      startMin: serializer.fromJson<int>(json['startMin']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      location: serializer.fromJson<String?>(json['location']),
      kind: $CommitmentsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'scheduleId': serializer.toJson<String?>(scheduleId),
      'title': serializer.toJson<String>(title),
      'rrule': serializer.toJson<String>(rrule),
      'startMin': serializer.toJson<int>(startMin),
      'durationMin': serializer.toJson<int>(durationMin),
      'location': serializer.toJson<String?>(location),
      'kind': serializer.toJson<String>(
        $CommitmentsTable.$converterkind.toJson(kind),
      ),
    };
  }

  Commitment copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    Value<String?> scheduleId = const Value.absent(),
    String? title,
    String? rrule,
    int? startMin,
    int? durationMin,
    Value<String?> location = const Value.absent(),
    CommitmentKind? kind,
  }) => Commitment(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    scheduleId: scheduleId.present ? scheduleId.value : this.scheduleId,
    title: title ?? this.title,
    rrule: rrule ?? this.rrule,
    startMin: startMin ?? this.startMin,
    durationMin: durationMin ?? this.durationMin,
    location: location.present ? location.value : this.location,
    kind: kind ?? this.kind,
  );
  Commitment copyWithCompanion(CommitmentsCompanion data) {
    return Commitment(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      title: data.title.present ? data.title.value : this.title,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      location: data.location.present ? data.location.value : this.location,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Commitment(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('title: $title, ')
          ..write('rrule: $rrule, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('location: $location, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    scheduleId,
    title,
    rrule,
    startMin,
    durationMin,
    location,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Commitment &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.scheduleId == this.scheduleId &&
          other.title == this.title &&
          other.rrule == this.rrule &&
          other.startMin == this.startMin &&
          other.durationMin == this.durationMin &&
          other.location == this.location &&
          other.kind == this.kind);
}

class CommitmentsCompanion extends UpdateCompanion<Commitment> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String?> scheduleId;
  final Value<String> title;
  final Value<String> rrule;
  final Value<int> startMin;
  final Value<int> durationMin;
  final Value<String?> location;
  final Value<CommitmentKind> kind;
  final Value<int> rowid;
  const CommitmentsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.title = const Value.absent(),
    this.rrule = const Value.absent(),
    this.startMin = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.location = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommitmentsCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    this.scheduleId = const Value.absent(),
    required String title,
    required String rrule,
    required int startMin,
    required int durationMin,
    this.location = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title),
       rrule = Value(rrule),
       startMin = Value(startMin),
       durationMin = Value(durationMin);
  static Insertable<Commitment> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? scheduleId,
    Expression<String>? title,
    Expression<String>? rrule,
    Expression<int>? startMin,
    Expression<int>? durationMin,
    Expression<String>? location,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (title != null) 'title': title,
      if (rrule != null) 'rrule': rrule,
      if (startMin != null) 'start_min': startMin,
      if (durationMin != null) 'duration_min': durationMin,
      if (location != null) 'location': location,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommitmentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String?>? scheduleId,
    Value<String>? title,
    Value<String>? rrule,
    Value<int>? startMin,
    Value<int>? durationMin,
    Value<String?>? location,
    Value<CommitmentKind>? kind,
    Value<int>? rowid,
  }) {
    return CommitmentsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      rrule: rrule ?? this.rrule,
      startMin: startMin ?? this.startMin,
      durationMin: durationMin ?? this.durationMin,
      location: location ?? this.location,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CommitmentsTable.$converterkind.toSql(kind.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommitmentsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('title: $title, ')
          ..write('rrule: $rrule, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('location: $location, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FieldDefsTable extends FieldDefs
    with TableInfo<$FieldDefsTable, FieldDef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldDefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FieldType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FieldType>($FieldDefsTable.$convertertype);
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _showInlineMeta = const VerificationMeta(
    'showInline',
  );
  @override
  late final GeneratedColumn<bool> showInline = GeneratedColumn<bool>(
    'show_inline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_inline" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    boardId,
    name,
    type,
    optionsJson,
    orderKey,
    showInline,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_defs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldDef> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('show_inline')) {
      context.handle(
        _showInlineMeta,
        showInline.isAcceptableOrUnknown(data['show_inline']!, _showInlineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldDef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldDef(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $FieldDefsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
      showInline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_inline'],
      )!,
    );
  }

  @override
  $FieldDefsTable createAlias(String alias) {
    return $FieldDefsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FieldType, String, String> $convertertype =
      const EnumNameConverter<FieldType>(FieldType.values);
}

class FieldDef extends DataClass implements Insertable<FieldDef> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String boardId;
  final String name;
  final FieldType type;

  /// JSON array of choices, for [FieldType.select] and [FieldType.multiSelect].
  /// Each entry is `{"label": ..., "colour": ...}`.
  final String optionsJson;
  final String orderKey;

  /// Whether it appears as a column in list and board views, or only in the detail sheet.
  final bool showInline;
  const FieldDef({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.boardId,
    required this.name,
    required this.type,
    required this.optionsJson,
    required this.orderKey,
    required this.showInline,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['board_id'] = Variable<String>(boardId);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $FieldDefsTable.$convertertype.toSql(type),
      );
    }
    map['options_json'] = Variable<String>(optionsJson);
    map['order_key'] = Variable<String>(orderKey);
    map['show_inline'] = Variable<bool>(showInline);
    return map;
  }

  FieldDefsCompanion toCompanion(bool nullToAbsent) {
    return FieldDefsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      boardId: Value(boardId),
      name: Value(name),
      type: Value(type),
      optionsJson: Value(optionsJson),
      orderKey: Value(orderKey),
      showInline: Value(showInline),
    );
  }

  factory FieldDef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldDef(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      boardId: serializer.fromJson<String>(json['boardId']),
      name: serializer.fromJson<String>(json['name']),
      type: $FieldDefsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
      showInline: serializer.fromJson<bool>(json['showInline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'boardId': serializer.toJson<String>(boardId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $FieldDefsTable.$convertertype.toJson(type),
      ),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'orderKey': serializer.toJson<String>(orderKey),
      'showInline': serializer.toJson<bool>(showInline),
    };
  }

  FieldDef copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? boardId,
    String? name,
    FieldType? type,
    String? optionsJson,
    String? orderKey,
    bool? showInline,
  }) => FieldDef(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    boardId: boardId ?? this.boardId,
    name: name ?? this.name,
    type: type ?? this.type,
    optionsJson: optionsJson ?? this.optionsJson,
    orderKey: orderKey ?? this.orderKey,
    showInline: showInline ?? this.showInline,
  );
  FieldDef copyWithCompanion(FieldDefsCompanion data) {
    return FieldDef(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      showInline: data.showInline.present
          ? data.showInline.value
          : this.showInline,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldDef(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('orderKey: $orderKey, ')
          ..write('showInline: $showInline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    boardId,
    name,
    type,
    optionsJson,
    orderKey,
    showInline,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldDef &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.boardId == this.boardId &&
          other.name == this.name &&
          other.type == this.type &&
          other.optionsJson == this.optionsJson &&
          other.orderKey == this.orderKey &&
          other.showInline == this.showInline);
}

class FieldDefsCompanion extends UpdateCompanion<FieldDef> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> boardId;
  final Value<String> name;
  final Value<FieldType> type;
  final Value<String> optionsJson;
  final Value<String> orderKey;
  final Value<bool> showInline;
  final Value<int> rowid;
  const FieldDefsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.showInline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldDefsCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String boardId,
    required String name,
    required FieldType type,
    this.optionsJson = const Value.absent(),
    required String orderKey,
    this.showInline = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       boardId = Value(boardId),
       name = Value(name),
       type = Value(type),
       orderKey = Value(orderKey);
  static Insertable<FieldDef> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? boardId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? optionsJson,
    Expression<String>? orderKey,
    Expression<bool>? showInline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (boardId != null) 'board_id': boardId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (optionsJson != null) 'options_json': optionsJson,
      if (orderKey != null) 'order_key': orderKey,
      if (showInline != null) 'show_inline': showInline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldDefsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? boardId,
    Value<String>? name,
    Value<FieldType>? type,
    Value<String>? optionsJson,
    Value<String>? orderKey,
    Value<bool>? showInline,
    Value<int>? rowid,
  }) {
    return FieldDefsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      type: type ?? this.type,
      optionsJson: optionsJson ?? this.optionsJson,
      orderKey: orderKey ?? this.orderKey,
      showInline: showInline ?? this.showInline,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $FieldDefsTable.$convertertype.toSql(type.value),
      );
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (showInline.present) {
      map['show_inline'] = Variable<bool>(showInline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldDefsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('orderKey: $orderKey, ')
          ..write('showInline: $showInline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FieldValuesTable extends FieldValues
    with TableInfo<$FieldValuesTable, FieldValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _fieldIdMeta = const VerificationMeta(
    'fieldId',
  );
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
    'field_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES field_defs (id)',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    taskId,
    fieldId,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(
        _fieldIdMeta,
        fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldValue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      fieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $FieldValuesTable createAlias(String alias) {
    return $FieldValuesTable(attachedDatabase, alias);
  }
}

class FieldValue extends DataClass implements Insertable<FieldValue> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String taskId;
  final String fieldId;
  final String? value;
  const FieldValue({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.taskId,
    required this.fieldId,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['task_id'] = Variable<String>(taskId);
    map['field_id'] = Variable<String>(fieldId);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  FieldValuesCompanion toCompanion(bool nullToAbsent) {
    return FieldValuesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      taskId: Value(taskId),
      fieldId: Value(fieldId),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory FieldValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldValue(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      fieldId: serializer.fromJson<String>(json['fieldId']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'taskId': serializer.toJson<String>(taskId),
      'fieldId': serializer.toJson<String>(fieldId),
      'value': serializer.toJson<String?>(value),
    };
  }

  FieldValue copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? taskId,
    String? fieldId,
    Value<String?> value = const Value.absent(),
  }) => FieldValue(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    taskId: taskId ?? this.taskId,
    fieldId: fieldId ?? this.fieldId,
    value: value.present ? value.value : this.value,
  );
  FieldValue copyWithCompanion(FieldValuesCompanion data) {
    return FieldValue(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldValue(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    taskId,
    fieldId,
    value,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldValue &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.taskId == this.taskId &&
          other.fieldId == this.fieldId &&
          other.value == this.value);
}

class FieldValuesCompanion extends UpdateCompanion<FieldValue> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> taskId;
  final Value<String> fieldId;
  final Value<String?> value;
  final Value<int> rowid;
  const FieldValuesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FieldValuesCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String taskId,
    required String fieldId,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       taskId = Value(taskId),
       fieldId = Value(fieldId);
  static Insertable<FieldValue> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? taskId,
    Expression<String>? fieldId,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (taskId != null) 'task_id': taskId,
      if (fieldId != null) 'field_id': fieldId,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FieldValuesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? taskId,
    Value<String>? fieldId,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return FieldValuesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      taskId: taskId ?? this.taskId,
      fieldId: fieldId ?? this.fieldId,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldValuesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectViewsTable extends ProjectViews
    with TableInfo<$ProjectViewsTable, ProjectView> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectViewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ViewKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ViewKind>($ProjectViewsTable.$converterkind);
  static const VerificationMeta _filterJsonMeta = const VerificationMeta(
    'filterJson',
  );
  @override
  late final GeneratedColumn<String> filterJson = GeneratedColumn<String>(
    'filter_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _groupByMeta = const VerificationMeta(
    'groupBy',
  );
  @override
  late final GeneratedColumn<String> groupBy = GeneratedColumn<String>(
    'group_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    boardId,
    name,
    kind,
    filterJson,
    groupBy,
    orderKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_views';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectView> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('filter_json')) {
      context.handle(
        _filterJsonMeta,
        filterJson.isAcceptableOrUnknown(data['filter_json']!, _filterJsonMeta),
      );
    }
    if (data.containsKey('group_by')) {
      context.handle(
        _groupByMeta,
        groupBy.isAcceptableOrUnknown(data['group_by']!, _groupByMeta),
      );
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectView map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectView(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $ProjectViewsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      filterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_json'],
      )!,
      groupBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_by'],
      ),
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
    );
  }

  @override
  $ProjectViewsTable createAlias(String alias) {
    return $ProjectViewsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ViewKind, String, String> $converterkind =
      const EnumNameConverter<ViewKind>(ViewKind.values);
}

class ProjectView extends DataClass implements Insertable<ProjectView> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String boardId;
  final String name;
  final ViewKind kind;

  /// The query DSL: `{"status": "open", "labels": ["uni"], "due": "<=7d"}`.
  final String filterJson;

  /// Field id or built-in key ('list', 'priority', 'due') to group columns by in a
  /// board view.
  final String? groupBy;
  final String orderKey;
  const ProjectView({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.boardId,
    required this.name,
    required this.kind,
    required this.filterJson,
    this.groupBy,
    required this.orderKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['board_id'] = Variable<String>(boardId);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $ProjectViewsTable.$converterkind.toSql(kind),
      );
    }
    map['filter_json'] = Variable<String>(filterJson);
    if (!nullToAbsent || groupBy != null) {
      map['group_by'] = Variable<String>(groupBy);
    }
    map['order_key'] = Variable<String>(orderKey);
    return map;
  }

  ProjectViewsCompanion toCompanion(bool nullToAbsent) {
    return ProjectViewsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      boardId: Value(boardId),
      name: Value(name),
      kind: Value(kind),
      filterJson: Value(filterJson),
      groupBy: groupBy == null && nullToAbsent
          ? const Value.absent()
          : Value(groupBy),
      orderKey: Value(orderKey),
    );
  }

  factory ProjectView.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectView(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      boardId: serializer.fromJson<String>(json['boardId']),
      name: serializer.fromJson<String>(json['name']),
      kind: $ProjectViewsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      filterJson: serializer.fromJson<String>(json['filterJson']),
      groupBy: serializer.fromJson<String?>(json['groupBy']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'boardId': serializer.toJson<String>(boardId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $ProjectViewsTable.$converterkind.toJson(kind),
      ),
      'filterJson': serializer.toJson<String>(filterJson),
      'groupBy': serializer.toJson<String?>(groupBy),
      'orderKey': serializer.toJson<String>(orderKey),
    };
  }

  ProjectView copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? boardId,
    String? name,
    ViewKind? kind,
    String? filterJson,
    Value<String?> groupBy = const Value.absent(),
    String? orderKey,
  }) => ProjectView(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    boardId: boardId ?? this.boardId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    filterJson: filterJson ?? this.filterJson,
    groupBy: groupBy.present ? groupBy.value : this.groupBy,
    orderKey: orderKey ?? this.orderKey,
  );
  ProjectView copyWithCompanion(ProjectViewsCompanion data) {
    return ProjectView(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      filterJson: data.filterJson.present
          ? data.filterJson.value
          : this.filterJson,
      groupBy: data.groupBy.present ? data.groupBy.value : this.groupBy,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectView(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('filterJson: $filterJson, ')
          ..write('groupBy: $groupBy, ')
          ..write('orderKey: $orderKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    boardId,
    name,
    kind,
    filterJson,
    groupBy,
    orderKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectView &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.boardId == this.boardId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.filterJson == this.filterJson &&
          other.groupBy == this.groupBy &&
          other.orderKey == this.orderKey);
}

class ProjectViewsCompanion extends UpdateCompanion<ProjectView> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> boardId;
  final Value<String> name;
  final Value<ViewKind> kind;
  final Value<String> filterJson;
  final Value<String?> groupBy;
  final Value<String> orderKey;
  final Value<int> rowid;
  const ProjectViewsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.filterJson = const Value.absent(),
    this.groupBy = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectViewsCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String boardId,
    required String name,
    required ViewKind kind,
    this.filterJson = const Value.absent(),
    this.groupBy = const Value.absent(),
    required String orderKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       boardId = Value(boardId),
       name = Value(name),
       kind = Value(kind),
       orderKey = Value(orderKey);
  static Insertable<ProjectView> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? boardId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? filterJson,
    Expression<String>? groupBy,
    Expression<String>? orderKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (boardId != null) 'board_id': boardId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (filterJson != null) 'filter_json': filterJson,
      if (groupBy != null) 'group_by': groupBy,
      if (orderKey != null) 'order_key': orderKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectViewsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? boardId,
    Value<String>? name,
    Value<ViewKind>? kind,
    Value<String>? filterJson,
    Value<String?>? groupBy,
    Value<String>? orderKey,
    Value<int>? rowid,
  }) {
    return ProjectViewsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      filterJson: filterJson ?? this.filterJson,
      groupBy: groupBy ?? this.groupBy,
      orderKey: orderKey ?? this.orderKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ProjectViewsTable.$converterkind.toSql(kind.value),
      );
    }
    if (filterJson.present) {
      map['filter_json'] = Variable<String>(filterJson.value);
    }
    if (groupBy.present) {
      map['group_by'] = Variable<String>(groupBy.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectViewsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('boardId: $boardId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('filterJson: $filterJson, ')
          ..write('groupBy: $groupBy, ')
          ..write('orderKey: $orderKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, TimetableSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldVersionsMeta = const VerificationMeta(
    'fieldVersions',
  );
  @override
  late final GeneratedColumn<String> fieldVersions = GeneratedColumn<String>(
    'field_versions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsOnMeta = const VerificationMeta(
    'startsOn',
  );
  @override
  late final GeneratedColumn<String> startsOn = GeneratedColumn<String>(
    'starts_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<String> endsOn = GeneratedColumn<String>(
    'ends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFallbackMeta = const VerificationMeta(
    'isFallback',
  );
  @override
  late final GeneratedColumn<bool> isFallback = GeneratedColumn<bool>(
    'is_fallback',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fallback" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    name,
    startsOn,
    endsOn,
    isFallback,
    orderKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimetableSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('field_versions')) {
      context.handle(
        _fieldVersionsMeta,
        fieldVersions.isAcceptableOrUnknown(
          data['field_versions']!,
          _fieldVersionsMeta,
        ),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('starts_on')) {
      context.handle(
        _startsOnMeta,
        startsOn.isAcceptableOrUnknown(data['starts_on']!, _startsOnMeta),
      );
    }
    if (data.containsKey('ends_on')) {
      context.handle(
        _endsOnMeta,
        endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta),
      );
    }
    if (data.containsKey('is_fallback')) {
      context.handle(
        _isFallbackMeta,
        isFallback.isAcceptableOrUnknown(data['is_fallback']!, _isFallbackMeta),
      );
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimetableSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimetableSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      fieldVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_versions'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts_on'],
      ),
      endsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_on'],
      ),
      isFallback: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fallback'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }
}

class TimetableSet extends DataClass implements Insertable<TimetableSet> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone. Rows are never hard-deleted while they might still sync.
  final DateTime? deletedAt;

  /// Which device last wrote this row. Also the tiebreaker for equal [orderKey] values,
  /// which two offline clients can genuinely produce.
  final String? clientId;

  /// JSON map of field name -> hybrid logical clock.
  final String fieldVersions;
  final String workspaceId;
  final String name;

  /// Inclusive bounds as 'YYYY-MM-DD'. Text rather than timestamps for the same reason
  /// all-day dates are: a semester starts on a date, not at an instant in a timezone.
  final String? startsOn;
  final String? endsOn;

  /// Applies to any day no dated set covers — the between-terms default.
  final bool isFallback;
  final String orderKey;
  const TimetableSet({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.clientId,
    required this.fieldVersions,
    required this.workspaceId,
    required this.name,
    this.startsOn,
    this.endsOn,
    required this.isFallback,
    required this.orderKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['field_versions'] = Variable<String>(fieldVersions);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || startsOn != null) {
      map['starts_on'] = Variable<String>(startsOn);
    }
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<String>(endsOn);
    }
    map['is_fallback'] = Variable<bool>(isFallback);
    map['order_key'] = Variable<String>(orderKey);
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      fieldVersions: Value(fieldVersions),
      workspaceId: Value(workspaceId),
      name: Value(name),
      startsOn: startsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(startsOn),
      endsOn: endsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endsOn),
      isFallback: Value(isFallback),
      orderKey: Value(orderKey),
    );
  }

  factory TimetableSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimetableSet(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      fieldVersions: serializer.fromJson<String>(json['fieldVersions']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      startsOn: serializer.fromJson<String?>(json['startsOn']),
      endsOn: serializer.fromJson<String?>(json['endsOn']),
      isFallback: serializer.fromJson<bool>(json['isFallback']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientId': serializer.toJson<String?>(clientId),
      'fieldVersions': serializer.toJson<String>(fieldVersions),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'startsOn': serializer.toJson<String?>(startsOn),
      'endsOn': serializer.toJson<String?>(endsOn),
      'isFallback': serializer.toJson<bool>(isFallback),
      'orderKey': serializer.toJson<String>(orderKey),
    };
  }

  TimetableSet copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    String? fieldVersions,
    String? workspaceId,
    String? name,
    Value<String?> startsOn = const Value.absent(),
    Value<String?> endsOn = const Value.absent(),
    bool? isFallback,
    String? orderKey,
  }) => TimetableSet(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientId: clientId.present ? clientId.value : this.clientId,
    fieldVersions: fieldVersions ?? this.fieldVersions,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    startsOn: startsOn.present ? startsOn.value : this.startsOn,
    endsOn: endsOn.present ? endsOn.value : this.endsOn,
    isFallback: isFallback ?? this.isFallback,
    orderKey: orderKey ?? this.orderKey,
  );
  TimetableSet copyWithCompanion(SchedulesCompanion data) {
    return TimetableSet(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      fieldVersions: data.fieldVersions.present
          ? data.fieldVersions.value
          : this.fieldVersions,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      startsOn: data.startsOn.present ? data.startsOn.value : this.startsOn,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      isFallback: data.isFallback.present
          ? data.isFallback.value
          : this.isFallback,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimetableSet(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('isFallback: $isFallback, ')
          ..write('orderKey: $orderKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    clientId,
    fieldVersions,
    workspaceId,
    name,
    startsOn,
    endsOn,
    isFallback,
    orderKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimetableSet &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientId == this.clientId &&
          other.fieldVersions == this.fieldVersions &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.startsOn == this.startsOn &&
          other.endsOn == this.endsOn &&
          other.isFallback == this.isFallback &&
          other.orderKey == this.orderKey);
}

class SchedulesCompanion extends UpdateCompanion<TimetableSet> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> clientId;
  final Value<String> fieldVersions;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String?> startsOn;
  final Value<String?> endsOn;
  final Value<bool> isFallback;
  final Value<String> orderKey;
  final Value<int> rowid;
  const SchedulesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.isFallback = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulesCompanion.insert({
    required String id,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientId = const Value.absent(),
    this.fieldVersions = const Value.absent(),
    required String workspaceId,
    required String name,
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.isFallback = const Value.absent(),
    required String orderKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name),
       orderKey = Value(orderKey);
  static Insertable<TimetableSet> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? clientId,
    Expression<String>? fieldVersions,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? startsOn,
    Expression<String>? endsOn,
    Expression<bool>? isFallback,
    Expression<String>? orderKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientId != null) 'client_id': clientId,
      if (fieldVersions != null) 'field_versions': fieldVersions,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (startsOn != null) 'starts_on': startsOn,
      if (endsOn != null) 'ends_on': endsOn,
      if (isFallback != null) 'is_fallback': isFallback,
      if (orderKey != null) 'order_key': orderKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedulesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? clientId,
    Value<String>? fieldVersions,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String?>? startsOn,
    Value<String?>? endsOn,
    Value<bool>? isFallback,
    Value<String>? orderKey,
    Value<int>? rowid,
  }) {
    return SchedulesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      fieldVersions: fieldVersions ?? this.fieldVersions,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      isFallback: isFallback ?? this.isFallback,
      orderKey: orderKey ?? this.orderKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (fieldVersions.present) {
      map['field_versions'] = Variable<String>(fieldVersions.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startsOn.present) {
      map['starts_on'] = Variable<String>(startsOn.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<String>(endsOn.value);
    }
    if (isFallback.present) {
      map['is_fallback'] = Variable<bool>(isFallback.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientId: $clientId, ')
          ..write('fieldVersions: $fieldVersions, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('isFallback: $isFallback, ')
          ..write('orderKey: $orderKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $BoardsTable boards = $BoardsTable(this);
  late final $ListsTable lists = $ListsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $LabelsTable labels = $LabelsTable(this);
  late final $TaskLabelsTable taskLabels = $TaskLabelsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $CapacityProfilesTable capacityProfiles = $CapacityProfilesTable(
    this,
  );
  late final $CommitmentsTable commitments = $CommitmentsTable(this);
  late final $FieldDefsTable fieldDefs = $FieldDefsTable(this);
  late final $FieldValuesTable fieldValues = $FieldValuesTable(this);
  late final $ProjectViewsTable projectViews = $ProjectViewsTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final Index boardWorkspace = Index(
    'board_workspace',
    'CREATE INDEX board_workspace ON boards (workspace_id)',
  );
  late final Index listBoard = Index(
    'list_board',
    'CREATE INDEX list_board ON lists (board_id)',
  );
  late final Index taskListOrder = Index(
    'task_list_order',
    'CREATE INDEX task_list_order ON tasks (list_id, order_key)',
  );
  late final Index taskWorkspaceDue = Index(
    'task_workspace_due',
    'CREATE INDEX task_workspace_due ON tasks (workspace_id, due_at)',
  );
  late final Index taskWorkspaceUpdated = Index(
    'task_workspace_updated',
    'CREATE INDEX task_workspace_updated ON tasks (workspace_id, updated_at)',
  );
  late final Index subtaskTaskOrder = Index(
    'subtask_task_order',
    'CREATE INDEX subtask_task_order ON subtasks (task_id, order_key)',
  );
  late final Index tasklabelLabel = Index(
    'tasklabel_label',
    'CREATE INDEX tasklabel_label ON task_labels (label_id)',
  );
  late final Index commitmentWorkspace = Index(
    'commitment_workspace',
    'CREATE INDEX commitment_workspace ON commitments (workspace_id)',
  );
  late final Index fielddefBoard = Index(
    'fielddef_board',
    'CREATE INDEX fielddef_board ON field_defs (board_id)',
  );
  late final Index fieldvalueTask = Index(
    'fieldvalue_task',
    'CREATE INDEX fieldvalue_task ON field_values (task_id)',
  );
  late final Index fieldvalueField = Index(
    'fieldvalue_field',
    'CREATE INDEX fieldvalue_field ON field_values (field_id)',
  );
  late final Index projectviewBoard = Index(
    'projectview_board',
    'CREATE INDEX projectview_board ON project_views (board_id)',
  );
  late final Index scheduleWorkspace = Index(
    'schedule_workspace',
    'CREATE INDEX schedule_workspace ON schedules (workspace_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    boards,
    lists,
    tasks,
    subtasks,
    labels,
    taskLabels,
    notes,
    outbox,
    localSettings,
    capacityProfiles,
    commitments,
    fieldDefs,
    fieldValues,
    projectViews,
    schedules,
    boardWorkspace,
    listBoard,
    taskListOrder,
    taskWorkspaceDue,
    taskWorkspaceUpdated,
    subtaskTaskOrder,
    tasklabelLabel,
    commitmentWorkspace,
    fielddefBoard,
    fieldvalueTask,
    fieldvalueField,
    projectviewBoard,
    scheduleWorkspace,
  ];
}

typedef $$WorkspacesTableCreateCompanionBuilder = WorkspacesCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String name,
  Value<int> rowid,
});
typedef $$WorkspacesTableUpdateCompanionBuilder = WorkspacesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> name,
  Value<int> rowid,
});

class $$WorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspacesTable,
          Workspace,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (
            Workspace,
            BaseReferences<_$AppDatabase, $WorkspacesTable, Workspace>,
          ),
          Workspace,
          PrefetchHooks Function()
        > {
  $$WorkspacesTableTableManager(_$AppDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkspacesTable, Workspace>(table),
                  BaseReferences<_$AppDatabase, $WorkspacesTable, Workspace>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspacesTable,
      Workspace,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (Workspace, BaseReferences<_$AppDatabase, $WorkspacesTable, Workspace>),
      Workspace,
      PrefetchHooks Function()
    >;
typedef $$BoardsTableCreateCompanionBuilder = BoardsCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String name,
  Value<String?> purpose,
  Value<String?> icon,
  Value<int?> colour,
  Value<bool> archived,
  Value<BoardView> viewDefault,
  required String orderKey,
  Value<int> rowid,
});
typedef $$BoardsTableUpdateCompanionBuilder = BoardsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> name,
  Value<String?> purpose,
  Value<String?> icon,
  Value<int?> colour,
  Value<bool> archived,
  Value<BoardView> viewDefault,
  Value<String> orderKey,
  Value<int> rowid,
});

final class $$BoardsTableReferences
    extends BaseReferences<_$AppDatabase, $BoardsTable, Board> {
  $$BoardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ListsTable, List<BoardList>> _listsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.lists,
    aliasName: 'boards__id__lists__board_id',
  );

  $$ListsTableProcessedTableManager get listsRefs {
    final manager = $$ListsTableTableManager(
      $_db,
      $_db.lists,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_listsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FieldDefsTable, List<FieldDef>>
  _fieldDefsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fieldDefs,
    aliasName: 'boards__id__field_defs__board_id',
  );

  $$FieldDefsTableProcessedTableManager get fieldDefsRefs {
    final manager = $$FieldDefsTableTableManager(
      $_db,
      $_db.fieldDefs,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fieldDefsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProjectViewsTable, List<ProjectView>>
  _projectViewsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.projectViews,
    aliasName: 'boards__id__project_views__board_id',
  );

  $$ProjectViewsTableProcessedTableManager get projectViewsRefs {
    final manager = $$ProjectViewsTableTableManager(
      $_db,
      $_db.projectViews,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_projectViewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoardsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BoardView, BoardView, String>
  get viewDefault => $composableBuilder(
    column: $table.viewDefault,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> listsRefs(
    Expression<bool> Function($$ListsTableFilterComposer f) f,
  ) {
    final $$ListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableFilterComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fieldDefsRefs(
    Expression<bool> Function($$FieldDefsTableFilterComposer f) f,
  ) {
    final $$FieldDefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldDefs,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldDefsTableFilterComposer(
            $db: $db,
            $table: $db.fieldDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> projectViewsRefs(
    Expression<bool> Function($$ProjectViewsTableFilterComposer f) f,
  ) {
    final $$ProjectViewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectViews,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectViewsTableFilterComposer(
            $db: $db,
            $table: $db.projectViews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewDefault => $composableBuilder(
    column: $table.viewDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BoardView, String> get viewDefault =>
      $composableBuilder(
        column: $table.viewDefault,
        builder: (column) => column,
      );

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  Expression<T> listsRefs<T extends Object>(
    Expression<T> Function($$ListsTableAnnotationComposer a) f,
  ) {
    final $$ListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableAnnotationComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fieldDefsRefs<T extends Object>(
    Expression<T> Function($$FieldDefsTableAnnotationComposer a) f,
  ) {
    final $$FieldDefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldDefs,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldDefsTableAnnotationComposer(
            $db: $db,
            $table: $db.fieldDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> projectViewsRefs<T extends Object>(
    Expression<T> Function($$ProjectViewsTableAnnotationComposer a) f,
  ) {
    final $$ProjectViewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectViews,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectViewsTableAnnotationComposer(
            $db: $db,
            $table: $db.projectViews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardsTable,
          Board,
          $$BoardsTableFilterComposer,
          $$BoardsTableOrderingComposer,
          $$BoardsTableAnnotationComposer,
          $$BoardsTableCreateCompanionBuilder,
          $$BoardsTableUpdateCompanionBuilder,
          (Board, $$BoardsTableReferences),
          Board,
          PrefetchHooks Function({
            bool listsRefs,
            bool fieldDefsRefs,
            bool projectViewsRefs,
          })
        > {
  $$BoardsTableTableManager(_$AppDatabase db, $BoardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> purpose = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> colour = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<BoardView> viewDefault = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                name: name,
                purpose: purpose,
                icon: icon,
                colour: colour,
                archived: archived,
                viewDefault: viewDefault,
                orderKey: orderKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String name,
                Value<String?> purpose = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> colour = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<BoardView> viewDefault = const Value.absent(),
                required String orderKey,
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                name: name,
                purpose: purpose,
                icon: icon,
                colour: colour,
                archived: archived,
                viewDefault: viewDefault,
                orderKey: orderKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardsTable, Board>(table),
                  $$BoardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                listsRefs = false,
                fieldDefsRefs = false,
                projectViewsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (listsRefs) db.lists,
                    if (fieldDefsRefs) db.fieldDefs,
                    if (projectViewsRefs) db.projectViews,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (listsRefs)
                        await $_getPrefetchedData<
                          Board,
                          $BoardsTable,
                          BoardList
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._listsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(db, table, p0).listsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fieldDefsRefs)
                        await $_getPrefetchedData<
                          Board,
                          $BoardsTable,
                          FieldDef
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._fieldDefsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).fieldDefsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (projectViewsRefs)
                        await $_getPrefetchedData<
                          Board,
                          $BoardsTable,
                          ProjectView
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._projectViewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).projectViewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BoardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardsTable,
      Board,
      $$BoardsTableFilterComposer,
      $$BoardsTableOrderingComposer,
      $$BoardsTableAnnotationComposer,
      $$BoardsTableCreateCompanionBuilder,
      $$BoardsTableUpdateCompanionBuilder,
      (Board, $$BoardsTableReferences),
      Board,
      PrefetchHooks Function({
        bool listsRefs,
        bool fieldDefsRefs,
        bool projectViewsRefs,
      })
    >;
typedef $$ListsTableCreateCompanionBuilder = ListsCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String boardId,
  required String name,
  required String orderKey,
  Value<int?> wipLimit,
  Value<bool> isDoneColumn,
  Value<int> rowid,
});
typedef $$ListsTableUpdateCompanionBuilder = ListsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> boardId,
  Value<String> name,
  Value<String> orderKey,
  Value<int?> wipLimit,
  Value<bool> isDoneColumn,
  Value<int> rowid,
});

final class $$ListsTableReferences
    extends BaseReferences<_$AppDatabase, $ListsTable, BoardList> {
  $$ListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('lists__board_id__boards__id');

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'lists__id__tasks__list_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ListsTableFilterComposer extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wipLimit => $composableBuilder(
    column: $table.wipLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDoneColumn => $composableBuilder(
    column: $table.isDoneColumn,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wipLimit => $composableBuilder(
    column: $table.wipLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDoneColumn => $composableBuilder(
    column: $table.isDoneColumn,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<int> get wipLimit =>
      $composableBuilder(column: $table.wipLimit, builder: (column) => column);

  GeneratedColumn<bool> get isDoneColumn => $composableBuilder(
    column: $table.isDoneColumn,
    builder: (column) => column,
  );

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListsTable,
          BoardList,
          $$ListsTableFilterComposer,
          $$ListsTableOrderingComposer,
          $$ListsTableAnnotationComposer,
          $$ListsTableCreateCompanionBuilder,
          $$ListsTableUpdateCompanionBuilder,
          (BoardList, $$ListsTableReferences),
          BoardList,
          PrefetchHooks Function({bool boardId, bool tasksRefs})
        > {
  $$ListsTableTableManager(_$AppDatabase db, $ListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<int?> wipLimit = const Value.absent(),
                Value<bool> isDoneColumn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                boardId: boardId,
                name: name,
                orderKey: orderKey,
                wipLimit: wipLimit,
                isDoneColumn: isDoneColumn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String boardId,
                required String name,
                required String orderKey,
                Value<int?> wipLimit = const Value.absent(),
                Value<bool> isDoneColumn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                boardId: boardId,
                name: name,
                orderKey: orderKey,
                wipLimit: wipLimit,
                isDoneColumn: isDoneColumn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListsTable, BoardList>(table),
                  $$ListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boardId = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boardId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.boardId,
                        referencedTable: $$ListsTableReferences._boardIdTable(
                          db,
                        ),
                        referencedColumn: $$ListsTableReferences
                            ._boardIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<BoardList, $ListsTable, Task>(
                      currentTable: table,
                      referencedTable: $$ListsTableReferences._tasksRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$ListsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListsTable,
      BoardList,
      $$ListsTableFilterComposer,
      $$ListsTableOrderingComposer,
      $$ListsTableAnnotationComposer,
      $$ListsTableCreateCompanionBuilder,
      $$ListsTableUpdateCompanionBuilder,
      (BoardList, $$ListsTableReferences),
      BoardList,
      PrefetchHooks Function({bool boardId, bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String listId,
  required String title,
  Value<String?> notesMd,
  required String orderKey,
  Value<TaskStatus> status,
  Value<int> priority,
  Value<DateTime?> dueAt,
  Value<String?> dueDate,
  Value<DateTime?> startAt,
  Value<DateTime?> completedAt,
  Value<String?> rrule,
  Value<String?> parentTaskId,
  Value<int?> estimateMin,
  Value<int?> actualMin,
  Value<String?> scheduledFor,
  Value<int> slipCount,
  Value<DateTime?> lastDeferredAt,
  Value<DateTime?> remindAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> listId,
  Value<String> title,
  Value<String?> notesMd,
  Value<String> orderKey,
  Value<TaskStatus> status,
  Value<int> priority,
  Value<DateTime?> dueAt,
  Value<String?> dueDate,
  Value<DateTime?> startAt,
  Value<DateTime?> completedAt,
  Value<String?> rrule,
  Value<String?> parentTaskId,
  Value<int?> estimateMin,
  Value<int?> actualMin,
  Value<String?> scheduledFor,
  Value<int> slipCount,
  Value<DateTime?> lastDeferredAt,
  Value<DateTime?> remindAt,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ListsTable _listIdTable(_$AppDatabase db) =>
      db.lists.createAlias('tasks__list_id__lists__id');

  $$ListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$ListsTableTableManager(
      $_db,
      $_db.lists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SubtasksTable, List<Subtask>> _subtasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.subtasks,
    aliasName: 'tasks__id__subtasks__task_id',
  );

  $$SubtasksTableProcessedTableManager get subtasksRefs {
    final manager = $$SubtasksTableTableManager(
      $_db,
      $_db.subtasks,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_subtasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskLabelsTable, List<TaskLabel>>
  _taskLabelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskLabels,
    aliasName: 'tasks__id__task_labels__task_id',
  );

  $$TaskLabelsTableProcessedTableManager get taskLabelsRefs {
    final manager = $$TaskLabelsTableTableManager(
      $_db,
      $_db.taskLabels,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskLabelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FieldValuesTable, List<FieldValue>>
  _fieldValuesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fieldValues,
    aliasName: 'tasks__id__field_values__task_id',
  );

  $$FieldValuesTableProcessedTableManager get fieldValuesRefs {
    final manager = $$FieldValuesTableTableManager(
      $_db,
      $_db.fieldValues,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fieldValuesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notesMd => $composableBuilder(
    column: $table.notesMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateMin => $composableBuilder(
    column: $table.estimateMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMin => $composableBuilder(
    column: $table.actualMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slipCount => $composableBuilder(
    column: $table.slipCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastDeferredAt => $composableBuilder(
    column: $table.lastDeferredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ListsTableFilterComposer get listId {
    final $$ListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableFilterComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> subtasksRefs(
    Expression<bool> Function($$SubtasksTableFilterComposer f) f,
  ) {
    final $$SubtasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableFilterComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskLabelsRefs(
    Expression<bool> Function($$TaskLabelsTableFilterComposer f) f,
  ) {
    final $$TaskLabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskLabels,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskLabelsTableFilterComposer(
            $db: $db,
            $table: $db.taskLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fieldValuesRefs(
    Expression<bool> Function($$FieldValuesTableFilterComposer f) f,
  ) {
    final $$FieldValuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldValues,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldValuesTableFilterComposer(
            $db: $db,
            $table: $db.fieldValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notesMd => $composableBuilder(
    column: $table.notesMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateMin => $composableBuilder(
    column: $table.estimateMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMin => $composableBuilder(
    column: $table.actualMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slipCount => $composableBuilder(
    column: $table.slipCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastDeferredAt => $composableBuilder(
    column: $table.lastDeferredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ListsTableOrderingComposer get listId {
    final $$ListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableOrderingComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notesMd =>
      $composableBuilder(column: $table.notesMd, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateMin => $composableBuilder(
    column: $table.estimateMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualMin =>
      $composableBuilder(column: $table.actualMin, builder: (column) => column);

  GeneratedColumn<String> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get slipCount =>
      $composableBuilder(column: $table.slipCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastDeferredAt => $composableBuilder(
    column: $table.lastDeferredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  $$ListsTableAnnotationComposer get listId {
    final $$ListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableAnnotationComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> subtasksRefs<T extends Object>(
    Expression<T> Function($$SubtasksTableAnnotationComposer a) f,
  ) {
    final $$SubtasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subtasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubtasksTableAnnotationComposer(
            $db: $db,
            $table: $db.subtasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskLabelsRefs<T extends Object>(
    Expression<T> Function($$TaskLabelsTableAnnotationComposer a) f,
  ) {
    final $$TaskLabelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskLabels,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskLabelsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fieldValuesRefs<T extends Object>(
    Expression<T> Function($$FieldValuesTableAnnotationComposer a) f,
  ) {
    final $$FieldValuesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldValues,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldValuesTableAnnotationComposer(
            $db: $db,
            $table: $db.fieldValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool listId,
            bool subtasksRefs,
            bool taskLabelsRefs,
            bool fieldValuesRefs,
          })
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notesMd = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<int?> estimateMin = const Value.absent(),
                Value<int?> actualMin = const Value.absent(),
                Value<String?> scheduledFor = const Value.absent(),
                Value<int> slipCount = const Value.absent(),
                Value<DateTime?> lastDeferredAt = const Value.absent(),
                Value<DateTime?> remindAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                listId: listId,
                title: title,
                notesMd: notesMd,
                orderKey: orderKey,
                status: status,
                priority: priority,
                dueAt: dueAt,
                dueDate: dueDate,
                startAt: startAt,
                completedAt: completedAt,
                rrule: rrule,
                parentTaskId: parentTaskId,
                estimateMin: estimateMin,
                actualMin: actualMin,
                scheduledFor: scheduledFor,
                slipCount: slipCount,
                lastDeferredAt: lastDeferredAt,
                remindAt: remindAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String listId,
                required String title,
                Value<String?> notesMd = const Value.absent(),
                required String orderKey,
                Value<TaskStatus> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<int?> estimateMin = const Value.absent(),
                Value<int?> actualMin = const Value.absent(),
                Value<String?> scheduledFor = const Value.absent(),
                Value<int> slipCount = const Value.absent(),
                Value<DateTime?> lastDeferredAt = const Value.absent(),
                Value<DateTime?> remindAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                listId: listId,
                title: title,
                notesMd: notesMd,
                orderKey: orderKey,
                status: status,
                priority: priority,
                dueAt: dueAt,
                dueDate: dueDate,
                startAt: startAt,
                completedAt: completedAt,
                rrule: rrule,
                parentTaskId: parentTaskId,
                estimateMin: estimateMin,
                actualMin: actualMin,
                scheduledFor: scheduledFor,
                slipCount: slipCount,
                lastDeferredAt: lastDeferredAt,
                remindAt: remindAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                listId = false,
                subtasksRefs = false,
                taskLabelsRefs = false,
                fieldValuesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subtasksRefs) db.subtasks,
                    if (taskLabelsRefs) db.taskLabels,
                    if (fieldValuesRefs) db.fieldValues,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (listId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.listId,
                            referencedTable: $$TasksTableReferences
                                ._listIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._listIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subtasksRefs)
                        await $_getPrefetchedData<Task, $TasksTable, Subtask>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._subtasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).subtasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskLabelsRefs)
                        await $_getPrefetchedData<Task, $TasksTable, TaskLabel>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskLabelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskLabelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fieldValuesRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          FieldValue
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._fieldValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).fieldValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool listId,
        bool subtasksRefs,
        bool taskLabelsRefs,
        bool fieldValuesRefs,
      })
    >;
typedef $$SubtasksTableCreateCompanionBuilder = SubtasksCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String taskId,
  required String title,
  Value<bool> done,
  required String orderKey,
  Value<int> rowid,
});
typedef $$SubtasksTableUpdateCompanionBuilder = SubtasksCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> taskId,
  Value<String> title,
  Value<bool> done,
  Value<String> orderKey,
  Value<int> rowid,
});

final class $$SubtasksTableReferences
    extends BaseReferences<_$AppDatabase, $SubtasksTable, Subtask> {
  $$SubtasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('subtasks__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubtasksTable,
          Subtask,
          $$SubtasksTableFilterComposer,
          $$SubtasksTableOrderingComposer,
          $$SubtasksTableAnnotationComposer,
          $$SubtasksTableCreateCompanionBuilder,
          $$SubtasksTableUpdateCompanionBuilder,
          (Subtask, $$SubtasksTableReferences),
          Subtask,
          PrefetchHooks Function({bool taskId})
        > {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubtasksCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                taskId: taskId,
                title: title,
                done: done,
                orderKey: orderKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String taskId,
                required String title,
                Value<bool> done = const Value.absent(),
                required String orderKey,
                Value<int> rowid = const Value.absent(),
              }) => SubtasksCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                taskId: taskId,
                title: title,
                done: done,
                orderKey: orderKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubtasksTable, Subtask>(table),
                  $$SubtasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$SubtasksTableReferences._taskIdTable(
                          db,
                        ),
                        referencedColumn: $$SubtasksTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubtasksTable,
      Subtask,
      $$SubtasksTableFilterComposer,
      $$SubtasksTableOrderingComposer,
      $$SubtasksTableAnnotationComposer,
      $$SubtasksTableCreateCompanionBuilder,
      $$SubtasksTableUpdateCompanionBuilder,
      (Subtask, $$SubtasksTableReferences),
      Subtask,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$LabelsTableCreateCompanionBuilder = LabelsCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String name,
  Value<int?> colour,
  Value<int> rowid,
});
typedef $$LabelsTableUpdateCompanionBuilder = LabelsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> name,
  Value<int?> colour,
  Value<int> rowid,
});

final class $$LabelsTableReferences
    extends BaseReferences<_$AppDatabase, $LabelsTable, Label> {
  $$LabelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskLabelsTable, List<TaskLabel>>
  _taskLabelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskLabels,
    aliasName: 'labels__id__task_labels__label_id',
  );

  $$TaskLabelsTableProcessedTableManager get taskLabelsRefs {
    final manager = $$TaskLabelsTableTableManager(
      $_db,
      $_db.taskLabels,
    ).filter((f) => f.labelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskLabelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LabelsTableFilterComposer
    extends Composer<_$AppDatabase, $LabelsTable> {
  $$LabelsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskLabelsRefs(
    Expression<bool> Function($$TaskLabelsTableFilterComposer f) f,
  ) {
    final $$TaskLabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskLabels,
      getReferencedColumn: (t) => t.labelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskLabelsTableFilterComposer(
            $db: $db,
            $table: $db.taskLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LabelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LabelsTable> {
  $$LabelsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LabelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabelsTable> {
  $$LabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => column);

  Expression<T> taskLabelsRefs<T extends Object>(
    Expression<T> Function($$TaskLabelsTableAnnotationComposer a) f,
  ) {
    final $$TaskLabelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskLabels,
      getReferencedColumn: (t) => t.labelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskLabelsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskLabels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LabelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabelsTable,
          Label,
          $$LabelsTableFilterComposer,
          $$LabelsTableOrderingComposer,
          $$LabelsTableAnnotationComposer,
          $$LabelsTableCreateCompanionBuilder,
          $$LabelsTableUpdateCompanionBuilder,
          (Label, $$LabelsTableReferences),
          Label,
          PrefetchHooks Function({bool taskLabelsRefs})
        > {
  $$LabelsTableTableManager(_$AppDatabase db, $LabelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> colour = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabelsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                name: name,
                colour: colour,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String name,
                Value<int?> colour = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabelsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                name: name,
                colour: colour,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LabelsTable, Label>(table),
                  $$LabelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskLabelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (taskLabelsRefs) db.taskLabels],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskLabelsRefs)
                    await $_getPrefetchedData<Label, $LabelsTable, TaskLabel>(
                      currentTable: table,
                      referencedTable: $$LabelsTableReferences
                          ._taskLabelsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LabelsTableReferences(db, table, p0).taskLabelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.labelId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabelsTable,
      Label,
      $$LabelsTableFilterComposer,
      $$LabelsTableOrderingComposer,
      $$LabelsTableAnnotationComposer,
      $$LabelsTableCreateCompanionBuilder,
      $$LabelsTableUpdateCompanionBuilder,
      (Label, $$LabelsTableReferences),
      Label,
      PrefetchHooks Function({bool taskLabelsRefs})
    >;
typedef $$TaskLabelsTableCreateCompanionBuilder = TaskLabelsCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String taskId,
  required String labelId,
  Value<int> rowid,
});
typedef $$TaskLabelsTableUpdateCompanionBuilder = TaskLabelsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> taskId,
  Value<String> labelId,
  Value<int> rowid,
});

final class $$TaskLabelsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskLabelsTable, TaskLabel> {
  $$TaskLabelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_labels__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LabelsTable _labelIdTable(_$AppDatabase db) =>
      db.labels.createAlias('task_labels__label_id__labels__id');

  $$LabelsTableProcessedTableManager get labelId {
    final $_column = $_itemColumn<String>('label_id')!;

    final manager = $$LabelsTableTableManager(
      $_db,
      $_db.labels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_labelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskLabelsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskLabelsTable> {
  $$TaskLabelsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LabelsTableFilterComposer get labelId {
    final $$LabelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableFilterComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskLabelsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskLabelsTable> {
  $$TaskLabelsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LabelsTableOrderingComposer get labelId {
    final $$LabelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableOrderingComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskLabelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskLabelsTable> {
  $$TaskLabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LabelsTableAnnotationComposer get labelId {
    final $$LabelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelId,
      referencedTable: $db.labels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabelsTableAnnotationComposer(
            $db: $db,
            $table: $db.labels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskLabelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskLabelsTable,
          TaskLabel,
          $$TaskLabelsTableFilterComposer,
          $$TaskLabelsTableOrderingComposer,
          $$TaskLabelsTableAnnotationComposer,
          $$TaskLabelsTableCreateCompanionBuilder,
          $$TaskLabelsTableUpdateCompanionBuilder,
          (TaskLabel, $$TaskLabelsTableReferences),
          TaskLabel,
          PrefetchHooks Function({bool taskId, bool labelId})
        > {
  $$TaskLabelsTableTableManager(_$AppDatabase db, $TaskLabelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskLabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskLabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskLabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> labelId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskLabelsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                taskId: taskId,
                labelId: labelId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String taskId,
                required String labelId,
                Value<int> rowid = const Value.absent(),
              }) => TaskLabelsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                taskId: taskId,
                labelId: labelId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskLabelsTable, TaskLabel>(table),
                  $$TaskLabelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, labelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskLabelsTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$TaskLabelsTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (labelId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.labelId,
                        referencedTable: $$TaskLabelsTableReferences
                            ._labelIdTable(db),
                        referencedColumn: $$TaskLabelsTableReferences
                            ._labelIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskLabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskLabelsTable,
      TaskLabel,
      $$TaskLabelsTableFilterComposer,
      $$TaskLabelsTableOrderingComposer,
      $$TaskLabelsTableAnnotationComposer,
      $$TaskLabelsTableCreateCompanionBuilder,
      $$TaskLabelsTableUpdateCompanionBuilder,
      (TaskLabel, $$TaskLabelsTableReferences),
      TaskLabel,
      PrefetchHooks Function({bool taskId, bool labelId})
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String title,
  Value<String> bodyMd,
  Value<bool> pinned,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> title,
  Value<String> bodyMd,
  Value<bool> pinned,
  Value<int> rowid,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyMd => $composableBuilder(
    column: $table.bodyMd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyMd => $composableBuilder(
    column: $table.bodyMd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get bodyMd =>
      $composableBuilder(column: $table.bodyMd, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> bodyMd = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                title: title,
                bodyMd: bodyMd,
                pinned: pinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String title,
                Value<String> bodyMd = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                title: title,
                bodyMd: bodyMd,
                pinned: pinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, Note>(table),
                  BaseReferences<_$AppDatabase, $NotesTable, Note>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String targetTable,
  required String rowId,
  required String changedFields,
  required String hlc,
  Value<DateTime> queuedAt,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> targetTable,
  Value<String> rowId,
  Value<String> changedFields,
  Value<String> hlc,
  Value<DateTime> queuedAt,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedFields => $composableBuilder(
    column: $table.changedFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedFields => $composableBuilder(
    column: $table.changedFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get changedFields => $composableBuilder(
    column: $table.changedFields,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> changedFields = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                targetTable: targetTable,
                rowId: rowId,
                changedFields: changedFields,
                hlc: hlc,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String targetTable,
                required String rowId,
                required String changedFields,
                required String hlc,
                Value<DateTime> queuedAt = const Value.absent(),
              }) => OutboxCompanion.insert(
                seq: seq,
                targetTable: targetTable,
                rowId: rowId,
                changedFields: changedFields,
                hlc: hlc,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSetting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTable,
                    LocalSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;
typedef $$CapacityProfilesTableCreateCompanionBuilder =
    CapacityProfilesCompanion Function({
      required String id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      required String workspaceId,
      Value<int> sleepTargetMin,
      Value<int> sleepStartMin,
      Value<int> wakeMonMin,
      Value<int> bedtimeMonMin,
      Value<int> wakeTueMin,
      Value<int> bedtimeTueMin,
      Value<int> wakeWedMin,
      Value<int> bedtimeWedMin,
      Value<int> wakeThuMin,
      Value<int> bedtimeThuMin,
      Value<int> wakeFriMin,
      Value<int> bedtimeFriMin,
      Value<int> wakeSatMin,
      Value<int> bedtimeSatMin,
      Value<int> wakeSunMin,
      Value<int> bedtimeSunMin,
      Value<int> mealsMin,
      Value<int> bufferMin,
      Value<double> focusFactor,
      Value<int> minGapMin,
      Value<int> rowid,
    });
typedef $$CapacityProfilesTableUpdateCompanionBuilder =
    CapacityProfilesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      Value<String> workspaceId,
      Value<int> sleepTargetMin,
      Value<int> sleepStartMin,
      Value<int> wakeMonMin,
      Value<int> bedtimeMonMin,
      Value<int> wakeTueMin,
      Value<int> bedtimeTueMin,
      Value<int> wakeWedMin,
      Value<int> bedtimeWedMin,
      Value<int> wakeThuMin,
      Value<int> bedtimeThuMin,
      Value<int> wakeFriMin,
      Value<int> bedtimeFriMin,
      Value<int> wakeSatMin,
      Value<int> bedtimeSatMin,
      Value<int> wakeSunMin,
      Value<int> bedtimeSunMin,
      Value<int> mealsMin,
      Value<int> bufferMin,
      Value<double> focusFactor,
      Value<int> minGapMin,
      Value<int> rowid,
    });

class $$CapacityProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CapacityProfilesTable> {
  $$CapacityProfilesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepTargetMin => $composableBuilder(
    column: $table.sleepTargetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepStartMin => $composableBuilder(
    column: $table.sleepStartMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeMonMin => $composableBuilder(
    column: $table.wakeMonMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeMonMin => $composableBuilder(
    column: $table.bedtimeMonMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeTueMin => $composableBuilder(
    column: $table.wakeTueMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeTueMin => $composableBuilder(
    column: $table.bedtimeTueMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeWedMin => $composableBuilder(
    column: $table.wakeWedMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeWedMin => $composableBuilder(
    column: $table.bedtimeWedMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeThuMin => $composableBuilder(
    column: $table.wakeThuMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeThuMin => $composableBuilder(
    column: $table.bedtimeThuMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeFriMin => $composableBuilder(
    column: $table.wakeFriMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeFriMin => $composableBuilder(
    column: $table.bedtimeFriMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeSatMin => $composableBuilder(
    column: $table.wakeSatMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeSatMin => $composableBuilder(
    column: $table.bedtimeSatMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeSunMin => $composableBuilder(
    column: $table.wakeSunMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bedtimeSunMin => $composableBuilder(
    column: $table.bedtimeSunMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mealsMin => $composableBuilder(
    column: $table.mealsMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bufferMin => $composableBuilder(
    column: $table.bufferMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get focusFactor => $composableBuilder(
    column: $table.focusFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minGapMin => $composableBuilder(
    column: $table.minGapMin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CapacityProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CapacityProfilesTable> {
  $$CapacityProfilesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepTargetMin => $composableBuilder(
    column: $table.sleepTargetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepStartMin => $composableBuilder(
    column: $table.sleepStartMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeMonMin => $composableBuilder(
    column: $table.wakeMonMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeMonMin => $composableBuilder(
    column: $table.bedtimeMonMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeTueMin => $composableBuilder(
    column: $table.wakeTueMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeTueMin => $composableBuilder(
    column: $table.bedtimeTueMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeWedMin => $composableBuilder(
    column: $table.wakeWedMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeWedMin => $composableBuilder(
    column: $table.bedtimeWedMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeThuMin => $composableBuilder(
    column: $table.wakeThuMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeThuMin => $composableBuilder(
    column: $table.bedtimeThuMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeFriMin => $composableBuilder(
    column: $table.wakeFriMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeFriMin => $composableBuilder(
    column: $table.bedtimeFriMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeSatMin => $composableBuilder(
    column: $table.wakeSatMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeSatMin => $composableBuilder(
    column: $table.bedtimeSatMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeSunMin => $composableBuilder(
    column: $table.wakeSunMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bedtimeSunMin => $composableBuilder(
    column: $table.bedtimeSunMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealsMin => $composableBuilder(
    column: $table.mealsMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bufferMin => $composableBuilder(
    column: $table.bufferMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get focusFactor => $composableBuilder(
    column: $table.focusFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minGapMin => $composableBuilder(
    column: $table.minGapMin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CapacityProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CapacityProfilesTable> {
  $$CapacityProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepTargetMin => $composableBuilder(
    column: $table.sleepTargetMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sleepStartMin => $composableBuilder(
    column: $table.sleepStartMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeMonMin => $composableBuilder(
    column: $table.wakeMonMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedtimeMonMin => $composableBuilder(
    column: $table.bedtimeMonMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeTueMin => $composableBuilder(
    column: $table.wakeTueMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedtimeTueMin => $composableBuilder(
    column: $table.bedtimeTueMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeWedMin => $composableBuilder(
    column: $table.wakeWedMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedtimeWedMin => $composableBuilder(
    column: $table.bedtimeWedMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeThuMin => $composableBuilder(
    column: $table.wakeThuMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedtimeThuMin => $composableBuilder(
    column: $table.bedtimeThuMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeFriMin => $composableBuilder(
    column: $table.wakeFriMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedtimeFriMin => $composableBuilder(
    column: $table.bedtimeFriMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeSatMin => $composableBuilder(
    column: $table.wakeSatMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedtimeSatMin => $composableBuilder(
    column: $table.bedtimeSatMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wakeSunMin => $composableBuilder(
    column: $table.wakeSunMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bedtimeSunMin => $composableBuilder(
    column: $table.bedtimeSunMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mealsMin =>
      $composableBuilder(column: $table.mealsMin, builder: (column) => column);

  GeneratedColumn<int> get bufferMin =>
      $composableBuilder(column: $table.bufferMin, builder: (column) => column);

  GeneratedColumn<double> get focusFactor => $composableBuilder(
    column: $table.focusFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minGapMin =>
      $composableBuilder(column: $table.minGapMin, builder: (column) => column);
}

class $$CapacityProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CapacityProfilesTable,
          CapacityProfile,
          $$CapacityProfilesTableFilterComposer,
          $$CapacityProfilesTableOrderingComposer,
          $$CapacityProfilesTableAnnotationComposer,
          $$CapacityProfilesTableCreateCompanionBuilder,
          $$CapacityProfilesTableUpdateCompanionBuilder,
          (
            CapacityProfile,
            BaseReferences<
              _$AppDatabase,
              $CapacityProfilesTable,
              CapacityProfile
            >,
          ),
          CapacityProfile,
          PrefetchHooks Function()
        > {
  $$CapacityProfilesTableTableManager(
    _$AppDatabase db,
    $CapacityProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapacityProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapacityProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapacityProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<int> sleepTargetMin = const Value.absent(),
                Value<int> sleepStartMin = const Value.absent(),
                Value<int> wakeMonMin = const Value.absent(),
                Value<int> bedtimeMonMin = const Value.absent(),
                Value<int> wakeTueMin = const Value.absent(),
                Value<int> bedtimeTueMin = const Value.absent(),
                Value<int> wakeWedMin = const Value.absent(),
                Value<int> bedtimeWedMin = const Value.absent(),
                Value<int> wakeThuMin = const Value.absent(),
                Value<int> bedtimeThuMin = const Value.absent(),
                Value<int> wakeFriMin = const Value.absent(),
                Value<int> bedtimeFriMin = const Value.absent(),
                Value<int> wakeSatMin = const Value.absent(),
                Value<int> bedtimeSatMin = const Value.absent(),
                Value<int> wakeSunMin = const Value.absent(),
                Value<int> bedtimeSunMin = const Value.absent(),
                Value<int> mealsMin = const Value.absent(),
                Value<int> bufferMin = const Value.absent(),
                Value<double> focusFactor = const Value.absent(),
                Value<int> minGapMin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapacityProfilesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                sleepTargetMin: sleepTargetMin,
                sleepStartMin: sleepStartMin,
                wakeMonMin: wakeMonMin,
                bedtimeMonMin: bedtimeMonMin,
                wakeTueMin: wakeTueMin,
                bedtimeTueMin: bedtimeTueMin,
                wakeWedMin: wakeWedMin,
                bedtimeWedMin: bedtimeWedMin,
                wakeThuMin: wakeThuMin,
                bedtimeThuMin: bedtimeThuMin,
                wakeFriMin: wakeFriMin,
                bedtimeFriMin: bedtimeFriMin,
                wakeSatMin: wakeSatMin,
                bedtimeSatMin: bedtimeSatMin,
                wakeSunMin: wakeSunMin,
                bedtimeSunMin: bedtimeSunMin,
                mealsMin: mealsMin,
                bufferMin: bufferMin,
                focusFactor: focusFactor,
                minGapMin: minGapMin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                Value<int> sleepTargetMin = const Value.absent(),
                Value<int> sleepStartMin = const Value.absent(),
                Value<int> wakeMonMin = const Value.absent(),
                Value<int> bedtimeMonMin = const Value.absent(),
                Value<int> wakeTueMin = const Value.absent(),
                Value<int> bedtimeTueMin = const Value.absent(),
                Value<int> wakeWedMin = const Value.absent(),
                Value<int> bedtimeWedMin = const Value.absent(),
                Value<int> wakeThuMin = const Value.absent(),
                Value<int> bedtimeThuMin = const Value.absent(),
                Value<int> wakeFriMin = const Value.absent(),
                Value<int> bedtimeFriMin = const Value.absent(),
                Value<int> wakeSatMin = const Value.absent(),
                Value<int> bedtimeSatMin = const Value.absent(),
                Value<int> wakeSunMin = const Value.absent(),
                Value<int> bedtimeSunMin = const Value.absent(),
                Value<int> mealsMin = const Value.absent(),
                Value<int> bufferMin = const Value.absent(),
                Value<double> focusFactor = const Value.absent(),
                Value<int> minGapMin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapacityProfilesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                sleepTargetMin: sleepTargetMin,
                sleepStartMin: sleepStartMin,
                wakeMonMin: wakeMonMin,
                bedtimeMonMin: bedtimeMonMin,
                wakeTueMin: wakeTueMin,
                bedtimeTueMin: bedtimeTueMin,
                wakeWedMin: wakeWedMin,
                bedtimeWedMin: bedtimeWedMin,
                wakeThuMin: wakeThuMin,
                bedtimeThuMin: bedtimeThuMin,
                wakeFriMin: wakeFriMin,
                bedtimeFriMin: bedtimeFriMin,
                wakeSatMin: wakeSatMin,
                bedtimeSatMin: bedtimeSatMin,
                wakeSunMin: wakeSunMin,
                bedtimeSunMin: bedtimeSunMin,
                mealsMin: mealsMin,
                bufferMin: bufferMin,
                focusFactor: focusFactor,
                minGapMin: minGapMin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CapacityProfilesTable, CapacityProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CapacityProfilesTable,
                    CapacityProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CapacityProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CapacityProfilesTable,
      CapacityProfile,
      $$CapacityProfilesTableFilterComposer,
      $$CapacityProfilesTableOrderingComposer,
      $$CapacityProfilesTableAnnotationComposer,
      $$CapacityProfilesTableCreateCompanionBuilder,
      $$CapacityProfilesTableUpdateCompanionBuilder,
      (
        CapacityProfile,
        BaseReferences<_$AppDatabase, $CapacityProfilesTable, CapacityProfile>,
      ),
      CapacityProfile,
      PrefetchHooks Function()
    >;
typedef $$CommitmentsTableCreateCompanionBuilder =
    CommitmentsCompanion Function({
      required String id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      required String workspaceId,
      Value<String?> scheduleId,
      required String title,
      required String rrule,
      required int startMin,
      required int durationMin,
      Value<String?> location,
      Value<CommitmentKind> kind,
      Value<int> rowid,
    });
typedef $$CommitmentsTableUpdateCompanionBuilder =
    CommitmentsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      Value<String> workspaceId,
      Value<String?> scheduleId,
      Value<String> title,
      Value<String> rrule,
      Value<int> startMin,
      Value<int> durationMin,
      Value<String?> location,
      Value<CommitmentKind> kind,
      Value<int> rowid,
    });

class $$CommitmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CommitmentsTable> {
  $$CommitmentsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CommitmentKind, CommitmentKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$CommitmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommitmentsTable> {
  $$CommitmentsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommitmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommitmentsTable> {
  $$CommitmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CommitmentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$CommitmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommitmentsTable,
          Commitment,
          $$CommitmentsTableFilterComposer,
          $$CommitmentsTableOrderingComposer,
          $$CommitmentsTableAnnotationComposer,
          $$CommitmentsTableCreateCompanionBuilder,
          $$CommitmentsTableUpdateCompanionBuilder,
          (
            Commitment,
            BaseReferences<_$AppDatabase, $CommitmentsTable, Commitment>,
          ),
          Commitment,
          PrefetchHooks Function()
        > {
  $$CommitmentsTableTableManager(_$AppDatabase db, $CommitmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommitmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommitmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommitmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> scheduleId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> rrule = const Value.absent(),
                Value<int> startMin = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<CommitmentKind> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommitmentsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                scheduleId: scheduleId,
                title: title,
                rrule: rrule,
                startMin: startMin,
                durationMin: durationMin,
                location: location,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                Value<String?> scheduleId = const Value.absent(),
                required String title,
                required String rrule,
                required int startMin,
                required int durationMin,
                Value<String?> location = const Value.absent(),
                Value<CommitmentKind> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommitmentsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                scheduleId: scheduleId,
                title: title,
                rrule: rrule,
                startMin: startMin,
                durationMin: durationMin,
                location: location,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommitmentsTable, Commitment>(table),
                  BaseReferences<_$AppDatabase, $CommitmentsTable, Commitment>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommitmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommitmentsTable,
      Commitment,
      $$CommitmentsTableFilterComposer,
      $$CommitmentsTableOrderingComposer,
      $$CommitmentsTableAnnotationComposer,
      $$CommitmentsTableCreateCompanionBuilder,
      $$CommitmentsTableUpdateCompanionBuilder,
      (
        Commitment,
        BaseReferences<_$AppDatabase, $CommitmentsTable, Commitment>,
      ),
      Commitment,
      PrefetchHooks Function()
    >;
typedef $$FieldDefsTableCreateCompanionBuilder = FieldDefsCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String boardId,
  required String name,
  required FieldType type,
  Value<String> optionsJson,
  required String orderKey,
  Value<bool> showInline,
  Value<int> rowid,
});
typedef $$FieldDefsTableUpdateCompanionBuilder = FieldDefsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> boardId,
  Value<String> name,
  Value<FieldType> type,
  Value<String> optionsJson,
  Value<String> orderKey,
  Value<bool> showInline,
  Value<int> rowid,
});

final class $$FieldDefsTableReferences
    extends BaseReferences<_$AppDatabase, $FieldDefsTable, FieldDef> {
  $$FieldDefsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('field_defs__board_id__boards__id');

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FieldValuesTable, List<FieldValue>>
  _fieldValuesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.fieldValues,
    aliasName: 'field_defs__id__field_values__field_id',
  );

  $$FieldValuesTableProcessedTableManager get fieldValuesRefs {
    final manager = $$FieldValuesTableTableManager(
      $_db,
      $_db.fieldValues,
    ).filter((f) => f.fieldId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fieldValuesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FieldDefsTableFilterComposer
    extends Composer<_$AppDatabase, $FieldDefsTable> {
  $$FieldDefsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FieldType, FieldType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showInline => $composableBuilder(
    column: $table.showInline,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> fieldValuesRefs(
    Expression<bool> Function($$FieldValuesTableFilterComposer f) f,
  ) {
    final $$FieldValuesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldValues,
      getReferencedColumn: (t) => t.fieldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldValuesTableFilterComposer(
            $db: $db,
            $table: $db.fieldValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FieldDefsTableOrderingComposer
    extends Composer<_$AppDatabase, $FieldDefsTable> {
  $$FieldDefsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showInline => $composableBuilder(
    column: $table.showInline,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldDefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FieldDefsTable> {
  $$FieldDefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FieldType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<bool> get showInline => $composableBuilder(
    column: $table.showInline,
    builder: (column) => column,
  );

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> fieldValuesRefs<T extends Object>(
    Expression<T> Function($$FieldValuesTableAnnotationComposer a) f,
  ) {
    final $$FieldValuesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldValues,
      getReferencedColumn: (t) => t.fieldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldValuesTableAnnotationComposer(
            $db: $db,
            $table: $db.fieldValues,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FieldDefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FieldDefsTable,
          FieldDef,
          $$FieldDefsTableFilterComposer,
          $$FieldDefsTableOrderingComposer,
          $$FieldDefsTableAnnotationComposer,
          $$FieldDefsTableCreateCompanionBuilder,
          $$FieldDefsTableUpdateCompanionBuilder,
          (FieldDef, $$FieldDefsTableReferences),
          FieldDef,
          PrefetchHooks Function({bool boardId, bool fieldValuesRefs})
        > {
  $$FieldDefsTableTableManager(_$AppDatabase db, $FieldDefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldDefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldDefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldDefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<FieldType> type = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<bool> showInline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FieldDefsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                boardId: boardId,
                name: name,
                type: type,
                optionsJson: optionsJson,
                orderKey: orderKey,
                showInline: showInline,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String boardId,
                required String name,
                required FieldType type,
                Value<String> optionsJson = const Value.absent(),
                required String orderKey,
                Value<bool> showInline = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FieldDefsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                boardId: boardId,
                name: name,
                type: type,
                optionsJson: optionsJson,
                orderKey: orderKey,
                showInline: showInline,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FieldDefsTable, FieldDef>(table),
                  $$FieldDefsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boardId = false, fieldValuesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (fieldValuesRefs) db.fieldValues],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boardId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.boardId,
                        referencedTable: $$FieldDefsTableReferences
                            ._boardIdTable(db),
                        referencedColumn: $$FieldDefsTableReferences
                            ._boardIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fieldValuesRefs)
                    await $_getPrefetchedData<
                      FieldDef,
                      $FieldDefsTable,
                      FieldValue
                    >(
                      currentTable: table,
                      referencedTable: $$FieldDefsTableReferences
                          ._fieldValuesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FieldDefsTableReferences(
                            db,
                            table,
                            p0,
                          ).fieldValuesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.fieldId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FieldDefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FieldDefsTable,
      FieldDef,
      $$FieldDefsTableFilterComposer,
      $$FieldDefsTableOrderingComposer,
      $$FieldDefsTableAnnotationComposer,
      $$FieldDefsTableCreateCompanionBuilder,
      $$FieldDefsTableUpdateCompanionBuilder,
      (FieldDef, $$FieldDefsTableReferences),
      FieldDef,
      PrefetchHooks Function({bool boardId, bool fieldValuesRefs})
    >;
typedef $$FieldValuesTableCreateCompanionBuilder =
    FieldValuesCompanion Function({
      required String id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      required String workspaceId,
      required String taskId,
      required String fieldId,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$FieldValuesTableUpdateCompanionBuilder =
    FieldValuesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      Value<String> workspaceId,
      Value<String> taskId,
      Value<String> fieldId,
      Value<String?> value,
      Value<int> rowid,
    });

final class $$FieldValuesTableReferences
    extends BaseReferences<_$AppDatabase, $FieldValuesTable, FieldValue> {
  $$FieldValuesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('field_values__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FieldDefsTable _fieldIdTable(_$AppDatabase db) =>
      db.fieldDefs.createAlias('field_values__field_id__field_defs__id');

  $$FieldDefsTableProcessedTableManager get fieldId {
    final $_column = $_itemColumn<String>('field_id')!;

    final manager = $$FieldDefsTableTableManager(
      $_db,
      $_db.fieldDefs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FieldValuesTableFilterComposer
    extends Composer<_$AppDatabase, $FieldValuesTable> {
  $$FieldValuesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FieldDefsTableFilterComposer get fieldId {
    final $$FieldDefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fieldId,
      referencedTable: $db.fieldDefs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldDefsTableFilterComposer(
            $db: $db,
            $table: $db.fieldDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $FieldValuesTable> {
  $$FieldValuesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FieldDefsTableOrderingComposer get fieldId {
    final $$FieldDefsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fieldId,
      referencedTable: $db.fieldDefs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldDefsTableOrderingComposer(
            $db: $db,
            $table: $db.fieldDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FieldValuesTable> {
  $$FieldValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FieldDefsTableAnnotationComposer get fieldId {
    final $$FieldDefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fieldId,
      referencedTable: $db.fieldDefs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldDefsTableAnnotationComposer(
            $db: $db,
            $table: $db.fieldDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FieldValuesTable,
          FieldValue,
          $$FieldValuesTableFilterComposer,
          $$FieldValuesTableOrderingComposer,
          $$FieldValuesTableAnnotationComposer,
          $$FieldValuesTableCreateCompanionBuilder,
          $$FieldValuesTableUpdateCompanionBuilder,
          (FieldValue, $$FieldValuesTableReferences),
          FieldValue,
          PrefetchHooks Function({bool taskId, bool fieldId})
        > {
  $$FieldValuesTableTableManager(_$AppDatabase db, $FieldValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> fieldId = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FieldValuesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                taskId: taskId,
                fieldId: fieldId,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String taskId,
                required String fieldId,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FieldValuesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                taskId: taskId,
                fieldId: fieldId,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FieldValuesTable, FieldValue>(table),
                  $$FieldValuesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, fieldId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$FieldValuesTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$FieldValuesTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (fieldId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fieldId,
                        referencedTable: $$FieldValuesTableReferences
                            ._fieldIdTable(db),
                        referencedColumn: $$FieldValuesTableReferences
                            ._fieldIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FieldValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FieldValuesTable,
      FieldValue,
      $$FieldValuesTableFilterComposer,
      $$FieldValuesTableOrderingComposer,
      $$FieldValuesTableAnnotationComposer,
      $$FieldValuesTableCreateCompanionBuilder,
      $$FieldValuesTableUpdateCompanionBuilder,
      (FieldValue, $$FieldValuesTableReferences),
      FieldValue,
      PrefetchHooks Function({bool taskId, bool fieldId})
    >;
typedef $$ProjectViewsTableCreateCompanionBuilder =
    ProjectViewsCompanion Function({
      required String id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      required String workspaceId,
      required String boardId,
      required String name,
      required ViewKind kind,
      Value<String> filterJson,
      Value<String?> groupBy,
      required String orderKey,
      Value<int> rowid,
    });
typedef $$ProjectViewsTableUpdateCompanionBuilder =
    ProjectViewsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> clientId,
      Value<String> fieldVersions,
      Value<String> workspaceId,
      Value<String> boardId,
      Value<String> name,
      Value<ViewKind> kind,
      Value<String> filterJson,
      Value<String?> groupBy,
      Value<String> orderKey,
      Value<int> rowid,
    });

final class $$ProjectViewsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectViewsTable, ProjectView> {
  $$ProjectViewsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('project_views__board_id__boards__id');

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProjectViewsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectViewsTable> {
  $$ProjectViewsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ViewKind, ViewKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupBy => $composableBuilder(
    column: $table.groupBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectViewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectViewsTable> {
  $$ProjectViewsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupBy => $composableBuilder(
    column: $table.groupBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectViewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectViewsTable> {
  $$ProjectViewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ViewKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupBy =>
      $composableBuilder(column: $table.groupBy, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectViewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectViewsTable,
          ProjectView,
          $$ProjectViewsTableFilterComposer,
          $$ProjectViewsTableOrderingComposer,
          $$ProjectViewsTableAnnotationComposer,
          $$ProjectViewsTableCreateCompanionBuilder,
          $$ProjectViewsTableUpdateCompanionBuilder,
          (ProjectView, $$ProjectViewsTableReferences),
          ProjectView,
          PrefetchHooks Function({bool boardId})
        > {
  $$ProjectViewsTableTableManager(_$AppDatabase db, $ProjectViewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectViewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectViewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectViewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ViewKind> kind = const Value.absent(),
                Value<String> filterJson = const Value.absent(),
                Value<String?> groupBy = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectViewsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                boardId: boardId,
                name: name,
                kind: kind,
                filterJson: filterJson,
                groupBy: groupBy,
                orderKey: orderKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String boardId,
                required String name,
                required ViewKind kind,
                Value<String> filterJson = const Value.absent(),
                Value<String?> groupBy = const Value.absent(),
                required String orderKey,
                Value<int> rowid = const Value.absent(),
              }) => ProjectViewsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                boardId: boardId,
                name: name,
                kind: kind,
                filterJson: filterJson,
                groupBy: groupBy,
                orderKey: orderKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectViewsTable, ProjectView>(table),
                  $$ProjectViewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boardId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.boardId,
                        referencedTable: $$ProjectViewsTableReferences
                            ._boardIdTable(db),
                        referencedColumn: $$ProjectViewsTableReferences
                            ._boardIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProjectViewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectViewsTable,
      ProjectView,
      $$ProjectViewsTableFilterComposer,
      $$ProjectViewsTableOrderingComposer,
      $$ProjectViewsTableAnnotationComposer,
      $$ProjectViewsTableCreateCompanionBuilder,
      $$ProjectViewsTableUpdateCompanionBuilder,
      (ProjectView, $$ProjectViewsTableReferences),
      ProjectView,
      PrefetchHooks Function({bool boardId})
    >;
typedef $$SchedulesTableCreateCompanionBuilder = SchedulesCompanion Function({
  required String id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  required String workspaceId,
  required String name,
  Value<String?> startsOn,
  Value<String?> endsOn,
  Value<bool> isFallback,
  required String orderKey,
  Value<int> rowid,
});
typedef $$SchedulesTableUpdateCompanionBuilder = SchedulesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> clientId,
  Value<String> fieldVersions,
  Value<String> workspaceId,
  Value<String> name,
  Value<String?> startsOn,
  Value<String?> endsOn,
  Value<bool> isFallback,
  Value<String> orderKey,
  Value<int> rowid,
});

class $$SchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFallback => $composableBuilder(
    column: $table.isFallback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFallback => $composableBuilder(
    column: $table.isFallback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get fieldVersions => $composableBuilder(
    column: $table.fieldVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startsOn =>
      $composableBuilder(column: $table.startsOn, builder: (column) => column);

  GeneratedColumn<String> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<bool> get isFallback => $composableBuilder(
    column: $table.isFallback,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);
}

class $$SchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedulesTable,
          TimetableSet,
          $$SchedulesTableFilterComposer,
          $$SchedulesTableOrderingComposer,
          $$SchedulesTableAnnotationComposer,
          $$SchedulesTableCreateCompanionBuilder,
          $$SchedulesTableUpdateCompanionBuilder,
          (
            TimetableSet,
            BaseReferences<_$AppDatabase, $SchedulesTable, TimetableSet>,
          ),
          TimetableSet,
          PrefetchHooks Function()
        > {
  $$SchedulesTableTableManager(_$AppDatabase db, $SchedulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> startsOn = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<bool> isFallback = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                name: name,
                startsOn: startsOn,
                endsOn: endsOn,
                isFallback: isFallback,
                orderKey: orderKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> fieldVersions = const Value.absent(),
                required String workspaceId,
                required String name,
                Value<String?> startsOn = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<bool> isFallback = const Value.absent(),
                required String orderKey,
                Value<int> rowid = const Value.absent(),
              }) => SchedulesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientId: clientId,
                fieldVersions: fieldVersions,
                workspaceId: workspaceId,
                name: name,
                startsOn: startsOn,
                endsOn: endsOn,
                isFallback: isFallback,
                orderKey: orderKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchedulesTable, TimetableSet>(table),
                  BaseReferences<_$AppDatabase, $SchedulesTable, TimetableSet>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedulesTable,
      TimetableSet,
      $$SchedulesTableFilterComposer,
      $$SchedulesTableOrderingComposer,
      $$SchedulesTableAnnotationComposer,
      $$SchedulesTableCreateCompanionBuilder,
      $$SchedulesTableUpdateCompanionBuilder,
      (
        TimetableSet,
        BaseReferences<_$AppDatabase, $SchedulesTable, TimetableSet>,
      ),
      TimetableSet,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db, _db.boards);
  $$ListsTableTableManager get lists =>
      $$ListsTableTableManager(_db, _db.lists);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$LabelsTableTableManager get labels =>
      $$LabelsTableTableManager(_db, _db.labels);
  $$TaskLabelsTableTableManager get taskLabels =>
      $$TaskLabelsTableTableManager(_db, _db.taskLabels);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$CapacityProfilesTableTableManager get capacityProfiles =>
      $$CapacityProfilesTableTableManager(_db, _db.capacityProfiles);
  $$CommitmentsTableTableManager get commitments =>
      $$CommitmentsTableTableManager(_db, _db.commitments);
  $$FieldDefsTableTableManager get fieldDefs =>
      $$FieldDefsTableTableManager(_db, _db.fieldDefs);
  $$FieldValuesTableTableManager get fieldValues =>
      $$FieldValuesTableTableManager(_db, _db.fieldValues);
  $$ProjectViewsTableTableManager get projectViews =>
      $$ProjectViewsTableTableManager(_db, _db.projectViews);
  $$SchedulesTableTableManager get schedules =>
      $$SchedulesTableTableManager(_db, _db.schedules);
}
