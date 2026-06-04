// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProgramsTable extends Programs
    with TableInfo<$ProgramsTable, ProgramRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mantraIdMeta = const VerificationMeta(
    'mantraId',
  );
  @override
  late final GeneratedColumn<String> mantraId = GeneratedColumn<String>(
    'mantra_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetWritingsMeta = const VerificationMeta(
    'targetWritings',
  );
  @override
  late final GeneratedColumn<int> targetWritings = GeneratedColumn<int>(
    'target_writings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDaysMeta = const VerificationMeta(
    'targetDays',
  );
  @override
  late final GeneratedColumn<int> targetDays = GeneratedColumn<int>(
    'target_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _dailyTargetMeta = const VerificationMeta(
    'dailyTarget',
  );
  @override
  late final GeneratedColumn<int> dailyTarget = GeneratedColumn<int>(
    'daily_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _totalChantsMeta = const VerificationMeta(
    'totalChants',
  );
  @override
  late final GeneratedColumn<int> totalChants = GeneratedColumn<int>(
    'total_chants',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalWritingsMeta = const VerificationMeta(
    'totalWritings',
  );
  @override
  late final GeneratedColumn<int> totalWritings = GeneratedColumn<int>(
    'total_writings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    mantraId,
    targetWritings,
    targetDays,
    startedAt,
    dailyTarget,
    status,
    totalChants,
    totalWritings,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('mantra_id')) {
      context.handle(
        _mantraIdMeta,
        mantraId.isAcceptableOrUnknown(data['mantra_id']!, _mantraIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mantraIdMeta);
    }
    if (data.containsKey('target_writings')) {
      context.handle(
        _targetWritingsMeta,
        targetWritings.isAcceptableOrUnknown(
          data['target_writings']!,
          _targetWritingsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetWritingsMeta);
    }
    if (data.containsKey('target_days')) {
      context.handle(
        _targetDaysMeta,
        targetDays.isAcceptableOrUnknown(data['target_days']!, _targetDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDaysMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('daily_target')) {
      context.handle(
        _dailyTargetMeta,
        dailyTarget.isAcceptableOrUnknown(
          data['daily_target']!,
          _dailyTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyTargetMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_chants')) {
      context.handle(
        _totalChantsMeta,
        totalChants.isAcceptableOrUnknown(
          data['total_chants']!,
          _totalChantsMeta,
        ),
      );
    }
    if (data.containsKey('total_writings')) {
      context.handle(
        _totalWritingsMeta,
        totalWritings.isAcceptableOrUnknown(
          data['total_writings']!,
          _totalWritingsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      mantraId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mantra_id'],
      )!,
      targetWritings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_writings'],
      )!,
      targetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_days'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      dailyTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_target'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalChants: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chants'],
      )!,
      totalWritings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_writings'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }
}

class ProgramRow extends DataClass implements Insertable<ProgramRow> {
  final String id;
  final String profileId;
  final String mantraId;
  final int targetWritings;
  final int targetDays;
  final DateTime startedAt;
  final int dailyTarget;

  /// 'active' | 'completed' | 'paused'
  final String status;
  final int totalChants;
  final int totalWritings;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  const ProgramRow({
    required this.id,
    required this.profileId,
    required this.mantraId,
    required this.targetWritings,
    required this.targetDays,
    required this.startedAt,
    required this.dailyTarget,
    required this.status,
    required this.totalChants,
    required this.totalWritings,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['mantra_id'] = Variable<String>(mantraId);
    map['target_writings'] = Variable<int>(targetWritings);
    map['target_days'] = Variable<int>(targetDays);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['daily_target'] = Variable<int>(dailyTarget);
    map['status'] = Variable<String>(status);
    map['total_chants'] = Variable<int>(totalChants);
    map['total_writings'] = Variable<int>(totalWritings);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      mantraId: Value(mantraId),
      targetWritings: Value(targetWritings),
      targetDays: Value(targetDays),
      startedAt: Value(startedAt),
      dailyTarget: Value(dailyTarget),
      status: Value(status),
      totalChants: Value(totalChants),
      totalWritings: Value(totalWritings),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory ProgramRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      mantraId: serializer.fromJson<String>(json['mantraId']),
      targetWritings: serializer.fromJson<int>(json['targetWritings']),
      targetDays: serializer.fromJson<int>(json['targetDays']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      dailyTarget: serializer.fromJson<int>(json['dailyTarget']),
      status: serializer.fromJson<String>(json['status']),
      totalChants: serializer.fromJson<int>(json['totalChants']),
      totalWritings: serializer.fromJson<int>(json['totalWritings']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'mantraId': serializer.toJson<String>(mantraId),
      'targetWritings': serializer.toJson<int>(targetWritings),
      'targetDays': serializer.toJson<int>(targetDays),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'dailyTarget': serializer.toJson<int>(dailyTarget),
      'status': serializer.toJson<String>(status),
      'totalChants': serializer.toJson<int>(totalChants),
      'totalWritings': serializer.toJson<int>(totalWritings),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  ProgramRow copyWith({
    String? id,
    String? profileId,
    String? mantraId,
    int? targetWritings,
    int? targetDays,
    DateTime? startedAt,
    int? dailyTarget,
    String? status,
    int? totalChants,
    int? totalWritings,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => ProgramRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    mantraId: mantraId ?? this.mantraId,
    targetWritings: targetWritings ?? this.targetWritings,
    targetDays: targetDays ?? this.targetDays,
    startedAt: startedAt ?? this.startedAt,
    dailyTarget: dailyTarget ?? this.dailyTarget,
    status: status ?? this.status,
    totalChants: totalChants ?? this.totalChants,
    totalWritings: totalWritings ?? this.totalWritings,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  ProgramRow copyWithCompanion(ProgramsCompanion data) {
    return ProgramRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      mantraId: data.mantraId.present ? data.mantraId.value : this.mantraId,
      targetWritings: data.targetWritings.present
          ? data.targetWritings.value
          : this.targetWritings,
      targetDays: data.targetDays.present
          ? data.targetDays.value
          : this.targetDays,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      dailyTarget: data.dailyTarget.present
          ? data.dailyTarget.value
          : this.dailyTarget,
      status: data.status.present ? data.status.value : this.status,
      totalChants: data.totalChants.present
          ? data.totalChants.value
          : this.totalChants,
      totalWritings: data.totalWritings.present
          ? data.totalWritings.value
          : this.totalWritings,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('mantraId: $mantraId, ')
          ..write('targetWritings: $targetWritings, ')
          ..write('targetDays: $targetDays, ')
          ..write('startedAt: $startedAt, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('status: $status, ')
          ..write('totalChants: $totalChants, ')
          ..write('totalWritings: $totalWritings, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    mantraId,
    targetWritings,
    targetDays,
    startedAt,
    dailyTarget,
    status,
    totalChants,
    totalWritings,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.mantraId == this.mantraId &&
          other.targetWritings == this.targetWritings &&
          other.targetDays == this.targetDays &&
          other.startedAt == this.startedAt &&
          other.dailyTarget == this.dailyTarget &&
          other.status == this.status &&
          other.totalChants == this.totalChants &&
          other.totalWritings == this.totalWritings &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class ProgramsCompanion extends UpdateCompanion<ProgramRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> mantraId;
  final Value<int> targetWritings;
  final Value<int> targetDays;
  final Value<DateTime> startedAt;
  final Value<int> dailyTarget;
  final Value<String> status;
  final Value<int> totalChants;
  final Value<int> totalWritings;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.mantraId = const Value.absent(),
    this.targetWritings = const Value.absent(),
    this.targetDays = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.dailyTarget = const Value.absent(),
    this.status = const Value.absent(),
    this.totalChants = const Value.absent(),
    this.totalWritings = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramsCompanion.insert({
    required String id,
    required String profileId,
    required String mantraId,
    required int targetWritings,
    required int targetDays,
    required DateTime startedAt,
    required int dailyTarget,
    this.status = const Value.absent(),
    this.totalChants = const Value.absent(),
    this.totalWritings = const Value.absent(),
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       mantraId = Value(mantraId),
       targetWritings = Value(targetWritings),
       targetDays = Value(targetDays),
       startedAt = Value(startedAt),
       dailyTarget = Value(dailyTarget),
       updatedAt = Value(updatedAt);
  static Insertable<ProgramRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? mantraId,
    Expression<int>? targetWritings,
    Expression<int>? targetDays,
    Expression<DateTime>? startedAt,
    Expression<int>? dailyTarget,
    Expression<String>? status,
    Expression<int>? totalChants,
    Expression<int>? totalWritings,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (mantraId != null) 'mantra_id': mantraId,
      if (targetWritings != null) 'target_writings': targetWritings,
      if (targetDays != null) 'target_days': targetDays,
      if (startedAt != null) 'started_at': startedAt,
      if (dailyTarget != null) 'daily_target': dailyTarget,
      if (status != null) 'status': status,
      if (totalChants != null) 'total_chants': totalChants,
      if (totalWritings != null) 'total_writings': totalWritings,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? mantraId,
    Value<int>? targetWritings,
    Value<int>? targetDays,
    Value<DateTime>? startedAt,
    Value<int>? dailyTarget,
    Value<String>? status,
    Value<int>? totalChants,
    Value<int>? totalWritings,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      mantraId: mantraId ?? this.mantraId,
      targetWritings: targetWritings ?? this.targetWritings,
      targetDays: targetDays ?? this.targetDays,
      startedAt: startedAt ?? this.startedAt,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      status: status ?? this.status,
      totalChants: totalChants ?? this.totalChants,
      totalWritings: totalWritings ?? this.totalWritings,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (mantraId.present) {
      map['mantra_id'] = Variable<String>(mantraId.value);
    }
    if (targetWritings.present) {
      map['target_writings'] = Variable<int>(targetWritings.value);
    }
    if (targetDays.present) {
      map['target_days'] = Variable<int>(targetDays.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (dailyTarget.present) {
      map['daily_target'] = Variable<int>(dailyTarget.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalChants.present) {
      map['total_chants'] = Variable<int>(totalChants.value);
    }
    if (totalWritings.present) {
      map['total_writings'] = Variable<int>(totalWritings.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('mantraId: $mantraId, ')
          ..write('targetWritings: $targetWritings, ')
          ..write('targetDays: $targetDays, ')
          ..write('startedAt: $startedAt, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('status: $status, ')
          ..write('totalChants: $totalChants, ')
          ..write('totalWritings: $totalWritings, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES programs(id) ON DELETE CASCADE',
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
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _modalityMeta = const VerificationMeta(
    'modality',
  );
  @override
  late final GeneratedColumn<String> modality = GeneratedColumn<String>(
    'modality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedHandwritingMeta = const VerificationMeta(
    'usedHandwriting',
  );
  @override
  late final GeneratedColumn<bool> usedHandwriting = GeneratedColumn<bool>(
    'used_handwriting',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("used_handwriting" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programId,
    startedAt,
    endedAt,
    count,
    modality,
    usedHandwriting,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
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
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('modality')) {
      context.handle(
        _modalityMeta,
        modality.isAcceptableOrUnknown(data['modality']!, _modalityMeta),
      );
    } else if (isInserting) {
      context.missing(_modalityMeta);
    }
    if (data.containsKey('used_handwriting')) {
      context.handle(
        _usedHandwritingMeta,
        usedHandwriting.isAcceptableOrUnknown(
          data['used_handwriting']!,
          _usedHandwritingMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      modality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modality'],
      )!,
      usedHandwriting: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}used_handwriting'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final String programId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int count;

  /// 'voice' | 'manual' | 'handwriting'
  final String modality;
  final bool usedHandwriting;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  const SessionRow({
    required this.id,
    required this.programId,
    required this.startedAt,
    this.endedAt,
    required this.count,
    required this.modality,
    required this.usedHandwriting,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['program_id'] = Variable<String>(programId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['count'] = Variable<int>(count);
    map['modality'] = Variable<String>(modality);
    map['used_handwriting'] = Variable<bool>(usedHandwriting);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      programId: Value(programId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      count: Value(count),
      modality: Value(modality),
      usedHandwriting: Value(usedHandwriting),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      count: serializer.fromJson<int>(json['count']),
      modality: serializer.fromJson<String>(json['modality']),
      usedHandwriting: serializer.fromJson<bool>(json['usedHandwriting']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'programId': serializer.toJson<String>(programId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'count': serializer.toJson<int>(count),
      'modality': serializer.toJson<String>(modality),
      'usedHandwriting': serializer.toJson<bool>(usedHandwriting),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SessionRow copyWith({
    String? id,
    String? programId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? count,
    String? modality,
    bool? usedHandwriting,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => SessionRow(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    count: count ?? this.count,
    modality: modality ?? this.modality,
    usedHandwriting: usedHandwriting ?? this.usedHandwriting,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      count: data.count.present ? data.count.value : this.count,
      modality: data.modality.present ? data.modality.value : this.modality,
      usedHandwriting: data.usedHandwriting.present
          ? data.usedHandwriting.value
          : this.usedHandwriting,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('count: $count, ')
          ..write('modality: $modality, ')
          ..write('usedHandwriting: $usedHandwriting, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    programId,
    startedAt,
    endedAt,
    count,
    modality,
    usedHandwriting,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.count == this.count &&
          other.modality == this.modality &&
          other.usedHandwriting == this.usedHandwriting &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<String> programId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> count;
  final Value<String> modality;
  final Value<bool> usedHandwriting;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.count = const Value.absent(),
    this.modality = const Value.absent(),
    this.usedHandwriting = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String programId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.count = const Value.absent(),
    required String modality,
    this.usedHandwriting = const Value.absent(),
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       programId = Value(programId),
       startedAt = Value(startedAt),
       modality = Value(modality),
       updatedAt = Value(updatedAt);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<String>? programId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? count,
    Expression<String>? modality,
    Expression<bool>? usedHandwriting,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (count != null) 'count': count,
      if (modality != null) 'modality': modality,
      if (usedHandwriting != null) 'used_handwriting': usedHandwriting,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? programId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? count,
    Value<String>? modality,
    Value<bool>? usedHandwriting,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      count: count ?? this.count,
      modality: modality ?? this.modality,
      usedHandwriting: usedHandwriting ?? this.usedHandwriting,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (modality.present) {
      map['modality'] = Variable<String>(modality.value);
    }
    if (usedHandwriting.present) {
      map['used_handwriting'] = Variable<bool>(usedHandwriting.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('count: $count, ')
          ..write('modality: $modality, ')
          ..write('usedHandwriting: $usedHandwriting, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RewardEventsTable extends RewardEvents
    with TableInfo<$RewardEventsTable, RewardEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RewardEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    kind,
    amount,
    source,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reward_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RewardEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RewardEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RewardEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $RewardEventsTable createAlias(String alias) {
    return $RewardEventsTable(attachedDatabase, alias);
  }
}

class RewardEventRow extends DataClass implements Insertable<RewardEventRow> {
  final String id;
  final String profileId;

  /// 'earn' | 'spend'
  final String kind;
  final int amount;
  final String source;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const RewardEventRow({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.amount,
    required this.source,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<int>(amount);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  RewardEventsCompanion toCompanion(bool nullToAbsent) {
    return RewardEventsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      kind: Value(kind),
      amount: Value(amount),
      source: Value(source),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory RewardEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RewardEventRow(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<int>(json['amount']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<int>(amount),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  RewardEventRow copyWith({
    String? id,
    String? profileId,
    String? kind,
    int? amount,
    String? source,
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => RewardEventRow(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  RewardEventRow copyWithCompanion(RewardEventsCompanion data) {
    return RewardEventRow(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RewardEventRow(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, kind, amount, source, createdAt, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RewardEventRow &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class RewardEventsCompanion extends UpdateCompanion<RewardEventRow> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> kind;
  final Value<int> amount;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const RewardEventsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RewardEventsCompanion.insert({
    required String id,
    required String profileId,
    required String kind,
    required int amount,
    required String source,
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       kind = Value(kind),
       amount = Value(amount),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<RewardEventRow> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RewardEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? kind,
    Value<int>? amount,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return RewardEventsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RewardEventsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $RewardEventsTable rewardEvents = $RewardEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    programs,
    sessions,
    rewardEvents,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'programs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProgramsTableCreateCompanionBuilder =
    ProgramsCompanion Function({
      required String id,
      required String profileId,
      required String mantraId,
      required int targetWritings,
      required int targetDays,
      required DateTime startedAt,
      required int dailyTarget,
      Value<String> status,
      Value<int> totalChants,
      Value<int> totalWritings,
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$ProgramsTableUpdateCompanionBuilder =
    ProgramsCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> mantraId,
      Value<int> targetWritings,
      Value<int> targetDays,
      Value<DateTime> startedAt,
      Value<int> dailyTarget,
      Value<String> status,
      Value<int> totalChants,
      Value<int> totalWritings,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

final class $$ProgramsTableReferences
    extends BaseReferences<_$AppDatabase, $ProgramsTable, ProgramRow> {
  $$ProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.programs.id, db.sessions.programId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
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

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mantraId => $composableBuilder(
    column: $table.mantraId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetWritings => $composableBuilder(
    column: $table.targetWritings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChants => $composableBuilder(
    column: $table.totalChants,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWritings => $composableBuilder(
    column: $table.totalWritings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
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

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mantraId => $composableBuilder(
    column: $table.mantraId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetWritings => $composableBuilder(
    column: $table.targetWritings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChants => $composableBuilder(
    column: $table.totalChants,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWritings => $composableBuilder(
    column: $table.totalWritings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get mantraId =>
      $composableBuilder(column: $table.mantraId, builder: (column) => column);

  GeneratedColumn<int> get targetWritings => $composableBuilder(
    column: $table.targetWritings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalChants => $composableBuilder(
    column: $table.totalChants,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalWritings => $composableBuilder(
    column: $table.totalWritings,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          ProgramRow,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (ProgramRow, $$ProgramsTableReferences),
          ProgramRow,
          PrefetchHooks Function({bool sessionsRefs})
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> mantraId = const Value.absent(),
                Value<int> targetWritings = const Value.absent(),
                Value<int> targetDays = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> dailyTarget = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalChants = const Value.absent(),
                Value<int> totalWritings = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                profileId: profileId,
                mantraId: mantraId,
                targetWritings: targetWritings,
                targetDays: targetDays,
                startedAt: startedAt,
                dailyTarget: dailyTarget,
                status: status,
                totalChants: totalChants,
                totalWritings: totalWritings,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String mantraId,
                required int targetWritings,
                required int targetDays,
                required DateTime startedAt,
                required int dailyTarget,
                Value<String> status = const Value.absent(),
                Value<int> totalChants = const Value.absent(),
                Value<int> totalWritings = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                profileId: profileId,
                mantraId: mantraId,
                targetWritings: targetWritings,
                targetDays: targetDays,
                startedAt: startedAt,
                dailyTarget: dailyTarget,
                status: status,
                totalChants: totalChants,
                totalWritings: totalWritings,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<
                      ProgramRow,
                      $ProgramsTable,
                      SessionRow
                    >(
                      currentTable: table,
                      referencedTable: $$ProgramsTableReferences
                          ._sessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProgramsTableReferences(db, table, p0).sessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.programId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      ProgramRow,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (ProgramRow, $$ProgramsTableReferences),
      ProgramRow,
      PrefetchHooks Function({bool sessionsRefs})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String programId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> count,
      required String modality,
      Value<bool> usedHandwriting,
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> programId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> count,
      Value<String> modality,
      Value<bool> usedHandwriting,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProgramsTable _programIdTable(_$AppDatabase db) => db.programs
      .createAlias($_aliasNameGenerator(db.sessions.programId, db.programs.id));

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<String>('program_id')!;

    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modality => $composableBuilder(
    column: $table.modality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get usedHandwriting => $composableBuilder(
    column: $table.usedHandwriting,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modality => $composableBuilder(
    column: $table.modality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get usedHandwriting => $composableBuilder(
    column: $table.usedHandwriting,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get modality =>
      $composableBuilder(column: $table.modality, builder: (column) => column);

  GeneratedColumn<bool> get usedHandwriting => $composableBuilder(
    column: $table.usedHandwriting,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool programId})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<String> modality = const Value.absent(),
                Value<bool> usedHandwriting = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                programId: programId,
                startedAt: startedAt,
                endedAt: endedAt,
                count: count,
                modality: modality,
                usedHandwriting: usedHandwriting,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String programId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> count = const Value.absent(),
                required String modality,
                Value<bool> usedHandwriting = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                programId: programId,
                startedAt: startedAt,
                endedAt: endedAt,
                count: count,
                modality: modality,
                usedHandwriting: usedHandwriting,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programId = false}) {
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
                    if (programId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programId,
                                referencedTable: $$SessionsTableReferences
                                    ._programIdTable(db),
                                referencedColumn: $$SessionsTableReferences
                                    ._programIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool programId})
    >;
typedef $$RewardEventsTableCreateCompanionBuilder =
    RewardEventsCompanion Function({
      required String id,
      required String profileId,
      required String kind,
      required int amount,
      required String source,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$RewardEventsTableUpdateCompanionBuilder =
    RewardEventsCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> kind,
      Value<int> amount,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$RewardEventsTableFilterComposer
    extends Composer<_$AppDatabase, $RewardEventsTable> {
  $$RewardEventsTableFilterComposer({
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

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RewardEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $RewardEventsTable> {
  $$RewardEventsTableOrderingComposer({
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

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RewardEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RewardEventsTable> {
  $$RewardEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$RewardEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RewardEventsTable,
          RewardEventRow,
          $$RewardEventsTableFilterComposer,
          $$RewardEventsTableOrderingComposer,
          $$RewardEventsTableAnnotationComposer,
          $$RewardEventsTableCreateCompanionBuilder,
          $$RewardEventsTableUpdateCompanionBuilder,
          (
            RewardEventRow,
            BaseReferences<_$AppDatabase, $RewardEventsTable, RewardEventRow>,
          ),
          RewardEventRow,
          PrefetchHooks Function()
        > {
  $$RewardEventsTableTableManager(_$AppDatabase db, $RewardEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RewardEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RewardEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RewardEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RewardEventsCompanion(
                id: id,
                profileId: profileId,
                kind: kind,
                amount: amount,
                source: source,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String kind,
                required int amount,
                required String source,
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RewardEventsCompanion.insert(
                id: id,
                profileId: profileId,
                kind: kind,
                amount: amount,
                source: source,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RewardEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RewardEventsTable,
      RewardEventRow,
      $$RewardEventsTableFilterComposer,
      $$RewardEventsTableOrderingComposer,
      $$RewardEventsTableAnnotationComposer,
      $$RewardEventsTableCreateCompanionBuilder,
      $$RewardEventsTableUpdateCompanionBuilder,
      (
        RewardEventRow,
        BaseReferences<_$AppDatabase, $RewardEventsTable, RewardEventRow>,
      ),
      RewardEventRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$RewardEventsTableTableManager get rewardEvents =>
      $$RewardEventsTableTableManager(_db, _db.rewardEvents);
}
