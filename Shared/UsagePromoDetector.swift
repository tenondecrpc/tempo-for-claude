import Foundation

enum UsagePromoDetector {
    static func detectDoubleLimitPromo(from data: Data) -> Bool? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data),
            let root = json as? [String: Any]
        else {
            return nil
        }

        let normalized = Dictionary(
            uniqueKeysWithValues: root.map { ($0.key.lowercased(), $0.value) }
        )

        if let iguana = normalized["iguana_necktie"] {
            return evaluatePromoValue(iguana, fallbackOnPresence: true)
        }

        for key in explicitFlagKeys {
            if let value = normalized[key], let result = evaluatePromoValue(value, fallbackOnPresence: false) {
                return result
            }
        }

        for key in explicitContainerKeys {
            if let value = normalized[key], let result = evaluatePromoValue(value, fallbackOnPresence: false) {
                return result
            }
        }

        return nil
    }

    private static let explicitFlagKeys: [String] = [
        "is_double_limit_active",
        "double_limit_active",
        "double_limit_promo_active",
        "is_2x_promo_active",
        "promo_2x_active",
        "double_limit_multiplier",
        "promo_multiplier",
        "limit_multiplier",
    ]

    private static let explicitContainerKeys: [String] = [
        "double_limit",
        "double_limit_promo",
        "promotion",
        "promo",
    ]

    private static let nestedFlagKeys: [String] = [
        "is_double_limit_active",
        "double_limit_active",
        "active",
        "is_active",
        "enabled",
        "is_enabled",
    ]

    private static let nestedMultiplierKeys: [String] = [
        "multiplier",
        "limit_multiplier",
        "promo_multiplier",
        "double_limit_multiplier",
    ]

    private static let nestedDescriptionKeys: [String] = [
        "name",
        "label",
        "title",
        "status",
        "description",
    ]

    private static func evaluatePromoValue(_ value: Any, fallbackOnPresence: Bool) -> Bool? {
        if value is NSNull { return nil }

        if let flag = boolValue(from: value) {
            return flag
        }

        if let multiplier = numericValue(from: value) {
            return multiplier >= 2.0
        }

        if let text = value as? String {
            if let parsed = boolValue(from: text) {
                return parsed
            }
            if looksLikeDoubleLimitPromotion(text) {
                return true
            }
            return fallbackOnPresence ? true : nil
        }

        if let array = value as? [Any] {
            for item in array {
                if let result = evaluatePromoValue(item, fallbackOnPresence: false) {
                    return result
                }
            }
            return fallbackOnPresence ? !array.isEmpty : nil
        }

        if let dictionary = value as? [String: Any] {
            let normalized = Dictionary(
                uniqueKeysWithValues: dictionary.map { ($0.key.lowercased(), $0.value) }
            )

            for key in nestedFlagKeys {
                if let raw = normalized[key], let flag = boolValue(from: raw) {
                    return flag
                }
            }

            for key in nestedMultiplierKeys {
                if let raw = normalized[key], let multiplier = numericValue(from: raw) {
                    return multiplier >= 2.0
                }
            }

            for key in nestedDescriptionKeys {
                if let raw = normalized[key] as? String, looksLikeDoubleLimitPromotion(raw) {
                    return true
                }
            }

            for (key, nested) in normalized {
                if nested is [String: Any] || nested is [Any] {
                    if let result = evaluatePromoValue(nested, fallbackOnPresence: false) {
                        return result
                    }
                    continue
                }

                if shouldInspectScalarKey(key), let result = evaluatePromoScalar(nested) {
                    return result
                }
            }

            return fallbackOnPresence ? true : nil
        }

        return fallbackOnPresence ? true : nil
    }

    private static func boolValue(from value: Any) -> Bool? {
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue
            }
            if number.doubleValue == 0 { return false }
            if number.doubleValue == 1 { return true }
        }
        if let text = value as? String {
            switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "on", "active", "enabled":
                return true
            case "false", "no", "off", "inactive", "disabled":
                return false
            default:
                return nil
            }
        }
        return nil
    }

    private static func numericValue(from value: Any) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let text = value as? String {
            return Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func evaluatePromoScalar(_ value: Any) -> Bool? {
        if let flag = boolValue(from: value) {
            return flag
        }
        if let multiplier = numericValue(from: value) {
            return multiplier >= 2.0
        }
        if let text = value as? String, looksLikeDoubleLimitPromotion(text) {
            return true
        }
        return nil
    }

    private static func shouldInspectScalarKey(_ key: String) -> Bool {
        let value = key.lowercased()
        return value.contains("promo")
            || value.contains("promotion")
            || value.contains("double")
            || value.contains("2x")
            || value.contains("multiplier")
            || value == "active"
            || value == "is_active"
            || value == "enabled"
            || value == "is_enabled"
    }

    private static func looksLikeDoubleLimitPromotion(_ text: String) -> Bool {
        let value = text.lowercased()
        return value.contains("2x")
            || value.contains("double limit")
            || (value.contains("promo") && value.contains("double"))
            || (value.contains("promotion") && value.contains("double"))
    }
}
