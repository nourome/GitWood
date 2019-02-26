//
//  MainViewModel.swift
//  GitWood
//
//  Created by Nour on 23/02/2019.
//  Copyright © 2019 Nour Saffaf. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol ViewModel {}

protocol UITableViewModelProtocol {
    associatedtype type
    associatedtype cell
    var count: Int {get}
    var items:[type] {get set}
    var moreItemsIndexPath: [IndexPath] {get}
    func cellModelFor(indexPath: IndexPath) -> cell
}

class MainViewModel<S: StorageProtocol>: UITableViewModelProtocol, ViewModel {
    
    typealias repos = TrendingRepo
    typealias cell = TrendingCellModel
    
    let storage: S
    let apiModel =  API3Model()
    private var _pageNumber = 0
    private let disposeBag = DisposeBag()
    private var lastIndexPathItem: Int = -1
    
    init(storage: S) {
        self.storage = storage
    }
    
    var pageNumber: Int {
        get {
            return _pageNumber
        }
        set(page) {
            _pageNumber = page
        }
    }
    
    
    var count: Int  {
        get {
            return items.count
        }
    }

    var moreItemsIndexPath: [IndexPath] {
        get {
            let indexPaths =  items.enumerated()
                .filter{$0.offset > lastIndexPathItem}
                .map {IndexPath(item: $0.offset, section: 0)}
            self.lastIndexPathItem = self.items.count - 1
            return indexPaths
            }
    }
    
    var items: [repos] = []
    
    
    
    func cellModelFor(indexPath: IndexPath) -> cell {
        
        if items.count < indexPath.item || items.isEmpty {
            fatalError("Items is empty or index is larger than size")
        }
        
        return TrendingCellModel(id: 0, name: items[indexPath.item].name,
                        detailed: items[indexPath.item].description ?? "No description available",
                        forks:items[indexPath.item].forks,
                        stars:items[indexPath.item].stars,
                        avatarUrl: items[indexPath.item].owner.avatarUrl,
                        isFavorited: items[indexPath.item].isFavorited ?? false)
    }
    
   
    
    func loadTrendingRepos(period: RequestPeriod)-> Single<ResponseStatus> {
        return Single<ResponseStatus>.create { single  in
            self.pageNumber += 1
            do {
                let url =  try self.apiModel.buildRequestUrl(.Trending(period), page: self._pageNumber)
              
                //check if the request is cached so you don't use another api call
                
                let req =  URLRequest(url: url)
                URLSession.shared.rx.response(request: req).subscribe(onNext: { res in
                    do {
                        guard try self.apiModel.validate(response: res) else {
                            single(.success(.Failure("HTTP response could not be validated")))
                            return
                        }
                       
                        let repositories =  try self.apiModel.decode(response: res.data, for: .Trending)
                        let trendingRepos = repositories.map{$0 as! MainViewModel<S>.repos}
                        let sorted =  trendingRepos.sorted(by: { $0.stars > $1.stars })
                        
                        if sorted.isEmpty {
                            single(.success(.Empty))
                        } else {
                            if self.items.isEmpty {
                                self.items.append(contentsOf: sorted)
                                self.lastIndexPathItem = self.items.count - 1
                                single(.success(.Success))
                            } else {
                                self.items.append(contentsOf: sorted)
                                single(.success(.More))
                            }
                        }
                       
                    }catch {
                        single(.error(error))
                    }
                    
                }, onError: { err in
                    single(.error(err))
                }).disposed(by: self.disposeBag)
                
            } catch {
                single(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
    func removeFavoriteRepo(at indexPath: IndexPath) -> Bool {
        
        let removeOperation = storage.remove(type: .Favorite, id: items[indexPath.item].id)
        
        if !removeOperation {
            return false
        } else {
            items[indexPath.item].isFavorited = true
            return true
        }
        
    }
    
    func insertOrUpdateRepo(at indexPath: IndexPath) -> Bool{
        
        let insertOperation = storage.insertOrUpdate(type: .Favorite, records: [items[indexPath.item]])
        
        if insertOperation {
            items[indexPath.item].isFavorited = true
        }
        
        return insertOperation
    }
    
    func reset() {
        items = []
        lastIndexPathItem = -1
    }
    
}
