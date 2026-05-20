import '../models/lifelog_models.dart';

enum PlaceDuplicateStrength { strong, weak }

class PlaceDuplicateGroup {
  final String signature;
  final List<String> placeIds;
  final String canonicalId;
  final String reason;
  final String label;
  final PlaceDuplicateStrength strength;

  const PlaceDuplicateGroup({
    required this.signature,
    required this.placeIds,
    required this.canonicalId,
    required this.reason,
    required this.label,
    required this.strength,
  });
}

class PlaceMergePreview {
  final String signature;
  final String reason;
  final PlaceDuplicateStrength strength;
  final Place canonical;
  final List<Place> sources;
  final List<String> details;
  final Place merged;

  const PlaceMergePreview({
    required this.signature,
    required this.reason,
    required this.strength,
    required this.canonical,
    required this.sources,
    required this.details,
    required this.merged,
  });
}

class PlaceMergeResult {
  final LifeLogState nextState;
  final List<String> removedIds;

  const PlaceMergeResult({required this.nextState, required this.removedIds});
}

class _SignatureRule {
  final String signature;
  final String reason;
  final PlaceDuplicateStrength strength;

  const _SignatureRule({
    required this.signature,
    required this.reason,
    required this.strength,
  });
}

class _PlaceCandidate {
  final String signature;
  final Place place;
  final String reason;
  final PlaceDuplicateStrength strength;

  const _PlaceCandidate({
    required this.signature,
    required this.place,
    required this.reason,
    required this.strength,
  });
}

PlaceMergePreview? inspectPlaceDuplicate(Place place, List<Place> places) {
  final targetRules = _buildPlaceSignatures(place);
  final candidates = places
      .where((item) => item.id != place.id)
      .map((item) => _matchPlaceBySignatures(item, targetRules))
      .whereType<_PlaceCandidate>()
      .toList()
    ..sort(_compareCandidates);

  if (candidates.isEmpty) return null;

  final best = candidates.first;
  return _buildPlaceMergePreview(
    best.place,
    [place],
    best.signature,
    best.reason,
    best.strength,
    _buildPreviewDetails(best.place, place, best.reason),
  );
}

List<PlaceDuplicateGroup> findPlaceDuplicateGroups(List<Place> places) {
  final buckets = <String, _Bucket>{};

  for (final place in places) {
    for (final signature in _buildPlaceSignatures(place)) {
      final bucket = buckets.putIfAbsent(
        signature.signature,
        () => _Bucket(reason: signature.reason, strength: signature.strength),
      );
      bucket.places.add(place);
      if (signature.strength == PlaceDuplicateStrength.strong) {
        bucket.strength = PlaceDuplicateStrength.strong;
      }
    }
  }

  final groups = <String, PlaceDuplicateGroup>{};
  for (final entry in buckets.entries) {
    final uniquePlaces = _uniqueById(entry.value.places);
    if (uniquePlaces.length < 2) continue;

    final canonical = _chooseCanonicalPlace(uniquePlaces);
    final placeIds = uniquePlaces.map((item) => item.id).toList()..sort();
    final groupKey = placeIds.join('|');
    final nextGroup = PlaceDuplicateGroup(
      signature: entry.key,
      placeIds: placeIds,
      canonicalId: canonical.id,
      reason: entry.value.reason,
      label: _buildDuplicateLabel(canonical),
      strength: entry.value.strength,
    );
    final current = groups[groupKey];
    if (current == null || _shouldReplaceGroup(current, nextGroup)) {
      groups[groupKey] = nextGroup;
    }
  }

  return groups.values.toList()..sort(_compareGroups);
}

PlaceMergePreview? buildGroupMergePreview(
    PlaceDuplicateGroup group, List<Place> places) {
  final members = _uniqueById(
      places.where((place) => group.placeIds.contains(place.id)).toList());
  if (members.length < 2) return null;

  final canonical = members.firstWhere(
    (place) => place.id == group.canonicalId,
    orElse: () => _chooseCanonicalPlace(members),
  );
  final sources = members.where((place) => place.id != canonical.id).toList();
  return _buildPlaceMergePreview(
    canonical,
    sources,
    group.signature,
    group.reason,
    group.strength,
    _buildPreviewDetails(canonical, sources.first, group.reason),
  );
}

