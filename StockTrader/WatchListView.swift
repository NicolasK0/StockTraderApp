//
//  WatchListView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import SwiftUI

struct WatchlistView: View {
    @State private var recentlyDeletedStocks: [Stock] = []
    @State private var showUndoOption = false
    @State private var undoTimer: Timer?
    @StateObject private var toastManager = ToastManager()
    @State private var showingDeleteConfirmation = false
    @State private var stockToDelete: Stock?
    @State private var showingBulkDeleteConfirmation = false
    @State private var isEditMode = false
    @State private var selectedStocks: Set<Stock.ID> = []
    @StateObject private var apiService = StockAPIService()
    @ObservedObject private var watchlistStorage = WatchlistStorage.shared
    @State private var isLoadingWatchlist = false
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var updatingStocks: Set<String> = [] // Track which stocks are being updated
    
    private var hasSelectedStocks: Bool {
        return !selectedStocks.isEmpty
    }
    
    private var selectedStockCount: Int {
        return selectedStocks.count
    }
    
    private var watchlistStats: (count: Int, totalValue: Double, gainers: Int, losers: Int) {
        let stocks = watchlistStorage.watchlistStocks
        let count: Int = stocks.count
        let totalValue: Double = stocks.reduce(0.0) { (accumulator: Double, stock: Stock) in
            return accumulator + stock.currentPrice
        }
        let gainers: Int = stocks.filter { (stock: Stock) in stock.isPositive }.count
        let losers: Int = stocks.filter { (stock: Stock) in !stock.isPositive }.count
        
        return (count: count, totalValue: totalValue, gainers: gainers, losers: losers)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("My Watchlist")
                    .font(.largeTitle)
                    .padding()
                
                // Refresh Button
                HStack {
                    Spacer()
                    Button(isRefreshing ? "Refreshing..." : "Refresh") {
                        refreshWatchlist()
                    }
                    .disabled(isRefreshing || watchlistStorage.watchlistStocks.isEmpty)
                    .font(.caption)
                    .foregroundColor(isRefreshing ? .gray : .blue)
                }
                .padding(.horizontal)
                
                // Replace the watchlist statistics section with this enhanced version
                if !watchlistStorage.watchlistStocks.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        // Stocks count card
                        VStack(spacing: 6) {
                            Text("\(watchlistStats.count)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            Text("Stocks")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.backgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cardBorder, lineWidth: 0.5)
                                )
                        )
                        
                        // Total value card
                        VStack(spacing: 6) {
                            Text(String(format: "$%.0f", watchlistStats.totalValue))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            Text("Total Value")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.backgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cardBorder, lineWidth: 0.5)
                                )
                        )
                        
                        // Gainers card
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.stockGreen)
                                Text("\(watchlistStats.gainers)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.stockGreen)
                            }
                            Text("Gainers")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.stockGreen.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stockGreen.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                        
                        // Losers card
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.stockRed)
                                Text("\(watchlistStats.losers)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.stockRed)
                            }
                            Text("Losers")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.stockRed.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stockRed.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                
                if isLoadingWatchlist {
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            PulsingLoadingView(color: .primaryBlue, size: 16)
                            
                            Text("Loading watchlist...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        
                        VStack(spacing: 8) {
                            LoadingCardView()
                            LoadingCardView()
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 20)
                } else if isRefreshing {
                    HStack(spacing: 8) {
                        PulsingLoadingView(color: .stockGreen, size: 14)
                        
                        Text("Refreshing prices...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 12)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                }
                
                // Watchlist Content
                // Replace the empty watchlist state with this enhanced version
                if watchlistStorage.watchlistStocks.isEmpty && !isLoadingWatchlist {
                    VStack(spacing: 32) {
                        // Animated icon group
                        ZStack {
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            VStack(spacing: -8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.primaryBlue)
                                
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.primaryBlue)
                            }
                        }
                        
                        VStack(spacing: 16) {
                            Text("Your watchlist is empty")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.textPrimary)
                            
                            Text("Add stocks to your watchlist to track\ntheir performance and get quick updates")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primaryBlue)
                                
                                Text("Search for stocks in the Search tab")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primaryBlue)
                                
                                Text("Tap 'Add to Watchlist' on any stock")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primaryBlue)
                                
                                Text("View all your saved stocks here")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.backgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.cardBorder, lineWidth: 0.5)
                                )
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                } else if !watchlistStorage.watchlistStocks.isEmpty {
                    List {
                        ForEach(watchlistStorage.watchlistStocks) { stock in
                            StockRowView(stock: stock)
                                .swipeActions(edge: .trailing) {
                                    Button("Remove") {
                                        watchlistStorage.removeStock(stock)
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditMode {
                        Button("Cancel") {
                            exitEditMode()
                        }
                    } else if !watchlistStorage.watchlistStocks.isEmpty {
                        Button("Edit") {
                            enterEditMode()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditMode {
                        Menu {
                            Button("Select All") {
                                selectAllStocks()
                            }
                            
                            Button("Deselect All") {
                                deselectAllStocks()
                            }
                            
                            if hasSelectedStocks {
                                Button("Delete Selected (\(selectedStockCount))") {
                                    deleteSelectedStocks()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else {
                        Menu {
                            Button("Refresh All") {
                                refreshWatchlist()
                            }
                            .disabled(isRefreshing)
                            
                            Button("Clear Watchlist") {
                                clearWatchlist()
                            }
                            .disabled(watchlistStorage.watchlistStocks.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog("Delete Stock", isPresented: $showingDeleteConfirmation, presenting: stockToDelete) { stock in
                Button("Delete \(stock.symbol)", role: .destructive) {
                    confirmDeleteStock()
                }
                Button("Cancel", role: .cancel) { }
            } message: { stock in
                Text("Are you sure you want to remove \(stock.symbol) from your watchlist?")
            }
            .confirmationDialog("Delete Selected Stocks", isPresented: $showingBulkDeleteConfirmation) {
                Button("Delete \(selectedStockCount) Stocks", role: .destructive) {
                    confirmBulkDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedStockCount) selected stocks?")
            }
            .navigationTitle("Watchlist")
            .onAppear {
                loadWatchlist()
            }
            .alert("Error", isPresented: $showError) {
                Button("Retry") {
                    if isRefreshing {
                        refreshWatchlist()
                    } else {
                        loadWatchlist()
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
        .toast(toastManager)
        .overlay(
            VStack {
                Spacer()
                
                if showUndoOption {
                    HStack {
                        Text("\(recentlyDeletedStocks.count) stock\(recentlyDeletedStocks.count == 1 ? "" : "s") deleted")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Undo") {
                            undoLastDeletion()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showUndoOption)
                }
            }
                .allowsHitTesting(showUndoOption)
        )
    }
    
    private func loadWatchlist() {
        isLoadingWatchlist = true
        
        // The watchlist is automatically loaded by WatchlistStorage init
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingWatchlist = false
        }
    }
    
    private func refreshWatchlist() {
        guard !watchlistStorage.watchlistStocks.isEmpty else { return }
        
        isRefreshing = true
        
        Task {
            var updatedStocks: [Stock] = []
            
            for stock in watchlistStorage.watchlistStocks {
                do {
                    let updatedStock = try await apiService.getStockQuote(symbol: stock.symbol)
                    updatedStocks.append(updatedStock)
                } catch {
                    // If individual stock fails, keep the old data
                    updatedStocks.append(stock)
                    
                    // Show error for the first failed stock
                    if errorMessage == nil {
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to update some stock prices"
                            self.showError = true
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                // Update the watchlist with fresh data
                self.watchlistStorage.watchlistStocks = updatedStocks
                self.watchlistStorage.saveWatchlist()
                self.isRefreshing = false
            }
        }
    }
    
    private func clearWatchlist() {
        watchlistStorage.clearWatchlist()
    }
    
    private func removeStockFromWatchlist(_ stock: Stock) {
        stockToDelete = stock
        showingDeleteConfirmation = true
        
        // Show feedback (you can add a toast notification here later)
        print("Removed \(stock.symbol) from watchlist")
    }
    
    // Edit mode management
    private func enterEditMode() {
        isEditMode = true
        selectedStocks.removeAll()
    }
    
    private func exitEditMode() {
        withAnimation {
            isEditMode = false
            selectedStocks.removeAll()
        }
    }
    
    // Stock selection methods
    private func toggleStockSelection(_ stock: Stock) {
        if selectedStocks.contains(stock.id) {
            selectedStocks.remove(stock.id)
        } else {
            selectedStocks.insert(stock.id)
        }
    }
    
    private func selectAllStocks() {
        selectedStocks = Set(watchlistStorage.watchlistStocks.map { $0.id })
    }
    
    private func deselectAllStocks() {
        selectedStocks.removeAll()
    }
    
    // Bulk operations
    private func deleteSelectedStocks() {
        showingBulkDeleteConfirmation = true
        let stocksToDelete = watchlistStorage.watchlistStocks.filter { selectedStocks.contains($0.id) }
        
        exitEditMode()
        
        print("Deleted \(stocksToDelete.count) stocks from watchlist")
    }
    
    // Add these actual deletion methods
    private func confirmDeleteStock() {
        guard let stock = stockToDelete else { return }
        
        withAnimation {
            watchlistStorage.removeStock(stock)
        }
        toastManager.showSuccess(
            message: "\(stock.symbol) removed from watchlist",
            icon: "minus.circle.fill"
        )
        
        // Store for undo
        recentlyDeletedStocks = [stock]
        showUndoToast(for: 1)
        stockToDelete = nil
    }
    
    private func confirmBulkDelete() {
        let stocksToDelete = watchlistStorage.watchlistStocks.filter { selectedStocks.contains($0.id) }
        let count = stocksToDelete.count
        
        withAnimation {
            for stock in stocksToDelete {
                watchlistStorage.removeStock(stock)
            }
        }
        toastManager.showSuccess(
            message: "\(count) stock\(count == 1 ? "" : "s") removed",
            icon: "trash.fill"
        )
        
        // Store for undo
        recentlyDeletedStocks = stocksToDelete
        showUndoToast(for: stocksToDelete.count)
        
        exitEditMode()
    }
    
    // Add undo methods
    private func showUndoToast(for count: Int) {
        showUndoOption = true
        
        // Cancel existing timer
        undoTimer?.invalidate()
        
        // Start new undo timer (5 seconds)
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            self.showUndoOption = false
            self.recentlyDeletedStocks.removeAll()
        }
    }
    
    private func undoLastDeletion() {
        undoTimer?.invalidate()
        
        withAnimation {
            for stock in recentlyDeletedStocks {
                watchlistStorage.addStock(stock)
            }
        }
        
        toastManager.showSuccess(
            message: "\(recentlyDeletedStocks.count) stock\(recentlyDeletedStocks.count == 1 ? "" : "s") restored",
            icon: "arrow.uturn.backward.circle.fill"
        )
        
        showUndoOption = false
        recentlyDeletedStocks.removeAll()
    }
}

#Preview {
    WatchlistView()
}
