//
//  ChangePasswordView.swift
//  FridgeChef
//
//  Yeni şifre belirleme ekranı (giriş yapmış kullanıcı). Canlı kural kontrolü.
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var sifre = ""
    @State private var tekrar = ""
    @State private var sifreGoster = false
    @State private var tekrarGoster = false
    @State private var basarili = false   // şifre değişti mi?

    // --- Canlı doğrulama kuralları ---
    private var enAz8: Bool { sifre.count >= 8 }
    private var rakamVeyaSembol: Bool {
        sifre.contains { $0.isNumber || $0.isPunctuation || $0.isSymbol }
    }
    private var eslesiyor: Bool { !sifre.isEmpty && sifre == tekrar }
    private var gecerli: Bool { enAz8 && rakamVeyaSembol && eslesiyor }

    var body: some View {
        Group {
            if basarili {
                basariliGorunum
            } else {
                formGorunumu
            }
        }
        .navigationTitle(basarili ? "" : "New password")
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

    // --- Form ---
    private var formGorunumu: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("New password")
                        .font(.largeTitle).bold()
                        .foregroundStyle(Color.textPrimary)
                    Text("Set a new password for your account")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 16)

                sifreAlani(baslik: "Password", deger: $sifre, goster: $sifreGoster,
                           ipucu: "Enter your password")

                sifreAlani(baslik: "Repeat password", deger: $tekrar, goster: $tekrarGoster,
                           ipucu: "Repeat your password")

                VStack(alignment: .leading, spacing: 10) {
                    kural("At least 8 characters", saglandi: enAz8)
                    kural("Contains a number or symbol", saglandi: rakamVeyaSembol)
                    kural("Passwords match", saglandi: eslesiyor)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: 14))

                Button {
                    Task {
                        let ok = await authManager.sifreDegistir(yeniSifre: sifre)
                        if ok { basarili = true }
                    }
                } label: {
                    Group {
                        if authManager.yukleniyor {
                            ProgressView().tint(.white)
                        } else {
                            Text("Continue").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gecerli ? Color.freshGreen : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .disabled(!gecerli || authManager.yukleniyor)
            }
            .padding(24)
        }
    }

    // --- Başarılı ekranı ---
    private var basariliGorunum: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.freshGreen)

            Text("Password Successfully Changed")
                .font(.title2).bold()
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Your password has been updated. You can now log in with your new password.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button {
                authManager.cikisYap()   // çıkış yap, giriş ekranına dön
            } label: {
                Text("Go to login")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // Göz ikonlu şifre alanı
    private func sifreAlani(baslik: LocalizedStringKey, deger: Binding<String>,
                            goster: Binding<Bool>, ipucu: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(baslik).font(.subheadline).bold()
                .foregroundStyle(Color.textPrimary)
            HStack {
                if goster.wrappedValue {
                    TextField(ipucu, text: deger)
                } else {
                    SecureField(ipucu, text: deger)
                }
                Button { goster.wrappedValue.toggle() } label: {
                    Image(systemName: goster.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: 14))
        }
    }

    // Tek bir kural satırı
    private func kural(_ metin: LocalizedStringKey, saglandi: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: saglandi ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(saglandi ? Color.freshGreen : Color.gray.opacity(0.4))
            Text(metin)
                .font(.subheadline)
                .foregroundStyle(saglandi ? Color.textPrimary : Color.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
    }
    .environment(AuthManager())
}
