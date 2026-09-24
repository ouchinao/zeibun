// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LawsTable extends Laws with TableInfo<$LawsTable, Law> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LawsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lawIdMeta = const VerificationMeta('lawId');
  @override
  late final GeneratedColumn<String> lawId = GeneratedColumn<String>(
      'law_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lawNumMeta = const VerificationMeta('lawNum');
  @override
  late final GeneratedColumn<String> lawNum = GeneratedColumn<String>(
      'law_num', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lawTypeMeta =
      const VerificationMeta('lawType');
  @override
  late final GeneratedColumn<String> lawType = GeneratedColumn<String>(
      'law_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleKanaMeta =
      const VerificationMeta('titleKana');
  @override
  late final GeneratedColumn<String> titleKana = GeneratedColumn<String>(
      'title_kana', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _abbrevMeta = const VerificationMeta('abbrev');
  @override
  late final GeneratedColumn<String> abbrev = GeneratedColumn<String>(
      'abbrev', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _promulgationDateMeta =
      const VerificationMeta('promulgationDate');
  @override
  late final GeneratedColumn<String> promulgationDate = GeneratedColumn<String>(
      'promulgation_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repealStatusMeta =
      const VerificationMeta('repealStatus');
  @override
  late final GeneratedColumn<String> repealStatus = GeneratedColumn<String>(
      'repeal_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('None'));
  static const VerificationMeta _repealDateMeta =
      const VerificationMeta('repealDate');
  @override
  late final GeneratedColumn<String> repealDate = GeneratedColumn<String>(
      'repeal_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scopeReasonMeta =
      const VerificationMeta('scopeReason');
  @override
  late final GeneratedColumn<String> scopeReason = GeneratedColumn<String>(
      'scope_reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentRevisionIdMeta =
      const VerificationMeta('currentRevisionId');
  @override
  late final GeneratedColumn<String> currentRevisionId =
      GeneratedColumn<String>('current_revision_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currentEnforcedAtMeta =
      const VerificationMeta('currentEnforcedAt');
  @override
  late final GeneratedColumn<String> currentEnforcedAt =
      GeneratedColumn<String>('current_enforced_at', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amendmentLawTitleMeta =
      const VerificationMeta('amendmentLawTitle');
  @override
  late final GeneratedColumn<String> amendmentLawTitle =
      GeneratedColumn<String>('amendment_law_title', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _catalogUpdatedMeta =
      const VerificationMeta('catalogUpdated');
  @override
  late final GeneratedColumn<String> catalogUpdated = GeneratedColumn<String>(
      'catalog_updated', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pendingRevisionIdMeta =
      const VerificationMeta('pendingRevisionId');
  @override
  late final GeneratedColumn<String> pendingRevisionId =
      GeneratedColumn<String>('pending_revision_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyRevisionIdMeta =
      const VerificationMeta('bodyRevisionId');
  @override
  late final GeneratedColumn<String> bodyRevisionId = GeneratedColumn<String>(
      'body_revision_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodySyncedAtMeta =
      const VerificationMeta('bodySyncedAt');
  @override
  late final GeneratedColumn<String> bodySyncedAt = GeneratedColumn<String>(
      'body_synced_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyIncludesAmendSupplMeta =
      const VerificationMeta('bodyIncludesAmendSuppl');
  @override
  late final GeneratedColumn<bool> bodyIncludesAmendSuppl =
      GeneratedColumn<bool>('body_includes_amend_suppl', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("body_includes_amend_suppl" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _missingSinceMeta =
      const VerificationMeta('missingSince');
  @override
  late final GeneratedColumn<String> missingSince = GeneratedColumn<String>(
      'missing_since', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<String> lastOpenedAt = GeneratedColumn<String>(
      'last_opened_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        lawId,
        lawNum,
        lawType,
        title,
        titleKana,
        abbrev,
        category,
        promulgationDate,
        repealStatus,
        repealDate,
        scopeReason,
        currentRevisionId,
        currentEnforcedAt,
        amendmentLawTitle,
        catalogUpdated,
        pendingRevisionId,
        bodyRevisionId,
        bodySyncedAt,
        bodyIncludesAmendSuppl,
        missingSince,
        lastOpenedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'laws';
  @override
  VerificationContext validateIntegrity(Insertable<Law> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('law_id')) {
      context.handle(
          _lawIdMeta, lawId.isAcceptableOrUnknown(data['law_id']!, _lawIdMeta));
    } else if (isInserting) {
      context.missing(_lawIdMeta);
    }
    if (data.containsKey('law_num')) {
      context.handle(_lawNumMeta,
          lawNum.isAcceptableOrUnknown(data['law_num']!, _lawNumMeta));
    } else if (isInserting) {
      context.missing(_lawNumMeta);
    }
    if (data.containsKey('law_type')) {
      context.handle(_lawTypeMeta,
          lawType.isAcceptableOrUnknown(data['law_type']!, _lawTypeMeta));
    } else if (isInserting) {
      context.missing(_lawTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_kana')) {
      context.handle(_titleKanaMeta,
          titleKana.isAcceptableOrUnknown(data['title_kana']!, _titleKanaMeta));
    }
    if (data.containsKey('abbrev')) {
      context.handle(_abbrevMeta,
          abbrev.isAcceptableOrUnknown(data['abbrev']!, _abbrevMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('promulgation_date')) {
      context.handle(
          _promulgationDateMeta,
          promulgationDate.isAcceptableOrUnknown(
              data['promulgation_date']!, _promulgationDateMeta));
    }
    if (data.containsKey('repeal_status')) {
      context.handle(
          _repealStatusMeta,
          repealStatus.isAcceptableOrUnknown(
              data['repeal_status']!, _repealStatusMeta));
    }
    if (data.containsKey('repeal_date')) {
      context.handle(
          _repealDateMeta,
          repealDate.isAcceptableOrUnknown(
              data['repeal_date']!, _repealDateMeta));
    }
    if (data.containsKey('scope_reason')) {
      context.handle(
          _scopeReasonMeta,
          scopeReason.isAcceptableOrUnknown(
              data['scope_reason']!, _scopeReasonMeta));
    } else if (isInserting) {
      context.missing(_scopeReasonMeta);
    }
    if (data.containsKey('current_revision_id')) {
      context.handle(
          _currentRevisionIdMeta,
          currentRevisionId.isAcceptableOrUnknown(
              data['current_revision_id']!, _currentRevisionIdMeta));
    }
    if (data.containsKey('current_enforced_at')) {
      context.handle(
          _currentEnforcedAtMeta,
          currentEnforcedAt.isAcceptableOrUnknown(
              data['current_enforced_at']!, _currentEnforcedAtMeta));
    }
    if (data.containsKey('amendment_law_title')) {
      context.handle(
          _amendmentLawTitleMeta,
          amendmentLawTitle.isAcceptableOrUnknown(
              data['amendment_law_title']!, _amendmentLawTitleMeta));
    }
    if (data.containsKey('catalog_updated')) {
      context.handle(
          _catalogUpdatedMeta,
          catalogUpdated.isAcceptableOrUnknown(
              data['catalog_updated']!, _catalogUpdatedMeta));
    }
    if (data.containsKey('pending_revision_id')) {
      context.handle(
          _pendingRevisionIdMeta,
          pendingRevisionId.isAcceptableOrUnknown(
              data['pending_revision_id']!, _pendingRevisionIdMeta));
    }
    if (data.containsKey('body_revision_id')) {
      context.handle(
          _bodyRevisionIdMeta,
          bodyRevisionId.isAcceptableOrUnknown(
              data['body_revision_id']!, _bodyRevisionIdMeta));
    }
    if (data.containsKey('body_synced_at')) {
      context.handle(
          _bodySyncedAtMeta,
          bodySyncedAt.isAcceptableOrUnknown(
              data['body_synced_at']!, _bodySyncedAtMeta));
    }
    if (data.containsKey('body_includes_amend_suppl')) {
      context.handle(
          _bodyIncludesAmendSupplMeta,
          bodyIncludesAmendSuppl.isAcceptableOrUnknown(
              data['body_includes_amend_suppl']!, _bodyIncludesAmendSupplMeta));
    }
    if (data.containsKey('missing_since')) {
      context.handle(
          _missingSinceMeta,
          missingSince.isAcceptableOrUnknown(
              data['missing_since']!, _missingSinceMeta));
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lawId};
  @override
  Law map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Law(
      lawId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}law_id'])!,
      lawNum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}law_num'])!,
      lawType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}law_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      titleKana: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_kana']),
      abbrev: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}abbrev']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      promulgationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}promulgation_date']),
      repealStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeal_status'])!,
      repealDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeal_date']),
      scopeReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope_reason'])!,
      currentRevisionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_revision_id']),
      currentEnforcedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_enforced_at']),
      amendmentLawTitle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}amendment_law_title']),
      catalogUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}catalog_updated']),
      pendingRevisionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pending_revision_id']),
      bodyRevisionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}body_revision_id']),
      bodySyncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_synced_at']),
      bodyIncludesAmendSuppl: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}body_includes_amend_suppl'])!,
      missingSince: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}missing_since']),
      lastOpenedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_opened_at']),
    );
  }

  @override
  $LawsTable createAlias(String alias) {
    return $LawsTable(attachedDatabase, alias);
  }
}

class Law extends DataClass implements Insertable<Law> {
  final String lawId;
  final String lawNum;
  final String lawType;
  final String title;
  final String? titleKana;
  final String? abbrev;
  final String? category;
  final String? promulgationDate;
  final String repealStatus;
  final String? repealDate;
  final String scopeReason;
  final String? currentRevisionId;
  final String? currentEnforcedAt;
  final String? amendmentLawTitle;
  final String? catalogUpdated;

  /// 未施行改正があるときの、asof 遠未来側のリビジョン。
  final String? pendingRevisionId;
  final String? bodyRevisionId;
  final String? bodySyncedAt;
  final bool bodyIncludesAmendSuppl;
  final String? missingSince;
  final String? lastOpenedAt;
  const Law(
      {required this.lawId,
      required this.lawNum,
      required this.lawType,
      required this.title,
      this.titleKana,
      this.abbrev,
      this.category,
      this.promulgationDate,
      required this.repealStatus,
      this.repealDate,
      required this.scopeReason,
      this.currentRevisionId,
      this.currentEnforcedAt,
      this.amendmentLawTitle,
      this.catalogUpdated,
      this.pendingRevisionId,
      this.bodyRevisionId,
      this.bodySyncedAt,
      required this.bodyIncludesAmendSuppl,
      this.missingSince,
      this.lastOpenedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['law_id'] = Variable<String>(lawId);
    map['law_num'] = Variable<String>(lawNum);
    map['law_type'] = Variable<String>(lawType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || titleKana != null) {
      map['title_kana'] = Variable<String>(titleKana);
    }
    if (!nullToAbsent || abbrev != null) {
      map['abbrev'] = Variable<String>(abbrev);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || promulgationDate != null) {
      map['promulgation_date'] = Variable<String>(promulgationDate);
    }
    map['repeal_status'] = Variable<String>(repealStatus);
    if (!nullToAbsent || repealDate != null) {
      map['repeal_date'] = Variable<String>(repealDate);
    }
    map['scope_reason'] = Variable<String>(scopeReason);
    if (!nullToAbsent || currentRevisionId != null) {
      map['current_revision_id'] = Variable<String>(currentRevisionId);
    }
    if (!nullToAbsent || currentEnforcedAt != null) {
      map['current_enforced_at'] = Variable<String>(currentEnforcedAt);
    }
    if (!nullToAbsent || amendmentLawTitle != null) {
      map['amendment_law_title'] = Variable<String>(amendmentLawTitle);
    }
    if (!nullToAbsent || catalogUpdated != null) {
      map['catalog_updated'] = Variable<String>(catalogUpdated);
    }
    if (!nullToAbsent || pendingRevisionId != null) {
      map['pending_revision_id'] = Variable<String>(pendingRevisionId);
    }
    if (!nullToAbsent || bodyRevisionId != null) {
      map['body_revision_id'] = Variable<String>(bodyRevisionId);
    }
    if (!nullToAbsent || bodySyncedAt != null) {
      map['body_synced_at'] = Variable<String>(bodySyncedAt);
    }
    map['body_includes_amend_suppl'] = Variable<bool>(bodyIncludesAmendSuppl);
    if (!nullToAbsent || missingSince != null) {
      map['missing_since'] = Variable<String>(missingSince);
    }
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<String>(lastOpenedAt);
    }
    return map;
  }

  LawsCompanion toCompanion(bool nullToAbsent) {
    return LawsCompanion(
      lawId: Value(lawId),
      lawNum: Value(lawNum),
      lawType: Value(lawType),
      title: Value(title),
      titleKana: titleKana == null && nullToAbsent
          ? const Value.absent()
          : Value(titleKana),
      abbrev:
          abbrev == null && nullToAbsent ? const Value.absent() : Value(abbrev),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      promulgationDate: promulgationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(promulgationDate),
      repealStatus: Value(repealStatus),
      repealDate: repealDate == null && nullToAbsent
          ? const Value.absent()
          : Value(repealDate),
      scopeReason: Value(scopeReason),
      currentRevisionId: currentRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentRevisionId),
      currentEnforcedAt: currentEnforcedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(currentEnforcedAt),
      amendmentLawTitle: amendmentLawTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(amendmentLawTitle),
      catalogUpdated: catalogUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogUpdated),
      pendingRevisionId: pendingRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingRevisionId),
      bodyRevisionId: bodyRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyRevisionId),
      bodySyncedAt: bodySyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(bodySyncedAt),
      bodyIncludesAmendSuppl: Value(bodyIncludesAmendSuppl),
      missingSince: missingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(missingSince),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
    );
  }

  factory Law.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Law(
      lawId: serializer.fromJson<String>(json['lawId']),
      lawNum: serializer.fromJson<String>(json['lawNum']),
      lawType: serializer.fromJson<String>(json['lawType']),
      title: serializer.fromJson<String>(json['title']),
      titleKana: serializer.fromJson<String?>(json['titleKana']),
      abbrev: serializer.fromJson<String?>(json['abbrev']),
      category: serializer.fromJson<String?>(json['category']),
      promulgationDate: serializer.fromJson<String?>(json['promulgationDate']),
      repealStatus: serializer.fromJson<String>(json['repealStatus']),
      repealDate: serializer.fromJson<String?>(json['repealDate']),
      scopeReason: serializer.fromJson<String>(json['scopeReason']),
      currentRevisionId:
          serializer.fromJson<String?>(json['currentRevisionId']),
      currentEnforcedAt:
          serializer.fromJson<String?>(json['currentEnforcedAt']),
      amendmentLawTitle:
          serializer.fromJson<String?>(json['amendmentLawTitle']),
      catalogUpdated: serializer.fromJson<String?>(json['catalogUpdated']),
      pendingRevisionId:
          serializer.fromJson<String?>(json['pendingRevisionId']),
      bodyRevisionId: serializer.fromJson<String?>(json['bodyRevisionId']),
      bodySyncedAt: serializer.fromJson<String?>(json['bodySyncedAt']),
      bodyIncludesAmendSuppl:
          serializer.fromJson<bool>(json['bodyIncludesAmendSuppl']),
      missingSince: serializer.fromJson<String?>(json['missingSince']),
      lastOpenedAt: serializer.fromJson<String?>(json['lastOpenedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lawId': serializer.toJson<String>(lawId),
      'lawNum': serializer.toJson<String>(lawNum),
      'lawType': serializer.toJson<String>(lawType),
      'title': serializer.toJson<String>(title),
      'titleKana': serializer.toJson<String?>(titleKana),
      'abbrev': serializer.toJson<String?>(abbrev),
      'category': serializer.toJson<String?>(category),
      'promulgationDate': serializer.toJson<String?>(promulgationDate),
      'repealStatus': serializer.toJson<String>(repealStatus),
      'repealDate': serializer.toJson<String?>(repealDate),
      'scopeReason': serializer.toJson<String>(scopeReason),
      'currentRevisionId': serializer.toJson<String?>(currentRevisionId),
      'currentEnforcedAt': serializer.toJson<String?>(currentEnforcedAt),
      'amendmentLawTitle': serializer.toJson<String?>(amendmentLawTitle),
      'catalogUpdated': serializer.toJson<String?>(catalogUpdated),
      'pendingRevisionId': serializer.toJson<String?>(pendingRevisionId),
      'bodyRevisionId': serializer.toJson<String?>(bodyRevisionId),
      'bodySyncedAt': serializer.toJson<String?>(bodySyncedAt),
      'bodyIncludesAmendSuppl': serializer.toJson<bool>(bodyIncludesAmendSuppl),
      'missingSince': serializer.toJson<String?>(missingSince),
      'lastOpenedAt': serializer.toJson<String?>(lastOpenedAt),
    };
  }

  Law copyWith(
          {String? lawId,
          String? lawNum,
          String? lawType,
          String? title,
          Value<String?> titleKana = const Value.absent(),
          Value<String?> abbrev = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> promulgationDate = const Value.absent(),
          String? repealStatus,
          Value<String?> repealDate = const Value.absent(),
          String? scopeReason,
          Value<String?> currentRevisionId = const Value.absent(),
          Value<String?> currentEnforcedAt = const Value.absent(),
          Value<String?> amendmentLawTitle = const Value.absent(),
          Value<String?> catalogUpdated = const Value.absent(),
          Value<String?> pendingRevisionId = const Value.absent(),
          Value<String?> bodyRevisionId = const Value.absent(),
          Value<String?> bodySyncedAt = const Value.absent(),
          bool? bodyIncludesAmendSuppl,
          Value<String?> missingSince = const Value.absent(),
          Value<String?> lastOpenedAt = const Value.absent()}) =>
      Law(
        lawId: lawId ?? this.lawId,
        lawNum: lawNum ?? this.lawNum,
        lawType: lawType ?? this.lawType,
        title: title ?? this.title,
        titleKana: titleKana.present ? titleKana.value : this.titleKana,
        abbrev: abbrev.present ? abbrev.value : this.abbrev,
        category: category.present ? category.value : this.category,
        promulgationDate: promulgationDate.present
            ? promulgationDate.value
            : this.promulgationDate,
        repealStatus: repealStatus ?? this.repealStatus,
        repealDate: repealDate.present ? repealDate.value : this.repealDate,
        scopeReason: scopeReason ?? this.scopeReason,
        currentRevisionId: currentRevisionId.present
            ? currentRevisionId.value
            : this.currentRevisionId,
        currentEnforcedAt: currentEnforcedAt.present
            ? currentEnforcedAt.value
            : this.currentEnforcedAt,
        amendmentLawTitle: amendmentLawTitle.present
            ? amendmentLawTitle.value
            : this.amendmentLawTitle,
        catalogUpdated:
            catalogUpdated.present ? catalogUpdated.value : this.catalogUpdated,
        pendingRevisionId: pendingRevisionId.present
            ? pendingRevisionId.value
            : this.pendingRevisionId,
        bodyRevisionId:
            bodyRevisionId.present ? bodyRevisionId.value : this.bodyRevisionId,
        bodySyncedAt:
            bodySyncedAt.present ? bodySyncedAt.value : this.bodySyncedAt,
        bodyIncludesAmendSuppl:
            bodyIncludesAmendSuppl ?? this.bodyIncludesAmendSuppl,
        missingSince:
            missingSince.present ? missingSince.value : this.missingSince,
        lastOpenedAt:
            lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
      );
  Law copyWithCompanion(LawsCompanion data) {
    return Law(
      lawId: data.lawId.present ? data.lawId.value : this.lawId,
      lawNum: data.lawNum.present ? data.lawNum.value : this.lawNum,
      lawType: data.lawType.present ? data.lawType.value : this.lawType,
      title: data.title.present ? data.title.value : this.title,
      titleKana: data.titleKana.present ? data.titleKana.value : this.titleKana,
      abbrev: data.abbrev.present ? data.abbrev.value : this.abbrev,
      category: data.category.present ? data.category.value : this.category,
      promulgationDate: data.promulgationDate.present
          ? data.promulgationDate.value
          : this.promulgationDate,
      repealStatus: data.repealStatus.present
          ? data.repealStatus.value
          : this.repealStatus,
      repealDate:
          data.repealDate.present ? data.repealDate.value : this.repealDate,
      scopeReason:
          data.scopeReason.present ? data.scopeReason.value : this.scopeReason,
      currentRevisionId: data.currentRevisionId.present
          ? data.currentRevisionId.value
          : this.currentRevisionId,
      currentEnforcedAt: data.currentEnforcedAt.present
          ? data.currentEnforcedAt.value
          : this.currentEnforcedAt,
      amendmentLawTitle: data.amendmentLawTitle.present
          ? data.amendmentLawTitle.value
          : this.amendmentLawTitle,
      catalogUpdated: data.catalogUpdated.present
          ? data.catalogUpdated.value
          : this.catalogUpdated,
      pendingRevisionId: data.pendingRevisionId.present
          ? data.pendingRevisionId.value
          : this.pendingRevisionId,
      bodyRevisionId: data.bodyRevisionId.present
          ? data.bodyRevisionId.value
          : this.bodyRevisionId,
      bodySyncedAt: data.bodySyncedAt.present
          ? data.bodySyncedAt.value
          : this.bodySyncedAt,
      bodyIncludesAmendSuppl: data.bodyIncludesAmendSuppl.present
          ? data.bodyIncludesAmendSuppl.value
          : this.bodyIncludesAmendSuppl,
      missingSince: data.missingSince.present
          ? data.missingSince.value
          : this.missingSince,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Law(')
          ..write('lawId: $lawId, ')
          ..write('lawNum: $lawNum, ')
          ..write('lawType: $lawType, ')
          ..write('title: $title, ')
          ..write('titleKana: $titleKana, ')
          ..write('abbrev: $abbrev, ')
          ..write('category: $category, ')
          ..write('promulgationDate: $promulgationDate, ')
          ..write('repealStatus: $repealStatus, ')
          ..write('repealDate: $repealDate, ')
          ..write('scopeReason: $scopeReason, ')
          ..write('currentRevisionId: $currentRevisionId, ')
          ..write('currentEnforcedAt: $currentEnforcedAt, ')
          ..write('amendmentLawTitle: $amendmentLawTitle, ')
          ..write('catalogUpdated: $catalogUpdated, ')
          ..write('pendingRevisionId: $pendingRevisionId, ')
          ..write('bodyRevisionId: $bodyRevisionId, ')
          ..write('bodySyncedAt: $bodySyncedAt, ')
          ..write('bodyIncludesAmendSuppl: $bodyIncludesAmendSuppl, ')
          ..write('missingSince: $missingSince, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        lawId,
        lawNum,
        lawType,
        title,
        titleKana,
        abbrev,
        category,
        promulgationDate,
        repealStatus,
        repealDate,
        scopeReason,
        currentRevisionId,
        currentEnforcedAt,
        amendmentLawTitle,
        catalogUpdated,
        pendingRevisionId,
        bodyRevisionId,
        bodySyncedAt,
        bodyIncludesAmendSuppl,
        missingSince,
        lastOpenedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Law &&
          other.lawId == this.lawId &&
          other.lawNum == this.lawNum &&
          other.lawType == this.lawType &&
          other.title == this.title &&
          other.titleKana == this.titleKana &&
          other.abbrev == this.abbrev &&
          other.category == this.category &&
          other.promulgationDate == this.promulgationDate &&
          other.repealStatus == this.repealStatus &&
          other.repealDate == this.repealDate &&
          other.scopeReason == this.scopeReason &&
          other.currentRevisionId == this.currentRevisionId &&
          other.currentEnforcedAt == this.currentEnforcedAt &&
          other.amendmentLawTitle == this.amendmentLawTitle &&
          other.catalogUpdated == this.catalogUpdated &&
          other.pendingRevisionId == this.pendingRevisionId &&
          other.bodyRevisionId == this.bodyRevisionId &&
          other.bodySyncedAt == this.bodySyncedAt &&
          other.bodyIncludesAmendSuppl == this.bodyIncludesAmendSuppl &&
          other.missingSince == this.missingSince &&
          other.lastOpenedAt == this.lastOpenedAt);
}

class LawsCompanion extends UpdateCompanion<Law> {
  final Value<String> lawId;
  final Value<String> lawNum;
  final Value<String> lawType;
  final Value<String> title;
  final Value<String?> titleKana;
  final Value<String?> abbrev;
  final Value<String?> category;
  final Value<String?> promulgationDate;
  final Value<String> repealStatus;
  final Value<String?> repealDate;
  final Value<String> scopeReason;
  final Value<String?> currentRevisionId;
  final Value<String?> currentEnforcedAt;
  final Value<String?> amendmentLawTitle;
  final Value<String?> catalogUpdated;
  final Value<String?> pendingRevisionId;
  final Value<String?> bodyRevisionId;
  final Value<String?> bodySyncedAt;
  final Value<bool> bodyIncludesAmendSuppl;
  final Value<String?> missingSince;
  final Value<String?> lastOpenedAt;
  final Value<int> rowid;
  const LawsCompanion({
    this.lawId = const Value.absent(),
    this.lawNum = const Value.absent(),
    this.lawType = const Value.absent(),
    this.title = const Value.absent(),
    this.titleKana = const Value.absent(),
    this.abbrev = const Value.absent(),
    this.category = const Value.absent(),
    this.promulgationDate = const Value.absent(),
    this.repealStatus = const Value.absent(),
    this.repealDate = const Value.absent(),
    this.scopeReason = const Value.absent(),
    this.currentRevisionId = const Value.absent(),
    this.currentEnforcedAt = const Value.absent(),
    this.amendmentLawTitle = const Value.absent(),
    this.catalogUpdated = const Value.absent(),
    this.pendingRevisionId = const Value.absent(),
    this.bodyRevisionId = const Value.absent(),
    this.bodySyncedAt = const Value.absent(),
    this.bodyIncludesAmendSuppl = const Value.absent(),
    this.missingSince = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LawsCompanion.insert({
    required String lawId,
    required String lawNum,
    required String lawType,
    required String title,
    this.titleKana = const Value.absent(),
    this.abbrev = const Value.absent(),
    this.category = const Value.absent(),
    this.promulgationDate = const Value.absent(),
    this.repealStatus = const Value.absent(),
    this.repealDate = const Value.absent(),
    required String scopeReason,
    this.currentRevisionId = const Value.absent(),
    this.currentEnforcedAt = const Value.absent(),
    this.amendmentLawTitle = const Value.absent(),
    this.catalogUpdated = const Value.absent(),
    this.pendingRevisionId = const Value.absent(),
    this.bodyRevisionId = const Value.absent(),
    this.bodySyncedAt = const Value.absent(),
    this.bodyIncludesAmendSuppl = const Value.absent(),
    this.missingSince = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : lawId = Value(lawId),
        lawNum = Value(lawNum),
        lawType = Value(lawType),
        title = Value(title),
        scopeReason = Value(scopeReason);
  static Insertable<Law> custom({
    Expression<String>? lawId,
    Expression<String>? lawNum,
    Expression<String>? lawType,
    Expression<String>? title,
    Expression<String>? titleKana,
    Expression<String>? abbrev,
    Expression<String>? category,
    Expression<String>? promulgationDate,
    Expression<String>? repealStatus,
    Expression<String>? repealDate,
    Expression<String>? scopeReason,
    Expression<String>? currentRevisionId,
    Expression<String>? currentEnforcedAt,
    Expression<String>? amendmentLawTitle,
    Expression<String>? catalogUpdated,
    Expression<String>? pendingRevisionId,
    Expression<String>? bodyRevisionId,
    Expression<String>? bodySyncedAt,
    Expression<bool>? bodyIncludesAmendSuppl,
    Expression<String>? missingSince,
    Expression<String>? lastOpenedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lawId != null) 'law_id': lawId,
      if (lawNum != null) 'law_num': lawNum,
      if (lawType != null) 'law_type': lawType,
      if (title != null) 'title': title,
      if (titleKana != null) 'title_kana': titleKana,
      if (abbrev != null) 'abbrev': abbrev,
      if (category != null) 'category': category,
      if (promulgationDate != null) 'promulgation_date': promulgationDate,
      if (repealStatus != null) 'repeal_status': repealStatus,
      if (repealDate != null) 'repeal_date': repealDate,
      if (scopeReason != null) 'scope_reason': scopeReason,
      if (currentRevisionId != null) 'current_revision_id': currentRevisionId,
      if (currentEnforcedAt != null) 'current_enforced_at': currentEnforcedAt,
      if (amendmentLawTitle != null) 'amendment_law_title': amendmentLawTitle,
      if (catalogUpdated != null) 'catalog_updated': catalogUpdated,
      if (pendingRevisionId != null) 'pending_revision_id': pendingRevisionId,
      if (bodyRevisionId != null) 'body_revision_id': bodyRevisionId,
      if (bodySyncedAt != null) 'body_synced_at': bodySyncedAt,
      if (bodyIncludesAmendSuppl != null)
        'body_includes_amend_suppl': bodyIncludesAmendSuppl,
      if (missingSince != null) 'missing_since': missingSince,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LawsCompanion copyWith(
      {Value<String>? lawId,
      Value<String>? lawNum,
      Value<String>? lawType,
      Value<String>? title,
      Value<String?>? titleKana,
      Value<String?>? abbrev,
      Value<String?>? category,
      Value<String?>? promulgationDate,
      Value<String>? repealStatus,
      Value<String?>? repealDate,
      Value<String>? scopeReason,
      Value<String?>? currentRevisionId,
      Value<String?>? currentEnforcedAt,
      Value<String?>? amendmentLawTitle,
      Value<String?>? catalogUpdated,
      Value<String?>? pendingRevisionId,
      Value<String?>? bodyRevisionId,
      Value<String?>? bodySyncedAt,
      Value<bool>? bodyIncludesAmendSuppl,
      Value<String?>? missingSince,
      Value<String?>? lastOpenedAt,
      Value<int>? rowid}) {
    return LawsCompanion(
      lawId: lawId ?? this.lawId,
      lawNum: lawNum ?? this.lawNum,
      lawType: lawType ?? this.lawType,
      title: title ?? this.title,
      titleKana: titleKana ?? this.titleKana,
      abbrev: abbrev ?? this.abbrev,
      category: category ?? this.category,
      promulgationDate: promulgationDate ?? this.promulgationDate,
      repealStatus: repealStatus ?? this.repealStatus,
      repealDate: repealDate ?? this.repealDate,
      scopeReason: scopeReason ?? this.scopeReason,
      currentRevisionId: currentRevisionId ?? this.currentRevisionId,
      currentEnforcedAt: currentEnforcedAt ?? this.currentEnforcedAt,
      amendmentLawTitle: amendmentLawTitle ?? this.amendmentLawTitle,
      catalogUpdated: catalogUpdated ?? this.catalogUpdated,
      pendingRevisionId: pendingRevisionId ?? this.pendingRevisionId,
      bodyRevisionId: bodyRevisionId ?? this.bodyRevisionId,
      bodySyncedAt: bodySyncedAt ?? this.bodySyncedAt,
      bodyIncludesAmendSuppl:
          bodyIncludesAmendSuppl ?? this.bodyIncludesAmendSuppl,
      missingSince: missingSince ?? this.missingSince,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lawId.present) {
      map['law_id'] = Variable<String>(lawId.value);
    }
    if (lawNum.present) {
      map['law_num'] = Variable<String>(lawNum.value);
    }
    if (lawType.present) {
      map['law_type'] = Variable<String>(lawType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleKana.present) {
      map['title_kana'] = Variable<String>(titleKana.value);
    }
    if (abbrev.present) {
      map['abbrev'] = Variable<String>(abbrev.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (promulgationDate.present) {
      map['promulgation_date'] = Variable<String>(promulgationDate.value);
    }
    if (repealStatus.present) {
      map['repeal_status'] = Variable<String>(repealStatus.value);
    }
    if (repealDate.present) {
      map['repeal_date'] = Variable<String>(repealDate.value);
    }
    if (scopeReason.present) {
      map['scope_reason'] = Variable<String>(scopeReason.value);
    }
    if (currentRevisionId.present) {
      map['current_revision_id'] = Variable<String>(currentRevisionId.value);
    }
    if (currentEnforcedAt.present) {
      map['current_enforced_at'] = Variable<String>(currentEnforcedAt.value);
    }
    if (amendmentLawTitle.present) {
      map['amendment_law_title'] = Variable<String>(amendmentLawTitle.value);
    }
    if (catalogUpdated.present) {
      map['catalog_updated'] = Variable<String>(catalogUpdated.value);
    }
    if (pendingRevisionId.present) {
      map['pending_revision_id'] = Variable<String>(pendingRevisionId.value);
    }
    if (bodyRevisionId.present) {
      map['body_revision_id'] = Variable<String>(bodyRevisionId.value);
    }
    if (bodySyncedAt.present) {
      map['body_synced_at'] = Variable<String>(bodySyncedAt.value);
    }
    if (bodyIncludesAmendSuppl.present) {
      map['body_includes_amend_suppl'] =
          Variable<bool>(bodyIncludesAmendSuppl.value);
    }
    if (missingSince.present) {
      map['missing_since'] = Variable<String>(missingSince.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<String>(lastOpenedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LawsCompanion(')
          ..write('lawId: $lawId, ')
          ..write('lawNum: $lawNum, ')
          ..write('lawType: $lawType, ')
          ..write('title: $title, ')
          ..write('titleKana: $titleKana, ')
          ..write('abbrev: $abbrev, ')
          ..write('category: $category, ')
          ..write('promulgationDate: $promulgationDate, ')
          ..write('repealStatus: $repealStatus, ')
          ..write('repealDate: $repealDate, ')
          ..write('scopeReason: $scopeReason, ')
          ..write('currentRevisionId: $currentRevisionId, ')
          ..write('currentEnforcedAt: $currentEnforcedAt, ')
          ..write('amendmentLawTitle: $amendmentLawTitle, ')
          ..write('catalogUpdated: $catalogUpdated, ')
          ..write('pendingRevisionId: $pendingRevisionId, ')
          ..write('bodyRevisionId: $bodyRevisionId, ')
          ..write('bodySyncedAt: $bodySyncedAt, ')
          ..write('bodyIncludesAmendSuppl: $bodyIncludesAmendSuppl, ')
          ..write('missingSince: $missingSince, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LawRevisionsTable extends LawRevisions
    with TableInfo<$LawRevisionsTable, LawRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LawRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _revisionIdMeta =
      const VerificationMeta('revisionId');
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
      'revision_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lawIdMeta = const VerificationMeta('lawId');
  @override
  late final GeneratedColumn<String> lawId = GeneratedColumn<String>(
      'law_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES laws (law_id)'));
  static const VerificationMeta _enforcedAtMeta =
      const VerificationMeta('enforcedAt');
  @override
  late final GeneratedColumn<String> enforcedAt = GeneratedColumn<String>(
      'enforced_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _promulgatedAtMeta =
      const VerificationMeta('promulgatedAt');
  @override
  late final GeneratedColumn<String> promulgatedAt = GeneratedColumn<String>(
      'promulgated_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scheduledEnforcedAtMeta =
      const VerificationMeta('scheduledEnforcedAt');
  @override
  late final GeneratedColumn<String> scheduledEnforcedAt =
      GeneratedColumn<String>('scheduled_enforced_at', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enforcementCommentMeta =
      const VerificationMeta('enforcementComment');
  @override
  late final GeneratedColumn<String> enforcementComment =
      GeneratedColumn<String>('enforcement_comment', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amendmentLawIdMeta =
      const VerificationMeta('amendmentLawId');
  @override
  late final GeneratedColumn<String> amendmentLawId = GeneratedColumn<String>(
      'amendment_law_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amendmentLawNumMeta =
      const VerificationMeta('amendmentLawNum');
  @override
  late final GeneratedColumn<String> amendmentLawNum = GeneratedColumn<String>(
      'amendment_law_num', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amendmentLawTitleMeta =
      const VerificationMeta('amendmentLawTitle');
  @override
  late final GeneratedColumn<String> amendmentLawTitle =
      GeneratedColumn<String>('amendment_law_title', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amendmentTypeMeta =
      const VerificationMeta('amendmentType');
  @override
  late final GeneratedColumn<String> amendmentType = GeneratedColumn<String>(
      'amendment_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apiUpdatedMeta =
      const VerificationMeta('apiUpdated');
  @override
  late final GeneratedColumn<String> apiUpdated = GeneratedColumn<String>(
      'api_updated', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<String> fetchedAt = GeneratedColumn<String>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        revisionId,
        lawId,
        enforcedAt,
        promulgatedAt,
        scheduledEnforcedAt,
        enforcementComment,
        amendmentLawId,
        amendmentLawNum,
        amendmentLawTitle,
        amendmentType,
        status,
        apiUpdated,
        fetchedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'law_revisions';
  @override
  VerificationContext validateIntegrity(Insertable<LawRevision> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('revision_id')) {
      context.handle(
          _revisionIdMeta,
          revisionId.isAcceptableOrUnknown(
              data['revision_id']!, _revisionIdMeta));
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('law_id')) {
      context.handle(
          _lawIdMeta, lawId.isAcceptableOrUnknown(data['law_id']!, _lawIdMeta));
    } else if (isInserting) {
      context.missing(_lawIdMeta);
    }
    if (data.containsKey('enforced_at')) {
      context.handle(
          _enforcedAtMeta,
          enforcedAt.isAcceptableOrUnknown(
              data['enforced_at']!, _enforcedAtMeta));
    } else if (isInserting) {
      context.missing(_enforcedAtMeta);
    }
    if (data.containsKey('promulgated_at')) {
      context.handle(
          _promulgatedAtMeta,
          promulgatedAt.isAcceptableOrUnknown(
              data['promulgated_at']!, _promulgatedAtMeta));
    }
    if (data.containsKey('scheduled_enforced_at')) {
      context.handle(
          _scheduledEnforcedAtMeta,
          scheduledEnforcedAt.isAcceptableOrUnknown(
              data['scheduled_enforced_at']!, _scheduledEnforcedAtMeta));
    }
    if (data.containsKey('enforcement_comment')) {
      context.handle(
          _enforcementCommentMeta,
          enforcementComment.isAcceptableOrUnknown(
              data['enforcement_comment']!, _enforcementCommentMeta));
    }
    if (data.containsKey('amendment_law_id')) {
      context.handle(
          _amendmentLawIdMeta,
          amendmentLawId.isAcceptableOrUnknown(
              data['amendment_law_id']!, _amendmentLawIdMeta));
    }
    if (data.containsKey('amendment_law_num')) {
      context.handle(
          _amendmentLawNumMeta,
          amendmentLawNum.isAcceptableOrUnknown(
              data['amendment_law_num']!, _amendmentLawNumMeta));
    }
    if (data.containsKey('amendment_law_title')) {
      context.handle(
          _amendmentLawTitleMeta,
          amendmentLawTitle.isAcceptableOrUnknown(
              data['amendment_law_title']!, _amendmentLawTitleMeta));
    }
    if (data.containsKey('amendment_type')) {
      context.handle(
          _amendmentTypeMeta,
          amendmentType.isAcceptableOrUnknown(
              data['amendment_type']!, _amendmentTypeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('api_updated')) {
      context.handle(
          _apiUpdatedMeta,
          apiUpdated.isAcceptableOrUnknown(
              data['api_updated']!, _apiUpdatedMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {revisionId};
  @override
  LawRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LawRevision(
      revisionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}revision_id'])!,
      lawId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}law_id'])!,
      enforcedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enforced_at'])!,
      promulgatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}promulgated_at']),
      scheduledEnforcedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}scheduled_enforced_at']),
      enforcementComment: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}enforcement_comment']),
      amendmentLawId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}amendment_law_id']),
      amendmentLawNum: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}amendment_law_num']),
      amendmentLawTitle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}amendment_law_title']),
      amendmentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}amendment_type']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      apiUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_updated']),
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $LawRevisionsTable createAlias(String alias) {
    return $LawRevisionsTable(attachedDatabase, alias);
  }
}

class LawRevision extends DataClass implements Insertable<LawRevision> {
  final String revisionId;
  final String lawId;
  final String enforcedAt;
  final String? promulgatedAt;
  final String? scheduledEnforcedAt;
  final String? enforcementComment;
  final String? amendmentLawId;
  final String? amendmentLawNum;
  final String? amendmentLawTitle;
  final String? amendmentType;
  final String status;
  final String? apiUpdated;
  final String fetchedAt;
  const LawRevision(
      {required this.revisionId,
      required this.lawId,
      required this.enforcedAt,
      this.promulgatedAt,
      this.scheduledEnforcedAt,
      this.enforcementComment,
      this.amendmentLawId,
      this.amendmentLawNum,
      this.amendmentLawTitle,
      this.amendmentType,
      required this.status,
      this.apiUpdated,
      required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['revision_id'] = Variable<String>(revisionId);
    map['law_id'] = Variable<String>(lawId);
    map['enforced_at'] = Variable<String>(enforcedAt);
    if (!nullToAbsent || promulgatedAt != null) {
      map['promulgated_at'] = Variable<String>(promulgatedAt);
    }
    if (!nullToAbsent || scheduledEnforcedAt != null) {
      map['scheduled_enforced_at'] = Variable<String>(scheduledEnforcedAt);
    }
    if (!nullToAbsent || enforcementComment != null) {
      map['enforcement_comment'] = Variable<String>(enforcementComment);
    }
    if (!nullToAbsent || amendmentLawId != null) {
      map['amendment_law_id'] = Variable<String>(amendmentLawId);
    }
    if (!nullToAbsent || amendmentLawNum != null) {
      map['amendment_law_num'] = Variable<String>(amendmentLawNum);
    }
    if (!nullToAbsent || amendmentLawTitle != null) {
      map['amendment_law_title'] = Variable<String>(amendmentLawTitle);
    }
    if (!nullToAbsent || amendmentType != null) {
      map['amendment_type'] = Variable<String>(amendmentType);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || apiUpdated != null) {
      map['api_updated'] = Variable<String>(apiUpdated);
    }
    map['fetched_at'] = Variable<String>(fetchedAt);
    return map;
  }

  LawRevisionsCompanion toCompanion(bool nullToAbsent) {
    return LawRevisionsCompanion(
      revisionId: Value(revisionId),
      lawId: Value(lawId),
      enforcedAt: Value(enforcedAt),
      promulgatedAt: promulgatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(promulgatedAt),
      scheduledEnforcedAt: scheduledEnforcedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledEnforcedAt),
      enforcementComment: enforcementComment == null && nullToAbsent
          ? const Value.absent()
          : Value(enforcementComment),
      amendmentLawId: amendmentLawId == null && nullToAbsent
          ? const Value.absent()
          : Value(amendmentLawId),
      amendmentLawNum: amendmentLawNum == null && nullToAbsent
          ? const Value.absent()
          : Value(amendmentLawNum),
      amendmentLawTitle: amendmentLawTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(amendmentLawTitle),
      amendmentType: amendmentType == null && nullToAbsent
          ? const Value.absent()
          : Value(amendmentType),
      status: Value(status),
      apiUpdated: apiUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(apiUpdated),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory LawRevision.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LawRevision(
      revisionId: serializer.fromJson<String>(json['revisionId']),
      lawId: serializer.fromJson<String>(json['lawId']),
      enforcedAt: serializer.fromJson<String>(json['enforcedAt']),
      promulgatedAt: serializer.fromJson<String?>(json['promulgatedAt']),
      scheduledEnforcedAt:
          serializer.fromJson<String?>(json['scheduledEnforcedAt']),
      enforcementComment:
          serializer.fromJson<String?>(json['enforcementComment']),
      amendmentLawId: serializer.fromJson<String?>(json['amendmentLawId']),
      amendmentLawNum: serializer.fromJson<String?>(json['amendmentLawNum']),
      amendmentLawTitle:
          serializer.fromJson<String?>(json['amendmentLawTitle']),
      amendmentType: serializer.fromJson<String?>(json['amendmentType']),
      status: serializer.fromJson<String>(json['status']),
      apiUpdated: serializer.fromJson<String?>(json['apiUpdated']),
      fetchedAt: serializer.fromJson<String>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'revisionId': serializer.toJson<String>(revisionId),
      'lawId': serializer.toJson<String>(lawId),
      'enforcedAt': serializer.toJson<String>(enforcedAt),
      'promulgatedAt': serializer.toJson<String?>(promulgatedAt),
      'scheduledEnforcedAt': serializer.toJson<String?>(scheduledEnforcedAt),
      'enforcementComment': serializer.toJson<String?>(enforcementComment),
      'amendmentLawId': serializer.toJson<String?>(amendmentLawId),
      'amendmentLawNum': serializer.toJson<String?>(amendmentLawNum),
      'amendmentLawTitle': serializer.toJson<String?>(amendmentLawTitle),
      'amendmentType': serializer.toJson<String?>(amendmentType),
      'status': serializer.toJson<String>(status),
      'apiUpdated': serializer.toJson<String?>(apiUpdated),
      'fetchedAt': serializer.toJson<String>(fetchedAt),
    };
  }

  LawRevision copyWith(
          {String? revisionId,
          String? lawId,
          String? enforcedAt,
          Value<String?> promulgatedAt = const Value.absent(),
          Value<String?> scheduledEnforcedAt = const Value.absent(),
          Value<String?> enforcementComment = const Value.absent(),
          Value<String?> amendmentLawId = const Value.absent(),
          Value<String?> amendmentLawNum = const Value.absent(),
          Value<String?> amendmentLawTitle = const Value.absent(),
          Value<String?> amendmentType = const Value.absent(),
          String? status,
          Value<String?> apiUpdated = const Value.absent(),
          String? fetchedAt}) =>
      LawRevision(
        revisionId: revisionId ?? this.revisionId,
        lawId: lawId ?? this.lawId,
        enforcedAt: enforcedAt ?? this.enforcedAt,
        promulgatedAt:
            promulgatedAt.present ? promulgatedAt.value : this.promulgatedAt,
        scheduledEnforcedAt: scheduledEnforcedAt.present
            ? scheduledEnforcedAt.value
            : this.scheduledEnforcedAt,
        enforcementComment: enforcementComment.present
            ? enforcementComment.value
            : this.enforcementComment,
        amendmentLawId:
            amendmentLawId.present ? amendmentLawId.value : this.amendmentLawId,
        amendmentLawNum: amendmentLawNum.present
            ? amendmentLawNum.value
            : this.amendmentLawNum,
        amendmentLawTitle: amendmentLawTitle.present
            ? amendmentLawTitle.value
            : this.amendmentLawTitle,
        amendmentType:
            amendmentType.present ? amendmentType.value : this.amendmentType,
        status: status ?? this.status,
        apiUpdated: apiUpdated.present ? apiUpdated.value : this.apiUpdated,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  LawRevision copyWithCompanion(LawRevisionsCompanion data) {
    return LawRevision(
      revisionId:
          data.revisionId.present ? data.revisionId.value : this.revisionId,
      lawId: data.lawId.present ? data.lawId.value : this.lawId,
      enforcedAt:
          data.enforcedAt.present ? data.enforcedAt.value : this.enforcedAt,
      promulgatedAt: data.promulgatedAt.present
          ? data.promulgatedAt.value
          : this.promulgatedAt,
      scheduledEnforcedAt: data.scheduledEnforcedAt.present
          ? data.scheduledEnforcedAt.value
          : this.scheduledEnforcedAt,
      enforcementComment: data.enforcementComment.present
          ? data.enforcementComment.value
          : this.enforcementComment,
      amendmentLawId: data.amendmentLawId.present
          ? data.amendmentLawId.value
          : this.amendmentLawId,
      amendmentLawNum: data.amendmentLawNum.present
          ? data.amendmentLawNum.value
          : this.amendmentLawNum,
      amendmentLawTitle: data.amendmentLawTitle.present
          ? data.amendmentLawTitle.value
          : this.amendmentLawTitle,
      amendmentType: data.amendmentType.present
          ? data.amendmentType.value
          : this.amendmentType,
      status: data.status.present ? data.status.value : this.status,
      apiUpdated:
          data.apiUpdated.present ? data.apiUpdated.value : this.apiUpdated,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LawRevision(')
          ..write('revisionId: $revisionId, ')
          ..write('lawId: $lawId, ')
          ..write('enforcedAt: $enforcedAt, ')
          ..write('promulgatedAt: $promulgatedAt, ')
          ..write('scheduledEnforcedAt: $scheduledEnforcedAt, ')
          ..write('enforcementComment: $enforcementComment, ')
          ..write('amendmentLawId: $amendmentLawId, ')
          ..write('amendmentLawNum: $amendmentLawNum, ')
          ..write('amendmentLawTitle: $amendmentLawTitle, ')
          ..write('amendmentType: $amendmentType, ')
          ..write('status: $status, ')
          ..write('apiUpdated: $apiUpdated, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      revisionId,
      lawId,
      enforcedAt,
      promulgatedAt,
      scheduledEnforcedAt,
      enforcementComment,
      amendmentLawId,
      amendmentLawNum,
      amendmentLawTitle,
      amendmentType,
      status,
      apiUpdated,
      fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LawRevision &&
          other.revisionId == this.revisionId &&
          other.lawId == this.lawId &&
          other.enforcedAt == this.enforcedAt &&
          other.promulgatedAt == this.promulgatedAt &&
          other.scheduledEnforcedAt == this.scheduledEnforcedAt &&
          other.enforcementComment == this.enforcementComment &&
          other.amendmentLawId == this.amendmentLawId &&
          other.amendmentLawNum == this.amendmentLawNum &&
          other.amendmentLawTitle == this.amendmentLawTitle &&
          other.amendmentType == this.amendmentType &&
          other.status == this.status &&
          other.apiUpdated == this.apiUpdated &&
          other.fetchedAt == this.fetchedAt);
}

class LawRevisionsCompanion extends UpdateCompanion<LawRevision> {
  final Value<String> revisionId;
  final Value<String> lawId;
  final Value<String> enforcedAt;
  final Value<String?> promulgatedAt;
  final Value<String?> scheduledEnforcedAt;
  final Value<String?> enforcementComment;
  final Value<String?> amendmentLawId;
  final Value<String?> amendmentLawNum;
  final Value<String?> amendmentLawTitle;
  final Value<String?> amendmentType;
  final Value<String> status;
  final Value<String?> apiUpdated;
  final Value<String> fetchedAt;
  final Value<int> rowid;
  const LawRevisionsCompanion({
    this.revisionId = const Value.absent(),
    this.lawId = const Value.absent(),
    this.enforcedAt = const Value.absent(),
    this.promulgatedAt = const Value.absent(),
    this.scheduledEnforcedAt = const Value.absent(),
    this.enforcementComment = const Value.absent(),
    this.amendmentLawId = const Value.absent(),
    this.amendmentLawNum = const Value.absent(),
    this.amendmentLawTitle = const Value.absent(),
    this.amendmentType = const Value.absent(),
    this.status = const Value.absent(),
    this.apiUpdated = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LawRevisionsCompanion.insert({
    required String revisionId,
    required String lawId,
    required String enforcedAt,
    this.promulgatedAt = const Value.absent(),
    this.scheduledEnforcedAt = const Value.absent(),
    this.enforcementComment = const Value.absent(),
    this.amendmentLawId = const Value.absent(),
    this.amendmentLawNum = const Value.absent(),
    this.amendmentLawTitle = const Value.absent(),
    this.amendmentType = const Value.absent(),
    required String status,
    this.apiUpdated = const Value.absent(),
    required String fetchedAt,
    this.rowid = const Value.absent(),
  })  : revisionId = Value(revisionId),
        lawId = Value(lawId),
        enforcedAt = Value(enforcedAt),
        status = Value(status),
        fetchedAt = Value(fetchedAt);
  static Insertable<LawRevision> custom({
    Expression<String>? revisionId,
    Expression<String>? lawId,
    Expression<String>? enforcedAt,
    Expression<String>? promulgatedAt,
    Expression<String>? scheduledEnforcedAt,
    Expression<String>? enforcementComment,
    Expression<String>? amendmentLawId,
    Expression<String>? amendmentLawNum,
    Expression<String>? amendmentLawTitle,
    Expression<String>? amendmentType,
    Expression<String>? status,
    Expression<String>? apiUpdated,
    Expression<String>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (revisionId != null) 'revision_id': revisionId,
      if (lawId != null) 'law_id': lawId,
      if (enforcedAt != null) 'enforced_at': enforcedAt,
      if (promulgatedAt != null) 'promulgated_at': promulgatedAt,
      if (scheduledEnforcedAt != null)
        'scheduled_enforced_at': scheduledEnforcedAt,
      if (enforcementComment != null) 'enforcement_comment': enforcementComment,
      if (amendmentLawId != null) 'amendment_law_id': amendmentLawId,
      if (amendmentLawNum != null) 'amendment_law_num': amendmentLawNum,
      if (amendmentLawTitle != null) 'amendment_law_title': amendmentLawTitle,
      if (amendmentType != null) 'amendment_type': amendmentType,
      if (status != null) 'status': status,
      if (apiUpdated != null) 'api_updated': apiUpdated,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LawRevisionsCompanion copyWith(
      {Value<String>? revisionId,
      Value<String>? lawId,
      Value<String>? enforcedAt,
      Value<String?>? promulgatedAt,
      Value<String?>? scheduledEnforcedAt,
      Value<String?>? enforcementComment,
      Value<String?>? amendmentLawId,
      Value<String?>? amendmentLawNum,
      Value<String?>? amendmentLawTitle,
      Value<String?>? amendmentType,
      Value<String>? status,
      Value<String?>? apiUpdated,
      Value<String>? fetchedAt,
      Value<int>? rowid}) {
    return LawRevisionsCompanion(
      revisionId: revisionId ?? this.revisionId,
      lawId: lawId ?? this.lawId,
      enforcedAt: enforcedAt ?? this.enforcedAt,
      promulgatedAt: promulgatedAt ?? this.promulgatedAt,
      scheduledEnforcedAt: scheduledEnforcedAt ?? this.scheduledEnforcedAt,
      enforcementComment: enforcementComment ?? this.enforcementComment,
      amendmentLawId: amendmentLawId ?? this.amendmentLawId,
      amendmentLawNum: amendmentLawNum ?? this.amendmentLawNum,
      amendmentLawTitle: amendmentLawTitle ?? this.amendmentLawTitle,
      amendmentType: amendmentType ?? this.amendmentType,
      status: status ?? this.status,
      apiUpdated: apiUpdated ?? this.apiUpdated,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (lawId.present) {
      map['law_id'] = Variable<String>(lawId.value);
    }
    if (enforcedAt.present) {
      map['enforced_at'] = Variable<String>(enforcedAt.value);
    }
    if (promulgatedAt.present) {
      map['promulgated_at'] = Variable<String>(promulgatedAt.value);
    }
    if (scheduledEnforcedAt.present) {
      map['scheduled_enforced_at'] =
          Variable<String>(scheduledEnforcedAt.value);
    }
    if (enforcementComment.present) {
      map['enforcement_comment'] = Variable<String>(enforcementComment.value);
    }
    if (amendmentLawId.present) {
      map['amendment_law_id'] = Variable<String>(amendmentLawId.value);
    }
    if (amendmentLawNum.present) {
      map['amendment_law_num'] = Variable<String>(amendmentLawNum.value);
    }
    if (amendmentLawTitle.present) {
      map['amendment_law_title'] = Variable<String>(amendmentLawTitle.value);
    }
    if (amendmentType.present) {
      map['amendment_type'] = Variable<String>(amendmentType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (apiUpdated.present) {
      map['api_updated'] = Variable<String>(apiUpdated.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<String>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LawRevisionsCompanion(')
          ..write('revisionId: $revisionId, ')
          ..write('lawId: $lawId, ')
          ..write('enforcedAt: $enforcedAt, ')
          ..write('promulgatedAt: $promulgatedAt, ')
          ..write('scheduledEnforcedAt: $scheduledEnforcedAt, ')
          ..write('enforcementComment: $enforcementComment, ')
          ..write('amendmentLawId: $amendmentLawId, ')
          ..write('amendmentLawNum: $amendmentLawNum, ')
          ..write('amendmentLawTitle: $amendmentLawTitle, ')
          ..write('amendmentType: $amendmentType, ')
          ..write('status: $status, ')
          ..write('apiUpdated: $apiUpdated, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArticlesTable extends Articles with TableInfo<$ArticlesTable, Article> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lawIdMeta = const VerificationMeta('lawId');
  @override
  late final GeneratedColumn<String> lawId = GeneratedColumn<String>(
      'law_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES laws (law_id)'));
  static const VerificationMeta _revisionIdMeta =
      const VerificationMeta('revisionId');
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
      'revision_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sectionMeta =
      const VerificationMeta('section');
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
      'section', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _supplAmendLawNumMeta =
      const VerificationMeta('supplAmendLawNum');
  @override
  late final GeneratedColumn<String> supplAmendLawNum = GeneratedColumn<String>(
      'suppl_amend_law_num', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _articleNumMeta =
      const VerificationMeta('articleNum');
  @override
  late final GeneratedColumn<String> articleNum = GeneratedColumn<String>(
      'article_num', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _articleTitleMeta =
      const VerificationMeta('articleTitle');
  @override
  late final GeneratedColumn<String> articleTitle = GeneratedColumn<String>(
      'article_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _breadcrumbMeta =
      const VerificationMeta('breadcrumb');
  @override
  late final GeneratedColumn<String> breadcrumb = GeneratedColumn<String>(
      'breadcrumb', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _plainTextMeta =
      const VerificationMeta('plainText');
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
      'plain_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyJsonMeta =
      const VerificationMeta('bodyJson');
  @override
  late final GeneratedColumn<String> bodyJson = GeneratedColumn<String>(
      'body_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lawId,
        revisionId,
        seq,
        section,
        supplAmendLawNum,
        path,
        articleNum,
        articleTitle,
        caption,
        breadcrumb,
        plainText,
        bodyJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'articles';
  @override
  VerificationContext validateIntegrity(Insertable<Article> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('law_id')) {
      context.handle(
          _lawIdMeta, lawId.isAcceptableOrUnknown(data['law_id']!, _lawIdMeta));
    } else if (isInserting) {
      context.missing(_lawIdMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
          _revisionIdMeta,
          revisionId.isAcceptableOrUnknown(
              data['revision_id']!, _revisionIdMeta));
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('section')) {
      context.handle(_sectionMeta,
          section.isAcceptableOrUnknown(data['section']!, _sectionMeta));
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('suppl_amend_law_num')) {
      context.handle(
          _supplAmendLawNumMeta,
          supplAmendLawNum.isAcceptableOrUnknown(
              data['suppl_amend_law_num']!, _supplAmendLawNumMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('article_num')) {
      context.handle(
          _articleNumMeta,
          articleNum.isAcceptableOrUnknown(
              data['article_num']!, _articleNumMeta));
    }
    if (data.containsKey('article_title')) {
      context.handle(
          _articleTitleMeta,
          articleTitle.isAcceptableOrUnknown(
              data['article_title']!, _articleTitleMeta));
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    if (data.containsKey('breadcrumb')) {
      context.handle(
          _breadcrumbMeta,
          breadcrumb.isAcceptableOrUnknown(
              data['breadcrumb']!, _breadcrumbMeta));
    }
    if (data.containsKey('plain_text')) {
      context.handle(_plainTextMeta,
          plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta));
    } else if (isInserting) {
      context.missing(_plainTextMeta);
    }
    if (data.containsKey('body_json')) {
      context.handle(_bodyJsonMeta,
          bodyJson.isAcceptableOrUnknown(data['body_json']!, _bodyJsonMeta));
    } else if (isInserting) {
      context.missing(_bodyJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Article map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Article(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lawId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}law_id'])!,
      revisionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}revision_id'])!,
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      section: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section'])!,
      supplAmendLawNum: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}suppl_amend_law_num']),
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      articleNum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}article_num']),
      articleTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}article_title']),
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
      breadcrumb: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}breadcrumb']),
      plainText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plain_text'])!,
      bodyJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_json'])!,
    );
  }

  @override
  $ArticlesTable createAlias(String alias) {
    return $ArticlesTable(attachedDatabase, alias);
  }
}

class Article extends DataClass implements Insertable<Article> {
  final int id;
  final String lawId;
  final String revisionId;
  final int seq;
  final String section;
  final String? supplAmendLawNum;
  final String path;
  final String? articleNum;
  final String? articleTitle;
  final String? caption;
  final String? breadcrumb;

  /// 検索用の平文（幅を正規化済み）。
  final String plainText;

  /// 表示用: 条のサブツリー JSON（`{tag, attr, children}`）。
  /// gzip した BLOB にしないのは、`dart:io` の gzip が Web に無く、
  /// 圧縮のためだけに依存を増やしたくないから。容量が問題になったら差し替える。
  final String bodyJson;
  const Article(
      {required this.id,
      required this.lawId,
      required this.revisionId,
      required this.seq,
      required this.section,
      this.supplAmendLawNum,
      required this.path,
      this.articleNum,
      this.articleTitle,
      this.caption,
      this.breadcrumb,
      required this.plainText,
      required this.bodyJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['law_id'] = Variable<String>(lawId);
    map['revision_id'] = Variable<String>(revisionId);
    map['seq'] = Variable<int>(seq);
    map['section'] = Variable<String>(section);
    if (!nullToAbsent || supplAmendLawNum != null) {
      map['suppl_amend_law_num'] = Variable<String>(supplAmendLawNum);
    }
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || articleNum != null) {
      map['article_num'] = Variable<String>(articleNum);
    }
    if (!nullToAbsent || articleTitle != null) {
      map['article_title'] = Variable<String>(articleTitle);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    if (!nullToAbsent || breadcrumb != null) {
      map['breadcrumb'] = Variable<String>(breadcrumb);
    }
    map['plain_text'] = Variable<String>(plainText);
    map['body_json'] = Variable<String>(bodyJson);
    return map;
  }

  ArticlesCompanion toCompanion(bool nullToAbsent) {
    return ArticlesCompanion(
      id: Value(id),
      lawId: Value(lawId),
      revisionId: Value(revisionId),
      seq: Value(seq),
      section: Value(section),
      supplAmendLawNum: supplAmendLawNum == null && nullToAbsent
          ? const Value.absent()
          : Value(supplAmendLawNum),
      path: Value(path),
      articleNum: articleNum == null && nullToAbsent
          ? const Value.absent()
          : Value(articleNum),
      articleTitle: articleTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(articleTitle),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      breadcrumb: breadcrumb == null && nullToAbsent
          ? const Value.absent()
          : Value(breadcrumb),
      plainText: Value(plainText),
      bodyJson: Value(bodyJson),
    );
  }

  factory Article.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Article(
      id: serializer.fromJson<int>(json['id']),
      lawId: serializer.fromJson<String>(json['lawId']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      seq: serializer.fromJson<int>(json['seq']),
      section: serializer.fromJson<String>(json['section']),
      supplAmendLawNum: serializer.fromJson<String?>(json['supplAmendLawNum']),
      path: serializer.fromJson<String>(json['path']),
      articleNum: serializer.fromJson<String?>(json['articleNum']),
      articleTitle: serializer.fromJson<String?>(json['articleTitle']),
      caption: serializer.fromJson<String?>(json['caption']),
      breadcrumb: serializer.fromJson<String?>(json['breadcrumb']),
      plainText: serializer.fromJson<String>(json['plainText']),
      bodyJson: serializer.fromJson<String>(json['bodyJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lawId': serializer.toJson<String>(lawId),
      'revisionId': serializer.toJson<String>(revisionId),
      'seq': serializer.toJson<int>(seq),
      'section': serializer.toJson<String>(section),
      'supplAmendLawNum': serializer.toJson<String?>(supplAmendLawNum),
      'path': serializer.toJson<String>(path),
      'articleNum': serializer.toJson<String?>(articleNum),
      'articleTitle': serializer.toJson<String?>(articleTitle),
      'caption': serializer.toJson<String?>(caption),
      'breadcrumb': serializer.toJson<String?>(breadcrumb),
      'plainText': serializer.toJson<String>(plainText),
      'bodyJson': serializer.toJson<String>(bodyJson),
    };
  }

  Article copyWith(
          {int? id,
          String? lawId,
          String? revisionId,
          int? seq,
          String? section,
          Value<String?> supplAmendLawNum = const Value.absent(),
          String? path,
          Value<String?> articleNum = const Value.absent(),
          Value<String?> articleTitle = const Value.absent(),
          Value<String?> caption = const Value.absent(),
          Value<String?> breadcrumb = const Value.absent(),
          String? plainText,
          String? bodyJson}) =>
      Article(
        id: id ?? this.id,
        lawId: lawId ?? this.lawId,
        revisionId: revisionId ?? this.revisionId,
        seq: seq ?? this.seq,
        section: section ?? this.section,
        supplAmendLawNum: supplAmendLawNum.present
            ? supplAmendLawNum.value
            : this.supplAmendLawNum,
        path: path ?? this.path,
        articleNum: articleNum.present ? articleNum.value : this.articleNum,
        articleTitle:
            articleTitle.present ? articleTitle.value : this.articleTitle,
        caption: caption.present ? caption.value : this.caption,
        breadcrumb: breadcrumb.present ? breadcrumb.value : this.breadcrumb,
        plainText: plainText ?? this.plainText,
        bodyJson: bodyJson ?? this.bodyJson,
      );
  Article copyWithCompanion(ArticlesCompanion data) {
    return Article(
      id: data.id.present ? data.id.value : this.id,
      lawId: data.lawId.present ? data.lawId.value : this.lawId,
      revisionId:
          data.revisionId.present ? data.revisionId.value : this.revisionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      section: data.section.present ? data.section.value : this.section,
      supplAmendLawNum: data.supplAmendLawNum.present
          ? data.supplAmendLawNum.value
          : this.supplAmendLawNum,
      path: data.path.present ? data.path.value : this.path,
      articleNum:
          data.articleNum.present ? data.articleNum.value : this.articleNum,
      articleTitle: data.articleTitle.present
          ? data.articleTitle.value
          : this.articleTitle,
      caption: data.caption.present ? data.caption.value : this.caption,
      breadcrumb:
          data.breadcrumb.present ? data.breadcrumb.value : this.breadcrumb,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      bodyJson: data.bodyJson.present ? data.bodyJson.value : this.bodyJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Article(')
          ..write('id: $id, ')
          ..write('lawId: $lawId, ')
          ..write('revisionId: $revisionId, ')
          ..write('seq: $seq, ')
          ..write('section: $section, ')
          ..write('supplAmendLawNum: $supplAmendLawNum, ')
          ..write('path: $path, ')
          ..write('articleNum: $articleNum, ')
          ..write('articleTitle: $articleTitle, ')
          ..write('caption: $caption, ')
          ..write('breadcrumb: $breadcrumb, ')
          ..write('plainText: $plainText, ')
          ..write('bodyJson: $bodyJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      lawId,
      revisionId,
      seq,
      section,
      supplAmendLawNum,
      path,
      articleNum,
      articleTitle,
      caption,
      breadcrumb,
      plainText,
      bodyJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Article &&
          other.id == this.id &&
          other.lawId == this.lawId &&
          other.revisionId == this.revisionId &&
          other.seq == this.seq &&
          other.section == this.section &&
          other.supplAmendLawNum == this.supplAmendLawNum &&
          other.path == this.path &&
          other.articleNum == this.articleNum &&
          other.articleTitle == this.articleTitle &&
          other.caption == this.caption &&
          other.breadcrumb == this.breadcrumb &&
          other.plainText == this.plainText &&
          other.bodyJson == this.bodyJson);
}

class ArticlesCompanion extends UpdateCompanion<Article> {
  final Value<int> id;
  final Value<String> lawId;
  final Value<String> revisionId;
  final Value<int> seq;
  final Value<String> section;
  final Value<String?> supplAmendLawNum;
  final Value<String> path;
  final Value<String?> articleNum;
  final Value<String?> articleTitle;
  final Value<String?> caption;
  final Value<String?> breadcrumb;
  final Value<String> plainText;
  final Value<String> bodyJson;
  const ArticlesCompanion({
    this.id = const Value.absent(),
    this.lawId = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.section = const Value.absent(),
    this.supplAmendLawNum = const Value.absent(),
    this.path = const Value.absent(),
    this.articleNum = const Value.absent(),
    this.articleTitle = const Value.absent(),
    this.caption = const Value.absent(),
    this.breadcrumb = const Value.absent(),
    this.plainText = const Value.absent(),
    this.bodyJson = const Value.absent(),
  });
  ArticlesCompanion.insert({
    this.id = const Value.absent(),
    required String lawId,
    required String revisionId,
    required int seq,
    required String section,
    this.supplAmendLawNum = const Value.absent(),
    required String path,
    this.articleNum = const Value.absent(),
    this.articleTitle = const Value.absent(),
    this.caption = const Value.absent(),
    this.breadcrumb = const Value.absent(),
    required String plainText,
    required String bodyJson,
  })  : lawId = Value(lawId),
        revisionId = Value(revisionId),
        seq = Value(seq),
        section = Value(section),
        path = Value(path),
        plainText = Value(plainText),
        bodyJson = Value(bodyJson);
  static Insertable<Article> custom({
    Expression<int>? id,
    Expression<String>? lawId,
    Expression<String>? revisionId,
    Expression<int>? seq,
    Expression<String>? section,
    Expression<String>? supplAmendLawNum,
    Expression<String>? path,
    Expression<String>? articleNum,
    Expression<String>? articleTitle,
    Expression<String>? caption,
    Expression<String>? breadcrumb,
    Expression<String>? plainText,
    Expression<String>? bodyJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lawId != null) 'law_id': lawId,
      if (revisionId != null) 'revision_id': revisionId,
      if (seq != null) 'seq': seq,
      if (section != null) 'section': section,
      if (supplAmendLawNum != null) 'suppl_amend_law_num': supplAmendLawNum,
      if (path != null) 'path': path,
      if (articleNum != null) 'article_num': articleNum,
      if (articleTitle != null) 'article_title': articleTitle,
      if (caption != null) 'caption': caption,
      if (breadcrumb != null) 'breadcrumb': breadcrumb,
      if (plainText != null) 'plain_text': plainText,
      if (bodyJson != null) 'body_json': bodyJson,
    });
  }

  ArticlesCompanion copyWith(
      {Value<int>? id,
      Value<String>? lawId,
      Value<String>? revisionId,
      Value<int>? seq,
      Value<String>? section,
      Value<String?>? supplAmendLawNum,
      Value<String>? path,
      Value<String?>? articleNum,
      Value<String?>? articleTitle,
      Value<String?>? caption,
      Value<String?>? breadcrumb,
      Value<String>? plainText,
      Value<String>? bodyJson}) {
    return ArticlesCompanion(
      id: id ?? this.id,
      lawId: lawId ?? this.lawId,
      revisionId: revisionId ?? this.revisionId,
      seq: seq ?? this.seq,
      section: section ?? this.section,
      supplAmendLawNum: supplAmendLawNum ?? this.supplAmendLawNum,
      path: path ?? this.path,
      articleNum: articleNum ?? this.articleNum,
      articleTitle: articleTitle ?? this.articleTitle,
      caption: caption ?? this.caption,
      breadcrumb: breadcrumb ?? this.breadcrumb,
      plainText: plainText ?? this.plainText,
      bodyJson: bodyJson ?? this.bodyJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lawId.present) {
      map['law_id'] = Variable<String>(lawId.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (supplAmendLawNum.present) {
      map['suppl_amend_law_num'] = Variable<String>(supplAmendLawNum.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (articleNum.present) {
      map['article_num'] = Variable<String>(articleNum.value);
    }
    if (articleTitle.present) {
      map['article_title'] = Variable<String>(articleTitle.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (breadcrumb.present) {
      map['breadcrumb'] = Variable<String>(breadcrumb.value);
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (bodyJson.present) {
      map['body_json'] = Variable<String>(bodyJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticlesCompanion(')
          ..write('id: $id, ')
          ..write('lawId: $lawId, ')
          ..write('revisionId: $revisionId, ')
          ..write('seq: $seq, ')
          ..write('section: $section, ')
          ..write('supplAmendLawNum: $supplAmendLawNum, ')
          ..write('path: $path, ')
          ..write('articleNum: $articleNum, ')
          ..write('articleTitle: $articleTitle, ')
          ..write('caption: $caption, ')
          ..write('breadcrumb: $breadcrumb, ')
          ..write('plainText: $plainText, ')
          ..write('bodyJson: $bodyJson')
          ..write(')'))
        .toString();
  }
}

class $SyncRunsTable extends SyncRuns with TableInfo<$SyncRunsTable, SyncRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
      'started_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _finishedAtMeta =
      const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<String> finishedAt = GeneratedColumn<String>(
      'finished_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lawsCheckedMeta =
      const VerificationMeta('lawsChecked');
  @override
  late final GeneratedColumn<int> lawsChecked = GeneratedColumn<int>(
      'laws_checked', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lawsUpdatedMeta =
      const VerificationMeta('lawsUpdated');
  @override
  late final GeneratedColumn<int> lawsUpdated = GeneratedColumn<int>(
      'laws_updated', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _bytesDownloadedMeta =
      const VerificationMeta('bytesDownloaded');
  @override
  late final GeneratedColumn<int> bytesDownloaded = GeneratedColumn<int>(
      'bytes_downloaded', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startedAt,
        finishedAt,
        status,
        lawsChecked,
        lawsUpdated,
        bytesDownloaded,
        error
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_runs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncRun> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
          _finishedAtMeta,
          finishedAt.isAcceptableOrUnknown(
              data['finished_at']!, _finishedAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('laws_checked')) {
      context.handle(
          _lawsCheckedMeta,
          lawsChecked.isAcceptableOrUnknown(
              data['laws_checked']!, _lawsCheckedMeta));
    }
    if (data.containsKey('laws_updated')) {
      context.handle(
          _lawsUpdatedMeta,
          lawsUpdated.isAcceptableOrUnknown(
              data['laws_updated']!, _lawsUpdatedMeta));
    }
    if (data.containsKey('bytes_downloaded')) {
      context.handle(
          _bytesDownloadedMeta,
          bytesDownloaded.isAcceptableOrUnknown(
              data['bytes_downloaded']!, _bytesDownloadedMeta));
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRun(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}started_at'])!,
      finishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}finished_at']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      lawsChecked: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}laws_checked'])!,
      lawsUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}laws_updated'])!,
      bytesDownloaded: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_downloaded'])!,
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
    );
  }

  @override
  $SyncRunsTable createAlias(String alias) {
    return $SyncRunsTable(attachedDatabase, alias);
  }
}

class SyncRun extends DataClass implements Insertable<SyncRun> {
  final int id;
  final String startedAt;
  final String? finishedAt;
  final String status;
  final int lawsChecked;
  final int lawsUpdated;
  final int bytesDownloaded;
  final String? error;
  const SyncRun(
      {required this.id,
      required this.startedAt,
      this.finishedAt,
      required this.status,
      required this.lawsChecked,
      required this.lawsUpdated,
      required this.bytesDownloaded,
      this.error});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<String>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<String>(finishedAt);
    }
    map['status'] = Variable<String>(status);
    map['laws_checked'] = Variable<int>(lawsChecked);
    map['laws_updated'] = Variable<int>(lawsUpdated);
    map['bytes_downloaded'] = Variable<int>(bytesDownloaded);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SyncRunsCompanion toCompanion(bool nullToAbsent) {
    return SyncRunsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      status: Value(status),
      lawsChecked: Value(lawsChecked),
      lawsUpdated: Value(lawsUpdated),
      bytesDownloaded: Value(bytesDownloaded),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
    );
  }

  factory SyncRun.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRun(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      finishedAt: serializer.fromJson<String?>(json['finishedAt']),
      status: serializer.fromJson<String>(json['status']),
      lawsChecked: serializer.fromJson<int>(json['lawsChecked']),
      lawsUpdated: serializer.fromJson<int>(json['lawsUpdated']),
      bytesDownloaded: serializer.fromJson<int>(json['bytesDownloaded']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<String>(startedAt),
      'finishedAt': serializer.toJson<String?>(finishedAt),
      'status': serializer.toJson<String>(status),
      'lawsChecked': serializer.toJson<int>(lawsChecked),
      'lawsUpdated': serializer.toJson<int>(lawsUpdated),
      'bytesDownloaded': serializer.toJson<int>(bytesDownloaded),
      'error': serializer.toJson<String?>(error),
    };
  }

  SyncRun copyWith(
          {int? id,
          String? startedAt,
          Value<String?> finishedAt = const Value.absent(),
          String? status,
          int? lawsChecked,
          int? lawsUpdated,
          int? bytesDownloaded,
          Value<String?> error = const Value.absent()}) =>
      SyncRun(
        id: id ?? this.id,
        startedAt: startedAt ?? this.startedAt,
        finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
        status: status ?? this.status,
        lawsChecked: lawsChecked ?? this.lawsChecked,
        lawsUpdated: lawsUpdated ?? this.lawsUpdated,
        bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
        error: error.present ? error.value : this.error,
      );
  SyncRun copyWithCompanion(SyncRunsCompanion data) {
    return SyncRun(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt:
          data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
      status: data.status.present ? data.status.value : this.status,
      lawsChecked:
          data.lawsChecked.present ? data.lawsChecked.value : this.lawsChecked,
      lawsUpdated:
          data.lawsUpdated.present ? data.lawsUpdated.value : this.lawsUpdated,
      bytesDownloaded: data.bytesDownloaded.present
          ? data.bytesDownloaded.value
          : this.bytesDownloaded,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRun(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('status: $status, ')
          ..write('lawsChecked: $lawsChecked, ')
          ..write('lawsUpdated: $lawsUpdated, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAt, finishedAt, status,
      lawsChecked, lawsUpdated, bytesDownloaded, error);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRun &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.status == this.status &&
          other.lawsChecked == this.lawsChecked &&
          other.lawsUpdated == this.lawsUpdated &&
          other.bytesDownloaded == this.bytesDownloaded &&
          other.error == this.error);
}

class SyncRunsCompanion extends UpdateCompanion<SyncRun> {
  final Value<int> id;
  final Value<String> startedAt;
  final Value<String?> finishedAt;
  final Value<String> status;
  final Value<int> lawsChecked;
  final Value<int> lawsUpdated;
  final Value<int> bytesDownloaded;
  final Value<String?> error;
  const SyncRunsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lawsChecked = const Value.absent(),
    this.lawsUpdated = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.error = const Value.absent(),
  });
  SyncRunsCompanion.insert({
    this.id = const Value.absent(),
    required String startedAt,
    this.finishedAt = const Value.absent(),
    required String status,
    this.lawsChecked = const Value.absent(),
    this.lawsUpdated = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.error = const Value.absent(),
  })  : startedAt = Value(startedAt),
        status = Value(status);
  static Insertable<SyncRun> custom({
    Expression<int>? id,
    Expression<String>? startedAt,
    Expression<String>? finishedAt,
    Expression<String>? status,
    Expression<int>? lawsChecked,
    Expression<int>? lawsUpdated,
    Expression<int>? bytesDownloaded,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (status != null) 'status': status,
      if (lawsChecked != null) 'laws_checked': lawsChecked,
      if (lawsUpdated != null) 'laws_updated': lawsUpdated,
      if (bytesDownloaded != null) 'bytes_downloaded': bytesDownloaded,
      if (error != null) 'error': error,
    });
  }

  SyncRunsCompanion copyWith(
      {Value<int>? id,
      Value<String>? startedAt,
      Value<String?>? finishedAt,
      Value<String>? status,
      Value<int>? lawsChecked,
      Value<int>? lawsUpdated,
      Value<int>? bytesDownloaded,
      Value<String?>? error}) {
    return SyncRunsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      lawsChecked: lawsChecked ?? this.lawsChecked,
      lawsUpdated: lawsUpdated ?? this.lawsUpdated,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<String>(finishedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lawsChecked.present) {
      map['laws_checked'] = Variable<int>(lawsChecked.value);
    }
    if (lawsUpdated.present) {
      map['laws_updated'] = Variable<int>(lawsUpdated.value);
    }
    if (bytesDownloaded.present) {
      map['bytes_downloaded'] = Variable<int>(bytesDownloaded.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRunsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('status: $status, ')
          ..write('lawsChecked: $lawsChecked, ')
          ..write('lawsUpdated: $lawsUpdated, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(Insertable<AppMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
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

  AppMetaData copyWith({String? key, String? value}) => AppMetaData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
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
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppMetaData> custom({
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

  AppMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppMetaCompanion(
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
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lawIdMeta = const VerificationMeta('lawId');
  @override
  late final GeneratedColumn<String> lawId = GeneratedColumn<String>(
      'law_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES laws (law_id)'));
  static const VerificationMeta _articleNumMeta =
      const VerificationMeta('articleNum');
  @override
  late final GeneratedColumn<String> articleNum = GeneratedColumn<String>(
      'article_num', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, lawId, articleNum, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('law_id')) {
      context.handle(
          _lawIdMeta, lawId.isAcceptableOrUnknown(data['law_id']!, _lawIdMeta));
    } else if (isInserting) {
      context.missing(_lawIdMeta);
    }
    if (data.containsKey('article_num')) {
      context.handle(
          _articleNumMeta,
          articleNum.isAcceptableOrUnknown(
              data['article_num']!, _articleNumMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lawId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}law_id'])!,
      articleNum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}article_num']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final String lawId;
  final String? articleNum;
  final String createdAt;
  const Bookmark(
      {required this.id,
      required this.lawId,
      this.articleNum,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['law_id'] = Variable<String>(lawId);
    if (!nullToAbsent || articleNum != null) {
      map['article_num'] = Variable<String>(articleNum);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      lawId: Value(lawId),
      articleNum: articleNum == null && nullToAbsent
          ? const Value.absent()
          : Value(articleNum),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      lawId: serializer.fromJson<String>(json['lawId']),
      articleNum: serializer.fromJson<String?>(json['articleNum']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lawId': serializer.toJson<String>(lawId),
      'articleNum': serializer.toJson<String?>(articleNum),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Bookmark copyWith(
          {int? id,
          String? lawId,
          Value<String?> articleNum = const Value.absent(),
          String? createdAt}) =>
      Bookmark(
        id: id ?? this.id,
        lawId: lawId ?? this.lawId,
        articleNum: articleNum.present ? articleNum.value : this.articleNum,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      lawId: data.lawId.present ? data.lawId.value : this.lawId,
      articleNum:
          data.articleNum.present ? data.articleNum.value : this.articleNum,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('lawId: $lawId, ')
          ..write('articleNum: $articleNum, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lawId, articleNum, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.lawId == this.lawId &&
          other.articleNum == this.articleNum &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<String> lawId;
  final Value<String?> articleNum;
  final Value<String> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.lawId = const Value.absent(),
    this.articleNum = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required String lawId,
    this.articleNum = const Value.absent(),
    required String createdAt,
  })  : lawId = Value(lawId),
        createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<String>? lawId,
    Expression<String>? articleNum,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lawId != null) 'law_id': lawId,
      if (articleNum != null) 'article_num': articleNum,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith(
      {Value<int>? id,
      Value<String>? lawId,
      Value<String?>? articleNum,
      Value<String>? createdAt}) {
    return BookmarksCompanion(
      id: id ?? this.id,
      lawId: lawId ?? this.lawId,
      articleNum: articleNum ?? this.articleNum,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lawId.present) {
      map['law_id'] = Variable<String>(lawId.value);
    }
    if (articleNum.present) {
      map['article_num'] = Variable<String>(articleNum.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('lawId: $lawId, ')
          ..write('articleNum: $articleNum, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LawsTable laws = $LawsTable(this);
  late final $LawRevisionsTable lawRevisions = $LawRevisionsTable(this);
  late final $ArticlesTable articles = $ArticlesTable(this);
  late final $SyncRunsTable syncRuns = $SyncRunsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [laws, lawRevisions, articles, syncRuns, appMeta, bookmarks];
}

typedef $$LawsTableCreateCompanionBuilder = LawsCompanion Function({
  required String lawId,
  required String lawNum,
  required String lawType,
  required String title,
  Value<String?> titleKana,
  Value<String?> abbrev,
  Value<String?> category,
  Value<String?> promulgationDate,
  Value<String> repealStatus,
  Value<String?> repealDate,
  required String scopeReason,
  Value<String?> currentRevisionId,
  Value<String?> currentEnforcedAt,
  Value<String?> amendmentLawTitle,
  Value<String?> catalogUpdated,
  Value<String?> pendingRevisionId,
  Value<String?> bodyRevisionId,
  Value<String?> bodySyncedAt,
  Value<bool> bodyIncludesAmendSuppl,
  Value<String?> missingSince,
  Value<String?> lastOpenedAt,
  Value<int> rowid,
});
typedef $$LawsTableUpdateCompanionBuilder = LawsCompanion Function({
  Value<String> lawId,
  Value<String> lawNum,
  Value<String> lawType,
  Value<String> title,
  Value<String?> titleKana,
  Value<String?> abbrev,
  Value<String?> category,
  Value<String?> promulgationDate,
  Value<String> repealStatus,
  Value<String?> repealDate,
  Value<String> scopeReason,
  Value<String?> currentRevisionId,
  Value<String?> currentEnforcedAt,
  Value<String?> amendmentLawTitle,
  Value<String?> catalogUpdated,
  Value<String?> pendingRevisionId,
  Value<String?> bodyRevisionId,
  Value<String?> bodySyncedAt,
  Value<bool> bodyIncludesAmendSuppl,
  Value<String?> missingSince,
  Value<String?> lastOpenedAt,
  Value<int> rowid,
});

final class $$LawsTableReferences
    extends BaseReferences<_$AppDatabase, $LawsTable, Law> {
  $$LawsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LawRevisionsTable, List<LawRevision>>
      _lawRevisionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.lawRevisions,
              aliasName: 'laws__law_id__law_revisions__law_id');

  $$LawRevisionsTableProcessedTableManager get lawRevisionsRefs {
    final manager = $$LawRevisionsTableTableManager($_db, $_db.lawRevisions)
        .filter(
            (f) => f.lawId.lawId.sqlEquals($_itemColumn<String>('law_id')!));

    final cache = $_typedResult.readTableOrNull(_lawRevisionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ArticlesTable, List<Article>> _articlesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.articles,
          aliasName: 'laws__law_id__articles__law_id');

  $$ArticlesTableProcessedTableManager get articlesRefs {
    final manager = $$ArticlesTableTableManager($_db, $_db.articles).filter(
        (f) => f.lawId.lawId.sqlEquals($_itemColumn<String>('law_id')!));

    final cache = $_typedResult.readTableOrNull(_articlesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
      _bookmarksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.bookmarks,
              aliasName: 'laws__law_id__bookmarks__law_id');

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager($_db, $_db.bookmarks).filter(
        (f) => f.lawId.lawId.sqlEquals($_itemColumn<String>('law_id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LawsTableFilterComposer extends Composer<_$AppDatabase, $LawsTable> {
  $$LawsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lawId => $composableBuilder(
      column: $table.lawId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lawNum => $composableBuilder(
      column: $table.lawNum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lawType => $composableBuilder(
      column: $table.lawType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleKana => $composableBuilder(
      column: $table.titleKana, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get abbrev => $composableBuilder(
      column: $table.abbrev, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promulgationDate => $composableBuilder(
      column: $table.promulgationDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repealStatus => $composableBuilder(
      column: $table.repealStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repealDate => $composableBuilder(
      column: $table.repealDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scopeReason => $composableBuilder(
      column: $table.scopeReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentRevisionId => $composableBuilder(
      column: $table.currentRevisionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentEnforcedAt => $composableBuilder(
      column: $table.currentEnforcedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amendmentLawTitle => $composableBuilder(
      column: $table.amendmentLawTitle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get catalogUpdated => $composableBuilder(
      column: $table.catalogUpdated,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pendingRevisionId => $composableBuilder(
      column: $table.pendingRevisionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyRevisionId => $composableBuilder(
      column: $table.bodyRevisionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodySyncedAt => $composableBuilder(
      column: $table.bodySyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get bodyIncludesAmendSuppl => $composableBuilder(
      column: $table.bodyIncludesAmendSuppl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get missingSince => $composableBuilder(
      column: $table.missingSince, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> lawRevisionsRefs(
      Expression<bool> Function($$LawRevisionsTableFilterComposer f) f) {
    final $$LawRevisionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.lawRevisions,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawRevisionsTableFilterComposer(
              $db: $db,
              $table: $db.lawRevisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> articlesRefs(
      Expression<bool> Function($$ArticlesTableFilterComposer f) f) {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.articles,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArticlesTableFilterComposer(
              $db: $db,
              $table: $db.articles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
      Expression<bool> Function($$BookmarksTableFilterComposer f) f) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableFilterComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LawsTableOrderingComposer extends Composer<_$AppDatabase, $LawsTable> {
  $$LawsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lawId => $composableBuilder(
      column: $table.lawId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lawNum => $composableBuilder(
      column: $table.lawNum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lawType => $composableBuilder(
      column: $table.lawType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleKana => $composableBuilder(
      column: $table.titleKana, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get abbrev => $composableBuilder(
      column: $table.abbrev, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promulgationDate => $composableBuilder(
      column: $table.promulgationDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repealStatus => $composableBuilder(
      column: $table.repealStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repealDate => $composableBuilder(
      column: $table.repealDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scopeReason => $composableBuilder(
      column: $table.scopeReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentRevisionId => $composableBuilder(
      column: $table.currentRevisionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentEnforcedAt => $composableBuilder(
      column: $table.currentEnforcedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amendmentLawTitle => $composableBuilder(
      column: $table.amendmentLawTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get catalogUpdated => $composableBuilder(
      column: $table.catalogUpdated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pendingRevisionId => $composableBuilder(
      column: $table.pendingRevisionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyRevisionId => $composableBuilder(
      column: $table.bodyRevisionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodySyncedAt => $composableBuilder(
      column: $table.bodySyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get bodyIncludesAmendSuppl => $composableBuilder(
      column: $table.bodyIncludesAmendSuppl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get missingSince => $composableBuilder(
      column: $table.missingSince,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$LawsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LawsTable> {
  $$LawsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lawId =>
      $composableBuilder(column: $table.lawId, builder: (column) => column);

  GeneratedColumn<String> get lawNum =>
      $composableBuilder(column: $table.lawNum, builder: (column) => column);

  GeneratedColumn<String> get lawType =>
      $composableBuilder(column: $table.lawType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleKana =>
      $composableBuilder(column: $table.titleKana, builder: (column) => column);

  GeneratedColumn<String> get abbrev =>
      $composableBuilder(column: $table.abbrev, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get promulgationDate => $composableBuilder(
      column: $table.promulgationDate, builder: (column) => column);

  GeneratedColumn<String> get repealStatus => $composableBuilder(
      column: $table.repealStatus, builder: (column) => column);

  GeneratedColumn<String> get repealDate => $composableBuilder(
      column: $table.repealDate, builder: (column) => column);

  GeneratedColumn<String> get scopeReason => $composableBuilder(
      column: $table.scopeReason, builder: (column) => column);

  GeneratedColumn<String> get currentRevisionId => $composableBuilder(
      column: $table.currentRevisionId, builder: (column) => column);

  GeneratedColumn<String> get currentEnforcedAt => $composableBuilder(
      column: $table.currentEnforcedAt, builder: (column) => column);

  GeneratedColumn<String> get amendmentLawTitle => $composableBuilder(
      column: $table.amendmentLawTitle, builder: (column) => column);

  GeneratedColumn<String> get catalogUpdated => $composableBuilder(
      column: $table.catalogUpdated, builder: (column) => column);

  GeneratedColumn<String> get pendingRevisionId => $composableBuilder(
      column: $table.pendingRevisionId, builder: (column) => column);

  GeneratedColumn<String> get bodyRevisionId => $composableBuilder(
      column: $table.bodyRevisionId, builder: (column) => column);

  GeneratedColumn<String> get bodySyncedAt => $composableBuilder(
      column: $table.bodySyncedAt, builder: (column) => column);

  GeneratedColumn<bool> get bodyIncludesAmendSuppl => $composableBuilder(
      column: $table.bodyIncludesAmendSuppl, builder: (column) => column);

  GeneratedColumn<String> get missingSince => $composableBuilder(
      column: $table.missingSince, builder: (column) => column);

  GeneratedColumn<String> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  Expression<T> lawRevisionsRefs<T extends Object>(
      Expression<T> Function($$LawRevisionsTableAnnotationComposer a) f) {
    final $$LawRevisionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.lawRevisions,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawRevisionsTableAnnotationComposer(
              $db: $db,
              $table: $db.lawRevisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> articlesRefs<T extends Object>(
      Expression<T> Function($$ArticlesTableAnnotationComposer a) f) {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.articles,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ArticlesTableAnnotationComposer(
              $db: $db,
              $table: $db.articles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
      Expression<T> Function($$BookmarksTableAnnotationComposer a) f) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableAnnotationComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LawsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LawsTable,
    Law,
    $$LawsTableFilterComposer,
    $$LawsTableOrderingComposer,
    $$LawsTableAnnotationComposer,
    $$LawsTableCreateCompanionBuilder,
    $$LawsTableUpdateCompanionBuilder,
    (Law, $$LawsTableReferences),
    Law,
    PrefetchHooks Function(
        {bool lawRevisionsRefs, bool articlesRefs, bool bookmarksRefs})> {
  $$LawsTableTableManager(_$AppDatabase db, $LawsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LawsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LawsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LawsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> lawId = const Value.absent(),
            Value<String> lawNum = const Value.absent(),
            Value<String> lawType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> titleKana = const Value.absent(),
            Value<String?> abbrev = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> promulgationDate = const Value.absent(),
            Value<String> repealStatus = const Value.absent(),
            Value<String?> repealDate = const Value.absent(),
            Value<String> scopeReason = const Value.absent(),
            Value<String?> currentRevisionId = const Value.absent(),
            Value<String?> currentEnforcedAt = const Value.absent(),
            Value<String?> amendmentLawTitle = const Value.absent(),
            Value<String?> catalogUpdated = const Value.absent(),
            Value<String?> pendingRevisionId = const Value.absent(),
            Value<String?> bodyRevisionId = const Value.absent(),
            Value<String?> bodySyncedAt = const Value.absent(),
            Value<bool> bodyIncludesAmendSuppl = const Value.absent(),
            Value<String?> missingSince = const Value.absent(),
            Value<String?> lastOpenedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LawsCompanion(
            lawId: lawId,
            lawNum: lawNum,
            lawType: lawType,
            title: title,
            titleKana: titleKana,
            abbrev: abbrev,
            category: category,
            promulgationDate: promulgationDate,
            repealStatus: repealStatus,
            repealDate: repealDate,
            scopeReason: scopeReason,
            currentRevisionId: currentRevisionId,
            currentEnforcedAt: currentEnforcedAt,
            amendmentLawTitle: amendmentLawTitle,
            catalogUpdated: catalogUpdated,
            pendingRevisionId: pendingRevisionId,
            bodyRevisionId: bodyRevisionId,
            bodySyncedAt: bodySyncedAt,
            bodyIncludesAmendSuppl: bodyIncludesAmendSuppl,
            missingSince: missingSince,
            lastOpenedAt: lastOpenedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String lawId,
            required String lawNum,
            required String lawType,
            required String title,
            Value<String?> titleKana = const Value.absent(),
            Value<String?> abbrev = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> promulgationDate = const Value.absent(),
            Value<String> repealStatus = const Value.absent(),
            Value<String?> repealDate = const Value.absent(),
            required String scopeReason,
            Value<String?> currentRevisionId = const Value.absent(),
            Value<String?> currentEnforcedAt = const Value.absent(),
            Value<String?> amendmentLawTitle = const Value.absent(),
            Value<String?> catalogUpdated = const Value.absent(),
            Value<String?> pendingRevisionId = const Value.absent(),
            Value<String?> bodyRevisionId = const Value.absent(),
            Value<String?> bodySyncedAt = const Value.absent(),
            Value<bool> bodyIncludesAmendSuppl = const Value.absent(),
            Value<String?> missingSince = const Value.absent(),
            Value<String?> lastOpenedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LawsCompanion.insert(
            lawId: lawId,
            lawNum: lawNum,
            lawType: lawType,
            title: title,
            titleKana: titleKana,
            abbrev: abbrev,
            category: category,
            promulgationDate: promulgationDate,
            repealStatus: repealStatus,
            repealDate: repealDate,
            scopeReason: scopeReason,
            currentRevisionId: currentRevisionId,
            currentEnforcedAt: currentEnforcedAt,
            amendmentLawTitle: amendmentLawTitle,
            catalogUpdated: catalogUpdated,
            pendingRevisionId: pendingRevisionId,
            bodyRevisionId: bodyRevisionId,
            bodySyncedAt: bodySyncedAt,
            bodyIncludesAmendSuppl: bodyIncludesAmendSuppl,
            missingSince: missingSince,
            lastOpenedAt: lastOpenedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LawsTable, Law>(table),
                    $$LawsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {lawRevisionsRefs = false,
              articlesRefs = false,
              bookmarksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (lawRevisionsRefs) db.lawRevisions,
                if (articlesRefs) db.articles,
                if (bookmarksRefs) db.bookmarks
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lawRevisionsRefs)
                    await $_getPrefetchedData<Law, $LawsTable, LawRevision>(
                        currentTable: table,
                        referencedTable:
                            $$LawsTableReferences._lawRevisionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LawsTableReferences(db, table, p0)
                                .lawRevisionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lawId == item.lawId),
                        typedResults: items),
                  if (articlesRefs)
                    await $_getPrefetchedData<Law, $LawsTable, Article>(
                        currentTable: table,
                        referencedTable:
                            $$LawsTableReferences._articlesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LawsTableReferences(db, table, p0).articlesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lawId == item.lawId),
                        typedResults: items),
                  if (bookmarksRefs)
                    await $_getPrefetchedData<Law, $LawsTable, Bookmark>(
                        currentTable: table,
                        referencedTable:
                            $$LawsTableReferences._bookmarksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LawsTableReferences(db, table, p0).bookmarksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lawId == item.lawId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LawsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LawsTable,
    Law,
    $$LawsTableFilterComposer,
    $$LawsTableOrderingComposer,
    $$LawsTableAnnotationComposer,
    $$LawsTableCreateCompanionBuilder,
    $$LawsTableUpdateCompanionBuilder,
    (Law, $$LawsTableReferences),
    Law,
    PrefetchHooks Function(
        {bool lawRevisionsRefs, bool articlesRefs, bool bookmarksRefs})>;
typedef $$LawRevisionsTableCreateCompanionBuilder = LawRevisionsCompanion
    Function({
  required String revisionId,
  required String lawId,
  required String enforcedAt,
  Value<String?> promulgatedAt,
  Value<String?> scheduledEnforcedAt,
  Value<String?> enforcementComment,
  Value<String?> amendmentLawId,
  Value<String?> amendmentLawNum,
  Value<String?> amendmentLawTitle,
  Value<String?> amendmentType,
  required String status,
  Value<String?> apiUpdated,
  required String fetchedAt,
  Value<int> rowid,
});
typedef $$LawRevisionsTableUpdateCompanionBuilder = LawRevisionsCompanion
    Function({
  Value<String> revisionId,
  Value<String> lawId,
  Value<String> enforcedAt,
  Value<String?> promulgatedAt,
  Value<String?> scheduledEnforcedAt,
  Value<String?> enforcementComment,
  Value<String?> amendmentLawId,
  Value<String?> amendmentLawNum,
  Value<String?> amendmentLawTitle,
  Value<String?> amendmentType,
  Value<String> status,
  Value<String?> apiUpdated,
  Value<String> fetchedAt,
  Value<int> rowid,
});

final class $$LawRevisionsTableReferences
    extends BaseReferences<_$AppDatabase, $LawRevisionsTable, LawRevision> {
  $$LawRevisionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LawsTable _lawIdTable(_$AppDatabase db) =>
      db.laws.createAlias('law_revisions__law_id__laws__law_id');

  $$LawsTableProcessedTableManager get lawId {
    final $_column = $_itemColumn<String>('law_id')!;

    final manager = $$LawsTableTableManager($_db, $_db.laws)
        .filter((f) => f.lawId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lawIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LawRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $LawRevisionsTable> {
  $$LawRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get revisionId => $composableBuilder(
      column: $table.revisionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enforcedAt => $composableBuilder(
      column: $table.enforcedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promulgatedAt => $composableBuilder(
      column: $table.promulgatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scheduledEnforcedAt => $composableBuilder(
      column: $table.scheduledEnforcedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enforcementComment => $composableBuilder(
      column: $table.enforcementComment,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amendmentLawId => $composableBuilder(
      column: $table.amendmentLawId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amendmentLawNum => $composableBuilder(
      column: $table.amendmentLawNum,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amendmentLawTitle => $composableBuilder(
      column: $table.amendmentLawTitle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amendmentType => $composableBuilder(
      column: $table.amendmentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apiUpdated => $composableBuilder(
      column: $table.apiUpdated, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));

  $$LawsTableFilterComposer get lawId {
    final $$LawsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableFilterComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LawRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LawRevisionsTable> {
  $$LawRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get revisionId => $composableBuilder(
      column: $table.revisionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enforcedAt => $composableBuilder(
      column: $table.enforcedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promulgatedAt => $composableBuilder(
      column: $table.promulgatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scheduledEnforcedAt => $composableBuilder(
      column: $table.scheduledEnforcedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enforcementComment => $composableBuilder(
      column: $table.enforcementComment,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amendmentLawId => $composableBuilder(
      column: $table.amendmentLawId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amendmentLawNum => $composableBuilder(
      column: $table.amendmentLawNum,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amendmentLawTitle => $composableBuilder(
      column: $table.amendmentLawTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amendmentType => $composableBuilder(
      column: $table.amendmentType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiUpdated => $composableBuilder(
      column: $table.apiUpdated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));

  $$LawsTableOrderingComposer get lawId {
    final $$LawsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableOrderingComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LawRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LawRevisionsTable> {
  $$LawRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get revisionId => $composableBuilder(
      column: $table.revisionId, builder: (column) => column);

  GeneratedColumn<String> get enforcedAt => $composableBuilder(
      column: $table.enforcedAt, builder: (column) => column);

  GeneratedColumn<String> get promulgatedAt => $composableBuilder(
      column: $table.promulgatedAt, builder: (column) => column);

  GeneratedColumn<String> get scheduledEnforcedAt => $composableBuilder(
      column: $table.scheduledEnforcedAt, builder: (column) => column);

  GeneratedColumn<String> get enforcementComment => $composableBuilder(
      column: $table.enforcementComment, builder: (column) => column);

  GeneratedColumn<String> get amendmentLawId => $composableBuilder(
      column: $table.amendmentLawId, builder: (column) => column);

  GeneratedColumn<String> get amendmentLawNum => $composableBuilder(
      column: $table.amendmentLawNum, builder: (column) => column);

  GeneratedColumn<String> get amendmentLawTitle => $composableBuilder(
      column: $table.amendmentLawTitle, builder: (column) => column);

  GeneratedColumn<String> get amendmentType => $composableBuilder(
      column: $table.amendmentType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get apiUpdated => $composableBuilder(
      column: $table.apiUpdated, builder: (column) => column);

  GeneratedColumn<String> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  $$LawsTableAnnotationComposer get lawId {
    final $$LawsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableAnnotationComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LawRevisionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LawRevisionsTable,
    LawRevision,
    $$LawRevisionsTableFilterComposer,
    $$LawRevisionsTableOrderingComposer,
    $$LawRevisionsTableAnnotationComposer,
    $$LawRevisionsTableCreateCompanionBuilder,
    $$LawRevisionsTableUpdateCompanionBuilder,
    (LawRevision, $$LawRevisionsTableReferences),
    LawRevision,
    PrefetchHooks Function({bool lawId})> {
  $$LawRevisionsTableTableManager(_$AppDatabase db, $LawRevisionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LawRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LawRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LawRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> revisionId = const Value.absent(),
            Value<String> lawId = const Value.absent(),
            Value<String> enforcedAt = const Value.absent(),
            Value<String?> promulgatedAt = const Value.absent(),
            Value<String?> scheduledEnforcedAt = const Value.absent(),
            Value<String?> enforcementComment = const Value.absent(),
            Value<String?> amendmentLawId = const Value.absent(),
            Value<String?> amendmentLawNum = const Value.absent(),
            Value<String?> amendmentLawTitle = const Value.absent(),
            Value<String?> amendmentType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> apiUpdated = const Value.absent(),
            Value<String> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LawRevisionsCompanion(
            revisionId: revisionId,
            lawId: lawId,
            enforcedAt: enforcedAt,
            promulgatedAt: promulgatedAt,
            scheduledEnforcedAt: scheduledEnforcedAt,
            enforcementComment: enforcementComment,
            amendmentLawId: amendmentLawId,
            amendmentLawNum: amendmentLawNum,
            amendmentLawTitle: amendmentLawTitle,
            amendmentType: amendmentType,
            status: status,
            apiUpdated: apiUpdated,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String revisionId,
            required String lawId,
            required String enforcedAt,
            Value<String?> promulgatedAt = const Value.absent(),
            Value<String?> scheduledEnforcedAt = const Value.absent(),
            Value<String?> enforcementComment = const Value.absent(),
            Value<String?> amendmentLawId = const Value.absent(),
            Value<String?> amendmentLawNum = const Value.absent(),
            Value<String?> amendmentLawTitle = const Value.absent(),
            Value<String?> amendmentType = const Value.absent(),
            required String status,
            Value<String?> apiUpdated = const Value.absent(),
            required String fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LawRevisionsCompanion.insert(
            revisionId: revisionId,
            lawId: lawId,
            enforcedAt: enforcedAt,
            promulgatedAt: promulgatedAt,
            scheduledEnforcedAt: scheduledEnforcedAt,
            enforcementComment: enforcementComment,
            amendmentLawId: amendmentLawId,
            amendmentLawNum: amendmentLawNum,
            amendmentLawTitle: amendmentLawTitle,
            amendmentType: amendmentType,
            status: status,
            apiUpdated: apiUpdated,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LawRevisionsTable, LawRevision>(table),
                    $$LawRevisionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lawId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lawId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lawId,
                    referencedTable:
                        $$LawRevisionsTableReferences._lawIdTable(db),
                    referencedColumn:
                        $$LawRevisionsTableReferences._lawIdTable(db).lawId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LawRevisionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LawRevisionsTable,
    LawRevision,
    $$LawRevisionsTableFilterComposer,
    $$LawRevisionsTableOrderingComposer,
    $$LawRevisionsTableAnnotationComposer,
    $$LawRevisionsTableCreateCompanionBuilder,
    $$LawRevisionsTableUpdateCompanionBuilder,
    (LawRevision, $$LawRevisionsTableReferences),
    LawRevision,
    PrefetchHooks Function({bool lawId})>;
typedef $$ArticlesTableCreateCompanionBuilder = ArticlesCompanion Function({
  Value<int> id,
  required String lawId,
  required String revisionId,
  required int seq,
  required String section,
  Value<String?> supplAmendLawNum,
  required String path,
  Value<String?> articleNum,
  Value<String?> articleTitle,
  Value<String?> caption,
  Value<String?> breadcrumb,
  required String plainText,
  required String bodyJson,
});
typedef $$ArticlesTableUpdateCompanionBuilder = ArticlesCompanion Function({
  Value<int> id,
  Value<String> lawId,
  Value<String> revisionId,
  Value<int> seq,
  Value<String> section,
  Value<String?> supplAmendLawNum,
  Value<String> path,
  Value<String?> articleNum,
  Value<String?> articleTitle,
  Value<String?> caption,
  Value<String?> breadcrumb,
  Value<String> plainText,
  Value<String> bodyJson,
});

final class $$ArticlesTableReferences
    extends BaseReferences<_$AppDatabase, $ArticlesTable, Article> {
  $$ArticlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LawsTable _lawIdTable(_$AppDatabase db) =>
      db.laws.createAlias('articles__law_id__laws__law_id');

  $$LawsTableProcessedTableManager get lawId {
    final $_column = $_itemColumn<String>('law_id')!;

    final manager = $$LawsTableTableManager($_db, $_db.laws)
        .filter((f) => f.lawId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lawIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get revisionId => $composableBuilder(
      column: $table.revisionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get section => $composableBuilder(
      column: $table.section, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supplAmendLawNum => $composableBuilder(
      column: $table.supplAmendLawNum,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get articleNum => $composableBuilder(
      column: $table.articleNum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get articleTitle => $composableBuilder(
      column: $table.articleTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get breadcrumb => $composableBuilder(
      column: $table.breadcrumb, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyJson => $composableBuilder(
      column: $table.bodyJson, builder: (column) => ColumnFilters(column));

  $$LawsTableFilterComposer get lawId {
    final $$LawsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableFilterComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get revisionId => $composableBuilder(
      column: $table.revisionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get section => $composableBuilder(
      column: $table.section, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supplAmendLawNum => $composableBuilder(
      column: $table.supplAmendLawNum,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get articleNum => $composableBuilder(
      column: $table.articleNum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get articleTitle => $composableBuilder(
      column: $table.articleTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get breadcrumb => $composableBuilder(
      column: $table.breadcrumb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyJson => $composableBuilder(
      column: $table.bodyJson, builder: (column) => ColumnOrderings(column));

  $$LawsTableOrderingComposer get lawId {
    final $$LawsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableOrderingComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get revisionId => $composableBuilder(
      column: $table.revisionId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get supplAmendLawNum => $composableBuilder(
      column: $table.supplAmendLawNum, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get articleNum => $composableBuilder(
      column: $table.articleNum, builder: (column) => column);

  GeneratedColumn<String> get articleTitle => $composableBuilder(
      column: $table.articleTitle, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get breadcrumb => $composableBuilder(
      column: $table.breadcrumb, builder: (column) => column);

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<String> get bodyJson =>
      $composableBuilder(column: $table.bodyJson, builder: (column) => column);

  $$LawsTableAnnotationComposer get lawId {
    final $$LawsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableAnnotationComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ArticlesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ArticlesTable,
    Article,
    $$ArticlesTableFilterComposer,
    $$ArticlesTableOrderingComposer,
    $$ArticlesTableAnnotationComposer,
    $$ArticlesTableCreateCompanionBuilder,
    $$ArticlesTableUpdateCompanionBuilder,
    (Article, $$ArticlesTableReferences),
    Article,
    PrefetchHooks Function({bool lawId})> {
  $$ArticlesTableTableManager(_$AppDatabase db, $ArticlesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> lawId = const Value.absent(),
            Value<String> revisionId = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<String> section = const Value.absent(),
            Value<String?> supplAmendLawNum = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String?> articleNum = const Value.absent(),
            Value<String?> articleTitle = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<String?> breadcrumb = const Value.absent(),
            Value<String> plainText = const Value.absent(),
            Value<String> bodyJson = const Value.absent(),
          }) =>
              ArticlesCompanion(
            id: id,
            lawId: lawId,
            revisionId: revisionId,
            seq: seq,
            section: section,
            supplAmendLawNum: supplAmendLawNum,
            path: path,
            articleNum: articleNum,
            articleTitle: articleTitle,
            caption: caption,
            breadcrumb: breadcrumb,
            plainText: plainText,
            bodyJson: bodyJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String lawId,
            required String revisionId,
            required int seq,
            required String section,
            Value<String?> supplAmendLawNum = const Value.absent(),
            required String path,
            Value<String?> articleNum = const Value.absent(),
            Value<String?> articleTitle = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<String?> breadcrumb = const Value.absent(),
            required String plainText,
            required String bodyJson,
          }) =>
              ArticlesCompanion.insert(
            id: id,
            lawId: lawId,
            revisionId: revisionId,
            seq: seq,
            section: section,
            supplAmendLawNum: supplAmendLawNum,
            path: path,
            articleNum: articleNum,
            articleTitle: articleTitle,
            caption: caption,
            breadcrumb: breadcrumb,
            plainText: plainText,
            bodyJson: bodyJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ArticlesTable, Article>(table),
                    $$ArticlesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lawId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lawId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lawId,
                    referencedTable: $$ArticlesTableReferences._lawIdTable(db),
                    referencedColumn:
                        $$ArticlesTableReferences._lawIdTable(db).lawId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ArticlesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ArticlesTable,
    Article,
    $$ArticlesTableFilterComposer,
    $$ArticlesTableOrderingComposer,
    $$ArticlesTableAnnotationComposer,
    $$ArticlesTableCreateCompanionBuilder,
    $$ArticlesTableUpdateCompanionBuilder,
    (Article, $$ArticlesTableReferences),
    Article,
    PrefetchHooks Function({bool lawId})>;
typedef $$SyncRunsTableCreateCompanionBuilder = SyncRunsCompanion Function({
  Value<int> id,
  required String startedAt,
  Value<String?> finishedAt,
  required String status,
  Value<int> lawsChecked,
  Value<int> lawsUpdated,
  Value<int> bytesDownloaded,
  Value<String?> error,
});
typedef $$SyncRunsTableUpdateCompanionBuilder = SyncRunsCompanion Function({
  Value<int> id,
  Value<String> startedAt,
  Value<String?> finishedAt,
  Value<String> status,
  Value<int> lawsChecked,
  Value<int> lawsUpdated,
  Value<int> bytesDownloaded,
  Value<String?> error,
});

class $$SyncRunsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncRunsTable> {
  $$SyncRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lawsChecked => $composableBuilder(
      column: $table.lawsChecked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lawsUpdated => $composableBuilder(
      column: $table.lawsUpdated, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytesDownloaded => $composableBuilder(
      column: $table.bytesDownloaded,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));
}

class $$SyncRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncRunsTable> {
  $$SyncRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lawsChecked => $composableBuilder(
      column: $table.lawsChecked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lawsUpdated => $composableBuilder(
      column: $table.lawsUpdated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytesDownloaded => $composableBuilder(
      column: $table.bytesDownloaded,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));
}

class $$SyncRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncRunsTable> {
  $$SyncRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get finishedAt => $composableBuilder(
      column: $table.finishedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get lawsChecked => $composableBuilder(
      column: $table.lawsChecked, builder: (column) => column);

  GeneratedColumn<int> get lawsUpdated => $composableBuilder(
      column: $table.lawsUpdated, builder: (column) => column);

  GeneratedColumn<int> get bytesDownloaded => $composableBuilder(
      column: $table.bytesDownloaded, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SyncRunsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncRunsTable,
    SyncRun,
    $$SyncRunsTableFilterComposer,
    $$SyncRunsTableOrderingComposer,
    $$SyncRunsTableAnnotationComposer,
    $$SyncRunsTableCreateCompanionBuilder,
    $$SyncRunsTableUpdateCompanionBuilder,
    (SyncRun, BaseReferences<_$AppDatabase, $SyncRunsTable, SyncRun>),
    SyncRun,
    PrefetchHooks Function()> {
  $$SyncRunsTableTableManager(_$AppDatabase db, $SyncRunsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> startedAt = const Value.absent(),
            Value<String?> finishedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> lawsChecked = const Value.absent(),
            Value<int> lawsUpdated = const Value.absent(),
            Value<int> bytesDownloaded = const Value.absent(),
            Value<String?> error = const Value.absent(),
          }) =>
              SyncRunsCompanion(
            id: id,
            startedAt: startedAt,
            finishedAt: finishedAt,
            status: status,
            lawsChecked: lawsChecked,
            lawsUpdated: lawsUpdated,
            bytesDownloaded: bytesDownloaded,
            error: error,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String startedAt,
            Value<String?> finishedAt = const Value.absent(),
            required String status,
            Value<int> lawsChecked = const Value.absent(),
            Value<int> lawsUpdated = const Value.absent(),
            Value<int> bytesDownloaded = const Value.absent(),
            Value<String?> error = const Value.absent(),
          }) =>
              SyncRunsCompanion.insert(
            id: id,
            startedAt: startedAt,
            finishedAt: finishedAt,
            status: status,
            lawsChecked: lawsChecked,
            lawsUpdated: lawsUpdated,
            bytesDownloaded: bytesDownloaded,
            error: error,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncRunsTable, SyncRun>(table),
                    BaseReferences<_$AppDatabase, $SyncRunsTable, SyncRun>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncRunsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncRunsTable,
    SyncRun,
    $$SyncRunsTableFilterComposer,
    $$SyncRunsTableOrderingComposer,
    $$SyncRunsTableAnnotationComposer,
    $$SyncRunsTableCreateCompanionBuilder,
    $$SyncRunsTableUpdateCompanionBuilder,
    (SyncRun, BaseReferences<_$AppDatabase, $SyncRunsTable, SyncRun>),
    SyncRun,
    PrefetchHooks Function()>;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
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

class $$AppMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaData,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
    AppMetaData,
    PrefetchHooks Function()> {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AppMetaTable, AppMetaData>(table),
                    BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaData,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
    AppMetaData,
    PrefetchHooks Function()>;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  required String lawId,
  Value<String?> articleNum,
  required String createdAt,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  Value<String> lawId,
  Value<String?> articleNum,
  Value<String> createdAt,
});

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LawsTable _lawIdTable(_$AppDatabase db) =>
      db.laws.createAlias('bookmarks__law_id__laws__law_id');

  $$LawsTableProcessedTableManager get lawId {
    final $_column = $_itemColumn<String>('law_id')!;

    final manager = $$LawsTableTableManager($_db, $_db.laws)
        .filter((f) => f.lawId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lawIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get articleNum => $composableBuilder(
      column: $table.articleNum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$LawsTableFilterComposer get lawId {
    final $$LawsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableFilterComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get articleNum => $composableBuilder(
      column: $table.articleNum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$LawsTableOrderingComposer get lawId {
    final $$LawsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableOrderingComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get articleNum => $composableBuilder(
      column: $table.articleNum, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LawsTableAnnotationComposer get lawId {
    final $$LawsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lawId,
        referencedTable: $db.laws,
        getReferencedColumn: (t) => t.lawId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LawsTableAnnotationComposer(
              $db: $db,
              $table: $db.laws,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, $$BookmarksTableReferences),
    Bookmark,
    PrefetchHooks Function({bool lawId})> {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> lawId = const Value.absent(),
            Value<String?> articleNum = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
          }) =>
              BookmarksCompanion(
            id: id,
            lawId: lawId,
            articleNum: articleNum,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String lawId,
            Value<String?> articleNum = const Value.absent(),
            required String createdAt,
          }) =>
              BookmarksCompanion.insert(
            id: id,
            lawId: lawId,
            articleNum: articleNum,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BookmarksTable, Bookmark>(table),
                    $$BookmarksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lawId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lawId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lawId,
                    referencedTable: $$BookmarksTableReferences._lawIdTable(db),
                    referencedColumn:
                        $$BookmarksTableReferences._lawIdTable(db).lawId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, $$BookmarksTableReferences),
    Bookmark,
    PrefetchHooks Function({bool lawId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LawsTableTableManager get laws => $$LawsTableTableManager(_db, _db.laws);
  $$LawRevisionsTableTableManager get lawRevisions =>
      $$LawRevisionsTableTableManager(_db, _db.lawRevisions);
  $$ArticlesTableTableManager get articles =>
      $$ArticlesTableTableManager(_db, _db.articles);
  $$SyncRunsTableTableManager get syncRuns =>
      $$SyncRunsTableTableManager(_db, _db.syncRuns);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
}
