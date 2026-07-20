//
//  AuthView.swift
//  FridgeChef
//
//  Karşılama / giriş ekranı. Üstteki fotoğraf onboarding sayfalarıyla birebir aynı stilde.
//

import SwiftUI

struct AuthView: View {
    @Environment(AuthManager.self) private var authManager
    // Apple girişi için geçici bayrak (gerçek bağlanınca kaldırılacak)
    @AppStorage("girisYapildi") private var girisYapildi = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // --- Üst fotoğraf (tam ekran, status bar altından) ---
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .overlay {
                            Image("AuthHero")
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()

                    // --- Başlık + alt yazı ---
                    VStack(spacing: 12) {
                        Text("Start Your Exciting Cooking Journey Today")
                            .font(.title).bold()
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Choose a login method to continue and discover delicious recipes.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // --- Butonlar (aralarında 8px) ---
                    VStack(spacing: 8) {
                        // Sign up (ana yeşil buton)
                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text("Sign up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.freshGreen)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }

                        // Continue with Google
                        Button {
                            Task { await authManager.googleIleGiris() }
                        } label: {
                            HStack(spacing: 10) {
                                Image("GoogleLogo").resizable().frame(width: 20, height: 20)
                                Text("Continue with Google").font(.headline)
                            }
                            .sosyalStili()
                        }

                        // Continue with Apple (geçici)
                        Button {
                            girisYapildi = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "apple.logo").font(.title3)
                                Text("Continue with Apple").font(.headline)
                            }
                            .sosyalStili()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // --- Sign in linki ---
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                        NavigationLink("Sign in") {
                            SignInView()
                        }
                        .font(.subheadline).bold()
                        .foregroundStyle(Color.freshGreen)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .alert("Error", isPresented: Binding(
                get: { authManager.hataMesaji != nil },
                set: { _ in authManager.hataMesaji = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authManager.hataMesaji ?? "")
            }
        }
    }
}

// Beyaz hap buton görünümü (Google/Apple)
private extension View {
    func sosyalStili() -> some View {
        self
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white)
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
            }
    }
}

#Preview {
    AuthView()
        .environment(AuthManager())
}
