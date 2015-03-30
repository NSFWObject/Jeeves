//
//  MenuItem.swift
//  Jeeves
//
//  Created by Sash Zats on 3/23/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Cocoa


public class MenuManager: NSObject, NSMenuDelegate {
    
    static public let SampleServerURL = NSBundle.mainBundle().URLForResource("Server Sample", withExtension: "")!
    
    private let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    
    public weak var delegate: MenuManagerDelegate?
    
    private let recentsManager: RecentsManager
    
    public init(recentsManager: RecentsManager) {
        self.recentsManager = recentsManager
        super.init()
        self.setupMenuItem()
    }
    
    private func setupMenuItem() {
        statusItem.image = NSImage(named:"StatusItem")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }
    
    // MARK: - Private
    
    private func rebuildMenu(menu: NSMenu) {
        menu.removeAllItems()
        
        // Open
        menu.addItem(ClosurableMenuItem(title: "Open…", handler: { [weak self] in
            if self != nil {
                self!.delegate?.menuManagerDidSelectOpen(self!)
            }
            }, keyEquivalent: ""))
        
        // Open Recent
        addRecentLocations(menu)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        // Quit
        menu.addItem(ClosurableMenuItem(title: "Quit", handler: { [weak self] in
            if self != nil {
                self!.delegate?.menuManagerDidSelectQuit(self!)
            }
            }, keyEquivalent: ""))
    }
    
    private func addRecentLocations(menu: NSMenu) {
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Recent Servers", action: nil, keyEquivalent: "")

        if self.recentsManager.locations.count > 0 {
            for recentURL in self.recentsManager.locations {
                let recent = ClosurableMenuItem(title: recentURL.lastPathComponent!, handler: { [weak self] in
                    if self != nil {
                        self!.delegate?.menuManager(self!, didSelectRecentWithURL: recentURL)
                    }
                    }, keyEquivalent: "")
                menu.addItem(recent)
            }
        }
        
        // Sample server
        let sampleServer = ClosurableMenuItem(title: "Sample Server", handler: { [weak self] in
            if self != nil {
                self!.delegate?.menuManager(self!, didSelectRecentWithURL: MenuManager.SampleServerURL)
            }
            }, keyEquivalent: "")
        menu.addItem(sampleServer)
    }
    
    // MARK: - NSMenuDelegate
    
    public func menuWillOpen(_: NSMenu) {
        rebuildMenu(self.statusItem.menu!)
    }
}


class ClosurableMenuItem: NSMenuItem {
    
    var handler:() -> ()
    
    init(title: String, handler: () -> (), keyEquivalent: String) {
        self.handler = handler
        super.init(title: title, action: "action:", keyEquivalent: keyEquivalent)
        self.target = self
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func action(sender: NSMenuItem) {
        self.handler()
    }
}


public protocol MenuManagerDelegate: class {
    func menuManager(menuManager: MenuManager, didSelectRecentWithURL url: NSURL)
    func menuManagerDidSelectOpen(menuManager: MenuManager)
    func menuManagerDidSelectQuit(menuManager: MenuManager)
    func menuManagerDidSelectOptions(menuManager: MenuManager)
}