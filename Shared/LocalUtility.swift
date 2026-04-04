import Foundation

/// LLM に投げずローカルロジックで返せるクエリを処理する
enum LocalUtility {

    /// ローカルで回答できる場合は回答文字列を返す。できなければ nil。
    static func tryHandle(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if let result = handleDateTime(trimmed) { return result }
        if let result = handleCalculation(trimmed) { return result }
        if let result = handleUnitConversion(trimmed) { return result }

        return nil
    }

    // MARK: - 日時

    private static func handleDateTime(_ input: String) -> String? {
        let lower = input.lowercased()
        let keywords = ["今何時", "いまなんじ", "現在時刻", "今日の日付", "今日は何日", "何曜日", "今日は何曜日", "今の時間"]
        guard keywords.contains(where: { lower.contains($0) }) else { return nil }

        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)

        if lower.contains("日付") || lower.contains("何日") {
            formatter.dateFormat = "yyyy年M月d日(EEEE)"
            return formatter.string(from: now)
        }
        if lower.contains("曜日") {
            formatter.dateFormat = "EEEE"
            return "今日は\(formatter.string(from: now))です"
        }

        formatter.dateFormat = "H時m分"
        return "現在 \(formatter.string(from: now)) です"
    }

    // MARK: - 計算

    private static func handleCalculation(_ input: String) -> String? {
        let calcKeywords = ["計算して", "計算:", "いくつ", "何%", "割る", "かける", "足す", "引く"]
        let hasKeyword = calcKeywords.contains(where: { input.contains($0) })

        // 数式っぽい文字列を抽出
        let expression = input
            .replacingOccurrences(of: "計算して", with: "")
            .replacingOccurrences(of: "計算:", with: "")
            .replacingOccurrences(of: "：", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "＋", with: "+")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "ー", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 数式として評価できるか試す
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/() ")
        guard !expression.isEmpty,
              expression.unicodeScalars.allSatisfy({ allowed.contains($0) }) || hasKeyword else {
            return nil
        }

        let cleanExpr = expression.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !cleanExpr.isEmpty else { return nil }

        let nsExpression = NSExpression(format: cleanExpr)
        if let result = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber {
            let d = result.doubleValue
            if d == d.rounded() && abs(d) < 1e15 {
                return "\(Int(d))"
            }
            return String(format: "%.4g", d)
        }

        return nil
    }

    // MARK: - 単位変換

    private static func handleUnitConversion(_ input: String) -> String? {
        // km ↔ マイル
        if let val = extractNumber(from: input, before: "km") ?? extractNumber(from: input, before: "キロ"),
           input.contains("マイル") {
            return String(format: "%.2fマイル", val * 0.621371)
        }
        if let val = extractNumber(from: input, before: "マイル"), input.contains("km") || input.contains("キロ") {
            return String(format: "%.2fkm", val * 1.60934)
        }

        // kg ↔ ポンド
        if let val = extractNumber(from: input, before: "kg") ?? extractNumber(from: input, before: "キロ"),
           input.contains("ポンド") {
            return String(format: "%.2fポンド", val * 2.20462)
        }

        // °C ↔ °F
        if let val = extractNumber(from: input, before: "度"),
           input.contains("華氏") || input.contains("°F") {
            return String(format: "%.1f°F", val * 9.0 / 5.0 + 32.0)
        }
        if let val = extractNumber(from: input, before: "°F") ?? extractNumber(from: input, before: "華氏"),
           input.contains("摂氏") || input.contains("°C") || input.contains("度") {
            return String(format: "%.1f°C", (val - 32.0) * 5.0 / 9.0)
        }

        // cm ↔ インチ
        if let val = extractNumber(from: input, before: "cm") ?? extractNumber(from: input, before: "センチ"),
           input.contains("インチ") {
            return String(format: "%.2fインチ", val / 2.54)
        }
        if let val = extractNumber(from: input, before: "インチ"),
           input.contains("cm") || input.contains("センチ") {
            return String(format: "%.2fcm", val * 2.54)
        }

        return nil
    }

    private static func extractNumber(from input: String, before suffix: String) -> Double? {
        guard let range = input.range(of: suffix) else { return nil }
        let preceding = input[input.startIndex..<range.lowerBound]
            .trimmingCharacters(in: .whitespaces)
        // 末尾の数字部分を取得
        let numStr = String(preceding.reversed().prefix(while: { $0.isNumber || $0 == "." }).reversed())
        return Double(numStr)
    }
}
