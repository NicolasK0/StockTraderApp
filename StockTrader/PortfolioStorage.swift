//
//  PortfolioStorage.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/24/25.
//

import Foundation

class PortfolioStorage: ObservableObject {
    @Published var portfolio = VirtualPortfolio()
    private let userDefaults = UserDefaults.standard
    private let portfolioKey = "VirtualPortfolio"
    private let versionKey = "PortfolioVersion"
    private let currentVersion = 1
    static let shared = PortfolioStorage()
    
    init() {
        loadPortfolio()
    }
    
    // MARK: - Core Storage Methods
    
    private func loadPortfolio() {
        guard let data = userDefaults.data(forKey: portfolioKey) else {
            print("No saved portfolio found, creating new one")
            portfolio = VirtualPortfolio()
            savePortfolio()
            return
        }
        
        do {
            portfolio = try JSONDecoder().decode(VirtualPortfolio.self, from: data)
            print("Loaded portfolio with $\(String(format: "%.2f", portfolio.cashBalance)) cash and \(portfolio.positions.count) positions")
        } catch {
            print("Failed to load portfolio: \(error.localizedDescription)")
            portfolio = VirtualPortfolio()
            savePortfolio()
        }
    }
    
    private func savePortfolio() {
        do {
            let data = try JSONEncoder().encode(portfolio)
            userDefaults.set(data, forKey: portfolioKey)
            userDefaults.set(currentVersion, forKey: versionKey)
            print("Saved portfolio with $\(String(format: "%.2f", portfolio.cashBalance)) cash")
        } catch {
            print("Failed to save portfolio: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Trading Operations
    
    func buyStock(_ stock: Stock, quantity: Int) -> Bool {
        let totalCost = Double(quantity) * stock.currentPrice
        
        guard portfolio.canAfford(quantity: quantity, price: stock.currentPrice) else {
            print("Insufficient funds for purchase")
            return false
        }
        
        // Deduct cash
        portfolio.cashBalance -= totalCost
        
        // Add or update position
        if let existingIndex = portfolio.positions.firstIndex(where: { $0.symbol == stock.symbol }) {
            // Update existing position with weighted average cost
            let existing = portfolio.positions[existingIndex]
            let newTotalShares = existing.quantity + quantity
            let newTotalCost = existing.totalCost + totalCost
            let newAverageCost = newTotalCost / Double(newTotalShares)
            
            portfolio.positions[existingIndex] = StockPosition(
                id: existing.id, // Keep the existing ID
                symbol: stock.symbol,
                companyName: stock.companyName,
                quantity: newTotalShares,
                averageCost: newAverageCost,
                purchaseDate: existing.purchaseDate
            )
        } else {
            // Create new position
            let newPosition = StockPosition(
                id: UUID(), // Generate new ID
                symbol: stock.symbol,
                companyName: stock.companyName,
                quantity: quantity,
                averageCost: stock.currentPrice,
                purchaseDate: Date()
            )
            portfolio.positions.append(newPosition)
        }
        
        // Add transaction record
        let transaction = Transaction(
            id: UUID(), // Generate new ID
            symbol: stock.symbol,
            companyName: stock.companyName,
            type: .buy,
            quantity: quantity,
            price: stock.currentPrice,
            date: Date()
        )
        portfolio.transactions.append(transaction)
        
        savePortfolio()
        print("Bought \(quantity) shares of \(stock.symbol) at $\(String(format: "%.2f", stock.currentPrice))")
        return true
    }
    
    func sellStock(_ stock: Stock, quantity: Int) -> Bool {
        guard let positionIndex = portfolio.positions.firstIndex(where: { $0.symbol == stock.symbol }) else {
            print("No position found for \(stock.symbol)")
            return false
        }
        
        let position = portfolio.positions[positionIndex]
        guard position.quantity >= quantity else {
            print("Insufficient shares to sell")
            return false
        }
        
        let totalProceeds = Double(quantity) * stock.currentPrice
        
        // Add cash from sale
        portfolio.cashBalance += totalProceeds
        
        // Update or remove position
        if position.quantity == quantity {
            // Sell entire position
            portfolio.positions.remove(at: positionIndex)
        } else {
            // Partial sale
            portfolio.positions[positionIndex] = StockPosition(
                id: position.id, // Keep the existing ID
                symbol: position.symbol,
                companyName: position.companyName,
                quantity: position.quantity - quantity,
                averageCost: position.averageCost,
                purchaseDate: position.purchaseDate
            )
        }
        
        // Add transaction record
        let transaction = Transaction(
            id: UUID(), // Generate new ID
            symbol: stock.symbol,
            companyName: stock.companyName,
            type: .sell,
            quantity: quantity,
            price: stock.currentPrice,
            date: Date()
        )
        portfolio.transactions.append(transaction) // Fixed: Added newline
        
        savePortfolio()
        print("Sold \(quantity) shares of \(stock.symbol) at $\(String(format: "%.2f", stock.currentPrice))")
        return true
    }
    
    // MARK: - Helper Methods
    
    func resetPortfolio(startingCash: Double = 10000.0) {
        portfolio = VirtualPortfolio(startingCash: startingCash)
        savePortfolio()
        print("Portfolio reset with $\(String(format: "%.2f", startingCash))")
    }
    
    func getRecentTransactions(limit: Int = 10) -> [Transaction] {
        return Array(portfolio.transactions.sorted { $0.date > $1.date }.prefix(limit))
    }
}
