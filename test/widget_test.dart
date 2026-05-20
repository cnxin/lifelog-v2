import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelog/app.dart';

void main() {
  testWidgets('LifeLog app smoke test', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('zh_CN');
    await tester.pumpWidget(const ProviderScope(child: LifeLogApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
