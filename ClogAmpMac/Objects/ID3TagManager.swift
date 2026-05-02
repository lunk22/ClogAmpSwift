import Foundation
import AVFoundation

class ID3TagManager {

    private let fileURL: URL

    init?(_ path: String) {
        guard !path.isEmpty else { return nil }
        self.fileURL = URL(fileURLWithPath: path)
    }

    // MARK: - Internal types

    private struct RawFrame {
        var id: String
        var flags: (UInt8, UInt8) = (0, 0)
        var data: Data
    }

    private struct ParsedTag {
        var versionMajor: UInt8
        var versionMinor: UInt8
        var flags: UInt8
        var tagSize: Int  // content byte count from header, excludes 10-byte header itself
        var frames: [RawFrame]
    }

    // MARK: - Synchsafe integers

    private func decodeSynchsafe(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) -> Int {
        return (Int(a) << 21) | (Int(b) << 14) | (Int(c) << 7) | Int(d)
    }

    private func encodeSynchsafe(_ n: Int) -> [UInt8] {
        return [
            UInt8((n >> 21) & 0x7F),
            UInt8((n >> 14) & 0x7F),
            UInt8((n >> 7)  & 0x7F),
            UInt8(n         & 0x7F)
        ]
    }

    // MARK: - ID3v2.2 → v2.3 frame ID upgrade table

    private static let v22ToV23: [String: String] = [
        "BUF": "RBUF", "CNT": "PCNT", "COM": "COMM", "CRA": "AENC",
        "ETC": "ETCO", "EQU": "EQUA", "GEO": "GEOB", "IPL": "IPLS",
        "LNK": "LINK", "MCI": "MCDI", "MLL": "MLLT", "PIC": "APIC",
        "POP": "POPM", "REV": "RVRB", "RVA": "RVAD", "SLT": "SYLT",
        "STC": "SYTC", "TAL": "TALB", "TBP": "TBPM", "TCM": "TCOM",
        "TCO": "TCON", "TCP": "TCMP", "TCR": "TCOP", "TDA": "TDAT",
        "TDY": "TDLY", "TEN": "TENC", "TFT": "TFLT", "TIM": "TIME",
        "TKE": "TKEY", "TLA": "TLAN", "TLE": "TLEN", "TMT": "TMED",
        "TOA": "TOPE", "TOF": "TOFN", "TOL": "TOLY", "TOR": "TORY",
        "TOT": "TOAL", "TP1": "TPE1", "TP2": "TPE2", "TP3": "TPE3",
        "TP4": "TPE4", "TPA": "TPOS", "TPB": "TPUB", "TRC": "TSRC",
        "TRD": "TRDA", "TRK": "TRCK", "TSI": "TSIZ", "TSS": "TSSE",
        "TT1": "TIT1", "TT2": "TIT2", "TT3": "TIT3", "TXT": "TEXT",
        "TXX": "TXXX", "TYE": "TYER", "UFI": "UFID", "ULT": "USLT",
        "WAF": "WOAF", "WAR": "WOAR", "WAS": "WOAS", "WCM": "WCOM",
        "WCP": "WCOP", "WPB": "WPUB", "WXX": "WXXX",
    ]

    // MARK: - Unsynchronisation

    // ID3v2 §2.4: when the unsync flag is set, every 0xFF 0x00 pair in the
    // encoded content has a spurious 0x00 inserted.  Remove them to recover
    // the original bytes.
    private func deUnsync(_ data: Data) -> Data {
        var result = Data()
        result.reserveCapacity(data.count)
        var i = 0
        while i < data.count {
            let byte = data[i]
            result.append(byte)
            if byte == 0xFF, i + 1 < data.count, data[i + 1] == 0x00 {
                i += 2  // absorb the padding 0x00
            } else {
                i += 1
            }
        }
        return result
    }

    // MARK: - Parsing

