import 'person.dart';

class PlaceExternalLink {
  final String label;
  final String url;
  final String platform;

  const PlaceExternalLink(
      {required this.label, required this.url, required this.platform});

  Map<String, dynamic> toJson() =>
      {'label': label, 'url': url, 'platform': platform};

  factory PlaceExternalLink.fromJson(Map<String, dynamic> map) {
    return PlaceExternalLink(
      label: map['label'] as String? ?? '',
      url: map['url'] as String? ?? '',
      platform: map['platform'] as String? ?? 'custom',
    );
  }
}

class Place {
  final String id;
  final String name;
  final String country;
  final String province;
  final String city;
  final String area;
  final String mall;
  final String storeName;
  final String category;
  final double rating;
  final String address;
  final double? latitude;
  final double? longitude;
  final String mapUrl;
  final String sourceUrl;
  final List<PlaceExternalLink> platformLinks;
  final List<String> photos;
  final String desc;
  final List<String> tags;
  final bool favorite;

  const Place({
    required this.id,
    required this.name,
    this.country = '中国',
    this.province = '',
    this.city = '',
    this.area = '',
    this.mall = '',
    this.storeName = '',
    this.category = '',
    this.rating = 0,
    this.address = '',
    this.latitude,
    this.longitude,
    this.mapUrl = '',
    this.sourceUrl = '',
    this.platformLinks = const [],
    this.photos = const [],
    this.desc = '',
    this.tags = const [],
    this.favorite = false,
  });

