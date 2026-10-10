import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'auth_api.dart';

class AppUpdateOffer {
  const AppUpdateOffer({
    required this.version,
    required this.url,
    required this.required,
    this.preview = false,
  });

  final String version;
  final Uri url;
  final bool required;
  final bool preview;
}

class AppUpdateService {
  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AppUpdateOffer?> check() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return null;
    }

    try {
      final response = await _client
          .get(Uri.parse('${AuthApi.baseUrl}/app-version'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final settings = jsonDecode(response.body) as Map<String, dynamic>;
      final package = await PackageInfo.fromPlatform();
      final installedVersion = '${package.version}+${package.buildNumber}';
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final platformSettings = settings[platform] as Map<String, dynamic>;
      final latest = (platformSettings['latestVersion'] as String? ?? '')
          .trim();
      final minimum = (platformSettings['minimumVersion'] as String? ?? '')
          .trim();
      final latestComparison = compareAppVersions(installedVersion, latest);
      final minimumComparison = compareAppVersions(installedVersion, minimum);
      if (latestComparison == null && minimumComparison == null) return null;

      final required = minimumComparison != null && minimumComparison < 0;
      if (!required && (latestComparison == null || latestComparison >= 0)) {
        return null;
      }

      final configuredUrl = (platformSettings['updateUrl'] as String? ?? '')
          .trim();
      final url = Uri.tryParse(
        configuredUrl.isNotEmpty
            ? configuredUrl
            : platform == 'android'
            ? 'https://play.google.com/store/apps/details?id=${package.packageName}'
            : '',
      );
      if (url == null ||
          url.scheme != 'https' ||
          !(platform == 'ios'
              ? {'apps.apple.com', 'testflight.apple.com'}.contains(url.host)
              : url.host == 'play.google.com')) {
        return null;
      }

      return AppUpdateOffer(
        version:
            required &&
                (latestComparison == null ||
                    compareAppVersions(minimum, latest) == 1)
            ? minimum
            : latest,
        url: url,
        required: required,
      );
    } catch (error) {
      debugPrint('App update check failed: $error');
      return null;
    }
  }
}

/// Returns null for missing or malformed versions. Supports 1.2.3 and 1.2.3+4.
int? compareAppVersions(String installed, String configured) {
  List<int>? parse(String value) {
    if (!RegExp(r'^\d+(\.\d+){1,2}(\+\d+)?$').hasMatch(value)) {
      return null;
    }
    final parts = value.split('+');
    final numbers = parts.first.split('.').map(int.parse).toList();
    while (numbers.length < 3) {
      numbers.add(0);
    }
    if (parts.length > 1) numbers.add(int.parse(parts.last));
    return numbers;
  }

  final current = parse(installed);
  final target = parse(configured);
  if (current == null || target == null) return null;
  for (var i = 0; i < 3; i++) {
    if (current[i] != target[i]) return current[i].compareTo(target[i]);
  }
  if (target.length == 4) {
    return (current.length == 4 ? current[3] : 0).compareTo(target[3]);
  }
  return 0;
}
