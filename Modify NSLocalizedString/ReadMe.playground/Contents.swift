import Foundation
//: # Below code works
//: ## 1. `NSLocalizedString` with single \\(foo)
let count = 10
let says = NSLocalizedString("It runs \(count) times", comment: "run times")
//: ## 2. `NSLocalizedString` with multiple \\(foo)s
let days = 3
let hours = 5
let newSays = NSLocalizedString("I have been here for \(days) days, \(hours) hours.", comment: "stay time")
//: ## 3. in function
func putString(a:String="", _ s:String) {
    print(s)
}
putString(a:"", NSLocalizedString("It runs \(count) times", comment: "run times"))
//: ## 4. in closure
let p = { (a:String) -> () in
    print(a)
}

p(NSLocalizedString("It runs \(count) times", comment: "run times"))
//: # Known issues
//: 1. /* */ in one single line is not supported.
//: 2. Multiple `NSLocalizedStrings`in one line is not supported as Apple suggest to use on `NSLocalizedString` instead of composite them together.
