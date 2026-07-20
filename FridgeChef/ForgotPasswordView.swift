//
//  ForgotPasswordView.swift
//  FridgeChef
//
//  Şifremi unuttum ekranı: e-posta gir → Firebase sıfırlama linki gönderir.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var gonderildi = false   // mail gönderildi mi?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if gonderildi {
                    basariliGorunum
                } else {
                    formGorunumu
                }
            }
            .padding(24)
        }
        .navigationTitle("Forgot password")
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

    // --- Form (e-posta girme) ---
    private var formGorunumu: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Forgot password")
                    .font(.largeTitle).bold()
                    .foregroundStyle(Color.textPrimary)
                Text("Enter your email address to reset your password")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("Email").font(.subheadline).bold()
                    .foregroundStyle(Color.textPrimary)
                TextField("Enter your email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: 14))
            }

            Button {
                Task {
                    let basarili = await authManager.sifreSifirla(email: email)
                    if basarili { gonderildi = true }
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
                .background(email.isEmpty ? Color.gray.opacity(0.4) : Color.freshGreen)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(email.isEmpty || authManager.yukleniyor)
        }
    }

    // --- Başarılı (mail gönderildi) ---
    private var basariliGorunum: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.freshGreen)
                .padding(.top, 40)

            Text("Check your email")
                .font(.title).bold()
                .foregroundStyle(Color.textPrimary)

            Text("We've sent password reset instructions to your email.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Text("Check your spam folder if you don't see it.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Back to Sign in")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
    .environment(AuthManager())
}
