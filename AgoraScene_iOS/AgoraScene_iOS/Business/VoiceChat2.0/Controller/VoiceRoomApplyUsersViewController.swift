//
//  VoiceRoomApplyUsersViewController.swift
//  VoiceRoomBaseUIKit
//
//  Created by 朱继超 on 2022/9/11.
//

import UIKit
import ZSwiftBaseLib

public class VoiceRoomApplyUsersViewController: UITableViewController {
    
    private var apply: VoiceRoomAudiencesEntity?
    
    private var roomId: String?
    
    lazy var empty: VREmptyView = {
        VREmptyView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: self.view.frame.height), title: "No Chat Room yet", image: nil).backgroundColor(.white)
    }()
    
    public convenience init(roomId:String) {
        self.init()
        self.roomId = roomId
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchUsers()
        self.view.insertSubview(self.empty, belowSubview: self.tableView)
        self.tableView.tableFooterView(UIView()).registerCell(VoiceRoomApplyCell.self, forCellReuseIdentifier: "VoiceRoomApplyCell").rowHeight(73).backgroundColor(.white).separatorInset(edge: UIEdgeInsets(top: 72, left: 15, bottom: 0, right: 15)).separatorColor(UIColor(0xF2F2F2)).showsVerticalScrollIndicator(false).backgroundColor(.clear)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.apply?.members?.count ?? 0
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "VoiceRoomApplyCell", for: indexPath) as? VoiceRoomApplyCell
        if cell == nil {
            cell = VoiceRoomApplyCell(style: .default, reuseIdentifier: "VoiceRoomApplyCell")
        }
        // Configure the cell...
        cell?.selectionStyle = .none
        cell?.user = self.apply?.members?[safe: indexPath.row]
        cell?.agreeClosure = { [weak self] in
            self?.agreeUserApply(user: $0)
            self?.apply?.members?[safe: indexPath.row]?.invited = true
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        return cell ?? VoiceRoomApplyCell()
    }

    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.apply?.cursor != nil,(self.apply?.members?.count ?? 0) - 2 == indexPath.row, (self.apply?.total ?? 0) >= (self.apply?.members?.count ?? 0) {
            self.fetchUsers()
        }
    }
    
}


extension VoiceRoomApplyUsersViewController {
    
    private func fetchUsers() {
        VoiceRoomBusinessRequest.shared.sendGETRequest(api: .fetchApplyMembers(roomId: self.roomId ?? "", cursor: self.apply?.cursor ?? "", pageSize: 15), params: [:], classType: VoiceRoomAudiencesEntity.self) { model, error in
            if model != nil,error == nil {
                if self.apply == nil {
                    self.apply = model
                } else {
                    self.apply?.cursor = model?.cursor
                    self.apply?.members?.append(contentsOf: model?.members ?? [])
                }
                self.tableView.reloadData()
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")")
            }
            self.empty.isHidden = (self.apply?.members?.count ?? 0 != 0)
        }
    }
    
    private func agreeUserApply(user: VRUser?) {
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .agreeApply(roomId: self.roomId ?? ""), params: ["uid":user?.uid ?? ""]) { dic, error in
            if dic != nil,error == nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("Agree success!")
                } else {
                    self.view.makeToast("Agree failed!")
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")")
            }
        }
    }
}
