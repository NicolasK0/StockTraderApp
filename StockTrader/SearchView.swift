//
//  SearchView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var apiService = StockAPIService()
    @ObservedObject private var watchlistStorage = WatchlistStorage.shared
    @State private var searchText = ""
    @State private var searchResults: [SearchMatch] = []
    @State private var isSearching = false
    @State private var errorMessage = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var isFetchingQuote = false
    @State private var stockQuotes: [Stock] = []
    @State private var recentSearches: [String] = []
    @StateObject private var portfolioStorage = PortfolioStorage.shared
    @StateObject private var toastManager = ToastManager()
    @State private var showingTradingView = false
    @State private var selectedStockForTrading: Stock?
    @State private var loadingStockSymbol = ""
    
    private var shouldShowRecentSearches: Bool {
        searchText.isEmpty && !recentSearches.isEmpty && searchResults.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                
                // Search Results Area
                if !searchResults.isEmpty {
                    searchResultsSection
                }
                
                if isSearching {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Searching...")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        // Show skeleton placeholders
                        LazyVStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { _ in
                                StockRowSkeleton()
                                    .padding(.horizontal)
                            }
                        }
                    }
                } else if !errorMessage.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .padding()
                } else if shouldShowRecentSearches {
                    recentSearchesSection
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.title)
                            .foregroundColor(.gray)
                        Text("No stocks found")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else if isFetchingQuote {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Getting quote for \(loadingStockSymbol)...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .sheet(isPresented: $showingTradingView) {
                if let stock = selectedStockForTrading {
                    TradingView(stock: stock)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .animation(.easeInOut(duration: 0.3), value: isSearching)
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search stocks...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchText) { oldValue, newValue in
                    // Cancel previous search and start a new one after delay
                    searchTask?.cancel()
                    
                    if newValue.isEmpty {
                        searchResults = []
                        errorMessage = ""
                        return
                    }
                    
                    // Debounce: wait for user to stop typing
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                        
                        if !Task.isCancelled {
                            await performDebouncedSearch(query: newValue)
                        }
                    }
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    searchResults = []
                    errorMessage = ""
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private var searchResultsSection: some View {
        VStack {
            // Search Results Section
            Text("Search Results")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            List(searchResults, id: \.symbol) { match in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.symbol)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(match.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if isFetchingQuote {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    fetchStockQuote(for: match.symbol)
                }
            }
            .frame(maxHeight: 200)
            
            // Stock Quotes Section
            if !stockQuotes.isEmpty {
                stockQuotesSection
            }
        }
    }
    
    private var stockQuotesSection: some View {
        VStack {
            HStack {
                Text("Stock Details")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    stockQuotes = []
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            ForEach(stockQuotes, id: \.symbol) { stock in
                VStack(spacing: 12) {
                    StockRowView(stock: stock)
                    
                    // Quick trading actions
                    HStack(spacing: 12) {
                        // Watchlist button (existing)
                        Button(watchlistStorage.isInWatchlist(stock) ? "Remove from Watchlist" : "Add to Watchlist") {
                            if watchlistStorage.isInWatchlist(stock) {
                                watchlistStorage.removeStock(stock)
                                toastManager.showSuccess(
                                    message: "\(stock.symbol) removed from watchlist",
                                    icon: "minus.circle.fill"
                                )
                            } else {
                                watchlistStorage.addStock(stock)
                                toastManager.showSuccess(
                                    message: "\(stock.symbol) added to watchlist",
                                    icon: "plus.circle.fill"
                                )
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(watchlistStorage.isInWatchlist(stock) ? Color.red : Color.blue)
                        .cornerRadius(6)
                        
                        Spacer()
                        
                        // Quick buy buttons
                        HStack(spacing: 8) {
                            ForEach([1, 5, 10], id: \.self) { quantity in
                                Button("Buy \(quantity)") {
                                    quickBuyStock(stock, quantity: quantity)
                                }
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(portfolioStorage.portfolio.canAfford(quantity: quantity, price: stock.currentPrice) ? Color.green : Color.gray)
                                .cornerRadius(4)
                                .disabled(!portfolioStorage.portfolio.canAfford(quantity: quantity, price: stock.currentPrice))
                            }
                            
                            Button("More") {
                                selectedStockForTrading = stock
                                showingTradingView = true
                            }
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    private var recentSearchesSection: some View {
        // Recent Searches Section
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Clear All") {
                    recentSearches = []
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recentSearches.reversed(), id: \.self) { search in
                        Button(search) {
                            searchText = search
                            performSearch()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Methods
    
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return
        }
        
        // Add to recent searches if not already present
        if !recentSearches.contains(query) {
            recentSearches.append(query)
            // Keep only last 10 searches
            if recentSearches.count > 10 {
                recentSearches.removeFirst()
            }
        }
        
        Task {
            isSearching = true
            errorMessage = ""
            
            do {
                searchResults = try await apiService.searchStocks(query: query)
            } catch {
                errorMessage = error.localizedDescription
                searchResults = []
            }
        }
    }
    
    // Add this new method to your SearchView
    private func performDebouncedSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        await MainActor.run {
            isSearching = true
            errorMessage = ""
        }
        
        do {
            let results = try await apiService.searchStocks(query: query)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                searchResults = []
                isSearching = false
            }
        }
    }
    
    // Add these methods to SearchView
    private func quickBuyStock(_ stock: Stock, quantity: Int) {
        let success = portfolioStorage.buyStock(stock, quantity: quantity)
        
        if success {
            toastManager.showSuccess(
                message: "Bought \(quantity) share\(quantity == 1 ? "" : "s") of \(stock.symbol)",
                icon: "plus.circle.fill"
            )
        } else {
            toastManager.showError(
                message: "Insufficient funds to buy \(stock.symbol)",
                icon: "exclamationmark.circle.fill"
            )
        }
    }

    
    // Add this new method to fetch quotes
    private func fetchStockQuote(for symbol: String) {
        Task {
            isFetchingQuote = true
            loadingStockSymbol = symbol
            
            do {
                let stock = try await apiService.getStockQuote(symbol: symbol)
                await MainActor.run {
                    // Add to quotes list if not already present
                    if !stockQuotes.contains(where: { $0.symbol == stock.symbol }) {
                        stockQuotes.append(stock)
                    }
                    isFetchingQuote = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch quote: \(error.localizedDescription)"
                    isFetchingQuote = false
                }
            }
        }
    }
}

#Preview {
    SearchView()
}