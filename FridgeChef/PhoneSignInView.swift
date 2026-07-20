//
//  PhoneSignInView.swift
//  FridgeChef
//
//  Telefon ile giriş: numara gir → SMS 6 haneli kod gönder → OTP ekranına geç.
//

import SwiftUI

struct PhoneSignInView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var numara = "+90"
    @State private var otpEkrani = false   // OTP ekranına geçiş

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Continue with Phone")
                        .font(.largeTitle).bold()
                        .foregroundStyle(Color.textPrimary)
                    Text("We'll send you a 6-digit code")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone number").font(.subheadline).bold()
                        .foregroundStyle(Color.textPrimary)
                    TextField("Enter your phone number", text: $numara)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    Task {
                        let ok = await authManager.telefonKoduGonder(numara: numara)
                        if ok { otpEkrani = true }
                    }
                } label: {
                    Group {
                        if authManager.yukleniyor {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send code").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(numara.count < 8 ? Color.gray.opacity(0.4) : Color.freshGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .disabled(numara.count < 8 || authManager.yukleniyor)
            }
            .padding(24)
        }
        .navigationTitle("Phone")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $otpEkrani) {
            OTPView(numara: numara)
        }
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

#Preview {
    NavigationStack {
        PhoneSignInView()
    }
    .environment(AuthManager())
}
