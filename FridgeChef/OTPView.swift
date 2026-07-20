//
//  OTPView.swift
//  FridgeChef
//
//  6 haneli SMS kodu giriş ekranı.
//

import SwiftUI

struct OTPView: View {
    @Environment(AuthManager.self) private var authManager
    let numara: String

    @State private var kod = ""
    @FocusState private var odakli: Bool

    var body: some View {
        VStack(spacing: 28) {

            VStack(spacing: 8) {
                Text("Enter the code")
                    .font(.largeTitle).bold()
                    .foregroundStyle(Color.textPrimary)
                Text("Enter the 6-digit code sent to your phone")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            // --- 6 haneli kutular (arkada gizli TextField) ---
            ZStack {
                TextField("", text: $kod)
                    .keyboardType(.numberPad)
                    .focused($odakli)
                    .opacity(0.001)   // görünmez ama girişi yakalar

                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        haneKutusu(i)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { odakli = true }
            }
            .padding(.horizontal, 24)

            // --- Doğrula butonu ---
            Button {
                Task { await authManager.telefonKoduDogrula(kod: kod) }
            } label: {
                Group {
                    if authManager.yukleniyor {
                        ProgressView().tint(.white)
                    } else {
                        Text("Verify").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(kod.count < 6 ? Color.gray.opacity(0.4) : Color.freshGreen)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(kod.count < 6 || authManager.yukleniyor)
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationTitle("Verify")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { odakli = true }
        .onChange(of: kod) { _, yeni in
            // Sadece rakam, en fazla 6 hane
            let temiz = String(yeni.filter(\.isNumber).prefix(6))
            if temiz != kod { kod = temiz }
            // 6 hane dolunca otomatik doğrula
            if kod.count == 6 {
                Task { await authManager.telefonKoduDogrula(kod: kod) }
            }
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

    // Tek bir hane kutusu
    private func haneKutusu(_ i: Int) -> some View {
        let karakterler = Array(kod)
        let dolu = i < karakterler.count
        let aktif = i == karakterler.count
        return Text(dolu ? String(karakterler[i]) : "")
            .font(.title).bold()
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(aktif ? Color.freshGreen : Color.clear, lineWidth: 2)
            }
    }
}

#Preview {
    NavigationStack {
        OTPView(numara: "+90 555 123 4567")
    }
    .environment(AuthManager())
}
