import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/person.dart';
import '../models/lifelog_models.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../utils/place_dedup.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final themeStyleProvider =
    StateProvider<AppThemeStyle>((ref) => AppThemeStyle.classic);
final themeModeProvider = StateProvider<bool>((ref) => false);
final dynamicColorEnabledProvider = StateProvider<bool>((ref) => false);
final dynamicLightColorSchemeProvider =
    StateProvider<ColorScheme?>((ref) => null);
final dynamicDarkColorSchemeProvider =
    StateProvider<ColorScheme?>((ref) => null);
final appColorsProvider = Provider<AppColors>((ref) {
  final style = ref.watch(themeStyleProvider);
  final isDark = ref.watch(themeModeProvider);
  final base = AppColors.fromStyle(style, isDark: isDark);
  if (!ref.watch(dynamicColorEnabledProvider)) return base;

  final dynamicScheme = isDark
      ? ref.watch(dynamicDarkColorSchemeProvider)
      : ref.watch(dynamicLightColorSchemeProvider);
  if (dynamicScheme == null) return base;

  final seededScheme = ColorScheme.fromSeed(
    seedColor: dynamicScheme.primary,
    brightness: isDark ? Brightness.dark : Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  return base.harmonizedWith(seededScheme, isDark: isDark);
});
final notificationsEnabledProvider = StateProvider<bool>((ref) => false);
final contactRemindersEnabledProvider = StateProvider<bool>((ref) => false);
final memoryReviewRemindersEnabledProvider =
    StateProvider<bool>((ref) => false);
final contactIntervalDaysProvider = StateProvider<int>((ref) => 30);

// 提醒时间配置（小时:分钟）
final birthdayReminderTimeProvider = StateProvider<String>((ref) => '09:00');
final contactReminderTimeProvider = StateProvider<String>((ref) => '10:00');
final memoryReviewReminderTimeProvider =
    StateProvider<String>((ref) => '09:00');

// 自定义关系和心情选项
final customRelationshipsProvider =
    StateProvider<List<String>>((ref) => ['朋友', '家人', '同事', '同学', '恋人', '其他']);
final customMoodsProvider =
    StateProvider<List<String>>((ref) => ['日常', '开心', '轻松', '愉快', '感动', '难忘']);

final searchQueryProvider = StateProvider<String>((ref) => '');
final placeSearchQueryProvider = StateProvider<String>((ref) => '');
final memorySearchQueryProvider = StateProvider<String>((ref) => '');

AppThemeStyle themeStyleFromName(String value) {
  return AppThemeStyle.values.firstWhere(
    (style) =>
        style.name == value || style.label.toLowerCase() == value.toLowerCase(),
    orElse: () => AppThemeStyle.classic,
  );
}

Future<void> loadPersistedPreferences(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final settings = await db.loadSettings();
  final reminders = await db.loadReminderSettings();
  ref.read(themeStyleProvider.notifier).state =
      themeStyleFromName(settings.themeStyle);
  ref.read(themeModeProvider.notifier).state = settings.themeMode;
  ref.read(dynamicColorEnabledProvider.notifier).state =
      settings.dynamicColorEnabled;
  ref.read(customRelationshipsProvider.notifier).state =
      settings.customRelationships;
  ref.read(customMoodsProvider.notifier).state = settings.customMoods;
  ref.read(notificationsEnabledProvider.notifier).state =
      reminders.birthdayEnabled;
  ref.read(contactRemindersEnabledProvider.notifier).state =
      reminders.contactEnabled;
  ref.read(memoryReviewRemindersEnabledProvider.notifier).state =
      reminders.memoryReviewEnabled;
  ref.read(birthdayReminderTimeProvider.notifier).state =
      reminders.birthdayTime;
  ref.read(contactReminderTimeProvider.notifier).state = reminders.contactTime;
  ref.read(memoryReviewReminderTimeProvider.notifier).state =
      reminders.memoryReviewTime;
  ref.read(contactIntervalDaysProvider.notifier).state =
      reminders.contactIntervalDays;
}

Future<void> saveCurrentPreferences(WidgetRef ref) async {
  await ref.read(databaseProvider).saveSettings(AppSettingsSnapshot(
        themeStyle: ref.read(themeStyleProvider).name,
        themeMode: ref.read(themeModeProvider),
        dynamicColorEnabled: ref.read(dynamicColorEnabledProvider),
        customRelationships: ref.read(customRelationshipsProvider),
        customMoods: ref.read(customMoodsProvider),
      ));
  await ref
      .read(databaseProvider)
      .saveReminderSettings(ReminderSettingsSnapshot(
        birthdayEnabled: ref.read(notificationsEnabledProvider),
        contactEnabled: ref.read(contactRemindersEnabledProvider),
        memoryReviewEnabled: ref.read(memoryReviewRemindersEnabledProvider),
        birthdayTime: ref.read(birthdayReminderTimeProvider),
        contactTime: ref.read(contactReminderTimeProvider),
        memoryReviewTime: ref.read(memoryReviewReminderTimeProvider),
        contactIntervalDays: ref.read(contactIntervalDaysProvider),
      ));
}

final peopleProvider =
    AsyncNotifierProvider<PeopleNotifier, List<Person>>(PeopleNotifier.new);
final placesProvider =
    AsyncNotifierProvider<PlacesNotifier, List<Place>>(PlacesNotifier.new);
final memoriesProvider =
    AsyncNotifierProvider<MemoriesNotifier, List<MemoryEvent>>(
        MemoriesNotifier.new);
final placeMergeHistoryProvider = AsyncNotifierProvider<
    PlaceMergeHistoryNotifier,
    List<PlaceMergeHistoryEntry>>(PlaceMergeHistoryNotifier.new);
final duplicatePlaceGroupsProvider = Provider<List<PlaceDuplicateGroup>>((ref) {
  final places = ref.watch(placesProvider).valueOrNull ?? const <Place>[];
  return findPlaceDuplicateGroups(places);
});

class PeopleNotifier extends AsyncNotifier<List<Person>> {
  DatabaseHelper get _db => ref.read(databaseProvider);

  @override
  Future<List<Person>> build() async {
    await _db.insertSeedData();
    return _db.getAllPeople();
  }

  Future<void> addPerson(Person person) async {
    await _db.savePerson(person);
    state = AsyncData(await _db.getAllPeople());
    ref.invalidate(memoriesProvider);
    await _updateNotifications();
  }

  Future<void> updatePerson(Person person) async {
    await _db.savePerson(person);
    state = AsyncData(await _db.getAllPeople());
    ref.invalidate(memoriesProvider);
    await _updateNotifications();
  }

  Future<void> deletePerson(String id) async {
    await _db.deletePerson(id);
    state = AsyncData(await _db.getAllPeople());
    ref.invalidate(memoriesProvider);
    await _updateNotifications();
  }

  Future<void> _updateNotifications() async {
    if (ref.read(notificationsEnabledProvider)) {
      final people = state.valueOrNull ?? [];
      final reminderTime = ref.read(birthdayReminderTimeProvider);
      await ref
          .read(notificationServiceProvider)
          .schedulePersonReminders(people, reminderTime: reminderTime);
    }
    if (ref.read(contactRemindersEnabledProvider)) {
      final people = state.valueOrNull ?? [];
      final memories = ref.read(memoriesProvider).valueOrNull ?? [];
      final intervalDays = ref.read(contactIntervalDaysProvider);
      final reminderTime = ref.read(contactReminderTimeProvider);
      await ref.read(notificationServiceProvider).scheduleContactReminders(
          people, memories, intervalDays,
          reminderTime: reminderTime);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull?.firstWhere((p) => p.id == id);
    if (current == null) return;
    await _db.savePerson(current.copyWith(favorite: !current.favorite));
    state = AsyncData(await _db.getAllPeople());
  }

  Future<void> search(String query) async {
    state = AsyncData(query.isEmpty
        ? await _db.getAllPeople()
        : await _db.searchPeople(query));
  }
}

class PlacesNotifier extends AsyncNotifier<List<Place>> {
  DatabaseHelper get _db => ref.read(databaseProvider);

  @override
  Future<List<Place>> build() async {
    await _db.insertSeedData();
    return _db.getAllPlaces();
  }

  Future<void> savePlace(Place place) async {
    await _db.savePlace(place);
    state = AsyncData(await _db.getAllPlaces());
    ref.invalidate(memoriesProvider);
  }

  Future<void> deletePlace(String id) async {
    await _db.deletePlace(id);
    state = AsyncData(await _db.getAllPlaces());
    ref.invalidate(memoriesProvider);
  }

  Future<void> toggleFavorite(String id) async {
    final current = state.valueOrNull?.firstWhere((p) => p.id == id);
    if (current == null) return;
    await _db.savePlace(current.copyWith(favorite: !current.favorite));
    state = AsyncData(await _db.getAllPlaces());
  }

  Future<void> search(String query) async {
    state = AsyncData(query.isEmpty
        ? await _db.getAllPlaces()
        : await _db.searchPlaces(query));
  }

  Future<String?> mergePlacePreview(PlaceMergePreview preview) async {
    final previousState = await _db.getState();
    final result = resolvePlaceMerge(previousState, preview);
    final historyEntry = PlaceMergeHistoryEntry(
      id: 'pm-${DateTime.now().millisecondsSinceEpoch}',
      happenedAt: DateTime.now().toIso8601String(),
      reason: preview.reason,
      removedIds: result.removedIds,
      placeIds: [
        preview.canonical.id,
        ...preview.sources.map((source) => source.id)
      ]..sort(),
      snapshot: previousState,
    );

    await _db.runPlaceMergeTransaction(result.nextState, result.removedIds);
    await _db.savePlaceMergeHistoryEntry(historyEntry);
    state = AsyncData(await _db.getAllPlaces());
    ref.invalidate(memoriesProvider);
    ref.invalidate(placeMergeHistoryProvider);
    return preview.canonical.id;
  }

  Future<void> mergeDuplicatePlaces(PlaceDuplicateGroup group) async {
    final places = state.valueOrNull ?? await _db.getAllPlaces();
    final preview = buildGroupMergePreview(group, places);
    if (preview == null) return;
    await mergePlacePreview(preview);
  }

  Future<int> mergeAllStrongDuplicatePlaces() async {
    var currentState = await _db.getState();
    var mergedCount = 0;
    var mergedGroupCount = 0;
    final removedIds = <String>{};
    final touchedPlaceIds = <String>{};

    while (true) {
      final groups = findPlaceDuplicateGroups(currentState.places)
          .where((group) => group.strength == PlaceDuplicateStrength.strong)
          .toList();
      if (groups.isEmpty) break;

      final preview = buildGroupMergePreview(groups.first, currentState.places);
      if (preview == null) break;
      final result = resolvePlaceMerge(currentState, preview);
      if (result.removedIds.isEmpty) break;

      currentState = result.nextState;
      mergedCount += result.removedIds.length;
      mergedGroupCount += 1;
      removedIds.addAll(result.removedIds);
      touchedPlaceIds.add(preview.canonical.id);
      touchedPlaceIds.addAll(preview.sources.map((source) => source.id));
    }

    if (mergedCount == 0) return 0;

    final previousState = await _db.getState();
    final historyEntry = PlaceMergeHistoryEntry(
      id: 'pm-${DateTime.now().millisecondsSinceEpoch}',
      happenedAt: DateTime.now().toIso8601String(),
      reason: '批量合并强重复地点（$mergedGroupCount组）',
      removedIds: removedIds.toList()..sort(),
      placeIds: touchedPlaceIds.toList()..sort(),
      snapshot: previousState,
    );

    await _db.runPlaceMergeTransaction(currentState, removedIds.toList());
    await _db.savePlaceMergeHistoryEntry(historyEntry);
    state = AsyncData(await _db.getAllPlaces());
    ref.invalidate(memoriesProvider);
    ref.invalidate(placeMergeHistoryProvider);
    return mergedCount;
  }

  Future<bool> undoLatestPlaceMerge() async {
    final history = await _db.loadPlaceMergeHistory();
    if (history.isEmpty) return false;

    final latest = history.first;
    await _db.replaceState(latest.snapshot);
    await _db.clearPlaceMergeHistory();
    for (final entry in history.skip(1).toList().reversed) {
      await _db.savePlaceMergeHistoryEntry(entry);
    }

    state = AsyncData(await _db.getAllPlaces());
    ref.invalidate(memoriesProvider);
    ref.invalidate(placeMergeHistoryProvider);
    return true;
  }
}

class PlaceMergeHistoryNotifier
    extends AsyncNotifier<List<PlaceMergeHistoryEntry>> {
  DatabaseHelper get _db => ref.read(databaseProvider);

  @override
  Future<List<PlaceMergeHistoryEntry>> build() async {
    return _db.loadPlaceMergeHistory();
  }
}

class MemoriesNotifier extends AsyncNotifier<List<MemoryEvent>> {
  DatabaseHelper get _db => ref.read(databaseProvider);

  @override
  Future<List<MemoryEvent>> build() async {
    await _db.insertSeedData();
    return _db.getAllMemories();
  }

  Future<void> saveMemory(MemoryEvent memory) async {
    await _db.saveMemory(memory);
    state = AsyncData(await _db.getAllMemories());
    await _updateNotifications();
  }

  Future<void> deleteMemory(String id) async {
    await _db.deleteMemory(id);
    state = AsyncData(await _db.getAllMemories());
    await _updateNotifications();
  }

  Future<void> search(String query) async {
    state = AsyncData(query.isEmpty
        ? await _db.getAllMemories()
        : await _db.searchMemories(query));
  }

  Future<void> _updateNotifications() async {
    final memories = state.valueOrNull ?? [];

    if (ref.read(contactRemindersEnabledProvider)) {
      final people = ref.read(peopleProvider).valueOrNull ?? [];
      final intervalDays = ref.read(contactIntervalDaysProvider);
      final reminderTime = ref.read(contactReminderTimeProvider);
      await ref.read(notificationServiceProvider).scheduleContactReminders(
          people, memories, intervalDays,
          reminderTime: reminderTime);
    }

    if (ref.read(memoryReviewRemindersEnabledProvider)) {
      final reminderTime = ref.read(memoryReviewReminderTimeProvider);
      await ref
          .read(notificationServiceProvider)
          .scheduleMemoryReviewReminders(memories, reminderTime: reminderTime);
    }
  }
}
