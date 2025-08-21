//
//  StockRowView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import SwiftUI

struct StockRowView: View {
    let stock: Stock
    
    var body: some View {
        HStack {
            // Left side - Stock symbol and company name
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(stock.companyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right side - Price and changes
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Text(stock.formattedChange)
                        .font(.caption)
                        .foregroundColor(stock.isPositive ? .green : .red)
                    
                    Text(stock.formattedPercentChange)
                        .font(.caption)
                        .foregroundColor(stock.isPositive ? .green : .red)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    StockRowView(stock: Stock.sampleStocks[0])
        .padding()
}
