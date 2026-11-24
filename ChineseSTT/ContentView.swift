
import SwiftUI
import UIKit

struct ContentView: View {

    @StateObject private var speech = SpeechRecognizer()

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                HStack {
                    Text("Language")
                    Spacer()
                    Text("繁體中文（台灣）")
                        .foregroundStyle(.secondary)
                }

                Toggle(
                    "On-device recognition",
                    isOn: $speech.useOnDevice
                )
                .disabled(
                    !speech.supportsOnDevice ||
                    speech.isRecording
                )

                if !speech.supportsOnDevice {
                    Text("On-device recognition is unavailable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Recognized text
                ScrollView {

                    Text(
                        speech.transcript.isEmpty
                        ? "Recognized text will appear here..."
                        : speech.transcript
                    )
                    .font(.system(size: 22))
                    .foregroundStyle(
                        speech.transcript.isEmpty
                        ? Color.secondary
                        : Color.primary
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
                }
                .frame(maxHeight: .infinity)
                .background(
                    Color(uiColor: .secondarySystemBackground)
                )
                .cornerRadius(12)

                // Copy and Clear buttons
                HStack(spacing: 20) {

                    Button {
                        UIPasteboard.general.string =
                            speech.transcript
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .disabled(speech.transcript.isEmpty)

                    Button {
                        speech.clearText()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(speech.isRecording)
                }
                .buttonStyle(.bordered)

                // Start / Stop button
                Button {

                    if speech.isRecording {
                        speech.finishRecording()
                    } else {
                        //speech.startRecording()
                        Task {
                            await speech.startRecording()
                        }
                    }

                } label: {

                    VStack(spacing: 10) {

                        Image(
                            systemName: speech.isRecording
                            ? "stop.fill"
                            : "mic.fill"
                        )
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                        .background(
                            speech.isRecording
                            ? Color.red
                            : Color.blue
                        )
                        .clipShape(Circle())

                        Text(
                            speech.isRecording
                            ? "Stop Recording"
                            : "Start Recording"
                        )
                        .font(.headline)
                    }
                }
                .disabled(!speech.isAuthorized)

                Text(
                    speech.isRecording
                    ? "Listening..."
                    : "Ready"
                )
                .foregroundStyle(
                    speech.isRecording
                    ? Color.red
                    : Color.secondary
                )

                if !speech.errorMessage.isEmpty {
                    Text(speech.errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Speech to Text")
        }
        .task {
            await speech.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