  Place copyWith({
    String? id,
    String? name,
    String? country,
    String? province,
    String? city,
    String? area,
    String? mall,
    String? storeName,
    String? category,
    double? rating,
    String? address,
    double? latitude,
    double? longitude,
    String? mapUrl,
    String? sourceUrl,
    List<PlaceExternalLink>? platformLinks,
    List<String>? photos,
    String? desc,
    List<String>? tags,
    bool? favorite,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      area: area ?? this.area,
      mall: mall ?? this.mall,
      storeName: storeName ?? this.storeName,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapUrl: mapUrl ?? this.mapUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      platformLinks: platformLinks ?? this.platformLinks,
      photos: photos ?? this.photos,
      desc: desc ?? this.desc,
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'province': province,
        'city': city,
        'area': area,
        'mall': mall,
        'storeName': storeName,
        'category': category,
        'rating': rating,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'mapUrl': mapUrl,
        'sourceUrl': sourceUrl,
        'platformLinks': platformLinks.map((link) => link.toJson()).toList(),
        'photos': photos,
        'desc': desc,
        'tags': tags,
        'favorite': favorite,
      };

  factory Place.fromJson(Map<String, dynamic> map) => Place(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        country: map['country'] as String? ?? '中国',
        province: map['province'] as String? ?? '',
        city: map['city'] as String? ?? '',
        area: map['area'] as String? ?? '',
        mall: map['mall'] as String? ?? '',
        storeName: map['storeName'] as String? ?? '',
        category: map['category'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        address: map['address'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        mapUrl: map['mapUrl'] as String? ?? '',
        sourceUrl: map['sourceUrl'] as String? ?? '',
        platformLinks: (map['platformLinks'] as List?)
                ?.whereType<Map>()
                .map((m) =>
                    PlaceExternalLink.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
        photos:
            (map['photos'] as List?)?.map((item) => item.toString()).toList() ??
                const [],
        desc: map['desc'] as String? ?? '',
        tags: (map['tags'] as List?)?.map((item) => item.toString()).toList() ??
            const [],
        favorite: map['favorite'] == true || map['favorite'] == 1,
      );
}

class MemoryEvent {
  final String id;
  final String title;
  final String date;
  final List<String> personIds;
  final String placeId;
  final String mood;
  final String content;
  final List<String> tags;
  final List<String> photos;

  const MemoryEvent({
    required this.id,
    required this.title,
    required this.date,
    this.personIds = const [],
    this.placeId = '',
    this.mood = '日常',
    this.content = '',
    this.tags = const [],
    this.photos = const [],
  });

  MemoryEvent copyWith({
    String? id,
    String? title,
    String? date,
    List<String>? personIds,
    String? placeId,
    String? mood,
    String? content,
    List<String>? tags,
    List<String>? photos,
  }) {
    return MemoryEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      personIds: personIds ?? this.personIds,
      placeId: placeId ?? this.placeId,
      mood: mood ?? this.mood,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'personIds': personIds,
        'placeId': placeId,
        'mood': mood,
        'content': content,
        'tags': tags,
        'photos': photos,
      };

  factory MemoryEvent.fromJson(Map<String, dynamic> map) => MemoryEvent(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        date: map['date'] as String? ?? '',
        personIds: (map['personIds'] as List?)
                ?.map((item) => item.toString())
                .toList() ??
            const [],
        placeId: map['placeId'] as String? ?? '',
        mood: map['mood'] as String? ?? '日常',
        content: map['content'] as String? ?? '',
        tags: (map['tags'] as List?)?.map((item) => item.toString()).toList() ??
            const [],
        photos:
            (map['photos'] as List?)?.map((item) => item.toString()).toList() ??
                const [],
      );
}

class LifeLogState {
  final List<Person> people;
  final List<Place> places;
  final List<MemoryEvent> memories;

  const LifeLogState(
      {required this.people, required this.places, required this.memories});

  Map<String, dynamic> toJson() => {
        'people': people.map((person) => person.toJson()).toList(),
        'places': places.map((place) => place.toJson()).toList(),
        'memories': memories.map((memory) => memory.toJson()).toList(),
      };

  factory LifeLogState.fromJson(Map<String, dynamic> map) {
    final source = map['state'] is Map
        ? Map<String, dynamic>.from(map['state'] as Map)
        : map;
    return LifeLogState(
      people: (source['people'] as List?)
              ?.whereType<Map>()
              .map((m) => Person.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      places: (source['places'] as List?)
              ?.whereType<Map>()
              .map((m) => Place.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      memories: (source['memories'] as List?)
              ?.whereType<Map>()
              .map((m) => MemoryEvent.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
    );
  }
}

class AppSettingsSnapshot {
  final String themeStyle;
  final bool themeMode;
  final List<String> customRelationships;
  final List<String> customMoods;

  const AppSettingsSnapshot({
    this.themeStyle = 'classic',
    this.themeMode = false,
    this.customRelationships = const ['朋友', '家人', '同事', '同学', '恋人', '其他'],
    this.customMoods = const ['日常', '开心', '轻松', '愉快', '感动', '难忘'],
  });

  Map<String, dynamic> toJson() => {
        'themeStyle': themeStyle,
        'themeMode': themeMode,
        'customRelationships': customRelationships,
        'customMoods': customMoods,
      };

  factory AppSettingsSnapshot.fromJson(Map<String, dynamic>? map) {
    if (map == null) return const AppSettingsSnapshot();
    return AppSettingsSnapshot(
      themeStyle: map['themeStyle']?.toString() ??
          map['theme']?.toString() ??
          'classic',
      themeMode: map['themeMode'] == true || map['isDarkMode'] == true,
      customRelationships: (map['customRelationships'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const ['朋友', '家人', '同事', '同学', '恋人', '其他'],
      customMoods: (map['customMoods'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const ['日常', '开心', '轻松', '愉快', '感动', '难忘'],
    );
  }
}

class ReminderSettingsSnapshot {
  final bool birthdayEnabled;
  final bool contactEnabled;
  final bool memoryReviewEnabled;
  final String birthdayTime;
  final String contactTime;
  final String memoryReviewTime;
  final int contactIntervalDays;

  const ReminderSettingsSnapshot({
    this.birthdayEnabled = false,
    this.contactEnabled = false,
    this.memoryReviewEnabled = false,
    this.birthdayTime = '09:00',
    this.contactTime = '10:00',
    this.memoryReviewTime = '09:00',
    this.contactIntervalDays = 30,
  });

  Map<String, dynamic> toJson() => {
        'birthdayEnabled': birthdayEnabled,
        'contactEnabled': contactEnabled,
        'memoryReviewEnabled': memoryReviewEnabled,
        'birthdayTime': birthdayTime,
        'contactTime': contactTime,
        'memoryReviewTime': memoryReviewTime,
        'contactIntervalDays': contactIntervalDays,
      };

  factory ReminderSettingsSnapshot.fromJson(Map<String, dynamic>? map) {
    if (map == null) return const ReminderSettingsSnapshot();
    return ReminderSettingsSnapshot(
      birthdayEnabled: map['birthdayEnabled'] == true || map['enabled'] == true,
      contactEnabled: map['contactEnabled'] == true ||
          map['contactRemindersEnabled'] == true,
      memoryReviewEnabled: map['memoryReviewEnabled'] == true ||
          map['memoryReviewRemindersEnabled'] == true,
      birthdayTime: map['birthdayTime']?.toString() ??
          map['reminderTime']?.toString() ??
          '09:00',
      contactTime: map['contactTime']?.toString() ?? '10:00',
      memoryReviewTime: map['memoryReviewTime']?.toString() ?? '09:00',
      contactIntervalDays: (map['contactIntervalDays'] as num?)?.toInt() ?? 30,
    );
  }
}

class LifeLogBackup {
  final int schemaVersion;
  final String appVersion;
  final String exportedAt;
  final LifeLogState state;
  final List<dynamic> photos;
  final AppSettingsSnapshot settings;
  final ReminderSettingsSnapshot reminderSettings;
  final List<dynamic> placeMergeHistory;

  const LifeLogBackup({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.state,
    this.photos = const [],
    this.settings = const AppSettingsSnapshot(),
    this.reminderSettings = const ReminderSettingsSnapshot(),
    this.placeMergeHistory = const [],
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'appVersion': appVersion,
        'exportedAt': exportedAt,
        'state': state.toJson(),
        'photos': photos,
        'settings': settings.toJson(),
        'reminderSettings': reminderSettings.toJson(),
        'placeMergeHistory': placeMergeHistory,
        'integrity': {
          'people': state.people.length,
          'places': state.places.length,
          'memories': state.memories.length,
          'photos': photos.length,
          'placeMergeHistory': placeMergeHistory.length,
        },
      };

  factory LifeLogBackup.fromJson(Map<String, dynamic> map) => LifeLogBackup(
        schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
        appVersion: map['appVersion']?.toString() ?? '',
        exportedAt: map['exportedAt']?.toString() ?? '',
        state: LifeLogState.fromJson(map),
        photos: (map['photos'] as List?) ?? const [],
        settings: AppSettingsSnapshot.fromJson(map['settings'] is Map
            ? Map<String, dynamic>.from(map['settings'] as Map)
            : null),
        reminderSettings: ReminderSettingsSnapshot.fromJson(
            map['reminderSettings'] is Map
                ? Map<String, dynamic>.from(map['reminderSettings'] as Map)
                : null),
        placeMergeHistory: (map['placeMergeHistory'] as List?) ?? const [],
      );
}

class PlaceMergeHistoryEntry {
  final String id;
  final String happenedAt;
  final String reason;
  final List<String> removedIds;
  final List<String> placeIds;
  final LifeLogState snapshot;

  const PlaceMergeHistoryEntry({
    required this.id,
    required this.happenedAt,
    required this.reason,
    required this.removedIds,
    required this.placeIds,
    required this.snapshot,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'happenedAt': happenedAt,
        'reason': reason,
        'removedIds': removedIds,
        'placeIds': placeIds,
        'snapshot': snapshot.toJson(),
      };

  factory PlaceMergeHistoryEntry.fromJson(Map<String, dynamic> map) {
    return PlaceMergeHistoryEntry(
      id: map['id']?.toString() ?? '',
      happenedAt: map['happenedAt']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '地点合并',
      removedIds: (map['removedIds'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      placeIds:
          (map['placeIds'] as List?)?.map((item) => item.toString()).toList() ??
              const [],
      snapshot: LifeLogState.fromJson(
        map['snapshot'] is Map
            ? Map<String, dynamic>.from(map['snapshot'] as Map)
            : const <String, dynamic>{},
      ),
    );
  }
}
