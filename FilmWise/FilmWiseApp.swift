//
//  FilmWiseApp.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/12/23.
//

import SwiftUI

class MainFlow {
    init(vm: MainViewModel) {
        vm.appScreen = .intro
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.8) {
            if vm.shouldShowLogin() {
                vm.showLogin()
            } else {
                vm.showSync()
            }
        }
    }
}

private let mainViewModel = MainViewModel(userService: UserService(), movieService: MovieService())

@main
struct FilmWiseApp: App {
    let mainFlow = MainFlow(vm: mainViewModel)
    
    var body: some Scene {
        WindowGroup {
            MainView(vm: mainViewModel)
        }
    }
}
