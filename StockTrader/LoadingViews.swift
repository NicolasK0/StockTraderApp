//
//  LoadingViews.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/25/25.
//

import SwiftUI

// MARK: - Loading Views

struct PulsingLoadingView: View {
    @State private var isPulsing = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .primaryBlue, size: CGFloat = 20) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(isPulsing ? 1.2 : 0.8)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct LoadingCardView: View {
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder circle
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                // Placeholder lines
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 12)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.4), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset * 200)
                .clipped()
        )
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1
            }
        }
    }
}

struct SearchLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                PulsingLoadingView(color: .primaryBlue, size: 16)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            // Loading placeholder cards
            VStack(spacing: 8) {
                LoadingCardView()
                LoadingCardView()
                LoadingCardView()
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }
}
