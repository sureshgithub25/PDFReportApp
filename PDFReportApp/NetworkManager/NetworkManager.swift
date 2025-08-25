//
//  NetworkManager.swift
//  PDFReportApp
//
//  Created by Suresh Kumar on 24/08/25.
//

import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decodingError(Error)
    case unknown(Error)
    case noResults
    case imageProcessingFailed
    case rateLimitExceeded
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .statusCode(let code):
            return "Status code: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unknown(_):
            return "tinny hiccup"
        case .noResults:
            return "result not found."
        case .imageProcessingFailed:
            return "image processing Falied"
        case .rateLimitExceeded:
            return "rate limit exceeded"
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension Endpoint {
    var baseURL: String {
        return "https://iosserver.free.beeceptor.com"
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var body: Data? {
        return nil
    }
        
    func makeRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}

enum TransactionEndpoint: Endpoint {
    case getHistory
    
    var path: String {
        switch self {
        case .getHistory:
            return "/history"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}


protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError>
}


final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError> {
        var request: URLRequest
        
        do {
            request = try endpoint.makeRequest()
        } catch {
            return Fail(error: error as? APIError ?? .invalidURL)
                .eraseToAnyPublisher()
        }
        
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                // Allow 200-299 status codes
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw APIError.statusCode(httpResponse.statusCode)
                }
                
                // Print response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> APIError in
                print("Decoding error: \(error)")
                if let apiError = error as? APIError {
                    return apiError
                } else if let decodingError = error as? DecodingError {
                    return .decodingError(decodingError)
                } else {
                    return .unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
