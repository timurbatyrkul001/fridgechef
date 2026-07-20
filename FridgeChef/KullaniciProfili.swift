//
//  KullaniciProfili.swift
//  FridgeChef
//
//  Kullanıcının Firestore'da saklanan profil verisi.
//

import Foundation

struct KullaniciProfili: Codable {
    var ad: String
    var telefon: String
    var cinsiyet: String
    var dogumTarihi: Date
    var adres: String
}
