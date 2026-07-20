//
//  KategoriKart.swift
//  FridgeChef
//
//  Kategori kartı: internetten yemek fotoğrafı (AsyncImage) + üstte isim.
//  Foto yüklenmezse yeşil degrade + emoji'ye düşer (bozulmaz).
//

import SwiftUI
import UIKit

struct KategoriKart: View {
    let ad: String
    let emoji: String
    var yukseklik: CGFloat = 130

    // Her kategoriye özel görsel (Pollinations) — tekrar olmasın diye ada göre üretir.
    private var url: URL? {
        let metin = "\(ad) dish, food photography, on a plate"
        let kodlu = metin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ad
        return URL(string: "https://image.pollinations.ai/prompt/\(kodlu)?width=400&height=300&nologo=true")
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            gorsel
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Okunabilirlik için alttan koyu degrade
            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)

            // İsim
            Text(ad)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(12)
        }
        .frame(height: yukseklik)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(.rect(cornerRadius: 16))
    }

    // Görsel önceliği: 1) Senin eklediğin asset ("cat_Salad" gibi)
    //                  2) İnternetten yemek fotoğrafı
    //                  3) Yeşil degrade + emoji
    @ViewBuilder
    private var gorsel: some View {
        if let kendiGorsel = UIImage(named: "cat_\(ad)") {
            Image(uiImage: kendiGorsel)
                .resizable()
                .scaledToFill()
        } else {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(colors: [Color.freshGreen, Color.darkGreen],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        Text(emoji).font(.system(size: 40))
                    }
                }
            }
        }
    }
}
