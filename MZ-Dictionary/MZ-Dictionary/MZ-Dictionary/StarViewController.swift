//
//  StarViewController.swift
//  MZ-Dictionary
//
//  Created by 김지은 on 2023/11/09.
//

import UIKit

class StarViewController: UIViewController {

    /// main tableview
    @IBOutlet weak var tvMain: UITableView!
    
    var list: [ListModel] = []
    
    var pageNum = 10
    var totalCount = 0
    var isTotalData = false
    var isDataRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCell()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchListCount()
        fetchList()
    }
    
    func fetchListCount() {
        Task {
            let (result, error) = await FireStoreManager.shared.fetchNumberOfStarDoc()
            if let error {
                print(error.localizedDescription)
                return
            }
            totalCount = result ?? 0
            print("totalCount: \(totalCount)")
        }
    }
    
    func fetchList() {
        FireStoreManager.shared.fetchStarList(pageSize: pageNum) { list in
            if self.pageNum == 10 {
                self.list = list ?? []
            } else {
                self.list += list ?? []
            }
            self.isTotalData = (self.pageNum >= self.totalCount)
            self.tvMain.reloadData()
        }
    }
    
    func registerTableViewCell() {
        tvMain.register(UINib(nibName: "MainTableViweCell", bundle: nil), forCellReuseIdentifier: "MainTableViweCell")
        tvMain.delegate = self
        tvMain.dataSource = self
    }
}
extension StarViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.height
        
        if offsetY > (contentHeight - height) && isDataRunning == false {
            isDataRunning = true
            pageNum += 10
            if pageNum > totalCount {
                pageNum = totalCount
            }
            
            if isTotalData == false {
                DispatchQueue.main.async {
                    self.tvMain.reloadSections(IndexSet(integer: 1), with: .none)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                    self.fetchList()
                })
            }
        }
     }
}

extension StarViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return list.count
        } else if section == 1 && isDataRunning && isTotalData == false {
            return 1
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StarTableViewCell", for: indexPath) as! StarTableViewCell
            cell.lblTitle.text = list[indexPath.row].title ?? ""
            cell.lblContent.text = list[indexPath.row].content ?? ""
            cell.btnStar.isSelected = list[indexPath.row].star ?? false
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell

            cell.start()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //마지막 인덱스 일때 data 추가 가능 여부를 변경한다.
        if indexPath.row == list.count - 1 {
            isDataRunning = false
        }
    }
}

class StarTableViewCell: UITableViewCell {
    
    /// title label
    @IBOutlet weak var lblTitle: UILabel!
    /// content label
    @IBOutlet weak var lblContent: UILabel!
    
    @IBOutlet weak var btnStar: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func starButtonSelected(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
}
