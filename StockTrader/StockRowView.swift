import SwiftUI

struct StockRowView: View {
    let stock: Stock
    @StateObject private var portfolioStorage = PortfolioStorage.shared
    @State private var showingTradingView = false
    
    private var position: StockPosition? {
        portfolioStorage.portfolio.getPosition(for: stock.symbol)
    }
    
    var body: some View {
        HStack {
            // Left side - Stock symbol and company name
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(stock.companyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Show position if user owns this stock
                if let position = position {
                    Text("\(position.quantity) shares")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Middle - Price and changes
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.formattedPrice)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Text(stock.formattedChange)
                        .font(.caption)
                        .foregroundColor(stock.isPositive ? .green : .red)
                    
                    Text(stock.formattedPercentChange)
                        .font(.caption)
                        .foregroundColor(stock.isPositive ? .green : .red)
                }
            }
            
            // Right side - Trade button
            VStack {
                Button("Trade") {
                    showingTradingView = true
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingTradingView) {
            TradingView(stock: stock)
        }
    }
}