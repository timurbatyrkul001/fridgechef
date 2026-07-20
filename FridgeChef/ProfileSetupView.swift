//
//  ProfileSetupView.swift
//  FridgeChef
//
//  Profil tamamlama ekranı (Cashly tarzı): ad, telefon, cinsiyet, doğum tarihi, adres.
//

import SwiftUI

struct ProfileSetupView: View {
    @Environment(AuthManager.self) private var authManager
    @AppStorage("profilTamamlandi") private var profilTamamlandi = false
    @AppStorage("kullaniciAdi") private var kullaniciAdi = ""

    @State private var adSoyad = ""
    @State private var telefon = ""
    @State private var cinsiyet = ""
    @State private var dogumTarihi = Date()
    @State private var adres = ""

    private let cinsiyetler = ["Male", "Female", "Other"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // --- Başlık ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Profile")
                            .font(.largeTitle).bold()
                            .foregroundStyle(Color.textPrimary)
                        Text("Tell us a bit about yourself")
                            .font(.body)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 16)

                    // --- Ad Soyad ---
                    alan(baslik: "Full name") {
                        TextField("Enter your full name", text: $adSoyad)
                    }

                    // --- Telefon ---
                    alan(baslik: "Phone number") {
                        TextField("Phone number", text: $telefon)
                            .keyboardType(.phonePad)
                    }

                    // --- Cinsiyet (açılır menü) ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender").font(.subheadline).bold()
                            .foregroundStyle(Color.textPrimary)
                        Menu {
                            ForEach(cinsiyetler, id: \.self) { c in
                                Button(LocalizedStringKey(c)) { cinsiyet = c }
                            }
                        } label: {
                            HStack {
                                Text(cinsiyet.isEmpty ? "Select gender" : LocalizedStringKey(cinsiyet))
                                    .foregroundStyle(cinsiyet.isEmpty ? Color.textSecondary : Color.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .clipShape(.rect(cornerRadius: 14))
                        }
                    }

                    // --- Doğum tarihi ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of birth").font(.subheadline).bold()
                            .foregroundStyle(Color.textPrimary)
                        DatePicker("", selection: $dogumTarihi, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.cardBackground)
                            .clipShape(.rect(cornerRadius: 14))
                    }

                    // --- Adres ---
                    alan(baslik: "Address") {
                        TextField("Enter your address", text: $adres)
                    }

                    // --- Devam butonu ---
                    Button {
                        Task {
                            // Profili buluta (Firestore) kaydet
                            let profil = KullaniciProfili(
                                ad: adSoyad,
                                telefon: telefon,
                                cinsiyet: cinsiyet,
                                dogumTarihi: dogumTarihi,
                                adres: adres
                            )
                            let ok = await authManager.profilKaydet(profil)
                            if ok {
                                kullaniciAdi = adSoyad
                                profilTamamlandi = true   // diyet ekranına geçer
                            }
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
                        .background(adSoyad.isEmpty ? Color.gray.opacity(0.4) : Color.freshGreen)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .disabled(adSoyad.isEmpty || authManager.yukleniyor)
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationTitle("Complete profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Etiket + kutu üreten yardımcı
    private func alan<İcerik: View>(
        baslik: LocalizedStringKey,
        @ViewBuilder _ icerik: () -> İcerik
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(baslik).font(.subheadline).bold()
                .foregroundStyle(Color.textPrimary)
            icerik()
                .padding()
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: 14))
        }
    }
}

#Preview {
    ProfileSetupView()
        .environment(AuthManager())
}
