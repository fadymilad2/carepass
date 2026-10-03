import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';
part 'area_picker/area_item.dart';

class AreaPicker extends StatefulWidget {
  final String currentArea;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  const AreaPicker({
    super.key,
    required this.currentArea,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends State<AreaPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isLocating = false;

  static const _locations = <String, List<String>>{
    'Accra': [
      'Osu',
      'East Legon',
      'Cantonments',
      'Airport Residential',
      'Labadi',
      'Madina',
      'Dansoman',
      'Spintex',
      'Adenta',
      'Tesano',
      'Accra Central',
    ],
    'Kumasi': ['Bantama', 'Ahodwo', 'Kwadaso', 'Tech', 'Santasi'],
    'Tema': ['Community 1', 'Community 11', 'Community 25', 'Sakumono'],
    'Tamale': ['Central', 'Education Ridge', 'Kalpohin'],
    'Takoradi': ['Market Circle', 'Effiakuma', 'Sekondi'],
  };

  List<String> get _searchResults {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    final results = <String>[];
    _locations.forEach((city, areas) {
      if (city.toLowerCase().contains(q)) results.add(city);
      results.addAll(areas.where((a) => a.toLowerCase().contains(q)));
    });
    return results.toSet().toList();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        _showError('Enable location services');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showError('Permission denied');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      final pos =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw Exception('Location timed out'),
          );

      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isEmpty || !mounted) return;

      final p = marks.first;
      final matched = _matchKnown([
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]);

      if (matched != null) {
        widget.onSelect(matched);
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) _showOutsideNetworkDialog(p.locality ?? p.country);
      }
    } catch (e) {
      _showError('Could not get location. Please select manually.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showOutsideNetworkDialog(String? detectedPlace) {
    showDialog(
      context: context,
      builder: (dc) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.location_off_outlined,
              color: AppColors.warning,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Outside Service Area')),
          ],
        ),
        content: Text(
          detectedPlace != null && detectedPlace.isNotEmpty
              ? 'We detected your location as "$detectedPlace", which is '
                    'outside our current network (Ghana only).\n\n'
                    'Please select your area manually from the list below.'
              : 'We couldn\'t match your location to our current network '
                    '(Ghana only).\n\nPlease select your area manually from '
                    'the list below.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dc),
            child: const Text('Select Manually'),
          ),
        ],
      ),
    );
  }

  String? _matchKnown(List<String?> candidates) {
    final all = <String>[
      ..._locations.keys,
      ..._locations.values.expand((a) => a),
    ];
    for (final c in candidates) {
      if (c == null || c.isEmpty) continue;
      final lower = c.toLowerCase();
      final exact = all.firstWhere(
        (l) => l.toLowerCase() == lower,
        orElse: () => '',
      );
      if (exact.isNotEmpty) return exact;
      final contains = all.firstWhere(
        (l) =>
            lower.contains(l.toLowerCase()) || l.toLowerCase().contains(lower),
        orElse: () => '',
      );
      if (contains.isNotEmpty) return contains;
    }
    return null;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchActive = _query.isNotEmpty;
    final results = _searchResults;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Area',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                  if (widget.currentArea.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onClear();
                      },
                      child: const Text('Show All'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextFormField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search for area or location',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: _isLocating
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                              color: AppColors.primary,
                              size: 18,
                            ),
                    ),
                    title: Text(
                      _isLocating
                          ? 'Getting your location...'
                          : 'Use my current location',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _isLocating ? null : _useCurrentLocation,
                  ),
                  const Divider(height: 1),

                  if (searchActive) ...[
                    if (results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No areas found for "$_query"',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...results.map(
                        (area) => _AreaItem(
                          area: area,
                          isSelected: area == widget.currentArea,
                          onTap: () {
                            widget.onSelect(area);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                  ] else ...[
                    ..._locations.entries.map(
                      (e) => Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(e.key, style: AppTextStyles.titleMedium),
                          initiallyExpanded: e.key == 'Accra',
                          iconColor: AppColors.primary,
                          collapsedIconColor: AppColors.primary,
                          children: e.value
                              .map(
                                (area) => Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: _AreaItem(
                                    area: area,
                                    isSelected: area == widget.currentArea,
                                    onTap: () {
                                      widget.onSelect(area);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
