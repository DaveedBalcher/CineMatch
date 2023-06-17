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
            saveUserToUserDefaults()
        }
    }
    @Published var appScreen: AppScreen = .login
    
    private var preratedMovies: [Movie] = []
    private var ratings: [UserRating] = []
    
    var allUsers: [User] = []
    
    private var userService: UserServiceProtocol
    private var movieService: MovieServiceProtocol
    
    init(userService: UserServiceProtocol, movieService: MovieServiceProtocol) {
        self.userService = userService
        self.movieService = movieService
        self.user = UserDefaultsManager.shared.loadUser()
    }
    
    // MARK: - Functional methods
    
    func createUser(with name: String) {
        let userName = name.replacingOccurrences(of: " ", with: "")
        guard !userName.isEmpty else { return }
        
        Task {
            do {
                try await userService.createUser(name: userName)
                print("/api/v1/user: Successfully created user: \(userName)")
                DispatchQueue.main.async {
                    self.user = User(name: userName)
                }
                self.showQuiz()
            } catch {
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
            print("/api/v1/movies/quiz: Failed to fetch movies: \(error)")
            return []
        }
    }
    
    func saveRating(for movie: Movie, rating: Int) {
        DispatchQueue.main.async {
            self.preratedMovies.removeAll { $0.title == movie.title }
            
            guard let newMovie = self.getRandomPreratedMovie() else {
                self.appScreen = .error(message: "No movies available")
                return
            }
            
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
    
    func fetchAllUsersExceptCurrentUser() async {
        do {
            let allUsers = try await userService.fetchAllUsers()
            DispatchQueue.main.async { [weak self] in
                self?.allUsers = allUsers.filter { $0.name.lowercased()  != self?.user?.name.lowercased() }
            }
            print("/api/v1/user: Successfully fetched \(allUsers.count) users")
        } catch {
            print("/api/v1/user: Failed to fetch users: \(error)")
        }
    }
    
    func fetchRecommendations(for matchUserName: String) {
        guard let user = self.user else { return }
        
        Task {
            do {
                let recommendedMovies = try await movieService.fetchMovieRecomendations(users: [user, User(name: matchUserName)])
                DispatchQueue.main.async { [weak self] in
                    self?.appScreen = .recommendation(movies: recommendedMovies)
                }
                print("/api/v1/movies/recs Successfully fetched \(recommendedMovies.count) movies")
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.appScreen = .sync
                    print("/api/v1/movies/recs: Failed to fetch movies: \(error)")
                }
            }
        }
    }
    
    func logout() {
        user = nil
        showLogin()
    }
    
    // MARK: - Navigation methods
    
    func shouldShowLogin() -> Bool {
        user == nil
    }
    
    func showLogin() {
        appScreen = .login
    }
    
    func showQuiz() {
        Task {
            DispatchQueue.main.async {
                self.appScreen = .loading
            }
            let movies = await self.fetchMovies()
            let userRatings = await self.getUserRatings()
            
            // Remove movies that the user has already rated
            let ratedMovieTitles = Set(userRatings.map { $0.title })
            let filteredMovies = movies.filter { !ratedMovieTitles.contains($0.title) }
            
            DispatchQueue.main.async {
                self.preratedMovies = filteredMovies
                
                guard let movie = self.getRandomPreratedMovie() else {
                    self.appScreen = .error(message: "No movies available")
                    return
                }
                
                self.appScreen = .quiz(movie: movie, ratingsLeft: 10)
            }
        }
    }

    func showSync() {
        Task {
            await self.fetchAllUsersExceptCurrentUser()
            DispatchQueue.main.async { [weak self] in
                self?.ratings = []
                self?.appScreen = .sync
            }
        }
    }
    
    func getAllUserNames() -> [String] {
        ["Pick me"] + allUsers.map { $0.name }
    }
    
    // MARK: - Private methods
    
    private func addRatingsToUser() async {
        guard let user = self.user else { return }
        
        do {
            try await movieService.postUserRating(userRatings: self.ratings, user: user)
            print("/api/v1/movies: Successfully added \(self.ratings.count) ratings")
        } catch {
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
            print("/api/v1/movies/ratings/\(user.name): Failed to fetched ratings: \(error)")
            return []
        }
    }
    
    private func getRandomPreratedMovie() -> Movie? {
        preratedMovies.randomElement()
    }
    
    private func saveUserToUserDefaults() {
        UserDefaultsManager.shared.saveUser(user)
    }
}
