//
//  MainTabView.swift
//  FridgeChef
//
//  Ana sekme çubuğu: Home · Recipes · Create · Favorites · Profile.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            DiscoverView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }

            IngredientsView()
                .tabItem { Label("Create", systemImage: "plus.circle.fill") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color.freshGreen)
    }
}
