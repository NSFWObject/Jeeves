//
//  Server.swift
//  Jeeves
//
//  Created by Sash Zats on 3/28/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

//import Foundation
//import GCDWebServer
//
//
//public class Server {
//    
//    public var rootFileURL: NSURL?
//    
//    private let server = GCDWebServer()
//    
//    private var routeFile: RoutesCollection? {
//        get {
//            if self.rootFileURL == nil {
//                return nil
//            }
//            let routesURL = self.rootFileURL!.URLByAppendingPathComponent("routes.json")
//            if !routesURL.checkResourceIsReachableAndReturnError(nil) {
//                return nil
//            }
//            
//            if let routesData = NSData(contentsOfURL: routesURL), let routesObject: AnyObject = NSJSONSerialization.JSONObjectWithData(routesData, options: NSJSONReadingOptions(0), error:nil) {
//                return RoutesCollection(jsonObject: routesObject)
//            }
//            
//            return nil
//        }
//    }
//    
//    // MARK: - Lifecycle
//    
//    public init() {
//        self.setupServer()
//    }
//    
//    // MARK: - Public
//    
//    public func start(#rootFileURL: NSURL, port:UInt = 8080) {
//        self.rootFileURL = rootFileURL
//        self.server.startWithOptions([
//            GCDWebServerOption_Port: port,
//            GCDWebServerOption_ServerName: "Jeeves"
//            ], error: nil)
//        
//        NSWorkspace.sharedWorkspace().openURL(self.server.serverURL)
//    }
//    
//    public func stop() {
//        self.server.stop()
//    }
//    
//    // MARK: - Private
//    
//    private func setupServer() {
//        self.server.removeAllHandlers()
//        
//        self.server.addHandlerWithMatchBlock({ (method: String!, url: NSURL!, headers: [NSObject : AnyObject]!, path: String!, query: [NSObject : AnyObject]!) -> GCDWebServerRequest! in
//            return GCDWebServerRequest(method: method, url: url, headers: headers, path: path, query: query)
//            }, processBlock: { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
//                return self.process(request: request)
//        })
//    }
//    
//    private func process(#request: GCDWebServerRequest) -> GCDWebServerResponse {
//        if self.rootFileURL == nil {
//            let response = GCDWebServerDataResponse(HTML: "<h1>Server is not configured</h1>")
//            response.statusCode = GCDWebServerServerErrorHTTPStatusCode.HTTPStatusCode_InternalServerError.rawValue
//            return response
//        }
//        
//        if let response = self.routedResponse(forRequest: request) {
//            return response
//        }
//        
//        if let response = self.directResponse(forRequest: request) {
//            return response
//        }
//        
//        if request.URL.pathExtension == "" {
//            // TODO: implement NSCopying in GCDWebServerRequest
//            let indexURL = request.URL.URLByAppendingPathComponent("index.html")
//            let modifiedRequest = GCDWebServerRequest(method: request.method, url: indexURL, headers: request.headers, path: indexURL.path, query: request.query)
//            if let response = self.directResponse(forRequest: modifiedRequest) {
//                return response
//            }
//        }
//        
//        // FIXME: should lookup internal index, 404… pages
//        let response = GCDWebServerDataResponse(HTML: "<h1>Not Found</h1>")
//        response.statusCode = GCDWebServerClientErrorHTTPStatusCode.HTTPStatusCode_NotFound.rawValue
//        return response
//    }
//    
//    private func routedResponse(forRequest request: GCDWebServerRequest) -> GCDWebServerResponse? {
//        if let routeFile = self.routeFile {
//            for route in routeFile.routes {
//                if isRoute(route, matchingRequest: request) {
//                    let url = self.rootFileURL!.URLByAppendingPathComponent(route.resource)
//                    if url.checkResourceIsReachableAndReturnError(nil) {
//                        return GCDWebServerFileResponse(file: url.relativePath)
//                    } else {
//                        return nil
//                    }
//                }
//            }
//        }
//        return nil
//    }
//    
//    private func directResponse(forRequest request:GCDWebServerRequest) -> GCDWebServerResponse? {
//        let url = self.rootFileURL!.URLByAppendingPathComponent(request.URL.path!)
//        let manager: NSFileManager = NSFileManager.defaultManager()
//        if url.checkResourceIsReachableAndReturnError(nil) {
//            var isDirectory: ObjCBool = false
//            if manager.fileExistsAtPath(url.relativePath!, isDirectory: &isDirectory)  && !isDirectory {
//                return GCDWebServerFileResponse(file: url.relativePath)
//            }
//        }
//        return nil
//    }
//    
//    private func isRoute(route: Route, matchingRequest request: GCDWebServerRequest) -> Bool {
//        let _request = Request(method: request.method, url: request.URL)
//        return route.isMatching(_request)
//    }
//    
//}
//
//
//public class Server_2 {
//    
//    private let server = GCDWebServer()
//    private let resolver: RequestMapper
//    
//    class func factory() -> Server_2 {
//        let urlResolver = LocalURLResolver()
//        let matchers: [RequestMatcher] = [
//            DirectRequestMatcher(),
//            IndexRequestMatcher()
//        ]
//        return Server_2(resolver: RequestMapper(matchers:matchers, resolver: LocalURLResolver()))
//    }
//    
//    public init(resolver: RequestMapper) {
//        self.resolver = resolver
//    }
//}
