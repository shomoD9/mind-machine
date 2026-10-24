/* Dedicated simulator host launched by KeyboardAcceptanceTests in native-ci.
 It owns a visible host field; the production keyboard is embedded here so tests
 do not depend on Settings, Full Access grants or keyboard-daemon preferences. */
import UIKit

@main
final class KeyboardTestHost: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = HostController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

@MainActor
private final class HostController: UIViewController, TextRouteOwner {
    private let composer = UITextView()
    private let hostProxy = RoutedTextProxy()
    private let keyboard = KeyboardViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        composer.text = "host draft stays here"
        composer.font = .systemFont(ofSize: 17)
        composer.autocorrectionType = .no
        composer.inputView = UIView(frame: .zero)
        composer.selectedRange = NSRange(location: composer.text.utf16.count, length: 0)
        composer.accessibilityIdentifier = "host-composer"
        composer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composer)
        NSLayoutConstraint.activate([
            composer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            composer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            composer.heightAnchor.constraint(equalToConstant: 64)
        ])

        // Keep both editors and the real keyplane visible when focus changes. The
        // controller is embedded as a child input surface; no system keyboard daemon
        // or fake save/search operation participates. The proxy writes this text view.
        hostProxy.owner = self
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "--vault-id"), flag + 1 < arguments.count,
              let id = UUID(uuidString: arguments[flag + 1]) else {
            fatalError("UI host requires a test-owned vault UUID")
        }
        keyboard.uiTestVaultURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("keyboard-ui-\(id.uuidString)/vault.json")
        keyboard.uiTestHostProxy = hostProxy
        addChild(keyboard)
        keyboard.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboard.view)
        NSLayoutConstraint.activate([
            keyboard.view.topAnchor.constraint(equalTo: composer.bottomAnchor, constant: 12),
            keyboard.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.view.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        keyboard.didMove(toParent: self)
    }

    // Adapt the host's real field to UITextDocumentProxy at the operating-system
    // boundary. Production RoutedTextProxy supplies Unicode/caret editing behavior.
    var privateEditorForTyping: UITextView? { composer }
    var routesToHost: Bool { false }
    var hostProxyForReading: UITextDocumentProxy? { nil }
    func writeToHost(_ write: (UITextDocumentProxy) -> Void) { fatalError("Host proxy cannot route recursively") }
    func privateEditorDidChange() {}
}
