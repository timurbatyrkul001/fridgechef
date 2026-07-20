//
//  FridgeChefApp.swift
//  FridgeChef
//
//  Created by Timur Batyrkul on 15.06.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

@main
struct FridgeChefApp: App {
    // Tüm uygulamanın paylaştığı giriş yöneticisi
    @State private var authManager: AuthManager

    init() {
        // Önce Firebase'i başlat (her şeyden önce gelmeli)
        FirebaseApp.configure()
        // Sonra giriş yöneticisini oluştur
        _authManager = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)   // tüm alt ekranlara aktar
                .onOpenURL { url in
                    // Google girişi tamamlanınca uygulamaya geri dönüş
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        // SwiftData deposu (favoriler + üretilen tarifler)
        .modelContainer(for: [FavoriteRecipe.self, GeneratedRecipe.self])
    }
}
