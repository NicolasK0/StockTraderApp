//
//  Portfolio.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/24/25.
//

import Foundation

// Add these enums at the top of Portfolio.swift, after the import statement


struct PortfolioPosition: Identifiable, Codable {
    var id = UUID()
    let symbol: String
    let companyName: String
    let shares: Double
    let purchasePrice: Double
    let purchaseDate: Date
    var currentPrice: Double
    
    // Computed properties for performance calculations
    var totalCost: Double {
        shares * purchasePrice
    }
    
    var currentValue: Double {
        shares * currentPrice
    }
    
    var totalGainLoss: Double {
        currentValue - totalCost
    }
    
    var percentGainLoss: Double {
        guard totalCost > 0 else { return 0 }
        return (totalGainLoss / totalCost) * 100
    }
    
    var isPositive: Bool {
        return totalGainLoss >= 0
    }
    
    // Formatted strings for display
    var formattedShares: String {
        return String(format: "%.2f", shares)
    }
    
    var formattedPurchasePrice: String {
        return String(format: "$%.2f", purchasePrice)
    }
    
    var formattedCurrentPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var formattedTotalCost: String {
        return String(format: "$%.2f", totalCost)
    }
    
    var formattedCurrentValue: String {
        return String(format: "$%.2f", currentValue)
    }
    
    var formattedGainLoss: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@$%.2f", sign, totalGainLoss)
    }
    
    var formattedPercentGainLoss: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentGainLoss)
    }
}

enum BuyResult {
    case success(shares: Int, totalCost: Double)
    case insufficientFunds(needed: Double, available: Double)
    case invalidQuantity
    case apiError(String)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    
    var message: String {
        switch self {
        case .success(let shares, let totalCost):
            return "Successfully bought \(shares) shares for \(String(format: "$%.2f", totalCost))"
        case .insufficientFunds(let needed, let available):
            let shortfall = needed - available
            return "Insufficient funds. You need \(String(format: "$%.2f", shortfall)) more."
        case .invalidQuantity:
            return "Invalid quantity. Please enter a positive number of shares."
        case .apiError(let error):
            return "Error: \(error)"
        }
    }
}

enum SellResult {
    case success(shares: Int, saleValue: Double, gainLoss: Double)
    case notOwned
    case insufficientShares(owned: Int, requested: Int)
    case invalidQuantity
    case apiError(String)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    
    var message: String {
        switch self {
        case .success(let shares, let saleValue, let gainLoss):
            let gainLossText = gainLoss >= 0 ? "gain of \(String(format: "$%.2f", gainLoss))" : "loss of \(String(format: "$%.2f", abs(gainLoss)))"
            return "Successfully sold \(shares) shares for \(String(format: "$%.2f", saleValue)) (\(gainLossText))"
        case .notOwned:
            return "You don't own any shares of this stock."
        case .insufficientShares(let owned, let requested):
            return "You only own \(owned) shares but tried to sell \(requested)."
        case .invalidQuantity:
            return "Invalid quantity. Please enter a positive number of shares."
        case .apiError(let error):
            return "Error: \(error)"
        }
    }
}

// MARK: - Stock Position Model
struct StockPosition: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let companyName: String
    var quantity: Int
    let averageCost: Double
    let purchaseDate: Date
    
    // Computed properties for position analysis
    var totalCost: Double {
        return Double(quantity) * averageCost
    }
    
    func currentValue(at currentPrice: Double) -> Double {
        return Double(quantity) * currentPrice
    }
    
    func gainLoss(at currentPrice: Double) -> Double {
        return currentValue(at: currentPrice) - totalCost
    }
    
    func gainLossPercentage(at currentPrice: Double) -> Double {
        guard totalCost > 0 else { return 0 }
        return (gainLoss(at: currentPrice) / totalCost) * 100
    }
}

