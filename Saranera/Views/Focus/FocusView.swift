import SwiftUI

struct FocusView: View {
    @Environment(AudioManager.self) private var audioManager
    @State private var viewModel = FocusViewModel()
    @State private var showSoundPicker = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.051, green: 0.106, blue: 0.165),
                    Color(red: 0.078, green: 0.145, blue: 0.235)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Center content
                if viewModel.isTimerActive {
                    TimerRingView(
                        progress: viewModel.progress,
                        formattedTime: viewModel.formattedTime,
                        timerState: viewModel.timerState,
                        currentSession: viewModel.currentSession,
                        totalSessions: viewModel.sessionsBeforeLongBreak
                    )
                    .transition(.scale.combined(with: .opacity))
                } else if viewModel.timerState == .completed {
                    completedView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    idleView
                        .transition(.scale.combined(with: .opacity))
                }

                // Active sounds display
                ActiveSoundsView()

                Spacer()

                // Bottom controls
                bottomControls
            }
            .padding()
        }
        .animation(.spring(duration: 0.5), value: viewModel.timerState)
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.051, green: 0.106, blue: 0.165))
        }
        .onChange(of: viewModel.timerState) { oldState, newState in
            handleStateChange(from: oldState, to: newState)
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))

            Button {
                viewModel.startPomodoro()
            } label: {
                Label("Start Focus", systemImage: "play.fill")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)

            // Show config summary
            Text("\(Int(viewModel.focusDuration / 60))m focus · \(Int(viewModel.shortBreakDuration / 60))m break · \(viewModel.sessionsBeforeLongBreak) sessions")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color(red: 0.357, green: 0.608, blue: 0.835))

            Text("Session Complete")
                .font(.system(.title2, design: .rounded, weight: .medium))
                .foregroundStyle(.white)

            let focusMinutes = Int(viewModel.totalFocusSecondsAccumulated / 60)
            Text("\(focusMinutes) minutes of focus")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Button {
                viewModel.stop()
            } label: {
                Text("Done")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 16) {
                // Sound picker button
                Button {
                    showSoundPicker = true
                } label: {
                    Image(systemName: "music.note.list")
                        .font(.system(.title3))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)

                if viewModel.isTimerActive {
                    // Play/Pause button
                    Button {
                        if viewModel.isPaused {
                            viewModel.resume()
                        } else {
                            viewModel.pause()
                        }
                    } label: {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(.title2))
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.glassProminent)

                    // Stop or Skip button
                    if viewModel.timerState == .shortBreak || viewModel.timerState == .longBreak {
                        Button {
                            viewModel.skip()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(.title3))
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.glass)
                    } else {
                        Button {
                            viewModel.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(.title3))
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.isTimerActive)
        .animation(.spring(duration: 0.3), value: viewModel.isPaused)
    }

    // MARK: - State Change Handler

    private func handleStateChange(from oldState: FocusTimerState, to newState: FocusTimerState) {
        switch newState {
        case .focusing:
            if audioManager.isSuspended {
                audioManager.resumeAll()
            }
        case .shortBreak, .longBreak:
            audioManager.pauseAll()
        case .completed, .idle:
            break
        }
    }
}

#Preview {
    FocusView()
        .environment(AudioManager(audioEnabled: false))
}
