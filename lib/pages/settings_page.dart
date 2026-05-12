import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/notification_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(themeStyleProvider);
    final isDark = ref.watch(themeModeProvider);
    final colors = AppColors.fromStyle(currentStyle, isDark: isDark);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Text('设置', style: theme.textTheme.headlineLarge),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 主题选择
              _SectionTitle(title: '主题颜色', icon: Icons.palette_rounded, colors: colors),
              const SizedBox(height: 12),
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: AppThemeStyle.values.map((style) {
                    final selected = style == currentStyle;
                    final c = AppColors.fromStyle(style);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(themeStyleProvider.notifier).state = style,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? c.primary.withAlpha(26) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? c.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [c.primary, c.secondary],
                                  ),
                                  border: selected ? Border.all(color: Colors.white, width: 3) : null,
                                  boxShadow: selected
                                      ? [BoxShadow(color: c.primary.withAlpha(100), blurRadius: 8, spreadRadius: 2)]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                style.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  color: selected ? c.primary : colors.textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 暗色模式
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onTap: () => ref.read(themeModeProvider.notifier).state = !isDark,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.softPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('暗色模式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textMain)),
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (v) => ref.read(themeModeProvider.notifier).state = v,
                      activeColor: colors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 通知提醒
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.softPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('生日和纪念日提醒', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textMain)),
                        ),
                        Switch(
                          value: ref.watch(notificationsEnabledProvider),
                          onChanged: (v) => _toggleNotifications(context, ref),
                          activeColor: colors.primary,
                        ),
                      ],
                    ),
                    if (ref.watch(notificationsEnabledProvider)) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _pickTime(context, ref, birthdayReminderTimeProvider, '生日和纪念日提醒时间'),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: colors.textSub),
                            const SizedBox(width: 8),
                            Text('提醒时间', style: TextStyle(fontSize: 13, color: colors.textSub)),
                            const Spacer(),
                            Text(
                              ref.watch(birthdayReminderTimeProvider),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.primary),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18, color: colors.textSub),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 定期联系提醒
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.softPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('定期联系提醒', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textMain)),
                              Text(
                                '超过 ${ref.watch(contactIntervalDaysProvider)} 天未联系时提醒',
                                style: TextStyle(fontSize: 12, color: colors.textSub),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: ref.watch(contactRemindersEnabledProvider),
                          onChanged: (v) => _toggleContactReminders(context, ref),
                          activeColor: colors.primary,
                        ),
                      ],
                    ),
                    if (ref.watch(contactRemindersEnabledProvider)) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('联系间隔', style: TextStyle(fontSize: 13, color: colors.textSub)),
                          Expanded(
                            child: Slider(
                              value: ref.watch(contactIntervalDaysProvider).toDouble(),
                              min: 7,
                              max: 90,
                              divisions: 83,
                              label: '${ref.watch(contactIntervalDaysProvider)} 天',
                              activeColor: colors.primary,
                              onChanged: (v) => ref.read(contactIntervalDaysProvider.notifier).state = v.toInt(),
                              onChangeEnd: (v) => _updateContactReminders(ref),
                            ),
                          ),
                          Text('${ref.watch(contactIntervalDaysProvider)} 天', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickTime(context, ref, contactReminderTimeProvider, '定期联系提醒时间'),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: colors.textSub),
                            const SizedBox(width: 8),
                            Text('提醒时间', style: TextStyle(fontSize: 13, color: colors.textSub)),
                            const Spacer(),
                            Text(
                              ref.watch(contactReminderTimeProvider),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.primary),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18, color: colors.textSub),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 回忆回顾提醒
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.softPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('回忆回顾提醒', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textMain)),
                              Text('回顾往年今天的美好时光', style: TextStyle(fontSize: 12, color: colors.textSub)),
                            ],
                          ),
                        ),
                        Switch(
                          value: ref.watch(memoryReviewRemindersEnabledProvider),
                          onChanged: (v) => _toggleMemoryReviewReminders(context, ref),
                          activeColor: colors.primary,
                        ),
                      ],
                    ),
                    if (ref.watch(memoryReviewRemindersEnabledProvider)) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _pickTime(context, ref, memoryReviewReminderTimeProvider, '回忆回顾提醒时间'),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: colors.textSub),
                            const SizedBox(width: 8),
                            Text('提醒时间', style: TextStyle(fontSize: 13, color: colors.textSub)),
                            const Spacer(),
                            Text(
                              ref.watch(memoryReviewReminderTimeProvider),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.primary),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18, color: colors.textSub),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 测试通知
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _sendTestNotification(context),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.softPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('发送测试通知', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textMain)),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: colors.textSub),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _SectionTitle(title: '自定义选项', icon: Icons.tune_rounded, colors: colors),
              const SizedBox(height: 12),

              // 自定义关系
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _editCustomOptions(context, ref, customRelationshipsProvider, '关系类型'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.softPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people_outline_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('自定义关系类型', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textMain)),
                          Text('管理人物关系选项', style: TextStyle(fontSize: 12, color: colors.textSub)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: colors.textSub),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 自定义心情
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _editCustomOptions(context, ref, customMoodsProvider, '心情标签'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.softPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.mood_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('自定义心情标签', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textMain)),
                          Text('管理记忆心情选项', style: TextStyle(fontSize: 12, color: colors.textSub)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: colors.textSub),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _SectionTitle(title: '数据管理', icon: Icons.storage_rounded, colors: colors),
              const SizedBox(height: 12),
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DataActionTile(
                      icon: Icons.upload_file_rounded,
                      title: '导出数据',
                      subtitle: '复制当前人物、地点和记忆 JSON 到剪贴板',
                      colors: colors,
                      onTap: () => _exportData(context, ref),
                    ),
                    Divider(height: 20, color: colors.line),
                    _DataActionTile(
                      icon: Icons.content_paste_rounded,
                      title: '从剪贴板恢复',
                      subtitle: '用剪贴板中的 LifeLog JSON 覆盖本地数据',
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
              const SizedBox(height: 28),

              _SectionTitle(title: '关于', icon: Icons.info_rounded, colors: colors),
              const SizedBox(height: 12),
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: colors.primaryGradient,
                        boxShadow: [colors.avatarShadow],
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LifeLog',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.1.0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '记录生活中的美好瞬间',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSub,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: colors.line),
                    const SizedBox(height: 16),
                    _AboutRow(
                      icon: Icons.palette_rounded,
                      label: '设计',
                      value: 'Material Design 3 + Glass UI',
                      colors: colors,
                    ),
                    const SizedBox(height: 12),
                    _AboutRow(
                      icon: Icons.code_rounded,
                      label: '技术栈',
                      value: 'Flutter 3.24 + Riverpod',
                      colors: colors,
                    ),
                    const SizedBox(height: 12),
                    _AboutRow(
                      icon: Icons.storage_rounded,
                      label: '数据存储',
                      value: 'Drift (SQLite)',
                      colors: colors,
                    ),
                    const SizedBox(height: 12),
                    _AboutRow(
                      icon: Icons.developer_mode_rounded,
                      label: '开发者',
                      value: 'cnxin',
                      colors: colors,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '© 2025 LifeLog. All rights reserved.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // M3 组件展示
              _SectionTitle(title: '组件展示', icon: Icons.widgets_rounded, colors: colors),
              const SizedBox(height: 12),

              // 按钮
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('按钮', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSub)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _GradientButton(label: '渐变按钮', colors: colors),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Outlined', style: TextStyle(color: colors.primary)),
                        ),
                        TextButton(onPressed: () {}, child: Text('Text', style: TextStyle(color: colors.primary))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 标签
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('标签', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSub)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['火锅', '咖啡', '电影', '散步', '寿司'].map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.softPurple,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary)),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['花生', '香菜', '太辣'].map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.softOrange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE17055))),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 色彩方案
              GlassCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('色彩方案', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSub)),
                    const SizedBox(height: 12),
                    _ColorSwatch('Primary', colors.primary),
                    _ColorSwatch('Primary Light', colors.primaryLight),
                    _ColorSwatch('Secondary', colors.secondary),
                    _ColorSwatch('Background', colors.bgColor),
                    _ColorSwatch('Text', colors.textMain),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: Text(
                  'LifeLog Flutter Demo v0.1.0\nMaterial Design 3 + Glass UI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.textSub),
                ),
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(databaseProvider).exportJson();
    await Clipboard.setData(ClipboardData(text: data));
    if (context.mounted) _showMessage(context, '已复制 JSON 数据到剪贴板');
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: '从剪贴板恢复？',
      content: '这会覆盖当前本地数据，请确认剪贴板中是 LifeLog JSON。',
    );
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
    final confirmed = await _confirm(
      context,
      title: '重置演示数据？',
      content: '这会清空当前本地数据并恢复内置示例。',
    );
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

  Future<void> _toggleNotifications(BuildContext context, WidgetRef ref) async {
    final current = ref.read(notificationsEnabledProvider);

    if (!current) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        if (context.mounted) _showMessage(context, '通知权限未授予');
        return;
      }
      ref.read(notificationsEnabledProvider.notifier).state = true;
      final people = ref.read(peopleProvider).valueOrNull ?? [];
      final reminderTime = ref.read(birthdayReminderTimeProvider);
      await NotificationService().schedulePersonReminders(people, reminderTime: reminderTime);
      if (context.mounted) _showMessage(context, '已开启生日和纪念日提醒');
    } else {
      ref.read(notificationsEnabledProvider.notifier).state = false;
      await NotificationService().cancelAll();
      if (context.mounted) _showMessage(context, '已关闭提醒');
    }
  }

  Future<void> _toggleContactReminders(BuildContext context, WidgetRef ref) async {
    final current = ref.read(contactRemindersEnabledProvider);

    if (!current) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        if (context.mounted) _showMessage(context, '通知权限未授予');
        return;
      }
      ref.read(contactRemindersEnabledProvider.notifier).state = true;
      final people = ref.read(peopleProvider).valueOrNull ?? [];
      final memories = ref.read(memoriesProvider).valueOrNull ?? [];
      final intervalDays = ref.read(contactIntervalDaysProvider);
      final reminderTime = ref.read(contactReminderTimeProvider);
      await NotificationService().scheduleContactReminders(people, memories, intervalDays, reminderTime: reminderTime);
      if (context.mounted) _showMessage(context, '已开启定期联系提醒');
    } else {
      ref.read(contactRemindersEnabledProvider.notifier).state = false;
      if (context.mounted) _showMessage(context, '已关闭定期联系提醒');
    }
  }

  Future<void> _toggleMemoryReviewReminders(BuildContext context, WidgetRef ref) async {
    final current = ref.read(memoryReviewRemindersEnabledProvider);

    if (!current) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        if (context.mounted) _showMessage(context, '通知权限未授予');
        return;
      }
      ref.read(memoryReviewRemindersEnabledProvider.notifier).state = true;
      final memories = ref.read(memoriesProvider).valueOrNull ?? [];
      final reminderTime = ref.read(memoryReviewReminderTimeProvider);
      await NotificationService().scheduleMemoryReviewReminders(memories, reminderTime: reminderTime);
      if (context.mounted) _showMessage(context, '已开启回忆回顾提醒');
    } else {
      ref.read(memoryReviewRemindersEnabledProvider.notifier).state = false;
      if (context.mounted) _showMessage(context, '已关闭回忆回顾提醒');
    }
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    final granted = await NotificationService().requestPermissions();
    if (!granted) {
      if (context.mounted) _showMessage(context, '通知权限未授予，请先授予权限');
      return;
    }
    await NotificationService().sendTestNotification();
    if (context.mounted) _showMessage(context, '测试通知已发送');
  }

  Future<void> _updateContactReminders(WidgetRef ref) async {
    if (ref.read(contactRemindersEnabledProvider)) {
      final people = ref.read(peopleProvider).valueOrNull ?? [];
      final memories = ref.read(memoriesProvider).valueOrNull ?? [];
      final intervalDays = ref.read(contactIntervalDaysProvider);
      final reminderTime = ref.read(contactReminderTimeProvider);
      await NotificationService().scheduleContactReminders(people, memories, intervalDays, reminderTime: reminderTime);
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref, StateProvider<String> provider, String title) async {
    final currentTime = ref.read(provider);
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref.read(provider.notifier).state = newTime;

      // 更新对应的提醒
      if (provider == birthdayReminderTimeProvider && ref.read(notificationsEnabledProvider)) {
        final people = ref.read(peopleProvider).valueOrNull ?? [];
        await NotificationService().schedulePersonReminders(people, reminderTime: newTime);
        if (context.mounted) _showMessage(context, '已更新生日和纪念日提醒时间');
      } else if (provider == contactReminderTimeProvider && ref.read(contactRemindersEnabledProvider)) {
        await _updateContactReminders(ref);
        if (context.mounted) _showMessage(context, '已更新定期联系提醒时间');
      } else if (provider == memoryReviewReminderTimeProvider && ref.read(memoryReviewRemindersEnabledProvider)) {
        final memories = ref.read(memoriesProvider).valueOrNull ?? [];
        await NotificationService().scheduleMemoryReviewReminders(memories, reminderTime: newTime);
        if (context.mounted) _showMessage(context, '已更新回忆回顾提醒时间');
      }
    }
  }

  Future<void> _editCustomOptions(BuildContext context, WidgetRef ref, StateProvider<List<String>> provider, String title) async {
    final colors = AppColors.fromStyle(ref.read(themeStyleProvider));
    final currentOptions = List<String>.from(ref.read(provider));
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('编辑$title'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: '输入新选项',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: colors.primary),
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty && !currentOptions.contains(text)) {
                          setState(() => currentOptions.add(text));
                          controller.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currentOptions.length,
                    itemBuilder: (context, index) {
                      final option = currentOptions[index];
                      return ListTile(
                        title: Text(option),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFE17055)),
                          onPressed: () {
                            if (currentOptions.length > 1) {
                              setState(() => currentOptions.removeAt(index));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('至少保留一个选项')),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(provider.notifier).state = currentOptions;
                Navigator.pop(ctx);
                _showMessage(context, '已更新$title');
              },
              child: const Text('保存'),
            ),
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

  const _DataActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.danger = false,
  });

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
              borderRadius: BorderRadius.circular(14),
            ),
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

class _GradientButton extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _GradientButton({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: colors.primaryGradient,
        boxShadow: [colors.fabShadow],
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorSwatch(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSub,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textMain,
          ),
        ),
      ],
    );
  }
}
