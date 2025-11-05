import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // 设置窗口大小为 800x600
    self.setContentSize(NSSize(width: 800, height: 600))
    self.center()
  }
}
