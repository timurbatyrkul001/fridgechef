//
//  RecipeCategoriesView.swift
//  FridgeChef
//
//  Tam sayfa kategori ızgarası (Cookpedia "Recipe Categories" uyarlaması).
//  Bir kategoriye dokununca CategoryDetailView açılır (AI o türde tarif önerir).
//

import SwiftUI

struct RecipeCategoriesView: View {
    private let kategoriler: [(ad: String, emoji: String)] = [
        ("Salad", "🥗"), ("Burger", "🍔"), ("Pizza", "🍕"), ("Noodles", "🍜"),
        ("Meat", "🥩"), ("Chicken", "🍗"), ("Fish", "🐟"), ("Rice", "🍚"),
        ("Seafood", "🦐"), ("Dessert", "🍰"), ("Soup", "🍲"), ("Bread", "🍞"),
        ("Pasta", "🍝"), ("Breakfast", "🍳"), ("Vegan", "🌱"), ("Cake", "🎂")
    ]

    private let sutunlar = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: sutunlar, spacing: 14) {
                ForEach(kategoriler, id: \.ad) { kategori in
                    NavigationLink {
                        CategoryDetailView(kategori: kategori.ad, emoji: kategori.emoji)
                    } label: {
                        KategoriKart(ad: kategori.ad, emoji: kategori.emoji, yukseklik: 130)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Recipe Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}
