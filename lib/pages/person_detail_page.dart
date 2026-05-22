import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/lifelog_models.dart';
import '../models/person.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/lunar_utils.dart';
import '../utils/relationship_insights.dart';
import '../widgets/glass_card.dart';

class PersonDetailPage extends ConsumerWidget {
  final String personId;
  const PersonDetailPage({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);
    final isDark = ref.watch(themeModeProvider);
    final colors = ref.watch(appColorsProvider);

    return peopleAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (people) {
        final person = people.where((p) => p.id == personId).firstOrNull;
        if (person == null) {
          return GradientBackground(
            colors: colors,
            isDark: isDark,
            child: Scaffold(
                appBar: AppBar(), body: const Center(child: Text('人物不存在'))),
          );
        }
        return GradientBackground(
          colors: colors,
          isDark: isDark,
          child: Scaffold(
            body: _DetailBody(person: person, colors: colors),
            floatingActionButton: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientFAB(
                  colors: colors,
                  icon: Icons.edit,
                  onPressed: () => context.push('/people/${person.id}/edit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Person person;
  final AppColors colors;

  const _DetailBody({required this.person, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final contactIntervalDays = ref.watch(contactIntervalDaysProvider);
    final relatedMemories = memories
        .where((memory) => memory.personIds.contains(person.id))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final insight = buildRelationshipInsight(
      person: person,
      memories: memories,
      places: places,
      now: DateTime.now(),
      contactIntervalDays: contactIntervalDays,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            size: 20, color: colors.textMain),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 22, color: colors.textSub),
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                    ],
                  ),
                ),

                // Profile header
                const SizedBox(height: 8),
                GradientAvatar(
                  name: person.name,
                  size: 82,
                  borderRadius: 28,
                  fontSize: 26,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                Text(
                  person.name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
                if (person.nickname.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(person.nickname,
                      style: TextStyle(fontSize: 14, color: colors.textSub)),
                ],
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.softPurple,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    person.relationship,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primary),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Info sections
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _InfoCard(
                icon: Icons.favorite_rounded,
                title: '关系状态',
                colors: colors,
                child: _RelationshipSummary(insight: insight, colors: colors),
              ),
              if (person.birthday != null)
                _InfoCard(
                  icon: Icons.cake,
                  title: '生日',
                  colors: colors,
                  child: Row(
                    children: [
                      Text(
                        person.birthday!,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colors.textMain),
                      ),
                      if (person.birthdayIsLunar) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.softOrange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('农历',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              if (person.anniversaries.isNotEmpty)
                _InfoCard(
                  icon: Icons.event,
                  title: '纪念日',
                  colors: colors,
                  child: Column(
                    children: person.anniversaries
                        .map((a) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(a.title,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: colors.textMain)),
                                  Text(a.date,
                                      style: TextStyle(
                                          fontSize: 13, color: colors.textSub)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (person.preferences.isNotEmpty)
                _InfoCard(
                  icon: Icons.favorite_rounded,
                  title: '喜好',
                  colors: colors,
                  child: _PreferenceTags(
                      groups: person.preferences, colors: colors),
                ),
              if (person.dislikes.isNotEmpty)
                _InfoCard(
                  icon: Icons.block_rounded,
                  title: '禁忌',
                  colors: colors,
                  child: _PreferenceTags(
                      groups: person.dislikes, colors: colors, isDislike: true),
                ),
              if (person.notes.isNotEmpty)
                _InfoCard(
                  icon: Icons.note_rounded,
                  title: '备注',
                  colors: colors,
                  child: Text(
                    person.notes,
                    style: TextStyle(
                        fontSize: 14, color: colors.textMain, height: 1.5),
                  ),
                ),
              if (relatedMemories.isNotEmpty)
                _InfoCard(
                  icon: Icons.auto_stories_rounded,
                  title: '相关回忆',
                  colors: colors,
                  child: _RelatedMemories(
                      memories: relatedMemories,
                      places: places,
                      colors: colors),
                ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认删除'),
        content: Text('确定要删除 ${person.name} 吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(peopleProvider.notifier).deletePerson(person.id);
              Navigator.pop(ctx);
              context.pop();
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFE17055)),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final AppColors colors;
  final Widget child;

  const _InfoCard(
      {required this.icon,
      required this.title,
      required this.colors,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        colors: colors,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _RelationshipSummary extends StatelessWidget {
  final RelationshipInsight insight;
  final AppColors colors;

  const _RelationshipSummary({required this.insight, required this.colors});

  @override
  Widget build(BuildContext context) {
    final accent = insight.status == RelationshipContactStatus.needsAttention
        ? const Color(0xFFE17055)
        : colors.primary;
    final placesLabel = insight.topPlaces.isEmpty
        ? '暂无常去地点'
        : insight.topPlaces
            .map((stat) => stat.count > 1
                ? '${stat.place.name} ×${stat.count}'
                : stat.place.name)
            .join('、');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _RelationshipStat(
                label: '最近互动',
                value: insight.lastInteractionLabel,
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RelationshipStat(
                label: '互动次数',
                value: '${insight.interactionCount} 次',
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: insight.status == RelationshipContactStatus.needsAttention
                ? colors.softOrange
                : colors.softPurple,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.volunteer_activism_rounded,
                      size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    insight.statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                insight.actionHint,
                style: TextStyle(fontSize: 13, color: colors.textMain),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_rounded, size: 16, color: colors.textSub),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                placesLabel,
                style:
                    TextStyle(fontSize: 13, height: 1.4, color: colors.textSub),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RelationshipStat extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;

  const _RelationshipStat({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.softPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: colors.textSub)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.textMain),
          ),
        ],
      ),
    );
  }
}

class _RelatedMemories extends StatelessWidget {
  final List<MemoryEvent> memories;
  final List<Place> places;
  final AppColors colors;

  const _RelatedMemories(
      {required this.memories, required this.places, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: memories.map((memory) {
        final place =
            places.where((item) => item.id == memory.placeId).firstOrNull;
        final title = memoryDisplayTitle(memory.title, memory.content);
        final content = memory.content.trim();
        final tags = [memory.mood, ...memory.tags]
            .where((item) => item.trim().isNotEmpty)
            .toList();
        return GestureDetector(
          onTap: () => context.push('/memories/${memory.id}'),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: colors.softPurple.withAlpha(110),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(title,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(memory.date,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textSub)),
                  ],
                ),
                if (place != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.place_rounded, size: 13, color: colors.textSub),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(place.name,
                            style:
                                TextStyle(fontSize: 12, color: colors.textSub),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis))
                  ]),
                ],
                if (content.isNotEmpty &&
                    isManualMemoryTitle(memory.title)) ...[
                  const SizedBox(height: 8),
                  Text(content,
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: colors.textMain),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: tags
                          .take(4)
                          .map((tag) => _MiniTag(
                              label: tag,
                              colors: colors,
                              accent: tag == memory.mood))
                          .toList()),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final AppColors colors;
  final bool accent;

  const _MiniTag(
      {required this.label, required this.colors, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: accent ? colors.softOrange : colors.softPurple,
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent ? const Color(0xFFE17055) : colors.primary)),
    );
  }
}

class _PreferenceTags extends StatelessWidget {
  final List<PreferenceGroup> groups;
  final AppColors colors;
  final bool isDislike;

  const _PreferenceTags(
      {required this.groups, required this.colors, this.isDislike = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups
          .map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.category,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSub,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: group.items
                          .map((item) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDislike
                                      ? colors.softOrange
                                      : colors.softPurple,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDislike
                                        ? const Color(0xFFE17055)
                                        : colors.primary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
