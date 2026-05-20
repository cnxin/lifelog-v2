import 'package:lunar/lunar.dart';

class CalendarLunarInfo {
  final String ganZhiZodiacText;
  final String weekText;
  final String weekOfYearText;
  final String lunarText;
  final String cellText;
  final List<String> festivals;
  final String jieQi;

  const CalendarLunarInfo({
    required this.ganZhiZodiacText,
    required this.weekText,
    required this.weekOfYearText,
    required this.lunarText,
    required this.cellText,
    required this.festivals,
    required this.jieQi,
  });
}

CalendarLunarInfo getCalendarLunarInfo(DateTime date) {
  final lunar = Lunar.fromDate(date);
  final zodiac = lunar.getYearShengXiao();
  final festivals = <String>[
    ...lunar.getFestivals(),
    ...lunar.getOtherFestivals(),
  ].where((item) => item.trim().isNotEmpty).toSet().toList();
  final jieQi = lunar.getJieQi();
  final lunarText = '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  final special = jieQi.isNotEmpty ? jieQi : (festivals.isNotEmpty ? festivals.first : '');

  return CalendarLunarInfo(
    ganZhiZodiacText: '${lunar.getYearInGanZhi()}$zodiac年 ${lunar.getMonthInGanZhi()}月 ${lunar.getDayInGanZhi()}日',
    weekText: _weekText(date.weekday),
    weekOfYearText: '第${_weekOfYear(date)}周',
    lunarText: lunarText,
    cellText: special.isNotEmpty ? special : lunar.getDayInChinese(),
    festivals: festivals,
    jieQi: jieQi,
  );
}

String memoryDisplayTitle(String title, String content) {
  final manual = title.trim();
  if (manual.isNotEmpty && manual != '新的回忆' && manual != '快速记录') return manual;
  final text = content.trim();
  if (text.isEmpty) return '未命名回忆';
  return text.length > 18 ? '${text.substring(0, 18)}…' : text;
}

bool isManualMemoryTitle(String title) {
  final text = title.trim();
  return text.isNotEmpty && text != '新的回忆' && text != '快速记录';
}

String _weekText(int weekday) {
  const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return names[weekday - 1];
}

int _weekOfYear(DateTime date) {
  final start = DateTime(date.year, 1, 1);
  final dayOfYear = date.difference(start).inDays + 1;
  return ((dayOfYear + start.weekday - 2) / 7).floor() + 1;
}
