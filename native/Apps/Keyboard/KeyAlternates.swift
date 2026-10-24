/* The long-press alternates for letter keys, matching Apple's iOS 17+ English (US) keyboard.
 KeyplaneView injects `KeyAlternates.actions(for:standard:)` through KeyboardKit's
 `keyboardCalloutActions` hook; KeyboardKit draws the callout, tracks the slide and types the
 chosen letter. Only the eleven letters Apple gives alternates (a c e i l n o s u y z) get a
 callout; numbers and punctuation keep KeyboardKit's standard table. Each list starts with the
 plain letter, so lifting without sliding types it, as KeyboardKit's own table does.
 Sources and the remaining on-device check are in docs/verification/keyboard-feel-2026-10-24.md (G5). */
import Foundation
import KeyboardKit

enum KeyAlternates {
    /// Lowercase lists in the order the source catalogue gives them. KeyboardKit mirrors the list
    /// for keys on the right half of the keyboard, as Apple's callout does.
    static let lowercase: [String: String] = [
        "a": "aàáâäæãåāǎăą",
        "c": "cçćčċ",
        "e": "eèéêëēėęěẽ",
        "i": "iìįīíïîıĩǐ",
        "l": "lłľļ",
        "n": "nńñňņ",
        "o": "oõōøœóòöôőǒ",
        "s": "sßśšşș",
        "u": "uūúùüûųůűũǔ",
        "y": "yÿŷý",
        "z": "zžźż"
    ]

    /// Lowercase and uppercase keys mapped to their callout actions, built once.
    /// Uppercase drops alternates that have no single-character capital (ß) or whose capital is
    /// the plain letter itself (dotless ı becomes I).
    static let table: [String: [KeyboardAction]] = {
        var result: [String: [KeyboardAction]] = [:]
        for (letter, list) in lowercase {
            result[letter] = list.map { .character(String($0)) }
            let capital = letter.uppercased()
            var capitals = [capital]
            for alternate in list.dropFirst() {
                let upper = String(alternate).uppercased()
                if upper.count == 1, upper != capital, !capitals.contains(upper) { capitals.append(upper) }
            }
            result[capital] = capitals.map { .character($0) }
        }
        return result
    }()

    /// Letters return Apple's list, or no callout when Apple has none; every other key keeps
    /// KeyboardKit's standard actions (digits, currency, punctuation, URL domains).
    static func actions(for action: KeyboardAction, standard: () -> [KeyboardAction]?) -> [KeyboardAction]? {
        guard case .character(let text) = action, text.count == 1,
              let scalar = text.unicodeScalars.first, CharacterSet.letters.contains(scalar) else { return standard() }
        return table[text] ?? []
    }
}
