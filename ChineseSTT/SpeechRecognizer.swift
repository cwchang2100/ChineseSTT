//
//  SpeechRecognizer.swift
//  ChineseSTT
//
//  Created by Chih-Wei Chang on 2026/11/24.
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognizer: ObservableObject {

    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String = ""
    @Published var useOnDevice: Bool = true

    private let speechRecognizer = SFSpeechRecognizer(
        locale: Locale(identifier: "zh-TW")
    )

    private let audioEngine = AVAudioEngine()

    private var recognitionRequest:
        SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask:
        SFSpeechRecognitionTask?

    private var tapInstalled = false

    var supportsOnDevice: Bool {
        speechRecognizer?.supportsOnDeviceRecognition ?? false
    }

    // Request permissions
    func requestAuthorization() async {

        let speechStatus = await withCheckedContinuation {
            continuation in

            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let microphoneGranted =
            await AVAudioApplication.requestRecordPermission()

        isAuthorized =
            speechStatus == .authorized && microphoneGranted

        if !isAuthorized {
            errorMessage = "Speech or microphone permission denied."
        }
    }

    // Start speech recognition
    func startRecording() {

        guard isAuthorized else {
            errorMessage = "Permission not granted."
            return
        }

        guard let recognizer = speechRecognizer,
              recognizer.isAvailable else {
            errorMessage = "Speech recognition is unavailable."
            return
        }

        if useOnDevice && !supportsOnDevice {
            errorMessage = "On-device recognition is not supported."
            return
        }

        stopRecording()

        errorMessage = ""
        transcript = ""

        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .record,
                mode: .measurement,
                options: []
            )

            try audioSession.setActive(true)

            let request = SFSpeechAudioBufferRecognitionRequest()

            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = useOnDevice

            recognitionRequest = request

            let inputNode = audioEngine.inputNode

            let recordingFormat =
                inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0,
                  recordingFormat.channelCount > 0 else {
                errorMessage = "Invalid microphone audio format."
                stopRecording()
                return
            }

            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: recordingFormat
            ) { buffer, _ in

                request.append(buffer)
            }

            tapInstalled = true

            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true

            recognitionTask = recognizer.recognitionTask(
                with: request
            ) { [weak self] result, error in

                let text =
                    result?.bestTranscription.formattedString

                let isFinal = result?.isFinal ?? false
                let errorText = error?.localizedDescription

                Task { @MainActor [weak self] in

                    guard let self = self,
                          self.recognitionRequest === request else {
                        return
                    }

                    if let text = text {
                        self.transcript = text
                    }

                    if let errorText = errorText {
                        self.errorMessage = errorText
                    }

                    if isFinal || errorText != nil {
                        self.stopRecording()
                    }
                }
            }

        } catch {
            errorMessage = error.localizedDescription
            stopRecording()
        }
    }

    // Stop microphone and finalize recognition
    func finishRecording() {

        audioEngine.stop()

        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        recognitionRequest?.endAudio()
        isRecording = false
    }

    // Release recognition resources
    func stopRecording() {

        finishRecording()

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    func clearText() {
        transcript = ""
    }
}
