//
//  Server.swift
//  Jeeves
//
//  Created by Sash Zats on 3/28/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Foundation
import GCDWebServer

public class Server {
    private var server: GCDWebServer
    
    public init() {
        self.server = GCDWebServer()
    }    
}