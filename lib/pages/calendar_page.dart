import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/person.dart';
import '../models/lifelog_models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/lunar_utils.dart';
import '../widgets/glass_card.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _showLunar = true;

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final placesAsync = ref.watch(placesProvider);
    final memoriesAsync = ref.watch(memoriesProvider);
    final colors = ref.watch(appColorsProvider);
    final people = peopleAsync.valueOrNull;
    final places = placesAsync.valueOrNull;
    final memories = memoriesAsync.valueOrNull;

    if (people == null || places == null || memories == null) {
      if (peopleAsync.hasError) {
        return Center(child: Text('${peopleAsync.error}'));
      }
      if (placesAsync.hasError) {
        return Center(child: Text('${placesAsync.error}'));
      }
      if (memoriesAsync.hasError) {
        return Center(child: Text('${memoriesAsync.error}'));
      }
      return const Center(child: CircularProgressIndicator());
    }

    final events = _monthEvents(people, places, memories, _focusedMonth);
    final selectedEvents =
        events.where((event) => _sameDate(event.date, _selectedDate)).toList();
    final grouped = <int, List<_CalendarEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.date.day, () => []).add(event);
    }
    final lunar = getCalendarLunarInfo(_selectedDate);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                children: [
                  Expanded(
                      child: Text('日历',
                          style: Theme.of(context).textTheme.headlineLarge)),
                  _MonthButton(
                      icon: Icons.chevron_left_rounded,
                      colors: colors,
                      onTap: () => _shiftMonth(-1)),
                  const SizedBox(width: 8),
                  _MonthButton(
                      icon: Icons.chevron_right_rounded,
                      colors: colors,
                      onTap: () => _shiftMonth(1)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GlassCard(
              colors: colors,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: colors.primaryGradient,
                            boxShadow: [colors.avatarShadow]),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                DateFormat('yyyy年 M月', 'zh_CN')
                                    .format(_focusedMonth),
                                style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textMain)),
                            const SizedBox(height: 4),
                            Text(lunar.ganZhiZodiacText,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textMain)),
                            const SizedBox(height: 2),
                            Text('${lunar.weekText} ${lunar.weekOfYearText}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textSub)),
                            const SizedBox(height: 2),
                            Text(lunar.lunarText,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showLunar = !_showLunar),
                        child: Text(_showLunar ? '隐藏农历' : '显示农历',
                            style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _CalendarGrid(
                    month: _focusedMonth,
                    selectedDate: _selectedDate,
                    eventsByDay: grouped,
                    showLunar: _showLunar,
                    colors: colors,
                    onSelect: (date) => setState(() => _selectedDate = date),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            child: Row(
              children: [
                Icon(Icons.event_note_rounded, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text('选中日期',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textMain)),
                const SizedBox(width: 8),
                Text(DateFormat('M月d日', 'zh_CN').format(_selectedDate),
                    style: TextStyle(fontSize: 13, color: colors.textSub)),
              ],
            ),
          ),
        ),
        if (selectedEvents.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                  colors: colors,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                      child: Text('这一天还没有记录。',
                          style: TextStyle(color: colors.textSub)))),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.separated(
              itemCount: selectedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _EventCard(event: selectedEvents[i], colors: colors),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  List<_CalendarEvent> _monthEvents(List<Person> people, List<Place> places,
      List<MemoryEvent> memories, DateTime month) {
    final events = <_CalendarEvent>[];
    for (final person in people) {
      if (person.birthday != null) {
        final birthday = DateTime.tryParse(person.birthday!);
        if (birthday != null) {
          final date = DateTime(month.year, birthday.month, birthday.day);
          if (date.month == month.month) {
            final lunar = getCalendarLunarInfo(date);
            events.add(_CalendarEvent(
              date: date,
              title: '${person.name} 的生日',
              subtitle: person.relationship,
              subtitleLines: [
                lunar.ganZhiZodiacText,
                '${lunar.weekText} ${lunar.weekOfYearText}',
                lunar.lunarText
              ],
              type: _EventType.birthday,
              target: '/people/${person.id}',
            ));
          }
        }
      }
      for (final anniversary in person.anniversaries) {
        final original = DateTime.tryParse(anniversary.date);
        if (original != null) {
          final date = DateTime(month.year, original.month, original.day);
          if (date.month == month.month) {
            final lunar = getCalendarLunarInfo(date);
            events.add(_CalendarEvent(
              date: date,
              title: '${person.name} · ${anniversary.title}',
              subtitle: person.name,
              subtitleLines: [
                lunar.ganZhiZodiacText,
                '${lunar.weekText} ${lunar.weekOfYearText}',
                lunar.lunarText
              ],
              type: _EventType.anniversary,
              target: '/people/${person.id}',
            ));
          }
        }
      }
    }
    for (final memory in memories) {
      final date = DateTime.tryParse(memory.date);
      if (date != null &&
          date.year == month.year &&
          date.month == month.month) {
        final personNames = people
            .where((p) => memory.personIds.contains(p.id))
            .map((p) => p.name)
            .toList();
        final place = places.where((p) => p.id == memory.placeId).firstOrNull;
        events.add(_CalendarEvent(
          date: date,
          title: memoryDisplayTitle(memory.title, memory.content),
          subtitle: [personNames.join('、'), place?.name ?? '']
              .where((item) => item.isNotEmpty)
              .join(' · '),
          content:
              isManualMemoryTitle(memory.title) ? memory.content.trim() : '',
          tags: [memory.mood, ...memory.tags]
              .where((item) => item.trim().isNotEmpty)
              .toList(),
          type: _EventType.memory,
          target: '/memories/${memory.id}',
        ));
      }
    }
    events.sort((a, b) {
      final byDay = a.date.day.compareTo(b.date.day);
      if (byDay != 0) return byDay;
      return a.title.compareTo(b.title);
    });
    return events;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final AppColors colors;
  final VoidCallback onTap;

  const _MonthButton(
      {required this.icon, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.line)),
        child: Icon(icon, color: colors.primary, size: 24),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Map<int, List<_CalendarEvent>> eventsByDay;
  final bool showLunar;
  final AppColors colors;
  final ValueChanged<DateTime> onSelect;

  const _CalendarGrid(
      {required this.month,
      required this.selectedDate,
      required this.eventsByDay,
      required this.showLunar,
      required this.colors,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = firstDay.weekday % 7;
    final cells = leading + daysInMonth;
    final totalCells = cells <= 35 ? 35 : 42;

    return Column(
      children: [
        Row(
          children: ['日', '一', '二', '三', '四', '五', '六']
              .map((label) => Expanded(
                  child: Center(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textSub)))))
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemBuilder: (_, index) {
            final day = index - leading + 1;
            final inMonth = day >= 1 && day <= daysInMonth;
            if (!inMonth) return const SizedBox();
            final date = DateTime(month.year, month.month, day);
            final selected = date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;
            final hasEvent = eventsByDay.containsKey(day);
            final lunar = showLunar ? getCalendarLunarInfo(date) : null;
            return GestureDetector(
              onTap: () => onSelect(date),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary
                      : (hasEvent ? colors.softPurple : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: hasEvent && !selected
                      ? Border.all(color: colors.primary.withAlpha(64))
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : (hasEvent
                                    ? colors.primary
                                    : colors.textMain))),
                    if (lunar != null) ...[
                      const SizedBox(height: 1),
                      Text(lunar.cellText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white.withAlpha(215)
                                  : colors.textSub)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final _CalendarEvent event;
  final AppColors colors;

  const _EventCard({required this.event, required this.colors});

  @override
  Widget build(BuildContext context) {
    final icon = switch (event.type) {
      _EventType.birthday => Icons.cake_rounded,
      _EventType.anniversary => Icons.favorite_rounded,
      _EventType.memory => Icons.auto_stories_rounded,
    };
    final tint =
        event.type == _EventType.memory ? colors.softPurple : colors.softOrange;

    return GlassCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      onTap: event.target.isEmpty ? null : () => context.push(event.target),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: tint, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text('${event.date.day}',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textMain)),
                if (event.subtitleLines.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  ...event.subtitleLines.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(line,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: line == event.subtitleLines.first
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: line == event.subtitleLines.first
                                    ? colors.textMain
                                    : colors.textSub)),
                      )),
                ] else ...[
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(event.subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textSub)),
                  ],
                  if (event.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(event.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: colors.textMain)),
                  ],
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: event.tags
                            .map((tag) => _Tag(label: tag, colors: colors))
                            .toList()),
                  ],
                ],
              ],
            ),
          ),
          Icon(icon, color: colors.primary, size: 21),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _Tag({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: colors.softPurple, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.primary)),
    );
  }
}

enum _EventType { birthday, anniversary, memory }

class _CalendarEvent {
  final DateTime date;
  final String title;
  final String subtitle;
  final List<String> subtitleLines;
  final String content;
  final List<String> tags;
  final _EventType type;
  final String target;

  const _CalendarEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    this.subtitleLines = const [],
    this.content = '',
    this.tags = const [],
    required this.type,
    this.target = '',
  });
}
