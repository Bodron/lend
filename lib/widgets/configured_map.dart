import 'package:flutter/material.dart';

import '../services/maps_configuration.dart';

/// Avoid creating an iOS map platform view before GMSServices is configured.
class ConfiguredMap extends StatelessWidget {
  const ConfiguredMap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MapsConfiguration.available) return child;
    final romanian = Localizations.localeOf(context).languageCode == 'ro';
    return ColoredBox(
      color: const Color(0xFFE8EDF3),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, color: Color(0xFF434750)),
              const SizedBox(height: 8),
              Text(
                romanian ? 'Harta nu este disponibilă' : 'Map is unavailable',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
