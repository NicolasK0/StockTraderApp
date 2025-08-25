//
//  SkeletonView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/25/25.
//

import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1), Color.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct StockRowSkeleton: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView()
                    .frame(width: 60, height: 16)
                SkeletonView()
                    .frame(width: 120, height: 12)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                SkeletonView()
                    .frame(width: 70, height: 16)
                SkeletonView()
                    .frame(width: 50, height: 12)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SkeletonView()
}
