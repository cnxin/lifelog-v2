import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import '../theme/app_theme.dart';

class CustomDateTimePicker extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay? initialTime;
  final Function(DateTime date, TimeOfDay? time) onConfirm;
  final AppColors colors;
  final bool includeTime;

  const CustomDateTimePicker({
    super.key,
    required this.initialDate,
    this.initialTime,
    required this.onConfirm,
    required this.colors,
    this.includeTime = true,
  });

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

Future<void> showLifeLogDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  required AppColors colors,
  required Function(DateTime date, TimeOfDay? time) onConfirm,
  TimeOfDay? initialTime,
  bool includeTime = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (context) => CustomDateTimePicker(
      initialDate: initialDate,
      initialTime: initialTime,
      colors: colors,
      includeTime: includeTime,
      onConfirm: onConfirm,
    ),
  );
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late int _pendingYear;
  late int _pendingMonth;
  bool _showLunar = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _pendingYear = _selectedDate.year;
    _pendingMonth = _selectedDate.month;
  }

  bool get _hasPendingYearMonth => _pendingYear != _selectedDate.year || _pendingMonth != _selectedDate.month;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottomPadding),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            color: widget.colors.cardSolid,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: widget.colors.softPurple),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(48), blurRadius: 64, offset: const Offset(0, 26)),
              BoxShadow(color: widget.colors.softPurple, blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildWheelPicker(),
                const SizedBox(height: 10),
                _buildWheelActions(),
                const SizedBox(height: 10),
                _buildLunarToggle(),
                if (_showLunar) ...[
                  const SizedBox(height: 10),
                  _buildLunarSummary(),
                ],
                const SizedBox(height: 14),
                _buildWeekdayHeader(),
                const SizedBox(height: 8),
                _buildDaysGrid(),
                if (widget.includeTime) ...[
                  const SizedBox(height: 16),
                  _buildTimeRow(),
                ],
                const SizedBox(height: 24),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _IconButton(icon: Icons.chevron_left_rounded, colors: widget.colors, onTap: () => _moveMonth(-1)),
        Expanded(
          child: Column(
            children: [
              Text(
                '${_selectedDate.year}年 ${_selectedDate.month}月',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: widget.colors.textMain),
              ),
              const SizedBox(height: 3),
              Text(
                '${_selectedDate.day}日 · 周${'一二三四五六日'[_selectedDate.weekday - 1]}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: widget.colors.primary),
              ),
            ],
          ),
        ),
        _IconButton(icon: Icons.chevron_right_rounded, colors: widget.colors, onTap: () => _moveMonth(1)),
      ],
    );
  }

  Widget _buildWheelPicker() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: widget.colors.softPurple, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            right: 8,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: widget.colors.cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x0F37416E), blurRadius: 18, offset: Offset(0, 8))],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildWheelColumn(_yearOptions, _pendingYear, (value) => setState(() => _pendingYear = value), '年')),
              const SizedBox(width: 10),
              Expanded(child: _buildWheelColumn(_monthOptions, _pendingMonth, (value) => setState(() => _pendingMonth = value), '月', pad: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheelColumn(List<int> values, int active, ValueChanged<int> onChanged, String suffix, {bool pad = false}) {
    final controller = FixedExtentScrollController(initialItem: values.indexOf(active).clamp(0, values.length - 1));
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 36,
      diameterRatio: 3.4,
      perspective: 0.002,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => onChanged(values[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final value = values[index];
          final isActive = value == active;
          final text = pad ? value.toString().padLeft(2, '0') : value.toString();
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 140),
              style: TextStyle(
                fontSize: isActive ? 18 : 15,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive ? widget.colors.textMain : widget.colors.textSub.withAlpha(150),
              ),
              child: Text('$text$suffix'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWheelActions() {
    return Row(
      children: [
        Expanded(child: _SoftButton(label: '回到今天', colors: widget.colors, onTap: _selectToday)),
        const SizedBox(width: 8),
        Expanded(
          child: _SoftButton(
            label: '应用年月',
            colors: widget.colors,
            enabled: _hasPendingYearMonth,
            onTap: _applyPendingYearMonth,
          ),
        ),
      ],
    );
  }

  Widget _buildLunarToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showLunar = !_showLunar),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: widget.colors.softPurple, borderRadius: BorderRadius.circular(16)),
        child: Text(
          _showLunar ? '隐藏农历' : '显示农历',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: widget.colors.primary),
        ),
      ),
    );
  }

  Widget _buildLunarSummary() {
    final lunar = Lunar.fromDate(_selectedDate);
    final parts = [lunar.getYearInGanZhi(), lunar.getMonthInChinese(), lunar.getDayInChinese()].where((part) => part.isNotEmpty).join(' · ');
    return Text(
      '当前选中：农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}\n$parts',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w700, color: widget.colors.textSub),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      children: weekdays.map((day) => Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: widget.colors.textSub))))).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final leadingEmptyCells = firstDayOfMonth.weekday - 1;
    final totalCells = ((daysInMonth + leadingEmptyCells) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: _showLunar ? 8 : 14, childAspectRatio: _showLunar ? 0.84 : 1),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < leadingEmptyCells) return const SizedBox();
        final day = index - leadingEmptyCells + 1;
        if (day > daysInMonth) return const SizedBox();

        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isSelected = _isSameDate(date, _selectedDate);
        final isToday = _isSameDate(date, DateTime.now());
        final lunarText = _showLunar ? Lunar.fromDate(date).getDayInChinese() : '';

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              gradient: isSelected ? widget.colors.primaryGradient : null,
              color: isToday && !isSelected ? widget.colors.softPurple : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected ? [BoxShadow(color: widget.colors.primary.withAlpha(54), blurRadius: 18, offset: const Offset(0, 8))] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(fontSize: _showLunar ? 17 : 18, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : (isToday ? widget.colors.primary : widget.colors.textMain)),
                ),
                if (_showLunar) ...[
                  const SizedBox(height: 2),
                  Text(
                    lunarText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isSelected ? Colors.white.withAlpha(230) : widget.colors.textSub.withAlpha(184)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _SoftButton(
            label: _selectedTime == null ? '不设置时间' : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
            icon: Icons.access_time_rounded,
            colors: widget.colors,
            onTap: _pickTime,
          ),
        ),
        if (_selectedTime != null) ...[
          const SizedBox(width: 8),
          _SoftButton(label: '清除', colors: widget.colors, onTap: () => setState(() => _selectedTime = null)),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(child: _ActionButton(label: '取消', colors: widget.colors, onTap: () => Navigator.pop(context))),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: '确定',
            colors: widget.colors,
            primary: true,
            onTap: () {
              widget.onConfirm(_selectedDate, _selectedTime);
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: widget.colors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _moveMonth(int offset) {
    final next = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
    setState(() {
      _selectedDate = _dateWithClampedDay(next.year, next.month, _selectedDate.day);
      _pendingYear = _selectedDate.year;
      _pendingMonth = _selectedDate.month;
    });
  }

  void _applyPendingYearMonth() {
    setState(() => _selectedDate = _dateWithClampedDay(_pendingYear, _pendingMonth, _selectedDate.day));
  }

  void _selectToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDate = DateTime(today.year, today.month, today.day);
      _pendingYear = today.year;
      _pendingMonth = today.month;
    });
  }

  DateTime _dateWithClampedDay(int year, int month, int day) {
    final normalizedYear = year.clamp(1900, 2100);
    final normalizedMonth = month.clamp(1, 12);
    final maxDay = DateTime(normalizedYear, normalizedMonth + 1, 0).day;
    return DateTime(normalizedYear, normalizedMonth, day.clamp(1, maxDay));
  }

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<int> get _yearOptions => List.generate(201, (index) => 1900 + index);
  List<int> get _monthOptions => List.generate(12, (index) => index + 1);
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final AppColors colors;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 24, color: colors.textSub),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  const _SoftButton({required this.label, required this.colors, required this.onTap, this.icon, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.62,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(color: enabled ? colors.softPurple : colors.textSub.withAlpha(22), borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: colors.primary),
                const SizedBox(width: 6),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: enabled ? colors.primary : colors.textSub))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({required this.label, required this.colors, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: primary ? null : colors.softPurple,
          gradient: primary ? colors.primaryGradient : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: primary ? Colors.white : colors.primary)),
        ),
      ),
    );
  }
}
