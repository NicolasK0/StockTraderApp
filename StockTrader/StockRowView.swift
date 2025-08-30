import SwiftUI

struct StockRowView: View {
    let stock: Stock
    var onTap: (() -> Void)? = nil
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Stock info with icon
            HStack(spacing: 12) {
                // Stock symbol circle
                ZStack {
                    Circle()
                        .fill(Color.primaryBlue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(String(stock.symbol.prefix(2)))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text(stock.companyName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Right side - Price and changes with enhanced styling
            VStack(alignment: .trailing, spacing: 6) {
                Text(stock.formattedPrice)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 6) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(stock.formattedChange)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(stock.formattedPercentChange)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.stockChangeColor(isPositive: stock.isPositive))
                )
            }
        }
        // Add these animation enhancements to your StockRowView
        // Replace the main HStack with this animated version
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardBorder, lineWidth: 0.5)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Execute the provided action
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        } perform: {
            // Long press action if needed
        }

        // Also add smooth color transitions for the price change indicator
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.stockChangeColor(isPositive: stock.isPositive))
                .animation(.easeInOut(duration: 0.3), value: stock.isPositive)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        StockRowView(stock: Stock.sampleStocks[0])
        StockRowView(stock: Stock.sampleStocks[1])
        StockRowView(stock: Stock.sampleStocks[3])
    }
    .padding()
    .background(Color.backgroundSecondary)
}
