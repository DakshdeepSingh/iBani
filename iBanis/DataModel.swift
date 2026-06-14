//
//  DataModel.swift — Updated (Hindi translation + Devanagari transliteration fallback)
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 25/03/25.
//  Updated on 24/08/25:
//  - Robust decoder for Hindi translations (handles string/object/array providers)
//  - Falls back to Hindi *transliteration* (Devanagari) when translation is missing
//  - Requests both: translation=en,hi and transliteration=hi
//

import Foundation
import Combine

// MARK: - Bani Categories

enum BaniCategory: String, CaseIterable {
//    case guruGranth = "ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ"
//    case dasamGranth = "ਦਸਮ ਗ੍ਰੰਥ"
//    case sarbloh = "ਸਰਬਲੋਹ ਗ੍ਰੰਥ "
    case sarvGranth = "ਸਰਵ ਗ੍ਰੰਥ"
    case nitnem = "ਨਿਤਨੇਮ"
    case dasam = "ਦਸਮ ਦਰਬਾਰ"
    case raag = "ਰਾਗ ਦਰਬਾਰ"
    //case others = " "
    var id: String { rawValue }
}

// MARK: - Helpers for dynamic keys / flexible provider decoding

/// Dynamic CodingKey for unknown keys
private struct AnyKey: CodingKey {
    var stringValue: String; init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }; init?(intValue: Int) { return nil }
}

/// Decodes a provider value that could be a String, an object with {text: "..."} or {translation: "..."} or {value: "..."},
/// or an array of such entries. We extract a single best string.
private struct ProviderValue: Codable {
    let best: String?

    init(from decoder: Decoder) throws {
        // 1) Try a direct string
        if let sv = try? decoder.singleValueContainer(), let s = try? sv.decode(String.self) {
            best = s
            return
        }
        // 2) Try object { text: ... } / { translation: ... } / { value: ... }
        if let obj = try? decoder.container(keyedBy: AnyKey.self) {
            if let tKey = AnyKey(stringValue: "text"), let t = try? obj.decode(String.self, forKey: tKey) { best = t; return }
            if let trKey = AnyKey(stringValue: "translation"), let tr = try? obj.decode(String.self, forKey: trKey) { best = tr; return }
            if let vKey = AnyKey(stringValue: "value"), let v = try? obj.decode(String.self, forKey: vKey) { best = v; return }
            best = nil
            return
        }
        // 3) Try an array of mixed entries and take the first successful text
        if var arr = try? decoder.unkeyedContainer() {
            var first: String? = nil
            while !arr.isAtEnd {
                if let pv = try? arr.decode(ProviderValue.self), let b = pv.best, !b.isEmpty { first = b; break }
                _ = try? arr.decode(Dummy.self) // skip unknown item
            }
            best = first
            return
        }
        // Fallback
        best = nil
    }
    private struct Dummy: Codable {}
}

private extension KeyedDecodingContainer where K == AnyKey {
    /// Finds the first decodable ProviderValue with a non-empty best string.
    func firstProviderBest() -> String? {
        for key in allKeys {
            if let pv = try? decode(ProviderValue.self, forKey: key), let s = pv.best, !s.isEmpty {
                return s
            }
        }
        return nil
    }
}

// MARK: - API-Level BaniLine Model (for decoding from banidb)

struct BaniLine: Identifiable, Codable {
    let id: Int
    let line: String
    let translation: String?          // English translation (if available)
    let hindiTranslation: String?     // Hindi translation or Devanagari transliteration fallback

    enum RootKeys: String, CodingKey { case verse }
    enum VerseLevel1Keys: String, CodingKey { case verseId, verse, translation, transliteration, transliterations }
    enum InnerVerseKeys: String, CodingKey { case gurmukhi }
    enum TranslationKeys: String, CodingKey { case en, hi, hindi }
    enum TransliterationKeys: String, CodingKey { case hi, hindi }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        let verseContainer = try container.nestedContainer(keyedBy: VerseLevel1Keys.self, forKey: .verse)
        id = try verseContainer.decode(Int.self, forKey: .verseId)
        let inner = try verseContainer.nestedContainer(keyedBy: InnerVerseKeys.self, forKey: .verse)
        line = try inner.decode(String.self, forKey: .gurmukhi)

        // --- English translation ---
        var english: String? = nil
        if let t = try? verseContainer.nestedContainer(keyedBy: TranslationKeys.self, forKey: .translation) {
            if let enDict = try? t.decode([String: ProviderValue].self, forKey: .en) {
                english = enDict.values.compactMap { $0.best }.first
            } else if let enNest = try? t.nestedContainer(keyedBy: AnyKey.self, forKey: .en) {
                english = enNest.firstProviderBest()
            }
        }
        self.translation = english

