import LocalAuthentication
import SwiftUI

/// Заключване с Face ID.
///
/// Включено по подразбиране — приложение, което показва целия ти месец, не
/// бива да се отваря от всеки, който вземе телефона отключен.
/// `@MainActor`, защото `LockGate` вика `authenticate()` от две места —
/// `.task` при появата и `.onChange` при връщане от фон. Без изолация двете
/// извиквания се засичат, пазачът `isAuthenticating` не ги спира и Face ID
/// се пуска два пъти един върху друг.
@MainActor
@Observable
final class AppLock {
    enum State {
        case locked
        case unlocked
        /// Устройството няма биометрия или тя е изключена. Тогава заключване
        /// няма — по-добре, отколкото да заключим човека извън данните му.
        case unavailable
    }

    private(set) var state: State = .locked
    private var isAuthenticating = false

    /// Настройката живее в App Group, за да е достъпна и за разширенията.
    private let defaults = UserDefaults(suiteName: InvexaStore.appGroupID) ?? .standard
    private let key = "lock.enabled"

    var isEnabled: Bool {
        get { defaults.object(forKey: key) as? Bool ?? true }
        set {
            defaults.set(newValue, forKey: key)
            if !newValue { state = .unlocked }
        }
    }

    func authenticate() async {
        guard isEnabled else {
            state = .unavailable
            return
        }
        guard !isAuthenticating, state != .unlocked else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "Отказ"

        var error: NSError?
        // `deviceOwnerAuthentication` включва и кода за достъп: ако Face ID
        // не разпознае лицето, човекът пак може да влезе.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            state = .unavailable
            return
        }

        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Отключи, за да видиш месеца си"
            )
            state = ok ? .unlocked : .locked
        } catch {
            state = .locked
        }
    }

    /// Заключва при прибиране на приложението във фон. Без това достатъчно е
    /// някой да превключи задачите, за да види всичко.
    func lock() {
        guard isEnabled else { return }
        state = .locked
    }
}

/// Обвивка, която показва съдържанието само след отключване.
struct LockGate<Content: View>: View {
    @Environment(\.scenePhase) private var phase
    @State private var lock = AppLock()

    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Palette.ground.ignoresSafeArea()

            switch lock.state {
            case .unlocked, .unavailable:
                content()
            case .locked:
                lockedScreen
            }
        }
        .task { await lock.authenticate() }
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .background:
                lock.lock()
            case .active:
                Task { await lock.authenticate() }
            default:
                break
            }
        }
    }

    private var lockedScreen: some View {
        VStack(spacing: 18) {
            Image(systemName: "faceid")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Palette.violet)

            Text("Invexa е заключено")
                .font(.amount(22))
                .foregroundStyle(Palette.text)

            Button("Отключи") {
                Task { await lock.authenticate() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 220)
        }
    }
}