// MARK: - Transaction Model
struct Transaction: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let companyName: String
    let type: TransactionType
    let quantity: Int
    let price: Double
    let date: Date
    
    enum TransactionType: String, Codable, CaseIterable {
        case buy = "Buy"
        case sell = "Sell"
    }
    
    var totalAmount: Double {
        return Double(quantity) * price
    }
}

// MARK: - Portfolio Model
struct VirtualPortfolio: Codable {
    var cashBalance: Double
    var positions: [StockPosition]
    var transactions: [Transaction]
    
    init(startingCash: Double = 10000.0) {
        self.cashBalance = startingCash
        self.positions = []
        self.transactions = []
    }
    
    // Portfolio summary calculations
    func totalPortfolioValue(stockPrices: [String: Double]) -> Double {
        let positionsValue = positions.reduce(0) { total, position in
            let currentPrice = stockPrices[position.symbol] ?? position.averageCost
            return total + position.currentValue(at: currentPrice)
        }
        return cashBalance + positionsValue
    }
    
    func totalGainLoss(stockPrices: [String: Double]) -> Double {
        return positions.reduce(0) { total, position in
            let currentPrice = stockPrices[position.symbol] ?? position.averageCost
            return total + position.gainLoss(at: currentPrice)
        }
    }
    
    // Check if user can afford a purchase
    func canAfford(quantity: Int, price: Double) -> Bool {
        let totalCost = Double(quantity) * price
        return cashBalance >= totalCost
    }
    
    // Get position for a specific stock
    func getPosition(for symbol: String) -> StockPosition? {
        return positions.first { $0.symbol == symbol }
    }
}

// Add this struct above the Portfolio struct in the same file
struct StockHolding: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let companyName: String
    var shares: Int
    let averageCost: Double // Average price paid per share
    var currentPrice: Double // Current market price per share
    let datePurchased: Date
    
    private enum CodingKeys: String, CodingKey {
            case symbol, companyName, shares, averageCost, currentPrice, datePurchased
            // Note: 'id' is intentionally omitted
    }
    
    init(symbol: String, companyName: String, shares: Int, purchasePrice: Double) {
        self.symbol = symbol.uppercased()
        self.companyName = companyName
        self.shares = shares
        self.averageCost = purchasePrice
        self.currentPrice = purchasePrice // Will be updated with market data
        self.datePurchased = Date()
    }
    
    // Computed properties for this holding
    var totalCost: Double {
        return averageCost * Double(shares)
    }
    
    var currentValue: Double {
        return currentPrice * Double(shares)
    }
    
    var gainLoss: Double {
        return currentValue - totalCost
    }
    
    var gainLossPercentage: Double {
        guard totalCost > 0 else { return 0.0 }
        return (gainLoss / totalCost) * 100
    }
    
    var isPositive: Bool {
        return gainLoss >= 0
    }
    
    // Formatted strings for display
    var formattedShares: String {
        return "\(shares) shares"
    }
    
    var formattedAverageCost: String {
        return String(format: "$%.2f", averageCost)
    }
    
    var formattedCurrentValue: String {
        return String(format: "$%.2f", currentValue)
    }
    
    var formattedGainLoss: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@$%.2f", sign, gainLoss)
    }
    
    var formattedGainLossPercentage: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@%.2f%%", sign, gainLossPercentage)
    }
}

struct Portfolio: Codable {
    var cashBalance: Double
    var holdings: [StockHolding]
    var totalInvested: Double
    var positions: [PortfolioPosition]
    
    init(startingCash: Double = 10000.0) {
        self.cashBalance = startingCash
        self.holdings = []
        self.totalInvested = 0.0
        self.positions = []
    }
    
    // Portfolio-wide calculations
    var totalCost: Double {
        positions.reduce(0) { $0 + $1.totalCost }
    }
    
