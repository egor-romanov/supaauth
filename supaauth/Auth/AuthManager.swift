//
//  AuthManager.swift
//  supaauth
//
//  Created by Egor Romanov on 16.04.2024.
//

import Foundation
import Supabase

struct AppUser {
    let uid: String
    let email: String?
}

struct Profile: Codable {
    var username: String?
    var fullname: String?
    var id: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case username
        case fullname = "full_name"
    }
}

struct Auth: Codable {
    let accessToken: String
    let refreshToken: String
    let providerRefreshToken: String?
}

class AuthManager: ObservableObject {
    
    static let shared = AuthManager()
    
    private init() {}
    
    let account = "intest.dev"
    let service = "token"
    var name: String? = nil
    
    let client = SupabaseClient(supabaseURL: URL(string: "https://project_ref.supabase.co")!, supabaseKey: "anon_key")
    
    func trySignIn() async -> AppUser? {
        guard let auth = KeychainHelper.shared.read(service: service, account: account, type: Auth.self) else {
            return nil
        }
        do {
            return try await getCurrentSession()
        } catch {
            print("Failed to get session: \(error.localizedDescription)")
        }
        do {
            let session = try await client.auth.setSession(accessToken: auth.accessToken, refreshToken: auth.refreshToken)
            return AppUser(uid: session.user.id.uuidString, email: session.user.email)
        } catch {
            print("Failed to set session: \(error.localizedDescription)")
        }
        return nil
    }
    
    func getCurrentSession() async throws -> AppUser {
        let session = try await client.auth.session
        print(session.user.id)
        return AppUser(uid: session.user.id.uuidString, email: session.user.email)
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws -> AppUser {
        let session = try await client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
        let auth = Auth(accessToken: session.accessToken,
                        refreshToken: session.refreshToken,
                        providerRefreshToken: session.providerRefreshToken)
        
        KeychainHelper.shared.save(auth, service: service, account: account)
        
        if self.name != nil {
            Task.detached {
                do {
                    try await self.client.auth.update(user: UserAttributes(
                        data: [
                            "name": .string(self.name ?? "me")
                        ]
                    )
                    )
                } catch {
                    print("Failed to update user info: \(error.localizedDescription)")
                }
            }
        }
        
        return AppUser(uid: session.user.id.uuidString, email: session.user.email)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
