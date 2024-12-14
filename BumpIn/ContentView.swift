//
//  ContentView.swift
//  BumpIn
//
//  Created by Arthur on 12/14/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            MainView(isAuthenticated: $isAuthenticated)
        } else {
            LoginView(isAuthenticated: $isAuthenticated)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif