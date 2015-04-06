//
//  MenuItem.swift
//  Jeeves
//
//  Created by Sash Zats on 3/23/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Cocoa


public class MenuManager: NSObject, NSMenuDelegate {
    
    static public let SampleServerURL = NSBundle.mainBundle().URLForResource("Sample", withExtension: "")!
    
    public weak var delegate: MenuManagerDelegate?
    public var selectedURL: NSURL? = nil{
        didSet {
            if let url = self.selectedURL {
                self.statusItem.toolTip = "Jeeves is serving \"\(url.lastPathComponent!)\""
                self.enabled = true
            } else {
                self.statusItem.toolTip = "Jeeves is resting"
                self.enabled = false
            }

        }
    }
    
    private var enabled: Bool = false {
        didSet {
            self.statusItem.image = NSImage(named: self.enabled ? "StatusItem-On" : "StatusItem")
        }
    }
    
    private let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    private let recentsManager: RecentsManager
    
    public init(recentsManager: RecentsManager) {
        self.recentsManager = recentsManager
        super.init()
        self.setupMenuItem()
    }
    
    // MARK: - Private
    
    private func setupMenuItem() {
        statusItem.image = NSImage(named:"StatusItem")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }
    
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
            for (index, recentURL) in enumerate(self.recentsManager.locations) {
                let recent = ClosurableMenuItem(title: recentURL.lastPathComponent!, handler: { [weak self] in
                    if self != nil {
                        self!.delegate?.menuManager(self!, didSelectRecentWithURL: recentURL)
                    }
                    let recentMenuItem = menu.itemArray[index] as! NSMenuItem
                    recentMenuItem.state = NSOnState
                }, keyEquivalent: "")
                recent.state = recentURL == self.selectedURL ? NSOnState : NSOffState
                menu.addItem(recent)
            }
        }
        
        // Sample server
        let sampleServer = ClosurableMenuItem(title: "Sample Server", handler: { [weak self] in
            if self != nil {
                self!.delegate?.menuManager(self!, didSelectRecentWithURL: MenuManager.SampleServerURL)
            }
        }, keyEquivalent: "")
        sampleServer.state = self.selectedURL == MenuManager.SampleServerURL ? NSOnState : NSOffState
        menu.addItem(sampleServer)
    }
    
    // MARK: - NSMenuDelegate
    
    public func menuWillOpen(_: NSMenu) {
        self.statusItem.image?.setTemplate(true)
        rebuildMenu(self.statusItem.menu!)
    }
    
    public func menuDidClose(menu: NSMenu) {
        if self.enabled {
            self.statusItem.image?.setTemplate(false)
        } else {
            self.statusItem.image?.setTemplate(true)
        }
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