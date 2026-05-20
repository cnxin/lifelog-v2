import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/models/lifelog_models.dart';
import 'package:lifelog/models/person.dart';
import 'package:lifelog/utils/backup_preview.dart';

void main() {
  group('Backup preview', () {
    test('parses LifeLog backup counts and metadata', () {
      const backup = LifeLogBackup(
        schemaVersion: 3,
        appVersion: '0.2.0',
        exportedAt: '2026-05-20T12:00:00',
        state: LifeLogState(
          people: [Person(id: 'p1', name: '张三', relationship: '朋友')],
          places: [Place(id: 'place1', name: '咖啡馆')],
          memories: [MemoryEvent(id: 'm1', title: '聊天', date: '2026-05-20')],
        ),
        photos: ['photo-a.jpg'],
        settings: AppSettingsSnapshot(themeStyle: 'mint'),
        reminderSettings: ReminderSettingsSnapshot(contactEnabled: true),
        placeMergeHistory: [
          {'id': 'merge-1'}
        ],
      );

      final preview = parseBackupPreview(jsonEncode(backup.toJson()));

      expect(preview.sourceLabel, 'LifeLog 0.2.0');
      expect(preview.peopleCount, 1);
      expect(preview.placesCount, 1);
      expect(preview.memoriesCount, 1);
      expect(preview.photoCount, 1);
      expect(preview.placeMergeHistoryCount, 1);
      expect(preview.hasSettings, true);
      expect(preview.hasReminderSettings, true);
      expect(preview.warnings, isEmpty);
    });

    test('reports integrity mismatches', () {
      final raw = jsonEncode({
        'schemaVersion': 3,
        'state': {
          'people': <Object>[],
          'places': <Object>[],
          'memories': <Object>[],
        },
        'integrity': {
          'people': 1,
          'places': 0,
          'memories': 0,
        },
      });

      final preview = parseBackupPreview(raw);

      expect(preview.warnings.single, contains('人物 数量校验不一致'));
    });
  });
}
