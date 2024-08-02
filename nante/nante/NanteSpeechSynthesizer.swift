//
//  NanteSpeechSynthesizer.swift
//  nante
//
//  Created by okamoto yuki on 2024/08/01.
//

import Foundation
import AVFoundation

class NanteSpeechSynthesizer: NSObject, ObservableObject {
    @Published var isPlaying = false

    @Published private var synthesizer = AVSpeechSynthesizer()
    private var voice: AVSpeechSynthesisVoice?

    func requestAuthorization() {
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
            switch status {
            case .authorized: break;
            case .denied: break;
            case .notDetermined: break;
            case .unsupported: break;
            @unknown default: break;
            }
        }
    }

    func configure(language: Language) {
        synthesizer.delegate = self

        let personalVoice = AVSpeechSynthesisVoice.speechVoices().filter { speechVoice in
            speechVoice.voiceTraits.contains(.isPersonalVoice) && speechVoice.language == language.identifier
        }.first

        if let personalVoice {
            voice = personalVoice
        } else {
            voice = AVSpeechSynthesisVoice.init(language: language.identifier)
        }
    }

    func play(text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        isPlaying = true

        let utterance = AVSpeechUtterance.init(string: text)
        utterance.voice = voice
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        isPlaying = false
    }
}

extension NanteSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
    }
}
