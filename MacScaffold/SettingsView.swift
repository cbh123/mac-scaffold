import SwiftUI

struct SettingsView: View {
    @AppStorage("replicateToken") var replicateToken: String = ""

    var body: some View {
        Form {
            TextField("Replicate Token", text: $replicateToken)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
        }
        .navigationTitle("Settings")
    }
}