Place mergePlaceRecords(Place target, Place source) {
  final tags = _uniqueStrings([...target.tags, ...source.tags]);
  final photos = _uniqueStrings([...target.photos, ...source.photos]);
  final platformLinks =
      _mergePlacePlatformLinks(target.platformLinks, source.platformLinks);

  return target.copyWith(
    name: _pickLongerName(target.name, source.name),
    country: target.country.isNotEmpty ? target.country : source.country,
    province: target.province.isNotEmpty ? target.province : source.province,
    city: target.city.isNotEmpty ? target.city : source.city,
    area: _pickLongerName(target.area, source.area),
    mall: _pickLongerName(target.mall, source.mall),
    storeName: _pickLongerName(target.storeName, source.storeName),
    category: target.category != '其他' && target.category.isNotEmpty
        ? target.category
        : source.category,
    rating: target.rating >= source.rating ? target.rating : source.rating,
    address: _pickLongerName(target.address, source.address),
    latitude: target.latitude ?? source.latitude,
    longitude: target.longitude ?? source.longitude,
    mapUrl: target.mapUrl.isNotEmpty ? target.mapUrl : source.mapUrl,
    sourceUrl:
        target.sourceUrl.isNotEmpty ? target.sourceUrl : source.sourceUrl,
    platformLinks: platformLinks,
    photos: photos,
    desc: _pickLongerName(target.desc, source.desc),
    tags: tags,
    favorite: target.favorite || source.favorite,
  );
}

PlaceMergeResult resolvePlaceMerge(
    LifeLogState state, PlaceMergePreview preview) {
  final targetId = preview.canonical.id;
  final sourceIds = preview.sources.map((source) => source.id).toSet();
  final nextPlaces = <Place>[];

  for (final place in state.places) {
    if (place.id == targetId) {
      nextPlaces.add(preview.merged);
    } else if (!sourceIds.contains(place.id)) {
      nextPlaces.add(place);
    }
  }

  final nextMemories = state.memories
      .map((memory) => sourceIds.contains(memory.placeId)
          ? memory.copyWith(placeId: targetId)
          : memory)
      .toList();

  return PlaceMergeResult(
    nextState: LifeLogState(
        people: state.people, places: nextPlaces, memories: nextMemories),
    removedIds: sourceIds.toList()..sort(),
  );
}

PlaceMergePreview _buildPlaceMergePreview(
  Place canonical,
  List<Place> sources,
  String signature,
  String reason,
  PlaceDuplicateStrength strength,
  List<String> details,
) {
  final merged = sources.fold<Place>(canonical, mergePlaceRecords);
  return PlaceMergePreview(
    signature: signature,
    reason: reason,
    strength: strength,
    canonical: canonical,
    sources: sources,
    details: details,
    merged: merged,
  );
}

List<_SignatureRule> _buildPlaceSignatures(Place place) {
  final country =
      _normalizeToken(place.country.isNotEmpty ? place.country : '中国');
  final province = _normalizeToken(place.province);
  final city = _normalizeToken(place.city);
  final area = _normalizeToken(place.area);
  final mall = _normalizeToken(place.mall);
  final name = _normalizeToken(place.name);
  final storeName = _normalizeToken(place.storeName);
  final address = _normalizeAddress(place.address);
  final category = _normalizeToken(place.category);
  final geo = _buildGeoBucket(place);
  final signatures = <_SignatureRule>[];

  _pushSignature(signatures, [country, province, city, mall, name, storeName],
      '同城同商场同店名', PlaceDuplicateStrength.strong);
  _pushSignature(
      signatures,
      [country, province, city, name, storeName, address],
      '同城同店名同地址',
      PlaceDuplicateStrength.strong);
  _pushSignature(signatures, [country, province, city, name, address],
      '同城同地点名同地址', PlaceDuplicateStrength.strong);

  if (geo.isNotEmpty) {
    _pushSignature(signatures, [country, province, city, geo, name], '同坐标附近同名称',
        PlaceDuplicateStrength.strong);
  }

  if (mall.isNotEmpty && name.isNotEmpty && storeName.isEmpty) {
    _pushSignature(signatures, [country, province, city, mall, name, category],
        '同城同商场同主名称', PlaceDuplicateStrength.weak);
  }

  if (name.isNotEmpty &&
      address.isEmpty &&
      area.isNotEmpty &&
      mall.isNotEmpty) {
    _pushSignature(signatures, [country, province, city, area, mall, name],
        '同区域同商场同名称', PlaceDuplicateStrength.weak);
  }

  if (name.isNotEmpty && city.isNotEmpty && address.isEmpty) {
    _pushSignature(signatures, [country, province, city, name], '同城同名称但地址缺失',
        PlaceDuplicateStrength.weak);
  }

  if (mall.isNotEmpty && category.isNotEmpty && _isWeakStoreName(storeName)) {
    _pushSignature(signatures, [country, province, city, mall, category, name],
        '同商场同分类名称接近', PlaceDuplicateStrength.weak);
  }

  return _uniqueRules(signatures);
}

