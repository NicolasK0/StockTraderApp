//
//  EmptyStateView.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/25/25.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, description: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding(40)
    }
}

// MARK: - Predefined Empty States
extension EmptyStateView {
    static func searchEmpty(onSearchTap: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass.circle",
            title: "Start Your Search",
            description: "Enter a stock symbol or company name to find stocks and view their current prices",
            actionTitle: "Search Stocks",
            action: onSearchTap
        )
    }
    
    static func watchlistEmpty(onAddStocksTap: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "star.circle",
            title: "Your Watchlist is Empty",
            description: "Add stocks you want to track to see their prices and changes in one place",
            actionTitle: "Find Stocks to Add",
            action: onAddStocksTap
        )
    }
    
    static func noResults(for searchQuery: String) -> EmptyStateView {
        EmptyStateView(
            icon: "questionmark.circle",
            title: "No Results Found",
            description: "We couldn't find any stocks matching '\(searchQuery)'. Try a different search term or stock symbol."
        )
    }
    
    static func networkError(onRetryTap: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Connection Issue",
            description: "Unable to load stock data. Please check your internet connection and try again.",
            actionTitle: "Try Again",
            action: onRetryTap
        )
    }
}
