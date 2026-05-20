import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/backup_preview.dart';
import '../widgets/glass_card.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.fromStyle(ref.watch(themeStyleProvider),
        isDark: ref.watch(themeModeProvider));
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final placeMergeHistory =
        ref.watch(placeMergeHistoryProvider).valueOrNull ?? [];
    final localPhotoCount =
        memories.fold<int>(0, (sum, memory) => sum + memory.photos.length);

    return GradientBackground(
      colors: colors,
      isDark: ref.watch(themeModeProvider),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
                  child: Row(
                    children: [
                      IconButton(
                          icon: Icon(Icons.arrow_back_ios_new,
                              size: 20, color: colors.textMain),
                          onPressed: () => context.pop()),
                      Expanded(
                          child: Text('账号管理',
                              style:
                                  Theme.of(context).textTheme.headlineLarge)),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GlassCard(
                    colors: colors,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GradientAvatar(
                            name: 'L',
                            size: 54,
                            borderRadius: 18,
                            colors: colors),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LifeLog · 本地账号',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textMain)),
                              const SizedBox(height: 4),
                              Text('资料保存在本设备，完整备份可用于 Android 与 iOS 间迁移。',
                                  style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: colors.textSub)),
                            ],
                          ),
                        ),
                        Icon(Icons.verified_user_rounded,
                            color: colors.primary, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                      title: '数据管理',
                      icon: Icons.storage_rounded,
                      colors: colors),
                  const SizedBox(height: 12),
                  GlassCard(
                    colors: colors,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _Metric(
                                value: '${people.length}',
                                label: '人物',
                                colors: colors),
                            const SizedBox(width: 10),
                            _Metric(
                                value: '${places.length}',
                                label: '地点',
                                colors: colors),
                            const SizedBox(width: 10),
                            _Metric(
                                value: '${memories.length}',
                                label: '回忆',
                                colors: colors),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _BackupHealthSummary(
                          photoCount: localPhotoCount,
                          placeMergeHistoryCount: placeMergeHistory.length,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),
                        _DataActionTile(
                          icon: Icons.upload_file_rounded,
                          title: '导出完整备份',
                          subtitle: '复制人物、地点、回忆、设置和提醒 JSON 到剪贴板',
                          colors: colors,
                          onTap: () => _exportData(context, ref),
                        ),
                        Divider(height: 20, color: colors.line),
                        _DataActionTile(
                          icon: Icons.content_paste_rounded,
                          title: '从剪贴板恢复',
                          subtitle: '先预览备份内容，确认后再覆盖当前本地数据',
                          colors: colors,
                          onTap: () => _importData(context, ref, colors),
                        ),
                        Divider(height: 20, color: colors.line),
                        _DataActionTile(
                          icon: Icons.restart_alt_rounded,
                          title: '重置演示数据',
                          subtitle: '清空当前数据并恢复内置示例',
                          colors: colors,
                          danger: true,
                          onTap: () => _resetData(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                      title: '关于', icon: Icons.info_rounded, colors: colors),
                  const SizedBox(height: 12),
                  GlassCard(
                    colors: colors,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: colors.primaryGradient,
                              boxShadow: [colors.avatarShadow]),
                          child: const Icon(Icons.auto_stories_rounded,
                              color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 14),
                        Text('LifeLog',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: colors.textMain)),
                        const SizedBox(height: 4),
                        Text('0.3.0 · Flutter 双端版',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.primary)),
                        const SizedBox(height: 18),
                        _AboutRow(
                            icon: Icons.phone_android_rounded,
                            label: '移动端',
                            value: 'Android / iOS',
                            colors: colors),
                        const SizedBox(height: 12),
                        _AboutRow(
                            icon: Icons.code_rounded,
                            label: '技术栈',
                            value: 'Flutter + Riverpod',
                            colors: colors),
                        const SizedBox(height: 12),
                        _AboutRow(
                            icon: Icons.storage_rounded,
                            label: '存储',
                            value: 'Drift (SQLite)',
                            colors: colors),
                        const SizedBox(height: 12),
                        _AboutRow(
                            icon: Icons.backup_rounded,
                            label: '备份',
                            value: 'schema v3',
                            colors: colors),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(databaseProvider).exportJson();
    await Clipboard.setData(ClipboardData(text: data));
    if (context.mounted) _showMessage(context, '已复制完整备份到剪贴板');
  }

  Future<void> _importData(
      BuildContext context, WidgetRef ref, AppColors colors) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (context.mounted) _showMessage(context, '剪贴板没有可恢复的数据');
      return;
    }
    BackupPreview preview;
    try {
      preview = parseBackupPreview(text);
    } catch (_) {
      if (context.mounted) _showMessage(context, '恢复失败：JSON 格式不正确');
      return;
    }
    if (!context.mounted) return;
    final confirmed = await _confirmImportPreview(context, preview, colors);
    if (!confirmed) return;
    try {
      await ref.read(databaseProvider).importJson(text);
      await loadPersistedPreferences(ref);
      _refreshData(ref);
      if (context.mounted) _showMessage(context, '数据已恢复');
    } catch (_) {
      if (context.mounted) _showMessage(context, '恢复失败：JSON 格式不正确');
    }
  }

  Future<void> _resetData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(context,
        title: '重置演示数据？', content: '这会清空当前本地数据并恢复内置示例。');
    if (!confirmed) return;
    await ref.read(databaseProvider).resetSeedData();
    _refreshData(ref);
    if (context.mounted) _showMessage(context, '已重置为演示数据');
  }

  void _refreshData(WidgetRef ref) {
    ref.invalidate(peopleProvider);
    ref.invalidate(placesProvider);
    ref.invalidate(memoriesProvider);
    ref.invalidate(placeMergeHistoryProvider);
  }

  Future<bool> _confirmImportPreview(
      BuildContext context, BackupPreview preview, AppColors colors) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认恢复备份？'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preview.sourceLabel} · schema v${preview.backup.schemaVersion}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.primary),
                  ),
                  if (preview.backup.exportedAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('导出时间：${preview.backup.exportedAt}',
                        style: TextStyle(fontSize: 12, color: colors.textSub)),
                  ],
                  const SizedBox(height: 14),
                  _ImportPreviewGrid(preview: preview, colors: colors),
                  const SizedBox(height: 12),
                  _PreviewFlagRow(
                    icon: Icons.settings_rounded,
                    label: '设置',
                    enabled: preview.hasSettings,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _PreviewFlagRow(
                    icon: Icons.notifications_active_rounded,
                    label: '提醒配置',
                    enabled: preview.hasReminderSettings,
                    colors: colors,
                  ),
                  if (preview.warnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...preview.warnings.map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          warning,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFE17055)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '确认后会覆盖当前设备上的人物、地点、回忆、设置、提醒和地点合并历史。',
                    style: TextStyle(
                        fontSize: 12, height: 1.4, color: colors.textSub),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('恢复')),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirm(BuildContext context,
      {required String title, required String content}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('确认')),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final AppColors colors;

  const _Metric(
      {required this.value, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: colors.softPurple, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.primary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: colors.textSub)),
          ],
        ),
      ),
    );
  }
}

