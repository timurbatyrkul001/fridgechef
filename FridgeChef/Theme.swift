//
//  Theme.swift
//  FridgeChef
//
//  Uygulamanın renk paleti tek yerde. Mangan tasarımından alındı.
//  Tüm ekranlarda Color.freshGreen, Color.darkGreen ... diye kullanırız.
//

import SwiftUI

extension Color {
    // Ana yeşil — butonlar, vurgular
    static let freshGreen = Color(hex: "7CB342")
    // Koyu yeşil — başlıklar
    static let darkGreen = Color(hex: "2E5D2B")
    // Ana metin (neredeyse siyah)
    static let textPrimary = Color(hex: "1C1C1E")
    // İkincil metin (gri açıklamalar)
    static let textSecondary = Color(hex: "8E8E93")
    // Kart zemini (çok açık gri)
    static let cardBackground = Color(hex: "F5F6F3")
}

// Hex koddan renk üretmemizi sağlayan yardımcı.
// SwiftUI normalde "#7CB342" gibi hex kabul etmez, bu eklenti onu çevirir.
extension Color {
    init(hex: String) {
        let temiz = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: temiz).scanHexInt64(&rgb)

        let kirmizi = Double((rgb >> 16) & 0xFF) / 255.0
        let yesil = Double((rgb >> 8) & 0xFF) / 255.0
        let mavi = Double(rgb & 0xFF) / 255.0

        self.init(red: kirmizi, green: yesil, blue: mavi)
    }
}
