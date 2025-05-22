//
//  HarriAWSSession.swift
//  AWSAuthSDK
//
//  Created by Ali Najjar on 22/05/2025.
//  Copyright © 2025 Amazon Web Services. All rights reserved.
//

/// Harri AWS Session
public struct HarriAWSSession: Codable {

    /// id token
    var idToken = HarriCognitoIdentityUserSessionToken()
    
    /// access token
    var accessToken = HarriCognitoIdentityUserSessionToken()
    
    /// refresh token
    var refreshToken = HarriCognitoIdentityUserSessionToken()
    
    /// expiry time
    var expiryTime: Date?
    
    /// user name
    var username: String?
    
    /// sign in info
    var signInInfo: [String: String] = [:]
    
    /// hostedUI options
    var hostedUIOptions: HostedUIOptions?

    /**
     Initializer
     - Parameter idToken: String
     - Parameter accessToken: String
     - Parameter refreshToken: String
     - Parameter expiryTime: Date?
     - Parameter signInInfo: [String: String]
     - Parameter hostedUIOptions: HostedUIOptions?
     */
    init(idToken: String, accessToken: String, refreshToken: String, expiryTime: Date?, username: String?, signInInfo: [String: String] = [:], hostedUIOptions: HostedUIOptions? = nil) {
        
        self.idToken = HarriCognitoIdentityUserSessionToken(tokenString: idToken)
        self.accessToken = HarriCognitoIdentityUserSessionToken(tokenString: accessToken)
        self.refreshToken = HarriCognitoIdentityUserSessionToken(tokenString: refreshToken)
        
        self.expiryTime = expiryTime
        self.username = username
        
        self.hostedUIOptions = hostedUIOptions
        self.signInInfo = signInInfo
    }

    /// Get User Name
    public var getUserName: String? {
        get {
            self.username
        }
    }

    /// Get Id Token
    public var getIdToken: String {
        get {
            self.idToken.tokenString
        }
    }

    /// Get Access Token
    public var getAccessToken: String {
        get {
            self.accessToken.tokenString
        }
    }

    /// Get Refresh Token
    public var getRefreshToken: String {
        get {
            self.refreshToken.tokenString
        }
    }

    /// Get Expiry Date
    public var getExpiryDate: Date? {
        get {
            self.expiryTime
        }
    }

    /**
    Get AWS Cognito Identity User Session
     - Returns AWSCognitoIdentityUserSession
     */
    func getAWSCognitoIdentityUserSession() -> AWSCognitoIdentityUserSession {

        let idToken = AWSCognitoIdentityUserSessionToken()
        idToken.updateWithtokenString(self.idToken.tokenString, tokenClaims: self.idToken.tokenClaims)

        let accessToken = AWSCognitoIdentityUserSessionToken()
        accessToken.updateWithtokenString(self.accessToken.tokenString, tokenClaims: self.accessToken.tokenClaims)

        let refreshToken = AWSCognitoIdentityUserSessionToken()
        refreshToken.updateWithtokenString(self.refreshToken.tokenString, tokenClaims: self.refreshToken.tokenClaims)


        let userSession = AWSCognitoIdentityUserSession()
        userSession.update(withIdToken: idToken, accessToken: accessToken, refreshToken: refreshToken, expirationTime: self.expiryTime)

        return userSession
    }

    /**
    Get AWS Cognito Auth User Session
     - Returns AWSCognitoAuthUserSession
     */
    func getAWSCognitoAuthUserSession() -> AWSCognitoAuthUserSession {

        let idToken = AWSCognitoAuthUserSessionToken()
        idToken.updateWithtokenString(self.idToken.tokenString, tokenClaims: self.idToken.tokenClaims)

        let accessToken = AWSCognitoAuthUserSessionToken()
        accessToken.updateWithtokenString(self.accessToken.tokenString, tokenClaims: self.accessToken.tokenClaims)

        let refreshToken = AWSCognitoAuthUserSessionToken()
        refreshToken.updateWithtokenString(self.refreshToken.tokenString, tokenClaims: self.refreshToken.tokenClaims)


        let authSession = AWSCognitoAuthUserSession()
        authSession.update(withIdToken: idToken, accessToken: accessToken, refreshToken: refreshToken, expirationTime: self.expiryTime)

        return authSession
    }
}
