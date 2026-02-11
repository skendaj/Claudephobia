import Foundation

enum ClaudeAPIError: LocalizedError {
    case unauthorized
    case invalidResponse(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired. Update your session key."
        case .invalidResponse(let detail): return "Unexpected response: \(detail)"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

struct RateLimitInfo {
    let percentUsed: Double   // 0.0 – 1.0
    let resetsAt: Date
}

struct ClaudeUsageData {
    let fiveHour: RateLimitInfo?
    let sevenDay: RateLimitInfo?
    let sevenDayOpus: RateLimitInfo?
    let sevenDaySonnet: RateLimitInfo?
    let sevenDayOAuthApps: RateLimitInfo?
    let sevenDayCowork: RateLimitInfo?
    let extraUsage: RateLimitInfo?
    let rateLimitTier: String?
}

/// Lightweight client used only for validating session keys via /api/organizations.
final class ClaudeAPIClient {
    private let baseURL = "https://claude.ai"
    private var sessionKey: String

    init(sessionKey: String) {
        self.sessionKey = sessionKey
    }

    func updateSessionKey(_ key: String) {
        self.sessionKey = key
    }

    func testConnection() async throws -> String {
        let url = URL(string: "\(baseURL)/api/organizations")!
        var request = URLRequest(url: url)
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeAPIError.networkError(error)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 || status == 403 {
            throw ClaudeAPIError.unauthorized
        }

        guard let orgs = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstOrg = orgs.first,
              let orgId = firstOrg["uuid"] as? String else {
            throw ClaudeAPIError.invalidResponse("Could not parse organization ID")
        }

        return orgId
    }
}
