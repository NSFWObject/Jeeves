//
//  JeevesKit.swift
//  Jeeves
//
//  Created by Sash Zats on 3/28/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Foundation
import Argo
import Runes
import GCDWebServerOSX

// MARK: - Types

public enum RequestMethod: String {
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

public struct Request: Printable {
    public let method: RequestMethod
    public let URL: NSURL
    
    public init(method: RequestMethod = .GET, URL: NSURL) {
        self.method = method
        self.URL = URL
    }
    
    public init(filePath:String) {
        self.init(method: .GET, URL: NSURL(fileURLWithPath: filePath)!)
    }
    
    public init(URLString: String) {
        self.init(method: .GET, URL: NSURL(string: URLString)!)
    }
    
    public var description: String {
        get {
            return "\(self.method.rawValue) \(self.URL.absoluteString!)"
        }
    }
}

public enum Response {
    case Success(URL: NSURL)
    case Failure(error: ResponseErrorCode)
}

public enum ResponseErrorCode: Int {
    case NotFound = 404
    case InternalError = 500
}

public struct Route {
    public let method: RequestMethod
    public let requestPath: String
    public let responseFileURL: NSURL
    
    public init(method: RequestMethod = .GET, requestPath: String, responseFileURL: NSURL) {
        self.method = method
        self.requestPath = requestPath
        self.responseFileURL = responseFileURL
    }
}

public struct RoutesCollection {
    let routes: [Route]
    
    public init(routes: [Route]) {
        self.routes = routes
    }
    
    init?(jsonObject: AnyObject?) {
        if jsonObject == nil {
            return nil
        }
        let j = JSONValue.parse(jsonObject!)
        if let instance = RoutesCollection.decode(j) {
            self = instance
        } else {
            return nil
        }
    }
}

// MARK: - JSONDecodable

extension NSURL: JSONDecodable {
    public static func decode(j: JSONValue) -> NSURL? {
        switch j {
        case let .JSONString(s): return NSURL(fileURLWithPath: s)
        default: return nil
        }
    }
}

extension RequestMethod: JSONDecodable {
    public static func decode(j: JSONValue) -> RequestMethod? {
        switch j {
        case let .JSONString(s): return RequestMethod(rawValue: s)
        default: return nil
        }
    }
}

extension Route: JSONDecodable {
    internal static func create(method: RequestMethod = .GET)(requestPath: String)(responseFileURL: NSURL) -> Route {
        return Route(method: method, requestPath: requestPath, responseFileURL: responseFileURL)
    }
    
    public static func decode(j: JSONValue) -> Route? {
        return Route.create
            <^> j <| "method"
            <*> j <| "path"
            <*> j <| "resource"
    }
}

extension RoutesCollection: JSONDecodable {
    internal static func create(routes: [Route]) -> RoutesCollection {
        return RoutesCollection(routes: routes)
    }
    
    public static func decode(j: JSONValue) -> RoutesCollection? {
        return RoutesCollection.create
            <^> j <|| "routes"
    }
}

// MARK: - RequestMatcher

public protocol RequestMatcher {
    var resolver: URLResolver {get}
    func match(#request: Request) -> RequestMatch
}

public enum RequestMatch: Equatable  {
    case Match(URL: NSURL)
    case None
}

public func == (lhs: RequestMatch, rhs: RequestMatch) -> Bool {
    switch (lhs, rhs) {
    case (.None, .None):
        return true
    case (.Match(let URL), .Match(let URL2)):
        return URL == URL2
    default:
        return false
    }
}

extension RequestMatch: Printable {
    public var description: String {
        get {
            switch self {
            case .None:
                return "No"
            case .Match(let URL):
                return "Yes \(URL)"
            }
        }
    }
}


extension RequestMatch: BooleanType {
    public var boolValue: Bool {
        get {
            switch self {
            case .None:
                return false
            default:
                return true
            }
        }
    }
}

public func | (lhs: RequestMatch, rhs: RequestMatch) -> RequestMatch {
    return lhs ?? rhs
}

public struct DirectRequestMatcher: RequestMatcher {
    public let resolver: URLResolver
    
    public init(resolver: URLResolver) {
        self.resolver = resolver
    }
    
    public func match(#request: Request) -> RequestMatch {
        if let URL = self.resolver.localURL(request.URL) {
            return .Match(URL: URL)
        }
        return .None
    }
}

public struct IndexRequestMatcher: RequestMatcher {
    public let resolver: URLResolver
    
    public init(resolver: URLResolver) {
        self.resolver = resolver
    }
    
    public func match(#request: Request) -> RequestMatch {
        if request.URL.pathExtension == nil || request.URL.pathExtension! == "" {
            let indexURL = request.URL.URLByAppendingPathComponent("index.html")
            if let URL = self.resolver.localURL(indexURL) {
                return RequestMatch.Match(URL: URL)
            }
        }
        return RequestMatch.None
    }
}

public struct RouteRequestMatcher: RequestMatcher {
    public let resolver: URLResolver
    public let route: Route
    
    public init(resolver: URLResolver, route: Route) {
        self.resolver = resolver
        self.route = route
    }

    public func match(#request: Request) -> RequestMatch {
        if request.method == route.method {
            if let regex: NSRegularExpression = NSRegularExpression(pattern: "^\(self.route.requestPath)$", options: .CaseInsensitive, error: nil) {
                if let path = request.URL.path {
                    let isMatchingRequest = regex.numberOfMatchesInString(path, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, (path as NSString).length)) > 0
                    if isMatchingRequest {
                        let responseRequest = Request(method: .GET, URL: self.route.responseFileURL)
                        var directMatcher = DirectRequestMatcher(resolver: self.resolver)
                        return directMatcher.match(request: responseRequest)
                    }
                }
            }
        }
        return RequestMatch.None
    }
}

public struct RouteCollectionRequestMatcher: RequestMatcher {
    public let resolver: URLResolver
    public let routes: RoutesCollection
    private var routeMatchers: [RouteRequestMatcher] = []
    
