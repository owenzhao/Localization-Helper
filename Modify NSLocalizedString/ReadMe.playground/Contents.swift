import Foundation
//: # Below code works
//: ## `NSLocalizedString` with single \\(foo)
let count = 10
let says = NSLocalizedString("It runs \(count) times", comment: "run times")
// let says = String.localizedStringWithFormat(NSLocalizedString("It runs %@ times", comment: "run times"), String(count))
//: ## `NSLocalizedString` with multiple \\(foo)s
let days = 3
let hours = 5
let newSays = NSLocalizedString("I have been here for \(days) days, \(hours) hours.", comment: "stay time")
// let newSays = String.localizedStringWithFormat(NSLocalizedString("I have been here for %@ days, %@ hours.", comment: "stay time"), String(days), String(hours))
//: # Known issues
//: 1. /* */ in one single line is not supported.
//: 2. Multiple `NSLocalizedStrings`in one line is not supported as Apple suggest to use on `NSLocalizedString` instead of composite them together.