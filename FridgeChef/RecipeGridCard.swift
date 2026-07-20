//
//  RecipeGridCard.swift
//  FridgeChef
//
//  Izgara için fotoğraflı tarif kartı (Cookpedia stili).
//  Foto: tarif başlığından AI ile üretilir (Pollinations). Üstte favori kalbi.
//

import SwiftUI
import SwiftData

struct RecipeGridCard: View {
    let recipe: Recipe
    var yukseklik: CGFloat = 190

    @Environment(\.modelContext) private var modelContext
    @Query private var favoriler: [FavoriteRecipe]

    private var favoriMi: Bool { favoriler.contains { $0.title == recipe.title } }

    // Gerçek foto URL'i (TheMealDB / Wikipedia). Yoksa nil → anında yeşil kapak.
    private var fotoURL: URL? {
        guard let s = recipe.imageURL else { return nil }
        return URL(string: s)
    }

    // Foto yoksa / yüklenirken gösterilen anında yeşil kapak (ağ yok, çark takılmaz)
    private var yesilKapak: some View {
        ZStack {
            LinearGradient(colors: [Color.freshGreen, Color.darkGreen],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "fork.knife")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: recipe) {
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let url = fotoURL {
                            AsyncImage(url: url) { phase in
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    LinearGradient(colors: [.clear, .black.opacity(0.65)],
                                   startPoint: .center, endPoint: .bottom)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.subheadline).bold()
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(recipe.cookTimeMinutes > 0
                             ? "\(recipe.cookTimeMinutes) min · \(recipe.difficulty)"
                             : recipe.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .padding(10)
                }
                .frame(height: yukseklik)
                .clipped()
                .clipShape(.rect(cornerRadius: 18))
            }
            .buttonStyle(.plain)

            // Favori kalbi (NavigationLink'in üstünde ayrı buton)
            Button {
                favoriDegistir()
            } label: {
                Image(systemName: favoriMi ? "heart.fill" : "heart")
                    .font(.subheadline)
                    .foregroundStyle(favoriMi ? .red : .white)
                    .padding(8)
                    .background(.black.opacity(0.35), in: .circle)
            }
            .padding(8)
        }
    }

    private func favoriDegistir() {
        if let mevcut = favoriler.first(where: { $0.title == recipe.title }) {
            modelContext.delete(mevcut)
        } else {
            modelContext.insert(FavoriteRecipe(from: recipe))
        }
    }
}
