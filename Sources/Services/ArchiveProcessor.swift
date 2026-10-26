import Foundation

public enum ArchiveProcessor {

    public static func extractArchive(archiveURL: URL, destinationURL: URL? = nil) throws -> URL {
        let parentDir = archiveURL.deletingLastPathComponent()
        let baseName = archiveURL.deletingPathExtension().lastPathComponent
        let outputDir = destinationURL ?? parentDir.appendingPathComponent("\(baseName) Extracted", isDirectory: true)

        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let ext = archiveURL.pathExtension.lowercased()
        let process = Process()

        if ext == "zip" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-q", "-o", archiveURL.path, "-d", outputDir.path]
        } else {
            // tar, gz, tgz, tar.gz
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            process.arguments = ["-xf", archiveURL.path, "-C", outputDir.path]
        }

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(domain: "ArchiveProcessor", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Archive extraction failed with status \(process.terminationStatus)"])
        }

        return outputDir
    }
}
