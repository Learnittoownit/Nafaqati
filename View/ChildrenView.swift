import SwiftUI

struct ChildrenView: View {
    @EnvironmentObject var parentVM: ParentViewModel

    var body: some View {
        ZStack {
            Color(hex: "E8EDF2").ignoresSafeArea()
            VStack {
                Text("Children")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "1B3A6B"))
                Text("Coming next")
                    .foregroundColor(Color.nafTextGray)
            }
        }
    }
}