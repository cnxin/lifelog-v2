import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class PeopleListPage extends ConsumerStatefulWidget {
  const PeopleListPage({super.key});

  @override
  ConsumerState<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends ConsumerState<PeopleListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final colors = ref.watch(appColorsProvider);
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
                    Text('人物', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 16),
                    // 搜索栏 - glass 风格
                    ClipRRect(
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
                              Icon(Icons.search,
                                  size: 20, color: colors.textSub),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(
                                      fontSize: 15, color: colors.textMain),
                                  decoration: InputDecoration(
                                    hintText: '搜索人物...',
                                    hintStyle: TextStyle(
                                        color: colors.textSub, fontSize: 15),
                                    border: InputBorder.none,
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  onChanged: (v) {
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = v;
                                    ref.read(peopleProvider.notifier).search(v);
                                  },
                                ),
                              ),
                              if (searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = '';
                                    ref
                                        .read(peopleProvider.notifier)
                                        .search('');
                                  },
                                  child: Icon(Icons.close,
                                      size: 18, color: colors.textSub),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Expanded(
              child: peopleAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (people) {
                  if (people.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: colors.textSub.withAlpha(100)),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty
                                ? '没有找到匹配的人物'
                                : '还没有人物，点击 + 添加',
                            style:
                                TextStyle(color: colors.textSub, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    itemCount: people.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _PersonCard(
                      person: people[i],
                      colors: colors,
                      colorVariant: i,
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // FAB
        Positioned(
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 100,
          child: GradientFAB(
            colors: colors,
            onPressed: () => context.push('/people/new'),
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends ConsumerWidget {
  final Person person;
  final AppColors colors;
  final int colorVariant;

  const _PersonCard(
      {required this.person, required this.colors, required this.colorVariant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      colors: colors,
      onTap: () => context.push('/people/${person.id}'),
      child: Row(
        children: [
          GradientAvatar(
            name: person.name,
            size: 48,
            borderRadius: 18,
            fontSize: 20,
            colors: colors,
            colorVariant: colorVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textMain),
                    ),
                    if (person.nickname.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${person.nickname})',
                        style: TextStyle(fontSize: 13, color: colors.textSub),
                      ),
                    ],
                    if (person.favorite) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFDCB6E)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _relationshipColor(person.relationship, colors),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        person.relationship,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _relationshipTextColor(
                                person.relationship, colors)),
                      ),
                    ),
                    if (person.birthday != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.cake, size: 14, color: colors.textSub),
                      const SizedBox(width: 3),
                      Text(
                        person.birthday!,
                        style: TextStyle(fontSize: 12, color: colors.textSub),
                      ),
                    ],
                  ],
                ),
                if (person.preferences.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: person.preferences
                        .expand((g) => g.items)
                        .take(4)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: entry.key.isEven
                                    ? colors.softPurple
                                    : colors.softOrange,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: entry.key.isEven
                                        ? colors.primary
                                        : colors.secondary),
                              ),
                            ))
                        .toList(),
                  ),
                ],
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

Color _relationshipColor(String relationship, AppColors colors) {
  switch (relationship) {
    case '家人':
    case '恋人':
      return const Color(0x1FFF8FB0);
    case '朋友':
      return colors.softOrange;
    case '同事':
    case '同学':
      return const Color(0x1F35C7D0);
    default:
      return colors.softPurple;
  }
}

Color _relationshipTextColor(String relationship, AppColors colors) {
  switch (relationship) {
    case '家人':
    case '恋人':
      return const Color(0xFFE26B91);
    case '朋友':
      return colors.secondary;
    case '同事':
    case '同学':
      return const Color(0xFF1B95A0);
    default:
      return colors.primary;
  }
}
