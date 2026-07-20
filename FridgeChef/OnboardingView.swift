//
//  OnboardingView.swift
//  FridgeChef
//
//  3 sayfalık tanıtım akışı. Kaydırarak geçilir, sonunda ana ekrana gider.
//

import SwiftUI

// Bir tanıtım sayfasının içeriği
struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String              // Assets'teki fotoğraf adı
    let title: LocalizedStringKey  // LocalizedStringKey = otomatik çevrilir
    let description: LocalizedStringKey
}

struct OnboardingView: View {
    // Tanıtım görüldü mü? true olunca bir daha gösterilmez (cihazda saklanır).
    @AppStorage("onboardingTamamlandi") private var onboardingTamamlandi = false

    // Şu an hangi sayfadayız (0, 1, 2)
    @State private var aktifSayfa = 0

    // 3 tanıtım sayfası
    private let sayfalar = [
        OnboardingPage(
            image: "onboarding1",
            title: "Welcome to FridgeChef!",
            description: "Add the ingredients in your fridge and we'll find recipes just for you. Let your kitchen adventure begin!"
        ),
        OnboardingPage(
            image: "onboarding2",
            title: "AI Finds Recipes",
            description: "Enter your ingredients and let AI suggest recipes you can make in seconds."
        ),
        OnboardingPage(
            image: "onboarding3",
            title: "Save Your Favorites",
            description: "Save the recipes you love and build your own personal recipe collection."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {

            // --- Kaydırılabilir sayfalar ---
            TabView(selection: $aktifSayfa) {
                ForEach(Array(sayfalar.enumerated()), id: \.element.id) { index, sayfa in
                    sayfaGorunumu(sayfa)
                        .tag(index)   // her sayfaya numara ver
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))   // kaydırma aç, varsayılan noktaları kapat

            // --- Nokta göstergeleri (kendi yeşil noktalarımız) ---
            HStack(spacing: 8) {
                ForEach(0..<sayfalar.count, id: \.self) { index in
                    Capsule()
                        .fill(index == aktifSayfa ? Color.freshGreen : Color.gray.opacity(0.3))
                        .frame(width: index == aktifSayfa ? 24 : 8, height: 8)
                        .animation(.spring, value: aktifSayfa)
                }
            }
            .padding(.vertical, 24)

            // --- Buton: son sayfada "Başla", diğerlerinde "Devam" ---
            Button {
                if aktifSayfa < sayfalar.count - 1 {
                    withAnimation { aktifSayfa += 1 }   // sonraki sayfaya geç
                } else {
                    onboardingTamamlandi = true          // bitir, ana ekrana git
                }
            } label: {
                Text(aktifSayfa < sayfalar.count - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            // --- Atla butonu ---
            Button("Skip for now") {
                onboardingTamamlandi = true
            }
            .font(.subheadline)
            .foregroundStyle(Color.freshGreen)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    // Tek bir tanıtım sayfasının görünümü (üstte yeşil + ikon, altta yazılar)
    private func sayfaGorunumu(_ sayfa: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            // Üst alan: gerçek yemek fotoğrafı + alta doğru yeşil geçiş
            Image(sayfa.image)
                .resizable()
                .scaledToFill()
                .frame(height: 380)
                .overlay(alignment: .bottom) {
                    // Fotoğrafın altını yeşile bağlayan yumuşak geçiş
                    LinearGradient(
                        colors: [.clear, Color.freshGreen.opacity(0.35)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .clipShape(.rect(cornerRadius: 32))
                .padding(.horizontal)

            // Başlık
            Text(sayfa.title)
                .font(.title).bold()
                .foregroundStyle(Color.darkGreen)
                .multilineTextAlignment(.center)

            // Açıklama
            Text(sayfa.description)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview {
    OnboardingView()
}
