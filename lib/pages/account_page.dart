import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.fromStyle(ref.watch(themeStyleProvider), isDark: ref.watch(themeModeProvider));
    final people = ref.watch(peopleProvider).valueOrNull ?? [];
    final places = ref.watch(placesProvider).valueOrNull ?? [];
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];

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
                      IconButton(icon: Icon(Icons.arrow_back_ios_new, size: 20, color: colors.textMain), onPressed: () => context.pop()),
                      Expanded(child: Text('账号管理', style: Theme.of(context).textTheme.headlineLarge)),
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
                        GradientAvatar(name: 'L', size: 54, borderRadius: 18, colors: colors),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LifeLog · 本地账号', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textMain)),
                              const SizedBox(height: 4),
                              Text('资料保存在本设备，完整备份可用于 Android 与 iOS 间迁移。', style: TextStyle(fontSize: 13, height: 1.35, color: colors.textSub)),
                            ],
                          ),
                        ),
                        Icon(Icons.verified_user_rounded, color: colors.primary, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: '数据管理', icon: Icons.storage_rounded, colors: colors),
                  const SizedBox(height: 12),
                  GlassCard(
                    colors: colors,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _Metric(value: '${people.length}', label: '人物', colors: colors),
                            const SizedBox(width: 10),
                            _Metric(value: '${places.length}', label: '地点', colors: colors),
                            const SizedBox(width: 10),
                            _Metric(value: '${memories.length}', label: '回忆', colors: colors),
                          ],
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
                          subtitle: '支持 React 0.1.0-test.42 完整备份和 Flutter 旧备份',
                          colors: colors,
                          onTap: () => _importData(context, ref),
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
                  _SectionTitle(title: '关于', icon: Icons.info_rounded, colors: colors),
                  const SizedBox(height: 12),
                  GlassCard(
                    colors: colors,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: colors.primaryGradient, boxShadow: [colors.avatarShadow]),
                          child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 14),
                        Text('LifeLog', style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800, color: colors.textMain)),
                        const SizedBox(height: 4),
                        Text('0.2.0 · Flutter 双端版', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.primary)),
                        const SizedBox(height: 18),
                        _AboutRow(icon: Icons.phone_android_rounded, label: '移动端', value: 'Android / iOS', colors: colors),
                        const SizedBox(height: 12),
                        _AboutRow(icon: Icons.code_rounded, label: '技术栈', value: 'Flutter + Riverpod', colors: colors),
                        const SizedBox(height: 12),
                        _AboutRow(icon: Icons.storage_rounded, label: '存储', value: 'Drift (SQLite)', colors: colors),
                        const SizedBox(height: 12),
                        _AboutRow(icon: Icons.backup_rounded, label: '备份', value: 'schema v3', colors: colors),
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

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(context, title: '从剪贴板恢复？', content: '这会覆盖当前本地数据，请先确认剪贴板中是 LifeLog 备份 JSON。');
    if (!confirmed) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (context.mounted) _showMessage(context, '剪贴板没有可恢复的数据');
      return;
    }
    try {
      await ref.read(databaseProvider).importJson(text);
      _refreshData(ref);
      if (context.mounted) _showMessage(context, '数据已恢复');
    } catch (_) {
      if (context.mounted) _showMessage(context, '恢复失败：JSON 格式不正确');
    }
  }

  Future<void> _resetData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(context, title: '重置演示数据？', content: '这会清空当前本地数据并恢复内置示例。');
    if (!confirmed) return;
    await ref.read(databaseProvider).resetSeedData();
    _refreshData(ref);
    if (context.mounted) _showMessage(context, '已重置为演示数据');
  }

  void _refreshData(WidgetRef ref) {
    ref.invalidate(peopleProvider);
    ref.invalidate(placesProvider);
    ref.invalidate(memoriesProvider);
  }

  Future<bool> _confirm(BuildContext context, {required String title, required String content}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('确认')),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final AppColors colors;

  const _Metric({required this.value, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: colors.softPurple, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w800, color: colors.primary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: colors.textSub)),
          ],
        ),
      ),
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

  const _DataActionTile({required this.icon, required this.title, required this.subtitle, required this.colors, required this.onTap, this.danger = false});

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
            decoration: BoxDecoration(color: danger ? colors.softOrange : colors.softPurple, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: danger ? accent : colors.textMain)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textSub)),
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

  const _SectionTitle({required this.title, required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600, color: colors.textMain)),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;

  const _AboutRow({required this.icon, required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSub)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textMain)),
      ],
    );
  }
}