void _pushSignature(
  List<_SignatureRule> signatures,
  List<String> parts,
  String reason,
  PlaceDuplicateStrength strength,
) {
  final normalized = parts.where((part) => part.isNotEmpty).toList();
  if (normalized.length < 4) return;
  signatures.add(_SignatureRule(
      signature: normalized.join('|'), reason: reason, strength: strength));
}

List<_SignatureRule> _uniqueRules(List<_SignatureRule> signatures) {
  final bucket = <String, _SignatureRule>{};
  for (final item in signatures) {
    final current = bucket[item.signature];
    if (current == null ||
        (current.strength == PlaceDuplicateStrength.weak &&
            item.strength == PlaceDuplicateStrength.strong)) {
      bucket[item.signature] = item;
    }
  }
  return bucket.values.toList();
}

_PlaceCandidate? _matchPlaceBySignatures(
    Place place, List<_SignatureRule> targetSignatures) {
  final candidateSignatures = {
    for (final item in _buildPlaceSignatures(place)) item.signature: item,
  };
  _SignatureRule? matched;
  for (final item in targetSignatures) {
    if (candidateSignatures.containsKey(item.signature)) {
      matched = item;
      break;
    }
  }
  if (matched == null) return null;

  final candidate = candidateSignatures[matched.signature];
  final strength = matched.strength == PlaceDuplicateStrength.strong ||
          candidate?.strength == PlaceDuplicateStrength.strong
      ? PlaceDuplicateStrength.strong
      : PlaceDuplicateStrength.weak;

  return _PlaceCandidate(
    signature: matched.signature,
    place: place,
    reason: matched.reason,
    strength: strength,
  );
}

Place _chooseCanonicalPlace(List<Place> places) {
  final sorted = [...places]
    ..sort((a, b) => _scorePlaceCandidate(b) - _scorePlaceCandidate(a));
  return sorted.first;
}

int _compareCandidates(_PlaceCandidate a, _PlaceCandidate b) {
  if (a.strength != b.strength) {
    return a.strength == PlaceDuplicateStrength.strong ? -1 : 1;
  }
  return _scorePlaceCandidate(b.place) - _scorePlaceCandidate(a.place);
}

int _compareGroups(PlaceDuplicateGroup a, PlaceDuplicateGroup b) {
  if (a.strength != b.strength) {
    return a.strength == PlaceDuplicateStrength.strong ? -1 : 1;
  }
  return b.placeIds.length - a.placeIds.length == 0
      ? a.label.compareTo(b.label)
      : b.placeIds.length - a.placeIds.length;
}

bool _shouldReplaceGroup(
    PlaceDuplicateGroup current, PlaceDuplicateGroup next) {
  if (current.strength != next.strength) {
    return next.strength == PlaceDuplicateStrength.strong;
  }
  return next.reason.length > current.reason.length;
}

int _scorePlaceCandidate(Place place) {
  var score = 0;
  if (place.favorite) score += 80;
  if (place.address.isNotEmpty) score += 25;
  if (place.mall.isNotEmpty) score += 20;
  if (place.storeName.isNotEmpty) score += 20;
  if (place.mapUrl.isNotEmpty) score += 18;
  if (place.sourceUrl.isNotEmpty) score += 14;
  if (place.platformLinks.isNotEmpty) score += 16;
  if (place.photos.isNotEmpty) score += 16;
  if (place.tags.isNotEmpty) score += 8;
  if (place.desc.isNotEmpty) score += 10;
  if (place.latitude != null && place.longitude != null) score += 10;
  score += place.name.length.clamp(0, 12);
  score += place.address.length.clamp(0, 20);
  return score;
}

