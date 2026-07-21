# FridgeChef 🍳

Turn the ingredients you already have into **AI-generated recipes**. Tell FridgeChef what's in your
fridge, set your cuisine preferences, and get recipes you can actually cook.

Built **natively for iOS with SwiftUI**.

## Features

- **Ingredients → recipes** — enter what you have and generate recipes with AI (Google Gemini).
- **Cuisine preferences** — tailor results to the cuisines you like.
- **Discover feed** — browse recipe ideas by category.
- **Favorites** — save recipes to cook later.
- **Full auth** — sign in, OTP verification, forgot / change password.
- **Profile** — manage your account and preferences.
- **Recipe images** — dish images via an image service + Wikipedia lookups.

## Tech stack

| Area | Choices |
| --- | --- |
| Platform | Native iOS · SwiftUI |
| AI | Google Gemini (`generativelanguage` API) |
| Data | TheMealDB API, Firebase (Auth) |
| Structure | MVVM-style views + services (`RecipeService`, `MealDBService`, `GorselService`, `AuthManager`) |

## Running it

Open `FridgeChef.xcodeproj` in Xcode and run on a simulator or device.

> `Secrets.plist` (Gemini API key) and `GoogleService-Info.plist` are intentionally **not committed**.
> Add your own to build.

---

Built by [Timur Batyrkul](https://github.com/timurbatyrkul001).
