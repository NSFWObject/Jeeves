//
//  MenuItem.swift
//  Jeeves
//
//  Created by Sash Zats on 4/6/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Cocoa


class MenuItem: NSObject, NSMenuDelegate {
    
    private let item = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    private let menu: NSMenu = NSMenu()
    
    var serverFolderName: String?
    
    override init() {
        super.init()
        self.item.menu = self.menu
        self.item.image = NSImage(named: "StatusItem")
        self.menu.delegate = self
    }
    
    private func rebuildMenu() {
        // Status
        let isServing = self.serverFolderName != nil
        if isServing {
            let statusLine = NSMenuItem(title: "Jeeves is Serving \"\(self.serverFolderName!)\"", action: "openServerFolderMenuAction", keyEquivalent: "")
            self.menu.addItem(statusLine)
            // Stop
            let stop = NSMenuItem(title: "Stop Jeeves", action: "stopMenuAction", keyEquivalent: "")
            self.menu.addItem(stop)
            
            // ---
            self.menu.addItem(NSMenuItem.separatorItem())
        } else {
            let statusLine = NSMenuItem(title: "Jeeves is Resting", action: nil, keyEquivalent: "")
            self.menu.addItem(statusLine)
        }
        
        // Open
        let open = NSMenuItem(title: "Open…", action: "openMenuAction", keyEquivalent: "")
        self.menu.addItem(open)
        
        // ---
        self.menu.addItem(NSMenuItem.separatorItem())
        
        // Quit
        let quit = NSMenuItem(title: "Quit", action: "quitMenuAction", keyEquivalent: "")
        self.menu.addItem(quit)
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(menu: NSMenu) {
        menu.removeAllItems()
        rebuildMenu()
    }
    
}