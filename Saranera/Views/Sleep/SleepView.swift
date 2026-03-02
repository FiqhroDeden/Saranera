import Combine
import SwiftUI

struct SleepView: View {
    @Environment(AudioManager.self) private var audioManager
    @State private var viewModel = SleepViewModel()
    @State private var showSoundPicker = false
    @State private var recommendationManager = RecommendationManager()

    // Auto-dim
    @State private var lastInteractionDate = Date()
    @State private var isDimmed = false

    // Duration presets in minutes
    private let durationPresets: [Int] = [15, 30, 45, 60, 90]
    // Fade presets in minutes (0 = instant)
    private let fadePresets: [Int] = [0, 2, 5, 10, 15]

    var body: some View {
        ZStack {
            // Background — darker than Focus
            LinearGradient(
                colors: [.black, .deepNavy],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Center content
                switch viewModel.timerState {
                case .idle:
                    idleView
                        .transition(.scale.combined(with: .opacity))
                case .playing, .fadingOut:
                    activeView
                        .transition(.scale.combined(with: .opacity))
                case .completed:
                    completedView
                        .transition(.scale.combined(with: .opacity))
                }

                // Active sounds
                ActiveSoundsView()

                Spacer()

                // Bottom controls
                bottomControls
            }
            .padding()
            .opacity(isDimmed && viewModel.isActive ? 0.15 : 1.0)
            .animation(.spring(duration: 1.0), value: isDimmed)
        }
        .animation(.spring(duration: 0.5), value: viewModel.timerState)
        .onAppear { recommendationManager.checkAvailability() }
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.deepNavy)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            checkAutoDim()
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 32) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.warmAmber.opacity(0.7))

            RecommendationView(
                manager: recommendationManager,
                mode: .sleep,
                availableSounds: Sound.catalog.filter { !$0.isPremium },
                onApply: { recommendation in
                    applySleepRecommendation(recommendation)
                }
            )

            durationPicker

            fadePicker

            // Start button
            Button {
                viewModel.start(audioManager: audioManager)
                resetDimTimer()
            } label: {
                Label("Start Sleep", systemImage: "moon.fill")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .tint(Color.warmAmber)
        }
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        VStack(spacing: 8) {
            Text("Sleep Timer")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))

            HStack(spacing: 12) {
                ForEach(durationPresets, id: \.self) { minutes in
                    durationButton(minutes: minutes)
                }
            }
        }
    }

    @ViewBuilder
    private func durationButton(minutes: Int) -> some View {
        let isSelected = viewModel.selectedDuration == TimeInterval(minutes * 60)
        if isSelected {
            Button {
                viewModel.selectedDuration = TimeInterval(minutes * 60)
            } label: {
                Text("\(minutes)m")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button {
                viewModel.selectedDuration = TimeInterval(minutes * 60)
            } label: {
                Text("\(minutes)m")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Fade Picker

    private var fadePicker: some View {
        VStack(spacing: 8) {
            Text("Fade Out")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))

            HStack(spacing: 12) {
                ForEach(fadePresets, id: \.self) { minutes in
                    fadeButton(minutes: minutes)
                }
            }
        }
    }

    @ViewBuilder
    private func fadeButton(minutes: Int) -> some View {
        let isSelected = viewModel.selectedFadeOut == TimeInterval(minutes * 60)
        let label = minutes == 0 ? "Off" : "\(minutes)m"
        if isSelected {
            Button {
                viewModel.selectedFadeOut = TimeInterval(minutes * 60)
            } label: {
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button {
                viewModel.selectedFadeOut = TimeInterval(minutes * 60)
            } label: {
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
        }
    }

    private func applySleepRecommendation(_ recommendation: SoundRecommendation) {
        audioManager.stopAll()
        for suggestion in recommendation.sounds {
            if let sound = Sound.catalog.first(where: { $0.id == suggestion.soundId }) {
                audioManager.play(sound: sound)
                audioManager.setVolume(for: sound, to: Float(suggestion.volume) / 100.0)
            }
        }
        viewModel.selectedDuration = TimeInterval(recommendation.timerMinutes * 60)
        viewModel.selectedFadeOut = TimeInterval(recommendation.fadeOutMinutes * 60)
    }

    // MARK: - Active View (Playing / Fading)

    private var activeView: some View {
        VStack(spacing: 16) {
            // Large timer digits
            Text(viewModel.formattedTime)
                .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                .foregroundStyle(.white.opacity(timerDigitOpacity))
                .monospacedDigit()
                .contentTransition(.numericText())

            if viewModel.timerState == .fadingOut {
                Text("Fading out...")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.warmAmber.opacity(0.5))
            }
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 16) {
            Text("Good night")
                .font(.system(.title, design: .rounded, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                // Sound picker
                Button {
                    showSoundPicker = true
                    resetDimTimer()
                } label: {
                    Image(systemName: "music.note.list")
                        .font(.system(.title3))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)

                if viewModel.isActive {
                    // Stop button
                    Button {
                        viewModel.stop()
                        resetDimTimer()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(.title2))
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.warmAmber)
                }
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.isActive)
    }

    // MARK: - Timer Digit Opacity

    private var timerDigitOpacity: Double {
        let progress = viewModel.timerProgress
        return 1.0 - (progress * 0.7)
    }

    // MARK: - Auto-Dim

    private func handleTap() {
        resetDimTimer()
    }

    private func resetDimTimer() {
        lastInteractionDate = Date()
        isDimmed = false
    }

    private func checkAutoDim() {
        guard viewModel.isActive else {
            isDimmed = false
            return
        }
        let elapsed = Date().timeIntervalSince(lastInteractionDate)
        if elapsed >= 30 && !isDimmed {
            isDimmed = true
        }
    }
}

#Preview {
    SleepView()
        .environment(AudioManager(audioEnabled: false))
}
