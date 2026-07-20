//
//  RecipeService.swift
//  FridgeChef
//
//  Google Gemini API'ye bağlanan servis. Malzeme + diyet tercihini gönderir,
//  structured output (JSON şema) ile tarif listesi alır.
//
//  Gemini'nin ücretsiz katmanı kullanılıyor (kredi kartı gerekmez).
//  Resmi SDK yerine doğrudan URLSession ile generateContent endpoint'ine
//  raw HTTP isteği atıyoruz.
//

import Foundation

// Servis hataları — kullanıcıya anlamlı mesaj göstermek için.
enum RecipeError: LocalizedError {
    case eksikAnahtar
    case agHatasi(String)
    case sunucuHatasi(Int, String)
    case reddedildi
    case cozumlemeHatasi

    var errorDescription: String? {
        switch self {
        case .eksikAnahtar:
            return "API anahtarı bulunamadı. Secrets.plist dosyasını kontrol et."
        case .agHatasi(let mesaj):
            return "Bağlantı hatası: \(mesaj)"
        case .sunucuHatasi(_, let mesaj):
            return mesaj
        case .reddedildi:
            return "Bu istek yanıtlanamadı. Farklı malzemeler dene."
        case .cozumlemeHatasi:
            return "Tarifler okunamadı. Lütfen tekrar dene."
        }
    }
}

struct RecipeService {

    // Kullanılan Gemini modeli. 2.0-flash'ın ücretsiz kotası bu hesapta 0 olduğu
    // için 2.5-flash kullanıyoruz (test edildi, ücretsiz katmanda çalışıyor).
    private static let model = "gemini-2.5-flash"

