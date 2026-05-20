import 'package:drift/drift.dart';
import 'dart:convert';
import '../models/person.dart' as person_model;
import '../models/lifelog_models.dart' as lifelog_model;
import 'database_connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [People, Places, Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(places, places.country);
            await m.addColumn(places, places.latitude);
            await m.addColumn(places, places.longitude);
          }
        },
      );

  // People operations
  Future<List<person_model.Person>> getAllPeople() async {
    final rows = await select(people).get();
    return rows.map(_personFromRow).toList();
  }

  Future<person_model.Person?> getPersonById(String uuid) async {
    final row = await (select(people)..where((p) => p.uuid.equals(uuid))).getSingleOrNull();
    return row != null ? _personFromRow(row) : null;
  }

  Future<void> insertPerson(person_model.Person person) async {
    await into(people).insert(
      PeopleCompanion.insert(
        uuid: person.id,
        name: person.name,
        relation: Value(person.relationship),
        birthday: Value(person.birthday ?? ''),
        anniversary: Value(jsonEncode(person.anniversaries.map((a) => a.toJson()).toList())),
        phone: Value(person.nickname),
        email: Value(person.birthdayIsLunar.toString()),
        notes: Value(person.notes),
        tags: Value(jsonEncode(person.preferences.map((g) => g.toJson()).toList())),
        photos: Value(jsonEncode(person.dislikes.map((g) => g.toJson()).toList())),
        favorite: Value(person.favorite),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updatePerson(person_model.Person person) async {
    await (update(people)..where((p) => p.uuid.equals(person.id))).write(
      PeopleCompanion(
        name: Value(person.name),
        relation: Value(person.relationship),
        birthday: Value(person.birthday ?? ''),
        anniversary: Value(jsonEncode(person.anniversaries.map((a) => a.toJson()).toList())),
        phone: Value(person.nickname),
        email: Value(person.birthdayIsLunar.toString()),
        notes: Value(person.notes),
        tags: Value(jsonEncode(person.preferences.map((g) => g.toJson()).toList())),
        photos: Value(jsonEncode(person.dislikes.map((g) => g.toJson()).toList())),
        favorite: Value(person.favorite),
      ),
    );
  }

  Future<void> deletePerson(String uuid) async {
    await (delete(people)..where((p) => p.uuid.equals(uuid))).go();
  }

  Future<List<person_model.Person>> searchPeople(String query) async {
    final rows = await (select(people)
          ..where((p) => p.name.like('%$query%') | p.relation.like('%$query%') | p.notes.like('%$query%')))
        .get();
    return rows.map(_personFromRow).toList();
  }

  // Places operations
  Future<List<lifelog_model.Place>> getAllPlaces() async {
    final rows = await select(places).get();
    return rows.map(_placeFromRow).toList();
  }

  Future<lifelog_model.Place?> getPlaceById(String uuid) async {
    final row = await (select(places)..where((p) => p.uuid.equals(uuid))).getSingleOrNull();
    return row != null ? _placeFromRow(row) : null;
  }

  Future<void> insertPlace(lifelog_model.Place place) async {
    await into(places).insert(
      PlacesCompanion.insert(
        uuid: place.id,
        name: place.name,
        country: Value(place.country),
        province: Value(place.province),
        city: Value(place.city),
        area: Value(place.area),
        mall: Value(place.mall),
        storeName: Value(place.storeName),
        category: Value(place.category),
        rating: Value(place.rating),
        address: Value(place.address),
        latitude: Value(place.latitude),
        longitude: Value(place.longitude),
        mapUrl: Value(place.mapUrl),
        sourceUrl: Value(place.sourceUrl),
        platformLinks: Value(jsonEncode(place.platformLinks.map((l) => l.toJson()).toList())),
        desc: Value(place.desc),
        tags: Value(jsonEncode(place.tags)),
        photos: Value(jsonEncode(place.photos)),
        favorite: Value(place.favorite),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updatePlace(lifelog_model.Place place) async {
    await (update(places)..where((p) => p.uuid.equals(place.id))).write(
      PlacesCompanion(
        name: Value(place.name),
        country: Value(place.country),
        province: Value(place.province),
        city: Value(place.city),
        area: Value(place.area),
        mall: Value(place.mall),
        storeName: Value(place.storeName),
        category: Value(place.category),
        rating: Value(place.rating),
        address: Value(place.address),
        latitude: Value(place.latitude),
        longitude: Value(place.longitude),
        mapUrl: Value(place.mapUrl),
        sourceUrl: Value(place.sourceUrl),
        platformLinks: Value(jsonEncode(place.platformLinks.map((l) => l.toJson()).toList())),
        desc: Value(place.desc),
        tags: Value(jsonEncode(place.tags)),
        photos: Value(jsonEncode(place.photos)),
        favorite: Value(place.favorite),
      ),
    );
  }

  Future<void> deletePlace(String uuid) async {
    await (delete(places)..where((p) => p.uuid.equals(uuid))).go();
  }

  Future<List<lifelog_model.Place>> searchPlaces(String query) async {
    final rows = await (select(places)
          ..where((p) => p.name.like('%$query%') | p.category.like('%$query%') | p.desc.like('%$query%')))
        .get();
    return rows.map(_placeFromRow).toList();
  }

  // Memories operations
  Future<List<lifelog_model.MemoryEvent>> getAllMemories() async {
    final rows = await (select(memories)..orderBy([(m) => OrderingTerm.desc(m.date)])).get();
    return rows.map(_memoryFromRow).toList();
  }

  Future<lifelog_model.MemoryEvent?> getMemoryById(String uuid) async {
    final row = await (select(memories)..where((m) => m.uuid.equals(uuid))).getSingleOrNull();
    return row != null ? _memoryFromRow(row) : null;
  }

  Future<void> insertMemory(lifelog_model.MemoryEvent memory) async {
    await into(memories).insert(
      MemoriesCompanion.insert(
        uuid: memory.id,
        title: memory.title,
        date: memory.date,
        personIds: Value(jsonEncode(memory.personIds)),
        placeId: Value(memory.placeId),
        mood: Value(memory.mood),
        content: Value(memory.content),
        tags: Value(jsonEncode(memory.tags)),
        photos: Value(jsonEncode(memory.photos)),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateMemory(lifelog_model.MemoryEvent memory) async {
    await (update(memories)..where((m) => m.uuid.equals(memory.id))).write(
      MemoriesCompanion(
        title: Value(memory.title),
        date: Value(memory.date),
        personIds: Value(jsonEncode(memory.personIds)),
        placeId: Value(memory.placeId),
        mood: Value(memory.mood),
        content: Value(memory.content),
        tags: Value(jsonEncode(memory.tags)),
        photos: Value(jsonEncode(memory.photos)),
      ),
    );
  }

  Future<void> deleteMemory(String uuid) async {
    await (delete(memories)..where((m) => m.uuid.equals(uuid))).go();
  }

  Future<List<lifelog_model.MemoryEvent>> searchMemories(String query) async {
    final rows = await (select(memories)
          ..where((m) => m.title.like('%$query%') | m.content.like('%$query%'))
          ..orderBy([(m) => OrderingTerm.desc(m.date)]))
        .get();
    return rows.map(_memoryFromRow).toList();
  }

  // Helper methods
  person_model.Person _personFromRow(PeopleData row) {
    return person_model.Person(
      id: row.uuid,
      name: row.name,
      nickname: row.phone,
      relationship: row.relation,
      birthday: row.birthday.isEmpty ? null : row.birthday,
      birthdayIsLunar: row.email == 'true',
      anniversaries: (jsonDecode(row.anniversary) as List)
          .map((e) => person_model.Anniversary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      preferences: (jsonDecode(row.tags) as List)
          .map((e) => person_model.PreferenceGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      dislikes: (jsonDecode(row.photos) as List)
          .map((e) => person_model.PreferenceGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      notes: row.notes,
      favorite: row.favorite,
    );
  }

  lifelog_model.Place _placeFromRow(PlaceRow row) {
    return lifelog_model.Place(
      id: row.uuid,
      name: row.name,
      country: row.country,
      province: row.province,
      city: row.city,
      area: row.area,
      mall: row.mall,
      storeName: row.storeName,
      category: row.category,
      rating: row.rating,
      address: row.address,
      latitude: row.latitude,
      longitude: row.longitude,
      mapUrl: row.mapUrl,
      sourceUrl: row.sourceUrl,
      platformLinks: (jsonDecode(row.platformLinks) as List)
          .map((e) => lifelog_model.PlaceExternalLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      desc: row.desc,
      tags: (jsonDecode(row.tags) as List).map((e) => e.toString()).toList(),
      photos: (jsonDecode(row.photos) as List).map((e) => e.toString()).toList(),
      favorite: row.favorite,
    );
  }

  lifelog_model.MemoryEvent _memoryFromRow(Memory row) {
    return lifelog_model.MemoryEvent(
      id: row.uuid,
      title: row.title,
      date: row.date,
      personIds: (jsonDecode(row.personIds) as List).map((e) => e.toString()).toList(),
      placeId: row.placeId,
      mood: row.mood,
      content: row.content,
      tags: (jsonDecode(row.tags) as List).map((e) => e.toString()).toList(),
      photos: (jsonDecode(row.photos) as List).map((e) => e.toString()).toList(),
    );
  }
}
