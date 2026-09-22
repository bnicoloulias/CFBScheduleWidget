import Foundation
import ImageIO
import OSLog
import UniformTypeIdentifiers

/// Downloads team logos and keeps small, render-ready copies on disk.
///
/// A widget cannot load images asynchronously while rendering, so logos have to
/// be resolved to `Data` during timeline generation and carried in the entry.
/// They are downsampled first: full-size ESPN logos are 500px PNGs, and a
/// timeline entry holding a dozen of those is far too heavy.
actor LogoLoader {
    static let shared = LogoLoader()

    /// Comfortably larger than the biggest on-screen logo, for Retina.
    static let maxPixelSize = 128

    private let logger = Logger(subsystem: "com.bobbynicoloulias.CollegeFootballSchedule", category: "LogoLoader")
    private let session: URLSession
    private var inMemory: [String: Data] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns downsampled PNG data for each team id, skipping any that fail.
    func logos(teamIDs: some Sequence<String>) async -> [String: Data] {
        var result: [String: Data] = [:]
        for teamID in Set(teamIDs) {
            if let data = await logo(teamID: teamID) {
                result[teamID] = data
            }
        }
        return result
    }

    func logo(teamID: String) async -> Data? {
        if let cached = inMemory[teamID] { return cached }

        if let fileURL = fileURL(teamID: teamID), let data = try? Data(contentsOf: fileURL) {
            inMemory[teamID] = data
            return data
        }

        guard let url = Team.logoURL(teamID: teamID) else { return nil }

        do {
            let (data, _) = try await session.data(from: url)
            guard let thumbnail = Self.downsampled(data, maxPixelSize: Self.maxPixelSize) else { return nil }

            inMemory[teamID] = thumbnail
            if let fileURL = fileURL(teamID: teamID) {
                try? thumbnail.write(to: fileURL, options: .atomic)
            }
            return thumbnail
        } catch {
            // A missing logo degrades to a placeholder glyph; nothing to report.
            logger.debug(
                "Logo fetch failed for \(teamID, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func fileURL(teamID: String) -> URL? {
        guard
            let directory = try? FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        else { return nil }

        let logos = directory.appending(path: "TeamLogos", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: logos, withIntermediateDirectories: true)
        return logos.appending(path: "\(teamID).png")
    }

    /// Re-encodes to a thumbnail PNG via ImageIO, which decodes only what it
    /// needs rather than the full-size bitmap.
    private static func downsampled(_ data: Data, maxPixelSize: Int) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output, UTType.png.identifier as CFString, 1, nil
            )
        else { return nil }

        CGImageDestinationAddImage(destination, thumbnail, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
