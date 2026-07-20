//
//  CuisinePreferenceView.swift
//  FridgeChef
//
//  Mutfak tercihi ekranı (çoklu seçim). AI tarif önerirken bu tercihler kullanılır.
//

import SwiftUI

struct Cuisine: Identifiable {
    let id = UUID()
    let kod: String      // saklanan kod (İngilizce)
    let emoji: String
    let isim: LocalizedStringKey
}

struct CuisinePreferenceView: View {
    // Seçilen mutfaklar (virgülle ayrılmış, cihazda saklanır)
    @AppStorage("mutfakTercihleri") private var mutfakTercihleri = ""
    @AppStorage("mutfakSecildi") private var mutfakSecildi = false

    @State private var secili: Set<String> = []

    private let mutfaklar = [
        Cuisine(kod: "Italian", emoji: "🍝", isim: "Italian"),
        Cuisine(kod: "Turkish", emoji: "🥙", isim: "Turkish"),
        Cuisine(kod: "Indian", emoji: "🍛", isim: "Indian"),
        Cuisine(kod: "Japanese", emoji: "🍣", isim: "Japanese"),
        Cuisine(kod: "Chinese", emoji: "🥡", isim: "Chinese"),
        Cuisine(kod: "Thai", emoji: "🍲", isim: "Thai"),
        Cuisine(kod: "Mexican", emoji: "🌮", isim: "Mexican"),
        Cuisine(kod: "French", emoji: "🥐", isim: "French"),
        Cuisine(kod: "Greek", emoji: "🥗", isim: "Greek"),
        Cuisine(kod: "Georgian", emoji: "🫓", isim: "Georgian"),
        Cuisine(kod: "Kazakh", emoji: "🍖", isim: "Kazakh"),
        Cuisine(kod: "Korean", emoji: "🍜", isim: "Korean"),
        Cuisine(kod: "American", emoji: "🍔", isim: "American"),
        Cuisine(kod: "Spanish", emoji: "🥘", isim: "Spanish")
    ]

    private let sutunlar = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            // --- Başlık ---
            VStack(alignment: .leading, spacing: 8) {
                Text("Set your food preferences")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Text("Which food do you prefer?")
                    .font(.title).bold()
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            // --- Mutfak ızgarası ---
            ScrollView {
                LazyVGrid(columns: sutunlar, spacing: 24) {
                    ForEach(mutfaklar) { mutfak in
                        mutfakKarti(mutfak)
                    }
                }
                .padding(24)
            }

            // --- Next butonu ---
            Button {
                mutfakTercihleri = secili.joined(separator: ",")
                mutfakSecildi = true
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(secili.isEmpty ? Color.gray.opacity(0.4) : Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .disabled(secili.isEmpty)
            .padding(.horizontal, 16)

            // --- Fark etmez (seçimsiz devam) ---
            Button("No preference") {
                mutfakTercihleri = ""
                mutfakSecildi = true
            }
            .font(.subheadline)
            .foregroundStyle(Color.textSecondary)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    // Tek bir mutfak kartı (emoji daire + isim, seçiliyse yeşil onay)
    private func mutfakKarti(_ mutfak: Cuisine) -> some View {
        let secildi = secili.contains(mutfak.kod)
        return Button {
            if secildi { secili.remove(mutfak.kod) }
            else { secili.insert(mutfak.kod) }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    Text(mutfak.emoji)
                        .font(.system(size: 36))
                        .frame(width: 80, height: 80)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(secildi ? Color.freshGreen : Color.clear, lineWidth: 3)
                        }
                    if secildi {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.freshGreen)
                            .background(Circle().fill(.white))
                    }
                }
                Text(mutfak.isim)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }
}

#Preview {
    CuisinePreferenceView()
}
