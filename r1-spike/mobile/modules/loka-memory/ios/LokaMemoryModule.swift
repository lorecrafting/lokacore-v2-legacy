import ExpoModulesCore

// OS-visible physical memory in bytes; below the installed RAM size.
public final class LokaMemoryModule: Module {
  public func definition() -> ModuleDefinition {
    Name("LokaMemory")
    Function("physicalMemory") { () -> [String: String] in
      ["api": "ProcessInfo.processInfo.physicalMemory", "bytes": String(ProcessInfo.processInfo.physicalMemory)]
    }
  }
}
