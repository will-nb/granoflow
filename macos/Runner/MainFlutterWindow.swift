import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private struct WindowSize: Decodable {
    let width: CGFloat
    let height: CGFloat
  }

  private struct DesktopWindowConfig: Decodable {
    let defaultSize: WindowSize?
    let phone: WindowSize?
    let tablet: WindowSize?

    private enum CodingKeys: String, CodingKey {
      case defaultSize = "default"
      case phone
      case tablet
    }
  }

  private let fallbackSize = NSSize(width: 1280, height: 720) // 默认尺寸

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    let initialSize = loadConfiguredSize() ?? fallbackSize
    self.setContentSize(initialSize)
    self.center()
  }

  private func loadConfiguredSize() -> NSSize? {
    guard let assetURL = Bundle.main.url(forResource: "flutter_assets/assets/config/desktop_window", withExtension: "json") else {
      return nil
    }

    do {
      let data = try Data(contentsOf: assetURL)
      let decoder = JSONDecoder()
      let config = try decoder.decode(DesktopWindowConfig.self, from: data)

      let size = config.defaultSize ?? config.phone ?? config.tablet
      guard let resolvedSize = size else {
        return nil
      }
      return NSSize(width: resolvedSize.width, height: resolvedSize.height)
    } catch {
      NSLog("[MainFlutterWindow] Failed to load desktop_window.json: \(error)")
      return nil
    }
  }
}
