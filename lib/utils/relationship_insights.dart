import '../models/lifelog_models.dart';
import '../models/person.dart';

enum RelationshipContactStatus {
  active,
  dueSoon,
  needsAttention,
  noMemories,
}

class RelationshipPlaceStat {
  final Place place;
  final int count;

  const RelationshipPlaceStat({required this.place, required this.count});
}

class RelationshipInsight {
  final Person person;
  final List<MemoryEvent> memories;
  final DateTime? lastInteractionDate;
  final int? daysSinceLastInteraction;
  final int contactIntervalDays;
  final RelationshipContactStatus status;
  final List<RelationshipPlaceStat> topPlaces;

  const RelationshipInsight({
    required this.person,
    required this.memories,
    required this.lastInteractionDate,
    required this.daysSinceLastInteraction,
    required this.contactIntervalDays,
    required this.status,
    required this.topPlaces,
  });

  int get interactionCount => memories.length;

  MemoryEvent? get lastMemory => memories.isEmpty ? null : memories.first;

  bool get needsDashboardAttention =>
      status == RelationshipContactStatus.needsAttention ||
      status == RelationshipContactStatus.dueSoon ||
      status == RelationshipContactStatus.noMemories;

  String get statusLabel {
    return switch (status) {
      RelationshipContactStatus.active => '状态稳定',
      RelationshipContactStatus.dueSoon => '近期可联系',
      RelationshipContactStatus.needsAttention => '需要关注',
      RelationshipContactStatus.noMemories => '还没有共同回忆',
    };
  }

  String get lastInteractionLabel {
    final days = daysSinceLastInteraction;
    if (days == null) return '暂无互动记录';
    if (days == 0) return '今天互动过';
    if (days == 1) return '昨天互动过';
    return '$days 天前互动';
  }

  String get actionHint {
    return switch (status) {
      RelationshipContactStatus.active => '保持当前节奏',
      RelationshipContactStatus.dueSoon => '可以安排一次问候',
      RelationshipContactStatus.needsAttention => '建议尽快联系一次',
      RelationshipContactStatus.noMemories => '可以先补一条共同回忆',
    };
  }
}

RelationshipInsight buildRelationshipInsight({
  required Person person,
  required List<MemoryEvent> memories,
  required List<Place> places,
  required DateTime now,
  required int contactIntervalDays,
}) {
  final relatedMemories = memories
      .where((memory) => memory.personIds.contains(person.id))
      .toList()
    ..sort(_compareMemoriesByDateDesc);
  final lastDate = relatedMemories
      .map((memory) => parseMemoryDate(memory.date))
      .whereType<DateTime>()
      .firstOrNull;
  final daysSince = lastDate == null
      ? null
      : _daysBetween(_dateOnly(lastDate), _dateOnly(now))
          .clamp(0, 99999)
          .toInt();

  return RelationshipInsight(
    person: person,
    memories: relatedMemories,
    lastInteractionDate: lastDate,
    daysSinceLastInteraction: daysSince,
    contactIntervalDays: contactIntervalDays,
    status: _contactStatus(daysSince, contactIntervalDays),
    topPlaces: _topPlaces(relatedMemories, places),
  );
}

List<RelationshipInsight> buildRelationshipInsights({
  required List<Person> people,
  required List<MemoryEvent> memories,
  required List<Place> places,
  required DateTime now,
  required int contactIntervalDays,
}) {
  final insights = people
      .map(
        (person) => buildRelationshipInsight(
          person: person,
          memories: memories,
          places: places,
          now: now,
          contactIntervalDays: contactIntervalDays,
        ),
      )
      .toList();
  insights.sort(_compareInsightPriority);
  return insights;
}

DateTime? parseMemoryDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return _dateOnly(parsed);
}

RelationshipContactStatus _contactStatus(int? daysSince, int intervalDays) {
  if (daysSince == null) return RelationshipContactStatus.noMemories;
  final safeInterval = intervalDays <= 0 ? 30 : intervalDays;
  if (daysSince >= safeInterval) {
    return RelationshipContactStatus.needsAttention;
  }
  final dueSoonWindow = safeInterval <= 7 ? 2 : 7;
  if (daysSince >= safeInterval - dueSoonWindow) {
    return RelationshipContactStatus.dueSoon;
  }
  return RelationshipContactStatus.active;
}

List<RelationshipPlaceStat> _topPlaces(
  List<MemoryEvent> memories,
  List<Place> places,
) {
  final placeById = {for (final place in places) place.id: place};
  final counts = <String, int>{};
  for (final memory in memories) {
    if (memory.placeId.isEmpty || !placeById.containsKey(memory.placeId)) {
      continue;
    }
    counts[memory.placeId] = (counts[memory.placeId] ?? 0) + 1;
  }

  final stats = counts.entries
      .map(
        (entry) => RelationshipPlaceStat(
          place: placeById[entry.key]!,
          count: entry.value,
        ),
      )
      .toList();
  stats.sort((a, b) {
    final countCompare = b.count.compareTo(a.count);
    if (countCompare != 0) return countCompare;
    return a.place.name.compareTo(b.place.name);
  });
  return stats.take(3).toList();
}

int _compareMemoriesByDateDesc(MemoryEvent a, MemoryEvent b) {
  final aDate = parseMemoryDate(a.date);
  final bDate = parseMemoryDate(b.date);
  if (aDate != null && bDate != null) return bDate.compareTo(aDate);
  if (aDate != null) return -1;
  if (bDate != null) return 1;
  return b.date.compareTo(a.date);
}

int _compareInsightPriority(RelationshipInsight a, RelationshipInsight b) {
  final statusCompare =
      _statusWeight(b.status).compareTo(_statusWeight(a.status));
  if (statusCompare != 0) return statusCompare;

  final daysCompare = (b.daysSinceLastInteraction ?? 99999)
      .compareTo(a.daysSinceLastInteraction ?? 99999);
  if (daysCompare != 0) return daysCompare;

  if (a.person.favorite != b.person.favorite) {
    return a.person.favorite ? -1 : 1;
  }
  return a.person.name.compareTo(b.person.name);
}

int _statusWeight(RelationshipContactStatus status) {
  return switch (status) {
    RelationshipContactStatus.noMemories => 3,
    RelationshipContactStatus.needsAttention => 2,
    RelationshipContactStatus.dueSoon => 1,
    RelationshipContactStatus.active => 0,
  };
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _daysBetween(DateTime from, DateTime to) => to.difference(from).inDays;
