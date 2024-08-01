//
//  Language.swift
//  nante
//
//  Created by okamoto yuki on 2024/08/01.
//

enum Language: String, CaseIterable {
    case en = "English"
    case ja = "日本語"
    case ko = "한국어"
    case es = "Español"
    case fr = "Français"
    case de = "Deutsch"
    case it = "Italiano"

    var identifier: String {
        switch self {
        case .en:
            "en_US"
        case .ja:
            "ja_JP"
        case .ko:
            "ko_KR"
        case .es:
            "es_ES"
        case .fr:
            "fr_FR"
        case .de:
            "de_DE"
        case .it:
            "it_IT"
        }
    }

    static func from(language: String) -> Language? {
        Self.allCases.first { $0.rawValue == language }
    }
}
