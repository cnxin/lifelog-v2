import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/lifelog_models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/lunar_utils.dart';
import '../widgets/glass_card.dart';
import '../widgets/photo_viewer.dart';

class MemoryDetailPage extends ConsumerWidget {
  final String memoryId;
  const MemoryDetailPage({super.key, required this.memoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final isDark = ref.watch(themeModeProvider);
    final colors = ref.watch(appColorsProvider);
    final memory = memories.where((m) => m.id == memoryId).firstOrNull;

    if (memory == null) {
      return GradientBackground(
          colors: colors,
          isDark: isDark,
          child: const Scaffold(body: Center(child: Text('记忆不存在'))));
    }

    final personNames = people
        .where((p) => memory.personIds.contains(p.id))
        .map((p) => p.name)
        .toList();
    final place = places.where((p) => p.id == memory.placeId).firstOrNull;
    final title = memoryDisplayTitle(memory.title, memory.content);
    final content = memory.content.trim();
    final tags = [memory.mood, ...memory.tags]
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return GradientBackground(
      colors: colors,
      isDark: isDark,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back_ios_new,
                              size: 20, color: colors.textMain),
                          onPressed: () => context.pop()),
                      const Spacer(),
                      IconButton(
                          icon: Icon(Icons.edit, color: colors.textSub),
                          onPressed: () =>
                              context.push('/memories/${memory.id}/edit')),
                      IconButton(
                          icon:
                              Icon(Icons.delete_outline, color: colors.textSub),
                          onPressed: () => _delete(context, ref, memory)),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: colors.primaryGradient,
                        boxShadow: [colors.avatarShadow]),
                    child: const Icon(Icons.auto_stories_rounded,
                        color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 20),
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: colors.textMain)),
                  const SizedBox(height: 18),
                  _InfoCard(
                      title: '基础信息',
                      icon: Icons.info_rounded,
                      colors: colors,
                      child: _MemoryMeta(
                          date: memory.date,
                          people: personNames,
                          placeName: place?.name ?? '',
                          colors: colors)),
                  if (memory.photos.isNotEmpty)
                    _InfoCard(
                        title: '照片',
                        icon: Icons.photo_library_rounded,
                        colors: colors,
                        child:
                            _PhotoGrid(photos: memory.photos, colors: colors)),
                  if (content.isNotEmpty)
                    _InfoCard(
                        title: '内容',
                        icon: Icons.notes_rounded,
                        colors: colors,
                        child: Text(content,
                            style: TextStyle(
                                color: colors.textMain, height: 1.55))),
                  if (tags.isNotEmpty)
                    _InfoCard(
                        title: '标签',
                        icon: Icons.sell_rounded,
                        colors: colors,
                        child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: tags
                                .map((tag) => _Tag(
                                    label: tag,
                                    colors: colors,
                                    accent: tag == memory.mood))
                                .toList())),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, MemoryEvent memory) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认删除'),
        content: Text(
            '确定要删除 ${memoryDisplayTitle(memory.title, memory.content)} 吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(memoriesProvider.notifier).deleteMemory(memory.id);
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

class _MemoryMeta extends StatelessWidget {
  final String date;
  final List<String> people;
  final String placeName;
  final AppColors colors;

  const _MemoryMeta(
      {required this.date,
      required this.people,
      required this.placeName,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _MetaRow(
          icon: Icons.calendar_today_rounded,
          label: '日期',
          value: date,
          colors: colors),
      if (people.isNotEmpty)
        _MetaRow(
            icon: Icons.people_rounded,
            label: '人物',
            value: people.join('、'),
            colors: colors),
      if (placeName.isNotEmpty)
        _MetaRow(
            icon: Icons.place_rounded,
            label: '地点',
            value: placeName,
            colors: colors),
    ];
    return Column(
        children: rows
            .expand((row) =>
                [row, if (row != rows.last) const SizedBox(height: 10)])
            .toList());
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;

  const _MetaRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textSub),
        const SizedBox(width: 8),
        SizedBox(
            width: 42,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSub))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textMain))),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppColors colors;
  final Widget child;
  const _InfoCard(
      {required this.title,
      required this.icon,
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
            Row(children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.primary))
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;
  final AppColors colors;

  const _PhotoGrid({required this.photos, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoViewer(
              photos: photos,
              initialIndex: index,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: colors.softPurple,
            child: _isLocalFile(photos[index])
                ? Image.file(
                    File(photos[index]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.broken_image_rounded, color: colors.primary),
                  )
                : Image.network(
                    photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.broken_image_rounded, color: colors.primary),
                  ),
          ),
        ),
      ),
    );
  }

  bool _isLocalFile(String path) {
    return path.startsWith('/') ||
        path.contains(':\\') ||
        !path.startsWith('http');
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final AppColors colors;
  final bool accent;
  const _Tag({required this.label, required this.colors, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: accent ? colors.softOrange : colors.softPurple,
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent ? const Color(0xFFE17055) : colors.primary)),
    );
  }
}
