//
//  RecipeListView.swift
//  FridgeChef
//
//  AI'nin önerdiği tariflerin listesi. Her kart: büyük 16:9 cover + başlık + alt başlık.
//  Karta dokununca detay ekranına gider.
//

import SwiftUI

struct RecipeListView: View {
    let recipes: [Recipe]

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No recipes",
                        systemImage: "tray",
                        description: Text("Try different ingredients or filters.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                            spacing: 14
                        ) {
                            ForEach(recipes) { recipe in
                                RecipeGridCard(recipe: recipe)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

// Liste kartı: 16:9 cover üstte, başlık + alt başlık altta.
struct RecipeCard: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeCover(recipe: recipe)
                .frame(height: 180)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Text(recipe.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

// Fotoğraf yerine geçen 16:9 cover: yeşil degrade + ikon + süre/zorluk rozeti.
struct RecipeCover: View {
    let recipe: Recipe

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.freshGreen, Color.darkGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "fork.knife")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.35))

            // Alt köşede süre + zorluk rozetleri
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    rozet(ikon: "clock", metin: "\(recipe.cookTimeMinutes) min")
                    rozet(ikon: "chart.bar", metin: recipe.difficulty)
                    Spacer()
                }
                .padding(12)
            }
        }
    }

    private func rozet(ikon: String, metin: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: ikon)
            Text(metin)
        }
        .font(.caption).bold()
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.black.opacity(0.25), in: .capsule)
    }
}
