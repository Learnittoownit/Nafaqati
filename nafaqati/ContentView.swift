//
//  ContentView.swift
//  nafaqati
//
//  Created by Rama AlQahtani on 02/12/1447 AH.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "gbblobe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
