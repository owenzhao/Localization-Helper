//
//  SourceEditorCommand.swift
//  Modify NSLocalizedString
//
//  Created by 肇鑫 on 2016-11-3.
//  Copyright © 2016年 ParusSoft.com. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
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
            else if let _ = line.range(of: Mark.multiLineCommentBeginRegex, options: .regularExpression) {
                isInMultilineComment = true
                
                continue
            }
            
//            MARK: - check if there is a valid NSLocalizedString
            guard let _ = line.range(of: Mark.validNSLocalizedStringRegex, options: .regularExpression) else { continue }
            
            //            MARK: - finally, we get a valid NSLocalizedString here
            //let says = NSLocalizedString  (  "It runs \(count) ` \\\"\"times   "   , comment: "run times")
            // get parts before NSLocalizedString
            let forepartsRange = line.range(of: Mark.forepartsRegex, options: .regularExpression)!
            let foreparts = line.substring(with: forepartsRange.lowerBound ..< line.index(forepartsRange.upperBound, offsetBy: -"NSLocalizedString".characters.count))
            
            // get key
            // get valid left double quote first
            let leftDoubleQuoteRange = line.range(of: Mark.leftDoubleQuoteRegex, options: .regularExpression)!
            
            // get valid right double quote
            let rightDoubleQuoteSearchRange = leftDoubleQuoteRange.upperBound ..< line.endIndex
            let rightDoubleQuoteRange = line.range(of: Mark.rightDoubleQuoteRegex, options: .regularExpression, range: rightDoubleQuoteSearchRange)!

            //get key
            
            let keyRange = leftDoubleQuoteRange.upperBound ..< line.index(before: rightDoubleQuoteRange.upperBound)
            let key = line.substring(with: keyRange)
            let otherRange = keyRange.upperBound ..< line.index(before: line.endIndex)
            var others = line.substring(with: otherRange)
            var lastRightParenthese = ""
            let isDoubleRightParentheses = { () -> Bool in
                if others.isEmpty { return false }
                
                return others.hasSuffix("))")
            }()

            if isDoubleRightParentheses {
                others.remove(at: others.index(before: others.endIndex))
                lastRightParenthese = ")"
            }
            let returnRange = otherRange.upperBound ..< line.endIndex
            let returnString = lastRightParenthese + line.substring(with: returnRange)
            
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
    static let multiLineCommentBeginRegex = "^\\s*\\/\\*"
    static let multiLineCommentEndRegex = "\\*\\/\\s*$"
    static let validNSLocalizedStringRegex = "^[^/]+[:=(,]\\s*NSLocalizedString\\s*\\(\\s*\".+\"\\)"
    static let forepartsRegex = "^[^/]+[:=(,]\\s*NSLocalizedString"
    static let leftDoubleQuoteRegex = "^[^/]+[:=(,]\\s*NSLocalizedString\\s*\\(\\s*\""
    static let rightDoubleQuoteRegex = "[^/]\""
}

