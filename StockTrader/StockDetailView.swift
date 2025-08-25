import SwiftUI

struct StockDetailView: View {
    let stock: Stock
    @StateObject private var apiService = StockAPIService()
    @Environment(\.dismiss) private var dismiss
    @StateObject private var watchlistStorage = WatchlistStorage.shared
    @StateObject private var toastManager = ToastManager()
    @State private var detailedStock: DetailedStock?
    @State private var isLoadingDetails = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stock header section (always available)
                stockHeaderSection
                
                if isLoadingDetails {
                    loadingSection
                } else if !errorMessage.isEmpty {
                    errorSection
                } else {
                    // Detailed sections
                    todaysTradingSection
                    weekRangeSection
                    keyStatisticsSection
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .refreshable {
            await refreshStockData()
        }
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(watchlistStorage.isInWatchlist(stock) ? "Remove" : "Add") {
                        toggleWatchlist()
                    }
                    .foregroundColor(watchlistStorage.isInWatchlist(stock) ? .red : .blue)
                    
                    Button(action: {
                        Task {
                            await refreshStockData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoadingDetails)
                }
            }
        }
        .onAppear {
            loadDetailedData()
        }
        .toast(toastManager)
    }
    
    // Add the watchlist toggle method
    private func toggleWatchlist() {
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
    
    private var stockHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stock.symbol)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(stock.companyName)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(stock.formattedPrice)
                .font(.title)
                .fontWeight(.semibold)
            
            HStack {
                Text(stock.formattedChange)
                    .foregroundColor(stock.isPositive ? .green : .red)
                Text(stock.formattedPercentChange)
                    .foregroundColor(stock.isPositive ? .green : .red)
            }
            .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView("Loading detailed information...")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Fetching latest trading data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private var errorSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text("Unable to load detailed information")
                .font(.headline)
            
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                loadDetailedData()
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func loadDetailedData() {
        isLoadingDetails = true
        errorMessage = ""
        
        Task {
            do {
                // For now, create detailed stock from basic stock
                // In a real app, you'd fetch additional data from API
                let detailed = DetailedStock(from: stock)
                
                // Simulate API delay
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    self.detailedStock = detailed
                    self.isLoadingDetails = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load detailed information: \(error.localizedDescription)"
                    self.isLoadingDetails = false
                }
            }
        }
    }
    
    // Add the section views from the previous step here
    private var todaysTradingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Trading")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                TradingDataCell(
                    title: "Open",
                    value: detailedStock?.formattedPrice ?? stock.formattedPrice
                )
                TradingDataCell(
                    title: "High",
                    value: String(format: "$%.2f", (detailedStock?.highPrice ?? stock.currentPrice))
                )
                TradingDataCell(
                    title: "Low",
                    value: String(format: "$%.2f", (detailedStock?.lowPrice ?? stock.currentPrice))
                )
                TradingDataCell(
                    title: "Volume",
                    value: detailedStock?.formattedVolume ?? "N/A"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var weekRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("52-Week Range")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("High")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", detailedStock?.week52High ?? (stock.currentPrice * 1.2)))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Low")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", detailedStock?.week52Low ?? (stock.currentPrice * 0.8)))
                        .fontWeight(.medium)
                }
                
                // Range indicator
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        let high = detailedStock?.week52High ?? (stock.currentPrice * 1.2)
                        let low = detailedStock?.week52Low ?? (stock.currentPrice * 0.8)
                        let range = high - low
                        let position = range > 0 ? (stock.currentPrice - low) / range : 0.5
                        
                        Circle()
                            .fill(stock.isPositive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: max(0, min(geometry.size.width - 8, geometry.size.width * position)))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var keyStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatisticRow(
                    title: "Market Cap",
                    value: detailedStock?.formattedMarketCap ?? "N/A"
                )
                StatisticRow(
                    title: "P/E Ratio",
                    value: detailedStock?.peRatio != nil ? String(format: "%.1f", detailedStock!.peRatio!) : "N/A"
                )
                StatisticRow(
                    title: "Dividend Yield",
                    value: detailedStock?.dividendYield != nil ? String(format: "%.2f%%", detailedStock!.dividendYield!) : "N/A"
                )
                StatisticRow(
                    title: "Previous Close",
                    value: String(format: "$%.2f", stock.currentPrice - stock.priceChange)
                )
                StatisticRow(
                    title: "Last Updated",
                    value: formatLastUpdated(detailedStock?.lastUpdated ?? Date())
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func refreshStockData() async {
        isLoadingDetails = true
        errorMessage = ""
        
        do {
            let updatedStock = try await apiService.getStockQuote(symbol: stock.symbol)
            
            // Update the detailed stock model with new data
            await MainActor.run {
                if let detailed = detailedStock {
                    self.detailedStock = DetailedStock(
                        symbol: updatedStock.symbol,
                        companyName: updatedStock.companyName,
                        currentPrice: updatedStock.currentPrice,
                        priceChange: updatedStock.priceChange,
                        percentChange: updatedStock.percentChange,
                        openPrice: detailed.openPrice,
                        highPrice: max(detailed.highPrice, updatedStock.currentPrice),
                        lowPrice: min(detailed.lowPrice, updatedStock.currentPrice),
                        previousClose: detailed.previousClose,
                        volume: detailed.volume,
                        week52High: detailed.week52High,
                        week52Low: detailed.week52Low,
                        marketCap: detailed.marketCap,
                        peRatio: detailed.peRatio,
                        dividendYield: detailed.dividendYield
                    )
                } else {
                    // If no detailed stock exists, create one from the updated stock
                    self.detailedStock = DetailedStock(from: updatedStock)
                }
                
                // Update watchlist if this stock is saved
                if watchlistStorage.isInWatchlist(stock) {
                    watchlistStorage.removeStock(stock)
                    watchlistStorage.addStock(updatedStock)
                }
                
                self.isLoadingDetails = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to refresh: \(error.localizedDescription)"
                self.isLoadingDetails = false
                toastManager.showError(
                    message: "Failed to refresh: \(error.localizedDescription)",
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
    }
}

struct TradingDataCell: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}
