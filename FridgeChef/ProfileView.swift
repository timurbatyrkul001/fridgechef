//
//  ProfileView.swift
//  FridgeChef
//
//  Profil sekmesi: hesap + diyet/mutfak tercihi (değiştirilebilir) + şifre + çıkış.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager

    // Cihazda saklanan tercihler (değiştirince AI'a da yansır)
    @AppStorage("diyetTercihi") private var diyetTercihi = ""
    @AppStorage("mutfakTercihleri") private var mutfakTercihleri = ""
    @AppStorage("diyetKisitlari") private var diyetKisitlari = ""
    @AppStorage("yemekSeviyesi") private var yemekSeviyesi = ""

    @State private var sifreAcik = false

    private let diyetler = ["I Eat Everything", "Vegetarian", "Vegan"]
    private let seviyeler = ["Novice", "Intermediate", "Advanced", "Professional"]
    private let kisitlamalar = ["Gluten-free", "Nut-free", "Dairy-free", "Low-carb",
                                "Keto", "Soy-free", "Peanut-free", "Raw food"]
    private let mutfaklar = ["Italian", "Turkish", "Indian", "Japanese", "Chinese",
                             "Thai", "Mexican", "French", "Greek", "Korean", "American", "Spanish"]

    var body: some View {
        NavigationStack {
            Form {
                // --- Hesap ---
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(Color.freshGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authManager.email ?? "FridgeChef User")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            Text("Signed in")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // --- Diyet tercihi ---
                Section("Diet") {
                    Picker("Diet preference", selection: $diyetTercihi) {
                        ForEach(diyetler, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                // --- Yemek yapma seviyesi ---
                Section("Cooking level") {
                    Picker("Skill level", selection: $yemekSeviyesi) {
                        Text("Any").tag("")
                        ForEach(seviyeler, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                // --- Diyet kısıtlamaları / alerjiler (çoklu) ---
                Section("Dietary restrictions & allergies") {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 100), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(kisitlamalar, id: \.self) { kisit in
                            cokluChip(kisit, kaynak: diyetKisitlari) { diyetKisitlari = $0 }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // --- Mutfak tercihleri (çoklu) ---
                Section("Cuisines you like") {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 92), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(mutfaklar, id: \.self) { mutfak in
                            cokluChip(mutfak, kaynak: mutfakTercihleri) { mutfakTercihleri = $0 }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // --- Hesap işlemleri ---
                Section {
                    Button {
                        sifreAcik = true
                    } label: {
                        Label("Change password", systemImage: "key")
                    }
                    Button(role: .destructive) {
                        authManager.cikisYap()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $sifreAcik) {
                NavigationStack { ChangePasswordView() }
            }
        }
    }

    // --- Ortak çoklu-seçim chip'i (mutfak + kısıtlamalar kullanır) ---
    // kaynak: virgülle ayrılmış mevcut seçimler, guncelle: yeni değeri yazar
    private func cokluChip(_ etiket: String, kaynak: String, guncelle: @escaping (String) -> Void) -> some View {
        let set = Set(kaynak.split(separator: ",").map(String.init))
        let secili = set.contains(etiket)
        return Button {
            var s = set
            if s.contains(etiket) { s.remove(etiket) } else { s.insert(etiket) }
            guncelle(s.sorted().joined(separator: ","))
        } label: {
            Text(etiket)
                .font(.subheadline)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(secili ? Color.freshGreen : Color.cardBackground)
                .foregroundStyle(secili ? .white : Color.textPrimary)
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}
