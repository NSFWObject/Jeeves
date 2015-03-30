//
//  RecentsManager.swift
//  Jeeves
//
//  Created by Sash Zats on 3/25/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Foundation

public class RecentsManager {

    public var locations: [NSURL]
    
    init() {
        self.locations = RecentsManager.defaultsToUrls()
    }
    
    // MARK: - Public
    
    public func add(location: NSURL) {
        var locations = self.locations
        locations.insert(location, atIndex: 0)
        while locations.count > 5 {
            locations.removeLast()
        }
        RecentsManager.urlsToDefaults(locations)
        self.locations = locations
    }
    
    public func remove(location: NSURL) {
        self.locations = self.locations.filter{ $0 != location }
        RecentsManager.urlsToDefaults(self.locations)
    }
    
    public func reset() {
        self.locations = []
        RecentsManager.urlsToDefaults(self.locations)
    }

    // MARK: Persistance

    static let defaultsKey = "com.Jeeves.Recents"

    static private func urlsToDefaults(urls: [NSURL]) {
        let locations = map(urls){ return $0.relativePath! }
        NSUserDefaults.standardUserDefaults().setObject(locations, forKey: RecentsManager.defaultsKey)
    }
    
    static private func defaultsToUrls() -> [NSURL] {
        let locations = NSUserDefaults.standardUserDefaults().objectForKey(RecentsManager.defaultsKey) as? [String] ?? []
        return map(locations) {
            return NSURL(fileURLWithPath: $0)!
        }
    }
}