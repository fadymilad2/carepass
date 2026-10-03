import 'package:carepass/features/home/data/models/home_provider_model.dart';
import 'package:carepass/features/home/domain/entities/home_entities.dart';
import 'package:carepass/features/home/presentation/widgets/home_nearby_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final position = Position(
    latitude: 0,
    longitude: 0,
    timestamp: DateTime(2026),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );

  test(
    'provider values come from the record; stored distance is never presented as current',
    () {
      final provider = HomeProviderModel.fromFirestore(
        {
          'name': 'Actual Clinic',
          'phoneNumber': '233000000000',
          'type': 'hospital',
          'area': 'Tema',
          'latitude': 0,
          'longitude': 1,
          'distanceKm': 0.8,
        },
        'real-id',
        position: position,
      );
      expect(provider.id, 'real-id');
      expect(provider.name, 'Actual Clinic');
      expect(provider.phone, '233000000000');
      expect(provider.distanceKm, closeTo(111.2, 0.5));
    },
  );

  test(
    'missing location and invalid provider coordinates do not invent a distance',
    () {
      expect(
        HomeProviderModel.fromFirestore({'distanceKm': 0.8}, 'a').distanceKm,
        isNull,
      );
      expect(
        HomeProviderModel.fromFirestore(
          {'latitude': 999, 'longitude': 0},
          'b',
          position: position,
        ).distanceKm,
        isNull,
      );
      expect(
        HomeProviderModel.fromFirestore(
          {'latitude': 0, 'longitude': 0},
          'c',
          position: position,
        ).distanceKm,
        0,
      );
    },
  );

  test(
    'nearest providers are selected before limiting and unknown distances sort last',
    () {
      final providers = [
        for (var i = 7; i > 0; i--)
          HomeProviderItem(
            id: '$i',
            name: 'Clinic $i',
            type: 'clinic',
            phone: '',
            area: 'Accra',
            distanceKm: i.toDouble(),
          ),
        const HomeProviderItem(
          id: 'unknown',
          name: 'A clinic',
          type: 'clinic',
          phone: '',
          area: 'Accra',
        ),
      ];
      expect(nearestHomeProviders(providers).map((p) => p.id), [
        '1',
        '2',
        '3',
        '4',
        '5',
      ]);
    },
  );

  testWidgets('empty results do not show fabricated clinics or distances', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeNearbyProviders(providers: const [], onSeeMore: () {}),
        ),
      ),
    );
    expect(
      find.text('No providers are available in this area yet.'),
      findsOneWidget,
    );
    expect(find.text('Accra Medical Center'), findsNothing);
    expect(find.text('Life Care Clinic'), findsNothing);
    expect(find.text('0.8 km'), findsNothing);
  });

  testWidgets(
    'errors offer retry instead of pretending that the area is empty',
    (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeNearbyProviders(
              providers: const [],
              hasError: true,
              onSeeMore: () {},
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(
        find.text('Unable to load providers. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.text('No providers are available in this area yet.'),
        findsNothing,
      );
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    },
  );

  testWidgets('provider tile shows real values and a valid zero distance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeNearbyProviders(
            providers: const [
              HomeProviderItem(
                id: 'actual',
                name: 'Actual Clinic',
                type: 'hospital',
                phone: '233000000000',
                area: 'Tema',
                distanceKm: 0,
              ),
            ],
            onSeeMore: () {},
          ),
        ),
      ),
    );
    expect(find.text('Actual Clinic'), findsOneWidget);
    expect(find.text('233000000000'), findsOneWidget);
    expect(find.text('0.0 km'), findsOneWidget);
  });
}
