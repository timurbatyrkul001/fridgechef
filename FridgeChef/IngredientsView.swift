//
//  IngredientsView.swift
//  FridgeChef
//
//  Recipes sekmesi: buzdolabındaki malzemeleri gir/foto çek → AI tarif üret.
//  (Keşif/bölümler artık HomeView'da.)
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct IngredientsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    // Daha önce üretilenler (tekrar kaydetmemek için)
    @Query private var uretilenler: [GeneratedRecipe]

    @State private var yeniMalzeme = ""
    @State private var malzemeler: [String] = []

    // Kullanıcı tercihleri (AI'a beslenir)
    @AppStorage("diyetTercihi") private var diyetTercihi = ""
    @AppStorage("mutfakTercihleri") private var mutfakTercihleri = ""
    @AppStorage("diyetKisitlari") private var diyetKisitlari = ""
    @AppStorage("yemekSeviyesi") private var yemekSeviyesi = ""

    // AI tarif durumu
    @State private var tarifler: [Recipe] = []
    @State private var yukleniyor = false
    @State private var sonuclarAcik = false
    @State private var hataMesaji: String?

    // Filtreler
    @State private var filtreler = RecipeFilters()
    @State private var filtreAcik = false

    // Fotoğraftan malzeme tanıma
    @State private var secilenFoto: PhotosPickerItem?
    @State private var taraniyor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        bannerKarti
                        malzemeKarti
                    }
                    .padding()
                }

                tarifBulButonu
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .navigationTitle("Create")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        filtreAcik = true
                    } label: {
                        Image(systemName: filtreler.aktif
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(filtreler.aktif ? Color.freshGreen : Color.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $sonuclarAcik) {
                RecipeListView(recipes: tarifler)
            }
            .sheet(isPresented: $filtreAcik) {
                FilterSheet(filtreler: $filtreler)
            }
            .alert("Oops", isPresented: .constant(hataMesaji != nil)) {
                Button("OK") { hataMesaji = nil }
            } message: {
                Text(hataMesaji ?? "")
            }
            .onChange(of: secilenFoto) { _, yeni in
                if let yeni { fotoTara(yeni) }
            }
        }
    }

    // MARK: - Bölümler

    private var bannerKarti: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("What's in your fridge?")
                    .font(.title3).bold()
                    .foregroundStyle(.white)
                Text("Add ingredients or snap a photo,\nAI will create recipes for you.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "refrigerator.fill")
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

    private var malzemeKarti: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                TextField("Add an ingredient (e.g. 300g chicken)", text: $yeniMalzeme)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { malzemeEkle() }

                Button(action: malzemeEkle) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.freshGreen)
                }
            }

            PhotosPicker(selection: $secilenFoto, matching: .images) {
                HStack(spacing: 8) {
                    if taraniyor {
                        ProgressView().tint(Color.freshGreen)
                        Text("Scanning photo…")
                    } else {
                        Image(systemName: "camera.fill")
                        Text("Scan your fridge")
                    }
                }
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(Color.freshGreen)
                .background(Color.freshGreen.opacity(0.12), in: .rect(cornerRadius: 14))
            }
            .disabled(taraniyor)

            if malzemeler.isEmpty {
                Text("No ingredients yet. Add a few above. 👆")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.vertical, 4)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 110), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(malzemeler, id: \.self) { malzeme in
                        Button {
                            malzemeler.removeAll { $0 == malzeme }
                        } label: {
                            HStack(spacing: 5) {
                                Text(malzeme).lineLimit(1)
                                Image(systemName: "xmark.circle.fill")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.freshGreen.opacity(0.12), in: .capsule)
                            .foregroundStyle(Color.freshGreen)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var tarifBulButonu: some View {
        Button {
            tarifBul()
        } label: {
            HStack {
                if yukleniyor {
                    ProgressView().tint(.white)
                    Text("Finding recipes…")
                } else {
                    Text("Find Recipes")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(malzemeler.isEmpty || yukleniyor ? Color.gray.opacity(0.4) : Color.freshGreen)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 16))
        }
        .disabled(malzemeler.isEmpty || yukleniyor)
    }

    // MARK: - Fonksiyonlar

    func malzemeEkle() {
        let temiz = yeniMalzeme.trimmingCharacters(in: .whitespaces)
        guard !temiz.isEmpty else { return }
        if !malzemeler.contains(temiz) { malzemeler.append(temiz) }
        yeniMalzeme = ""
    }

    func fotoTara(_ oge: PhotosPickerItem) {
        taraniyor = true
        Task {
            defer {
                taraniyor = false
                secilenFoto = nil
            }
            do {
                guard
                    let data = try await oge.loadTransferable(type: Data.self),
                    let uiImage = UIImage(data: data),
                    let jpeg = uiImage.jpegData(compressionQuality: 0.7)
                else {
                    hataMesaji = "Fotoğraf okunamadı."
                    return
                }
                let bulunan = try await RecipeService.malzemeTani(gorselData: jpeg)
                for m in bulunan where !malzemeler.contains(m) {
                    malzemeler.append(m)
                }
            } catch {
                hataMesaji = error.localizedDescription
            }
        }
    }

    func tarifBul() {
        yukleniyor = true
        Task {
            do {
                let gelen = try await RecipeService.tarifBul(
                    malzemeler: malzemeler,
                    diyet: diyetTercihi,
                    kisitlar: diyetKisitlari,
                    seviye: yemekSeviyesi,
                    mutfaklar: mutfakTercihleri,
                    filtreler: filtreler
                )
                if gelen.isEmpty {
                    hataMesaji = "Couldn't find recipes for these ingredients. Try adding more or loosening your filters."
                } else {
                    tarifler = gelen
                    sonuclarAcik = true
                    // "Your Recipes" için kaydet (tekrarsız) — varsa gerçek foto bağla
                    for r in gelen where !uretilenler.contains(where: { $0.title == r.title }) {
                        var rr = r
                        if rr.imageURL == nil {
                            rr.imageURL = await GorselService.realFoto(r.title)
                        }
                        modelContext.insert(GeneratedRecipe(from: rr))
                    }
                }
            } catch {
                hataMesaji = error.localizedDescription
            }
            yukleniyor = false
        }
    }
}

#Preview {
    IngredientsView()
        .environment(AuthManager())
}
