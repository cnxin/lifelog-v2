import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/models/person.dart';
import 'package:lifelog/models/lifelog_models.dart';

void main() {
  group('Person Model Tests', () {
    test('Person creation with all fields', () {
      const person = Person(
        id: '1',
        name: '张三',
        nickname: '老张',
        relationship: '朋友',
        birthday: '1990-05-15',
        anniversaries: [Anniversary(title: '认识', date: '2020-01-01')],
        preferences: [PreferenceGroup(category: '标签', items: ['同事', '技术'])],
        dislikes: [PreferenceGroup(category: '忌口', items: ['香菜'])],
        notes: '测试备注',
        favorite: true,
      );

      expect(person.name, '张三');
      expect(person.relationship, '朋友');
      expect(person.preferences.first.items.length, 2);
      expect(person.favorite, true);
    });

    test('Person toJson and fromJson', () {
      const person = Person(
        id: '1',
        name: '李四',
        relationship: '家人',
        preferences: [PreferenceGroup(category: '标签', items: ['家人'])],
        favorite: false,
      );

      final json = person.toJson();
      final restored = Person.fromJson(json);

      expect(restored.id, person.id);
      expect(restored.name, person.name);
      expect(restored.relationship, person.relationship);
      expect(restored.preferences.first.items, person.preferences.first.items);
      expect(restored.favorite, person.favorite);
    });

    test('Person copyWith', () {
      const person = Person(id: '1', name: '王五', relationship: '同事');
      final updated = person.copyWith(name: '王五五', favorite: true);

      expect(updated.id, '1');
      expect(updated.name, '王五五');
      expect(updated.relationship, '同事');
      expect(updated.favorite, true);
    });
  });

  group('Place Model Tests', () {
    test('Place creation with external links', () {
      const place = Place(
        id: '1',
        name: '星巴克',
        city: '杭州',
        category: '咖啡厅',
        rating: 4.5,
        platformLinks: [
          PlaceExternalLink(label: '大众点评', url: 'https://example.com', platform: 'dianping'),
        ],
        tags: ['咖啡', '工作'],
        favorite: true,
      );

      expect(place.name, '星巴克');
      expect(place.rating, 4.5);
      expect(place.platformLinks.length, 1);
      expect(place.platformLinks[0].label, '大众点评');
    });

    test('Place toJson and fromJson', () {
      const place = Place(
        id: '1',
        name: '测试地点',
        city: '杭州',
        category: '餐厅',
        rating: 4.0,
        platformLinks: [
          PlaceExternalLink(label: '链接', url: 'https://test.com', platform: 'custom'),
        ],
      );

      final json = place.toJson();
      final restored = Place.fromJson(json);

      expect(restored.id, place.id);
      expect(restored.name, place.name);
      expect(restored.rating, place.rating);
      expect(restored.platformLinks.length, 1);
      expect(restored.platformLinks[0].url, 'https://test.com');
    });
  });

  group('MemoryEvent Model Tests', () {
    test('MemoryEvent creation', () {
      const memory = MemoryEvent(
        id: '1',
        title: '周末聚会',
        date: '2026-05-11',
        personIds: ['p1', 'p2'],
        placeId: 'place1',
        mood: '开心',
        content: '和朋友们一起喝咖啡',
        tags: ['聚会', '咖啡'],
        photos: ['photo1.jpg'],
      );

      expect(memory.title, '周末聚会');
      expect(memory.personIds.length, 2);
      expect(memory.mood, '开心');
    });

    test('MemoryEvent toJson and fromJson', () {
      const memory = MemoryEvent(
        id: '1',
        title: '测试记忆',
        date: '2026-05-11',
        personIds: ['p1'],
        mood: '愉快',
      );

      final json = memory.toJson();
      final restored = MemoryEvent.fromJson(json);

      expect(restored.id, memory.id);
      expect(restored.title, memory.title);
      expect(restored.date, memory.date);
      expect(restored.personIds, memory.personIds);
      expect(restored.mood, memory.mood);
    });

    test('MemoryEvent copyWith', () {
      const memory = MemoryEvent(
        id: '1',
        title: '原标题',
        date: '2026-05-11',
        mood: '日常',
      );

      final updated = memory.copyWith(title: '新标题', mood: '开心');

      expect(updated.id, '1');
      expect(updated.title, '新标题');
      expect(updated.date, '2026-05-11');
      expect(updated.mood, '开心');
    });
  });

  group('LifeLogState Tests', () {
    test('LifeLogState toJson and fromJson', () {
      const state = LifeLogState(
        people: [Person(id: '1', name: '张三', relationship: '朋友')],
        places: [Place(id: '1', name: '星巴克', city: '杭州', category: '咖啡厅', rating: 4.5)],
        memories: [MemoryEvent(id: '1', title: '聚会', date: '2026-05-11', mood: '开心')],
      );

      final json = state.toJson();
      final restored = LifeLogState.fromJson(json);

      expect(restored.people.length, 1);
      expect(restored.places.length, 1);
      expect(restored.memories.length, 1);
      expect(restored.people[0].name, '张三');
      expect(restored.places[0].name, '星巴克');
      expect(restored.memories[0].title, '聚会');
    });
  });
}
