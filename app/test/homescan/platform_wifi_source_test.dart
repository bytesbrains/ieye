import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/core/homescan/home_scan_model.dart';
import 'package:ieye/features/homescan/platform_wifi_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('in.ieye/wifi');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('maps every native security string', () {
    expect(PlatformWifiSource.mapSecurity('open'), WifiSecurity.open);
    expect(PlatformWifiSource.mapSecurity('wep'), WifiSecurity.wep);
    expect(PlatformWifiSource.mapSecurity('wpa'), WifiSecurity.wpaTkip);
    expect(PlatformWifiSource.mapSecurity('wpa2'), WifiSecurity.wpa2);
    expect(PlatformWifiSource.mapSecurity('wpa3'), WifiSecurity.wpa3);
    expect(PlatformWifiSource.mapSecurity('unavailable'),
        WifiSecurity.unavailable);
    expect(PlatformWifiSource.mapSecurity('anything-else'),
        WifiSecurity.unknown);
  });

  test('reads a native WPA2 result into a WifiObservation', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'getWifi') return null;
      return <String, dynamic>{
        'ssid': 'home-network',
        'security': 'wpa2',
        'band': '5 GHz',
        'channel': 44,
      };
    });

    // supported: true forces the channel path regardless of runner OS (CI = Linux).
    final obs = await const PlatformWifiSource(supported: true).current();
    expect(obs.security, WifiSecurity.wpa2);
    expect(obs.ssid, 'home-network');
    expect(obs.band, '5 GHz');
    expect(obs.channel, 44);
    expect(obs.readable, isTrue);
  });

  test('a channel failure degrades to unavailable, never a false secure',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'boom');
    });
    // Force the channel path so this tests the ERROR handling (not the
    // non-macOS short-circuit) on every runner.
    final obs = await const PlatformWifiSource(supported: true).current();
    expect(obs.security, WifiSecurity.unavailable);
    expect(obs.readable, isFalse);
  });
}
