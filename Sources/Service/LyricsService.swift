import Foundation

public actor LyricsService {
    public static let shared = LyricsService()
    
    private var cache: [String: [LyricLine]] = [:]
    
    private init() {}
    
    public func fetchLyrics(artist: String, title: String) async -> [LyricLine] {
        let (cleanArtist, cleanTitle) = cleanSearchTerms(artist: artist, title: title)
        let cacheKey = "\(cleanArtist.lowercased()) - \(cleanTitle.lowercased())"
        
        if let cached = cache[cacheKey], !cached.isEmpty {
            return cached
        }
        
        guard !cleanTitle.isEmpty else { return [] }
        
        // 1. Coba exact match ke /api/get jika artis tersedia
        if !cleanArtist.isEmpty {
            if let lines = await queryGetEndpoint(artist: cleanArtist, title: cleanTitle) {
                cache[cacheKey] = lines
                return lines
            }
        }
        
        // 2. Coba search endpoint /api/search?q=
        let searchQuery = "\(cleanArtist) \(cleanTitle)".trimmingCharacters(in: .whitespacesAndNewlines)
        if let lines = await querySearchEndpoint(query: searchQuery) {
            cache[cacheKey] = lines
            return lines
        }
        
        // 3. Jika masih gagal, coba search hanya dengan judul lagu
        if !cleanArtist.isEmpty {
            if let lines = await querySearchEndpoint(query: cleanTitle) {
                cache[cacheKey] = lines
                return lines
            }
        }
        
        return []
    }
    
    private func queryGetEndpoint(artist: String, title: String) async -> [LyricLine]? {
        var components = URLComponents(string: "https://lrclib.net/api/get")
        components?.queryItems = [
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "track_name", value: title)
        ]
        
        guard let url = components?.url else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4.0
            request.setValue("YAN-Notch-Utility/0.1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            return parseLyricsPayload(data)
        } catch {
            return nil
        }
    }
    
    private func querySearchEndpoint(query: String) async -> [LyricLine]? {
        guard !query.isEmpty else { return nil }
        var components = URLComponents(string: "https://lrclib.net/api/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        
        guard let url = components?.url else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4.0
            request.setValue("YAN-Notch-Utility/0.1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let first = array.first {
                return parseLyricsDict(first)
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func parseLyricsPayload(_ data: Data) -> [LyricLine]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return parseLyricsDict(json)
    }
    
    private func parseLyricsDict(_ dict: [String: Any]) -> [LyricLine]? {
        // Prioritas 1: Synced Lyrics (LRC timestamp)
        if let synced = dict["syncedLyrics"] as? String, !synced.isEmpty {
            let lines = parseLRC(synced)
            if !lines.isEmpty {
                return subdivideLongLines(lines)
            }
        }
        
        // Prioritas 2: Plain Lyrics
        if let plain = dict["plainLyrics"] as? String, !plain.isEmpty {
            let rawLines = plain.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            let lines = rawLines.enumerated().map {
                LyricLine(time: Double($0.offset) * 4.0, text: $0.element)
            }
            if !lines.isEmpty {
                return subdivideLongLines(lines)
            }
        }
        
        return nil
    }
    
    // MARK: - Smart Subdivision: Memecah Baris Lirik Panjang Menjadi Frase Ritmik
    
    public func subdivideLongLines(_ lines: [LyricLine], maxChars: Int = 28) -> [LyricLine] {
        guard !lines.isEmpty else { return [] }
        var result: [LyricLine] = []
        
        for i in 0..<lines.count {
            let current = lines[i]
            let duration: Double
            if i + 1 < lines.count {
                duration = max(0.5, lines[i + 1].time - current.time)
            } else {
                duration = 4.5
            }
            
            let chunks = subdivideLine(text: current.text, startTime: current.time, duration: duration, maxChars: maxChars)
            result.append(contentsOf: chunks)
        }
        
        return result
    }
    
    private func subdivideLine(text: String, startTime: Double, duration: Double, maxChars: Int = 28) -> [LyricLine] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxChars, duration >= 2.5 else {
            return [LyricLine(time: startTime, text: trimmed)]
        }
        
        let words = trimmed.split(separator: " ").map(String.init)
        guard words.count >= 2 else {
            return [LyricLine(time: startTime, text: trimmed)]
        }
        
        // Batasi durasi bernyanyi efektif jika ada jeda instrumental panjang sebelum baris berikutnya
        let maxSingingDuration = max(3.5, Double(trimmed.count) * 0.25)
        let effectiveDuration = min(duration, maxSingingDuration)
        
        // Berapa jumlah potongan ideal (k)
        var k = Int(ceil(Double(trimmed.count) / Double(maxChars)))
        // Pastikan setiap potongan punya minimal durasi 1.4 detik agar nyaman dibaca
        k = min(k, max(1, Int(floor(effectiveDuration / 1.4))))
        guard k > 1 else {
            return [LyricLine(time: startTime, text: trimmed)]
        }
        
        var chunks: [String] = []
        let targetChars = Double(trimmed.count) / Double(k)
        var currentWords: [String] = []
        var currentLength = 0
        
        for (i, word) in words.enumerated() {
            let remainingWords = words.count - i
            let remainingChunksNeeded = k - chunks.count
            
            currentWords.append(word)
            currentLength += word.count + (currentWords.count > 1 ? 1 : 0)
            
            let hasPunctuation = word.hasSuffix(",") || word.hasSuffix(";") || word.hasSuffix("-") || word.hasSuffix("...")
            let reachedTarget = Double(currentLength) >= targetChars * 0.85
            let mustSplit = remainingWords <= remainingChunksNeeded
            
            if (reachedTarget || hasPunctuation || mustSplit) && chunks.count < k - 1 && !currentWords.isEmpty {
                chunks.append(currentWords.joined(separator: " "))
                currentWords = []
                currentLength = 0
            }
        }
        
        if !currentWords.isEmpty {
            chunks.append(currentWords.joined(separator: " "))
        }
        
        let totalChars = max(1, chunks.reduce(0) { $0 + $1.count })
        var result: [LyricLine] = []
        var accumulatedChars = 0
        
        for (idx, chunk) in chunks.enumerated() {
            let chunkStartTime: Double
            if idx == 0 {
                chunkStartTime = startTime
            } else {
                let ratio = Double(accumulatedChars) / Double(totalChars)
                chunkStartTime = startTime + (ratio * effectiveDuration)
            }
            result.append(LyricLine(time: chunkStartTime, text: chunk))
            accumulatedChars += chunk.count
        }
        
        return result
    }
    
    public func currentLyric(from lines: [LyricLine], at time: TimeInterval) -> String? {
        guard !lines.isEmpty else { return nil }
        
        // Jika masih di intro sebelum lirik pertama
        if let first = lines.first, time < first.time {
            return first.text
        }
        
        var activeText: String? = lines.first?.text
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
    
    private func cleanSearchTerms(artist: String, title: String) -> (artist: String, title: String) {
        var cleanTitle = title
        var cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Hapus notification badge seperti "(6) "
        if let badgeRegex = try? NSRegularExpression(pattern: #"^\(\d+\)\s*"#) {
            cleanTitle = badgeRegex.stringByReplacingMatches(in: cleanTitle, range: NSRange(location: 0, length: cleanTitle.utf16.count), withTemplate: "")
        }
        
        // Hapus akhiran "- YouTube"
        if let ytRegex = try? NSRegularExpression(pattern: #"\s*-\s*YouTube$"#, options: .caseInsensitive) {
            cleanTitle = ytRegex.stringByReplacingMatches(in: cleanTitle, range: NSRange(location: 0, length: cleanTitle.utf16.count), withTemplate: "")
        }
        
        // Hapus tag seperti (Official Video), [Official Audio], dll.
        let tagsPattern = #"(?i)\s*[\(\[][^\)\]]*(?:official|video|audio|lyrics|music|remastered|feat\.?|ft\.?|hd|4k)[^\)\]]*[\)\]]"#
        if let tagRegex = try? NSRegularExpression(pattern: tagsPattern) {
            cleanTitle = tagRegex.stringByReplacingMatches(in: cleanTitle, range: NSRange(location: 0, length: cleanTitle.utf16.count), withTemplate: "")
        }
        
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Jika artist adalah placeholder atau kosong, pisahkan jika judul berformat "Artis - Judul"
        let isGenericArtist = cleanArtist.isEmpty ||
                              cleanArtist.contains("YouTube") ||
                              cleanArtist.contains("Media Player") ||
                              cleanArtist.contains("Browser") ||
                              cleanArtist.contains("Video")
        
        if isGenericArtist && cleanTitle.contains(" - ") {
            let parts = cleanTitle.components(separatedBy: " - ")
            if parts.count >= 2 {
                cleanArtist = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                cleanTitle = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return (cleanArtist, cleanTitle)
    }
}
