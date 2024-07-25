//
//  ContentView.swift
//  nante
//
//  Created by okamoto yuki on 2024/07/25.
//

import SwiftUI
import SwiftData
import Speech
import MLKitTranslate

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @StateObject private var speechRecognizer = JapaneseSpeechRecognizerWithTranslation()
    @State private var isRecording = false

    var body: some View {
        VStack {
            Button(action: {
                if isRecording {
                    speechRecognizer.stopTranscribing()
                } else {
                    speechRecognizer.startTranscribing()
                }
                isRecording.toggle()
            }) {
                Image(systemName: speechRecognizer.canUse ? (isRecording ? "stop.circle.fill" : "mic.circle.fill") : "mic.slash.circle.fill")
                    .font(.system(size: 40))
                    .padding()
                    .background(Circle().fill(Color.white))
            }.padding()
            Text(speechRecognizer.transcript)
                .padding()
            Text(speechRecognizer.translatedText)
                .padding()
        }.onAppear {
            speechRecognizer.requestAuthorization()
        }
    }
}

class JapaneseSpeechRecognizerWithTranslation: ObservableObject {
    @Published var transcript = ""
    @Published var translatedText: String = ""

    @Published var canUse = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))

    private var translator: Translator?

    init() {
        setupTranslator()
    }

    private func setupTranslator() {
        let options = TranslatorOptions(sourceLanguage: .japanese, targetLanguage: .english)
        self.translator = Translator.translator(options: options)

        let conditions = ModelDownloadConditions(
            allowsCellularAccess: false,
            allowsBackgroundDownloading: true
        )

        translator?.downloadModelIfNeeded(with: conditions) { error in
            if let error = error {
                print("Error downloading translation model: \(error)")
            } else {
                print("Translation model downloaded successfully")
            }
        }
    }

    func translate(_ text: String) {
        translator?.translate(text) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Translation error: \(error)")
                return
            }
            guard let result = result else {
                print("No translation result")
                return
            }
            DispatchQueue.main.async {
                self.translatedText = result
            }
        }
    }

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

        if speechRecognizer?.isAvailable != true {
            canUse = false
            return
        }

        canUse = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    func startTranscribing() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            return
        }

        do {
            recognitionTask?.cancel()

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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
