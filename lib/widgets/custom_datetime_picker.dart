import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import '../theme/app_theme.dart';

class CustomDateTimePicker extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay? initialTime;
  final Function(DateTime date, TimeOfDay? time) onConfirm;
  final AppColors colors;
  final DateTime? anniversaryStartDate;

  const CustomDateTimePicker({
    super.key,
    required this.initialDate,
    this.initialTime,
    required this.onConfirm,
    required this.colors,
    this.anniversaryStartDate,
  });

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late DateTime _displayMonth;
  bool _useLunar = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReminderCard(),
                    const SizedBox(height: 16),
                    _buildMonthSelector(),
                    const SizedBox(height: 10),
                    _buildCalendarCard(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1F2433)),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              '选择日期时间',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2433)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0F1F2433), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('提醒时间', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3A4056))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _PillButton(
                  icon: Icons.calendar_today_rounded,
                  label: '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                  subLabel: _getAnniversaryText(),
                  active: true,
                  colors: widget.colors,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: _PillButton(
                  icon: Icons.access_time_rounded,
                  label: _selectedTime == null
                      ? '不设置'
                      : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                  active: _selectedTime != null,
                  colors: widget.colors,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.repeat_rounded, size: 18, color: Color(0xFF8A91A8)),
              const SizedBox(width: 10),
              const Expanded(child: Text('重复提醒', style: TextStyle(fontSize: 14, color: Color(0xFF3A4056)))),
              Text('不重复', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.colors.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8A91A8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.brightness_2_rounded, size: 18, color: Color(0xFF8A91A8)),
              const SizedBox(width: 10),
              const Expanded(child: Text('农历', style: TextStyle(fontSize: 14, color: Color(0xFF3A4056)))),
              Switch(
                value: _useLunar,
                activeColor: widget.colors.primary,
                onChanged: (value) => setState(() => _useLunar = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _getAnniversaryText() {
    if (widget.anniversaryStartDate == null) return null;
    final start = widget.anniversaryStartDate!;
    final selected = _selectedDate;
    final years = selected.year - start.year;
    if (years > 0 && selected.month == start.month && selected.day == start.day) return '$years周年';
    return null;
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF3A4056)),
          onPressed: () => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1)),
        ),
        Expanded(
          child: Text(
            '${_displayMonth.year}年${_displayMonth.month}月',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2433)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF3A4056)),
          onPressed: () => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1)),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x0F1F2433), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          _buildWeekdayHeader(),
          const SizedBox(height: 8),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8A91A8))),
        ),
      )).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final firstDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final leadingEmptyCells = firstDayOfMonth.weekday - 1;
    final totalCells = ((daysInMonth + leadingEmptyCells) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.72),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < leadingEmptyCells) return const SizedBox();
        final day = index - leadingEmptyCells + 1;
        if (day > daysInMonth) return const SizedBox();

        final date = DateTime(_displayMonth.year, _displayMonth.month, day);
        final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
        final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
        final lunarText = _useLunar ? Lunar.fromDate(date).getDayInChinese() : '';

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? null : (isToday ? const Color(0xFFF0F2FF) : Colors.transparent),
              gradient: isSelected ? widget.colors.primaryGradient : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF1F2433),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lunarText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : const Color(0xFF9BA2B8)),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(color: Color(0xFFF7F7FB)),
      child: Row(
        children: [
          if (_selectedTime != null)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTime = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: const Center(child: Text('清除时间', style: TextStyle(color: Color(0xFF6F768C), fontWeight: FontWeight.w700))),
                ),
              ),
            ),
          if (_selectedTime != null) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                widget.onConfirm(_selectedDate, _selectedTime);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(gradient: widget.colors.primaryGradient, borderRadius: BorderRadius.circular(18)),
                child: const Center(child: Text('确定', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subLabel;
  final bool active;
  final AppColors colors;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.colors,
    required this.onTap,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF0F2FF) : const Color(0xFFF6F6F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? colors.primary.withAlpha(80) : const Color(0xFFE9EAF0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? colors.primary : const Color(0xFF8A91A8)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1F2433))),
                  if (subLabel != null) Text(subLabel!, style: const TextStyle(fontSize: 11, color: Color(0xFF8A91A8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
