import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../../core/homescan/home_scan_model.dart';
import '../../core/homescan/lan_scanner.dart';

/// A [WifiSource] backed by a native method channel. Lives in the feature layer
/// (not pure-Dart `core/`) because it depends on Flutter platform channels.
///
/// Only macOS is wired today (CoreWLAN). Every other platform — and any channel
/// error — reports [WifiSecurity.unavailable] honestly, never a guessed "secure".
class PlatformWifiSource implements WifiSource {
  /// [supported] overrides the platform gate (default: macOS-only). Tests pass
  /// `supported: true` to exercise the channel path on any runner (CI is Linux).
  const PlatformWifiSource({bool? supported}) : _supported = supported;

  final bool? _supported;

  static const MethodChannel _channel = MethodChannel('in.ieye/wifi');

  @override
  Future<WifiObservation> current() async {
    if (!(_supported ?? Platform.isMacOS)) {
      // Android/iOS Wi-Fi reads aren't wired yet; the UI states the gap.
      return const WifiObservation(security: WifiSecurity.unavailable);
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getWifi');
      if (res == null) {
        return const WifiObservation(security: WifiSecurity.unavailable);
      }
      return WifiObservation(
        ssid: res['ssid'] as String?,
        security: mapSecurity(res['security'] as String?),
        band: res['band'] as String?,
        channel: res['channel'] as int?,
      );
    } on PlatformException {
      return const WifiObservation(security: WifiSecurity.unavailable);
    } on MissingPluginException {
      return const WifiObservation(security: WifiSecurity.unavailable);
    }
  }

  /// Maps the native security string to [WifiSecurity]. Exposed for tests.
  static WifiSecurity mapSecurity(String? s) => switch (s) {
        'open' => WifiSecurity.open,
        'wep' => WifiSecurity.wep,
        'wpa' => WifiSecurity.wpaTkip,
        'wpa2' => WifiSecurity.wpa2,
        'wpa3' => WifiSecurity.wpa3,
        'unavailable' => WifiSecurity.unavailable,
        _ => WifiSecurity.unknown,
      };
}
