//
//  JSONParsingHelpers.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/21/25.
//

import Foundation

// MARK: - JSON Parsing Helpers

extension String {
    /// Safely converts a string to Double, removing common formatting
    var safeDoubleValue: Double {
        let cleanString = self
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Double(cleanString) ?? 0.0
    }
    
    /// Safely converts string to integer
    var safeIntValue: Int {
        let cleanString = self
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Int(cleanString) ?? 0
    }
    
    /// Removes percentage symbol and converts to double
    var percentageValue: Double {
        let cleanString = self.replacingOccurrences(of: "%", with: "")
        return Double(cleanString) ?? 0.0
    }
}

extension Dictionary where Key == String, Value == Any {
    /// Safely get string value from dictionary
    func safeString(for key: String) -> String {
        return self[key] as? String ?? ""
    }
    
    /// Safely get double value from dictionary (handles string or number)
    func safeDouble(for key: String) -> Double {
        if let doubleValue = self[key] as? Double {
            return doubleValue
        } else if let stringValue = self[key] as? String {
            return stringValue.safeDoubleValue
        }
        return 0.0
    }
}
