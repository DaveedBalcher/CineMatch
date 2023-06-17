//
//  UserDefaultsManager.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/17/23.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private init() {}

    func saveUser(_ user: User?) {
        if let user = user {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(user) {
                UserDefaults.standard.set(encoded, forKey: "user")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "user")
        }
    }

    func loadUser() -> User? {
        if let userData = UserDefaults.standard.data(forKey: "user") {
            let decoder = JSONDecoder()
            return try? decoder.decode(User.self, from: userData)
        }
        return nil
    }
}