    private func parseTag(from data: Data) -> ParsedTag? {
        guard data.count >= 10,
              data[0] == 0x49, data[1] == 0x44, data[2] == 0x33  // "ID3"
        else { return nil }

        let major = data[3]
        let minor = data[4]
        let flags = data[5]
        guard major == 2 || major == 3 || major == 4 else { return nil }

        // tagSize is the encoded byte count (excludes the 10-byte header).
        // Keep the encoded value so we know exactly where the audio data starts.
        let tagSize = decodeSynchsafe(data[6], data[7], data[8], data[9])
        let tagEnd  = min(10 + tagSize, data.count)

        // When the unsync flag (bit 7) is set the entire tag content has been
        // unsynchronised.  De-unsync into a fresh, zero-based buffer before
        // parsing so frame headers and data are read correctly.
        let tagUnsync = (flags & 0x80) != 0
        let content: Data = tagUnsync
            ? deUnsync(data.subdata(in: 10..<tagEnd))
            : data.subdata(in: 10..<tagEnd)

        var frames: [RawFrame] = []

        if major == 2 {
            // ID3v2.2: 6-byte frame headers (3-byte ID + 3-byte big-endian size, no flags).
            // Upgrade frame IDs to v2.3 equivalents and treat the tag as v2.3 going forward.
            var off = 0
            while off + 6 <= content.count {
                guard content[off] != 0 else { break }

                let idBytes = [content[off], content[off+1], content[off+2]]
                guard let rawID = String(bytes: idBytes, encoding: .isoLatin1),
                      rawID.unicodeScalars.allSatisfy({ ($0.value >= 0x30 && $0.value <= 0x39) ||
                                                        ($0.value >= 0x41 && $0.value <= 0x5A) })
                else { break }

                let frameSize = (Int(content[off+3]) << 16) | (Int(content[off+4]) << 8) | Int(content[off+5])
                off += 6
                guard frameSize >= 0, off + frameSize <= content.count else { break }

                let id        = ID3TagManager.v22ToV23[rawID] ?? rawID
                let frameData = content.subdata(in: off..<(off + frameSize))
                frames.append(RawFrame(id: id, data: frameData))
                off += frameSize
            }
            // Return as v2.3 so any subsequent write uses v2.3 headers
            return ParsedTag(versionMajor: 3, versionMinor: 0, flags: 0,
                             tagSize: tagSize, frames: frames)
        }

        // ID3v2.3 / v2.4: 10-byte frame headers
        var off = 0
        while off + 10 <= content.count {
            guard content[off] != 0 else { break }

            let idBytes = [content[off], content[off+1], content[off+2], content[off+3]]
            guard let id = String(bytes: idBytes, encoding: .isoLatin1),
                  id.unicodeScalars.allSatisfy({ ($0.value >= 0x30 && $0.value <= 0x39) ||
                                                ($0.value >= 0x41 && $0.value <= 0x5A) })
            else { break }

            let frameSize: Int
            if major == 4 {
                frameSize = decodeSynchsafe(content[off+4], content[off+5], content[off+6], content[off+7])
            } else {
                frameSize = (Int(content[off+4]) << 24) | (Int(content[off+5]) << 16) |
                            (Int(content[off+6]) << 8)  |  Int(content[off+7])
            }

            let flag0 = content[off+8], flag1 = content[off+9]
            off += 10
            guard frameSize >= 0, off + frameSize <= content.count else { break }

            let frameData = content.subdata(in: off..<(off + frameSize))
            frames.append(RawFrame(id: id, flags: (flag0, flag1), data: frameData))
            off += frameSize
        }

        return ParsedTag(versionMajor: major, versionMinor: minor, flags: flags & 0x7F,
                         tagSize: tagSize, frames: frames)
    }

    // MARK: - Serialization

    private func computeFramesSize(_ frames: [RawFrame]) -> Int {
        frames.reduce(0) { $0 + 10 + $1.data.count }
    }

    private func serializeTag(_ tag: ParsedTag, padding: Int) -> Data {
        let totalContent = computeFramesSize(tag.frames) + padding
        var result = Data(capacity: 10 + totalContent)

        result.append(contentsOf: [0x49, 0x44, 0x33])           // "ID3"
        result.append(tag.versionMajor)
        result.append(tag.versionMinor)
        result.append(tag.flags & 0x7F)                          // clear unsync flag
        result.append(contentsOf: encodeSynchsafe(totalContent))

        for frame in tag.frames {
            guard frame.id.count == 4,
                  let idData = frame.id.data(using: .isoLatin1)
            else { continue }

            result.append(contentsOf: idData)

            let sz = frame.data.count
            if tag.versionMajor == 4 {
                result.append(contentsOf: encodeSynchsafe(sz))
            } else {
                result.append(contentsOf: [
                    UInt8((sz >> 24) & 0xFF), UInt8((sz >> 16) & 0xFF),
                    UInt8((sz >> 8)  & 0xFF), UInt8(sz          & 0xFF)
                ])
            }
            result.append(contentsOf: [frame.flags.0, frame.flags.1])
            result.append(frame.data)
        }

        result.append(Data(repeating: 0, count: padding))
        return result
    }

