import SwiftUI

struct LibraryView: View {
    var body: some View {
        ZStack {
            Color(red: 0.051, green: 0.106, blue: 0.165)
                .ignoresSafeArea()

            Text("Library")
                .font(.system(.largeTitle, design: .rounded, weight: .light))
                .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
        }
    }
}

#Preview {
    LibraryView()
        .environment(AudioManager.shared)
}
