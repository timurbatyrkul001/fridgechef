//
//  SplashView.swift
//  FridgeChef
//
//  Açılış ekranı: yeşil zemin + FridgeChef logosu, sonra ana ekrana geçer.
//

import SwiftUI

struct SplashView: View {
    // Logonun büyüme animasyonu için
    @State private var olcek = 0.6
    @State private var saydamlik = 0.0

    var body: some View {
        ZStack {
            // Tüm ekranı kaplayan yeşil zemin
            Color.freshGreen
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo ikonu (beyaz daire içinde çatal-bıçak)
                Image(systemName: "fork.knife")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(Color.freshGreen)
                    .frame(width: 130, height: 130)
                    .background(.white)
                    .clipShape(Circle())

                // Uygulama adı
                Text("FridgeChef")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                // Slogan
                Text("Your fridge, your chef")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .scaleEffect(olcek)       // animasyonla büyüsün
            .opacity(saydamlik)       // animasyonla belirsin
        }
        .onAppear {
            // Ekran açılınca yumuşak büyüme + belirme animasyonu
            withAnimation(.easeOut(duration: 0.8)) {
                olcek = 1.0
                saydamlik = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
