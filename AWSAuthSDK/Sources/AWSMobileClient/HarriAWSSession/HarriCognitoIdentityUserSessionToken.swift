//
//  HarriCognitoIdentityUserSessionToken.swift
//  AWSAuthSDK
//
//  Created by Ali Najjar on 22/05/2025.
//  Copyright © 2025 Amazon Web Services. All rights reserved.
//

/// Harri Cognito Identity User Session Token
struct HarriCognitoIdentityUserSessionToken: Codable {
    
    /// token string
    var tokenString = ""
    
    /// token claims
    var tokenClaims: [String: Any] = [:]

    /**
     Inititializer
     */
    init() {
        tokenString = ""
        tokenClaims = [:]
    }

    /**
     Inititializer
     - Parameter tokenString: String
     - Parameter tokenClaims: [String: Any]
     */
    init(tokenString: String, tokenClaims: [String: Any] = [:]) {

        self.tokenString = tokenString
        self.tokenClaims = tokenClaims
    }

    /**
     Initializer
     - Parameter decoder: Decoder
     */
    init(from decoder: Decoder) throws {
        self.init()

        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? values.decodeIfPresent(String.self, forKey: CodingKeys.tokenString){
            self.tokenString = value
        }
    }

    /**
     Encoder
     */
    func encode(to encoder: Encoder) throws  {

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.tokenString, forKey: .tokenString)
    }

    /// Coding Keys
    enum CodingKeys: CodingKey {
        case tokenString
        case claims
        case tokenClaims
    }
}
