
import SwiftUI
import UIKit

struct ContentView: View {

    @StateObject private var speech = SpeechRecognizer()

    @StateObject private var webController = WebViewController()

    @State private var autoInsert = false

    @State private var urlString = "https://chatgpt.com/"

    //@State private var fieldSelector = "#speechInput"
    @State private var fieldSelector = "[contenteditable='true']"

    var body: some View {

        NavigationStack {

            VStack(spacing: 10) {

                // URL address bar
                HStack {

                    TextField("URL", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    Button("Go") {
                        webController.loadURL(urlString)
                        //webController.loadLocalHTML()
                    }

                    Button {
                        webController.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }

                // Embedded web page
                WebView(
                    webView: webController.webView
                )
                .frame(maxHeight: .infinity)
                .border(Color.gray.opacity(0.3))

                Divider()

                // Target HTML field
                HStack {

                    Text("Selector:")

                    TextField(
                        "CSS selector",
                        text: $fieldSelector
                    )
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }

                // Automatic text insertion
                Toggle(
                    "Auto insert recognized text",
                    isOn: $autoInsert
                )

                Toggle(
                    "On-device recognition",
                    isOn: $speech.useOnDevice
                )
                .disabled(
                    !speech.supportsOnDevice ||
                    speech.isRecording
                )

                // Recognized text
                ScrollView {

                    Text(
                        speech.transcript.isEmpty
                        ? "Recognized text..."
                        : speech.transcript
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(8)
                }
                .frame(height: 90)
                .background(
                    Color(uiColor: .secondarySystemBackground)
                )
                .cornerRadius(8)

                // Text operation buttons
                HStack {

                    Button {
                        Task {
                            await webController.insertText(
                                speech.transcript,
                                selector: fieldSelector
                            )
                        }
                    } label: {
                        Label(
                            "Insert",
                            systemImage: "arrow.up"
                        )
                    }
                    .disabled(speech.transcript.isEmpty)

                    Button {
                        UIPasteboard.general.string =
                            speech.transcript
                    } label: {
                        Label(
                            "Copy",
                            systemImage: "doc.on.doc"
                        )
                    }

                    Button {
                        speech.clearText()
                    } label: {
                        Label(
                            "Clear",
                            systemImage: "trash"
                        )
                    }
                    .disabled(speech.isRecording)
                }
                .buttonStyle(.bordered)

                // Recording button
                Button {

                    if speech.isRecording {

                        speech.finishRecording()

                    } else {

                        Task {
                            await speech.startRecording()
                        }
                    }

                } label: {

                    HStack {

                        Image(
                            systemName: speech.isRecording
                            ? "stop.fill"
                            : "mic.fill"
                        )

                        Text(
                            speech.isRecording
                            ? "Stop Recording"
                            : "Start Recording"
                        )
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        speech.isRecording
                        ? Color.red
                        : Color.blue
                    )
                    .cornerRadius(12)
                }
                .disabled(!speech.isAuthorized)

                // Error messages
                if !speech.errorMessage.isEmpty {

                    Text(speech.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if !webController.errorMessage.isEmpty {

                    Text(webController.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding(10)
            .navigationTitle("Speech to Text")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {

            webController.loadURL(urlString)
            //webController.loadLocalHTML() // for testing only

            await speech.requestAuthorization()
        }
        .onChange(of: speech.transcript) { _, newValue in

            if autoInsert && !newValue.isEmpty {

                Task {

                    await webController.insertText(
                        newValue,
                        selector: fieldSelector
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
