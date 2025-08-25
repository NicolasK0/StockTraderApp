//
//  ContentView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/19/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            WatchlistView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Watchlist")
                }
            
            PortfolioView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Portfolio")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

