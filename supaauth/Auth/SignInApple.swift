//
//  SignInApple.swift
//  supaauth
//
//  Created by Egor Romanov on 16.04.2024.
//

import SwiftUI
import CryptoKit
import AuthenticationServices

struct SignInView: View {
    @AppStorage("userName") private var storedUserName = ""
    @AppStorage("userCredential") private var userCredential = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let authManager: AuthManager = AuthManager.shared
    
    private let nonce: String = randomNonceString()
    
    let onSignedIn: (String) -> Void
    
    var body: some View {
        #if os(watchOS)
            ScrollView {
                Text("Login and start saving your AI notes.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.all)
                
                SignInWithAppleButton(onRequest: onRequest, onCompletion: siwaCompletion)
                    .signInWithAppleButtonStyle(.white)
            }
        #else
        VStack{
            Spacer ()
            Text("Login and start saving your AI notes.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.all)
            if (colorScheme == .dark) {
                SignInWithAppleButton(onRequest: onRequest, onCompletion: siwaCompletion)
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 60, alignment: .center)
                    .padding(.horizontal, 60)
            } else {
                SignInWithAppleButton(onRequest: onRequest, onCompletion: siwaCompletion)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 60, alignment: .center)
                    .padding(.horizontal, 60)
            }
            Spacer()
        }
        #endif
    }
    
    private func onRequest(request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    private func siwaCompletion(result: Result<ASAuthorization, Error>) {
        guard
            case .success(let authorization) = result,
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            if case .failure(let error) = result {
                print("Failed to authenticate: \(error.localizedDescription)")
            }
            
            return
        }
        
        if credential.fullName != nil {
            authManager.name = credential.fullName?.nickname ?? credential.fullName?.formatted() ?? "me"
            storedUserName = credential.fullName?.nickname ?? credential.fullName?.formatted() ?? "me"
        }
        
        // Pass credential.identityToken and credential.authorizationCode
        DispatchQueue.main.async {
            Task {
                do {
                    let authResponse = try await authManager.signInWithApple(idToken: String(data: credential.identityToken ?? Data(), encoding: .utf8) ?? "", nonce: self.nonce)
                    onSignedIn(authResponse.uid)
                } catch {
                    print("Error authenticating supa: \(error)")
                }
                dismiss()
            }
        }
        
        userCredential = credential.user
    }
    
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView { _ in }
    }
}
