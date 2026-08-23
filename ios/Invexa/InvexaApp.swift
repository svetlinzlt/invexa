import SwiftUI
import SwiftData
import InvexaCore

@main
struct InvexaApp: App {
    /// Хранилището е локално и се синхронизира през личния iCloud на
    /// потребителя. Няма мой сървър и няма регистрация — това е и най-евтиният
    /// вариант, и най-силната позиция по GDPR.
    private let container: ModelContainer = {
        do {
            return try InvexaStore.makeContainer()
        } catch {
            // Ако хранилището не се отваря, приложението няма какво да покаже.
            // По-добре да спре шумно тук, отколкото да работи с празни данни и
            // потребителят да реши, че месецът му е изчезнал.
            fatalError("Хранилището не се отвори: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LockGate {
                RootView()
            }
            .preferredColorScheme(.dark)
            .tint(Palette.violet)
        }
        .modelContainer(container)
    }
}
