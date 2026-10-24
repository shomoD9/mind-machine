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
private final class HostController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let composer = UITextView()
        composer.text = "host draft stays here"
        composer.accessibilityIdentifier = "host-composer"
        composer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composer)
        NSLayoutConstraint.activate([
            composer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            composer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            composer.heightAnchor.constraint(equalToConstant: 64)
        ])
    }
}
