//
//  FavoritesView.swift
//  FridgeChef
//
//  Kaydedilen favori tarifler. RecipePad stili: 2'li ızgara, kalpli kartlar.
//  Bir karta dokununca detay açılır; basılı tutunca "favoriden çıkar".
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    // Kayıtlı favoriler, en yeni en üstte (otomatik güncellenir)
    @Query(sort: \FavoriteRecipe.savedAt, order: .reverse) private var favorites: [FavoriteRecipe]
    @Environment(\.modelContext) private var modelContext

    // 2 sütunlu ızgara
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    // Henüz favori yok
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on a recipe to save it here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(favorites) { fav in
                                NavigationLink(value: fav.asRecipe) {
                                    FavoriteCard(favorite: fav)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(fav)
                                    } label: {
                                        Label("Remove from favorites", systemImage: "heart.slash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

// Izgara kartı: küçük cover + kalp + başlık + alt başlık.
struct FavoriteCard: View {
    let favorite: FavoriteRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RecipeCover(recipe: favorite.asRecipe)
                    .frame(height: 120)
                    .clipped()

                // Dolu kalp — favoride olduğunu gösterir
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(7)
                    .background(.white, in: .circle)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.title)
                    .font(.subheadline).bold()
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(favorite.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}
