import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/lifelog_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const appVersion = '0.3.2';
  static const _stateKey = 'lifelog_web_state';
  static const _settingsKey = 'lifelog_settings';
  static const _reminderSettingsKey = 'lifelog_reminder_settings';
  static const _photosBackupKey = 'lifelog_backup_photos';
  static const _placeMergeHistoryKey = 'lifelog_place_merge_history';

  SharedPreferences? _prefs;
  LifeLogState? _state;

  Future<void> _ensureInitialized() async {
    if (_state != null) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_stateKey);
    if (raw == null || raw.isEmpty) {
      _state = const LifeLogState(people: [], places: [], memories: []);
      await insertSeedData();
    } else {
      _state = LifeLogState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  Future<void> _save() async {
    await _prefs!.setString(_stateKey, jsonEncode(_state!.toJson()));
  }

  Future<List<Person>> getAllPeople() async {
    await _ensureInitialized();
    return List<Person>.from(_state!.people);
  }

  Future<void> savePerson(Person person) async {
    await _ensureInitialized();
    final people = List<Person>.from(_state!.people);
    final index = people.indexWhere((p) => p.id == person.id);
    if (index >= 0) {
      people[index] = person;
    } else {
      people.add(person);
    }
    _state = LifeLogState(
        people: people, places: _state!.places, memories: _state!.memories);
    await _save();
  }

  Future<void> deletePerson(String id) async {
    await _ensureInitialized();
    _state = LifeLogState(
      people: _state!.people.where((p) => p.id != id).toList(),
      places: _state!.places,
      memories: _state!.memories,
    );
    await _save();
  }

  Future<List<Person>> searchPeople(String query) async {
    await _ensureInitialized();
    return _state!.people
        .where((p) =>
            p.name.contains(query) ||
            p.relationship.contains(query) ||
            p.notes.contains(query))
        .toList();
  }

  Future<List<Place>> getAllPlaces() async {
    await _ensureInitialized();
    return List<Place>.from(_state!.places);
  }

  Future<void> savePlace(Place place) async {
    await _ensureInitialized();
    final places = List<Place>.from(_state!.places);
    final index = places.indexWhere((p) => p.id == place.id);
    if (index >= 0) {
      places[index] = place;
    } else {
      places.add(place);
    }
    _state = LifeLogState(
        people: _state!.people, places: places, memories: _state!.memories);
    await _save();
  }

  Future<void> deletePlace(String id) async {
    await _ensureInitialized();
    _state = LifeLogState(
      people: _state!.people,
      places: _state!.places.where((p) => p.id != id).toList(),
      memories: _state!.memories,
    );
    await _save();
  }

  Future<List<Place>> searchPlaces(String query) async {
    await _ensureInitialized();
    return _state!.places
        .where((p) =>
            p.name.contains(query) ||
            p.category.contains(query) ||
            p.desc.contains(query))
        .toList();
  }

  Future<List<MemoryEvent>> getAllMemories() async {
    await _ensureInitialized();
    final memories = List<MemoryEvent>.from(_state!.memories);
    memories.sort((a, b) => b.date.compareTo(a.date));
    return memories;
  }

  Future<void> saveMemory(MemoryEvent memory) async {
    await _ensureInitialized();
    final memories = List<MemoryEvent>.from(_state!.memories);
    final index = memories.indexWhere((m) => m.id == memory.id);
    if (index >= 0) {
      memories[index] = memory;
    } else {
      memories.add(memory);
    }
    _state = LifeLogState(
        people: _state!.people, places: _state!.places, memories: memories);
    await _save();
  }

  Future<void> deleteMemory(String id) async {
    await _ensureInitialized();
    _state = LifeLogState(
      people: _state!.people,
      places: _state!.places,
      memories: _state!.memories.where((m) => m.id != id).toList(),
    );
    await _save();
  }

  Future<List<MemoryEvent>> searchMemories(String query) async {
    await _ensureInitialized();
    return _state!.memories
        .where((m) => m.title.contains(query) || m.content.contains(query))
        .toList();
  }

  Future<void> insertSeedData() async {
    _state ??= const LifeLogState(people: [], places: [], memories: []);
    if (_state!.people.isNotEmpty) return;
    _state = LifeLogState(
      people: const [
        Person(
          id: '1',
          name: '张三',
          relationship: '朋友',
          birthday: '1990-05-15',
          preferences: [
            PreferenceGroup(category: '标签', items: ['同事', '技术'])
          ],
          favorite: true,
        ),
      ],
      places: const [
        Place(
          id: '1',
          name: '星巴克',
          city: '杭州',
          area: '西湖区',
          category: '咖啡厅',
          rating: 4.5,
          tags: ['咖啡', '工作'],
          favorite: true,
        ),
      ],
      memories: [
        MemoryEvent(
          id: '1',
          title: '周末聚会',
          date: DateTime.now().toIso8601String().substring(0, 10),
          personIds: const ['1'],
          placeId: '1',
          mood: '开心',
          content: '和朋友们一起喝咖啡聊天',
          tags: const ['聚会', '咖啡'],
        ),
      ],
    );
    await _save();
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
    final backup = LifeLogBackup(
      schemaVersion: 3,
      appVersion: appVersion,
      exportedAt: DateTime.now().toIso8601String(),
      state: _state!,
      photos: _decodeList(_prefs!.getString(_photosBackupKey)),
      settings: await loadSettings(),
      reminderSettings: await loadReminderSettings(),
      placeMergeHistory: _decodeList(_prefs!.getString(_placeMergeHistoryKey)),
    );
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  Future<LifeLogState> getState() async {
    await _ensureInitialized();
    return _state!;
  }

  Future<void> replaceState(LifeLogState state) async {
    await _ensureInitialized();
    _state = state;
    await _save();
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
    final backup =
        LifeLogBackup.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    _state = backup.state;
    await _save();
    await saveSettings(backup.settings);
    await saveReminderSettings(backup.reminderSettings);
    await _prefs!.setString(_photosBackupKey, jsonEncode(backup.photos));
    await _prefs!
        .setString(_placeMergeHistoryKey, jsonEncode(backup.placeMergeHistory));
  }

  Future<void> resetSeedData() async {
    await _ensureInitialized();
    _state = const LifeLogState(people: [], places: [], memories: []);
    await insertSeedData();
  }

  List<dynamic> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final value = jsonDecode(raw);
    return value is List ? value : const [];
  }
}
