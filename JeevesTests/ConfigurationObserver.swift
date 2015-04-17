import Quick
import Nimble
import Jeeves

class ConfigurationObserver: QuickSpec {
    override func spec() {
        
        let bundle = NSBundle(forClass: ConfigurationObserver.self)
        println(bundle.bundleURL)
        "Hello".writeToURL(bundle.bundleURL.URLByAppendingPathComponent("Mooo"), atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        /*
        1. Add file
        2. Edit file
        3. Remove file
         */
        describe("") {
            it("") {
                
            }
        }
    }
}
