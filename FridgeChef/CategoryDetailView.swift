//
//  CategoryDetailView.swift
//  FridgeChef
//
//  Kategoriye girince açılan sayfa (Cookpedia "Salad" ekranı uyarlaması):
//  üstte kategori görseli + AI'nin önerdiği tariflerin fotoğraflı ızgarası.
//

import SwiftUI

struct CategoryDetailView: View {
    let kategori: String
    let emoji: String

    @AppStorage("mutfakTercihleri") private var mutfakTercihleri = ""
    @AppStorage("diyetTercihi") private var diyetTercihi = ""
    @AppStorage("diyetKisitlari") private var diyetKisitlari = ""
    @AppStorage("yemekSeviyesi") private var yemekSeviyesi = ""

    @State private var tarifler: [Recipe] = []
    @State private var yukleniyor = false
    @State private var basladi = false
    @State private var hataMesaji: String?

    private let sutunlar = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Üst görsel (kategori banner'ı)
                KategoriKart(ad: kategori, emoji: emoji, yukseklik: 180)

                if yukleniyor {
                    VStack(spacing: 10) {
                        ProgressView().tint(Color.freshGreen)
                        Text("Finding \(kategori.lowercased()) recipes…")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else if tarifler.isEmpty {
                    ContentUnavailableView(
                        "No recipes",
                        systemImage: "tray",
                        description: Text("Try again or add some ingredients first.")
                    )
                    .padding(.top, 30)
                } else {
                    Text("Suggestions")
                        .font(.title3).bold()
                        .foregroundStyle(Color.textPrimary)

                    LazyVGrid(columns: sutunlar, spacing: 14) {
                        ForEach(tarifler) { tarif in
                            RecipeGridCard(recipe: tarif, yukseklik: 200)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(kategori)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !basladi {
                basladi = true
                await uret()
            }
        }
        .alert("Oops", isPresented: .constant(hataMesaji != nil)) {
            Button("OK") { hataMesaji = nil }
        } message: {
            Text(hataMesaji ?? "")
        }
    }

    private func uret() async {
        yukleniyor = true
        do {
            let mutfaklar = mutfakTercihleri.split(separator: ",").map(String.init)
            if mutfaklar.isEmpty {
                // Mutfak seçili değil → bedava gerçek tarif veritabanı
                tarifler = try await MealDBService.kategoriTarifleri(kategori)
            } else {
                // Mutfak seçili → AI o ülkelerin tariflerini üretir
                do {
                    var f = RecipeFilters()
                    f.categories = [kategori]
                    tarifler = try await RecipeService.tarifBul(
                        malzemeler: [],
                        diyet: diyetTercihi,
                        kisitlar: diyetKisitlari,
                        seviye: yemekSeviyesi,
                        mutfaklar: mutfakTercihleri,
                        filtreler: f
                    )
                } catch {
                    // AI meşgul/başarısız → gerçek veritabanına düş (boş/hata kalmasın)
                    tarifler = try await MealDBService.kategoriTarifleri(kategori, cuisines: mutfaklar)
                }
            }
        } catch {
            hataMesaji = error.localizedDescription
        }
        yukleniyor = false
    }
}
