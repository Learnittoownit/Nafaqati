import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var parentVM: ParentViewModel

    var body: some View {
        ZStack {
            Color(hex: "E8EDF2").ignoresSafeArea()
            VStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "1B3A6B"))
                Text("Coming next")
                    .foregroundColor(Color.nafTextGray)
            }
        }
    }
}