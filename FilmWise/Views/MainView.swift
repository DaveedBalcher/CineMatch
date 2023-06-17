//
//  MainView.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/12/23.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var vm: MainViewModel
    
    var body: some View {
        VStack {
            switch vm.appScreen {
            case .intro:
                Text("CINEMATCH")
                    .font(.largeTitle)
                    .bold()
            case .loading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            case .login:
                LoginView() { name in
                    vm.createUser(name: name)
                }
            case let .quiz(movie, ratingsLeft: ratingsLeft):
                QuizView(vm: QuizViewModel(movie: movie, ratingsLeft: ratingsLeft)) { rating in
                    vm.saveRating(movie: movie, rating: rating)
                }
            case .sync:
                SyncView(loggedInUser: vm.user!.name, users: vm.getAllUserStrings()) { selectedUser in
                    vm.fetchRecommendations(matchUserName: selectedUser)
                } shouldLogoutCompletion: {
                    vm.logout()
                } goToQuizCompletion: {
                    vm.showQuiz()
                }
            case let .recommendation(movies: movies):
                RecommendationView(movies: movies) {
                    vm.appScreen = .sync
                }
            case let .error(message: message):
                Text(message)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(vm: MainViewModel(userService: UserService(), movieService: MovieService()))
    }
}
