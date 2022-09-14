//
//  VRRoomsViewController.swift
//  Pods-VoiceRoomBaseUIKit_Example
//
//  Created by 朱继超 on 2022/8/24.
//

import UIKit
import ZSwiftBaseLib

let bottomSafeHeight = safeAreaExist ? 33:0
let page_size = 15

public final class VRRoomsViewController: VRBaseViewController {
    
    var index: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.container.index = self.index
            }
        }
    }
    
    private let all = VRAllRoomsViewController()
    private let normal = VRNormalRoomsViewController()
    private let spatialSound = VRSpatialSoundViewController()
    
    lazy var background: UIImageView = {
        UIImageView(frame: self.view.frame).image(UIImage("roomList")!)
    }()
    
    lazy var menuBar: VRRoomMenuBar = {
        VRRoomMenuBar(frame: CGRect(x: 20, y: ZNavgationHeight, width: ScreenWidth-40, height: 35), items: VRRoomMenuBar.entities, indicatorImage: UIImage("fline")!,indicatorFrame: CGRect(x: 0, y: 35 - 2, width: 18, height: 2)).backgroundColor(.clear)
    }()
    
    lazy var container: VoiceRoomPageContainer = {
        VoiceRoomPageContainer(frame: CGRect(x: 0, y: self.menuBar.frame.maxY, width: ScreenWidth, height: ScreenHeight - self.menuBar.frame.maxY - 10 - CGFloat(ZBottombarHeight) - 30), viewControllers: [self.all,self.normal,self.spatialSound]).backgroundColor(.clear)
    }()
    
    lazy var create: VRRoomCreateView = {
        VRRoomCreateView(frame: CGRect(x: 0, y: self.container.frame.maxY - 50, width: ScreenWidth, height: 72)).image(UIImage("blur")!).backgroundColor(.clear)
    }()
    
    let avatar = UIButton {
        UIButton(type: .custom).frame(CGRect(x: ScreenWidth - 70, y: ZNavgationHeight - 40, width: 50, height: 30)).backgroundColor(.clear).tag(111)
        UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30)).image(UIImage("avatar")!).contentMode(.scaleAspectFit).tag(112)
        UIImageView(frame: CGRect(x: 38, y: 9, width: 12, height: 12)).image(UIImage("arrow_right")!).contentMode(.scaleAspectFit)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubViews([self.background,self.menuBar,self.container,self.create])
        self.view.bringSubviewToFront(self.navigation)
        self.navigation.title.text = "Agora Chat Room"
        self.navigation.addSubview(self.avatar)
        self.avatar.addTarget(self, action: #selector(editProfile), for: .touchUpInside)
        if let header = self.avatar.viewWithTag(112) as? UIImageView {
            header.image = UIImage(named: VoiceRoomUserInfo.shared.user?.portrait ?? "")
        }
        self.viewsAction()
        self.childViewControllersEvent()
    }
    

}

extension VRRoomsViewController {
        
    public override var backImageName: String { "" }
    
    @objc func editProfile() {
        self.navigationController?.pushViewController(VRUserProfileViewController.init(), animated: true)
    }
    
    private func viewsAction() {
        self.create.action = { [weak self] in
            self?.navigationController?.pushViewController(VRCreateRoomViewController.init(), animated: true)
        }
        self.container.scrollClosure = { [weak self] in
            let idx = IndexPath(row: $0, section: 0)
            guard let `self` = self else { return }
            self.menuBar.refreshSelected(indexPath: idx)
        }
        self.menuBar.selectClosure = { [weak self] in
            self?.index = $0.row
        }
    }
    
    private func entryRoom(room: VRRoomEntity) {
        if room.is_private ?? false {
            let alert = VoiceRoomPasswordAlert(frame: CGRect(x: 37.5, y: 168, width: ScreenWidth-75, height: (ScreenWidth-75)*(240/300.0))).cornerRadius(16).backgroundColor(.white)
            let vc = VoiceRoomAlertViewController(compent: self.component(), custom: alert)
            self.presentViewController(vc)
            alert.actionEvents = {
                if $0 == 31 {
                    room.roomPassword = alert.code
                    self.loginIMThenPush(room: room)
                }
                vc.dismiss(animated: true)
            }
        }
        
    }
    
    private func component() -> PresentedViewComponent {
        var component = PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: ScreenHeight))
        component.destination = .topBaseline
        component.canPanDismiss = false
        return component
    }
    
    private func loginIMThenPush(room: VRRoomEntity) {
        VoiceRoomIMManager.shared?.loginIM(userName: VoiceRoomUserInfo.shared.user?.chat_uid ?? "", token: VoiceRoomUserInfo.shared.user?.authorization ?? "", completion: { userName, error in
            if error == nil {
                let vc = VoiceRoomViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }

    private func entryRoom(with entity: VRRoomEntity) {
        let vc = VoiceRoomViewController()
        vc.entity = entity
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func roomListEvent() {
        self.roomList.didSelected = { [weak self] in
            print($0.name ?? "")
            self?.entryRoom(with: $0)
        }
        self.roomList.loadMore = { [weak self] in
            if self?.roomList.rooms?.total ?? 0 > self?.roomList.rooms?.rooms?.count ?? 0 {
                self?.fetchRooms(cursor: self?.roomList.rooms?.cursor ?? "")
            }
        }
    }

    private func childViewControllersEvent() {
        self.all.didSelected = { [weak self] in
            self?.entryRoom(room: $0)
        }
        self.all.totalCountClosure = { [weak self] in
            guard let `self` = self else { return }
            self.menuBar.dataSource[0].detail = "(\($0))"
            self.menuBar.menuList.reloadItems(at: [IndexPath(row: 0, section: 0)])
        }
        
        self.normal.didSelected = { [weak self] in
            self?.entryRoom(room: $0)
        }
        self.normal.totalCountClosure = { [weak self] in
            guard let `self` = self else { return }
            self.menuBar.dataSource[1].detail = "(\($0))"
            self.menuBar.menuList.reloadItems(at: [IndexPath(row: 1, section: 0)])
        }
        
        self.spatialSound.didSelected = { [weak self] in
            self?.entryRoom(room: $0)
        }
        self.spatialSound.totalCountClosure = { [weak self] in
            guard let `self` = self else { return }
            self.menuBar.dataSource[2].detail = "(\($0))"
            self.menuBar.menuList.reloadItems(at: [IndexPath(row: 2, section: 0)])
        }
    }
}