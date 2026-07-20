//
//  PreferencesView.swift
//  FridgeChef
//
//  Diyet tercihi ekranı: kullanıcı ne yediğini seçer, AI ona göre tarif önerir.
//

import SwiftUI

// Bir diyet seçeneği
struct DietOption: Identifiable {
    let id = UUID()
    let baslik: String
    let aciklama: String
    let emoji: String
}

struct PreferencesView: View {
    // Seçilen diyet tercihi (cihazda kalıcı saklanır)
    @AppStorage("diyetTercihi") private var diyetTercihi = ""

    // Şu an seçili olan kart
    @State private var secili: String = ""

    private let secenekler = [
        DietOption(
            baslik: "I Eat Everything",
            aciklama: "We'll suggest all kinds of recipes — meat and veggie",
            emoji: "🍗"
        ),
        DietOption(
            baslik: "Vegetarian",
            aciklama: "We'll suggest delicious veggie-focused recipes",
            emoji: "🥗"
        ),
        DietOption(
            baslik: "Vegan",
            aciklama: "We'll suggest recipes with no animal products",
            emoji: "🌱"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // --- Başlık ---
            VStack(alignment: .leading, spacing: 8) {
                Text("Hi! 👋")
                    .font(.title2)
                    .foregroundStyle(Color.textSecondary)
                Text("What do you like to eat?")
                    .font(.largeTitle).bold()
                    .foregroundStyle(Color.darkGreen)
            }
            .padding(.top, 40)

            // --- Seçenek kartları ---
            VStack(spacing: 14) {
                ForEach(secenekler) { secenek in
                    secenekKarti(secenek)
                }
            }

            Spacer()

            // --- Başla butonu ---
            Button {
                diyetTercihi = secili   // seçimi kaydet, ana ekrana geç
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(secili.isEmpty ? Color.gray.opacity(0.4) : Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 16))
            }
            .disabled(secili.isEmpty)   // bir seçim yapılmadan buton pasif
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // Tek bir seçenek kartı (seçiliyse yeşil çerçeve + onay)
    private func secenekKarti(_ secenek: DietOption) -> some View {
        let secildi = (secili == secenek.baslik)

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                secili = secenek.baslik
            }
        } label: {
            HStack(spacing: 16) {
                Text(secenek.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(secenek.baslik))   // String'i çeviri anahtarı yap
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text(LocalizedStringKey(secenek.aciklama))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Sağdaki seçim göstergesi (yuvarlak)
                Image(systemName: secildi ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(secildi ? Color.freshGreen : Color.gray.opacity(0.4))
            }
            .padding()
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                // Seçiliyse yeşil çerçeve
                RoundedRectangle(cornerRadius: 16)
                    .stroke(secildi ? Color.freshGreen : Color.clear, lineWidth: 2)
            }
        }
    }
}

#Preview {
    PreferencesView()
}
