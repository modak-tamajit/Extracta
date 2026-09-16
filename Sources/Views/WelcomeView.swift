import SwiftUI

struct WelcomeView: View {
    let finish: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Image(systemName: "hand.raised.fill").font(.system(size: 48)).foregroundStyle(.indigo)
            Text("Your screenshots stay yours.").font(.largeTitle.weight(.bold))
            Text("Extracta reads screenshots, finds useful dates and links, and organizes them entirely on your device.")
                .font(.title3).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 14) {
                WelcomePromise(symbol: "airplane", text: "Works in Airplane Mode")
                WelcomePromise(symbol: "icloud.slash", text: "No cloud processing")
                WelcomePromise(symbol: "eye.slash", text: "No tracking or analytics")
            }
            Spacer()
            Button("Begin privately", action: finish)
                .buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth: .infinity)
        }
        .padding(28)
    }
}

private struct WelcomePromise: View {
    let symbol: String
    let text: String
    var body: some View { Label(text, systemImage: symbol).font(.body.weight(.medium)) }
}
