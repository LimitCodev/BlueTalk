import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/main.dart';

void main() {
  testWidgets('la app arranca y muestra BlueTalk', (WidgetTester tester) async {
    await tester.pumpWidget(const BlueTalkApp());

    expect(find.text('BlueTalk'), findsOneWidget);
  });
}
