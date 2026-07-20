//
//  RecipeDetailView.swift
//  FridgeChef
//
//  Tarif detayı (Cookpedia tarzı): büyük hero foto + başlık + bilgi rozetleri
//  + Ingredients (numaralı) + Instructions (numaralı adımlar).
//  Tüm tarifler bu ekranı kullanır.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteRecipe]

    private var favoriMi: Bool {
        favorites.contains { $0.title == recipe.title }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // --- Büyük hero foto (tam genişlik) ---
                heroGorsel
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: 22) {

                    // Başlık + açıklama
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.title)
                            .font(.title).bold()
                            .foregroundStyle(Color.textPrimary)
                        if !recipe.subtitle.isEmpty {
                            Text(recipe.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    // Bilgi rozetleri
                    bilgiRozetleri

                    // Ingredients (numaralı)
                    bolum(baslik: "Ingredients") {
                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { i, malzeme in
                            HStack(alignment: .top, spacing: 12) {
                                numara(i + 1)
                                Text(malzeme)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    // Instructions (numaralı adımlar)
                    bolum(baslik: "Instructions") {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, adim in
                            HStack(alignment: .top, spacing: 12) {
                                numara(i + 1)
                                Text(adim)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: paylasimMetni) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favoriDegistir()
                } label: {
                    Image(systemName: favoriMi ? "heart.fill" : "heart")
                        .foregroundStyle(favoriMi ? .red : Color.textSecondary)
                }
            }
        }
    }

    // MARK: - Parçalar

    @ViewBuilder
    private var heroGorsel: some View {
        if let s = recipe.imageURL, let u = URL(string: s) {
            AsyncImage(url: u) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    yesilKapak
                }
            }
        } else {
            yesilKapak
        }
    }

    private var yesilKapak: some View {
        ZStack {
            LinearGradient(colors: [Color.freshGreen, Color.darkGreen],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "fork.knife")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var bilgiRozetleri: some View {
        HStack(spacing: 12) {
            if recipe.cookTimeMinutes > 0 {
                rozet(ikon: "clock", deger: "\(recipe.cookTimeMinutes) min", etiket: "cook time")
            }
            if !recipe.difficulty.isEmpty {
                rozet(ikon: "chart.bar", deger: recipe.difficulty, etiket: "level")
            }
            rozet(ikon: "list.bullet", deger: "\(recipe.ingredients.count)", etiket: "items")
        }
    }

    private func rozet(ikon: String, deger: String, etiket: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: ikon)
                Text(deger).bold()
            }
            .font(.subheadline)
            .foregroundStyle(Color.freshGreen)
            Text(etiket)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.freshGreen.opacity(0.1), in: .rect(cornerRadius: 14))
    }

    private func numara(_ n: Int) -> some View {
        Text("\(n)")
            .font(.subheadline).bold()
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Color.freshGreen, in: .circle)
    }

    @ViewBuilder
    private func bolum<Content: View>(baslik: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(baslik)
                .font(.title2).bold()
                .foregroundStyle(Color.textPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Paylaşılacak düz metin
    private var paylasimMetni: String {
        var metin = "🍳 \(recipe.title)\n\(recipe.subtitle)\n\n"
        if recipe.cookTimeMinutes > 0 {
            metin += "⏱ \(recipe.cookTimeMinutes) min · \(recipe.difficulty)\n\n"
        }
        metin += "🛒 Ingredients:\n"
        metin += recipe.ingredients.map { "• \($0)" }.joined(separator: "\n")
        metin += "\n\n👨‍🍳 Instructions:\n"
        metin += recipe.steps.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
        metin += "\n\n— FridgeChef"
        return metin
    }

    private func favoriDegistir() {
        if let mevcut = favorites.first(where: { $0.title == recipe.title }) {
            modelContext.delete(mevcut)
        } else {
            modelContext.insert(FavoriteRecipe(from: recipe))
        }
    }
}