        // --- Hindi translation (preferred) ---
        var hindi: String? = nil
        if let t = try? verseContainer.nestedContainer(keyedBy: TranslationKeys.self, forKey: .translation) {
            if let hiDict = try? t.decode([String: ProviderValue].self, forKey: .hi) {
                hindi = hiDict.values.compactMap { $0.best }.first
            } else if let hiNest = try? t.nestedContainer(keyedBy: AnyKey.self, forKey: .hi) {
                hindi = hiNest.firstProviderBest()
            } else if let hindiDict = try? t.decode([String: ProviderValue].self, forKey: .hindi) {
                hindi = hindiDict.values.compactMap { $0.best }.first
            } else if let hindiNest = try? t.nestedContainer(keyedBy: AnyKey.self, forKey: .hindi) {
                hindi = hindiNest.firstProviderBest()
            }
        }

        // --- Fallback: Hindi *transliteration* (Devanagari) ---
        if (hindi == nil || hindi?.isEmpty == true) {
            // Some responses use a single field `transliteration` or a dict `transliterations`
            if let singleTL = try? verseContainer.decode(String.self, forKey: .transliteration), !singleTL.isEmpty {
                hindi = singleTL
            } else if let tl = try? verseContainer.nestedContainer(keyedBy: TransliterationKeys.self, forKey: .transliterations) {
                if let hi = try? tl.decode(String.self, forKey: .hi), !hi.isEmpty {
                    hindi = hi
                } else if let hindiStr = try? tl.decode(String.self, forKey: .hindi), !hindiStr.isEmpty {
                    hindi = hindiStr
                } else if let any = try? verseContainer.nestedContainer(keyedBy: AnyKey.self, forKey: .transliterations) {
                    hindi = any.firstProviderBest()
                }
            } else if let any = try? verseContainer.nestedContainer(keyedBy: AnyKey.self, forKey: .transliteration) {
                hindi = any.firstProviderBest()
            }
        }

        self.hindiTranslation = hindi
    }

    init(id: Int, line: String, translation: String?, hindiTranslation: String?) {
        self.id = id
        self.line = line
        self.translation = translation
        self.hindiTranslation = hindiTranslation
    }
}

// MARK: - API-Level Bani Model

struct Bani: Codable {
    let id: Int
    let name: String
    let lines: [BaniLine]

    enum CodingKeys: String, CodingKey {
        case baniInfo
        case verses
    }

    enum BaniInfoKeys: String, CodingKey {
        case id = "baniID"
        case gurmukhi
        case gurmukhiUni
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var info = container.nestedContainer(keyedBy: BaniInfoKeys.self, forKey: .baniInfo)
        try info.encode(id, forKey: .id)
        try info.encode(name, forKey: .gurmukhiUni)
        try container.encode(lines, forKey: .verses)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let info = try container.nestedContainer(keyedBy: BaniInfoKeys.self, forKey: .baniInfo)
        id = try info.decode(Int.self, forKey: .id)
        if let unicode = try? info.decode(String.self, forKey: .gurmukhiUni) {
            name = unicode
        } else {
            name = try info.decode(String.self, forKey: .gurmukhi)
        }
        lines = try container.decode([BaniLine].self, forKey: .verses)
    }

    init(id: Int, name: String, lines: [BaniLine]) {
        self.id = id
        self.name = name
        self.lines = lines
    }
}

// MARK: - Simple Codable Models for Local Storage

struct SimpleBaniLine: Codable {
    let id: Int
    let line: String
    let translation: String?
    let hindiTranslation: String?
}

struct SimpleBani: Codable {
    let id: Int
    let name: String
    let lines: [SimpleBaniLine]
}

// MARK: - BaniType

enum BaniType: String, CaseIterable, Identifiable, Codable {
    case japjiSahib, jaapSahib, tavPrasadSavaiye, chaupaiSahib, anandSahib, rehrasSahib, kirtanSohila, sukhmaniSahib
    case shabadHazareP10, svaiyeDeenan, chandiDiVaar, ardaas, aarti
    case asaDiVaar, dakhniOankar, sidhGosht, bavanAkhree, jaitsreeVaar, ramkaliVaar, basantVaar, baarehMaahaTukhari, salokMahalla9, raagmala
    case guruGranthSahibJi, dasamGranth, sarblohGranth

    var id: String { rawValue }

    var numericID: Int {
        switch self {
        case .japjiSahib: return 2
        case .jaapSahib: return 4
        case .tavPrasadSavaiye: return 6
        case .chaupaiSahib: return 9
        case .anandSahib: return 10
        case .rehrasSahib: return 21
        case .kirtanSohila: return 23
        case .sukhmaniSahib: return 31
        case .shabadHazareP10: return 5
        case .svaiyeDeenan: return 7
        case .chandiDiVaar: return 13
        case .ardaas: return 24
        case .aarti: return 22
        case .asaDiVaar: return 90
        case .dakhniOankar: return 35
        case .sidhGosht: return 34
        case .bavanAkhree: return 33
        case .jaitsreeVaar: return 96
        case .ramkaliVaar: return 100
        case .basantVaar: return 104
        case .baarehMaahaTukhari: return 28
        case .salokMahalla9: return 30
        case .raagmala: return 38
        default: return -1
        }
    }