    // MARK: - File I/O

    private func modifyTag(_ modifier: (inout ParsedTag) -> Void) {
        guard let fileData = try? Data(contentsOf: fileURL) else { return }

        var tag: ParsedTag
        let originalTagTotalSize: Int

        if let existing = parseTag(from: fileData) {
            tag = existing
            originalTagTotalSize = 10 + existing.tagSize
        } else {
            tag = ParsedTag(versionMajor: 3, versionMinor: 0, flags: 0, tagSize: 0, frames: [])
            originalTagTotalSize = 0
        }

        modifier(&tag)

        let framesSize       = computeFramesSize(tag.frames)
        let originalContent  = max(0, originalTagTotalSize - 10)
        let padding          = originalContent >= framesSize ? originalContent - framesSize : 512

        var output = serializeTag(tag, padding: padding)
        if originalTagTotalSize < fileData.count {
            output.append(fileData.subdata(in: originalTagTotalSize..<fileData.count))
        }
        try? output.write(to: fileURL)
    }

    // MARK: - Text decoding

    private func decodeText(_ data: Data, enc: UInt8) -> String {
        switch enc {
        case 0:  return String(data: data, encoding: .isoLatin1) ?? ""
        case 1:  return String(data: data, encoding: .utf16) ?? ""
        case 2:  return String(data: data, encoding: .utf16BigEndian) ?? ""
        default: return String(data: data, encoding: .utf8) ?? ""
        }
    }

    // Splits data at first null terminator; returns (text bytes, bytes after null).
    // data must have zero-based indices (use Data(slice) before calling if needed).
    private func splitAtNull(_ data: Data, enc: UInt8) -> (Data, Data) {
        let wide = (enc == 1 || enc == 2)
        if wide {
            var i = 0
            while i + 1 < data.count {
                if data[i] == 0 && data[i+1] == 0 {
                    let text = i > 0 ? data.subdata(in: 0..<i) : Data()
                    let rest = i+2 < data.count ? data.subdata(in: (i+2)..<data.count) : Data()
                    return (text, rest)
                }
                i += 2
            }
        } else {
            for i in 0..<data.count {
                if data[i] == 0 {
                    let text = i > 0 ? data.subdata(in: 0..<i) : Data()
                    let rest = i+1 < data.count ? data.subdata(in: (i+1)..<data.count) : Data()
                    return (text, rest)
                }
            }
        }
        return (data, Data())
    }

    private func stripTrailingNulls(_ data: Data, enc: UInt8) -> Data {
        var d = data
        let wide = (enc == 1 || enc == 2)
        if wide {
            while d.count >= 2 {
                let last2 = d.subdata(in: (d.count-2)..<d.count)
                if last2[0] == 0 && last2[1] == 0 { d = d.subdata(in: 0..<(d.count-2)) }
                else { break }
            }
        } else {
            while d.last == 0 { d = d.subdata(in: 0..<(d.count-1)) }
        }
        return d
    }

    // MARK: - Text frame helpers (TIT2, TPE1, TBPM)

    private func readTextFrame(_ frame: RawFrame) -> String {
        guard !frame.data.isEmpty else { return "" }
        let enc = frame.data[0]
        let raw = Data(frame.data.dropFirst())
        return decodeText(stripTrailingNulls(raw, enc: enc), enc: enc)
    }

    private func makeTextFrame(id: String, text: String) -> RawFrame {
        var data = Data()
        data.append(0x03)                           // UTF-8 encoding
        data.append(contentsOf: text.utf8)
        return RawFrame(id: id, data: data)
    }

    // MARK: - TXXX helpers

