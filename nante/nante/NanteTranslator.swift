//
//  NanteTranslator.swift
//  nante
//
//  Created by okamoto yuki on 2024/08/01.
//

import Foundation
import MLKitTranslate

class NanteTranslator: ObservableObject {
    @Published var translatedText: String = ""
    @Published var isLoading: Bool = true
    @Published var canUse: Bool = true

    private var translator: Translator?

    func configure(sourceLanguage: Language, targetLanguage: Language, onDownloadCompleted: (() -> Void)? = nil) {
        let options = TranslatorOptions(
            sourceLanguage: getTranslateLanguage(language: sourceLanguage),
            targetLanguage: getTranslateLanguage(language: targetLanguage)
        )
        translator = Translator.translator(options: options)

        let conditions = ModelDownloadConditions(
            allowsCellularAccess: false,
            allowsBackgroundDownloading: true
        )

        isLoading = true

        translator?.downloadModelIfNeeded(with: conditions) { [weak self] error in
            if let error = error {
                self?.canUse = false
            } else {
                onDownloadCompleted?()
            }
            self?.isLoading = false
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

    private func getTranslateLanguage(language: Language) -> TranslateLanguage {
        switch language {
        case .en:
                .english
        case .ja:
                .japanese
        case .ko:
                .korean
        case .es:
                .spanish
        case .fr:
                .french
        case .de:
                .german
        case .it:
                .italian
        }
    }
}
