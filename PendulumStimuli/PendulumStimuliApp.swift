import SwiftUI
import Combine

@available(macOS 13.0, *) // macOS Ventura
class MenuBarIconViewModel: ObservableObject {
    @Published var iconState: String = ".fill"
    private var timer: AnyCancellable?
    private var startTime: Date?
    @Published var slopeDurationMinutes: Double
    @Published var initialBPM: Double
    @Published var targetBPM: Double

    init(initialBPM: Double = 135, targetBPM: Double = 60, slopeDurationMinutes: Double = 30) {
        self.initialBPM = initialBPM
        self.targetBPM = targetBPM
        self.slopeDurationMinutes = slopeDurationMinutes
        self.startTime = Date()
        setupTimer()
    }

    private func setupTimer() {
        timer = Timer.publish(every: currentInterval(), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.toggleIconState()
                self?.adjustTimer()
            }
    }

    private func currentInterval() -> TimeInterval {
        let elapsedTime = Date().timeIntervalSince(startTime ?? Date())
        let progress = min(elapsedTime / (slopeDurationMinutes * 60), 1.0)
        let currentBPM = initialBPM - (initialBPM - targetBPM) * progress
        return 60 / currentBPM
    }

    private func adjustTimer() {
        timer?.cancel()
        timer = Timer.publish(every: currentInterval(), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.toggleIconState()
            }
    }

    private func toggleIconState() {
        iconState = iconState == "" ? ".fill" : ""
    }

    func setInitialBPM(bpm: Double) {
        initialBPM = bpm
        //resetTimer()
    }

    func setTargetBPM(bpm: Double) {
        targetBPM = bpm
        //resetTimer()
    }

    func setSlopeDuration(minutes: Double) {
        slopeDurationMinutes = minutes
        //resetTimer()
    }

    private func resetTimer() {
        startTime = Date()
        adjustTimer()
    }
}

@main
struct PendulumStimuliApp: App {
    @StateObject private var viewModel = MenuBarIconViewModel()

    var body: some Scene {
        let _ = NSApplication.shared.setActivationPolicy(.prohibited)

        MenuBarExtra("heart\(viewModel.iconState)", systemImage: "heart\(viewModel.iconState)") {
            VStack {
                initialBpmView
                targetBpmView
                slopeDurationView
                Divider()
                resetButton
                quitButton
            }
        }
    }

    private var initialBpmView: some View {
        VStack {
            Text("Initial BPM: \(viewModel.initialBPM, specifier: "%.0f")")
            HStack {
                Button("-5 BPM") { viewModel.setInitialBPM(bpm: max(viewModel.initialBPM - 5, 50)) }
                Button("+5 BPM") { viewModel.setInitialBPM(bpm: min(viewModel.initialBPM + 5, 150)) }
            }
        }
    }

    private var targetBpmView: some View {
        VStack {
            Text("Target BPM: \(viewModel.targetBPM, specifier: "%.0f")")
            HStack {
                Button("-5 BPM") { viewModel.setTargetBPM(bpm: max(viewModel.targetBPM - 5, 50)) }
                Button("+5 BPM") { viewModel.setTargetBPM(bpm: min(viewModel.targetBPM + 5, 150)) }
            }
        }
    }

    private var slopeDurationView: some View {
        VStack {
            Text("Slope Duration: \(Int(viewModel.slopeDurationMinutes)) Minutes")
            HStack {
                Button("-5min") { viewModel.setSlopeDuration(minutes: max(viewModel.slopeDurationMinutes - 5, 20)) }
                Button("+5min") { viewModel.setSlopeDuration(minutes: min(viewModel.slopeDurationMinutes + 5, 60)) }
            }
        }
    }

    private var resetButton: some View {
        Button("Reset to defaults") {
            viewModel.setInitialBPM(bpm: 135)
            viewModel.setSlopeDuration(minutes: 30)
        }
    }

    private var quitButton: some View {
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
