//
//  ContentView.swift
//  FridgeChef
//
//  Uygulamanın kökü: Splash → (ilk açılışta) Onboarding → Ana ekran.
//

import SwiftUI

struct ContentView: View {
    // Firebase giriş yöneticisi (FridgeChefApp'ten gelir)
    @Environment(AuthManager.self) private var authManager
    // Açılış ekranı bitti mi?
    @State private var acilisBitti = false
    // Tanıtım daha önce görüldü mü? (cihazda kalıcı saklanır)
    @AppStorage("onboardingTamamlandi") private var onboardingTamamlandi = false
    // Sosyal giriş için geçici bayrak (Google/Apple bağlanınca kaldırılacak)
    @AppStorage("girisYapildi") private var girisYapildi = false
    // Profil tamamlandı mı?
    @AppStorage("profilTamamlandi") private var profilTamamlandi = false
    // Diyet tercihi seçildi mi?
    @AppStorage("diyetTercihi") private var diyetTercihi = ""
    // Mutfak tercihi seçildi mi?
    @AppStorage("mutfakSecildi") private var mutfakSecildi = false

    var body: some View {
        icerik
            // Kullanıcı (giriş) değişince: buluttaki profili kontrol et
            .task(id: authManager.kullaniciID) {
                if authManager.girisYapildiMi, await authManager.profilVarMi() {
                    profilTamamlandi = true   // kayıtlı kullanıcı → profil ekranını atla
                }
            }
    }

    @ViewBuilder
    private var icerik: some View {
        if !acilisBitti {
            // 1) Açılış ekranı
            SplashView()
                .task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { acilisBitti = true }
                }
        } else if !onboardingTamamlandi {
            // 2) Tanıtım (sadece ilk açılışta)
            OnboardingView()
        } else if !authManager.girisYapildiMi && !girisYapildi {
            // 3) Giriş / kayıt (Firebase ile e-posta, ya da geçici sosyal bayrak)
            AuthView()
        } else if !profilTamamlandi {
            // 4) Profil tamamlama (sadece ilk girişte)
            ProfileSetupView()
        } else if diyetTercihi.isEmpty {
            // 5) Diyet tercihi (sadece ilk girişte)
            PreferencesView()
        } else if !mutfakSecildi {
            // 6) Mutfak tercihi (sadece ilk girişte)
            CuisinePreferenceView()
        } else {
            // 7) Ana ekran (Home · Recipes · Create · Favorites · Profile)
            MainTabView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
