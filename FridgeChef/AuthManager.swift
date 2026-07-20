//
//  AuthManager.swift
//  FridgeChef
//
//  Firebase ile giriş/kayıt işlemlerini yöneten sınıf.
//  Tüm ekranlar bu tek yöneticiyi kullanır.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@Observable
class AuthManager {
    // Şu anki kullanıcı (nil ise giriş yapılmamış)
    var user: User?
    // Hata mesajı (varsa ekranda gösterilir)
    var hataMesaji: String?
    // İşlem sürüyor mu? (buton spinner'ı için)
    var yukleniyor = false
    // Telefon doğrulama kimliği (SMS gönderilince dolar)
    var dogrulamaID: String?

    init() {
        // Firebase başlatılmadıysa (örn. Preview'da) dokunma
        guard FirebaseApp.app() != nil else { return }
        #if DEBUG
        // Simülatörde test telefon numaralarıyla çalışmak için (gerçek SMS gitmez)
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        #endif
        // Uygulama açılınca: zaten giriş yapılmış mı bak
        user = Auth.auth().currentUser
        // Giriş durumu değişince (giriş/çıkış) otomatik haberdar ol
        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }

    // Giriş yapılmış mı? (ContentView bunu kullanır)
    var girisYapildiMi: Bool { user != nil }
    // Kullanıcı kimliği (View'lar Firebase'i bilmeden kullanır)
    var kullaniciID: String? { user?.uid }
    // Kullanıcının e-posta adresi
    var email: String? { user?.email }

    // E-posta + şifre ile YENİ hesap oluştur
    func kayitOl(email: String, sifre: String) async {
        yukleniyor = true
        hataMesaji = nil
        do {
            let sonuc = try await Auth.auth().createUser(withEmail: email, password: sifre)
            // Kullanıcının e-postasına doğrulama linki gönder
            try? await sonuc.user.sendEmailVerification()
            // Başarılı: addStateDidChangeListener otomatik user'ı günceller
        } catch {
            hataMesaji = cevirHata(error)
        }
        yukleniyor = false
    }

    // E-posta + şifre ile GİRİŞ yap
    func girisYap(email: String, sifre: String) async {
        yukleniyor = true
        hataMesaji = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: sifre)
        } catch {
            hataMesaji = cevirHata(error)
        }
        yukleniyor = false
    }

    // Google ile giriş
    func googleIleGiris() async {
        yukleniyor = true
        hataMesaji = nil
        do {
            // Firebase'den Google istemci kimliğini al
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                hataMesaji = "Google yapılandırması bulunamadı."
                yukleniyor = false
                return
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            // Google ekranını gösterecek ekranı bul
            guard let kokVC = Self.kokViewController() else {
                hataMesaji = "Ekran bulunamadı."
                yukleniyor = false
                return
            }

            // Google giriş ekranını aç
            let sonuc = try await GIDSignIn.sharedInstance.signIn(withPresenting: kokVC)
            guard let idToken = sonuc.user.idToken?.tokenString else {
                hataMesaji = "Google kimliği alınamadı."
                yukleniyor = false
                return
            }
            // Google kimliğini Firebase'e ver, giriş yap
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: sonuc.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
        } catch {
            // Kullanıcı iptal ettiyse hata gösterme
            if (error as NSError).code != GIDSignInError.canceled.rawValue {
                hataMesaji = cevirHata(error)
            }
        }
        yukleniyor = false
    }

    // Google ekranını gösterecek en üstteki ekranı bul
    static func kokViewController() -> UIViewController? {
        guard let sahne = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let kok = sahne.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return kok
    }

    // --- Firestore: profil ---

    // Profili buluta kaydet (users/{uid})
    func profilKaydet(_ profil: KullaniciProfili) async -> Bool {
        guard let uid = user?.uid else {
            hataMesaji = "Önce giriş yapmalısın."
            return false
        }
        do {
            try Firestore.firestore().collection("users").document(uid).setData(from: profil, merge: true)
            return true
        } catch {
            hataMesaji = error.localizedDescription
            return false
        }
    }

    // Bu kullanıcının buluta kayıtlı profili var mı?
    func profilVarMi() async -> Bool {
        guard let uid = user?.uid else { return false }
        do {
            let belge = try await Firestore.firestore().collection("users").document(uid).getDocument()
            return belge.exists
        } catch {
            return false
        }
    }

    // Telefona 6 haneli SMS kodu gönder
    func telefonKoduGonder(numara: String) async -> Bool {
        yukleniyor = true
        hataMesaji = nil
        do {
            let id = try await PhoneAuthProvider.provider().verifyPhoneNumber(numara, uiDelegate: nil)
            dogrulamaID = id
            yukleniyor = false
            return true
        } catch {
            hataMesaji = cevirHata(error)
            yukleniyor = false
            return false
        }
    }

    // Girilen 6 haneli kodu doğrula ve giriş yap
    func telefonKoduDogrula(kod: String) async {
        guard let id = dogrulamaID else {
            hataMesaji = "Doğrulama kimliği bulunamadı."
            return
        }
        yukleniyor = true
        hataMesaji = nil
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: id, verificationCode: kod
            )
            try await Auth.auth().signIn(with: credential)
        } catch {
            hataMesaji = cevirHata(error)
        }
        yukleniyor = false
    }

    // Giriş yapmış kullanıcının şifresini değiştir
    func sifreDegistir(yeniSifre: String) async -> Bool {
        yukleniyor = true
        hataMesaji = nil
        do {
            try await Auth.auth().currentUser?.updatePassword(to: yeniSifre)
            yukleniyor = false
            return true
        } catch {
            hataMesaji = cevirHata(error)
            yukleniyor = false
            return false
        }
    }

    // Şifre sıfırlama e-postası gönder
    func sifreSifirla(email: String) async -> Bool {
        yukleniyor = true
        hataMesaji = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            yukleniyor = false
            return true
        } catch {
            hataMesaji = cevirHata(error)
            yukleniyor = false
            return false
        }
    }

    // Çıkış yap
    func cikisYap() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        // Geçici sosyal giriş bayrağını da temizle (giriş ekranına dönmek için)
        UserDefaults.standard.set(false, forKey: "girisYapildi")
    }

    // Firebase hatasını okunabilir mesaja çevir
    private func cevirHata(_ error: Error) -> String {
        let kod = AuthErrorCode(rawValue: (error as NSError).code)
        switch kod {
        case .invalidEmail:        return "Geçersiz e-posta adresi."
        case .emailAlreadyInUse:   return "Bu e-posta zaten kayıtlı."
        case .weakPassword:        return "Şifre çok zayıf (en az 6 karakter)."
        case .wrongPassword:       return "Hatalı şifre."
        case .userNotFound:        return "Böyle bir kullanıcı yok."
        default:                   return error.localizedDescription
        }
    }
}
