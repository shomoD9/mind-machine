// Structural handoff exported by FigCraft inspect.code, not application logic.
// Referenced by docs/design/README.md as a component-export feasibility sample.
import SwiftUI

struct ButtonPrimary: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("Save")
                .font(.custom("Avenir Next", size: 15).weight(.semibold))
                .foregroundColor(Color(red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
                .offset(x: 12, y: 12)
        }
            .frame(width: 345, height: 48, alignment: .topLeading)
            .background(Color(red: 0.14, green: 0.14, blue: 0.14, opacity: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
