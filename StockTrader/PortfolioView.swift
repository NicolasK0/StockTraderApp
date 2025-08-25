//
//  PortfolioView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/24/25.
//

import SwiftUI

struct PortfolioView: View {
    @StateObject private var portfolioStorage = PortfolioStorage.shared
    @StateObject private var apiService = StockAPIService()
    @State private var currentStockPrices: [String: Double] = [:]
    @State private var isRefreshing = false
    @State private var showingResetAlert = false
    
    private var totalPortfolioValue: Double {
        portfolioStorage.portfolio.totalPortfolioValue(stockPrices: currentStockPrices)
    }
    
    private var totalGainLoss: Double {
        portfolioStorage.portfolio.totalGainLoss(stockPrices: currentStockPrices)
    }
    
    private var gainLossPercentage: Double {
        let initialInvestment = totalPortfolioValue - totalGainLoss
        guard initialInvestment > 0 else { return 0 }
        return (totalGainLoss / initialInvestment) * 100
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio Summary
                    VStack(spacing: 16) {
                        Text("Portfolio Value")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "$%.2f", totalPortfolioValue))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text(String(format: "$%.2f", totalGainLoss))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(totalGainLoss >= 0 ? .green : .red)
                                Text("Total Gain/Loss")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(String(format: "%.2f%%", gainLossPercentage))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(totalGainLoss >= 0 ? .green : .red)
                                Text("Percentage")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Cash Balance
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Cash Balance")
                                .font(.headline)
                            Text(String(format: "$%.2f", portfolioStorage.portfolio.cashBalance))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Current Positions
                    if !portfolioStorage.portfolio.positions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Positions (\(portfolioStorage.portfolio.positions.count))")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Refresh") {
                                    refreshPrices()
                                }
                                .font(.caption)
                                .disabled(isRefreshing)
                            }
                            
                            ForEach(portfolioStorage.portfolio.positions) { position in
                                PositionRowView(
                                    position: position,
                                    currentPrice: currentStockPrices[position.symbol] ?? position.averageCost
                                )
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Recent Transactions
                    if !portfolioStorage.portfolio.transactions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Transactions")
                                .font(.headline)
                            
                            ForEach(portfolioStorage.getRecentTransactions(limit: 5)) { transaction in
                                TransactionRowView(transaction: transaction)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Empty State
                    if portfolioStorage.portfolio.positions.isEmpty && portfolioStorage.portfolio.transactions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Start Trading")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Search for stocks and start building your portfolio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                .padding()
            }
            .navigationTitle("Portfolio")
            .onAppear {
                loadCurrentPrices()
            }
            .refreshable {
                await refreshPortfolio()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Refresh Prices") {
                            refreshPrices()
                        }
                        
                        Button("Reset Portfolio", role: .destructive) {
                            showingResetAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Reset Portfolio", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    portfolioStorage.resetPortfolio()
                    currentStockPrices = [:]
                }
            } message: {
                Text("This will reset your portfolio to $10,000 and remove all positions and transactions. This cannot be undone.")
            }
        }
    }
    
    private func loadCurrentPrices() {
        let symbols = portfolioStorage.portfolio.positions.map { $0.symbol }
        guard !symbols.isEmpty else { return }
        
        Task {
            var prices: [String: Double] = [:]
            
            for symbol in symbols {
                do {
                    let stock = try await apiService.getStockQuote(symbol: symbol)
                    prices[symbol] = stock.currentPrice
                } catch {
                    print("Failed to get price for \(symbol): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.currentStockPrices = prices
            }
        }
    }
    
    private func refreshPrices() {
        isRefreshing = true
        Task {
            await refreshPortfolio()
            DispatchQueue.main.async {
                self.isRefreshing = false
            }
        }
    }
    
    private func refreshPortfolio() async {
        loadCurrentPrices()
    }
}

// Add these supporting views at the bottom of PortfolioView.swift

struct PositionRowView: View {
    let position: StockPosition
    let currentPrice: Double
    
    private var currentValue: Double {
        position.currentValue(at: currentPrice)
    }
    
    private var gainLoss: Double {
        position.gainLoss(at: currentPrice)
    }
    
    private var gainLossPercentage: Double {
        position.gainLossPercentage(at: currentPrice)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(position.companyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(position.quantity) shares @ \(String(format: "$%.2f", position.averageCost))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", currentValue))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Text(String(format: "$%.2f", gainLoss))
                        .font(.caption)
                        .foregroundColor(gainLoss >= 0 ? .green : .red)
                    
                    Text(String(format: "(%.2f%%)", gainLossPercentage))
                        .font(.caption)
                        .foregroundColor(gainLoss >= 0 ? .green : .red)
                }
                
                Text(String(format: "$%.2f", currentPrice))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(transaction.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(transaction.type == .buy ? Color.green : Color.red)
                        .cornerRadius(4)
                }
                
                Text("\(transaction.quantity) shares @ \(String(format: "$%.2f", transaction.price))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(dateFormatter.string(from: transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", transaction.totalAmount))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == .buy ? .red : .green)
            }
        }
        .padding(.vertical, 4)
    }
}
