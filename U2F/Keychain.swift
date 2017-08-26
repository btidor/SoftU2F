//
//  Keychain.swift
//  U2FTouchID
//

// TODO: write tests

import Foundation

/// A wrapper around the OSX Keychain APIs for creating and using keys bound in
/// the Secure Enclave and storing associated metadata in the Keychain.
class Keychain {
    
    /// Text for Touch ID prompt. Displayed as:
    /// "APPLICATION" is trying to OPERATION_PROMPT
    static let OPERATION_PROMPT = "authenticate"
    
    /**
     Generates a private key in the Secure Enclave and stores a reference to it
     in the Keychain. See the function body for key and usage parameters.
     
     - Parameter metadata: Initial data to store in the Application Tag.
     - Returns: A reference to the private key.
    */
    static func generatePrivateKey(metadata: Data) throws -> SecKey {
        guard #available(OSX 10.12.1, *) else {
            // OSX 10.12.1 is requred in order to use  the .privateKeyUsage and
            // .touchIDAny access control flags below.
            throw U2FError.unsupportedOSVersion
        }
        
        var error: Unmanaged<CFError>? = nil
        defer { error?.release() }
        
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .touchIDAny], // TODO: this ANDs the options?
            &error) else {
                throw keychainError(in: #function, error: error!)
        }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String:          kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String:    256,
            kSecAttrTokenID as String:          kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String:      true,
                kSecAttrApplicationTag as String:   metadata,
                kSecAttrAccessControl as String:    access,
            ],
        ]
        
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw keychainError(in: #function, error: error!)
        }
        return privateKey
    }
    
    /**
     Derives a fingerprint from a private key (the Application Label) that can
     be used to find it again in the Keychain.
     
     - Parameter privateKey: A private key reference.
     - Returns: The key fingerprint.
    */
    static func getKeyFingerprint(privateKey: SecKey) throws -> Data {
        guard let attributes = SecKeyCopyAttributes(privateKey) as? [String: Any] else {
            throw U2FError.keychainError(#function, nil, "SecKeyCopyAttributes returned nil")
        }
        
        return attributes[kSecAttrApplicationLabel as String] as! Data
    }
    
    /**
     Searches the Keychain for a key with the given key fingerprint. Only
     matches keys bound in the Secure Enclave.
     
     In the process, configures the key with `OPERATION_PROMPT`, which will be
     shown to the user when the key is used to create a signature.
     
     - Returns: A reference to the private key.
    */
    static func findPrivateKey(keyFingerprint: Data) throws -> SecKey {
        var privateKey: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrTokenID as String:          kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationLabel as String: keyFingerprint,
            
            kSecUseOperationPrompt as String:   OPERATION_PROMPT,
            kSecReturnRef as String:            true,
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &privateKey)
        guard status == errSecSuccess else {
            throw keychainError(in: #function, status: status)
        }
        return privateKey! as! SecKey
    }
    
    /**
     Use a private key to sign data.
 
     - Parameter data: The data to sign.
     - Paramater privateKey: A private key reference.
     - Returns: A signature over `data` made with `privateKey`.
    */
    static func sign(data: Data, with privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>? = nil
        defer { error?.release() }
        
        guard let signature = SecKeyCreateSignature(
            privateKey, .ecdsaSignatureMessageX962SHA256, data as CFData, &error) else {
                throw keychainError(in: #function, error: error!)
        }
        return signature as Data
    }
    
    /**
     Derives the corresponding public key from a given private key reference and
     formats it for export.
     
     - Parameter privateKey: A private key reference.
     - Returns: The public key in ANSI X9.63 format.
    */
    static func exportPublicKey(from privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>? = nil
        defer { error?.release() }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw U2FError.keychainError(#function, nil, "SecKeyCopyPublicKey returned nil")
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            throw keychainError(in: #function, error: error!)
        }
        return publicKeyData as Data
    }
    
    /**
     Loads the Kechain metadata (Application Tag) associated with a given
     private key reference.
 
     - Parameter keyFingerprint: The fingerprint of a private key in the
       Keychain.
     - Returns: Application Tag data associated with `keyFingerprint`.
    */
    static func getKeyMetadata(keyFingerprint: Data) throws -> Data {
        var ref: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrApplicationLabel as String: keyFingerprint,
            
            kSecReturnAttributes as String:     true,
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &ref)
        guard status == errSecSuccess else {
            throw keychainError(in: #function, status: status)
        }

        let attributes = ref as! [String: Any]
        return attributes[kSecAttrApplicationTag as String] as! Data
    }
    
    /**
     Sets the Keychain metadata (Application Tag) associated with a given
     private key reference.
     
     - Parameter keyFingerprint: The fingerprint of a private key in the
       Keychain.
     - Parameter metadata: The new Application Tag data to store.
    */
    static func setKeyMetadata(keyFingerprint: Data, metadata: Data) throws {
        let query: [String: Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrApplicationLabel as String: keyFingerprint,
        ]
        
        let attributes: [String: Any] = [
            kSecAttrApplicationTag as String:   metadata,
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw keychainError(in: #function, status: status)
        }
    }
    
    internal static func keychainError(in function: String, error: Unmanaged<CFError>) -> Error {
        let cfError = error.takeUnretainedValue()
        let code = CFErrorGetCode(cfError)
        if code == -2 {
            return U2FError.userCanceled
        } else {
            let description = CFErrorCopyDescription(cfError)
            return U2FError.keychainError(function, code, description as String?)
        }
    }
    
    internal static func keychainError(in function: String, status: OSStatus) -> Error {
        if status == errSecItemNotFound {
            return U2FError.keyNotFound
        } else {
            let description = SecCopyErrorMessageString(status, nil)! as String
            return U2FError.keychainError(function, Int(status), description)
        }
    }
}
