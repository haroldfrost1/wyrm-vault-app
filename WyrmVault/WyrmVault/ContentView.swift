//
//  ContentView.swift
//  WyrmVault
//
//  Created by Harold on 20/10/2025.
//

import SwiftUI

struct ContentView: View {
    @State var photoGalleryViewModel = PhotoGalleryViewModel()

    var body: some View {
        NavigationStack {
            PhotoGalleryView(viewModel: photoGalleryViewModel)
                .navigationTitle("Photos")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
}
