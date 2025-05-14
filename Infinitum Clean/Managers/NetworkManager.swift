import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(Int)
    case unauthorized
    case noInternetConnection
}

final class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constants.API.timeout
        configuration.timeoutIntervalForResource = Constants.API.timeout
        
        session = URLSession(configuration: configuration)
        
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: Constants.API.baseURL + "/" + Constants.API.version + "/" + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Add default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    AppLogger.shared.error("Decoding failed: \(error.localizedDescription)", category: .network)
                    throw NetworkError.decodingFailed(error)
                }
            case 401:
                throw NetworkError.unauthorized
            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.invalidResponse
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    throw NetworkError.noInternetConnection
                default:
                    throw NetworkError.requestFailed(error)
                }
            }
            throw NetworkError.requestFailed(error)
        }
    }
    
    func downloadFile(from url: URL, to destination: URL) async throws {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        try data.write(to: destination)
    }
    
    func uploadFile(
        from sourceURL: URL,
        to endpoint: String,
        method: String = "POST",
        headers: [String: String] = [:]
    ) async throws {
        guard let url = URL(string: Constants.API.baseURL + "/" + Constants.API.version + "/" + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add default headers
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let (_, response) = try await session.upload(for: request, fromFile: sourceURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
} 