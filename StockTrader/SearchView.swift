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
    @State private var hasSearched = false
    @State private var isSearchFieldFocused = false
    @State private var isRefreshing = false
    @FocusState private var searchFieldFocused: Bool
    @State private var sortOption: SortOption = .relevance
    @State private var convertedStocks: [Stock] = []
    
    private var shouldShowRecentSearches: Bool {
        searchText.isEmpty && !recentSearches.isEmpty && searchResults.isEmpty
    }
    private var sortedSearchResults: [Stock] {
        switch sortOption {
        case .relevance:
            return convertedStocks
        case .alphabetical:
            return convertedStocks.sorted { (stock1: Stock, stock2: Stock) in
                stock1.companyName < stock2.companyName
            }
        case .reverseAlphabetical:
            return convertedStocks.sorted { (stock1: Stock, stock2: Stock) in
                stock1.companyName > stock2.companyName
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case alphabetical = "A-Z"
        case reverseAlphabetical = "Z-A"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                
                // Initial empty state (no search performed)
                if !hasSearched && searchText.isEmpty && !isSearchFieldFocused {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Search Stocks")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Find stocks by symbol or company name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                }
                
                // No results found
                else if hasSearched && searchResults.isEmpty && !isSearching {
                    VStack {
                        Image(systemName: "rectangle.on.rectangle.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("No stocks match \"\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                }
                
                // Network error state
                else if !errorMessage.isEmpty {
                    if errorMessage.contains("network") || errorMessage.contains("connection") {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("Network Error")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Please check your internet connection and try again")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Retry") {
                                Task {
                                    await performDebouncedSearch(query: searchText)
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .padding(40)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("Something went wrong")
                                .font(.headline)
                            
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button("Try Again") {
                                Task {
                                    await performDebouncedSearch(query: searchText)
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .padding(40)
                    }
                }
                
                // Search Results Area
                else if !convertedStocks.isEmpty {
                    searchResultsSection
                }
                
                else if isSearching {
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .font(.caption)
                                .foregroundColor(.gray)
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
        // Search Bar with enhanced styling
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search stocks or companies...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .medium))
                    .focused($searchFieldFocused)
                    .onSubmit {
                        performSearchAndFetchQuotes() // Use this method on submit
                    }
                    .onChange(of: searchText) { oldValue, newValue in
                        performLiveSearch(query: newValue)
                    }
                    .onChange(of: searchFieldFocused) { oldValue, newValue in
                        isSearchFieldFocused = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: { clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(searchFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            if isSearching {
                SearchLoadingView(message: "Searching for stocks...")
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.3), value: isSearching)
            }
        }
    }
    
    private func handleStockSelection(_ stock: Stock) {
        // Add to quotes list if not already present
        if !stockQuotes.contains(where: { $0.symbol == stock.symbol }) {
            stockQuotes.append(stock)
        }
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Results header with count and sorting
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search Results")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(convertedStocks.count) stocks found")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sort picker with better styling
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            sortOption = option
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Sort")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Enhanced results list - Using Button wrapper to ensure proper tap handling
            LazyVStack(spacing: 8) {
                ForEach(sortedSearchResults) { stock in
                    Button(action: {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        // Navigate to detail view - using the existing sheet mechanism
                        selectedStockForTrading = stock
                        showingTradingView = true
                    }) {
                        StockRowView(stock: stock)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                }
            }
            .background(Color(.systemBackground))
            
            // Stock Quotes Section (rest remains unchanged)
            if !stockQuotes.isEmpty {
                stockQuotesSection
            }
        }
        .background(Color(.systemBackground))
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
            
            List(stockQuotes, id: \.symbol) { stock in
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
            .refreshable {
                refreshStockQuotes()
            }
            .overlay(
                Group {
                    if isRefreshing {
                        VStack {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Updating stock prices...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(.regularMaterial)
                            .cornerRadius(8)
                            Spacer()
                        }
                        .transition(.move(edge: .top))
                    }
                }
            )
            .frame(maxHeight: 300) // Add height constraint for the list
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
    
    // Main search method - Fixed to properly populate both arrays
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return
        }
        hasSearched = true
        // Add to recent searches if not already present
        if !recentSearches.contains(query) {
            recentSearches.append(query)
            // Keep only last 10 searches
            if recentSearches.count > 10 {
                recentSearches.removeFirst()
            }
        }
        
        Task {
            await MainActor.run {
                isSearching = true
                errorMessage = ""
            }
            
            do {
                // First get search matches from API
                let matches = try await apiService.searchStocks(query: query)
                searchResults = matches // Store the SearchMatch objects
                
                // Then fetch quotes (Stock objects) for all matches
                var stocks: [Stock] = []
                for result in matches.prefix(10) { // Limit to first 10 results
                    do {
                        let stock = try await apiService.getStockQuote(symbol: result.symbol)
                        stocks.append(stock)
                    } catch {
                        // If we can't get quote, create a basic stock object with default values
                        let basicStock = Stock(
                            symbol: result.symbol,
                            companyName: result.name,
                            currentPrice: 0.0,
                            priceChange: 0.0,
                            percentChange: 0.0
                        )
                        stocks.append(basicStock)
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    convertedStocks = stocks // This populates the displayed results
                    isSearching = false
                }
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    searchResults = []
                    convertedStocks = []
                    isSearching = false
                }
            }
        }
    }
    
    // Handler for onSubmit - calls the fixed search method
    private func performSearchAndFetchQuotes() {
        performSearch()
    }
    
    // Ensure performLiveSearch also properly converts matches to stocks
    private func performLiveSearch(query: String) {
        // Cancel previous search and start a new one after delay
        searchTask?.cancel()
        
        if query.isEmpty {
            searchResults = []
            errorMessage = ""
            convertedStocks = [] // Reset converted stocks as well
            return
        }
        
        // Debounce: wait for user to stop typing
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
            
            if !Task.isCancelled {
                await performDebouncedSearch(query: query)
            }
        }
    }
    
    // Fix performDebouncedSearch to ensure it properly populates both arrays
    private func performDebouncedSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        await MainActor.run {
            isSearching = true
            errorMessage = ""
        }
        
        do {
            // First get search matches
            let results = try await apiService.searchStocks(query: query)
            
            // Then fetch quotes for all matches
            var stocks: [Stock] = []
            for result in results.prefix(10) { // Limit to first 10 results
                do {
                    let stock = try await apiService.getStockQuote(symbol: result.symbol)
                    stocks.append(stock)
                } catch {
                    // If we can't get quote, create a basic stock object
                    let basicStock = Stock(
                        symbol: result.symbol,
                        companyName: result.name,
                        currentPrice: 0.0,
                        priceChange: 0.0,
                        percentChange: 0.0
                    )
                    stocks.append(basicStock)
                }
            }
            
            await MainActor.run {
                searchResults = results
                convertedStocks = stocks
                isSearching = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                searchResults = []
                convertedStocks = []
                isSearching = false
            }
        }
    }
    
    // Add the missing clearSearch method
    private func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = ""
        hasSearched = false
        searchFieldFocused = false
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
    
    private func refreshStockQuotes() {
        Task {
            await MainActor.run {
                isRefreshing = true
            }
            
            // Refresh all current stock quotes
            var refreshedQuotes: [Stock] = []
            
            for quote in stockQuotes {
                do {
                    let refreshedStock = try await apiService.getStockQuote(symbol: quote.symbol)
                    refreshedQuotes.append(refreshedStock)
                } catch {
                    // Keep the old quote if refresh fails
                    refreshedQuotes.append(quote)
                }
            }
            
            await MainActor.run {
                stockQuotes = refreshedQuotes
                isRefreshing = false
            }
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
