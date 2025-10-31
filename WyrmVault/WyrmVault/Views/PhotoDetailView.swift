//
//  PhotoDetailView.swift
//  WyrmVault
//
//  Created by Harold on 26/10/2025.
//

import SwiftUI
import AVKit

struct PhotoDetailView: View {
    @Bindable var viewModel: PhotoGalleryViewModel
    let initialIndex: Int
    @State private var currentIndex: Int
    
    private let loadThreshold: Int = 5 // Load more when within 5 items of the edge

    init(viewModel: PhotoGalleryViewModel, initialIndex: Int) {
        self.viewModel = viewModel
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(viewModel.originals.enumerated()), id: \.element.id) { index, original in
                    PhotoDetailItem(original: original)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { _, newIndex in
                // Re-enable auto-loading when swiping through photos in detail view
                viewModel.checkAndLoadMoreIfNeeded(currentIndex: newIndex, threshold: loadThreshold)
            }
            
            // Loading indicator for infinite scroll
            if viewModel.isLoading && viewModel.originals.count > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            // Disable auto-loading when entering detail view
            viewModel.shouldAutoLoad = false
        }
        .onDisappear {
            // Re-enable auto-loading when leaving detail view
            viewModel.shouldAutoLoad = true
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Photo Detail Item
struct PhotoDetailItem: View {
    let original: Original
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Group {
                switch original.fileClassification {
                case .video:
                    // Simple video player - just works!
                    if let videoURL = ApiService.shared.originalURL(for: original.id) {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .aspectRatio(contentMode: .fit)
                    } else {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text("Invalid video URL")
                                .foregroundColor(.white)
                        }
                    }
                    
                case .image, .unclassified, .audio, .none:
                    imageView
                }
            }
        }
    }
    
    // MARK: - Image View
    @ViewBuilder
    private var imageView: some View {
        AsyncImage(url: ApiService.shared.originalURL(for: original.id)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .tint(.white)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                imageScale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = imageScale
                                // Reset if zoomed out too much
                                if imageScale < 1.0 {
                                    withAnimation {
                                        imageScale = 1.0
                                        lastScale = 1.0
                                        imageOffset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        imageScale > 1.0 ? DragGesture()
                            .onChanged { value in
                                imageOffset = value.translation
                            }
                            .onEnded { _ in
                                // Keep offset when zoomed
                            } : nil
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if imageScale > 1.0 {
                                imageScale = 1.0
                                lastScale = 1.0
                                imageOffset = .zero
                            } else {
                                imageScale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }
            case .failure:
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Failed to load image")
                        .foregroundColor(.white)
                }
            @unknown default:
                EmptyView()
            }
        }
    }
}

#Preview {
    let viewModel = PhotoGalleryViewModel()
    // Add some sample data to the view model for preview
    viewModel.originals = [
        Original(
            id: "preview-image",
            uploadEventId: 1,
            originalName: "sample-photo.jpg",
            sha256Hash: "abc123",
            mimeType: "image/jpeg",
            size: 2048000,
            fileClassification: .image,
            fileMetadata: nil,
            dateTaken: "2025-10-26T12:00:00Z",
            thumbnails: [Thumbnail](),
            collections: [Collection](),
            createdAt: "2025-10-26T12:00:00Z",
            updatedAt: "2025-10-26T12:00:00Z"
        ),
        Original(
            id: "preview-video",
            uploadEventId: 2,
            originalName: "sample-video.mp4",
            sha256Hash: "def456",
            mimeType: "video/mp4",
            size: 10485760,
            fileClassification: .video,
            fileMetadata: nil,
            dateTaken: "2025-10-26T13:00:00Z",
            thumbnails: [Thumbnail](),
            collections: [Collection](),
            createdAt: "2025-10-26T13:00:00Z",
            updatedAt: "2025-10-26T13:00:00Z"
        )
    ]
    
    return NavigationStack {
        PhotoDetailView(
            viewModel: viewModel,
            initialIndex: 0
        )
    }
}
