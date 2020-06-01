//
//  CatListViewController.swift
//  UI
//
//  Created by Danil Lahtin on 01.06.2020.
//  Copyright © 2020 Danil Lahtin. All rights reserved.
//

import UIKit
import Core


public final class CatListViewController: UIViewController {
    public typealias CellFactory = (UITableView, IndexPath, Cat) -> UITableViewCell
    
    public private(set) weak var tableView: UITableView!
    private var imageLoader: ImageLoader!
    private var cellFactory: CellFactory!
    
    private var cats: [Cat] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    public convenience init(imageLoader: ImageLoader) {
        self.init()
        
        self.imageLoader = imageLoader
        self.cellFactory = { _, _, cat in
            let cell = UITableViewCell()
            
            cell.textLabel?.text = cat.name
            imageLoader.load(from: cat.imageUrl, into: cell.imageView)
            
            return cell
        }
    }
    
    public override func loadView() {
        let tableView = UITableView()
        
        self.view = tableView
        self.tableView = tableView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
    }
}

extension CatListViewController {
    public func catsUpdated(with cats: [Cat]) {
        self.cats = cats
    }
}

extension CatListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cats.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellFactory(tableView, indexPath, cats[indexPath.row])
    }
}
