//
//  HomeView.swift
//  FridgeChef
//
//  Home sekmesi = feed: hoş geldin banner + Recent Recipes + Your Bookmark.
//  (Keşif → DiscoverView/Recipes, malzeme+AI → IngredientsView/Create.)
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \FavoriteRecipe.savedAt, order: .reverse) private var favoriler: [FavoriteRecipe]
    @Query(sort: \GeneratedRecipe.createdAt, order: .reverse) private var uretilenler: [GeneratedRecipe]
    @State private var recent: [Recipe] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    bannerKarti
                    if !recent.isEmpty { yatayTarifBolum("Recent Recipes", recent) }
                    if !uretilenler.isEmpty {
                        yatayTarifBolum("Your Recipes", uretilenler.map(\.asRecipe))
                    }
                    if !favoriler.isEmpty {
                        yatayTarifBolum("Your Bookmark", favoriler.map(\.asRecipe))
                    }
                }
                .padding()
            }
            .navigationTitle("FridgeChef")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .task {
                if recent.isEmpty {
                    recent = await MealDBService.populerKarisik(["pancakes", "omelette", "sandwich", "salad"])
                }
            }
        }
    }

    private var bannerKarti: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back! 👋")
                    .font(.title3).bold()
                    .foregroundStyle(.white)
                Text("Find your next delicious meal.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.freshGreen, Color.darkGreen],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(.rect(cornerRadius: 20))
    }

    private func yatayTarifBolum(_ baslik: String, _ liste: [Recipe]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(baslik)
                .font(.title3).bold()
                .foregroundStyle(Color.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(liste) { tarif in
                        RecipeGridCard(recipe: tarif, yukseklik: 210)
                            .frame(width: 210)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}
