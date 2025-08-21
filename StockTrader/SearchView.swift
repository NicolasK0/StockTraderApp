//
//  SearchView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Stock Search")
                    .font(.largeTitle)
                    .padding()
                
                List(Stock.sampleStocks) { stock in
                        StockRowView(stock: stock)
                }
                
            }
            .navigationTitle("Search")
        }
    }
}

#Preview {
    SearchView()
}
