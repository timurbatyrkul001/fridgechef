//
//  SignUpView.swift
//  FridgeChef
//
//  E-posta + şifre ile kayıt ekranı (Cashly tarzı).
//  NOT: Şu an gerçek kayıt yok — Firebase ile bağlanacak.
//

import SwiftUI

struct SignUpView: View {
    @Environment(AuthManager.self) private var authManager
    @AppStorage("girisYapildi") private var girisYapildi = false
    // Bu ekranı kapatıp geri dönmek için (Sign in linki)
    @Environment(\.dismiss) private var dismiss

    @State private var ad = ""
    @State private var email = ""
    @State private var sifre = ""
    @State private var sifreyiGoster = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // --- Başlık ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create your account")
                        .font(.largeTitle).bold()
                        .foregroundStyle(Color.textPrimary)
                    Text("Sign up to start cooking with what's in your fridge!")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 16)

                // --- Ad alanı ---
                alan(baslik: "Name") {
                    TextField("Enter your name", text: $ad)
                }

                // --- E-posta alanı ---
                alan(baslik: "Email") {
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                // --- Şifre alanı (göz ikonlu) ---
                alan(baslik: "Password") {
                    HStack {
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
                }

                // --- Kayıt butonu ---
                Button {
                    Task { await authManager.kayitOl(email: email, sifre: sifre) }
                } label: {
                    Group {
                        if authManager.yukleniyor {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign up").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .disabled(authManager.yukleniyor)

                // --- Şartlar metni ---
                (
                    Text("By signing up you agree to our ")
                        .foregroundStyle(Color.textSecondary)
                    + Text("Terms of Use").foregroundStyle(Color.freshGreen)
                    + Text(" and ").foregroundStyle(Color.textSecondary)
                    + Text("Privacy Policy").foregroundStyle(Color.freshGreen)
                    + Text(".").foregroundStyle(Color.textSecondary)
                )
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

                // --- "ya da" ayıracı ---
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.25))
                    Text("or sign up with")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize()
                        .padding(.horizontal, 12)
                    Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.25))
                }

                // --- Sosyal kayıt ---
                VStack(spacing: 14) {
                    Button { Task { await authManager.googleIleGiris() } } label: {
                        HStack(spacing: 10) {
                            Image("GoogleLogo").resizable().frame(width: 20, height: 20)
                            Text("Continue with Google").font(.headline)
                        }
                        .kayitSosyalStili()
                    }
                    Button { girisYapildi = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo").font(.title3)
                            Text("Continue with Apple").font(.headline)
                        }
                        .kayitSosyalStili()
                    }
                }

                // --- Giriş linki ---
                HStack {
                    Spacer()
                    Text("Already have an account?")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Button("Sign in") {
                        dismiss()   // bir önceki Sign In ekranına dön
                    }
                    .font(.subheadline).bold()
                    .foregroundStyle(Color.freshGreen)
                    Spacer()
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .navigationTitle("Sign up")
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

    // Etiket + alan kutusu üreten yardımcı (tekrarı önler)
    private func alan<İcerik: View>(
        baslik: LocalizedStringKey,
        @ViewBuilder _ icerik: () -> İcerik
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(baslik)
                .font(.subheadline).bold()
                .foregroundStyle(Color.textPrimary)
            icerik()
                .padding()
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: 14))
        }
    }
}

// Beyaz, kenarlıklı sosyal buton görünümü
private extension View {
    func kayitSosyalStili() -> some View {
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
        SignUpView()
    }
    .environment(AuthManager())
}
