//
//  NanteSpeechRecognizer.swift
//  nante
//
//  Created by okamoto yuki on 2024/08/01.
//

import Foundation
import Speech

class NanteSpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var canUse = false
    @Published var isRecording = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { (status) in
            switch status {
            case .authorized: break
            case .denied: break
            case .restricted: break
            case .notDetermined: break
            @unknown default: break
            }
        }

        canUse = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    func configure(language: Language) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language.identifier))
    }

    func startTranscribing() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            return
        }

        do {
            recognitionTask?.cancel()
            isRecording = true
            transcript = ""

            if audioEngine == nil {
                audioEngine = AVAudioEngine()
            }

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
            }
            recognitionRequest.shouldReportPartialResults = true

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            let inputNode = audioEngine!.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }

            audioEngine!.prepare()
            try audioEngine!.start()

        } catch {
            print("There was a problem starting the audio engine: \(error.localizedDescription)")
        }
    }

    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
    }
}
