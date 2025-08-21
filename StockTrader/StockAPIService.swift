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
}
