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
            // Search tab content will go here
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            // Watchlist tab content will go here
            WatchlistView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Watchlist")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

