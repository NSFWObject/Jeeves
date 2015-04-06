import Quick
import Nimble
import Jeeves


struct FSI {
    let name: String
    var children: [FSI]
    var data: NSData?
    init(name: String, children: [FSI] = [], data: NSData? = nil) {
        self.name = name
        self.children = children
        self.data = data
    }
    func member(named name: String) -> FSI? {
        for item in self.children {
            if item.name == name {
                return item
            }
        }
        return nil
    }
    func localURLForPath(path: String) -> NSURL? {
        var item = self
        var pathComponentns = path.componentsSeparatedByString("/")
        var workingPathComponents = pathComponentns
        if item.name == pathComponentns.first {
            workingPathComponents.removeAtIndex(0)
        } else {
            return nil
        }
        while workingPathComponents.count > 0 {
            if item.children.count == 0 {
                return nil
            }
            if let child = item.member(named: workingPathComponents.first!) {
                item = child
            } else {
                return nil
            }
            workingPathComponents.removeAtIndex(0)
        }
        
        return NSURL(fileURLWithPath: (pathComponentns as NSArray).componentsJoinedByString("/"))
    }
}

struct TestResolver: URLResolver {
    var root: FSI!

    init() {
    }
    
    func localURL(fileURL: NSURL) -> NSURL? {
        return fileURL.path != nil ? self.root.localURLForPath(fileURL.path!) : nil
    }
    
    func dataForURL(URL: NSURL) -> NSData? {
        if let url = self.localURL(URL) {
            return NSData(contentsOfURL: url)
        }
        return nil
    }
}

