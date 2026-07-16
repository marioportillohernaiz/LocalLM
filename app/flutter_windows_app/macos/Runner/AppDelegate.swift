import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let backendHealthURL = URL(string: "http://127.0.0.1:8000/health")!
  private let ollamaTagsURL = URL(string: "http://127.0.0.1:11434/api/tags")!
  private var backendProcess: Process?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    startBackendIfNeeded()
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    if let process = backendProcess, process.isRunning {
      process.terminate()
    }
  }

  private func startBackendIfNeeded() {
    if isReachable(backendHealthURL) {
      return
    }

    guard let backendExecutable = locateBackendExecutable() else {
      NSLog("LocalLM: backend executable not found next to the app bundle; skipping auto-start")
      return
    }

    ensureOllamaRunning()

    let dataDir = applicationSupportDirectory(appending: "LocalLM/data")
    let logDir = libraryLogsDirectory(appending: "LocalLM")
    try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)

    let logFile = logDir.appendingPathComponent("backend.log")
    FileManager.default.createFile(atPath: logFile.path, contents: nil)
    let logHandle = try? FileHandle(forWritingTo: logFile)

    let process = Process()
    process.executableURL = backendExecutable
    process.environment = ProcessInfo.processInfo.environment.merging(
      ["LOCALLM_DATA_DIR": dataDir.path],
      uniquingKeysWith: { _, new in new }
    )
    process.standardOutput = logHandle
    process.standardError = logHandle

    do {
      try process.run()
      backendProcess = process
    } catch {
      NSLog("LocalLM: failed to start backend: \(error)")
    }
  }

  private func ensureOllamaRunning() {
    if isReachable(ollamaTagsURL) {
      return
    }

    let ollamaAppURL = URL(fileURLWithPath: "/Applications/Ollama.app")
    if FileManager.default.fileExists(atPath: ollamaAppURL.path) {
      let configuration = NSWorkspace.OpenConfiguration()
      configuration.activates = false
      configuration.hides = true
      NSWorkspace.shared.openApplication(at: ollamaAppURL, configuration: configuration)
    }
  }

  private func locateBackendExecutable() -> URL? {
    let appBundleURL = URL(fileURLWithPath: Bundle.main.bundlePath)
    let candidate = appBundleURL
      .deletingLastPathComponent()
      .appendingPathComponent("backend/locallm-backend")
    guard FileManager.default.isExecutableFile(atPath: candidate.path) else {
      return nil
    }
    return candidate
  }

  private func applicationSupportDirectory(appending path: String) -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent(path)
  }

  private func libraryLogsDirectory(appending path: String) -> URL {
    let base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
    return base.appendingPathComponent(path)
  }

  private func isReachable(_ url: URL, timeout: TimeInterval = 1.5) -> Bool {
    var request = URLRequest(url: url)
    request.timeoutInterval = timeout
    let semaphore = DispatchSemaphore(value: 0)
    var reachable = false

    let task = URLSession.shared.dataTask(with: request) { _, response, _ in
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
        reachable = true
      }
      semaphore.signal()
    }
    task.resume()
    _ = semaphore.wait(timeout: .now() + timeout + 0.5)
    return reachable
  }
}
