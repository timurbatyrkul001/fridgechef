//
//  DiscoverView.swift
//  FridgeChef
//
//  Recipes sekmesi = keşif: Most Popular, Recipe Categories, Our Recommendations,
//  Most Searches, New Recipes. Hepsi GERÇEK tarif veritabanı (AI değil).
//

import SwiftUI

struct DiscoverView: View {
    @State private var populer: [Recipe] = []
    @State private var onerilen: [Recipe] = []
    @State private var aramalar: [Recipe] = []
    @State private var yeniler: [Recipe] = []

    private let kategoriler: [(ad: String, emoji: String)] = [
        ("Soup", "🍲"), ("Salad", "🥗"), ("Chicken", "🍗"), ("Meat", "🥩"),
        ("Fish", "🐟"), ("Pasta", "🍝"), ("Breakfast", "🍳"), ("Dessert", "🍰")
    ]

    @State private var aranan = ""
    @State private var aramaAcik = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    aramaCubugu
                    if !populer.isEmpty { yatayTarifBolum("Most Popular", populer) }
                    kategorilerBolumu
                    if !onerilen.isEmpty { yatayTarifBolum("Our Recommendations", onerilen) }
                    if !aramalar.isEmpty { yatayTarifBolum("Most Searches", aramalar) }
                    if !yeniler.isEmpty { yatayTarifBolum("New Recipes", yeniler) }
                }
                .padding()
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationDestination(isPresented: $aramaAcik) {
                SearchResultsView(sorgu: aranan.trimmingCharacters(in: .whitespaces))
            }
            .task {
                if populer.isEmpty {
                    async let mp = MealDBService.populerKarisik(["pizza", "burger", "pasta", "sushi"])
                    async let rec = MealDBService.populerKarisik(["chicken", "beef", "rice"])
                    async let ms = MealDBService.populerKarisik(["cake", "dessert", "pie"])
                    async let nr = MealDBService.populerKarisik(["soup", "salad", "noodle"])
                    populer = await mp
                    onerilen = await rec
                    aramalar = await ms
                    yeniler = await nr
                }
            }
        }
    }

    private var aramaCubugu: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
            TextField("Search a recipe (e.g. Olivier salad, Khinkali)", text: $aranan)
                .submitLabel(.search)
                .onSubmit {
                    if !aranan.trimmingCharacters(in: .whitespaces).isEmpty {
                        aramaAcik = true
                    }
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground, in: .capsule)
    }

    private func yatayTarifBolum(_ baslik: String, _ liste: [Recipe],
                                 genislik: CGFloat = 210, yukseklik: CGFloat = 210) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(baslik)
                .font(.title3).bold()
                .foregroundStyle(Color.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(liste) { tarif in
                        RecipeGridCard(recipe: tarif, yukseklik: yukseklik)
                            .frame(width: genislik)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var kategorilerBolumu: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recipe Categories")
                    .font(.title3).bold()
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                NavigationLink {
                    RecipeCategoriesView()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.freshGreen)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(kategoriler, id: \.ad) { kategori in
                        NavigationLink {
                            CategoryDetailView(kategori: kategori.ad, emoji: kategori.emoji)
                        } label: {
                            KategoriKart(ad: kategori.ad, emoji: kategori.emoji, yukseklik: 96)
                                .frame(width: 130)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
