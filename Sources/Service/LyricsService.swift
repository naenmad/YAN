import Foundation

public actor LyricsService {
    public static let shared = LyricsService()
    
    private var cache: [String: [LyricLine]] = [:]
    
    private init() {}
    
    public func fetchLyrics(artist: String, title: String) async -> [LyricLine] {
        let cleanTitle = cleanTitleString(title)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = "\(cleanArtist.lowercased()) - \(cleanTitle.lowercased())"
        
        if let cached = cache[cacheKey] {
            return cached
        }
        
        guard !cleanTitle.isEmpty else { return [] }
        
        var components = URLComponents(string: "https://lrclib.net/api/get")
        components?.queryItems = [
            URLQueryItem(name: "artist_name", value: cleanArtist),
            URLQueryItem(name: "track_name", value: cleanTitle)
        ]
        
        guard let url = components?.url else { return [] }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4.0
            request.setValue("YAN-Notch-Utility/0.1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let synced = json["syncedLyrics"] as? String {
                let lines = parseLRC(synced)
                if !lines.isEmpty {
                    cache[cacheKey] = lines
                    return lines
                }
            }
            
            // Fallback ke plain lyrics
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let plain = json["plainLyrics"] as? String {
                let rawLines = plain.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                let lines = rawLines.enumerated().map { LyricLine(time: Double($0.offset) * 4.0, text: $0.element) }
                cache[cacheKey] = lines
                return lines
            }
        } catch {
            // Jaringan gagal atau timeout, abaikan
        }
        
        return []
    }
    
    public func currentLyric(from lines: [LyricLine], at time: TimeInterval) -> String? {
        guard !lines.isEmpty else { return nil }
        
        // Cari baris lirik dengan timestamp <= waktu saat ini yang paling akhir
        var activeText: String? = nil
        for line in lines {
            if line.time <= time {
                activeText = line.text
            } else {
                break
            }
        }
        return activeText
    }
    
    private func parseLRC(_ lrc: String) -> [LyricLine] {
        var result: [LyricLine] = []
        let rawLines = lrc.components(separatedBy: "\n")
        
        let pattern = #"\[(\d{2}):(\d{2}(?:\.\d{2,3})?)\](.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            
            if let match = regex.firstMatch(in: trimmed, range: range) {
                if let minRange = Range(match.range(at: 1), in: trimmed),
                   let secRange = Range(match.range(at: 2), in: trimmed),
                   let textRange = Range(match.range(at: 3), in: trimmed) {
                    let minutes = Double(trimmed[minRange]) ?? 0
                    let seconds = Double(trimmed[secRange]) ?? 0
                    let text = String(trimmed[textRange]).trimmingCharacters(in: .whitespaces)
                    
                    if !text.isEmpty {
                        let totalTime = (minutes * 60) + seconds
                        result.append(LyricLine(time: totalTime, text: text))
                    }
                }
            }
        }
        
        return result.sorted { $0.time < $1.time }
    }
    
    private func cleanTitleString(_ title: String) -> String {
        // Hapus keterangan seperti (Official Video), [Remastered], dll.
        var cleaned = title
        if let regex = try? NSRegularExpression(pattern: #"\((?:official|video|audio|lyrics|remastered|feat\.?|ft\.?).*?\)"#, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
        }
        if let regex = try? NSRegularExpression(pattern: #"\[(?:official|video|audio|lyrics|remastered|feat\.?|ft\.?).*?\]"#, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