class JeevesKitTests: QuickSpec {
    override func spec() {
        var root: FSI!
        
        beforeSuite {
            root = FSI(name: "", children:[
                FSI(name: ".zsh"),
                FSI(name: "Pictures", children: [
                    FSI(name: "cat.jpg"),
                    FSI(name: "logo.png")
                    ]),
                FSI(name: "Documents", children: [
                    FSI(name: "readme.md"),
                    FSI(name: "Prices.xlsx"),
                    FSI(name: "index.html")
                    ]),
                FSI(name: "Downloads", children: [
                    FSI(name: "archive.zip"),
                    FSI(name: "Secret", children: [
                        FSI(name: "data.dat"),
                        FSI(name: "crash")
                        ])
                    ])
                ])
        }
        
        describe("TestResolver") {
            it("Sanity") {
                var resolver = TestResolver()
                resolver.root = root
                expect(resolver.localURL(NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)).to(equal(NSURL(fileURLWithPath: "/Pictures/cat.jpg")!))
                expect(resolver.localURL(NSURL(fileURLWithPath: "/Downloads/Secret/crash")!)).to(equal(NSURL(fileURLWithPath: "/Downloads/Secret/crash")!))
                expect(resolver.localURL(NSURL(fileURLWithPath: "/.zsh")!)).to(equal(NSURL(fileURLWithPath: "/.zsh")!))
            }
            
        }
        
        describe("RequestMatcher") {
            var testResolver: TestResolver!
            beforeSuite {
                testResolver = TestResolver()
                testResolver.root = root
            }
            
            describe("Strict") {
                var matcher: DirectRequestMatcher!
                beforeEach{
                    matcher = DirectRequestMatcher(resolver: testResolver)
                }
                
                it("should match URL path if there is a corresponding file on the disk") {
                    let request = Request(method: .GET, URL: NSURL(string: "http://google.com/Pictures/cat.jpg")!)
                    switch matcher.match(request: request) {
                    case .Match(let URL):
                        expect(URL).to(equal(NSURL(fileURLWithPath: "/Pictures/cat.jpg")))
                    case .None:
                        fail();
                    }
                }

                it("should not match URL path if there is no corresponding file on the disk") {
                    let request = Request(URL: NSURL(string: "http://google.com/Pictures/dog.jpg")!)
                    expect(matcher.match(request: request)).to(equal(RequestMatch.None))
                }
                
                it("should ignore base URL for valid paths") {
                    let request1 = Request(URL: NSURL(string: "http://google.com/Pictures/cat.jpg")!)
                    let request2 = Request(URL: NSURL(string: "http://yahoo.com/Pictures/cat.jpg")!)
                    expect(matcher.match(request: request1)).to(equal(RequestMatch.Match(URL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)))
                    expect(matcher.match(request: request2)).to(equal(RequestMatch.Match(URL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)))
                    
                }
                
                pending("Not sure what to do when matched path leads to a folder") {
                    it("should not match path with no extension if it's a folder on the disk") {
                        let request = Request(URL: NSURL(string: "http://google.com/Pictures/")!)
                        expect(matcher.match(request: request)).to(equal(RequestMatch.None))
                    }
                }
            }
            
            pending("Compiler being a dick at the moment, crashes inside of IndexRequestMatcher.match") {
                describe("Index") {
                    var matcher: IndexRequestMatcher!
                    beforeEach{
                        matcher = IndexRequestMatcher(resolver: testResolver)
                    }
                    
                    it("should match URL path appending index.html if there is a corresponding file on the disk") {
                        let request = Request(URLString: "http://example.com/Documents")
                        let match: RequestMatch = .Match(URL: NSURL(fileURLWithPath: "/Documents/index.html")!)
                        expect(matcher.match(request: request)).to(equal(match))
                    }

                    it("should not match URL path appending index.html if there is no corresponding file on the disk") {
                        let request = Request(URLString: "http://example.com/Pictures")
                        expect(matcher.match(request: request)).to(equal(.None))
                    }
                    
                    it("should not append index.html to URL path if it contains extension") {
                        let request = Request(URLString: "http://example.com/Pictures/cat.jpg")
                        expect(matcher.match(request: request)).to(equal(.None))
                    }
                }
            }

            describe("RouteRequestMatcher") {
                it("should match if method, path & response URL are matching request") {
                    let route = Route(method: .POST, requestPath: "/cat", responseFileURL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)
                    let matcher = RouteRequestMatcher(resolver: testResolver, route: route)
                    let request = Request(method: .POST, URL: NSURL(string: "http://example.com/cat")!)
                    let match: RequestMatch = .Match(URL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)
                    expect(matcher.match(request: request)).to(equal(match))
                }

                it("should match if method, path regex & response URL are matching request") {
                    let route = Route(method: .POST, requestPath: "/c.t", responseFileURL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)
                    let matcher = RouteRequestMatcher(resolver: testResolver, route: route)
                    let request = Request(method: .POST, URL: NSURL(string: "http://example.com/cat")!)
                    let match: RequestMatch = .Match(URL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)
                    expect(matcher.match(request: request)).to(equal(match))
                }

                it("should not match if only method and path are matching request") {
                    let route = Route(method: .POST, requestPath: "/cat", responseFileURL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)
                    let matcher = RouteRequestMatcher(resolver: testResolver, route: route)
                    let request = Request(method: .POST, URL: NSURL(string: "http://example.com/cats")!)
                    expect(matcher.match(request: request)).to(equal(RequestMatch.None))
                }

                it("should not match if only method and URL are matching request") {
                    let route = Route(method: .POST, requestPath: "/cat", responseFileURL: NSURL(fileURLWithPath: "/Pictures/dog.jpg")!)
                    let matcher = RouteRequestMatcher(resolver: testResolver, route: route)
                    let request = Request(method: .POST, URL: NSURL(string: "http://example.com/cat")!)
                    let match: RequestMatch = .Match(URL: NSURL(fileURLWithPath: "/Pictures/dog.jpg")!)
                    expect(matcher.match(request: request)).to(equal(RequestMatch.None))
                }

                it("should not match if only path and URL are matching request") {
                    let route = Route(method: .PUT, requestPath: "/cat", responseFileURL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!)
                    let matcher = RouteRequestMatcher(resolver: testResolver, route: route)
                    let request = Request(method: .POST, URL: NSURL(string: "http://example.com/cat")!)
                    expect(matcher.match(request: request)).to(equal(RequestMatch.None))
                }
            }
            
            describe("RouteCollectionRequestMatcher") {
                it("should match the request if one of the route request matchers is matching") {
                    let routeCollection = RoutesCollection(routes: [
                        Route(method: .PUT, requestPath: "/cat", responseFileURL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!),
                        Route(method: .PATCH, requestPath: "/prices", responseFileURL: NSURL(fileURLWithPath: "/Documents/Prices.xlxs")!)
                    ])
                    let matcher = RouteCollectionRequestMatcher(routes: routeCollection, resolver: testResolver)
                    let request = Request(method: .PATCH, URL: NSURL(string: "http://example.com/prices")!)
                    expect(matcher.match(request: request)).to(equal(RequestMatch.None))
                    
                }

                it("should not match the request if none of the route request matchers are matching") {
                    let routeCollection = RoutesCollection(routes: [
                        Route(method: .PUT, requestPath: "/cat", responseFileURL: NSURL(fileURLWithPath: "/Pictures/cat.jpg")!),
                        Route(method: .PATCH, requestPath: "/prices", responseFileURL: NSURL(fileURLWithPath: "/Documents/Prices.xlxs")!)
                    ])
                    let matcher = RouteCollectionRequestMatcher(routes: routeCollection, resolver: testResolver)
                    let request = Request(method: .GET, URL: NSURL(string: "http://example.com/prices")!)
                    expect(matcher.match(request: request)).to(equal(RequestMatch.None))
                }
            }
            
        }
    }
}
