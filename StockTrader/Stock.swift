//
//  Stock.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import Foundation

struct Stock: Identifiable, Codable {
    let symbol: String
    let companyName: String
    let currentPrice: Double
    let priceChange: Double
    let percentChange: Double
    
    
    // Custom initializer for API data
    init(symbol: String, companyName: String, currentPrice: Double, priceChange: Double, percentChange: Double) {
        self.symbol = symbol
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.percentChange = percentChange
    }
    
    // Initializer from API strings with safe conversion
    init(symbol: String, companyName: String, priceString: String, changeString: String, percentString: String) {
        self.symbol = symbol
        self.companyName = companyName
        self.currentPrice = Double(priceString) ?? 0.0
        self.priceChange = Double(changeString) ?? 0.0
        
        // Remove % symbol and convert to double
        let cleanPercent = percentString.replacingOccurrences(of: "%", with: "")
        self.percentChange = Double(cleanPercent) ?? 0.0
    }
    
    var id: String {
        return symbol
    }
    
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
    
    // Add this to your existing Stock struct (after the existing properties)
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case symbol
        case companyName
        case currentPrice
        case priceChange
        case percentChange
    }
    
    // Custom decoder to handle edge cases
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        symbol = try container.decode(String.self, forKey: .symbol)
        companyName = try container.decode(String.self, forKey: .companyName)
        currentPrice = try container.decodeIfPresent(Double.self, forKey: .currentPrice) ?? 0.0
        priceChange = try container.decodeIfPresent(Double.self, forKey: .priceChange) ?? 0.0
        percentChange = try container.decodeIfPresent(Double.self, forKey: .percentChange) ?? 0.0
    }
    
    // Custom encoder for reliable storage
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(symbol, forKey: .symbol)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(currentPrice, forKey: .currentPrice)
        try container.encode(priceChange, forKey: .priceChange)
        try container.encode(percentChange, forKey: .percentChange)
    }
    
    // MARK: - Equality for watchlist management
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        return lhs.symbol == rhs.symbol
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(symbol)
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
