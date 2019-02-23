//
//  Api3Model.swift
//  GitWood
//
//  Created by Nour on 23/02/2019.
//  Copyright © 2019 Nour Saffaf. All rights reserved.
//

import Foundation

struct API3Model: APIModel {
    static var version = 3
    var token: String? = nil
    static internal var baseUrl: String = "https://api.github.com/"
    var page: Int = 1
    
    func buildRequestUrl(_ requestType: RequestType) throws -> URL {
        
        let requestPathExt = requestType.urlPathExt
        let apiUrl = API3Model.baseUrl.appending(requestPathExt)
        
        guard let requestURL = URL(string: apiUrl) else { throw ApiError.ErrorConstrcutURL("Api URL is wrong. Fix the static var ApiUrl \(apiUrl)") }
        
        guard var requestUrlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: true) else {
            throw ApiError.ErrorConstrcutURL("URL component could not be built from ApiURL!")
        }
        
        if (token != nil) {
            
        }
        
        requestUrlComponents.queryItems?.append(URLQueryItem(name: "sort", value: RequestSort.Stars.rawValue))
        
        requestUrlComponents.queryItems?.append(URLQueryItem(name: "order", value: RequestOrder.Desc.rawValue))
        
        
        guard let url = requestUrlComponents.url else {
            throw ApiError.ErrorConstrcutURL("Could not build url from components")
        }
        
        return url
    }
    
    func decode(response: Data, for requestType: ResponseType) throws -> [RepoModel]? {
        
        do {
            switch requestType {
            case .Trending:
                return try JSONDecoder().decode(TrendingResponse.self, from: response).items
            default:
                return nil
            }
        } catch {
            throw ApiError.ErrorDecodeResponse("Decoding failed \(error)")
        }
    }
    
}
