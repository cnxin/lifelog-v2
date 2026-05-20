import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  if (kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lifelog_settings', '{"themeStyle":"classic","themeMode":false,"customRelationships":["朋友","家人","同事","同学","恋人","其他"],"customMoods":["日常","开心","轻松","愉快","感动","难忘"]}');
  }
  await NotificationService().initialize();
  runApp(const _WebPreviewFrame(child: ProviderScope(child: LifeLogApp())));
}

class _WebPreviewFrame extends StatelessWidget {
  final Widget child;

  const _WebPreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Material(
      color: const Color(0xFFE6EAF1),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(430.0, math.max(360.0, constraints.maxWidth - 24));
            final height = math.min(932.0, math.max(640.0, constraints.maxHeight - 24));
            return Center(
              child: Container(
                width: width,
                height: height,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 28, offset: Offset(0, 16)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
