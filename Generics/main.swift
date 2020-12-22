//
//  main.swift
//  Generics
//
//  Created by FeedMyTummy on 12/21/20.
//

import Foundation

enum LocalStoreError: Error {
    case notStoredLocally
    case unknown
}

protocol LocalStoreFetcher {
    associatedtype StoredType
    
    func fetch(identifier: String, _ completion: (Result<StoredType?, LocalStoreError>) -> Void)
}

protocol LocalStorePersister {
    associatedtype StoredType
    
    func persist(_ item: StoredType)
}

protocol LocalStore: LocalStoreFetcher, LocalStorePersister { /* EMPTY */ }

enum RemoteStoreError: Error {
    case unknown
}

protocol RemoteStoreFetcher {
    associatedtype StoredType
    
    func fetch(identifier: String, _ completion: (Result<StoredType, RemoteStoreError>) -> Void)
}

protocol RemoteStorePersister {
    associatedtype StoredType
    
    func persists(_ item: StoredType, _ completion: (Result<StoredType, RemoteStoreError>) -> Void)
}


protocol RemoteStore: RemoteStoreFetcher, RemoteStorePersister { /* EMPTY */ }

enum CacheBackedDataStoreError: Error {
    case localStoreError(LocalStoreError)
    case remoteStoreError(RemoteStoreError)
}

struct CacheBackedVideoStore<Local: LocalStore, Remote: RemoteStore> where Local.StoredType == Remote.StoredType {
    let localStore: Local
    let remoteStore: Remote
    
    func fetch(identifier: String, _ completion: (Result<Remote.StoredType, CacheBackedDataStoreError>) -> Void) {
        localStore.fetch(identifier: identifier) { result in
            switch result {
            case .success(let localData):
                if let localData = localData{
                    completion(.success(localData))
                } else {
                    remoteStore.fetch(identifier: identifier) { result in
                        switch result {
                        case .success(let remoteData):
                            localStore.persist(remoteData)
                            completion(.success(remoteData))
                        case .failure(let error):
                            completion(.failure(.remoteStoreError(error)))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(.localStoreError(error)))
            }
        }
    }
}

struct Video { /* EMPTY */ }

struct LocalVideoStore: LocalStore {
    
    func fetch(identifier: String, _ completion: (Result<Video?, LocalStoreError>) -> Void) {
        completion(.success(nil))
    }
    
    func persist(_ item: Video) {
        
    }
}

struct RemoteVideoStore: RemoteStore {
    
    func fetch(identifier: String, _ completion: (Result<Video, RemoteStoreError>) -> Void) {
        completion(.failure(.unknown))
    }
    
    func persists(_ item: Video, _ completion: (Result<Video, RemoteStoreError>) -> Void) {
        
    }
    
}

let localVideos = LocalVideoStore()
let remoteStore = RemoteVideoStore()

let cachedBackedVideoStore = CacheBackedVideoStore(localStore: localVideos, remoteStore: remoteStore)
cachedBackedVideoStore.fetch(identifier: "") { result in
    switch result {
    case .success(let video):
        print(video)
    case .failure(let error):
        print(error)
    }
}