class _BackupHealthSummary extends StatelessWidget {
  final int photoCount;
  final int placeMergeHistoryCount;
  final AppColors colors;

  const _BackupHealthSummary({
    required this.photoCount,
    required this.placeMergeHistoryCount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.softOrange,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.line),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _HealthChip(
              icon: Icons.photo_library_rounded,
              label: '照片索引 $photoCount',
              colors: colors),
          _HealthChip(
              icon: Icons.merge_type_rounded,
              label: '合并历史 $placeMergeHistoryCount',
              colors: colors),
          _HealthChip(
              icon: Icons.verified_rounded,
              label: '备份 schema v3',
              colors: colors),
        ],
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _HealthChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.primary),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textMain)),
      ],
    );
  }
}

class _ImportPreviewGrid extends StatelessWidget {
  final BackupPreview preview;
  final AppColors colors;

  const _ImportPreviewGrid({required this.preview, required this.colors});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('人物', preview.peopleCount),
      ('地点', preview.placesCount),
      ('回忆', preview.memoriesCount),
      ('照片', preview.photoCount),
      ('合并历史', preview.placeMergeHistoryCount),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              width: 86,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: colors.softPurple,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.$2}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.primary)),
                  const SizedBox(height: 2),
                  Text(item.$1,
                      style: TextStyle(fontSize: 12, color: colors.textSub)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewFlagRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final AppColors colors;

  const _PreviewFlagRow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: enabled ? colors.primary : colors.textSub),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: colors.textMain))),
        Text(
          enabled ? '包含' : '未包含',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: enabled ? colors.primary : colors.textSub,
          ),
        ),
      ],
    );
  }
}

class _DataActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;
  final bool danger;
  final VoidCallback onTap;

  const _DataActionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.colors,
      required this.onTap,
      this.danger = false});

  @override
  Widget build(BuildContext context) {
    final accent = danger ? const Color(0xFFE17055) : colors.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: danger ? colors.softOrange : colors.softPurple,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: danger ? accent : colors.textMain)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSub)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textSub, size: 22),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppColors colors;

  const _SectionTitle(
      {required this.title, required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textMain)),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;

  const _AboutRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSub)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textMain)),
      ],
    );
  }
}