    var totalCurrentValue: Double {
        positions.reduce(0) { $0 + $1.currentValue }
    }
    
    
    var percentGainLoss: Double {
        guard totalCost > 0 else { return 0 }
        return (totalGainLoss / totalCost) * 100
    }
    
    // Formatted portfolio totals
    var formattedTotalCost: String {
        return String(format: "$%.2f", totalCost)
    }
    
    var formattedCurrentValue: String {
        return String(format: "$%.2f", totalCurrentValue)
    }
        
    var formattedPercentGainLoss: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@$%.2f%%", sign, percentGainLoss)
    }
    // Computed properties for portfolio analysis
    var totalPortfolioValue: Double {
        let stockValue = holdings.reduce(0) { total, holding in
            total + (holding.currentPrice * Double(holding.shares))
        }
        return cashBalance + stockValue
    }
    
    var totalStockValue: Double {
        return holdings.reduce(0) { total, holding in
            total + (holding.currentPrice * Double(holding.shares))
        }
    }
    
    var totalGainLoss: Double {
        return totalStockValue - totalInvested
    }
    
    var totalGainLossPercentage: Double {
        guard totalInvested > 0 else { return 0.0 }
        return (totalGainLoss / totalInvested) * 100
    }
    
    var isPositive: Bool {
        return totalGainLoss >= 0
    }
    
    // Formatted strings for display
    var formattedCashBalance: String {
        return String(format: "$%.2f", cashBalance)
    }
    
    var formattedTotalValue: String {
        return String(format: "$%.2f", totalPortfolioValue)
    }
    
    var formattedGainLoss: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@$%.2f", sign, totalGainLoss)
    }
    
    var formattedGainLossPercentage: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@%.2f%%", sign, totalGainLossPercentage)
    }
    
    // Add these methods inside the Portfolio struct

    mutating func buyStock(stock: Stock, shares: Int) -> BuyResult {
        let totalCost = stock.currentPrice * Double(shares)
        
        // Check if user has enough cash
        guard totalCost <= cashBalance else {
            return .insufficientFunds(needed: totalCost, available: cashBalance)
        }
        
        // Check for minimum purchase amount
        guard shares > 0 else {
            return .invalidQuantity
        }
        
        // Check if user already owns this stock
        if let existingIndex = holdings.firstIndex(where: { $0.symbol == stock.symbol }) {
            // Update existing holding with average cost
            let existingHolding = holdings[existingIndex]
            let totalShares = existingHolding.shares + shares
            let totalInvestment = (existingHolding.averageCost * Double(existingHolding.shares)) + totalCost
            let newAverageCost = totalInvestment / Double(totalShares)
            
            holdings[existingIndex] = StockHolding(
                symbol: stock.symbol,
                companyName: stock.companyName,
                shares: totalShares,
                purchasePrice: newAverageCost
            )
            holdings[existingIndex].currentPrice = stock.currentPrice
        } else {
            // Create new holding
            let newHolding = StockHolding(
                symbol: stock.symbol,
                companyName: stock.companyName,
                shares: shares,
                purchasePrice: stock.currentPrice
            )
            holdings.append(newHolding)
        }
        
        // Update cash balance and total invested
        cashBalance -= totalCost
        totalInvested += totalCost
        
        return .success(shares: shares, totalCost: totalCost)
    }

    mutating func sellStock(symbol: String, shares: Int, currentPrice: Double) -> SellResult {
        guard let holdingIndex = holdings.firstIndex(where: { $0.symbol.uppercased() == symbol.uppercased() }) else {
            return .notOwned
        }
        
        let holding = holdings[holdingIndex]
        
        // Check if user has enough shares to sell
        guard shares <= holding.shares else {
            return .insufficientShares(owned: holding.shares, requested: shares)
        }
        
        guard shares > 0 else {
            return .invalidQuantity
        }
        
        let saleValue = Double(shares) * currentPrice
        let originalCost = Double(shares) * holding.averageCost
        
        // Update cash balance
        cashBalance += saleValue
        totalInvested -= originalCost
        
        // Update or remove holding
        if shares == holding.shares {
            // Selling all shares - remove holding
            holdings.remove(at: holdingIndex)
        } else {
            // Selling partial shares - update holding
            holdings[holdingIndex].shares -= shares
        }
        
        return .success(shares: shares, saleValue: saleValue, gainLoss: saleValue - originalCost)
    }

    mutating func updateHoldingPrices(stocks: [Stock]) {
        for stock in stocks {
            if let holdingIndex = holdings.firstIndex(where: { $0.symbol == stock.symbol }) {
                holdings[holdingIndex].currentPrice = stock.currentPrice
            }
        }
    }

    func getHolding(for symbol: String) -> StockHolding? {
        return holdings.first { $0.symbol.uppercased() == symbol.uppercased() }
    }

    func canAfford(stock: Stock, shares: Int) -> Bool {
        let totalCost = stock.currentPrice * Double(shares)
        return totalCost <= cashBalance
    }

    func sharesOwned(of symbol: String) -> Int {
        return holdings.first { $0.symbol.uppercased() == symbol.uppercased() }?.shares ?? 0
    }
    
    // Add these validation methods inside the Portfolio struct

    // MARK: - Validation Methods

    func isValid() -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        // Check cash balance
        if cashBalance < 0 {
            errors.append("Cash balance cannot be negative: \(formattedCashBalance)")
        }
        
        // Check total invested
        if totalInvested < 0 {
            errors.append("Total invested cannot be negative: \(String(format: "$%.2f", totalInvested))")
        }
        
        // Validate each holding
        for (index, holding) in holdings.enumerated() {
            if holding.shares <= 0 {
                errors.append("Holding \(index) (\(holding.symbol)) has invalid share count: \(holding.shares)")
            }
            
            if holding.averageCost <= 0 {
                errors.append("Holding \(index) (\(holding.symbol)) has invalid average cost: \(holding.formattedAverageCost)")
            }
            
            if holding.currentPrice < 0 {
                errors.append("Holding \(index) (\(holding.symbol)) has invalid current price: \(String(format: "$%.2f", holding.currentPrice))")
            }
            
            if holding.symbol.isEmpty {
                errors.append("Holding \(index) has empty symbol")
            }
        }
        
        // Check for duplicate holdings
        let symbols = holdings.map { $0.symbol.uppercased() }
        let uniqueSymbols = Set(symbols)
        if symbols.count != uniqueSymbols.count {
            errors.append("Portfolio contains duplicate holdings")
        }
        
        return (isValid: errors.isEmpty, errors: errors)
    }

    mutating func fixDataIntegrity() {
        // Remove invalid holdings
        holdings.removeAll { holding in
            holding.shares <= 0 || holding.averageCost <= 0 || holding.symbol.isEmpty
        }
        
        // Merge duplicate holdings
        var mergedHoldings: [StockHolding] = []
        let groupedHoldings = Dictionary(grouping: holdings) { $0.symbol.uppercased() }
        
        for (symbol, duplicates) in groupedHoldings {
            if duplicates.count == 1 {
                mergedHoldings.append(duplicates[0])
            } else {
                // Merge duplicates by calculating weighted average cost
                let totalShares = duplicates.reduce(0) { $0 + $1.shares }
                let totalInvestment = duplicates.reduce(0.0) { total, holding in
                    total + (Double(holding.shares) * holding.averageCost)
                }
                let averageCost = totalInvestment / Double(totalShares)
                let currentPrice = duplicates.first?.currentPrice ?? 0.0
                let companyName = duplicates.first?.companyName ?? symbol
                
                let mergedHolding = StockHolding(
                    symbol: symbol,
                    companyName: companyName,
                    shares: totalShares,
                    purchasePrice: averageCost
                )
                var merged = mergedHolding
                merged.currentPrice = currentPrice
                mergedHoldings.append(merged)
            }
        }
        
        holdings = mergedHoldings
        
        // Ensure cash balance is not negative
        if cashBalance < 0 {
            cashBalance = 0
        }
        
        // Recalculate total invested based on current holdings
        totalInvested = holdings.reduce(0) { total, holding in
            total + (holding.averageCost * Double(holding.shares))
        }
    }

    func calculateExpectedTotalInvested() -> Double {
        return holdings.reduce(0) { total, holding in
            total + (holding.averageCost * Double(holding.shares))
        }
    }
    
    // Add these custom Codable methods inside the Portfolio struct

    // MARK: - Custom Codable Implementation
    enum CodingKeys: String, CodingKey {
        case cashBalance
        case holdings
        case totalInvested
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        cashBalance = try container.decodeIfPresent(Double.self, forKey: .cashBalance) ?? 10000.0
        holdings = try container.decodeIfPresent([StockHolding].self, forKey: .holdings) ?? []
        totalInvested = try container.decodeIfPresent(Double.self, forKey: .totalInvested) ?? 0.0
        positions = []
        
        // Validate and fix data integrity after loading
        let validation = self.isValid()
        if !validation.isValid {
            print("Portfolio data integrity issues found: \(validation.errors)")
            var mutableSelf = self
            mutableSelf.fixDataIntegrity()
            self = mutableSelf
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cashBalance, forKey: .cashBalance)
        try container.encode(holdings, forKey: .holdings)
        try container.encode(totalInvested, forKey: .totalInvested)
    }
}

