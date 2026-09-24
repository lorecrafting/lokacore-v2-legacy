import ExpoModulesCore

// A2 local module: OS-visible physical memory, evidence files the M1 pulls, and real process death.
public final class LokaMemoryModule: Module {
  public func definition() -> ModuleDefinition {
    Name("LokaMemory")
    Function("physicalMemory") { () -> [String: String] in
      ["api": "ProcessInfo.processInfo.physicalMemory", "bytes": String(ProcessInfo.processInfo.physicalMemory)]
    }
    // Documents/ in the app data container; `devicectl device copy from` reads it for a development-signed app.
    Function("writeFile") { (name: String, base64: String) throws in
      let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      try Data(base64Encoded: base64)!.write(to: dir.appendingPathComponent(name), options: .atomic)
    }
    // SIGABRT: the process dies and iOS writes a crash report whose native frames the dSYM symbolicates.
    Function("kill") { () -> Void in
      abort()
    }
  }
}
