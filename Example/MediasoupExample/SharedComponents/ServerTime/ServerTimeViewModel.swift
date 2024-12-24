//
//  ServerTimeViewModel.swift
//  SqeIdFramework
//
//  Created by Jimmy Suhartono on 05/07/24.
//

import Foundation

protocol ServerTimeViewModel: AuthenticationBaseViewModel {
    func fetchServerTime(timeoutInMilliseconds: TimeInterval, completion: @escaping (Result<Time, NetworkError>) -> Void)
}

class ServerTimeViewModelImpl: ServerTimeViewModel {
    private let serverTimeService: ServerTimeService
    
    let dependencies: AuthenticationDependencies

    init(dependencies: AuthenticationDependencies,
         serverTimeService: ServerTimeService? = nil) {
        self.dependencies = dependencies
        self.serverTimeService = serverTimeService ?? ServerTimeServiceImpl(baseUrl: dependencies.apiBaseUrl.absoluteString)
    }
    
    func fetchServerTime(timeoutInMilliseconds: TimeInterval, completion: @escaping (Result<Time, NetworkError>) -> Void) {
        let properties = [
            CommonEventPropertyKeys.clientId: dependencies.clientId
        ]
        trackEvent(with: CommonEventNames.getTime, properties: properties)
        
        serverTimeService.getTime(timeoutInMilliseconds: timeoutInMilliseconds) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let time):
                trackEvent(with: CommonEventNames.getTimeSucceed, properties: properties)
                completion(.success(time))
            case .failure(let error):
                trackEvent(with: CommonEventNames.getTimeFailed, properties: AnalyticsUtil.updatePropertiesWithError(properties: properties, error: error.debugDescription))
                completion(.failure(error))
            }
        }
    }
    
}
