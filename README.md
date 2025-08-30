# 📈 StockTrader  
A SwiftUI iOS app that lets users search stocks, build a watchlist, simulate trades, and track a virtual portfolio.  
**Built solo using SwiftUI.**

---

## 📱 Screens & Demo

<p align="center">
  <img src="screenshots/search.png" width="30%" />
  <img src="screenshots/watchlist.png" width="30%" />
  <img src="screenshots/portfolio.png" width="30%" />
</p>

**Walkthrough:**  
1. Open the app  
2. Search for a stock (e.g., AAPL)  
3. Add to your watchlist or trade shares  
4. Track performance in your portfolio  

---

## 🚀 Features
- Search stocks by symbol or company name (powered by Alpha Vantage API)  
- Add/remove stocks from a persistent watchlist  
- Refresh real-time stock quotes with async API calls  
- Simulate buying/selling shares with a $10,000 virtual balance  
- View portfolio summary, positions, and recent transactions  
- Undo deletion and receive success/error toasts  
- Polished UI with loading states, skeletons, and haptic feedback  

---

## 🛠 Skills Demonstrated
- Implemented a complete SwiftUI app architecture with `ObservableObject` state management  
- Integrated async/await networking with JSON decoding from Alpha Vantage API  
- Built reusable SwiftUI components (rows, toasts, loaders, empty states) with Previews for iteration  
- Persisted user data using `UserDefaults` + Codable for watchlist and portfolio storage  
- Designed undo functionality with timers for improved UX  
- Added animations, haptics, and skeleton loading views for polished UI/UX  
- Modeled domain entities (`Stock`, `Portfolio`, `Transaction`) with Codable structs  
- Implemented test utilities to validate portfolio calculations and edge cases  

---

## 📚 Tech Stack
- **Swift**: 5.9  
- **Frameworks**: SwiftUI, Combine, Foundation  
- **Xcode**: 15+  
- **iOS Target**: iOS 16+  
- **Packages**:  
  - None required — all functionality built-in with Swift/SwiftUI  

---

## ⚡ Setup (Run in 2 Minutes)
1. Clone the repo:  
   ```bash
   git clone https://github.com/yourusername/StockTrader.git
   cd StockTrader
   ```
2. Open in Xcode:
open StockTrader.xcodeproj
Run on simulator or a device with iOS 16+
3. Add your Alpha Vantage
 API key to Config.plist under ALPHA_VANTAGE_API_KEY.

## 🔮 Future Improvements
- Add push notifications for major price changes or portfolio updates  
- Expand persistence to iCloud/CloudKit for multi-device sync  
- Add home screen widgets for watchlist and portfolio snapshots  
- Integrate charts for stock price history and technical indicators  

---

## 🙏 Credits & Inspiration
- Built using [CodeDreams](https://codedreams.app/)  
- Stock data: [Alpha Vantage API](https://www.alphavantage.co/)  
- Icons: SF Symbols (Apple)  

---

## 📄 License & Contact
- License: MIT  
- Author: Nicolas Kousoulas  
- Contact: [LinkedIn]https://www.linkedin.com/in/nicolas-kousoulas/ | nkous05@gmail.com
