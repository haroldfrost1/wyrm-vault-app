//
//  ApiService.swift
//  WyrmVault
//
//  Created by Harold on 20/10/2025.
//

import Foundation

class ApiService {
    static let shared = ApiService()
    
    // Configure these to match your API endpoints
    private let apiBaseURL = "http://localhost:8000"
    private let fileServerBaseURL = "http://localhost:8001"
    
    private init() {}
    
    // MARK: - Fetch Originals
    func fetchOriginals(page: Int = 1, pageSize: Int = 50) async throws -> PaginatedResponse<Original> {
        var components = URLComponents(string: "\(apiBaseURL)/originals")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize))
        ]
        
        guard let url = components.url else {
            throw ApiError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ApiError.serverError
        }
        
        let apiResponse = try JSONDecoder().decode(ApiResponse<PaginatedResponse<Original>>.self, from: data)
        
        guard let payload = apiResponse.payload else {
            throw ApiError.noData
        }
        
        return payload
    }
    
    // MARK: - Build Image URLs
    func thumbnailURL(for thumbnailId: String) -> URL? {
        URL(string: "\(fileServerBaseURL)/thumbnails/\(thumbnailId)")
    }
    
    func originalURL(for originalId: String) -> URL? {
        URL(string: "\(fileServerBaseURL)/originals/\(originalId)")
    }
}

// MARK: - Errors
enum ApiError: Error {
    case invalidURL
    case serverError
    case noData
    case decodingError
}