    private func readTXXX(_ frame: RawFrame) -> (description: String, text: String)? {
        guard frame.data.count >= 2 else { return nil }
        let enc  = frame.data[0]
        let body = Data(frame.data.dropFirst())
        let (descData, textData) = splitAtNull(body, enc: enc)
        return (decodeText(descData, enc: enc), decodeText(textData, enc: enc))
    }

    private func makeTXXXFrame(description: String, text: String) -> RawFrame {
        var data = Data()
        data.append(0x00)  // ISO-8859-1
        data.append(contentsOf: (description.data(using: .isoLatin1) ?? Data()))
        data.append(0x00)  // null terminator
        data.append(contentsOf: (text.data(using: .isoLatin1) ?? text.data(using: .utf8) ?? Data()))
        return RawFrame(id: "TXXX", data: data)
    }

    // MARK: - SYLT helpers

    // Returns the raw position binary stored after the SYLT frame header.
    private func readSYLTPayload(_ frame: RawFrame) -> (description: String, rawData: Data)? {
        guard frame.data.count >= 6 else { return nil }
        let enc  = frame.data[0]
        // Skip: enc(1) + lang(3) + timestampFormat(1) + contentType(1) = 6 bytes
        let body = Data(frame.data.dropFirst(6))
        let (descData, rawData) = splitAtNull(body, enc: enc)
        return (decodeText(descData, enc: enc), rawData)
    }

    private func makeSYLTFrame(description: String, rawData: Data) -> RawFrame {
        var data = Data()
        data.append(0x00)                                   // ISO-8859-1 encoding
        data.append(contentsOf: "eng".utf8)                 // language
        data.append(0x02)                                   // timestamp format: milliseconds (ID3TSF_MS)
        data.append(0x03)                                   // content type: movement (ID3CT_MOVEMENT)
        data.append(contentsOf: (description.data(using: .isoLatin1) ?? Data()))
        data.append(0x00)                                   // null terminator
        data.append(rawData)
        return RawFrame(id: "SYLT", data: data)
    }

    // MARK: - SYLT binary format (custom ClogAmp position encoding)
    //
    // Each entry: [name\tcomment\0][uint32 big-endian milliseconds]

    private func parseSYLTBinary(_ data: Data) -> String {
        var result = ""
        var offset = 0

        while offset < data.count {
            var strEnd = offset
            while strEnd < data.count && data[strEnd] != 0 { strEnd += 1 }
            guard strEnd < data.count else { break }

            let str    = String(data: data.subdata(in: offset..<strEnd), encoding: .utf8) ?? ""
            offset     = strEnd + 1

            guard offset + 4 <= data.count else { break }
            let ms: UInt32 = (UInt32(data[offset])   << 24) | (UInt32(data[offset+1]) << 16) |
                             (UInt32(data[offset+2]) << 8)  |  UInt32(data[offset+3])
            offset += 4

            let parts   = str.components(separatedBy: "\t")
            let name    = parts.count > 0 ? parts[0] : ""
            let comment: String
            let jumpTo:  String
            if parts.count == 2 {
                comment = parts[1]; jumpTo = ""
            } else if parts.count >= 3 {
                jumpTo = parts[1]; comment = parts[2]
            } else {
                comment = ""; jumpTo = ""
            }

            if !result.isEmpty { result += "$LS" }
            result += "\(name)$CS\(comment)$CS\(jumpTo)$CS\(ms)"
        }

        return result
    }

    private func buildSYLTBinary(_ positionString: String) -> Data {
        guard !positionString.isEmpty else { return Data() }
        var data = Data()

        for line in positionString.components(separatedBy: "$LS") {
            let cells = line.components(separatedBy: "$CS")
            guard cells.count >= 4 else { continue }

            let name    = cells[0]
            let comment = cells[1]
            // cells[2] is jumpTo — not stored in binary (matching original id3lib implementation)
            let ms      = UInt32(cells[3]) ?? 0

            data.append(contentsOf: ("\(name)\t\(comment)").utf8)
            data.append(0x00)
            data.append(contentsOf: [
                UInt8((ms >> 24) & 0xFF), UInt8((ms >> 16) & 0xFF),
                UInt8((ms >> 8)  & 0xFF), UInt8(ms          & 0xFF)
            ])
        }

        return data
    }

    // MARK: - Duration

