//
//  QuizView.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/12/23.
//

import SwiftUI

class QuizViewModel: ObservableObject {
    @Published var movie: Movie
    @Published var ratingsLeft: Int
    @Published var selectedIndex: Int = -1

    init(movie: Movie, ratingsLeft: Int) {
        self.movie = movie
        self.ratingsLeft = ratingsLeft
    }
}

struct QuizView: View {
    @ObservedObject var vm: QuizViewModel
    var completion: ((Int)->Void)?

    var body: some View {
        VStack {
            
            Spacer()
            
            VStack {
                Text(vm.movie.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                AsyncImage(url: URL(string: vm.movie.poster)!) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        Image(systemName: "photo")
                    @unknown default:
                        ProgressView()
                    }
                }
            }
            .padding()

            HStack {
                ForEach(0..<5) { number in
                    Button {
                        withAnimation {
                            vm.selectedIndex = number
                            completion?(number)
                        }
                    } label: {
                        let systemName = number <= vm.selectedIndex ? "star.fill" : "star"
                        Image(systemName: systemName)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(number <= vm.selectedIndex ? .yellow : .gray)
                            .frame(width: 30, height: 30)
                            .padding()
                    }
                }
            }
            .padding()

            Spacer()

            Button {
                withAnimation {
                    vm.selectedIndex = -1
                    completion?(-1)
                }
            } label: {
                Text( "Haven't seen it          ")
                    .fontWeight(.semibold)
                    .font(.body)
                    .padding(24)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(40)
                    .foregroundColor(.white)
                    .padding(24)
            }
            .padding()

            Text("\(vm.ratingsLeft) more to go")
                .font(.headline)
                .padding(.top)
        }
        .onReceive(vm.$movie) { _ in
            withAnimation {
                vm.selectedIndex = -1
            }
        }
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView(vm: QuizViewModel(movie: Movie.forPreview, ratingsLeft: 10))
    }
}

private extension Movie {
    static var forPreview: Movie {
        Movie(title: "Avengers: Endgame",
                     year: "2019",
                     rated: "PG-13",
                     released: "26 Apr 2019",
                     runtime: "181 min",
                     genre: "Action, Adventure, Drama",
                     director: "Anthony Russo, Joe Russo",
                     writer: "Christopher Markus, Stephen McFeely, Stan Lee",
                     actors: "Robert Downey Jr., Chris Evans, Mark Ruffalo",
                     plot: "After the devastating events of Avengers: Infinity War (2018), the universe is in ruins. With the help of remaining allies, the Avengers assemble once more in order to reverse Thanos' actions and restore balance to the universe.",
                     language: "English, Japanese, Xhosa, German",
                     country: "United States",
                     awards: "Nominated for 1 Oscar. 70 wins & 133 nominations total",
                     poster: "https://m.media-amazon.com/images/M/MV5BMTc5MDE2ODcwNV5BMl5BanBnXkFtZTgwMzI2NzQ2NzM@._V1_SX300.jpg",
                     ratings: [],
                     metascore: "78",
                     imdbRating: "8.4",
                     imdbVotes: "1,180,832",
                     imdbID: "tt4154796",
                     type: "movie",
                     dvd: "30 Jul 2019",
                     boxOffice: "$858,373,000",
                     production: "N/A",
                     website: "N/A",
              response: "True",
              rationales: [])

    }
}