String _buildDuplicateLabel(Place place) {
  final parts = [place.name, place.storeName, place.mall]
      .where((item) => item.isNotEmpty)
      .toList();
  return parts.isEmpty ? place.name : parts.join(' · ');
}

String _buildGeoBucket(Place place) {
  if (place.latitude == null || place.longitude == null) return '';
  final lat = (place.latitude! * 1000).round() / 1000;
  final lng = (place.longitude! * 1000).round() / 1000;
  return '$lat,$lng';
}

String _normalizeToken(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[·•・\s]+'), '')
      .replaceAll(RegExp(r'[()（）【】]'), '');
}

String _normalizeAddress(String value) {
  return _normalizeToken(value)
      .replaceAll(RegExp(r'[\-_,，。；;:：]'), '')
      .replaceAll(RegExp(r'第?\d+层'), '')
      .replaceAll(RegExp(r'\b[ab]\d+\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bf\d+\b', caseSensitive: false), '');
}

String _pickLongerName(String primary, String fallback) {
  final left = primary.trim();
  final right = fallback.trim();
  if (left.isEmpty) return right;
  if (right.isEmpty) return left;
  return left.length >= right.length ? left : right;
}

List<Place> _uniqueById(List<Place> places) {
  final seen = <String>{};
  return places.where((place) => seen.add(place.id)).toList();
}

List<String> _uniqueStrings(List<String> items) {
  final seen = <String>{};
  return items
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && seen.add(item))
      .toList();
}

List<PlaceExternalLink> _mergePlacePlatformLinks(
    List<PlaceExternalLink> target, List<PlaceExternalLink> source) {
  final seen = <String>{};
  final links = <PlaceExternalLink>[];
  for (final link in [...target, ...source]) {
    final key = '${link.platform}|${link.url}'.toLowerCase();
    if (link.url.trim().isEmpty || !seen.add(key)) continue;
    links.add(link);
  }
  return links;
}

bool _isWeakStoreName(String value) {
  final normalized = _normalizeToken(value);
  return normalized.isEmpty ||
      ['总店', '分店', '旗舰店', '店', '门店'].contains(normalized);
}

List<String> _buildPreviewDetails(
    Place existing, Place incoming, String reason) {
  final details = <String>[];

  if (reason.contains('同城')) {
    final city = [existing.province, existing.city]
        .where((item) => item.isNotEmpty)
        .join(' · ');
    details.add('城市一致：${city.isEmpty ? '未设置' : city}');
  }

  if (reason.contains('商场')) {
    details.add(
        '商场/园区：${existing.mall.isEmpty ? '未填写' : existing.mall} / ${incoming.mall.isEmpty ? '未填写' : incoming.mall}');
  }

  if (reason.contains('店名') || reason.contains('名称')) {
    final left = [existing.name, existing.storeName]
        .where((item) => item.isNotEmpty)
        .join(' · ');
    final right = [incoming.name, incoming.storeName]
        .where((item) => item.isNotEmpty)
        .join(' · ');
    details.add(
        '名称接近：${left.isEmpty ? existing.name : left} / ${right.isEmpty ? incoming.name : right}');
  }

  if (reason.contains('地址')) {
    details.add(
        '地址命中：${existing.address.isEmpty ? '未填写' : existing.address} / ${incoming.address.isEmpty ? '未填写' : incoming.address}');
  } else if (existing.address.isEmpty || incoming.address.isEmpty) {
    details.add('至少一条记录缺少详细地址，需要人工确认。');
  }

  if (existing.mapUrl.isNotEmpty ||
      incoming.mapUrl.isNotEmpty ||
      (existing.latitude != null && incoming.latitude != null)) {
    details.add('存在地图链接或坐标信息，可作为同一地点辅助判断。');
  }

  return details;
}

class _Bucket {
  final String reason;
  PlaceDuplicateStrength strength;
  final List<Place> places = [];

  _Bucket({required this.reason, required this.strength});
}
