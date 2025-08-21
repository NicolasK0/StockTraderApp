//
//  APIModels.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/21/25.
//

import Foundation

// MARK: - Alpha Vantage API Response Models

struct AlphaVantageQuoteResponse: Codable {
    let globalQuote: GlobalQuote
    
    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
    }
}

struct GlobalQuote: Codable {
    let symbol: String
    let open: String
    let high: String
    let low: String
    let price: String
    let volume: String
    let latestTradingDay: String
    let previousClose: String
    let change: String
    let changePercent: String
    
    enum CodingKeys: String, CodingKey {
        case symbol = "01. symbol"
        case open = "02. open"
        case high = "03. high"
        case low = "04. low"
        case price = "05. price"
        case volume = "06. volume"
        case latestTradingDay = "07. latest trading day"
        case previousClose = "08. previous close"
        case change = "09. change"
        case changePercent = "10. change percent"
    }
}

// MARK: - Search Results Models

struct AlphaVantageSearchResponse: Codable {
    let bestMatches: [SearchMatch]
    
    enum CodingKeys: String, CodingKey {
        case bestMatches = "bestMatches"
    }
}

struct SearchMatch: Codable {
    let symbol: String
    let name: String
    let type: String
    let region: String
    let marketOpen: String
    let marketCLose: String
    let timezone: String
    let currency: String
    let matchScore: String
    
    enum CodingKeys: String, CodingKey {
        case Symbol = "1. symbol"
        case name = "2. name"
        case type = "3. type"
        case region = "4. region"
        case marketOpen = "5. marketOpen"
        case marketClose = "6. marketClose"
        case timezone = "7. timezone"
        case currency = "8. currency"
        case matchScore = "9. matchScore"
    }
}
