import Foundation
import AuthenticationServices
import UIKit

/// Manages Google OAuth2 authentication using ASWebAuthenticationSession.
/// This avoids the need for the full Google Sign-In SDK by handling OAuth2 directly.
@MainActor
class GoogleAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var userProfileImageURL: String?
    @Published var isAuthenticated = false

    private let clientID = AppConstants.Google.clientID
    private let redirectURI = "com.familytube.app:/oauth2callback"
    private let tokenURL = "https://oauth2.googleapis.com/token"
    private let userInfoURL = "https://www.googleapis.com/oauth2/v2/userinfo"

    private var authSession: ASWebAuthenticationSession?

    private let tokenKey = "ft_access_token"
    private let refreshTokenKey = "ft_refresh_token"
    private let userEmailKey = "ft_user_email"
    private let userNameKey = "ft_user_name"

    override init() {
        super.init()
        loadSavedTokens()
    }

    // MARK: - Sign In

    func signIn() async throws {
        let scopes = [
            AppConstants.Google.driveScope,
            AppConstants.Google.emailScope,
            AppConstants.Google.profileScope
        ].joined(separator: " ")

        let authURL = "https://accounts.google.com/o/oauth2/v2/auth"
            + "?client_id=\(clientID)"
            + "&redirect_uri=\(redirectURI)"
            + "&response_type=code"
            + "&scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scopes)"
            + "&access_type=offline"
            + "&prompt=consent"

        guard let url = URL(string: authURL) else {
            throw AuthError.invalidURL
        }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "com.familytube.app"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let callbackURL = callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: AuthError.noCallback)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            session.start()
        }
        authSession = nil

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.noAuthCode
        }

        try await exchangeCodeForTokens(code: code)
        try await fetchUserInfo()
        isAuthenticated = true
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(code: String) async throws {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "code=\(code)"
            + "&client_id=\(clientID)"
            + "&redirect_uri=\(redirectURI)"
            + "&grant_type=authorization_code"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        refreshToken = tokenResponse.refreshToken ?? refreshToken
        saveTokens()
    }

    // MARK: - Refresh Token

    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw AuthError.noRefreshToken
        }

        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "refresh_token=\(refreshToken)"
            + "&client_id=\(clientID)"
            + "&grant_type=refresh_token"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        saveTokens()
    }

    // MARK: - User Info

    private func fetchUserInfo() async throws {
        guard let accessToken = accessToken else {
            throw AuthError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: userInfoURL)!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let userInfo = try JSONDecoder().decode(GoogleUserInfo.self, from: data)

        userEmail = userInfo.email
        userName = userInfo.name
        userProfileImageURL = userInfo.picture

        UserDefaults.standard.set(userEmail, forKey: userEmailKey)
        UserDefaults.standard.set(userName, forKey: userNameKey)
    }

    // MARK: - Sign Out

    func signOut() {
        accessToken = nil
        refreshToken = nil
        userEmail = nil
        userName = nil
        userProfileImageURL = nil
        isAuthenticated = false

        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
    }

    // MARK: - Persistence

    private func saveTokens() {
        if let accessToken = accessToken {
            UserDefaults.standard.set(accessToken, forKey: tokenKey)
        }
        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        }
    }

    private func loadSavedTokens() {
        accessToken = UserDefaults.standard.string(forKey: tokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        userName = UserDefaults.standard.string(forKey: userNameKey)

        if accessToken != nil {
            isAuthenticated = true
        }
    }
}

// MARK: - Supporting Types

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct GoogleUserInfo: Codable {
    let id: String
    let email: String
    let name: String
    let picture: String?
}

enum AuthError: LocalizedError {
    case invalidURL
    case noCallback
    case noAuthCode
    case tokenExchangeFailed
    case tokenRefreshFailed
    case noRefreshToken
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid authentication URL"
        case .noCallback: return "No authentication callback received"
        case .noAuthCode: return "No authorization code received"
        case .tokenExchangeFailed: return "Failed to exchange token"
        case .tokenRefreshFailed: return "Failed to refresh token"
        case .noRefreshToken: return "No refresh token available"
        case .notAuthenticated: return "User is not authenticated"
        }
    }
}
