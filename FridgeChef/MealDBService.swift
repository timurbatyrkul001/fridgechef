//
//  MealDBService.swift
//  FridgeChef
//
//  Kategoriler için GERÇEK tarif veritabanı (TheMealDB, ücretsiz).
//  AI'ı yormaz — kategoriye girince hazır, fotoğraflı tarifler gelir.
//  (AI yalnızca kullanıcı kendi malzemelerini girince çalışır.)
//

import Foundation

struct MealDBService {

    // Bir kategori için gerçek tarifler. cuisines verilirse o ülkelere göre süzer.
    static func kategoriTarifleri(_ kategori: String, cuisines: [String] = []) async throws -> [Recipe] {
        let kelime = kategori.lowercased().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? kategori
        let hepsi = try await getir("https://www.themealdb.com/api/json/v1/1/search.php?s=\(kelime)")

        guard !cuisines.isEmpty else { return hepsi }
        // subtitle = "Turkish · Salad" → seçilen ülkeyle eşleşenleri al
        let eslesen = hepsi.filter { tarif in
            cuisines.contains { ulke in tarif.subtitle.localizedCaseInsensitiveContains(ulke) }
        }
        // O ülkelerden hiç yoksa boş bırakma, hepsini göster
        return eslesen.isEmpty ? hepsi : eslesen
    }

    // Ana sayfa şeritleri için (Most Popular, Recommendations vb.).
    // Her şeride farklı harf verilir → farklı, çeşitli gerçek tarifler.
    static func harfTarifleri(_ harf: String) async throws -> [Recipe] {
        let tarifler = try await getir("https://www.themealdb.com/api/json/v1/1/search.php?f=\(harf)")
        return Array(tarifler.prefix(12))
    }

    // Birkaç iştah açıcı yemek terimini paralel çekip karıştırır (güzel fotolar için).
    static func populerKarisik(_ terimler: [String]) async -> [Recipe] {
        var sonuc: [Recipe] = []
        var gorulen = Set<String>()
        await withTaskGroup(of: [Recipe].self) { group in
            for terim in terimler {
                group.addTask { (try? await kategoriTarifleri(terim)) ?? [] }
            }
            for await liste in group {
                for tarif in liste.prefix(3) where !gorulen.contains(tarif.title) {
                    gorulen.insert(tarif.title)
                    sonuc.append(tarif)
                }
            }
        }
        return sonuc
    }

    // Ortak: URL'den tarif listesi çeker.
    private static func getir(_ adres: String) async throws -> [Recipe] {
        guard let url = URL(string: adres) else { return [] }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw RecipeError.agHatasi(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RecipeError.agHatasi("Tarifler alınamadı")
        }
        // meals null gelebilir (sonuç yoksa) → boş liste
        guard
            let kok = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let meals = kok["meals"] as? [[String: Any]]
        else {
            return []
        }
        return meals.compactMap { tarifeCevir($0) }
    }

    // TheMealDB "meal" sözlüğünü bizim Recipe modeline çevirir.
    private static func tarifeCevir(_ m: [String: Any]) -> Recipe? {
        guard let baslik = m["strMeal"] as? String else { return nil }

        let mutfak = (m["strArea"] as? String) ?? ""
        let kategori = (m["strCategory"] as? String) ?? ""
        let altBaslik = [mutfak, kategori].filter { !$0.isEmpty }.joined(separator: " · ")
        let foto = m["strMealThumb"] as? String

        // Malzeme + ölçü (strIngredient1..20 / strMeasure1..20)
        var malzemeler: [String] = []
        for i in 1...20 {
            let ad = ((m["strIngredient\(i)"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
            let olcu = ((m["strMeasure\(i)"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
            if !ad.isEmpty {
                malzemeler.append(olcu.isEmpty ? ad : "\(olcu) \(ad)")
            }
        }

        // Yapılış adımları
        let metin = (m["strInstructions"] as? String) ?? ""
        var adimlar = metin
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if adimlar.count <= 1 {
            adimlar = metin
                .components(separatedBy: ". ")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }

        return Recipe(
            title: baslik,
            subtitle: altBaslik,
            cookTimeMinutes: 0,        // TheMealDB süre vermiyor
            difficulty: kategori,
            ingredients: malzemeler,
            steps: adimlar,
            imageURL: foto
        )
    }
}
