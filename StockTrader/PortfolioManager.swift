//
//  PortfolioManager.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/24/25.
//

import Foundation
import Combine

class PortfolioManager: ObservableObject {
    @Published var portfolio: Portfolio
    
    private let userDefaults = UserDefaults.standard
    private let portfolioKey = "UserPortfolio"
    private let versionKey = "PortfolioVersion"
    private let currentVersion = 1
    
    init() {
        // Initialize with default portfolio
        self.portfolio = Portfolio()
        
        // Load saved data or create new portfolio
        loadPortfolio()
    }
    
    // MARK: - Core Persistence Methods
    
    func loadPortfolio() {
        guard let data = userDefaults.data(forKey: portfolioKey) else {
            print("No saved portfolio found, creating new portfolio with $10,000")
            portfolio = Portfolio(startingCash: 10000.0)
            savePortfolio()
            return
        }
        
        do {
            let savedPortfolio = try JSONDecoder().decode(Portfolio.self, from: data)
            portfolio = savedPortfolio
            print("Loaded portfolio with \(portfolio.formattedCashBalance) cash and \(portfolio.holdings.count) holdings")
        } catch {
            print("Failed to load portfolio: \(error.localizedDescription)")
            print("Creating new portfolio")
            portfolio = Portfolio(startingCash: 10000.0)
            savePortfolio()
        }
    }
    
    func savePortfolio() {
        do {
            let data = try JSONEncoder().encode(portfolio)
            userDefaults.set(data, forKey: portfolioKey)
            print("Saved portfolio with \(portfolio.formattedTotalValue) total value")
        } catch {
            print("Failed to save portfolio: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Trading Operations
    
    func buyStock(stock: Stock, shares: Int) -> BuyResult {
        let result = portfolio.buyStock(stock: stock, shares: shares)
        
        if result.isSuccess {
            savePortfolio()
        }
        
        return result
    }
    
    func sellStock(symbol: String, shares: Int, currentPrice: Double) -> SellResult {
        let result = portfolio.sellStock(symbol: symbol, shares: shares, currentPrice: currentPrice)
        
        if result.isSuccess {
            savePortfolio()
        }
        
        return result
    }
    
    func updatePortfolioPrices(with stocks: [Stock]) {
        portfolio.updateHoldingPrices(stocks: stocks)
        savePortfolio()
    }
    
    // MARK: - Portfolio Query Methods
    
    func getHolding(for symbol: String) -> StockHolding? {
        return portfolio.getHolding(for: symbol)
    }
    
    func canAfford(stock: Stock, shares: Int) -> Bool {
        return portfolio.canAfford(stock: stock, shares: shares)
    }
    
    func sharesOwned(of symbol: String) -> Int {
        return portfolio.sharesOwned(of: symbol)
    }
    
    // MARK: - Portfolio Reset and Management
    
    func resetPortfolio(startingCash: Double = 10000.0) {
        portfolio = Portfolio(startingCash: startingCash)
        savePortfolio()
        print("Portfolio reset with \(portfolio.formattedCashBalance)")
    }
    
    func addCash(amount: Double) {
        guard amount > 0 else { return }
        portfolio.cashBalance += amount
        savePortfolio()
        print("Added \(String(format: "$%.2f", amount)) to portfolio")
    }
}
