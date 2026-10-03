import 'package:carepass/core/widgets/area_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('shared picker searches and selects an area', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AreaPicker(
                  currentArea: '',
                  onSelect: (area) => selected = area,
                  onClear: () {},
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Osu');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Osu'));
    await tester.pumpAndSettle();
    expect(selected, 'Osu');
    expect(find.byType(AreaPicker), findsNothing);
  });
  testWidgets('shared picker clears an existing area filter', (tester) async {
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AreaPicker(
                  currentArea: 'Accra',
                  onSelect: (_) {},
                  onClear: () => cleared = true,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show All'));
    await tester.pumpAndSettle();
    expect(cleared, isTrue);
    expect(find.byType(AreaPicker), findsNothing);
  });
}
