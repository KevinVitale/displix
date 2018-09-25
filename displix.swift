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
    public func modes(showingLowResolutions lowRes: Bool) -> [CGDisplayMode] {
        let options = [ kCGDisplayShowDuplicateLowResolutionModes : kCFBooleanTrue ] as CFDictionary?
        return CGDisplayCopyAllDisplayModes(id, lowRes ? options : nil) as? [CGDisplayMode] ?? []
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
        var err: CGError
        var config: CGDisplayConfigRef? = nil

        err = CGBeginDisplayConfiguration(&config);
        guard err == .success else {
            throw Error.error(err)
        }

        err = CGConfigureDisplayWithDisplayMode(config, id, mode, nil);
        guard err == .success else {
            throw Error.error(err)
        }

        err = CGCompleteDisplayConfiguration(config, .forSession);
        guard err == .success else {
            throw Error.error(err)
        }
    }
}

/**
 */
extension Display {
    func printModes(showingLowResolutions lowRes: Bool) {
        let displayModes =  modes(showingLowResolutions: lowRes)
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

public struct Settings {
    public var showLowRes: Bool = false
    public var display: Display = .main
    public var modeIndex: Int   = -1

    public static func parseCommandLineArguments(displays: [Display]) -> Settings {
        var settings = Settings()

        var opt: Int32 = 0
        repeat {
            opt = getopt(CommandLine.argc, CommandLine.unsafeArgv, "d:m:a")
            guard opt >= 0 else { break }

            switch Unicode.Scalar(Int(opt)) {
                case "a": 
                    settings.showLowRes = true
                case "d": 
                    let idx = Int(atoi(optarg))
                    if idx < displays.count {
                        settings.display = displays[idx]
                    }
                case "m": 
                    settings.modeIndex = Int(atoi(optarg))
                default: ()
            }
        } while opt != -1

        return settings
    }
}

let displays = try! Display.all(.online)
let settings: Settings = .parseCommandLineArguments(displays: displays)

guard settings.modeIndex < 0 else {
    let modes = settings.display.modes(showingLowResolutions: settings.showLowRes)
    guard settings.modeIndex < modes.count else {
        settings.display.printModes(showingLowResolutions: settings.showLowRes)
        exit(0)
    }
    let mode = modes[settings.modeIndex]
    print("W: \(mode.width); H: \(mode.height)")
    do {
        try settings.display.set(mode: mode)
    } catch {
        print(error)
    }
    exit(0)
}

displays.forEach {
    $0.printModes(showingLowResolutions: settings.showLowRes)
}

