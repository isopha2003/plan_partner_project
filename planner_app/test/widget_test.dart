import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planner_app/main.dart';

void main() {
  testWidgets('앱 초기 화면 렌더링 확인', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PlannerApp()));
    expect(find.text('생활 플래너'), findsWidgets);
  });
}
