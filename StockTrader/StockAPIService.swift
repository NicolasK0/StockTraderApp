//
//  StockAPIService.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/20/25.
//

import Foundation

class StockAPIService: ObservableObject {
    private let baseURL = "https://www.alphavantage.co/query"
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["ALPHA_VANTAGE_API_KEY"] as? String else {
            fatalError("API key not found in Config.plist")
        }
        return key
    }
    
    private let urlSession: URLSession
    
    // This service will handle API calls to Alpha Vantage
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: configuration)
        print("StockAPIService initialized")
    }
    
    // Replace the existing searchStocks method with this improved version
    func searchStocks(query: String) async throws -> [SearchMatch] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, trimmedQuery.count >= 2 else {
            return []
        }
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "function", value: "SYMBOL_SEARCH"),
            URLQueryItem(name: "keywords", value: trimmedQuery),
            URLQueryItem(name: "apikey", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        // Validate the JSON response before parsing
        try validateJSONResponse(data)
        
        do {
            let searchResponse = try JSONDecoder().decode(AlphaVantageSearchResponse.self, from: data)
            
            // Filter results to only include common stocks (optional)
            let filteredMatches = searchResponse.bestMatches.filter { match in
                match.type.contains("Equity") || match.type.isEmpty
            }
            
            return filteredMatches
        } catch let decodingError as DecodingError {
            print("Search decoding error: \(decodingError)")
            // Search failures are less critical than quote failures
            return []
        } catch APIError.apiLimitExceeded {
            throw APIError.apiLimitExceeded
        } catch {
            print("Search parsing error: \(error)")
            return []
        }
    }
    
    // Replace the existing getStockQuote method with this improved version
    func getStockQuote(symbol: String) async throws -> Stock {
        return try await performWithTimeout {
            return try await self.getStockQuoteWithoutTimeout(symbol: symbol)
        }
    }
    
    private func getStockQuoteWithoutTimeout(symbol: String) async throws -> Stock {
        guard !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.invalidSymbol
        }
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "function", value: "GLOBAL_QUOTE"),
            URLQueryItem(name: "symbol", value: symbol.uppercased()),
            URLQueryItem(name: "apikey", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        // Add this line after receiving data but before parsing
        print("Raw API Response: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
        
        // Validate the JSON response before parsing
        try validateJSONResponse(data)
        
        do {
            let quoteResponse = try JSONDecoder().decode(AlphaVantageQuoteResponse.self, from: data)
            
            // Additional validation - make sure we have actual data
            guard !quoteResponse.globalQuote.symbol.isEmpty else {
                throw APIError.invalidSymbol
            }
            
            return convertToStock(from: quoteResponse.globalQuote)
        } catch let decodingError as DecodingError {
            print("Detailed decoding error: \(decodingError)")
            throw APIError.decodingError
        } catch let error as APIError where error == .invalidSymbol || error == .apiLimitExceeded {
            // Re-throw these specific errors
            throw error
        } catch {
            print("Unexpected parsing error: \(error)")
            throw APIError.malformedResponse
        }
        
    }
    
    private func convertToStock(from quote: GlobalQuote) -> Stock {
        let currentPrice = quote.price.safeDoubleValue
        let change = quote.change.safeDoubleValue
        let percentChange = quote.changePercent.percentageValue
        
        return Stock(
            symbol: quote.symbol,
            companyName: quote.symbol, // Will be enhanced with company name lookup later
            currentPrice: currentPrice,
            priceChange: change,
            percentChange: percentChange
        )
    }
    
    // Add this new method to convert search results to basic stock info
    private func convertSearchMatchToStock(from match: SearchMatch) -> Stock {
        return Stock(
            symbol: match.symbol,
            companyName: match.name,
            currentPrice: 0.0, // Price will be fetched separately
            priceChange: 0.0,
            percentChange: 0.0
        )
    }
    
    // Add these error types at the bottom of the file, outside the class
    enum APIError: Error, LocalizedError {
        case invalidURL
        case networkError
        case decodingError
        case noData
        case apiLimitExceeded
        case invalidSymbol
        case malformedResponse
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .networkError:
                return "Network error occurred"
            case .decodingError:
                return "Failed to decode response"
            case .noData:
                return "No data received"
            case .apiLimitExceeded:
                return "API rate limit exceeded. Please try again later."
            case .invalidSymbol:
                return "Stock symbol not found"
            case .malformedResponse:
                return "Received unexpected response format"
            case .timeout:
                return "Request timed out. Please check your connection and try again."
            }
        }
    }
    
    // Add this method inside the StockAPIService class
    private func validateJSONResponse(_ data: Data) throws {
        // Check if the response contains an error message
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Alpha Vantage returns error messages in specific formats
            if let errorMessage = jsonObject["Error Message"] as? String {
                print("API Error: \(errorMessage)")
                throw APIError.invalidSymbol
            }
            
            if let note = jsonObject["Note"] as? String, note.contains("rate limit") {
                print("Rate limit exceeded: \(note)")
                throw APIError.apiLimitExceeded
            }
            
            // Check for empty Global Quote (invalid symbol response)
            if let globalQuote = jsonObject["Global Quote"] as? [String: Any],
               globalQuote.isEmpty {
                print("Empty Global Quote - invalid symbol")
                throw APIError.invalidSymbol
            }
            
            // Check if response is empty or missing expected fields
            if jsonObject.isEmpty {
                throw APIError.malformedResponse
            }
        }
    }
    
    private func performWithTimeout<T>(_ operation: @escaping () async throws -> T, timeout: TimeInterval = 15.0) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                return try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw APIError.timeout
            }
            
            // Return the first completed task
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    func testAPIConnection() async -> Bool {
        do {
            let results = try await searchStocks(query: "AAPL")
            print("API connection successful. Found \(results.count) results for AAPL")
            return !results.isEmpty
        } catch {
            print("API connection failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // Add this comprehensive test method at the end of the StockAPIService class
    func testDataParsingWorkflow() async -> (success: Bool, details: String) {
        var testResults: [String] = []
        
        do {
            // Test 1: Search functionality
            testResults.append("🔍 Testing stock search...")
            let searchResults = try await searchStocks(query: "Apple")
            if searchResults.isEmpty {
                return (false, "Search returned no results for 'Apple'")
            }
            testResults.append("✅ Search found \(searchResults.count) results")
            
            // Test 2: Quote fetching and parsing
            testResults.append("📊 Testing quote fetching...")
            let appleStock = try await getStockQuote(symbol: "AAPL")
            
            // Validate the parsed data
            guard appleStock.currentPrice > 0 else {
                return (false, "Invalid price parsed: \(appleStock.currentPrice)")
            }
            
            testResults.append("✅ Successfully parsed AAPL stock:")
            testResults.append("   Symbol: \(appleStock.symbol)")
            testResults.append("   Price: \(appleStock.formattedPrice)")
            testResults.append("   Change: \(appleStock.formattedChange)")
            testResults.append("   Percent: \(appleStock.formattedPercentChange)")
            
            // Test 3: Error handling with invalid symbol
            testResults.append("❌ Testing error handling...")
            do {
                _ = try await getStockQuote(symbol: "INVALIDXYZ123")
                testResults.append("⚠️ Should have failed with invalid symbol")
            } catch APIError.invalidSymbol {
                testResults.append("✅ Correctly handled invalid symbol")
            } catch {
                testResults.append("⚠️ Unexpected error for invalid symbol: \(error)")
            }
            
            let successMessage = testResults.joined(separator: "\n")
            return (true, successMessage)
            
        } catch APIError.apiLimitExceeded {
            return (false, "API rate limit exceeded. Please try again later.")
        } catch {
            return (false, "Test failed with error: \(error.localizedDescription)")
        }
    }
}
