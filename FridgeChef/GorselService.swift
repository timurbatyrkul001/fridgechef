//
//  GorselService.swift
//  FridgeChef
//
//  Bir yemek adı için Wikipedia'dan GERÇEK fotoğraf URL'i getirir.
//  AI tariflerine (fotosu olmayan) gerçek görsel bağlamak için.
//

import Foundation

struct GorselService {
    static func realFoto(_ ad: String) async -> String? {
        let temiz = ad.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ad
        let adres = "https://en.wikipedia.org/w/api.php?action=query&titles=\(temiz)&prop=pageimages&format=json&pithumbsize=600&redirects=1"
        guard let url = URL(string: adres) else { return nil }

        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let kok = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let query = kok["query"] as? [String: Any],
            let pages = query["pages"] as? [String: Any]
        else { return nil }

        for (_, deger) in pages {
            if let sayfa = deger as? [String: Any],
               let thumb = sayfa["thumbnail"] as? [String: Any],
               let kaynak = thumb["source"] as? String {
                return kaynak
            }
        }
        return nil
    }
}
