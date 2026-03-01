import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let formattedTime: String
    let timerState: FocusTimerState
    let currentSession: Int
    let totalSessions: Int

    private var ringColor: Color {
        switch timerState {
        case .focusing:
            Color.softBlue // Soft Blue
        case .shortBreak, .longBreak:
            Color.warmAmber // Amber
        case .idle, .completed:
            Color.softBlue
        }
    }

    private var phaseLabel: String {
        switch timerState {
        case .idle: "Ready"
        case .focusing: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        case .completed: "Complete"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(ringColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 240, height: 240)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time display
                Text(formattedTime)
                    .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            // Phase label
            Text(phaseLabel)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            // Session dots
            HStack(spacing: 8) {
                ForEach(1...totalSessions, id: \.self) { session in
                    Circle()
                        .fill(session <= currentSession ? ringColor : ringColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.deepNavy.ignoresSafeArea()
        TimerRingView(
            progress: 0.65,
            formattedTime: "16:15",
            timerState: .focusing,
            currentSession: 2,
            totalSessions: 4
        )
    }
}
