//
//  WatchListStorage.swift
//  StockTrader
//
//  Created by Nicolas Kousoulas on 8/21/25.
//

import Foundation

class WatchlistStorage: ObservableObject {
    static let shared = WatchlistStorage()
    @Published var watchlistStocks: [Stock] = []
    private let versionKey = "WatchlistVersion"
    private let currentVersion = 1
    private let userDefaults = UserDefaults.standard
    private let watchlistKey = "SavedWatchlist"
    
    private init() {
        migrateDataIfNeeded()
        loadWatchlist()
    }
    
    // MARK: - Core Storage Methods
    
    func loadWatchlist() {
        guard let data = userDefaults.data(forKey: watchlistKey) else {
            print("No saved watchlist found")
            watchlistStocks = []
            return
        }
        
        do {
            let savedStocks = try JSONDecoder().decode([Stock].self, from: data)
            watchlistStocks = savedStocks
            print("Loaded \(savedStocks.count) stocks from watchlist")
        } catch {
            print("Failed to load watchlist: \(error.localizedDescription)")
            watchlistStocks = []
        }
    }
    
    func saveWatchlist() {
        do {
            let data = try JSONEncoder().encode(watchlistStocks)
            userDefaults.set(data, forKey: watchlistKey)
            print("Saved \(watchlistStocks.count) stocks to watchlist")
        } catch {
            print("Failed to save watchlist: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Watchlist Management
    
    func addStock(_ stock: Stock) {
        // Check if stock is already in watchlist
        guard !watchlistStocks.contains(where: { $0.symbol == stock.symbol }) else {
            print("Stock \(stock.symbol) is already in watchlist")
            return
        }
        
        watchlistStocks.append(stock)
        saveWatchlist()
        print("Added \(stock.symbol) to watchlist")
    }
    
    func removeStock(_ stock: Stock) {
        watchlistStocks.removeAll { $0.id == stock.id }
        saveWatchlist()
        print("Removed \(stock.symbol) from watchlist")
    }
    
    func isInWatchlist(_ stock: Stock) -> Bool {
        return watchlistStocks.contains(where: { $0.symbol == stock.symbol })
    }
    
    func clearWatchlist() {
        watchlistStocks.removeAll()
        saveWatchlist()
        print("Cleared all stocks from watchlist")
    }
    
    private func migrateDataIfNeeded() {
        let savedVersion = userDefaults.integer(forKey: versionKey)
        
        if savedVersion < currentVersion {
            print("Migrating watchlist data from version \(savedVersion) to \(currentVersion)")
            
            switch savedVersion {
            case 0:
                // Migration from version 0 (first version) to version 1
                migrateFromV0ToV1()
            default:
                break
            }
            
            userDefaults.set(currentVersion, forKey: versionKey)
        }
    }
    
    private func migrateFromV0ToV1() {
        // Example migration - in the future you might need to convert data formats
        print("Performing migration from v0 to v1")
        
        // For now, just ensure data integrity
        if let data = userDefaults.data(forKey: watchlistKey) {
            do {
                let stocks = try JSONDecoder().decode([Stock].self, from: data)
                print("Successfully validated \(stocks.count) stocks during migration")
            } catch {
                print("Migration failed, clearing corrupted data: \(error)")
                userDefaults.removeObject(forKey: watchlistKey)
            }
        }
    }
    
    // Add backup functionality
    func createBackup() -> Data? {
        do {
            let backupData = try JSONEncoder().encode(watchlistStocks)
            print("Created backup of \(watchlistStocks.count) stocks")
            return backupData
        } catch {
            print("Failed to create backup: \(error)")
            return nil
        }
    }
    
    func restoreFromBackup(_ data: Data) -> Bool {
        do {
            let restoredStocks = try JSONDecoder().decode([Stock].self, from: data)
            watchlistStocks = restoredStocks
            saveWatchlist()
            print("Restored \(restoredStocks.count) stocks from backup")
            return true
        } catch {
            print("Failed to restore from backup: \(error)")
            return false
        }
    }
}
