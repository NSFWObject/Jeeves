//: Playground - noun: a place where people can play

import Foundation

class TempNotifier {
    
    var onChange: (Int) -> Void = {t in }
    var currentTemp = 72
    
    init() {
        // 1.
        onChange = { [unowned self] temp in
            self.currentTemp = temp
        }

        // 2.
        onChange = {[unowned self] temp in
            self.tempHandler(temp)
        }
        
        // 3.
        unowned let s = self
        onChange = s.tempHandler

    }
    
    deinit {
        println("deinit")
    }
    
    private func tempHandler(temp: Int) {
        self.currentTemp = temp
    }
}

var tN: TempNotifier? = TempNotifier()
tN = nil

