import Foundation

struct DetailedStock: Identifiable, Codable {
    var id: String { symbol } // Computed property instead
    let symbol: String
    let companyName: String
    let currentPrice: Double
    let priceChange: Double
    let percentChange: Double
    
    // Extended trading information
    let openPrice: Double
    let highPrice: Double
    let lowPrice: Double
    let previousClose: Double
    let volume: Int
    
    // 52-week data
    let week52High: Double?
    let week52Low: Double?
    
    // Additional metrics
    let marketCap: Double?
    let peRatio: Double?
    let dividendYield: Double?
    
    // Trading day information
    let lastUpdated: Date
    
    // Convert from basic Stock model
    init(from stock: Stock) {
        self.symbol = stock.symbol
        self.companyName = stock.companyName
        self.currentPrice = stock.currentPrice
        self.priceChange = stock.priceChange
        self.percentChange = stock.percentChange
        
        // Default values for missing data
        self.openPrice = stock.currentPrice
        self.highPrice = stock.currentPrice
        self.lowPrice = stock.currentPrice
        self.previousClose = stock.currentPrice - stock.priceChange
        self.volume = 0
        
        self.week52High = nil
        self.week52Low = nil
        self.marketCap = nil
        self.peRatio = nil
        self.dividendYield = nil
        
        self.lastUpdated = Date()
    }
    
    // Full initializer for API data
    init(symbol: String, companyName: String, currentPrice: Double, priceChange: Double, percentChange: Double,
         openPrice: Double, highPrice: Double, lowPrice: Double, previousClose: Double, volume: Int,
         week52High: Double? = nil, week52Low: Double? = nil, marketCap: Double? = nil,
         peRatio: Double? = nil, dividendYield: Double? = nil) {
        
        self.symbol = symbol
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.percentChange = percentChange
        self.openPrice = openPrice
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.previousClose = previousClose
        self.volume = volume
        self.week52High = week52High
        self.week52Low = week52Low
        self.marketCap = marketCap
        self.peRatio = peRatio
        self.dividendYield = dividendYield
        self.lastUpdated = Date()
    }
    
    // Rest of your computed properties remain the same...
    var isPositive: Bool {
        return priceChange >= 0
    }
    
    var formattedPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var formattedChange: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@$%.2f", sign, priceChange)
    }
    
    var formattedPercentChange: String {
        let sign = isPositive ? "+" : ""
        return String(format: "%@%.2f%%", sign, percentChange)
    }
    
    var formattedVolume: String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", Double(volume) / 1_000)
        } else {
            return "\(volume)"
        }
    }
    
    var formattedMarketCap: String? {
        guard let marketCap = marketCap else { return nil }
        
        if marketCap >= 1_000_000_000 {
            return String(format: "$%.1fB", marketCap / 1_000_000_000)
        } else if marketCap >= 1_000_000 {
            return String(format: "$%.1fM", marketCap / 1_000_000)
        } else {
            return String(format: "$%.0f", marketCap)
        }
    }
}
