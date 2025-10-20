//
//  PhotoGalleryView.swift
//  WyrmVault
//
//  Created by Harold on 20/10/2025.
//

import SwiftUI

struct PhotoGalleryView: View {
    @StateObject private var viewModel = PhotoGalleryViewModel()
    
    var body: some View {
            ScrollView {
                if viewModel.isLoading && viewModel.originals.isEmpty {
                    ProgressView("Loading photos...")
                        .padding()
                } else if viewModel.originals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No photos yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: viewModel.gridColumns, spacing: 2) {
                        ForEach(viewModel.originals) { original in
                            PhotoGridItem(original: original)
                                .aspectRatio(1, contentMode: .fill)
                                .onAppear {
                                    // Load more when reaching the last item
                                    if original.id == viewModel.originals.last?.id {
                                        Task {
                                            await viewModel.loadMore()
                                        }
                                    }
                                }
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        .task {
            await viewModel.loadInitial()
        }
    }
}

// MARK: - Grid Item
struct PhotoGridItem: View {
    let original: Original
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if isLoading {
                    Color.gray.opacity(0.2)
                    ProgressView()
                } else {
                    Color.gray.opacity(0.2)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Try to load thumbnail first, fall back to original if no thumbnail
        guard let thumbnailId = original.thumbnails.first?.id,
              let url = ApiService.shared.thumbnailURL(for: thumbnailId) else {
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - View Model
@MainActor
class PhotoGalleryViewModel: ObservableObject {
    @Published var originals: [Original] = []
    @Published var isLoading = false
    @Published var gridColumns: [GridItem] = []
    
    private var currentPage = 1
    private var totalPages = 1
    private var pageSize = 50
    
    init() {
        updateGridColumns()
    }
    
    private func updateGridColumns() {
        // For macOS, use window size to determine column count
        // Default to 6 columns, will adjust based on window width if needed
        let columnCount = 6
        gridColumns = Array(repeating: GridItem(.flexible(), spacing: 2), count: columnCount)
    }
    
    func loadInitial() async {
        guard !isLoading else { return }
        
        isLoading = true
        currentPage = 1
        
        do {
            let response = try await ApiService.shared.fetchOriginals(page: currentPage, pageSize: pageSize)
            originals = response.items
            totalPages = response.totalPages
        } catch {
            print("Failed to load originals: \(error)")
        }
        
        isLoading = false
    }
    
    func loadMore() async {
        guard !isLoading, currentPage < totalPages else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let response = try await ApiService.shared.fetchOriginals(page: currentPage, pageSize: pageSize)
            originals.append(contentsOf: response.items)
        } catch {
            print("Failed to load more originals: \(error)")
            currentPage -= 1 // Revert page increment on error
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadInitial()
    }
}

#Preview {
    PhotoGalleryView()
}

