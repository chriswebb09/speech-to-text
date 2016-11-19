//
//  NuanceAPIClient.swift
//  speech-to-text
//
//  Created by Christopher Webb-Orenstein on 11/19/16.
//  Copyright © 2016 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

typealias JSONData = [String: Any]

struct Client {
    
    fileprivate static let baseURL: String = "apistring"
    
    func get(request: ClientRequest, handler: @escaping ([String]?) -> Void) {
        let urlRequest = generateURLRequest(with: request.url)
        let urlSession = generateURLSession()
        
        sendAPICall(withSession: urlSession, request: urlRequest) { json in
            guard let json = json else { handler(nil); return }
            print(json)
        }
    }
    
}

extension Client {
    func generateURLRequest(with url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }
    
    func generateURLSession() -> URLSession {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        return session
    }
    
    func sendAPICall(withSession session: URLSession, request: URLRequest, handler: @escaping (JSONData?) -> Void) {
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data else { handler(nil); return }
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! JSONData else { handler(nil); return }
                handler(json)
            }
            }.resume()
    }
    
}

enum ClientRequest {
    case search, results, stream
    var url: URL {
        switch self {
        case .search:
            return URL.clientURL(withEndpoint: "/results")
        case .results:
            return URL.clientURL(withEndpoint: "/results")
        case .stream:
            return URL.clientURL(withEndpoint: "/stream")
        }
        
    }
}

struct ValidSearch {
    
    let string: String
    
    init?(_ string: String) {
        guard let escapedString = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return nil }
        self.string = escapedString
    }
    
}

extension URL {
    
    static func clientURL(withEndpoint endpoint: String) -> URL {
        return URL(string: Client.baseURL + endpoint)!
    }
    
}
