//
//  PhotoGalleryView.swift
//  WyrmVault
//
//  Created by Harold on 20/10/2025.
//

import SwiftUI

struct PhotoGalleryView: View {
    @Bindable var viewModel: PhotoGalleryViewModel
    
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
                    ForEach(Array(viewModel.originals.enumerated()), id: \.element.id) { index, original in
                        if (original.thumbnails.isEmpty) {

                        } else {
                            NavigationLink(destination: PhotoDetailView(originals: viewModel.originals, initialIndex: index)) {
                                PhotoGridItem(
                                    imageURL:  ApiService.shared.thumbnailURL(for: original.thumbnails.first!.id) )
                                .aspectRatio(1, contentMode: .fill)
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
    var imageURL: URL?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
        }
    }
}

// MARK: - View Model
@Observable class PhotoGalleryViewModel {
    var originals: [Original] = []
    var isLoading = false
    var gridColumns: [GridItem] = []
    
    private var currentPage = 1
    private var totalPages = 1
    private var pageSize = 50
    
    init() {
        updateGridColumns()
    }
    
    private func updateGridColumns() {
        // Use an adaptive grid so the number of columns adjusts with available width.
        // Cells will be at least 120pt wide and at most 220pt, maintaining 2pt spacing.
        gridColumns = [
            GridItem(.adaptive(minimum: 88, maximum: 120), spacing: 2)
        ]
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
    PhotoGalleryView(viewModel: PhotoGalleryViewModel())
}

