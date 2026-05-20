import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/models/lifelog_models.dart';
import 'package:lifelog/models/person.dart';
import 'package:lifelog/utils/relationship_insights.dart';

void main() {
  group('Relationship insights', () {
    test('marks people beyond contact interval as needing attention', () {
      const person = Person(id: 'p1', name: '张三', relationship: '朋友');
      const place = Place(id: 'cafe', name: '咖啡馆');
      const memories = [
        MemoryEvent(
          id: 'm1',
          title: '聊天',
          date: '2026-04-01',
          personIds: ['p1'],
          placeId: 'cafe',
        ),
        MemoryEvent(
          id: 'm2',
          title: '更早',
          date: '2026-03-20',
          personIds: ['p1'],
          placeId: 'cafe',
        ),
      ];

      final insight = buildRelationshipInsight(
        person: person,
        memories: memories,
        places: const [place],
        now: DateTime(2026, 5, 20),
        contactIntervalDays: 30,
      );

      expect(insight.status, RelationshipContactStatus.needsAttention);
      expect(insight.daysSinceLastInteraction, 49);
      expect(insight.interactionCount, 2);
      expect(insight.topPlaces.single.place.id, 'cafe');
      expect(insight.topPlaces.single.count, 2);
    });

    test('sorts dashboard insights by attention priority', () {
      const people = [
        Person(id: 'new', name: '新人', relationship: '朋友'),
        Person(id: 'active', name: '活跃', relationship: '同事'),
        Person(id: 'stale', name: '很久没聊', relationship: '家人'),
      ];
      const memories = [
        MemoryEvent(
            id: 'm1', title: '今天', date: '2026-05-20', personIds: ['active']),
        MemoryEvent(
            id: 'm2', title: '旧事', date: '2026-04-01', personIds: ['stale']),
      ];

      final insights = buildRelationshipInsights(
        people: people,
        memories: memories,
        places: const [],
        now: DateTime(2026, 5, 20),
        contactIntervalDays: 30,
      );

      expect(
          insights.map((item) => item.person.id), ['new', 'stale', 'active']);
      expect(insights.first.status, RelationshipContactStatus.noMemories);
      expect(insights[1].status, RelationshipContactStatus.needsAttention);
    });
  });
}
