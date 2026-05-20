import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/models/lifelog_models.dart';
import 'package:lifelog/utils/place_dedup.dart';

void main() {
  group('Place deduplication', () {
    test('detects strong duplicates by city, name, and address', () {
      const places = [
        Place(
          id: 'a',
          name: '星巴克',
          province: '浙江省',
          city: '杭州',
          address: '西湖区文三路 1 号',
          category: '咖啡厅',
        ),
        Place(
          id: 'b',
          name: '星巴克',
          province: '浙江省',
          city: '杭州',
          address: '西湖区文三路1号',
          category: '咖啡厅',
        ),
      ];

      final groups = findPlaceDuplicateGroups(places);

      expect(groups, hasLength(1));
      expect(groups.single.strength, PlaceDuplicateStrength.strong);
      expect(groups.single.placeIds, ['a', 'b']);
    });

    test('merge keeps richer place data and redirects memories', () {
      const state = LifeLogState(
        people: [],
        places: [
          Place(
            id: 'a',
            name: '星巴克',
            province: '浙江省',
            city: '杭州',
            address: '西湖区文三路1号',
            category: '咖啡厅',
            rating: 4.2,
            tags: ['咖啡'],
            favorite: true,
          ),
          Place(
            id: 'b',
            name: '星巴克',
            province: '浙江省',
            city: '杭州',
            address: '西湖区文三路1号',
            category: '咖啡厅',
            rating: 4.8,
            tags: ['工作'],
            desc: '靠窗座位多',
          ),
        ],
        memories: [
          MemoryEvent(id: 'm1', title: '聊天', date: '2026-05-20', placeId: 'b'),
        ],
      );

      final group = findPlaceDuplicateGroups(state.places).single;
      final preview = buildGroupMergePreview(group, state.places)!;
      final result = resolvePlaceMerge(state, preview);

      expect(result.removedIds, ['b']);
      expect(result.nextState.places, hasLength(1));
      expect(result.nextState.places.single.name, '星巴克');
      expect(result.nextState.places.single.rating, 4.8);
      expect(result.nextState.places.single.tags, containsAll(['咖啡', '工作']));
      expect(result.nextState.places.single.favorite, true);
      expect(result.nextState.memories.single.placeId, 'a');
    });
  });
}
