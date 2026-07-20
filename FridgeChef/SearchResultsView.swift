//
//  SearchResultsView.swift
//  FridgeChef
//
//  Arama sonuçları: önce gerçek veritabanı (TheMealDB), o yemek yoksa AI yazar.
//

import SwiftUI

struct SearchResultsView: View {
    let sorgu: String

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
            if yukleniyor {
                VStack(spacing: 10) {
                    ProgressView().tint(Color.freshGreen)
                    Text("Searching “\(sorgu)”…")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else if tarifler.isEmpty {
                ContentUnavailableView(
                    "No results",
                    systemImage: "magnifyingglass",
                    description: Text("Couldn't find “\(sorgu)”. Try a different name.")
                )
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: sutunlar, spacing: 14) {
                    ForEach(tarifler) { tarif in
                        RecipeGridCard(recipe: tarif, yukseklik: 130)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(sorgu)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !basladi {
                basladi = true
                await ara()
            }
        }
        .alert("Oops", isPresented: .constant(hataMesaji != nil)) {
            Button("OK") { hataMesaji = nil }
        } message: {
            Text(hataMesaji ?? "")
        }
    }

    private func ara() async {
        yukleniyor = true
        do {
            // 1) Gerçek veritabanı
            var sonuc = try await MealDBService.kategoriTarifleri(sorgu)
            // 2) Yoksa AI yazsın + aranan yemeğin GERÇEK fotosunu bağla
            if sonuc.isEmpty {
                var ai = try await RecipeService.tarifAra(
                    isim: sorgu,
                    diyet: diyetTercihi,
                    kisitlar: diyetKisitlari,
                    seviye: yemekSeviyesi
                )
                if let foto = await GorselService.realFoto(sorgu) {
                    ai = ai.map { var r = $0; r.imageURL = foto; return r }
                }
                sonuc = ai
            }
            tarifler = sonuc
        } catch {
            hataMesaji = error.localizedDescription
        }
        yukleniyor = false
    }
}
