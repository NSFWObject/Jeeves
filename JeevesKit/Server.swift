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
    
    private let server = GCDWebServer()
    private let resolver: RequestMapper
    
    class func factory() -> Server {
        let urlResolver = LocalURLResolver()
        let matchers: [RequestMatcher] = [
            DirectRequestMatcher(),
            IndexRequestMatcher()
        ]
        return Server(resolver: RequestMapper(matchers:matchers, resolver: LocalURLResolver()))
    }
    
    public init(resolver: RequestMapper) {
        self.resolver = resolver
    }
}
