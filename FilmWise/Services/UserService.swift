//
//  UserService.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/13/23.
//

import Foundation
import Combine

struct User: Codable {
    let name: String
}

struct UserRating: Codable {
    let title: String
    let rating: Int
    let imbdID: String?
    var status: String = "watched"
}

typealias AllUsersResponse = [User]
typealias UserRatingsResponse = [UserRating]

class UserService: ObservableObject {
    func createUser(name: String) async throws {
        let url = URL(string: "https://worker.jawn.workers.dev/api/v1/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let user = User(name: name)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(user)
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "HTTP", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        guard httpResponse.statusCode == 200 else {
            let errorDescription = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
        }
    }
    
    func fetchAllUsers() async throws -> [User] {
        let url = URL(string: "https://worker.jawn.workers.dev/api/v1/user")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let users = try JSONDecoder().decode(AllUsersResponse.self, from: data)
        return users
    }
    
    func fetchRatings(for user: User) async throws -> [UserRating] {
        let url = URL(string: "https://worker.jawn.workers.dev/api/v1/movies/ratings/\(user.name.replacingOccurrences(of: " ", with: ""))")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let userRatings = try JSONDecoder().decode(UserRatingsResponse.self, from: data)
        
        for rating in userRatings {
            print(rating.title, " - ", rating.rating)
        }
        
        return userRatings
    }
}
