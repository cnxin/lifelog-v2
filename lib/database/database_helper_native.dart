import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/lifelog_models.dart';
import 'app_database.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const appVersion = '0.3.2';
  static const _settingsKey = 'lifelog_settings';
  static const _reminderSettingsKey = 'lifelog_reminder_settings';
  static const _photosBackupKey = 'lifelog_backup_photos';
  static const _placeMergeHistoryKey = 'lifelog_place_merge_history';

  AppDatabase? _database;
  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _migrated = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _database = AppDatabase();
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    if (!_migrated && _prefs!.containsKey('lifelog_state')) {
      await _migrateFromSharedPreferences();
      _migrated = true;
    }
  }

  Future<void> _migrateFromSharedPreferences() async {
    try {
      final jsonStr = _prefs!.getString('lifelog_state');
      if (jsonStr == null || jsonStr.isEmpty) return;
      final state =
          LifeLogState.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      await _replaceState(state);
      await _prefs!.setString('lifelog_state_backup', jsonStr);
    } catch (_) {}
  }

  Future<List<Person>> getAllPeople() async {
    await _ensureInitialized();
    return await _database!.getAllPeople();
  }

  Future<void> savePerson(Person person) async {
    await _ensureInitialized();
    final existing = await _database!.getPersonById(person.id);
    if (existing != null) {
      await _database!.updatePerson(person);
    } else {
      await _database!.insertPerson(person);
    }
  }

  Future<void> deletePerson(String id) async {
    await _ensureInitialized();
    await _database!.deletePerson(id);
  }

  Future<List<Person>> searchPeople(String query) async {
    await _ensureInitialized();
    return await _database!.searchPeople(query);
  }

  Future<List<Place>> getAllPlaces() async {
    await _ensureInitialized();
    return await _database!.getAllPlaces();
  }

  Future<void> savePlace(Place place) async {
    await _ensureInitialized();
    final existing = await _database!.getPlaceById(place.id);
    if (existing != null) {
      await _database!.updatePlace(place);
    } else {
      await _database!.insertPlace(place);
    }
  }

  Future<void> deletePlace(String id) async {
    await _ensureInitialized();
    await _database!.deletePlace(id);
  }

  Future<List<Place>> searchPlaces(String query) async {
    await _ensureInitialized();
    return await _database!.searchPlaces(query);
  }

  Future<List<MemoryEvent>> getAllMemories() async {
    await _ensureInitialized();
    return await _database!.getAllMemories();
  }

  Future<void> saveMemory(MemoryEvent memory) async {
    await _ensureInitialized();
    final existing = await _database!.getMemoryById(memory.id);
    if (existing != null) {
      await _database!.updateMemory(memory);
    } else {
      await _database!.insertMemory(memory);
    }
  }

  Future<void> deleteMemory(String id) async {
    await _ensureInitialized();
    await _database!.deleteMemory(id);
  }

  Future<List<MemoryEvent>> searchMemories(String query) async {
    await _ensureInitialized();
    return await _database!.searchMemories(query);
  }

  Future<void> insertSeedData() async {
    await _ensureInitialized();
    final people = await getAllPeople();
    if (people.isNotEmpty) return;

    await _database!.insertPerson(const Person(
      id: '1',
      name: '张三',
      relationship: '朋友',
      birthday: '1990-05-15',
      preferences: [
        PreferenceGroup(category: '标签', items: ['同事', '技术'])
      ],
      favorite: true,
    ));

    await _database!.insertPlace(const Place(
      id: '1',
      name: '星巴克',
      city: '杭州',
      area: '西湖区',
      category: '咖啡厅',
      rating: 4.5,
      tags: ['咖啡', '工作'],
      favorite: true,
    ));

    await _database!.insertMemory(MemoryEvent(
      id: '1',
      title: '周末聚会',
      date: DateTime.now().toIso8601String().substring(0, 10),
      personIds: const ['1'],
      placeId: '1',
      mood: '开心',
      content: '和朋友们一起喝咖啡聊天',
      tags: const ['聚会', '咖啡'],
    ));
  }

  Future<AppSettingsSnapshot> loadSettings() async {
    await _ensureInitialized();
    final raw = _prefs!.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return const AppSettingsSnapshot();
    return AppSettingsSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettingsSnapshot settings) async {
    await _ensureInitialized();
    await _prefs!.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<ReminderSettingsSnapshot> loadReminderSettings() async {
    await _ensureInitialized();
    final raw = _prefs!.getString(_reminderSettingsKey);
    if (raw == null || raw.isEmpty) return const ReminderSettingsSnapshot();
    return ReminderSettingsSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveReminderSettings(ReminderSettingsSnapshot settings) async {
    await _ensureInitialized();
    await _prefs!
        .setString(_reminderSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<String> exportJson() async {
    await _ensureInitialized();
    final state = LifeLogState(
      people: await getAllPeople(),
      places: await getAllPlaces(),
      memories: await getAllMemories(),
    );
    final backup = LifeLogBackup(
      schemaVersion: 3,
      appVersion: appVersion,
      exportedAt: DateTime.now().toIso8601String(),
      state: state,
      photos: _decodeList(_prefs!.getString(_photosBackupKey)),
      settings: await loadSettings(),
      reminderSettings: await loadReminderSettings(),
      placeMergeHistory: _decodeList(_prefs!.getString(_placeMergeHistoryKey)),
    );
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  Future<LifeLogState> getState() async {
    await _ensureInitialized();
    return LifeLogState(
      people: await getAllPeople(),
      places: await getAllPlaces(),
      memories: await getAllMemories(),
    );
  }

  Future<void> replaceState(LifeLogState state) async {
    await _ensureInitialized();
    await _replaceState(state);
  }

  Future<void> runPlaceMergeTransaction(
      LifeLogState nextState, List<String> removedIds) async {
    await replaceState(nextState);
  }

  Future<List<PlaceMergeHistoryEntry>> loadPlaceMergeHistory() async {
    await _ensureInitialized();
    final raw = _prefs!.getString(_placeMergeHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    final value = jsonDecode(raw);
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) =>
            PlaceMergeHistoryEntry.fromJson(Map<String, dynamic>.from(entry)))
        .where((entry) => entry.id.isNotEmpty)
        .toList();
  }

  Future<void> savePlaceMergeHistoryEntry(PlaceMergeHistoryEntry entry,
      {int limit = 20}) async {
    await _ensureInitialized();
    final history = await loadPlaceMergeHistory();
    final nextHistory = [entry, ...history.where((item) => item.id != entry.id)]
        .take(limit)
        .toList();
    await _prefs!.setString(_placeMergeHistoryKey,
        jsonEncode(nextHistory.map((item) => item.toJson()).toList()));
  }

  Future<void> clearPlaceMergeHistory() async {
    await _ensureInitialized();
    await _prefs!.remove(_placeMergeHistoryKey);
  }

  Future<void> importJson(String jsonStr) async {
    await _ensureInitialized();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final backup = LifeLogBackup.fromJson(json);
    await _replaceState(backup.state);
    await saveSettings(backup.settings);
    await saveReminderSettings(backup.reminderSettings);
    await _prefs!.setString(_photosBackupKey, jsonEncode(backup.photos));
    await _prefs!
        .setString(_placeMergeHistoryKey, jsonEncode(backup.placeMergeHistory));
  }

  Future<void> resetSeedData() async {
    await _ensureInitialized();
    await _replaceState(
        const LifeLogState(people: [], places: [], memories: []));
    await insertSeedData();
  }

  Future<void> _replaceState(LifeLogState state) async {
    for (final person in await getAllPeople()) {
      await _database!.deletePerson(person.id);
    }
    for (final place in await getAllPlaces()) {
      await _database!.deletePlace(place.id);
    }
    for (final memory in await getAllMemories()) {
      await _database!.deleteMemory(memory.id);
    }
    for (final person in state.people) {
      await _database!.insertPerson(person);
    }
    for (final place in state.places) {
      await _database!.insertPlace(place);
    }
    for (final memory in state.memories) {
      await _database!.insertMemory(memory);
    }
  }

  List<dynamic> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final value = jsonDecode(raw);
    return value is List ? value : const [];
  }
}
