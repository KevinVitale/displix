import Foundation

extension Display {
  func printModes(showingLowResolutions lowRes: Bool) {
    let displayModes =  availableModes(includeAll: lowRes)
    print("\tID:\t\(id)")
    print("\tCount: \(displayModes.count)")
    print("\t-----\t-----\t------");
    print("\tMode:\t#\(mode.ioDisplayModeID)\t\(mode.width)\t\(mode.height)\t(\(mode.refreshRate) Hz)")
    print("\t-----\t-----\t------");
    print("\tIndex\tWidth\tHeight");
    print("\t-----\t-----\t------");
    for (idx, mode) in displayModes.enumerated() {
      print("\t[\(idx)] \t\(mode.width)\t\(mode.height)\t(\(mode.refreshRate) Hz)")
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
  let modes = settings.display.availableModes(includeAll: settings.showLowRes)
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

for (idx, display) in displays.enumerated() {
  print("DISPLAY: \(idx)")
  display.printModes(showingLowResolutions: settings.showLowRes)
  print("")
}