    var displayTitle: String {
        switch self {
        case .japjiSahib: return "ਜਪੁਜੀ ਸਾਹਿਬ"
        case .jaapSahib: return "ਜਾਪੁ ਸਾਹਿਬ"
        case .tavPrasadSavaiye: return "ਤ੍ਵ ਪ੍ਰਸਾਦਿ ਸਵੱਯੇ"
        case .chaupaiSahib: return "ਬੇਨਤੀ ਚੌਪਈ ਸਾਹਿਬ"
        case .anandSahib: return "ਆਨੰਦ ਸਾਹਿਬ"
        case .rehrasSahib: return "ਰਹਰਾਸਿ ਸਾਹਿਬ"
        case .kirtanSohila: return "ਕੀਰਤਨ ਸੋਹਿਲਾ"
        case .sukhmaniSahib: return "ਸੁਖਮਨੀ ਸਾਹਿਬ"
        case .shabadHazareP10: return "ਸ਼ਬਦ ਹਜ਼ਾਰੇ ਪਾ: ੧੦"
        case .svaiyeDeenan: return "ਸਵੈਯੇ ਦੀਨਨ ਕੇ"
        case .chandiDiVaar: return "ਚੰਡੀ ਦੀ ਵਾਰ"
        case .ardaas: return "ਅਰਦਾਸ"
        case .aarti: return "ਆਰਤੀ-ਆਰਤਾ"
        case .asaDiVaar: return "ਆਸਾ ਦੀ ਵਾਰ"
        case .dakhniOankar: return "ਦਖਣੀ ਓਅੰਕਾਰ"
        case .sidhGosht: return "ਸਿਧ ਗੋਸਟ"
        case .bavanAkhree: return "ਬਾਵਨ ਅਖਰੀ"
        case .jaitsreeVaar: return "ਜੈਤਸਰੀ ਕੀ ਵਾਰ"
        case .ramkaliVaar: return "ਰਾਮਕਲੀ ਕੀ ਵਾਰ"
        case .basantVaar: return "ਬਸੰਤ ਕੀ ਵਾਰ"
        case .baarehMaahaTukhari: return "ਬਾਰਹ ਮਾਹਾ ਤੁਖਾਰੀ"
        case .salokMahalla9: return "ਸਲੋਕ ਮਹਲਾ ੯"
        case .raagmala: return "ਰਾਗਮਾਲਾ"
        case .sarblohGranth: return "ਸਰਬਲੋਹ ਗ੍ਰੰਥ ਜੀ"
        case .guruGranthSahibJi: return "ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ"
        case .dasamGranth: return "ਦਸਮ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ"
        default: return " "
        }
    }

    var category: BaniCategory {
        switch self {
        case .japjiSahib, .jaapSahib, .tavPrasadSavaiye, .chaupaiSahib, .anandSahib, .rehrasSahib, .kirtanSohila, .sukhmaniSahib:
            return .nitnem
        case .shabadHazareP10, .svaiyeDeenan, .chandiDiVaar, .ardaas, .aarti:
            return .dasam
        case .asaDiVaar, .dakhniOankar, .sidhGosht, .bavanAkhree, .jaitsreeVaar, .ramkaliVaar, .basantVaar, .baarehMaahaTukhari, .salokMahalla9, .raagmala:
            return .raag
        case .guruGranthSahibJi, .dasamGranth, .sarblohGranth:
            return .sarvGranth
        }
    }
}

// MARK: - Banis Cache (on-disk)

class Banis {
    private var banis: [BaniType: Bani] = [:]
    static let shared = Banis()
    private init() { loadFromDisk() }

