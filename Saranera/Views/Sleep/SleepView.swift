import SwiftUI

struct SleepView: View {
    var body: some View {
        ZStack {
            Color(red: 0.051, green: 0.106, blue: 0.165) // Deep Navy #0D1B2A
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835)) // Soft Blue #5B9BD5

                Text("Sleep")
                    .font(.system(.largeTitle, design: .rounded, weight: .light))
                    .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))
            }
        }
    }
}

#Preview {
    SleepView()
}
