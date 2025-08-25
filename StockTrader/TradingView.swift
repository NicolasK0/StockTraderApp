//
//  TradingView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/24/25.
//

import SwiftUI

struct TradingView: View {
    let stock: Stock
    @StateObject private var portfolioStorage = PortfolioStorage.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity = 1
    @State private var showingBuyConfirmation = false
    @State private var showingSellConfirmation = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    private var position: StockPosition? {
        portfolioStorage.portfolio.getPosition(for: stock.symbol)
    }
    
    private var maxSellQuantity: Int {
        position?.quantity ?? 0
    }
    
    private var totalBuyCost: Double {
        Double(quantity) * stock.currentPrice
    }
    
    private var totalSellProceeds: Double {
        Double(quantity) * stock.currentPrice
    }
    
    private var canAffordPurchase: Bool {
        portfolioStorage.portfolio.canAfford(quantity: quantity, price: stock.currentPrice)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Stock Information
                VStack(spacing: 12) {
                    Text(stock.symbol)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(stock.companyName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(stock.formattedPrice)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text(stock.formattedChange)
                        Text(stock.formattedPercentChange)
                    }
                    .font(.subheadline)
                    .foregroundColor(stock.isPositive ? .green : .red)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Portfolio Information
                VStack(spacing: 8) {
                    HStack {
                        Text("Cash Balance:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", portfolioStorage.portfolio.cashBalance))
                            .fontWeight(.semibold)
                    }
                    
                    if let position = position {
                        HStack {
                            Text("Current Position:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(position.quantity) shares")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Average Cost:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "$%.2f", position.averageCost))
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Quantity Selection
                VStack(spacing: 12) {
                    Text("Quantity")
                        .font(.headline)
                    
                    HStack {
                        Button("-") {
                            if quantity > 1 {
                                quantity -= 1
                            }
                        }
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .disabled(quantity <= 1)
                        
                        Text("\(quantity)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(minWidth: 60)
                        
                        Button("+") {
                            quantity += 1
                        }
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    // Quick quantity buttons
                    HStack(spacing: 12) {
                        ForEach([10, 50, 100], id: \.self) { amount in
                            Button("\(amount)") {
                                quantity = amount
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Trading Actions
                VStack(spacing: 16) {
                    // Buy Section
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total Cost:")
                            Spacer()
                            Text(String(format: "$%.2f", totalBuyCost))
                                .fontWeight(.bold)
                        }
                        
                        Button("Buy \(quantity) Share\(quantity == 1 ? "" : "s")") {
                            showingBuyConfirmation = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAffordPurchase ? Color.green : Color.gray)
                        .cornerRadius(10)
                        .disabled(!canAffordPurchase)
                    }
                    
                    // Sell Section
                    if maxSellQuantity > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Total Proceeds:")
                                Spacer()
                                Text(String(format: "$%.2f", totalSellProceeds))
                                    .fontWeight(.bold)
                            }
                            
                            Button("Sell \(min(quantity, maxSellQuantity)) Share\(min(quantity, maxSellQuantity) == 1 ? "" : "s")") {
                                quantity = min(quantity, maxSellQuantity)
                                showingSellConfirmation = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .disabled(maxSellQuantity == 0)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Trade \(stock.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {
                    // Only dismiss after successful buy/sell
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog("Confirm Purchase", isPresented: $showingBuyConfirmation) {
                Button("Buy \(quantity) Share\(quantity == 1 ? "" : "s") for \(String(format: "$%.2f", totalBuyCost))", role: .none) {
                    performBuy()
                }
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog("Confirm Sale", isPresented: $showingSellConfirmation) {
                Button("Sell \(min(quantity, maxSellQuantity)) Share\(min(quantity, maxSellQuantity) == 1 ? "" : "s") for \(String(format: "$%.2f", totalSellProceeds))", role: .none) {
                    performSell()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private func performBuy() {
        let success = portfolioStorage.buyStock(stock, quantity: quantity)
        
        if success {
            alertTitle = "Success"
            alertMessage = "Successfully bought \(quantity) share\(quantity == 1 ? "" : "s") of \(stock.symbol)!"
        } else {
            alertTitle = "Error"
            alertMessage = "Purchase failed. Insufficient funds."
        }
        
        showingAlert = true
    }
    
    private func performSell() {
        let actualQuantity = min(quantity, maxSellQuantity)
        let success = portfolioStorage.sellStock(stock, quantity: actualQuantity)
        
        if success {
            alertTitle = "Success"
            alertMessage = "Successfully sold \(actualQuantity) share\(actualQuantity == 1 ? "" : "s") of \(stock.symbol)!"
        } else {
            alertTitle = "Error"
            alertMessage = "Sale failed. Insufficient shares."
        }
        
        showingAlert = true
    }
}