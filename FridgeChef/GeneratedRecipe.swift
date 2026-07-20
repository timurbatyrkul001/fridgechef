//
//  GeneratedRecipe.swift
//  FridgeChef
//
//  AI'ın kullanıcı için ürettiği tarifler ("Your Recipes").
//  Create'te tarif üretilince otomatik kaydedilir. (Bookmark'tan ayrı.)
//

import Foundation
import SwiftData

@Model
final class GeneratedRecipe {
    var title: String
    var subtitle: String
    var cookTimeMinutes: Int
    var difficulty: String
    var ingredients: [String]
    var steps: [String]
    var imageURL: String?
    var createdAt: Date

    init(from recipe: Recipe) {
        self.title = recipe.title
        self.subtitle = recipe.subtitle
        self.cookTimeMinutes = recipe.cookTimeMinutes
        self.difficulty = recipe.difficulty
        self.ingredients = recipe.ingredients
        self.steps = recipe.steps
        self.imageURL = recipe.imageURL
        self.createdAt = Date()
    }
}

extension GeneratedRecipe {
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
