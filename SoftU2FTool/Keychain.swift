//
//  Keychain.swift
//  U2FTouchID
//
//  Created by btidor on 8/5/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation

class Keychain {
    static func generatePrivateKey(metadata: Data) throws -> SecKey {
        guard #available(OSX 10.12.1, *) else {
            // Requred in order to use .privateKeyUsage and .touchIDAny in
            // `access` below.
            throw U2FError.unsupportedOSVersion
        }
        
        var error: Unmanaged<CFError>? = nil
        defer { error?.release() }
        
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .touchIDAny], // TODO: this ANDs the options?
            &error) else {
                let description = CFErrorCopyDescription(error!.takeRetainedValue())
                throw U2FError.keychainError(description as String?)
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
            let description = CFErrorCopyDescription(error!.takeRetainedValue())
            throw U2FError.keychainError(description as String?)
        }
        return privateKey
    }
    
    static func findPrivateKey(keyFingerprint: Data) throws -> SecKey {
        var privateKey: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrTokenID as String:          kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationLabel as String: keyFingerprint,
            
            kSecUseOperationPrompt as String:   "authenticate",
            kSecReturnRef as String:            true,
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &privateKey)
        switch status {
        case errSecSuccess:
            return privateKey! as! SecKey
        case errSecItemNotFound:
            throw U2FError.keyNotFound
        default:
            throw U2FError.keychainError(SecCopyErrorMessageString(status, nil)! as String)
        }
    }
    
    static func sign(data: Data, with privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>? = nil
        defer { error?.release() }
        
        guard let signature = SecKeyCreateSignature(
            privateKey, .ecdsaSignatureMessageX962SHA256, data as CFData, &error) else {
                let description = CFErrorCopyDescription(error!.takeRetainedValue())
                throw U2FError.keychainError(description as String?)
        }
        return signature as Data
    }
    
    static func exportPublicKey(from privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>? = nil
        defer { error?.release() }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw U2FError.keychainError("SecKeyCopyPublicKey returned nil")
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            let description = CFErrorCopyDescription(error!.takeRetainedValue())
            throw U2FError.keychainError(description as String?)
        }
        return publicKeyData as Data
    }
    
    static func getKeyFingerprint(privateKey: SecKey) throws -> Data {
        guard let attributes = SecKeyCopyAttributes(privateKey) as? [String: Any] else {
            throw U2FError.keychainError("SecKeyCopyAttributes returned nil")
        }
        
        return attributes[kSecAttrApplicationLabel as String] as! Data
    }
    
    static func getKeyMetadata(keyFingerprint: Data) throws -> Data {
        var ref: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrApplicationLabel as String: keyFingerprint,
            
            kSecReturnAttributes as String:     true,
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &ref)
        switch status {
        case errSecSuccess:
            let attributes = ref as! [String: Any]
            return attributes[kSecAttrApplicationTag as String] as! Data
        case errSecItemNotFound:
            throw U2FError.keyNotFound
        default:
            throw U2FError.keychainError(SecCopyErrorMessageString(status, nil)! as String)
        }
    }
    
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
            throw U2FError.keychainError(SecCopyErrorMessageString(status, nil)! as String)
        }
    }
}
