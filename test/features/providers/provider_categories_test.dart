import 'package:carepass/features/providers/data/models/provider_models.dart';
import 'package:carepass/features/providers/domain/entities/provider_entities.dart';
import 'package:carepass/features/home/data/models/home_provider_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one provider is discoverable in every assigned category', () {
    final provider = MedicalProviderModel.fromFirestore({
      'name': 'Medical Complex',
      'type': 'clinic',
      'types': ['clinic', 'pharmacy', 'lab', 'lab'],
    }, 'complex');

    for (final type in [
      ProviderType.clinic,
      ProviderType.pharmacy,
      ProviderType.lab,
    ]) {
      expect(provider.offersType(type), isTrue);
    }
    expect(provider.offersType(ProviderType.dental), isFalse);
    expect(provider.id, 'complex');
    expect(provider.providerTypes, hasLength(3));
    expect(provider.typeLabel, 'Clinic · Pharmacy · Laboratory');
  });

  test('legacy providers retain their single category', () {
    for (final types in [null, <String>[]]) {
      final provider = MedicalProviderModel.fromFirestore({
        'type': 'pharmacy',
        'types': ?types,
      }, 'legacy');
      expect(provider.providerTypes, [ProviderType.pharmacy]);
    }
  });

  test('explicit categories override a stale legacy category', () {
    final provider = MedicalProviderModel.fromFirestore({
      'type': 'clinic',
      'types': ['pharmacy', 'lab'],
    }, 'complex');
    expect(provider.offersType(ProviderType.clinic), isFalse);
    expect(provider.offersType(ProviderType.lab), isTrue);
  });

  test('home cards read the same categories', () {
    final provider = HomeProviderModel.fromFirestore({
      'type': 'clinic',
      'types': ['clinic', 'pharmacy', 'lab'],
    }, 'complex');
    expect(provider.typeLabel, 'Clinic · Pharmacy · Laboratory');
  });
}
