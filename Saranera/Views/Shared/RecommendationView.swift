import SwiftUI

struct RecommendationView: View {
    var manager: RecommendationManager
    let mode: RecommendationMode
    let availableSounds: [Sound]
    let onApply: (SoundRecommendation) -> Void

    @State private var moodText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        switch manager.availability {
        case .notEligible:
            EmptyView()
        case .notEnabled:
            notEnabledView
        case .notReady:
            notReadyView
        case .available:
            availableView
        }
    }

    // MARK: - Not Enabled

    private var notEnabledView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.3))
            Text("Enable Apple Intelligence in Settings for smart recommendations")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal)
    }

    // MARK: - Not Ready

    private var notReadyView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.3))
            TextField("AI is getting ready...", text: .constant(""))
                .font(.system(.subheadline, design: .rounded))
                .disabled(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .capsule)
    }

    // MARK: - Available

    @ViewBuilder
    private var availableView: some View {
        VStack(spacing: 12) {
            switch manager.state {
            case .idle:
                moodInputView
            case .loading:
                loadingView
            case .streaming:
                streamingView
            case .completed:
                completedView
            case .error:
                errorView
            }
        }
    }

    // MARK: - Mood Input

    private var moodInputView: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.softBlue)

            TextField("Describe your mood...", text: $moodText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white)
                .focused($isTextFieldFocused)
                .onSubmit { submitMood() }

            if !moodText.isEmpty {
                Button {
                    submitMood()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(.title3))
                        .foregroundStyle(Color.softBlue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .capsule)
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("Thinking...")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(in: .capsule)
    }

    // MARK: - Streaming

    private var streamingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let partial = manager.partialResult, let sounds = partial.sounds {
                ForEach(Array(sounds.enumerated()), id: \.offset) { _, suggestion in
                    if let soundId = suggestion.soundId,
                       let sound = Sound.catalog.first(where: { $0.id == soundId }) {
                        HStack {
                            Image(systemName: sound.iconName)
                                .foregroundStyle(Color.softBlue)
                            Text(sound.name)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            if let volume = suggestion.volume {
                                Text("\(volume)%")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }

            if let partial = manager.partialResult, let reasoning = partial.reasoning {
                Text(reasoning)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            ProgressView()
                .tint(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let recommendation = manager.result {
                ForEach(Array(recommendation.sounds.enumerated()), id: \.offset) { _, suggestion in
                    if let sound = Sound.catalog.first(where: { $0.id == suggestion.soundId }) {
                        HStack {
                            Image(systemName: sound.iconName)
                                .foregroundStyle(Color.softBlue)
                            Text(sound.name)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(suggestion.volume)%")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(recommendation.timerMinutes) min")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    if mode == .sleep && recommendation.fadeOutMinutes > 0 {
                        Text("\u{00B7} \(recommendation.fadeOutMinutes) min fade")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Text(recommendation.reasoning)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: 12) {
                    Button {
                        onApply(recommendation)
                        manager.reset()
                        moodText = ""
                    } label: {
                        Label("Apply", systemImage: "checkmark")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glassProminent)

                    Button {
                        manager.reset()
                        moodText = ""
                    } label: {
                        Text("Dismiss")
                            .font(.system(.subheadline, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 8) {
            Text(manager.errorMessage ?? "Something went wrong")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Button {
                manager.reset()
            } label: {
                Text("Try again")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Actions

    private func submitMood() {
        guard !moodText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isTextFieldFocused = false
        Task {
            await manager.recommend(
                mood: moodText,
                mode: mode,
                availableSounds: availableSounds
            )
        }
    }
}
