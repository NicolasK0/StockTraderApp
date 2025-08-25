//
//  PortfolioTester.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/24/25.
//

import Foundation

// Test utility for validating portfolio functionality
class PortfolioTester {
    
    static func runAllTests() {
        print("🧪 Starting Portfolio Tests...\n")
        
        testBasicPortfolioCreation()
        testBuyingStocks()
        testSellingStocks()
        testPortfolioCalculations()
        testDataPersistence()
        testEdgeCases()
        
        print("✅ All Portfolio Tests Completed!\n")
    }
    
    static func testBasicPortfolioCreation() {
        print("📝 Testing Portfolio Creation...")
        
        let portfolio = Portfolio(startingCash: 10000.0)
        assert(portfolio.cashBalance == 10000.0, "Initial cash balance should be $10,000")
        assert(portfolio.holdings.isEmpty, "New portfolio should have no holdings")
        assert(portfolio.totalInvested == 0.0, "New portfolio should have no invested amount")
        
        print("✅ Portfolio creation test passed\n")
    }
    
    static func testBuyingStocks() {
        print("📝 Testing Stock Purchases...")
        
        var portfolio = Portfolio(startingCash: 10000.0)
        let appleStock = Stock(symbol: "AAPL", companyName: "Apple Inc.", currentPrice: 150.0, priceChange: 2.5, percentChange: 1.69)
        
        // Test successful purchase
        let buyResult = portfolio.buyStock(stock: appleStock, shares: 10)
        assert(buyResult.isSuccess, "Should successfully buy 10 shares")
        assert(portfolio.cashBalance == 8500.0, "Cash balance should be $8,500 after purchase")
        assert(portfolio.holdings.count == 1, "Should have 1 holding")
        assert(portfolio.sharesOwned(of: "AAPL") == 10, "Should own 10 AAPL shares")
        
        // Test insufficient funds
        let bigPurchase = portfolio.buyStock(stock: appleStock, shares: 100)
        assert(!bigPurchase.isSuccess, "Should fail with insufficient funds")
        
        print("✅ Stock purchase tests passed\n")
    }
    
    static func testSellingStocks() {
        print("📝 Testing Stock Sales...")
        
        var portfolio = Portfolio.samplePortfolio
        
        // Test successful sale
        let sellResult = portfolio.sellStock(symbol: "AAPL", shares: 5, currentPrice: 180.0)
        assert(sellResult.isSuccess, "Should successfully sell 5 AAPL shares")
        
        // Test selling stock not owned
        let invalidSale = portfolio.sellStock(symbol: "NVDA", shares: 1, currentPrice: 500.0)
        assert(!invalidSale.isSuccess, "Should fail when selling unowned stock")
        
        print("✅ Stock sale tests passed\n")
    }
    
    static func testPortfolioCalculations() {
        print("📝 Testing Portfolio Calculations...")
        
        let portfolio = Portfolio.samplePortfolio
        
        assert(portfolio.totalStockValue > 0, "Should have positive stock value")
        assert(portfolio.totalPortfolioValue > 0, "Should have positive total portfolio value")
        
        print("Portfolio Stats:")
        print("- Cash: \(portfolio.formattedCashBalance)")
        print("- Stock Value: \(String(format: "$%.2f", portfolio.totalStockValue))")
        print("- Total Value: \(portfolio.formattedTotalValue)")
        print("- Gain/Loss: \(portfolio.formattedGainLoss) (\(portfolio.formattedGainLossPercentage))")
        
        print("✅ Portfolio calculation tests passed\n")
    }
    
    static func testDataPersistence() {
        print("📝 Testing Data Persistence...")
        
        let originalPortfolio = Portfolio.samplePortfolio
        
        // Test encoding
        do {
            let encodedData = try JSONEncoder().encode(originalPortfolio)
            
            // Test decoding
            let decodedPortfolio = try JSONDecoder().decode(Portfolio.self, from: encodedData)
            
            assert(decodedPortfolio.cashBalance == originalPortfolio.cashBalance, "Cash balance should match")
            assert(decodedPortfolio.holdings.count == originalPortfolio.holdings.count, "Holdings count should match")
            assert(decodedPortfolio.totalInvested == originalPortfolio.totalInvested, "Total invested should match")
            
            print("✅ Data persistence tests passed\n")
        } catch {
            print("❌ Data persistence test failed: \(error)\n")
        }
    }
    
    static func testEdgeCases() {
        print("📝 Testing Edge Cases...")
        
        var portfolio = Portfolio(startingCash: 100.0)
        let expensiveStock = Stock(symbol: "BRK.A", companyName: "Berkshire Hathaway", currentPrice: 500000.0, priceChange: 1000.0, percentChange: 0.2)
        
        // Test buying expensive stock with insufficient funds
        let result = portfolio.buyStock(stock: expensiveStock, shares: 1)
        assert(!result.isSuccess, "Should fail to buy expensive stock")
        
        // Test invalid quantities
        let zeroShares = portfolio.buyStock(stock: expensiveStock, shares: 0)
        assert(!zeroShares.isSuccess, "Should fail with zero shares")
        
        let negativeShares = portfolio.buyStock(stock: expensiveStock, shares: -5)
        assert(!negativeShares.isSuccess, "Should fail with negative shares")
        
        print("✅ Edge case tests passed\n")
    }
}
