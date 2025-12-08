import 'package:flutter_test/flutter_test.dart';
import 'package:gvstorage/main.dart';

void main() {
  testWidgets('GvStorage app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GvStorageApp());

    // Verify that the app renders the home page with GvStorage branding
    expect(find.text('GvStorage'), findsWidgets);
  });
}
