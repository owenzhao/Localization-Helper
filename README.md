# Localization-Helper
## How to use
1. Clone or download the project. Code sign both targets, `Localization Helper` and `Modify NSLocalizedString` with your own id.
2. Choose `Modify NSLocalizedString` as you current working target and click run.
3. In the Xcode that pops up, choose a project other than this project.
4. In the opening source editor, click Xcode menu, File->Modify LocalizationString->Modify LocalizationStrings.

## Below code works
### `NSLocalizedString` with single \\(foo)

```swift
let count = 10
let says = NSLocalizedString("It runs \(count) times", comment: "run times")
// let says = String.localizedStringWithFormat(NSLocalizedString("It runs %@ times", comment: "run times"), String(count))
```

### `NSLocalizedString` with multiple \\(foo)s

```swift
let days = 3
let hours = 5
let newSays = NSLocalizedString("I have been here for \(days) days, \(hours) hours.", comment: "stay time")
// let newSays = String.localizedStringWithFormat(NSLocalizedString("I have been here for %@ days, %@ hours.", comment: "stay time"), String(days), String(hours))
```

## Known issues
1. /* */ in one single line is not supported.
2. Multiple `NSLocalizedStrings`in one line is not supported as Apple suggests using one `NSLocalizedString` instead of compositing them together.


