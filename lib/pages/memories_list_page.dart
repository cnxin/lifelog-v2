import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/lifelog_models.dart';
import '../models/person.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/lunar_utils.dart';
import '../widgets/glass_card.dart';

class MemoriesListPage extends ConsumerStatefulWidget {
  const MemoriesListPage({super.key});

  @override
  ConsumerState<MemoriesListPage> createState() => _MemoriesListPageState();
}

class _MemoriesListPageState extends ConsumerState<MemoriesListPage> {
  final _searchController = TextEditingController();
  String _personFilter = '';
  String _placeFilter = '';
  String _moodFilter = '';
  String _tagFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final query = ref.watch(memorySearchQueryProvider);
    final colors = AppColors.fromStyle(ref.watch(themeStyleProvider),
        isDark: ref.watch(themeModeProvider));
    final theme = Theme.of(context);

    return Stack(
      children: [
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('记忆', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 16),
                    _SearchBox(
                      controller: _searchController,
                      query: query,
                      hint: '搜索标题、正文、人物、地点、心情或标签',
                      colors: colors,
                      onChanged: (value) => ref
                          .read(memorySearchQueryProvider.notifier)
                          .state = value,
                      onClear: () {
                        _searchController.clear();
                        ref.read(memorySearchQueryProvider.notifier).state = '';
                      },
                    ),
                    const SizedBox(height: 12),
                    memoriesAsync.maybeWhen(
                      data: (memories) => _MemoryFilters(
                        memories: memories,
                        people: people,
                        places: places,
                        colors: colors,
                        personFilter: _personFilter,
                        placeFilter: _placeFilter,
                        moodFilter: _moodFilter,
                        tagFilter: _tagFilter,
                        onPersonChanged: (value) =>
                            setState(() => _personFilter = value),
                        onPlaceChanged: (value) =>
                            setState(() => _placeFilter = value),
                        onMoodChanged: (value) =>
                            setState(() => _moodFilter = value),
                        onTagChanged: (value) =>
                            setState(() => _tagFilter = value),
                        onClear: _clearFilters,
                        hasQuery: query.trim().isNotEmpty,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Expanded(
              child: memoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (memories) {
                  final filtered =
                      _filterMemories(memories, people, places, query);
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    itemCount: filtered.isEmpty ? 1 : filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      if (filtered.isEmpty) {
                        return _EmptyMemoriesCard(
                          hasAnyMemories: memories.isNotEmpty,
                          hasActiveFilters: _hasActiveFilters(query),
                          colors: colors,
                          onClear: _clearFilters,
                        );
                      }
                      return _MemoryCard(
                        memory: filtered[i],
                        people: people,
                        places: places,
                        colors: colors,
                        colorVariant: i,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 100,
          child: GradientFAB(
              colors: colors, onPressed: () => context.push('/memories/new')),
        ),
      ],
    );
  }

  List<MemoryEvent> _filterMemories(List<MemoryEvent> memories,
      List<Person> people, List<Place> places, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final peopleById = {for (final person in people) person.id: person.name};
    final placesById = {for (final place in places) place.id: place.name};

    return memories.where((memory) {
      final personNames = memory.personIds
          .map((id) => peopleById[id] ?? '')
          .where((name) => name.isNotEmpty)
          .join(',');
      final placeName = placesById[memory.placeId] ?? '';
      final content = [
        memory.title,
        memoryDisplayTitle(memory.title, memory.content),
        memory.content,
        memory.mood,
        personNames,
        placeName,
        memory.tags.join(','),
      ].join(' ').toLowerCase();

      if (normalizedQuery.isNotEmpty && !content.contains(normalizedQuery)) {
        return false;
      }
      if (_personFilter.isNotEmpty &&
          !memory.personIds.contains(_personFilter)) {
        return false;
      }
      if (_placeFilter.isNotEmpty && memory.placeId != _placeFilter) {
        return false;
      }
      if (_moodFilter.isNotEmpty && memory.mood != _moodFilter) {
        return false;
      }
      if (_tagFilter.isNotEmpty && !memory.tags.contains(_tagFilter)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _hasActiveFilters(String query) {
    return query.trim().isNotEmpty ||
        _personFilter.isNotEmpty ||
        _placeFilter.isNotEmpty ||
        _moodFilter.isNotEmpty ||
        _tagFilter.isNotEmpty;
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(memorySearchQueryProvider.notifier).state = '';
    setState(() {
      _personFilter = '';
      _placeFilter = '';
      _moodFilter = '';
      _tagFilter = '';
    });
  }
}

class _MemoryFilters extends StatelessWidget {
  final List<MemoryEvent> memories;
  final List<Person> people;
  final List<Place> places;
  final AppColors colors;
  final String personFilter;
  final String placeFilter;
  final String moodFilter;
  final String tagFilter;
  final ValueChanged<String> onPersonChanged;
  final ValueChanged<String> onPlaceChanged;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<String> onTagChanged;
  final VoidCallback onClear;
  final bool hasQuery;

  const _MemoryFilters({
    required this.memories,
    required this.people,
    required this.places,
    required this.colors,
    required this.personFilter,
    required this.placeFilter,
    required this.moodFilter,
    required this.tagFilter,
    required this.onPersonChanged,
    required this.onPlaceChanged,
    required this.onMoodChanged,
    required this.onTagChanged,
    required this.onClear,
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    final personOptions = _personOptions();
    final placeOptions = _placeOptions();
    final moodOptions = _setOptions(memories.map((memory) => memory.mood));
    final tagOptions = _setOptions(memories.expand((memory) => memory.tags));
    final hasActiveFilters = hasQuery ||
        personFilter.isNotEmpty ||
        placeFilter.isNotEmpty ||
        moodFilter.isNotEmpty ||
        tagFilter.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterMenu(
                  label: '人物',
                  value: personFilter,
                  options: personOptions,
                  colors: colors,
                  onChanged: onPersonChanged),
              const SizedBox(width: 8),
              _FilterMenu(
                  label: '地点',
                  value: placeFilter,
                  options: placeOptions,
                  colors: colors,
                  onChanged: onPlaceChanged),
              const SizedBox(width: 8),
              _FilterMenu(
                  label: '心情',
                  value: moodFilter,
                  options: moodOptions,
                  colors: colors,
                  onChanged: onMoodChanged),
              const SizedBox(width: 8),
              _FilterMenu(
                  label: '标签',
                  value: tagFilter,
                  options: tagOptions,
                  colors: colors,
                  onChanged: onTagChanged),
            ],
          ),
        ),
        if (hasActiveFilters) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onClear,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restart_alt_rounded,
                    size: 16, color: colors.primary),
                const SizedBox(width: 4),
                Text('清除筛选',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<_FilterOption> _personOptions() {
    final ids = memories.expand((memory) => memory.personIds).toSet();
    return people
        .where((person) => ids.contains(person.id))
        .map((person) => _FilterOption(value: person.id, label: person.name))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  List<_FilterOption> _placeOptions() {
    final ids = memories
        .map((memory) => memory.placeId)
        .where((id) => id.isNotEmpty)
        .toSet();
    return places
        .where((place) => ids.contains(place.id))
        .map((place) => _FilterOption(value: place.id, label: place.name))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  List<_FilterOption> _setOptions(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .map((value) => _FilterOption(value: value, label: value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }
}

class _FilterMenu extends StatelessWidget {
  final String label;
  final String value;
  final List<_FilterOption> options;
  final AppColors colors;
  final ValueChanged<String> onChanged;

  const _FilterMenu({
    required this.label,
    required this.value,
    required this.options,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabel = value.isEmpty
        ? label
        : options
                .where((option) => option.value == value)
                .map((option) => option.label)
                .firstOrNull ??
            label;
    return PopupMenuButton<String>(
      enabled: options.isNotEmpty,
      initialValue: value.isEmpty ? null : value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(value: '', child: Text('全部$label')),
        ...options.map((option) =>
            PopupMenuItem(value: option.value, child: Text(option.label))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value.isEmpty ? colors.cardBg : colors.softPurple,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color:
                  value.isEmpty ? colors.line : colors.primary.withAlpha(90)),
          boxShadow: [colors.shadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLabel,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: value.isEmpty ? colors.textSub : colors.primary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 16,
                color: value.isEmpty ? colors.textSub : colors.primary),
          ],
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final MemoryEvent memory;
  final List<Person> people;
  final List<Place> places;
  final AppColors colors;
  final int colorVariant;

  const _MemoryCard({
    required this.memory,
    required this.people,
    required this.places,
    required this.colors,
    required this.colorVariant,
  });

  @override
  Widget build(BuildContext context) {
    final personNames = people
        .where((p) => memory.personIds.contains(p.id))
        .map((p) => p.name)
        .toList();
    final place = places.where((p) => p.id == memory.placeId).firstOrNull;
    final title = memoryDisplayTitle(memory.title, memory.content);
    final content = memory.content.trim();
    final hasPhotos = memory.photos.isNotEmpty;

    return GlassCard(
      colors: colors,
      onTap: () => context.push('/memories/${memory.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colorVariant.isEven
                    ? [colors.primary, colors.secondary]
                    : [const Color(0xFF35C7D0), colors.primary],
              ),
              boxShadow: [colors.avatarShadow],
            ),
            child: Icon(
                hasPhotos ? Icons.image_rounded : Icons.favorite_border_rounded,
                color: Colors.white,
                size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textMain))),
                    if (hasPhotos) ...[
                      Icon(Icons.image_rounded,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 3),
                      Text('${memory.photos.length}',
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(memory.date,
                    style: TextStyle(fontSize: 12, color: colors.textSub)),
                const SizedBox(height: 8),
                if (personNames.isNotEmpty || place != null)
                  Text(
                    [
                      if (personNames.isNotEmpty) personNames.join('、'),
                      if (place != null) place.name
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: colors.textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (content.isNotEmpty &&
                    isManualMemoryTitle(memory.title)) ...[
                  const SizedBox(height: 8),
                  Text(content,
                      style: TextStyle(
                          fontSize: 13, color: colors.textMain, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Pill(label: memory.mood, colors: colors, accent: true),
                    ...memory.tags
                        .take(3)
                        .map((tag) => _Pill(label: tag, colors: colors)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 20, color: colors.textSub.withAlpha(100)),
        ],
      ),
    );
  }
}

class _EmptyMemoriesCard extends StatelessWidget {
  final bool hasAnyMemories;
  final bool hasActiveFilters;
  final AppColors colors;
  final VoidCallback onClear;

  const _EmptyMemoriesCard({
    required this.hasAnyMemories,
    required this.hasActiveFilters,
    required this.colors,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      colors: colors,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
              hasAnyMemories
                  ? Icons.search_off_rounded
                  : Icons.auto_stories_rounded,
              size: 38,
              color: colors.primary),
          const SizedBox(height: 10),
          Text(
            hasAnyMemories ? '没有找到匹配的回忆' : '还没有回忆记录',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textMain),
          ),
          if (hasAnyMemories && hasActiveFilters) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('清除筛选'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String hint;
  final AppColors colors;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.query,
    required this.hint,
    required this.colors,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.line),
            boxShadow: [colors.shadow],
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: colors.textSub),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(fontSize: 15, color: colors.textMain),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: colors.textSub, fontSize: 15),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (query.isNotEmpty)
                GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close, size: 18, color: colors.textSub)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final AppColors colors;
  final bool accent;

  const _Pill({required this.label, required this.colors, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? colors.softOrange : colors.softPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: accent ? const Color(0xFFE17055) : colors.primary),
      ),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}
