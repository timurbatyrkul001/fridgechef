//
//  FavoriteRecipe.swift
//  FridgeChef
//
//  Favoriye eklenen tarifin cihazda kalıcı saklanan hali (SwiftData).
//
//  Recipe (API'den gelen geçici veri) ile FavoriteRecipe (diske kaydedilen)
//  ayrı tutuluyor: biri "gelen veri", diğeri "sakladığımız veri".
//

import Foundation
import SwiftData

@Model
final class FavoriteRecipe {
    var title: String
    var subtitle: String
    var cookTimeMinutes: Int
    var difficulty: String
    var ingredients: [String]
    var steps: [String]
    var imageURL: String?  // gerçek foto (TheMealDB/Wikipedia)
    var savedAt: Date      // ne zaman favoriye eklendi (sıralama için)

    // Bir Recipe'i favoriye çevirir.
    init(from recipe: Recipe) {
        self.title = recipe.title
        self.subtitle = recipe.subtitle
        self.cookTimeMinutes = recipe.cookTimeMinutes
        self.difficulty = recipe.difficulty
        self.ingredients = recipe.ingredients
        self.steps = recipe.steps
        self.imageURL = recipe.imageURL
        self.savedAt = Date()
    }
}

extension FavoriteRecipe {
    // Detay ekranını yeniden kullanmak için tekrar Recipe'e çevirir.
    var asRecipe: Recipe {
        Recipe(
            title: title,
            subtitle: subtitle,
            cookTimeMinutes: cookTimeMinutes,
            difficulty: difficulty,
            ingredients: ingredients,
            steps: steps,
            imageURL: imageURL
        )
    }
}
