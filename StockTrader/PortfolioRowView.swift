import SwiftUI

struct PortfolioRowView: View {
    let position: PortfolioPosition
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row: Stock info and current price
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(position.companyName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(position.formattedCurrentPrice)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(position.formattedShares) shares")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Bottom row: Performance metrics
            HStack {
                // Cost basis
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cost Basis")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(position.formattedTotalCost)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Current value
                VStack(alignment: .center, spacing: 2) {
                    Text("Current Value")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(position.formattedCurrentValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Gain/Loss
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Gain/Loss")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(position.formattedGainLoss)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(position.isPositive ? .green : .red)
                        
                        Text(position.formattedPercentGainLoss)
                            .font(.caption2)
                            .foregroundColor(position.isPositive ? .green : .red)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
}

#Preview {
    PortfolioRowView(position: Portfolio.samplePortfolio.positions[0])
        .padding()
}
