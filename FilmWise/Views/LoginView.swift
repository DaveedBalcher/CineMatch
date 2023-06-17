//
//  LoginView.swift
//  FilmWise
//
//  Created by Daveed Balcher on 6/12/23.
//

import SwiftUI

struct LoginView: View {
    @State var name = ""
    var completion: ((String)->Void)?
    @State var isFocused = false

    var body: some View {
        VStack {
            
            Spacer()
            
            Text("CINEMATCH")
                .font(.largeTitle)
                .fontWeight(.black)
                .padding(4)
            Text("A Shared Cinematic Experience")
                .foregroundColor(Color.blue)
                .fontWeight(.semibold)
            
            Spacer()
            
            TextField("Enter your name here...", text: $name, onEditingChanged: { editing in
                withAnimation {
                    self.isFocused = editing
                }
            })
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(color: .gray, radius: isFocused ? 10 : 0, x: 0, y: isFocused ? 10 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color.blue : Color.gray, lineWidth: isFocused ? 2 : 1)
            )
            .font(.headline)
            .padding([.leading, .trailing], 48)

            Button(action: {
                withAnimation {
                    completion?(name)
                }
            }) {
                Text( "Log in          ")
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
            .disabled(name.isEmpty)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
