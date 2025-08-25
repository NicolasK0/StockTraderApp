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
        !selectedStocks.isEmpty
    }
    private var selectedStockCount: Int {
        selectedStocks.count
    }
    
    private var watchlistStats: (count: Int, totalValue: Double, gainers: Int, losers: Int) {
        let stocks = watchlistStorage.watchlistStocks
        let count = stocks.count
        let totalValue = stocks.reduce(0) { $0 + $1.currentPrice }
        let gainers = stocks.filter { $0.isPositive }.count
        let losers = stocks.filter { !$0.isPositive }.count
        
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
                
                if !watchlistStorage.watchlistStocks.isEmpty {
                    VStack(spacing: 8) {
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(watchlistStats.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Stocks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(String(format: "$%.2f", watchlistStats.totalValue))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Total Value")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(watchlistStats.gainers)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Gainers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(watchlistStats.losers)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text("Losers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                if isLoadingWatchlist {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading your watchlist...")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                } else if isRefreshing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Refreshing stock prices...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                // Watchlist Content
                if watchlistStorage.watchlistStocks.isEmpty && !isLoadingWatchlist {
                    VStack {
                        Image(systemName: "star")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Your watchlist is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Search for stocks to add them to your watchlist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                } else {
                    List {
                        // Replace the existing ForEach in your watchlist List with this NavigationLink version
                        ForEach(watchlistStorage.watchlistStocks) { stock in
                            NavigationLink(destination: StockDetailView(stock: stock)) {
                                StockRowView(stock: stock)
                            }
                            .navigationViewStyle(StackNavigationViewStyle())
                            .buttonStyle(PlainButtonStyle())
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
            // Add these confirmation dialogs after the .toolbar modifier
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
        // Add undo overlay after the toast modifier
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