// Add this extension at the bottom of Portfolio.swift

// MARK: - Sample Data for Testing
// Sample data for testing portfolio features
extension Portfolio {
    static let samplePortfolio: Portfolio = {
        var portfolio = Portfolio()
        
        // Create sample positions with different performance scenarios
        let positions = [
            PortfolioPosition(
                symbol: "AAPL",
                companyName: "Apple Inc.",
                shares: 10.0,
                purchasePrice: 150.00,
                purchaseDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                currentPrice: 185.25
            ),
            PortfolioPosition(
                symbol: "MSFT",
                companyName: "Microsoft Corporation",
                shares: 5.0,
                purchasePrice: 400.00,
                purchaseDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                currentPrice: 378.90
            ),
            PortfolioPosition(
                symbol: "GOOGL",
                companyName: "Alphabet Inc.",
                shares: 8.0,
                purchasePrice: 120.00,
                purchaseDate: Calendar.current.date(byAdding: .month, value: -9, to: Date()) ?? Date(),
                currentPrice: 142.80
            ),
            PortfolioPosition(
                symbol: "TSLA",
                companyName: "Tesla, Inc.",
                shares: 12.0,
                purchasePrice: 280.00,
                purchaseDate: Calendar.current.date(byAdding: .month, value: -4, to: Date()) ?? Date(),
                currentPrice: 248.50
            ),
            PortfolioPosition(
                symbol: "NVDA",
                companyName: "NVIDIA Corporation",
                shares: 3.0,
                purchasePrice: 200.00,
                purchaseDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date(),
                currentPrice: 456.78
            )
        ]
        
        portfolio.positions = positions
        return portfolio
    }()
}

extension StockHolding {
    static var sampleHoldings: [StockHolding] {
        var apple = StockHolding(symbol: "AAPL", companyName: "Apple Inc.", shares: 15, purchasePrice: 145.0)
        apple.currentPrice = 175.50
        
        var google = StockHolding(symbol: "GOOGL", companyName: "Alphabet Inc.", shares: 3, purchasePrice: 2800.0)
        google.currentPrice = 2650.75
        
        var amazon = StockHolding(symbol: "AMZN", companyName: "Amazon.com Inc.", shares: 7, purchasePrice: 120.0)
        amazon.currentPrice = 135.25
        
        return [apple, google, amazon]
    }
}
