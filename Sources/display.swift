import CoreFoundation
import CoreGraphics

public struct Display: Identifiable {
  /// The display's underlying system `ID`.
  public private(set) var id: CGDirectDisplayID
  
  /// The current display mode.
  public var mode: CGDisplayMode {
    return CGDisplayCopyDisplayMode(id)!
  }
  
  /**
   Returns the availabe modes for this display.
   
   - parameter includeAll: Forces the system to return all available modes on the display that are known by the system.
   - returns: The list of this display's modes.
   */
  public func availableModes(includeAll: Bool) -> [CGDisplayMode] {
    let options = [
      kCGDisplayShowDuplicateLowResolutionModes : kCFBooleanTrue
    ] as CFDictionary?
    
    // Query the displays modes (with the `ID` and possible additional options)
    let displaysModes = CGDisplayCopyAllDisplayModes(
      id,
      includeAll ? options : nil
    ) as? [CGDisplayMode] ?? []
    
    return displaysModes.sorted(by: {
      $0.ioDisplayModeID < $1.ioDisplayModeID
    })
  }
  
  /**
   Changes this display's mode.
   */
  func set(mode: CGDisplayMode) throws {
    var err: CGError
    var config: CGDisplayConfigRef? = nil
    
    err = CGBeginDisplayConfiguration(&config);
    guard err == .success else {
      throw Error(wrappedValue: err)
    }
    
    err = CGConfigureDisplayWithDisplayMode(config, id, mode, nil);
    guard err == .success else {
      throw Error(wrappedValue: err)
    }
    
    err = CGCompleteDisplayConfiguration(config, .forSession);
    guard err == .success else {
      throw Error(wrappedValue: err)
    }
  }
  
  public static func all(_ list: List) throws -> [Display] {
    return try list.ids().map(Display.init)
  }
  
  /// Main (primary) display, as reported by the system.
  public static let main: Display = .init(id: CGMainDisplayID())
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
        throw Error(wrappedValue: err)
      }
      return displayCount
    }
    
    func ids() throws -> [CGDirectDisplayID] {
      let displayCount = Int(try self.count())
      var displayIDs = Array<CGDirectDisplayID>(repeating: 0, count: displayCount)
      let err = listFunc(.max, &displayIDs, nil)
      
      guard err == .success else {
        throw Error(wrappedValue: err)
      }
      
      return displayIDs
    }
  }
}

extension Display {
  /**
   Converts `CGError` into a _Swift_ `Error`.
   */
  @propertyWrapper
  public struct Error: Swift.Error, CustomStringConvertible {
    public init(wrappedValue: CoreGraphics.CGError) {
      self.wrappedValue = wrappedValue
    }
    
    public let wrappedValue: CoreGraphics.CGError
    
    public var description: String {
      switch wrappedValue {
        case .success:
          return "success"
        case .failure:
          return "failure"
        case .illegalArgument:
          return "illegal argument"
        case .invalidConnection:
          return "invalid connection"
        case .invalidContext:
          return "invalid context"
        case .cannotComplete:
          return "cannot complete"
        case .notImplemented:
          return "not implemented"
        case .rangeCheck:
          return "range check"
        case .typeCheck:
          return "type check"
        case .invalidOperation:
          return "invalid operation"
        case .noneAvailable:
          return "none available"
        @unknown default:
          return "unknown"
      }
    }
  }
}
