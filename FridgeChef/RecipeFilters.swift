//
//  RecipeFilters.swift
//  FridgeChef
//
//  Tarif filtreleri: kategori, zorluk, süre, mutfak.
//  Bunlar arama değil — AI'a verilen kısıtlamalar (prompt'a eklenir).
//

import SwiftUI

// Seçilen filtreler
struct RecipeFilters: Equatable {
    var categories: Set<String> = []   // çoklu seçim
    var complexity: String? = nil      // tekli: Easy/Medium/Hard
    var maxMinutes: Int? = nil         // tekli: 15/30/60
    var cuisine: String? = nil         // tekli

    // En az bir filtre seçili mi?
    var aktif: Bool {
        !categories.isEmpty || complexity != nil || maxMinutes != nil || cuisine != nil
    }

    // --- Seçenek listeleri ---
    static let tumKategoriler = ["Soup", "Meat", "Chicken", "Fish", "Rice", "Noodle", "Salad", "Dessert"]
    static let tumZorluklar = ["Easy", "Medium", "Hard"]
    static let tumSureler: [(etiket: String, dakika: Int)] = [("≤15 min", 15), ("≤30 min", 30), ("≤1 hr", 60)]
    static let tumMutfaklar = ["Turkish", "Italian", "Chinese", "Japanese", "Indian", "Mexican", "French", "Greek"]
}

// Filtre ekranı (alt pencere)
struct FilterSheet: View {
    @Binding var filtreler: RecipeFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    bolum("Category") {
                        chipIzgara(RecipeFilters.tumKategoriler) { kategori in
                            chip(kategori, secili: filtreler.categories.contains(kategori)) {
                                if filtreler.categories.contains(kategori) {
                                    filtreler.categories.remove(kategori)
                                } else {
                                    filtreler.categories.insert(kategori)
                                }
                            }
                        }
                    }

                    bolum("Complexity") {
                        chipIzgara(RecipeFilters.tumZorluklar) { zorluk in
                            chip(zorluk, secili: filtreler.complexity == zorluk) {
                                filtreler.complexity = (filtreler.complexity == zorluk) ? nil : zorluk
                            }
                        }
                    }

                    bolum("Cooking Time") {
                        chipIzgara(RecipeFilters.tumSureler.map(\.etiket)) { etiket in
                            let dakika = RecipeFilters.tumSureler.first { $0.etiket == etiket }!.dakika
                            chip(etiket, secili: filtreler.maxMinutes == dakika) {
                                filtreler.maxMinutes = (filtreler.maxMinutes == dakika) ? nil : dakika
                            }
                        }
                    }

                    bolum("Cuisine") {
                        chipIzgara(RecipeFilters.tumMutfaklar) { mutfak in
                            chip(mutfak, secili: filtreler.cuisine == mutfak) {
                                filtreler.cuisine = (filtreler.cuisine == mutfak) ? nil : mutfak
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { filtreler = RecipeFilters() }
                        .disabled(!filtreler.aktif)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.bold()
                }
            }
        }
    }

    // --- Yardımcılar ---

    // Başlıklı bölüm
    private func bolum<C: View>(_ baslik: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(baslik)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Chip'leri saran ızgara
    private func chipIzgara(_ ogeler: [String], @ViewBuilder content: @escaping (String) -> some View) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 92), spacing: 10)],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(ogeler, id: \.self) { content($0) }
        }
    }

    // Tek bir chip (hap şeklinde buton)
    private func chip(_ etiket: String, secili: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(etiket)
                .font(.subheadline)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(secili ? Color.freshGreen : Color.cardBackground)
                .foregroundStyle(secili ? .white : Color.textPrimary)
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}
