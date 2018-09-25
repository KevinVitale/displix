import Foundation
import CoreGraphics

public struct Display
{
    /**
     */
    public enum Error: Swift.Error {
        case error(CGError)

        /**
         */
        public var error: CGError {
            switch self {
                case .error(let error): return error
            }
        }
    }

    /// The display's system `ID`.
    public private(set) var id: CGDirectDisplayID

    /// A convenience for getting the `main` display.
    public static let main: Display = .init(id: CGMainDisplayID())
    
    /// The current display mode.
    public var mode: CGDisplayMode {
        return  CGDisplayCopyDisplayMode(id)!
    }

    /// Available display modes.
    public func modes(showLowResolutions lowRes: Bool = true) -> [CGDisplayMode] {
        let options = [
            kCGDisplayShowDuplicateLowResolutionModes : lowRes ? kCFBooleanTrue : kCFBooleanFalse
        ] as CFDictionary?
        return CGDisplayCopyAllDisplayModes(id, options) as? [CGDisplayMode] ?? []
    }

    /**
     * Creates a new `Display` for the given identifier.
     *
     * - parameter id: The identifier of the display to be accessed.
     */
    public init(id: CGDirectDisplayID) { 
        self.id = id 
    }

    /**
     */
    public static func all(_ list: List) throws -> [Display] {
        return try list.ids().map(Display.init)
    }

    /**
     */
    func set(mode: CGDisplayMode) throws {
    }
}

/**
 */
extension Display {
    func printModes(showingLowResolutions lowRes: Bool = true) {
        let displayModes =  modes(showLowResolutions: lowRes)
        print("\tID:\t\(id)")
        print("\tModes:\t\(displayModes.count)")
        print("\t-----\t-----\t------");
        print("\tIndex\tWidth\tHeight");
        print("\t-----\t-----\t------");
        for (idx, mode) in displayModes.enumerated() {
            print("\t[\(idx)] \t\(mode.width)\t\(mode.height)")
        }
    }
}

/**
 */
extension Display {
    public enum List {
        case online
        case active

        private typealias Func = ((
             _    maxDisplays: UInt32, 
             _ activeDisplays: UnsafeMutablePointer<CGDirectDisplayID>?, 
             _   displayCount: UnsafeMutablePointer<UInt32>?
             ) -> CGError)

        private var listFunc: Func {
            switch self {
                case .online: return CGGetOnlineDisplayList
                case .active: return CGGetActiveDisplayList
            }
        }

        func count() throws -> UInt32 {
            var displayCount: UInt32 = 0
            let err = listFunc(.max, nil, &displayCount)
            guard err == .success else {
                throw Error.error(err)
            }
            return displayCount
        }

        func ids() throws -> [CGDirectDisplayID] {
            let displayCount = Int(try self.count())
            var displayIDs = Array<CGDirectDisplayID>(repeating: 0, count: displayCount)
            let err = listFunc(.max, &displayIDs, nil)

            guard err == .success else {
                throw Error.error(err)
            }

            return displayIDs
        }
    }
}

let displays = try! Display.all(.online)
for (idx, display) in displays.enumerated() {
    print("DISPLAY: \(idx)")
    display.printModes()
    print()
}
