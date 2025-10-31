//
//  ApiModels.swift
//  WyrmVault
//
//  Created by Harold on 20/10/2025.
//

import Foundation

// MARK: - API Response Wrapper
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let code: String
    let message: String
    let payload: T?
}

// MARK: - Paginated Response
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case items, total, page
        case pageSize = "page_size"
        case totalPages = "total_pages"
    }
}

// MARK: - FileClassification
enum FileClassification: String, Codable, CaseIterable {
    case unclassified = "UNCLASSIFIED"
    case image = "image"
    case video = "video"
    case audio = "audio"
}

// MARK: - Original
struct Original: Codable, Identifiable {
    let id: String
    let uploadEventId: Int
    let originalName: String
    let sha256Hash: String?
    let mimeType: String?
    let size: Int?
    let fileClassification: FileClassification?
    let fileMetadata: [String: AnyCodable]?
    let dateTaken: String?
    let thumbnails: [Thumbnail]
    let collections: [Collection]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case uploadEventId = "upload_event_id"
        case originalName = "original_name"
        case sha256Hash = "sha256_hash"
        case mimeType = "mime_type"
        case size
        case fileClassification = "file_classification"
        case fileMetadata = "file_metadata"
        case dateTaken = "date_taken"
        case thumbnails, collections
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Thumbnail
struct Thumbnail: Codable, Identifiable {
    let id: String
}

// MARK: - Collection
struct Collection: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let color: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, color
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Helper for decoding arbitrary JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

