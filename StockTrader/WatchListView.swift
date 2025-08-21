//
//  WatchListView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import SwiftUI

struct WatchlistView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("My Watchlist")
                    .font(.largeTitle)
                    .padding()
                
                // Display saved stocks using StockRowView
                List(Stock.sampleStocks.prefix(3)) { stock in
                    StockRowView(stock: stock)
                }
            }
            .navigationTitle("Watchlist")
        }
    }
}

#Preview {
    WatchlistView()
}