    public init(routes: RoutesCollection, resolver: URLResolver) {
        self.routes = routes
        self.resolver = resolver
        self.routeMatchers = routes.routes.map{
            return RouteRequestMatcher(resolver: resolver, route: $0)
        }
    }
    
    public func match(#request: Request) -> RequestMatch {
        for routeMatcher in self.routeMatchers {
            let match = routeMatcher.match(request: request)
            if match {
                return match
            }
        }
        return RequestMatch.None
    }
}

// MARK: - RequestMapper

public struct RequestMapper {
    let matchers: [RequestMatcher]
    
    public init(matchers: [RequestMatcher]) {
        self.matchers = matchers
    }

    public func map(#request: Request) -> Response {
        for matcher in self.matchers {
            switch matcher.match(request: request) {
            case .Match(let URL):
                return Response.Success(URL: URL)
            case .None:
                break
            }
        }
        return Response.Failure(error: .NotFound)
    }
}

// MARK: - URLResolver

public protocol URLResolver {
    func localURL(requestURL: NSURL) -> NSURL?
    func dataForURL(URL: NSURL) -> NSData?
}

public struct LocalURLResolver: URLResolver {

    public init() {
    }

    public func localURL(fileURL: NSURL) -> NSURL? {
        return fileURL.checkResourceIsReachableAndReturnError(nil) ? fileURL : nil
    }
    
    public func dataForURL(URL: NSURL) -> NSData? {
        return NSData(contentsOfURL: URL)
    }
}

// MARK: - Server

public class Server {
    public let resolver: URLResolver
    public let rootURL: NSURL

    private let matchers: [RequestMatcher]
    private var engine: GCDWebServer?
    
    public var serverURL: NSURL? {
        get {
            return self.engine?.serverURL
        }
    }
    
    public init(rootURL: NSURL, resolver: URLResolver) {
        self.rootURL = rootURL
        self.resolver = resolver

        // Matchers
        var routeCollection: RoutesCollection?
        let jeevesURL = rootURL.URLByAppendingPathComponent("jeeves.json")
        if let jeevesData = resolver.dataForURL(jeevesURL) {
            if let jeevesDocument = RoutesCollection(jsonObject: NSJSONSerialization.JSONObjectWithData(jeevesData, options: .allZeros, error: nil)) {
                routeCollection = jeevesDocument
            }
        }
        routeCollection = routeCollection ?? RoutesCollection(routes: [])
        self.matchers = [
            IndexRequestMatcher(resolver: resolver),
            DirectRequestMatcher(resolver: resolver),
            RouteCollectionRequestMatcher(routes: routeCollection!, resolver: resolver)
        ]
    }
    
    public func start(error: NSErrorPointer) -> Bool {
        self.stop()
        
        let server = GCDWebServer()
        server.addHandlerWithMatchBlock({ (method: String!, url: NSURL!, headers: [NSObject : AnyObject]!, path: String!, query: [NSObject : AnyObject]!) -> GCDWebServerRequest! in
            return GCDWebServerRequest(method: method, url: url, headers: headers, path: path, query: query)
        }, processBlock: { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            return self.process(request)
        })
        let options: [String: AnyObject] = [
            "Port": 8080,
            "ServerName": "Jeeves"
        ]
        if !server.startWithOptions(options, error: error) {
            return false
        }
        self.engine = server
        return true
    }
    
    public func stop() {
        if self.engine != nil && self.engine!.running {
            self.engine?.stop()
        }
        self.engine = nil
    }
    
    // MARK: - Private
    
    private func process(originalRequest: GCDWebServerRequest) -> GCDWebServerResponse {
        if let request = self.canonicalRequest(originalRequest, baseURL: self.rootURL) {
            for matcher in self.matchers {
                switch matcher.match(request: request) {
                case .Match(let URL):
                    if let response = self.fileResponse(URL) {
                        return response
                    }
                case .None:
                    continue
                }
            }
            return self.errorResponse(404, message: "<h1>404: Not Found</h1>\(originalRequest.method) \(originalRequest.URL.absoluteString != nil ? originalRequest.URL.absoluteString! : originalRequest.URL) didn't match anything")
        }
        return self.errorResponse(500, message: "<h1>500: Internal Error</h1>Failed to process request")
    }
    
    private func canonicalRequest(request: GCDWebServerRequest, baseURL: NSURL) -> Request? {
        if let method = RequestMethod(rawValue: request.method) {
            return Request(method: method, URL: baseURL.URLByAppendingPathComponent(request.URL.path!))
        }
        return nil
    }
    
    private func errorResponse(code: Int, message: String) -> GCDWebServerResponse {
        // TODO: wrap message with default error css
        let respose = GCDWebServerDataResponse(HTML: message)
        respose.statusCode = code
        return respose
    }
    
    private func fileResponse(fileURL: NSURL) -> GCDWebServerResponse? {
//        if NSFileManager.defaultManager().fileExistsAtPath(fileURL.absoluteString, isDirectory: <#UnsafeMutablePointer<ObjCBool>#>)
        let request = NSURLRequest(URL: fileURL)
        var response: NSURLResponse?
        if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: nil) {
            if response != nil && response?.MIMEType != nil {
                // TODO: add support for custom headers
                return GCDWebServerDataResponse(data: data, contentType: response!.MIMEType!)
            }
        }
        return nil
    }
}

