//
//  ContentViewModel.swift
//  nante
//
//  Created by okamoto yuki on 2024/08/01.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {
    @Published var canRecord: Bool = false
    @Published var isRecording = false

    @Published var canTranslate: Bool = false
    @Published var isLoading: Bool = true

    @Published var canPlay = false
    @Published var isPlaying = false

    @Published var transcript: String = ""
    @Published var translatedText: String = ""

    @Published var selectedSpeechRecognitionLanguage: String = Language.allCases[0].rawValue {
        didSet {
            if oldValue != selectedSpeechRecognitionLanguage {
                selectedSpeechRecognitionLanguageChanged()
            }
        }
    }

    @Published var selectedTranslationLanguage: String = Language.allCases[1].rawValue {
        didSet {
            if oldValue != selectedTranslationLanguage {
                selectedTranslationLanguageChanged()
            }
        }
    }

    @Published private var speechRecognizer = NanteSpeechRecognizer()
    @Published private var translator = NanteTranslator()
    @Published private var speechSynthesizer = NanteSpeechSynthesizer()

    private var cancellables = Set<AnyCancellable>()

    private let languages = Language.allCases.map { $0.rawValue }

    init() {
        speechRecognizer.$canUse
            .sink { [weak self] canUse in
                self?.canRecord = canUse
            }
            .store(in: &cancellables)

        speechRecognizer.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)

        speechRecognizer.$transcript
            .sink { [weak self] transcript in
                self?.transcript = transcript
            }
            .store(in: &cancellables)

        translator.$translatedText
            .sink { [weak self] translatedText in
                self?.translatedText = translatedText
                self?.canPlay = !translatedText.isEmpty
            }
            .store(in: &cancellables)

        translator.$canUse
            .sink { [weak self] canUse in
                self?.canTranslate = canUse
            }
            .store(in: &cancellables)

        translator.$isLoading
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)

        speechSynthesizer.$isPlaying
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
            }
            .store(in: &cancellables)

        let sourceLanguage = Language.from(language: selectedSpeechRecognitionLanguage)!
        let targetLanguage = Language.from(language: selectedTranslationLanguage)!
        speechRecognizer.configure(language: sourceLanguage)
        translator.configure(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        speechSynthesizer.configure(language: targetLanguage)
    }

    var speechRecognitionLanguages: [String] {
        languages
    }

    var translationLanguages: [String] {
        languages.filter { $0 != selectedSpeechRecognitionLanguage }
    }

    func requestAuthorization() {
        speechRecognizer.requestAuthorization()
    }

    func startTranscribing() {
        speechRecognizer.startTranscribing()
    }

    func stopTranscribing() {
        speechRecognizer.stopTranscribing()
        translator.translate(transcript)
    }

    func playSpeak() {
        speechSynthesizer.play(text: translatedText)
    }

    func stopSpeak() {
        speechSynthesizer.stop()
    }

    private func selectedSpeechRecognitionLanguageChanged() {
        let sourceLanguage = Language.from(language: selectedSpeechRecognitionLanguage)!
        speechRecognizer.configure(language: sourceLanguage)

        speechRecognizer.transcript = ""
        translator.translatedText = ""

        if selectedSpeechRecognitionLanguage == selectedTranslationLanguage {
            selectedTranslationLanguage = translationLanguages.first!
        }
    }

    private func selectedTranslationLanguageChanged() {
        if selectedSpeechRecognitionLanguage == selectedTranslationLanguage {
            selectedTranslationLanguage = translationLanguages.first!
            return
        }

        let sourceLanguage = Language.from(language: selectedSpeechRecognitionLanguage)!
        let targetLanguage = Language.from(language: selectedTranslationLanguage)!
        translator.configure(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage) { [weak self] in
            if self?.canTranslate == true,
               let transcript = self?.transcript,
               !transcript.isEmpty {
                self?.translator.translate(transcript)
            } else {
                self?.translator.translatedText = ""
            }
        }
        speechSynthesizer.configure(language: targetLanguage)
    }
}
