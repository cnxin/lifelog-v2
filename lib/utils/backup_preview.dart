import 'dart:convert';

import '../models/lifelog_models.dart';

class BackupPreview {
  final LifeLogBackup backup;
  final int peopleCount;
  final int placesCount;
  final int memoriesCount;
  final int photoCount;
  final int placeMergeHistoryCount;
  final bool hasSettings;
  final bool hasReminderSettings;
  final List<String> warnings;

  const BackupPreview({
    required this.backup,
    required this.peopleCount,
    required this.placesCount,
    required this.memoriesCount,
    required this.photoCount,
    required this.placeMergeHistoryCount,
    required this.hasSettings,
    required this.hasReminderSettings,
    this.warnings = const [],
  });

  int get totalRecords => peopleCount + placesCount + memoriesCount;

  String get sourceLabel {
    if (backup.appVersion.isNotEmpty) return 'LifeLog ${backup.appVersion}';
    return backup.schemaVersion <= 1 ? '旧版 LifeLog 备份' : 'LifeLog 备份';
  }
}

BackupPreview parseBackupPreview(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map) {
    throw const FormatException('Backup JSON must be an object.');
  }

  final map = Map<String, dynamic>.from(decoded);
  final backup = LifeLogBackup.fromJson(map);
  final state = backup.state;
  final integrity = map['integrity'] is Map
      ? Map<String, dynamic>.from(map['integrity'] as Map)
      : const <String, dynamic>{};

  return BackupPreview(
    backup: backup,
    peopleCount: state.people.length,
    placesCount: state.places.length,
    memoriesCount: state.memories.length,
    photoCount: backup.photos.length,
    placeMergeHistoryCount: backup.placeMergeHistory.length,
    hasSettings: map['settings'] is Map,
    hasReminderSettings: map['reminderSettings'] is Map,
    warnings: _integrityWarnings(
      integrity: integrity,
      peopleCount: state.people.length,
      placesCount: state.places.length,
      memoriesCount: state.memories.length,
      photoCount: backup.photos.length,
      placeMergeHistoryCount: backup.placeMergeHistory.length,
    ),
  );
}

List<String> _integrityWarnings({
  required Map<String, dynamic> integrity,
  required int peopleCount,
  required int placesCount,
  required int memoriesCount,
  required int photoCount,
  required int placeMergeHistoryCount,
}) {
  if (integrity.isEmpty) return const [];

  final warnings = <String>[];
  _checkCount(warnings, integrity, 'people', peopleCount, '人物');
  _checkCount(warnings, integrity, 'places', placesCount, '地点');
  _checkCount(warnings, integrity, 'memories', memoriesCount, '回忆');
  _checkCount(warnings, integrity, 'photos', photoCount, '照片索引');
  _checkCount(
    warnings,
    integrity,
    'placeMergeHistory',
    placeMergeHistoryCount,
    '地点合并历史',
  );
  return warnings;
}

void _checkCount(
  List<String> warnings,
  Map<String, dynamic> integrity,
  String key,
  int actual,
  String label,
) {
  final expected = (integrity[key] as num?)?.toInt();
  if (expected != null && expected != actual) {
    warnings.add('$label 数量校验不一致：备份标记 $expected，实际解析 $actual');
  }
}
