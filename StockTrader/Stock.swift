//
//  Stock.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import Foundation

struct Stock: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let companyName: String
    let currentPrice: Double
    let priceChange: Double
    let percentChange: Double
    
    // Computed property to determine if stock is up or down
    var isPositive: Bool {
        return priceChange >= 0
    }
    
    // Formatted price string
    var formattedPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    // Formatted change string with + or - sign
    var formattedChange: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@$%.2f", sign, priceChange)
    }
    
    // Formatted percentage change
    var formattedPercentChange: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentChange)
    }
}

// Sample data for testing
extension Stock {
    static let sampleStocks = [
        Stock(symbol: "AAPL", companyName: "Apple Inc.", currentPrice: 185.25, priceChange: 2.50, percentChange: 1.37),
        Stock(symbol: "GOOGL", companyName: "Alphabet Inc.", currentPrice: 142.80, priceChange: -1.25, percentChange: -0.87),
        Stock(symbol: "MSFT", companyName: "Microsoft Corporation", currentPrice: 378.90, priceChange: 5.60, percentChange: 1.50),
        Stock(symbol: "TSLA", companyName: "Tesla, Inc.", currentPrice: 248.50, priceChange: -12.30, percentChange: -4.72),
        Stock(symbol: "AMZN", companyName: "Amazon.com Inc.", currentPrice: 155.75, priceChange: 0.85, percentChange: 0.55)
    ]
}
