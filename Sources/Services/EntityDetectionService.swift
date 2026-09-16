import Foundation

struct DetectedEntity: Sendable, Hashable {
    let type: EntityType
    let value: String
    let dateValue: Date?
}

/// Uses NSDataDetector plus a small email pass to pull useful actions out of OCR text.
enum EntityDetectionService {
    static func detect(in text: String) -> [DetectedEntity] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        var entities = Set<DetectedEntity>()
        let mask: NSTextCheckingResult.CheckingType = [.date, .address, .link, .phoneNumber]
        if let detector = try? NSDataDetector(types: mask.rawValue) {
            detector.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                guard let match, let valueRange = Range(match.range, in: text) else { return }
                let value = String(text[valueRange])
                switch match.resultType {
                case .date: entities.insert(.init(type: .date, value: value, dateValue: match.date))
                case .address: entities.insert(.init(type: .address, value: value, dateValue: nil))
                case .phoneNumber: entities.insert(.init(type: .phone, value: match.phoneNumber ?? value, dateValue: nil))
                case .link:
                    let type: EntityType = value.contains("@") ? .email : .url
                    entities.insert(.init(type: type, value: match.url?.absoluteString ?? value, dateValue: nil))
                default: break
                }
            }
        }

        let emailPattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
        if let regex = try? NSRegularExpression(pattern: emailPattern, options: .caseInsensitive) {
            regex.matches(in: text, range: range).forEach { match in
                if let matchRange = Range(match.range, in: text) {
                    entities.insert(.init(type: .email, value: String(text[matchRange]), dateValue: nil))
                }
            }
        }
        return entities.sorted { $0.value.localizedCaseInsensitiveCompare($1.value) == .orderedAscending }
    }
}
