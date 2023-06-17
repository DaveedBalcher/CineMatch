//
//  MovieService.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/13/23.
//

import Foundation
import Combine

struct Movie: Decodable, Hashable {
    let title: String
    let year: String
    let rated: String
    let released: String
    let runtime: String
    let genre: String
    let director: String
    let writer: String
    let actors: String
    let plot: String
    let language: String
    let country: String
    let awards: String
    let poster: String
    let ratings: [Rating]
    let metascore: String
    let imdbRating: String
    let imdbVotes: String
    let imdbID: String
    let type: String
    let dvd: String
    let boxOffice: String
    let production: String
    let website: String
    let response: String
    let rationales: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case rated = "Rated"
        case released = "Released"
        case runtime = "Runtime"
        case genre = "Genre"
        case director = "Director"
        case writer = "Writer"
        case actors = "Actors"
        case plot = "Plot"
        case language = "Language"
        case country = "Country"
        case awards = "Awards"
        case poster = "Poster"
        case ratings = "Ratings"
        case metascore = "Metascore"
        case imdbRating = "imdbRating"
        case imdbVotes = "imdbVotes"
        case imdbID = "imdbID"
        case type = "Type"
        case dvd = "DVD"
        case boxOffice = "BoxOffice"
        case production = "Production"
        case website = "Website"
        case response = "Response"
        case rationales = "Rationales"
    }
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.imdbID == rhs.imdbID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(imdbID)
    }
}

struct Rating: Decodable {
    let source: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case source = "Source"
        case value = "Value"
    }
}

struct MovieRatingRequest: Encodable {
    let name: String
    let results: [UserRating]
}

typealias MovieQuizResponse = [Movie]
typealias MovieRecsResponse = [Movie]

class MovieService: ObservableObject {
    func fetchMovies() async throws -> MovieQuizResponse {
        let url = URL(string: "https://worker.jawn.workers.dev/api/v1/movies/quiz")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let movies = try JSONDecoder().decode(MovieQuizResponse.self, from: data)
        return movies
    }
    
    func postUserRating(userRatings: [UserRating], user: User) async throws {
        let url = URL(string: "https://worker.jawn.workers.dev/api/v1/movies")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let movieRatingRequest = MovieRatingRequest(name: user.name, results: userRatings)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(movieRatingRequest)
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
    
    func fetchMovieRecomendations(users: [User]) async throws -> [Movie] {
        let url = URL(string: "https://worker.jawn.workers.dev/api/v1/movies/recs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(users)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "HTTP", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        guard httpResponse.statusCode == 200 else {
            let errorDescription = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
        }
        
        let movies = try JSONDecoder().decode(MovieQuizResponse.self, from: data)
        return movies
    }
}
