//
//  ColorScheme.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/25/25.
//

import SwiftUI

extension Color {
    // MARK: - Stock App Color Scheme
    
    // Primary brand colors
    static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 0.99) // #007AFF
    static let primaryDark = Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
    
    // Stock-specific colors
    static let stockGreen = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    static let stockRed = Color(red: 0.96, green: 0.28, blue: 0.29) // #FF3B30
    
    // Background colors
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    // Text colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // Card and component colors
    static let cardBackground = Color(.systemBackground)
    static let cardBorder = Color(.separator)
    static let buttonBackground = Color(.systemBlue)
    
    // Status colors
    static let successGreen = Color(.systemGreen)
    static let warningOrange = Color(.systemOrange)
    static let errorRed = Color(.systemRed)
    
    // Helper method for dynamic stock colors
    static func stockChangeColor(isPositive: Bool) -> Color {
        return isPositive ? stockGreen : stockRed
    }
}
