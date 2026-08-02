import Cocoa
import CoreWLAN
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Home Security Scan — Wi-Fi encryption read (macOS). CoreWLAN exposes the
    // CURRENT interface's security + band without a scan (and without Location,
    // which only gates the SSID). We never join, scan, or change anything.
    let channel = FlutterMethodChannel(
      name: "in.ieye/wifi",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "getWifi" {
        result(MainFlutterWindow.currentWifi())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Reads the current Wi-Fi security/band. Returns {"security": "unavailable"}
  /// when there is no Wi-Fi interface or it isn't associated (e.g. Ethernet /
  /// Wi-Fi off) — never a misleading "open".
  static func currentWifi() -> [String: Any] {
    guard let iface = CWWiFiClient.shared().interface(),
      iface.powerOn(),
      let channel = iface.wlanChannel()
    else {
      return ["security": "unavailable"]
    }

    var out: [String: Any] = [
      "security": mapSecurity(iface.security()),
      "channel": channel.channelNumber,
    ]
    if let ssid = iface.ssid() { out["ssid"] = ssid }
    switch channel.channelBand {
    case .band2GHz: out["band"] = "2.4 GHz"
    case .band5GHz: out["band"] = "5 GHz"
    case .band6GHz: out["band"] = "6 GHz"
    default: break
    }
    return out
  }

  static func mapSecurity(_ s: CWSecurity) -> String {
    switch s {
    case .none: return "open"
    case .WEP, .dynamicWEP: return "wep"
    case .wpaPersonal, .wpaPersonalMixed, .wpaEnterprise, .wpaEnterpriseMixed:
      return "wpa"
    case .wpa2Personal, .wpa2Enterprise, .personal, .enterprise: return "wpa2"
    case .wpa3Personal, .wpa3Enterprise, .wpa3Transition: return "wpa3"
    default: return "unknown"
    }
  }
}
