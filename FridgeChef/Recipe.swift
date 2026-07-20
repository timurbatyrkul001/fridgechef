//
//  Recipe.swift
//  FridgeChef
//
//  Claude API'den gelen tarif verisinin modeli.
//  AI, structured output (JSON şema) ile tam bu yapıda cevap döner.
//

import Foundation

// Tek bir tarif
struct Recipe: Codable, Identifiable, Hashable {
    // AI id döndürmüyor, biz cihazda üretiyoruz (liste/detay için lazım)
    var id = UUID()
    let title: String          // Tarif adı, ör. "Domatesli Menemen"
    let subtitle: String       // Kısa açıklama, ör. "5 dakikada hazır kahvaltı"
    let cookTimeMinutes: Int    // Pişirme süresi (dakika)
    let difficulty: String      // "Easy" | "Medium" | "Hard"
    let ingredients: [String]   // Malzeme listesi
    let steps: [String]         // Adım adım yapılış
    var imageURL: String? = nil // Gerçek foto (TheMealDB); AI tariflerinde nil

    // AI'nin döndürdüğü JSON'da id/imageURL yok — decode ederken atla.
    enum CodingKeys: String, CodingKey {
        case title, subtitle, cookTimeMinutes, difficulty, ingredients, steps
    }
}

// AI'nin döndürdüğü en dış JSON: { "recipes": [ ... ] }
struct RecipeResponse: Codable {
    let recipes: [Recipe]
}