    // --- API anahtarını Secrets.plist'ten oku ---
    private static func apiAnahtari() throws -> String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let anahtar = dict["GEMINI_API_KEY"] as? String,
            !anahtar.isEmpty,
            anahtar != "BURAYA_GEMINI_ANAHTARINI_YAPISTIR"
        else {
            throw RecipeError.eksikAnahtar
        }
        return anahtar
    }

    // --- Ana fonksiyon: malzeme + diyet + kısıtlama + seviye + mutfak + filtre ---
    static func tarifBul(
        malzemeler: [String],
        diyet: String,
        kisitlar: String = "",
        seviye: String = "",
        mutfaklar: String = "",
        filtreler: RecipeFilters = RecipeFilters()
    ) async throws -> [Recipe] {
        let anahtar = try apiAnahtari()

        // Gemini'nin döndüreceği JSON yapısını tanımlayan şema.
        // responseSchema sayesinde cevap GARANTİ bu yapıya uyar.
        // (Gemini tipleri BÜYÜK harf ister: OBJECT, ARRAY, STRING, INTEGER)
        let schema: [String: Any] = [
            "type": "OBJECT",
            "properties": [
                "recipes": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "title": ["type": "STRING"],
                            "subtitle": ["type": "STRING"],
                            "cookTimeMinutes": ["type": "INTEGER"],
                            "difficulty": ["type": "STRING", "enum": ["Easy", "Medium", "Hard"]],
                            "ingredients": ["type": "ARRAY", "items": ["type": "STRING"]],
                            "steps": ["type": "ARRAY", "items": ["type": "STRING"]]
                        ],
                        "required": ["title", "subtitle", "cookTimeMinutes", "difficulty", "ingredients", "steps"]
                    ]
                ]
            ],
            "required": ["recipes"]
        ]

        let diyetCumlesi = diyetAciklamasi(diyet)
        let kisitCumlesi = kisitAciklamasi(kisitlar)
        let seviyeCumlesi = seviyeAciklamasi(seviye)
        let mutfakCumlesi = mutfakAciklamasi(mutfaklar, filtreler: filtreler)
        let filtreCumlesi = filtreAciklamasi(filtreler)
        let malzemeMetni = malzemeler.joined(separator: ", ")

        let systemPrompt = """
        You are a friendly home cooking assistant. Given a list of ingredients the \
        user has in their fridge, suggest 3 realistic recipes they can actually make. \
        Ingredient entries may include amounts (e.g. "300 g chicken", "2 eggs", \
        "1 pack pasta") — take these quantities into account and don't suggest recipes \
        that need far more than what's available. \(diyetCumlesi)\(filtreCumlesi) Prefer \
        recipes that mostly use the listed ingredients, but you may assume basic pantry \
        staples (salt, pepper, oil, water). \(kisitCumlesi)\(seviyeCumlesi)\(mutfakCumlesi)Keep steps clear and \
        beginner-friendly. Respond in the same language as the ingredient names.
        """

        // Malzeme varsa onlardan, yoksa kategoriye/tercihlere göre popüler tarifler
        let userMessage = malzemeler.isEmpty
            ? "Suggest 3 popular recipes the user could cook."
            : "Ingredients I have: \(malzemeMetni)"

        // --- İstek gövdesi (Gemini formatı) ---
        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [["text": userMessage]]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "thinkingConfig": ["thinkingBudget": 0]   // düşünmeyi kapat: hızlı + güvenilir
            ]
        ]

        // --- Gönder ve çözümle ---
        let data = try await gonder(body: body, anahtar: anahtar)
        return try cevabiCoz(data)
    }

    // Ortak ağ fonksiyonu: gövdeyi Gemini'ye POST eder, ham veriyi döner.
    private static func gonder(body: [String: Any], anahtar: String) async throws -> Data {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anahtar, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RecipeError.agHatasi(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw RecipeError.agHatasi("Geçersiz yanıt")
        }
        guard (200...299).contains(http.statusCode) else {
            let mesaj: String
            switch http.statusCode {
            case 429, 500, 503:
                mesaj = "The AI is busy right now. Please try again in a moment."
            default:
                mesaj = "Something went wrong. Please try again."
            }
            throw RecipeError.sunucuHatasi(http.statusCode, mesaj)
        }
        return data
    }

    // --- İsme göre tarif ara (AI) — TheMealDB'de bulunmayan yemekler için ---
    static func tarifAra(isim: String, diyet: String = "", kisitlar: String = "", seviye: String = "") async throws -> [Recipe] {
        let anahtar = try apiAnahtari()

        let schema: [String: Any] = [
            "type": "OBJECT",
            "properties": [
                "recipes": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "title": ["type": "string"],
                            "subtitle": ["type": "string"],
                            "cookTimeMinutes": ["type": "integer"],
                            "difficulty": ["type": "string", "enum": ["Easy", "Medium", "Hard"]],
                            "ingredients": ["type": "array", "items": ["type": "string"]],
                            "steps": ["type": "array", "items": ["type": "string"]]
                        ],
                        "required": ["title", "subtitle", "cookTimeMinutes", "difficulty", "ingredients", "steps"]
                    ]
                ]
            ],
            "required": ["recipes"]
        ]

        let systemPrompt = """
        You are a cooking assistant. The user is searching for a specific dish by name. \
        Give 6 distinct authentic versions of that dish — the classic plus real \
        variations (different fillings, regional styles, vegetarian option, etc.). \
        If it belongs to a specific cuisine, keep every version authentic. \
        \(diyetAciklamasi(diyet))\(kisitAciklamasi(kisitlar))\(seviyeAciklamasi(seviye))\
        Respond in the same language as the dish name.
        """

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": "Recipe for: \(isim)"]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "thinkingConfig": ["thinkingBudget": 0]
            ]
        ]

        let data = try await gonder(body: body, anahtar: anahtar)
        return try cevabiCoz(data)
    }

    // --- Fotoğraftan malzeme tanıma (Gemini görüntü desteği) ---
    static func malzemeTani(gorselData: Data) async throws -> [String] {
        let anahtar = try apiAnahtari()
        let base64 = gorselData.base64EncodedString()

        // Sadece malzeme listesi döndürecek basit şema
        let schema: [String: Any] = [
            "type": "OBJECT",
            "properties": ["ingredients": ["type": "ARRAY", "items": ["type": "STRING"]]],
            "required": ["ingredients"]
        ]

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64]],
                    ["text": """
                    Look at this photo of food or a fridge. List the food ingredients you \
                    can clearly identify. For each, add an approximate amount when you can \
                    estimate it (e.g. "2 yumurta", "~300 gr tavuk", "1 paket makarna", \
                    "domates salçası"). Only list edible food ingredients, nothing else. \
                    Use short Turkish names.
                    """]
                ]
            ]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "thinkingConfig": ["thinkingBudget": 0]   // düşünmeyi kapat: hızlı + güvenilir
            ]
        ]

        let data = try await gonder(body: body, anahtar: anahtar)
        return try malzemeleriCoz(data)
    }

    // Görüntü cevabından malzeme listesini çıkarır.
    private static func malzemeleriCoz(_ data: Data) throws -> [String] {
        guard let kok = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RecipeError.cozumlemeHatasi
        }
        if let feedback = kok["promptFeedback"] as? [String: Any], feedback["blockReason"] != nil {
            throw RecipeError.reddedildi
        }
        guard
            let candidates = kok["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let jsonString = parts.first?["text"] as? String,
            let jsonData = jsonString.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let liste = parsed["ingredients"] as? [String]
        else {
            throw RecipeError.cozumlemeHatasi
        }
        return liste
    }

    // Gemini'nin cevabını parçalayıp tarif dizisine çevirir.
    private static func cevabiCoz(_ data: Data) throws -> [Recipe] {
        guard
            let kok = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw RecipeError.cozumlemeHatasi
        }

        // İstek güvenlik nedeniyle engellendiyse promptFeedback.blockReason gelir.
        if let feedback = kok["promptFeedback"] as? [String: Any],
           feedback["blockReason"] != nil {
            throw RecipeError.reddedildi
        }

        // candidates[0].content.parts[0].text -> içi bizim JSON'umuz.
        guard
            let candidates = kok["candidates"] as? [[String: Any]],
            let ilk = candidates.first,
            let content = ilk["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let jsonString = parts.first?["text"] as? String,
            let jsonData = jsonString.data(using: .utf8)
        else {
            throw RecipeError.cozumlemeHatasi
        }

        do {
            return try JSONDecoder().decode(RecipeResponse.self, from: jsonData).recipes
        } catch {
            throw RecipeError.cozumlemeHatasi
        }
    }

    // Seçilen filtreleri AI için kısıtlama cümlelerine çevirir.
    private static func filtreAciklamasi(_ f: RecipeFilters) -> String {
        var parcalar: [String] = []
        if !f.categories.isEmpty {
            parcalar.append("Focus on these dish types: \(f.categories.sorted().joined(separator: ", ")).")
        }
        if let zorluk = f.complexity {
            parcalar.append("Difficulty must be \(zorluk).")
        }
        if let dakika = f.maxMinutes {
            parcalar.append("Each recipe must take \(dakika) minutes or less.")
        }
        if let mutfak = f.cuisine {
            parcalar.append("Use \(mutfak) cuisine style.")
        }
        return parcalar.isEmpty ? "" : " " + parcalar.joined(separator: " ")
    }

    // Diyet kısıtlamaları / alerjiler → AI için katı kısıtlama cümlesi.
    private static func kisitAciklamasi(_ kisitlar: String) -> String {
        guard !kisitlar.isEmpty else { return "" }
        let liste = kisitlar.split(separator: ",").joined(separator: ", ")
        return "The user has these dietary restrictions or allergies: \(liste). Strictly avoid any ingredient that violates them. "
    }

    // Kullanıcının yemek yapma seviyesi → tarif zorluğunu ayarla.
    private static func seviyeAciklamasi(_ seviye: String) -> String {
        guard !seviye.isEmpty else { return "" }
        return "The user's cooking skill level is \(seviye); match the recipe difficulty to this level. "
    }

    // Mutfak tercihini cümleye çevirir. (Filtrede mutfak seçiliyse o öncelikli,
    // burayı atlıyoruz ki çelişki olmasın.)
    private static func mutfakAciklamasi(_ mutfaklar: String, filtreler: RecipeFilters) -> String {
        guard filtreler.cuisine == nil, !mutfaklar.isEmpty else { return "" }
        let liste = mutfaklar.split(separator: ",").joined(separator: ", ")
        return "The user generally enjoys these cuisines: \(liste) — lean toward them when it fits the ingredients. "
    }

    // Diyet tercihini system prompt cümlesine çevirir.
    private static func diyetAciklamasi(_ diyet: String) -> String {
        switch diyet {
        case "Vegetarian":
            return "The user is vegetarian — suggest only vegetarian recipes (no meat or fish)."
        case "Vegan":
            return "The user is vegan — suggest only vegan recipes (no animal products at all)."
        default:
            return "The user eats everything — meat, fish and veggie recipes are all fine."
        }
    }
}
