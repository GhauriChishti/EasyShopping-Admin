import 'package:admin_panel/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard is shown on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('View Products'), findsOneWidget);
  });
}
