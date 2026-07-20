//
//  SignInView.swift
//  FridgeChef
//
//  E-posta + şifre ile giriş ekranı (Cashly tarzı).
//  NOT: Şu an gerçek doğrulama yok — Firebase ile bağlanacak.
//

import SwiftUI

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    @AppStorage("girisYapildi") private var girisYapildi = false

    @State private var email = ""
    @State private var sifre = ""
    @State private var sifreyiGoster = false
    @State private var beniHatirla = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // --- Başlık ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign in")
                        .font(.largeTitle).bold()
                        .foregroundStyle(Color.textPrimary)
                    Text("We're thrilled to have you back. Let's dive in and find delicious recipes for you!")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 16)

                // --- E-posta alanı ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline).bold()
                        .foregroundStyle(Color.textPrimary)
                    TextField("Enter your email", text: $email)
                        .textInputAutocapitalization(.never)   // e-postada büyük harf yapma
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))
                }

                // --- Şifre alanı ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline).bold()
                        .foregroundStyle(Color.textPrimary)
                    HStack {
                        // Şifre göster/gizle durumuna göre alan değişir
                        if sifreyiGoster {
                            TextField("Enter your password", text: $sifre)
                        } else {
                            SecureField("Enter your password", text: $sifre)
                        }
                        Button {
                            sifreyiGoster.toggle()
                        } label: {
                            Image(systemName: sifreyiGoster ? "eye.slash" : "eye")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: 14))
                }

                // --- Beni hatırla + Şifremi unuttum ---
                HStack {
                    Button {
                        beniHatirla.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: beniHatirla ? "checkmark.square.fill" : "square")
                                .foregroundStyle(beniHatirla ? Color.freshGreen : Color.textSecondary)
                            Text("Remember me")
                                .font(.subheadline)
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                    Spacer()
                    NavigationLink("Forgot password?") {
                        ForgotPasswordView()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.freshGreen)
                }

                // --- Giriş butonu ---
                Button {
                    Task { await authManager.girisYap(email: email, sifre: sifre) }
                } label: {
                    // İşlem sürerken spinner, normalde "Sign in" yazısı
                    Group {
                        if authManager.yukleniyor {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign in").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .disabled(authManager.yukleniyor)

                // --- "ya da" ayıracı ---
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.25))
                    Text("or sign in with")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize()
                        .padding(.horizontal, 12)
                    Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.25))
                }

                // --- Sosyal girişler ---
                VStack(spacing: 14) {
                    Button { Task { await authManager.googleIleGiris() } } label: {
                        HStack(spacing: 10) {
                            Image("GoogleLogo").resizable().frame(width: 20, height: 20)
                            Text("Continue with Google").font(.headline)
                        }
                        .sosyalStili()
                    }
                    Button { girisYapildi = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo").font(.title3)
                            Text("Continue with Apple").font(.headline)
                        }
                        .sosyalStili()
                    }
                }

                // --- Kayıt linki ---
                HStack {
                    Spacer()
                    Text("Don't have an account?")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    NavigationLink("Sign up") {
                        SignUpView()
                    }
                    .font(.subheadline).bold()
                    .foregroundStyle(Color.freshGreen)
                    Spacer()
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
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

// Beyaz, kenarlıklı sosyal giriş butonu görünümü
private extension View {
    func sosyalStili() -> some View {
        self
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white)
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
            }
    }
}

#Preview {
    NavigationStack {
        SignInView()
    }
    .environment(AuthManager())
}
