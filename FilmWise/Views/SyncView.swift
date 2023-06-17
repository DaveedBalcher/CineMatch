//
//  SyncView.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/12/23.
//

import SwiftUI

struct SyncView: View {
    let loggedInUser: String
    let users: [String]
    @State private var selectedUser = "Pick me"
    @State private var isSyncing = false
    @State private var showingPopup = false
    var shouldSyncCompletion: ((String)->Void)?
    var shouldLogoutCompletion: (()->Void)?
    var goToQuizCompletion: (()->Void)?
    
    var body: some View {
        NavigationView {
            VStack {
                
                Spacer()
                
                Text("Hey \(loggedInUser)!")
                .font(.title)
                .fontWeight(.semibold)
                
                Spacer()
                
                HStack {
                    Text("Choose your movie partner")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.trailing, -12)
                    Picker("Users", selection: $selectedUser) {
                        ForEach(users, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack {
                    if selectedUser != "Pick me" {
                        Button {
                            withAnimation {
                                isSyncing = true
                                shouldSyncCompletion?(selectedUser)
                            }
                        } label: {
                            Text( "What are we watching?          ")
                                .fontWeight(.semibold)
                                .font(.body)
                                .padding(24)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                                )
                                .cornerRadius(40)
                                .foregroundColor(.white)
                                .padding(36)
                        }
                        .padding(48)
                        
                        VStack {
                            if isSyncing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            }
                        }
                        .frame(minHeight: 50)
                    }
                }
                .frame(minHeight: 300)
                
                Spacer()
            }
            .onAppear {
                selectedUser = users.first ?? "No Users"
            }
            .navigationBarItems(trailing:
                                    HStack {
                Button {
                    showingPopup = true
                } label: {
                    Image(systemName: "gear")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                }
                .actionSheet(isPresented: $showingPopup) {
                    ActionSheet(title: Text("Settings"), buttons: [
                        .default(Text("Quiz"), action: {
                            goToQuizCompletion?()
                        }),
                        .destructive(Text("Logout"), action: {
                            shouldLogoutCompletion?()
                        }),
                        .cancel()
                    ])
                }
            }
            )
        }
    }
}

struct SyncView_Previews: PreviewProvider {
    static var previews: some View {
        SyncView(loggedInUser: "User 0", users: ["Pick me", "User 1", "User 2", "User 3"])
    }
}