    private let fileName = "cachedBanis.json"
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(fileName)
    }

    public func addBani(_ bani: Bani, withType type: BaniType) {
        banis[type] = bani
        saveToDisk()
    }

    public func getBani(withType type: BaniType) -> Bani? {
        loadFromDisk()
        return banis[type]
    }

    public func saveToDisk() {
        let simpleDict: [BaniType: SimpleBani] = banis.mapValues { bani in
            SimpleBani(
                id: bani.id,
                name: bani.name,
                lines: bani.lines.map { SimpleBaniLine(id: $0.id, line: $0.line, translation: $0.translation, hindiTranslation: $0.hindiTranslation) }
            )
        }
        do {
            let data = try JSONEncoder().encode(simpleDict)
            try data.write(to: fileURL)
            print("✅ Banis saved to disk at \(fileURL)")
        } catch {
            print("❌ Error saving banis to disk:", error)
        }
    }

    public func loadFromDisk() {
        self.banis = [:]
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("📂 No banis file found.")
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let simpleBanis = try JSONDecoder().decode([BaniType: SimpleBani].self, from: data)
            self.banis = simpleBanis.mapValues { simple in
                let lines = simple.lines.map { BaniLine(id: $0.id, line: $0.line, translation: $0.translation, hindiTranslation: $0.hindiTranslation) }
                return Bani(id: simple.id, name: simple.name, lines: lines)
            }
            print("✅ Banis loaded from disk.")
        } catch {
            print("❌ Error loading banis from disk:", error)
        }
    }

    public func clearCacheFromDisk() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                banis.removeAll()
                print("🧹 Banis cache cleared.")
            }
        } catch {
            print("❌ Failed to clear cache:", error)
        }
    }
}

// MARK: - Observable Data Model

class BaniDataModel: ObservableObject {
    static let shared = BaniDataModel()
    private init() {}

    @Published var currentBani: Bani?
    @Published var isLoading = false

    private func makeURL(for id: Int) -> URL? {
        // Ask for both translations and transliteration (Devanagari) as fallback
        return URL(string: "https://api.banidb.com/v2/banis/\(id)?script=unicode&translation=en,hi&transliteration=hi")
    }

    func fetchBani(for type: BaniType) {
        // Sarbloh Granth is handled as a bundled PDF
        guard type != .sarblohGranth else {
            print("📄 Sarbloh Granth is a bundled PDF, skipping fetch.")
            return
        }

        // Try cache first
        if let bani = Banis.shared.getBani(withType: type) {
            let wantsHindi = UserDefaults.standard.bool(forKey: "showHindiTranslation")
            let hasAnyHindi = bani.lines.contains { $0.hindiTranslation?.isEmpty == false }
            if wantsHindi && !hasAnyHindi {
                print("↻ Cached bani missing Hindi; refetching from API…")
            } else {
                isLoading = false
                self.currentBani = bani
                return
            }
        }

        let id = type.numericID
        guard id > 0, let url = makeURL(for: id) else {
            print("❌ Invalid Bani ID or URL")
            return
        }

        isLoading = true
        print("🌐 Fetching from URL: \(url.absoluteString)")

        let session = URLSession(configuration: .default)
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { self.isLoading = false }
            if let data = data {
                do {
                    let bani = try JSONDecoder().decode(Bani.self, from: data)
                    DispatchQueue.main.async {
                        self.currentBani = bani
                        Banis.shared.addBani(bani, withType: type)
                        // Debug hint if Hindi (translation) missing when user wants it
                        let wantsHindi = UserDefaults.standard.bool(forKey: "showHindiTranslation")
                        let hasHindi = bani.lines.contains { ($0.hindiTranslation?.isEmpty == false) }
                        if wantsHindi && !hasHindi {
                            print("ℹ️ No Hindi *translation* found in API; showing Devanagari transliteration if available.")
                        }
                    }
                } catch {
                    print("❌ Decoding error:", error)
                    if let raw = String(data: data, encoding: .utf8) {
                        print("📦 Raw JSON response:", raw)
                    }
                }
            } else if let error = error {
                print("❌ Network error:", error)
            }
        }.resume()
    }

    func preloadAllBanis() {
        let defaults = UserDefaults.standard
        let hasPreloaded = defaults.bool(forKey: "hasPreloadedBanis")

        guard !hasPreloaded else {
            print("✅ Banis already preloaded.")
            return
        }

        print("🚀 Preloading all Banis...")

        for type in BaniType.allCases {
            // Skip Sarbloh Granth since it's a local PDF, not fetched from API
            guard type != .sarblohGranth else {
                print("📄 Skipping Sarbloh Granth – handled as bundled PDF.")
                continue
            }

            let id = type.numericID
            guard id > 0, let url = makeURL(for: id) else { continue }

            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data {
                    do {
                        let bani = try JSONDecoder().decode(Bani.self, from: data)
                        DispatchQueue.main.async {
                            Banis.shared.addBani(bani, withType: type)
                            print("✅ Saved \(type.rawValue) to disk")
                        }
                    } catch {
                        print("❌ Error decoding \(type):", error)
                    }
                } else if let error = error {
                    print("❌ Network error for \(type):", error)
                }
            }.resume()
        }

        // Mark as preloaded
        defaults.set(true, forKey: "hasPreloadedBanis")
    }
}

// MARK: - Function to Load PDF

func loadBundledPDF(named name: String) -> URL? {
    Bundle.main.url(forResource: name, withExtension: "pdf")
}
