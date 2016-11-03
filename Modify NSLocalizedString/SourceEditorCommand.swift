//
//  SourceEditorCommand.swift
//  Modify NSLocalizedString
//
//  Created by 肇鑫 on 2016-11-3.
//  Copyright © 2016年 ParusSoft.com. All rights reserved.
//

import Foundation
import XcodeKit

let localizedString = "NSLocalizedString"
let localizedStringRegex = "\\WNSLocalizedString\\W"

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        
        func isValidMarkInRange(stringToSearch s:String, searchMark mark:String, searchOptions options:String.CompareOptions = [], searchDirection direction:Direction, searchBound bound:String.Index) -> Bool {
            func rangeFrom(direction:Direction, bound:String.Index) -> Range<String.Index> {
                switch direction {
                case .left:
                    return s.startIndex ..< bound
                case .right:
                    return bound ..< s.endIndex
                }
            }
            
            func boundFrom(direction:Direction, range:Range<String.Index>) -> String.Index {
                switch direction {
                case .left:
                    return range.lowerBound
                case .right:
                    return range.upperBound
                }
            }
            
            let searchRange:Range<String.Index> = rangeFrom(direction: direction, bound: bound)
            
            guard let range = s.range(of: mark, options: options, range:searchRange) else { return false}
            
            switch mark {
            case let x where x == Mark.singleLineComment || x == Mark.multiLineCommentBeginRegex:
                return !isValidMarkInRange(stringToSearch: s, searchMark: Mark.doubleQuote, searchOptions: .backwards, searchDirection: .left, searchBound: range.lowerBound)
            case let x where x == Mark.doubleQuote:
                let doubleQuoteRegex = try! NSRegularExpression(pattern: Mark.doubleQuote, options: [])
                let invalidDoubleQuoteRegex = try! NSRegularExpression(pattern: Mark.invalidDoubleQuoteRegex, options: [])
                let nssearchRange:NSRange
                if direction == .left {
                    nssearchRange = NSRangeFromString(s.substring(with: searchRange))
                }
                else {
                    let substring = s.substring(with: searchRange)
                    let deltaNSRange = NSRangeFromString(substring)
                    nssearchRange = NSMakeRange(s.characters.count - substring.characters.count, deltaNSRange.length)
                }
                //                let nsrange = (s as NSString).range(of: mark, options: options, range: nssearchRange)
                let validDoubleQuote = doubleQuoteRegex.numberOfMatches(in: s, options: [], range: nssearchRange) - invalidDoubleQuoteRegex.numberOfMatches(in: s, options: [], range: nssearchRange)
                
                return validDoubleQuote % 2 == 1
            case let x where x == Mark.backlitQuote:
                let bRange = s.range(of: Mark.backlitQuoteRegex, options: .regularExpression, range: searchRange)!
                
                return bRange.upperBound == searchRange.upperBound
            case let x where x == Mark.localizedStringWithFormatRegex || x == Mark.nsLocalizedStringWithFormatRegex:
                let parts = "\\s*\\(\\s*"
                let lRange = s.range(of: mark + parts, options: .regularExpression, range: searchRange)!
                
                return lRange.upperBound == searchRange.upperBound
            default:
                fatalError()
            }
        }
        
        func formatAndArgumentsFrom(key:String, others:String, returnString:String) -> String? { //(key:String, comment:String) -> String in
            var ranges:[Range<String.Index>] = []
            let rex = "\\\\\\([a-z,A-Z,_]\\w*\\)"
            var s = key
            var range = key.startIndex ..< key.endIndex
            while let r = key.range(of:rex, options:.regularExpression, range:range) {
                ranges.append(r)
                if r.upperBound < key.endIndex {
                    range = r.upperBound ..< key.endIndex
                }
                else {
                    break
                }
            }
            
            guard !ranges.isEmpty else { return nil }
            
            var variables = [String]()
            ranges.reversed().forEach {
                let vr = s.index($0.lowerBound, offsetBy: 2) ..< s.index($0.upperBound, offsetBy: -1)
                let v = s.substring(with:vr)
                variables.append("String(\(v))")
                s.replaceSubrange($0, with:"%@")
            }
            
            return s + others + ", " + variables.reversed().joined(separator:", ") + ")" + returnString
        }
        
        var lineIndices:[Int] = []
        var isInMultilineComment = false
        
        for index in 0 ..< invocation.buffer.lines.count {
            let line = invocation.buffer.lines[index] as! String
            
            if isInMultilineComment {
                // check if multiline comment stops in this line
                if let _ = line.range(of: Mark.multiLineCommentEndRegex, options: .regularExpression) {
                    isInMultilineComment = false
                }
                
                continue
            }
            else if isValidMarkInRange(stringToSearch: line, searchMark: Mark.multiLineCommentBeginRegex, searchOptions: .regularExpression, searchDirection: .left, searchBound: line.endIndex) {
                isInMultilineComment = true
                
                continue
            }
            
            // check if it is a rough valid NSLocalizedString, not "blablaNSLocalizedString" or "NSLocalizedStringblalba"
            guard let _ = line.range(of: localizedStringRegex, options: .regularExpression) else { continue }
            
            let lsRange = line.range(of: localizedString)!
            
            // if contains, check if it is a valid NSLocalizedString
            // check if there is a valid single line comment on the left
            guard !isValidMarkInRange(stringToSearch: line, searchMark: Mark.singleLineComment, searchDirection: .left, searchBound: lsRange.lowerBound) else { continue }
            
            // check if there is a valid left double quote on the left
            guard !isValidMarkInRange(stringToSearch: line, searchMark: Mark.doubleQuote, searchDirection: .left, searchBound: lsRange.lowerBound) else { continue }
            
            // check if there is a valid left ` on the left
            guard !isValidMarkInRange(stringToSearch: line, searchMark: Mark.backlitQuote, searchDirection: .left, searchBound: lsRange.lowerBound) else { continue }
            
            // check if there is a valid localizedStringWithFormat on the left
            guard !isValidMarkInRange(stringToSearch: line, searchMark: Mark.localizedStringWithFormatRegex, searchOptions: .regularExpression, searchDirection: .left, searchBound: lsRange.lowerBound) else { continue }
            guard !isValidMarkInRange(stringToSearch: line, searchMark: Mark.nsLocalizedStringWithFormatRegex, searchOptions: .regularExpression, searchDirection: .left, searchBound: lsRange.lowerBound) else { continue }
            
            //            MARK: - finally, we get a valid NSLocalizedString here
            //let says = NSLocalizedString  (  "It runs \(count) ` \\\"\"times   "   , comment: "run times")
            // get parts before NSLocalizedString
            let fpRange = line.startIndex ..< lsRange.lowerBound
            let foreparts = line.substring(with: fpRange)
            // get key
            // get valid left double quote first
            let keySearchRange = lsRange.upperBound ..< line.endIndex
            let leftDoubleQuoteRegex = "\\s*\\(\\s*\""
            let leftDoubleQuoteRange = line.range(of: leftDoubleQuoteRegex, options: .regularExpression, range: keySearchRange)!
            
            // get valid right double quote
            var rightDoubleQuoteSearchRange = leftDoubleQuoteRange.upperBound ..< line.endIndex
            var rightDoubleQuoteRange:Range<String.Index>?
            
            while let range = line.range(of: "\"", range: rightDoubleQuoteSearchRange) {
                rightDoubleQuoteRange = range
                
                let checkRange = line.index(before: range.lowerBound) ..< range.upperBound
                if line.substring(with: checkRange) != "\\\"" { break }
                
                rightDoubleQuoteSearchRange = range.upperBound ..< line.endIndex
            }
            
            guard rightDoubleQuoteRange != nil else { continue }
            
            let keyRange = leftDoubleQuoteRange.upperBound ..< line.index(before: rightDoubleQuoteRange!.upperBound)
            let key = line.substring(with: keyRange)
            let otherRange = keyRange.upperBound ..< line.index(before: line.endIndex)
            let others = line.substring(with: otherRange)
            let returnRange = otherRange.upperBound ..< line.endIndex
            let returnString = line.substring(with: returnRange)
            
            guard let lastparts = formatAndArgumentsFrom(key: key, others: others, returnString: returnString) else { continue } // not variables
            
            let newLine = foreparts + "String.localizedStringWithFormat(NSLocalizedString(\"" + lastparts
            lineIndices.append(index)
            invocation.buffer.lines[index] = newLine
        }
        
        if !lineIndices.isEmpty {
            let updateSelections:[XCSourceTextRange] = lineIndices.map {
                let selection = XCSourceTextRange()
                selection.start = XCSourceTextPosition(line: $0, column: 0)
                selection.end = XCSourceTextPosition(line: $0, column: 0)
                
                return selection
            }
            
            invocation.buffer.selections.setArray(updateSelections)
        }
        
        completionHandler(nil)
    }
}

enum Direction {
    case left, right
}

struct Mark {
    static let singleLineComment = "//"
    // TODO: the regular exprees assuming "/*" always at the beginning of a line, which may not be true. For example: "blabla /*"
    static let multiLineCommentBeginRegex = "^ *\\/\\*"
    // TODO: the regular express assuming `*/` always at the end of a line, which may not be true. For example: "*/ blabla"
    static let multiLineCommentEndRegex = "\\*\\/.*$"
    static let doubleQuote = "\""
    static let invalidDoubleQuoteRegex = "\\\\\""
    static let backlitQuote = "`"
    static let backlitQuoteRegex = "`\\w*"
    static let localizedStringWithFormatRegex = "String\\.localizedStringWithFormat"
    static let nsLocalizedStringWithFormatRegex = "NSString\\.localizedStringWithFormat"
}

