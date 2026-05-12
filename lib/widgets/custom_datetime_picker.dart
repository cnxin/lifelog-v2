import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.colors.gradientColors,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateTimeButtons(),
                    const SizedBox(height: 24),
                    _buildCalendar(),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: widget.colors.textMain),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            '选择日期时间',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.colors.textMain,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDateTimeButtons() {
    final anniversaryText = _getAnniversaryText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '提醒时间',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.colors.textSub,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GlassCard(
                colors: widget.colors,
                onTap: () {},
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: widget.colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: widget.colors.textMain,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (anniversaryText != null)
                            Text(
                              anniversaryText,
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.colors.textSub,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                colors: widget.colors,
                onTap: _pickTime,
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 18, color: widget.colors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : '不设置',
                      style: TextStyle(
                        color: widget.colors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _getAnniversaryText() {
    if (widget.anniversaryStartDate == null) return null;

    final start = widget.anniversaryStartDate!;
    final selected = _selectedDate;

    final years = selected.year - start.year;
    final months = selected.month - start.month;
    final days = selected.day - start.day;

    if (years > 0 && months == 0 && days == 0) {
      return '$years周年';
    } else if (years == 0 && months > 0 && days == 0) {
      return '$months个月';
    } else if (years == 0 && months == 0 && days >= 0) {
      return '$days天';
    }

    return null;
  }

  Widget _buildCalendar() {
    return GlassCard(
      colors: widget.colors,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 16),
          _buildWeekdayHeader(),
          const SizedBox(height: 8),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: widget.colors.textMain),
          onPressed: () {
            setState(() {
              _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
            });
          },
        ),
        Text(
          '${_displayMonth.year}年${_displayMonth.month}月',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.colors.textMain,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: widget.colors.textMain),
          onPressed: () {
            setState(() {
              _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.colors.textSub,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final firstDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    int firstWeekday = firstDayOfMonth.weekday;
    if (firstWeekday == 7) firstWeekday = 0;

    final totalCells = ((daysInMonth + firstWeekday) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return const SizedBox();
        }

        final day = index - firstWeekday + 1;
        if (day > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(_displayMonth.year, _displayMonth.month, day);
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        final lunar = Lunar.fromDate(date);
        final lunarDay = lunar.getDayInChinese();

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: isSelected ? widget.colors.primaryGradient : null,
              color: isSelected ? null : (isToday ? widget.colors.softPurple : null),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : widget.colors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lunarDay,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white70 : widget.colors.textSub,
                  ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.colors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_selectedTime != null)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTime = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.colors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.colors.line),
                  ),
                  child: Center(
                    child: Text(
                      '清除时间',
                      style: TextStyle(
                        color: widget.colors.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: widget.colors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    '确定',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
