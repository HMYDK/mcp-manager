import Foundation

struct CommandResult {
    let exitCode: Int32?
    let stdout: String
    let stderr: String
    let timedOut: Bool
}

enum ProcessRunner {
    static func run(
        command: String,
        arguments: [String],
        currentDirectory: String? = nil,
        timeout: TimeInterval = 5
    ) -> CommandResult {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        if let currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory, isDirectory: true)
        }

        let semaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            semaphore.signal()
        }

        do {
            try process.run()
        } catch {
            return CommandResult(exitCode: nil, stdout: "", stderr: error.localizedDescription, timedOut: false)
        }

        let waitResult = semaphore.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
            process.terminate()
            _ = semaphore.wait(timeout: .now() + 1)
            let out = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return CommandResult(exitCode: nil, stdout: out, stderr: err, timedOut: true)
        }

        let out = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return CommandResult(exitCode: process.terminationStatus, stdout: out, stderr: err, timedOut: false)
    }

    static func which(_ command: String) -> String {
        let result = run(command: "which", arguments: [command], timeout: 2)
        guard result.exitCode == 0 else {
            return ""
        }

        return result.stdout
            .split(separator: "\n")
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
