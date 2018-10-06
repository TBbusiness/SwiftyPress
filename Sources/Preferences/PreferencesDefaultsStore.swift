//
//  PreferencesDefaultsStore.swift
//  SwiftyPress
//
//  Created by Basem Emara on 2018-10-06.
//

import ZamzamKit

public struct PreferencesDefaultsStore: PreferencesStore {
    private let defaults: UserDefaults
    
    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }
}

public extension PreferencesDefaultsStore {
    
    /// Retrieves the value from user defaults that corresponds to the given key.
    ///
    /// - Parameter key: The key that is used to read the user defaults item.
    func get<T>(_ key: DefaultsKey<T?>) -> T? {
        return defaults[key]
    }
    
    /// Stores the value in the user defaults item under the given key.
    ///
    /// - Parameters:
    ///   - value: Value to be written to the user defaults.
    ///   - key: Key under which the value is stored in the user defaults.
    func set<T>(_ value: T?, forKey key: DefaultsKey<T?>) {
        defaults[key] = value
    }
    
    /// Deletes the single user defaults item specified by the key.
    ///
    /// - Parameter key: The key that is used to delete the keychain item.
    /// - Returns: True if the item was successfully deleted.
    func remove<T>(_ key: DefaultsKey<T?>) {
        defaults.remove(key)
    }
}