    private func readDuration() -> Int {
        let asset    = AVURLAsset(url: fileURL)
        let duration = asset.duration
        guard duration.isValid, !duration.isIndefinite else { return 0 }
        return Int(CMTimeGetSeconds(duration))
    }

    // MARK: - Public read API

    func readBasicInfo() -> [String: Any]? {
        guard let fileData = try? Data(contentsOf: fileURL) else { return nil }
        var result: [String: Any] = [:]

        result["duration"]     = 0
        result["hasPositions"] = false

        guard let tag = parseTag(from: fileData) else {
            result["duration"] = readDuration()
            return result
        }

        var tlenMs: Int? = nil

        for frame in tag.frames {
            switch frame.id {
            case "TIT2":
                result["title"] = readTextFrame(frame)
            case "TPE1":
                result["artist"] = readTextFrame(frame)
            case "TLEN":
                tlenMs = Int(readTextFrame(frame))
            case "TBPM":
                result["bpm"] = Int(readTextFrame(frame)) ?? 0
            case "TXXX":
                if let (desc, text) = readTXXX(frame) {
                    switch desc {
                    case "CloggingLevel":     result["cloggingLevel"] = text
                    case "LastTempo":          result["lastTempo"] = text
                    case "CloggingBeatsWait": result["waitBeats"] = Int(text) ?? 0
                    default: break
                    }
                }
            case "SYLT":
                if let (desc, raw) = readSYLTPayload(frame), desc == "ClogChoreoParts" {
                    result["hasPositions"] = !raw.isEmpty
                }
            default: break
            }
        }

        if let ms = tlenMs, ms > 0 {
            result["duration"] = ms / 1000
        } else {
            result["duration"] = readDuration()
        }

        return result
    }

    func readUserText(_ description: String) -> String {
        guard let fileData = try? Data(contentsOf: fileURL),
              let tag = parseTag(from: fileData)
        else { return "" }

        for frame in tag.frames {
            if frame.id == "TXXX", let (desc, text) = readTXXX(frame), desc == description {
                return text
            }
        }
        return ""
    }

    func loadPositions() -> String {
        guard let fileData = try? Data(contentsOf: fileURL),
              let tag = parseTag(from: fileData)
        else { return "" }

        for frame in tag.frames {
            if frame.id == "SYLT",
               let (desc, raw) = readSYLTPayload(frame),
               desc == "ClogChoreoParts",
               !raw.isEmpty {
                return parseSYLTBinary(raw)
            }
        }
        return ""
    }

    // MARK: - Public write API

    func saveTitle(_ value: String) {
        modifyTag { tag in
            tag.frames.removeAll { $0.id == "TIT2" }
            tag.frames.insert(self.makeTextFrame(id: "TIT2", text: value), at: 0)
        }
    }

    func saveArtist(_ value: String) {
        modifyTag { tag in
            tag.frames.removeAll { $0.id == "TPE1" }
            let idx = tag.frames.firstIndex { $0.id == "TIT2" }.map { $0 + 1 } ?? 0
            tag.frames.insert(self.makeTextFrame(id: "TPE1", text: value), at: idx)
        }
    }

    func saveUserText(_ description: String, sValue value: String) {
        modifyTag { tag in
            tag.frames.removeAll { frame in
                frame.id == "TXXX" && (self.readTXXX(frame)?.description == description)
            }
            tag.frames.append(self.makeTXXXFrame(description: description, text: value))
        }
    }

    func removeAllBpms() {
        modifyTag { tag in
            tag.frames.removeAll { $0.id == "TBPM" }
        }
    }

    func saveBPM(_ bpm: Int32) {
        modifyTag { tag in
            tag.frames.removeAll { $0.id == "TBPM" }
            tag.frames.append(self.makeTextFrame(id: "TBPM", text: "\(bpm)"))
        }
    }

    func savePositions(_ positionString: String) {
        modifyTag { tag in
            let rawData = self.buildSYLTBinary(positionString)
            tag.frames.removeAll { frame in
                frame.id == "SYLT" && (self.readSYLTPayload(frame)?.description == "ClogChoreoParts")
            }
            tag.frames.append(self.makeSYLTFrame(description: "ClogChoreoParts", rawData: rawData))
        }
    }
}
