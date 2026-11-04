import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reto_factus/main.dart';

void main() {
  testWidgets('Smoke test inicial', (WidgetTester tester) async {
    // Envolvemos la app en ProviderScope tal como en main.dart
    await tester.pumpWidget(const ProviderScope(child: RetoFactusApp()));
    expect(find.byType(RetoFactusApp), findsOneWidget);
  });
}
