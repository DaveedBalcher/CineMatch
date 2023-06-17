//
//  MainViewModel.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/12/23.
//

import Foundation
import Combine

enum AppScreen {
    case intro,
         loading,
         login,
         quiz(movie: Movie, ratingsLeft: Int),
         sync,
         recommendation(movies: [Movie]),
         error(message: String)
}

class MainViewModel: ObservableObject {
    @Published var user: User? {
        didSet {
            saveUserToUserDefaults(user: user)
        }
    }
    @Published var appScreen: AppScreen = .login
    
    private var preratedMovies: [Movie] = []
    private var ratings: [UserRating] = []
    
    var allUsers: [User] = []
    
    private var userService: UserService
    private var movieService: MovieService
    
    init(userService: UserService, movieService: MovieService) {
        self.userService = userService
        self.movieService = movieService
        
        // Load the user from UserDefaults when the app starts.
        if let userData = UserDefaults.standard.data(forKey: "user") {
            let decoder = JSONDecoder()
            if let loadedUser = try? decoder.decode(User.self, from: userData) {
                self.user = loadedUser
            }
        }
    }
    
    func createUser(name: String) {
        let userName = name.replacingOccurrences(of: " ", with: "")
        guard userName.count > 0 else { return }
        
        Task {
            do {
                try await userService.createUser(name: userName)
                print("/api/v1/user: Successfully created user: \(userName)")
                DispatchQueue.main.async {
                    self.user = User(name: userName)
                }
                
                showQuiz()
            } catch {
                // Handle userService.createUser() error.
                print("/api/v1/user: Failed to create user: \(error)")
            }
        }
    }

    func fetchMovies() async -> [Movie] {
        do {
            let movies = try await movieService.fetchMovies()
            print("/api/v1/movies/quiz: Successfully fetched \(movies.count) movies")
            return movies
        } catch {
            // Handle the error.
            print("/api/v1/movies/quiz: Failed to fetch movies: \(error)")
            return []
        }
    }
    
    func saveRating(movie: Movie, rating: Int) {
        DispatchQueue.main.async {
            self.preratedMovies.removeAll { $0.title == movie.title }
            
            guard let newMovie = self.getRandomMovie() else {
                self.appScreen = .error(message: "No movies available")
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if rating != -1 {
                    let userRating = UserRating(title: movie.title, rating: rating+1, imbdID: newMovie.imdbID)
                    self.ratings.append(userRating)
                }
                
                if self.ratings.count < 10 {
                    self.appScreen = .quiz(movie: newMovie, ratingsLeft: 10 - self.ratings.count)
                } else {
                    Task {
                        await self.addRatingsToUser()
                        self.showSync()
                    }
                }
            }
        }
    }
    
    func fetchAllUsers() async {
        do {
            let allUsers = try await userService.fetchAllUsers()
            DispatchQueue.main.async { [weak self] in
                self?.allUsers = allUsers.filter { $0.name.lowercased()  != self?.user?.name.lowercased() }
                print("/api/v1/user: Successfully fetched \(allUsers.count) users")
            }
        } catch {
            // Handle the error.
            print("/api/v1/user: Failed to fetch users: \(error)")
        }
    }
    
    func fetchRecommendations(matchUserName: String) {
        guard let user = self.user else { return }
        
        Task {
            do {
                let recommendedMovies = try await movieService.fetchMovieRecomendations(users: [user, User(name: matchUserName)])
                DispatchQueue.main.async { [weak self] in
                    print("/api/v1/movies/recs Successfully fetched \(recommendedMovies.count) movies")
                    
                    self?.appScreen = .recommendation(movies: recommendedMovies)
                }
            } catch {
                // Handle the error.
                DispatchQueue.main.async { [weak self] in
                    self?.appScreen = .sync
                    print("/api/v1/movies/recs: Failed to fetch movies: \(error)")
                }
            }
        }
    }
    
    private func addRatingsToUser() async {
        guard let user = self.user else { return }
        
        do {
            try await movieService.postUserRating(userRatings: self.ratings, user: user)
            print("/api/v1/movies: Successfully added \(self.ratings.count) ratings")
        } catch {
            // Handle the error.
            print("/api/v1/movies: Failed to add ratings: \(error)")
        }
    }
    
    private func getUserRatings() async -> [UserRating] {
        guard let user = self.user else { return [] }
        
        do {
            let userRatings = try await userService.fetchRatings(for: user)
            print("/api/v1/movies/ratings/\(user.name): Successfully fetched \(userRatings.count) ratings")
            return userRatings
        } catch {
            // Handle the error.
            print("/api/v1/movies/ratings/\(user.name): Failed to fetched ratings: \(error)")
            return []
        }
    }
    
    private func getRandomMovie() -> Movie? {
        preratedMovies.randomElement()
    }
    
    // MARK: - Navigation
    
    func shouldShowLogin() -> Bool {
        user == nil
    }
    
    func showLogin() {
        appScreen = .login
    }
    
    func showQuiz() {
        Task {
            do {
                DispatchQueue.main.async {
                    self.appScreen = .loading
                }
                let movies = await fetchMovies()
                let userRatings = await getUserRatings()
                
                // Remove movies that the user has already rated
                let ratedMovieTitles = Set(userRatings.map { $0.title })
                let filteredMovies = movies.filter { !ratedMovieTitles.contains($0.title) }
                
                DispatchQueue.main.async {
                    self.preratedMovies = filteredMovies
                    
                    guard let movie = self.getRandomMovie() else {
                        self.appScreen = .error(message: "No movies available")
                        return
                    }
                    
                    self.appScreen = .quiz(movie: movie, ratingsLeft: 10)
                }
            }
        }
    }

    func showSync() {
        Task {
            await self.fetchAllUsers()
            DispatchQueue.main.async { [weak self] in
                self?.ratings = []
                self?.appScreen = .sync
            }
        }
    }
    
    func getAllUserStrings() -> [String] {
        ["Pick me"] + allUsers.map { $0.name }
    }
    
    func logout() {
        user = nil
        showLogin()
    }
    
    private func saveUserToUserDefaults(user: User?) {
        if let user = user {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(user) {
                UserDefaults.standard.set(encoded, forKey: "user")
            }
        } else {
            DispatchQueue.main.async {
                UserDefaults.standard.removeObject(forKey: "user")
            }
        }
    }
}
