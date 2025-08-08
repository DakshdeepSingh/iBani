//
//  DataModel.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 25/03/25.
//
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

// MARK: - API-Level BaniLine Model (for decoding from banidb)

struct BaniLine: Identifiable, Codable {
    let id: Int
    let line: String
    let translation: String?

    enum RootKeys: String, CodingKey { case verse }
    enum VerseLevel1Keys: String, CodingKey { case verseId, verse, translation }
    enum InnerVerseKeys: String, CodingKey { case gurmukhi }
    enum TranslationKeys: String, CodingKey { case en }
    enum EnglishTranslationKeys: String, CodingKey { case bdb }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        let verseContainer = try container.nestedContainer(keyedBy: VerseLevel1Keys.self, forKey: .verse)
        id = try verseContainer.decode(Int.self, forKey: .verseId)
        let inner = try verseContainer.nestedContainer(keyedBy: InnerVerseKeys.self, forKey: .verse)
        line = try inner.decode(String.self, forKey: .gurmukhi)

        if let translationContainer = try? verseContainer.nestedContainer(keyedBy: TranslationKeys.self, forKey: .translation),
           let englishContainer = try? translationContainer.nestedContainer(keyedBy: EnglishTranslationKeys.self, forKey: .en) {
            translation = try? englishContainer.decode(String.self, forKey: .bdb)
        } else {
            translation = nil
        }
    }

    init(id: Int, line: String, translation: String?) {
        self.id = id
        self.line = line
        self.translation = translation
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
    case guruGranthSahibJi,dasamGranth,sarblohGranth
//    case guruGranthSahibJi
//    case dasamGranth
    //case unknown

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
        case .sarblohGranth: return"ਸਰਬਲੋਹ ਗ੍ਰੰਥ ਜੀ"
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
//        default:
//            return .others
        }
    }
}


// MARK: - Banis ViewModel

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
                lines: bani.lines.map { SimpleBaniLine(id: $0.id, line: $0.line, translation: $0.translation) }
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
                let lines = simple.lines.map { BaniLine(id: $0.id, line: $0.line, translation: $0.translation) }
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
    
    func fetchBani(for type: BaniType) {
        guard type != .sarblohGranth else {
            print("📄 Sarbloh Granth is a bundled PDF, skipping fetch.")
            return
        }
        if let bani = Banis.shared.getBani(withType: type) {
            isLoading = true
            self.currentBani = bani
            return
        }
        
        let id = type.numericID
        guard id > 0, let url = URL(string: "https://api.banidb.com/v2/banis/\(id)?script=unicode") else {
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
            // ✅ Skip Sarbloh Granth since it's a local PDF, not fetched from API
            guard type != .sarblohGranth else {
                print("📄 Skipping Sarbloh Granth – handled as bundled PDF.")
                continue
            }
            
            let id = type.numericID
            guard id > 0,
                  let url = URL(string: "https://api.banidb.com/v2/banis/\(id)?script=unicode") else {
                continue
            }
            
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

