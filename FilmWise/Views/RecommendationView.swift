//
//  RecommendationView.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/14/23.
//

import SwiftUI

struct RecommendationView: View {
    let movies: [Movie]
    let onBack: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                List(movies, id: \.self) { movie in
                    VStack(alignment: .center) {
                        Text(movie.title)
                            .font(.title)
                            .fontWeight(.bold)
                        AsyncImage(url: URL(string: movie.poster)!) { phase in
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
                        .padding(.bottom)

                        ForEach(movie.rationales ?? [], id: \.self) { rationale in
                            Text(rationale)
                                .font(.subheadline)
                                .padding(.bottom, 1)
                        }
                    }
                    .padding()
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("You two will love these")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                                    Button(action: onBack) {
                                        HStack {
                                            Image(systemName: "arrow.left")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    }
            )
        }
    }
}

struct RecommendationView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendationView(movies: []) {}
    }
}
