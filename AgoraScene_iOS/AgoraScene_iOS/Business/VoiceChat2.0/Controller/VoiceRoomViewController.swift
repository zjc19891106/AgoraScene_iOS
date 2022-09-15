//
//  VoiceRoomViewController.swift
//  AgoraScene_iOS
//
//  Created by CP on 2022/9/6.
//

import UIKit
import SnapKit
import ZSwiftBaseLib
import AgoraChat

public enum ROLE_TYPE {
    case owner
    case audience
}

fileprivate let giftMap = [["gift_id":"gift1","gift_name":"sweet_heart","gift_value":"1","gift_count":"1","selected":true],["gift_id":"gift2","gift_name":"flower","gift_value":"2","gift_count":"1","selected":false],["gift_id":"gift3","gift_name":"crystal_box","gift_value":"10","gift_count":"1","selected":false],["gift_id":"gift4","gift_name":"super_agora","gift_value":"20","gift_count":"1","selected":false],["gift_id":"gift5","gift_name":"star","gift_value":"50","gift_count":"1","selected":false],["gift_id":"gift6","gift_name":"lollipop","gift_value":"100","gift_count":"1","selected":false],["gift_id":"gift7","gift_name":"diamond","gift_value":"500","gift_count":"1","selected":false],["gift_id":"gift8","gift_name":"crown","gift_value":"1000","gift_count":"1","selected":false],["gift_id":"gift9","gift_name":"rocket","gift_value":"1500","gift_count":"1","selected":false]]

class VoiceRoomViewController: VRBaseViewController,VoiceRoomIMDelegate {
    
    private var headerView: AgoraChatRoomHeaderView!
    private var rtcView: AgoraChatRoomNormalRtcView!
    private var sRtcView: AgoraChatRoom3DRtcView!
    
    lazy var giftList: VoiceRoomGiftView  = {
        VoiceRoomGiftView(frame: CGRect(x: 10, y: self.chatView.frame.minY - (ScreenWidth/9.0*2), width: ScreenWidth/3.0*2, height: ScreenWidth/9.0*1.8)).backgroundColor(.clear)
    }()
    
    private lazy var chatView: VoiceRoomChatView = {
        VoiceRoomChatView(frame: CGRect(x: 0, y: ScreenHeight - CGFloat(ZBottombarHeight) - (ScreenHeight/667)*210 - 50, width: ScreenWidth, height:(ScreenHeight/667)*210))
    }()
    
    private lazy var chatBar: VoiceRoomChatBar = {
        VoiceRoomChatBar(frame: CGRect(x: 0, y: ScreenHeight-CGFloat(ZBottombarHeight)-50, width: ScreenWidth, height: 50),style:.normal)
    }()
    
    private lazy var inputBar: VoiceRoomInputBar = {
        VoiceRoomInputBar(frame: CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: 60)).backgroundColor(.white)
    }()
    
    private var preView: VMPresentView!
    private var noticeView: VMNoticeView!
    private var isShowPreSentView: Bool = false
    
    public var entity: VRRoomEntity? {
        didSet {
            
        }
    }
    
    public var roomInfo: VRRoomInfo?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigation.isHidden = true
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VoiceRoomIMManager.shared?.delegate = self
        layoutUI()
        self.charBarEvents()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigation.isHidden = false
    }
    
    deinit {
        VoiceRoomIMManager.shared?.delegate = nil
        VoiceRoomIMManager.shared?.userQuitRoom(completion: nil)
    }
    
}

extension VoiceRoomViewController {
    
    //加载RTC
    private func loadRtc() {
        
    }
    
    //加载IM
    private func loadIM() {
        guard let roomId = self.roomInfo?.room?.chat_room_id  else { return }
        VoiceRoomIMManager.shared?.joinedChatRoom(roomId: roomId, completion: { room, error in
            if error == nil {
                
            } else {
                self.view.makeToast("\(error?.errorDescription ?? "")")
            }
        })
    }
    
    //加入房间获取房间详情
    private func requestRoomDetail() {
        
    }
    
    private func layoutUI() {
        
        SwiftyFitsize.reference(width: 375, iPadFitMultiple: 0.6)
        
        let bgImgView = UIImageView()
        bgImgView.image = UIImage(named: "lbg")
        self.view.addSubview(bgImgView)
        
        headerView = AgoraChatRoomHeaderView()
        headerView.entity = roomInfo?.room ?? VRRoomEntity()
        headerView.completeBlock = {[weak self] action in
            self?.didHeaderAction(with: action)
        }
        self.view.addSubview(headerView)
        
        self.sRtcView = AgoraChatRoom3DRtcView()
        self.view.addSubview(self.sRtcView)
        self.sRtcView.isHidden = (roomInfo?.room?.type ?? 0) == 0
        
        self.rtcView = AgoraChatRoomNormalRtcView()
        self.view.addSubview(self.rtcView)
        self.rtcView.isHidden = (roomInfo?.room?.type ?? 0) != 0
        
        bgImgView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalTo(self.view);
        }
        
        let isHairScreen = SwiftyFitsize.isFullScreen
        self.headerView.snp.makeConstraints { make in
            make.left.top.right.equalTo(self.view);
            make.height.equalTo(isHairScreen ? 140~ : 140~ - 25);
        }
        
        self.sRtcView.snp.makeConstraints { make in
            make.top.equalTo(self.headerView.snp.bottom);
            make.left.right.equalTo(self.view);
            make.height.equalTo(550~);
        }
        
        self.rtcView.snp.makeConstraints { make in
            make.top.equalTo(self.headerView.snp.bottom);
            make.left.right.equalTo(self.view);
            make.height.equalTo(240~);
        }
        self.view.addSubViews([self.chatView,self.giftList,self.chatBar,self.inputBar])
        self.inputBar.isHidden = true
        
    }
    
    
    
    private func didHeaderAction(with action: HEADER_ACTION) {
        if action == .back {
            self.notifySeverLeave()
            navigationController?.popViewController(animated: true)
        } else {
            showNoticeView(with: .owner)
        }
    }
    
    private func notifySeverLeave() {
        guard let roomId = self.roomInfo?.room?.chat_room_id  else { return }
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .leaveRoom(roomId: roomId), params: [:]) { dic, error in
            if let result = dic?["result"] as? Bool,error == nil,result {
                debugPrint("result:\(result)")
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.inputBar.endEditing(true)
        if self.isShowPreSentView {
            UIView.animate(withDuration: 0.5, animations: {
                self.preView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: 450~)
            }) { _ in
                self.preView.removeFromSuperview()
                self.preView = nil
                self.sRtcView.isUserInteractionEnabled = true
                self.rtcView.isUserInteractionEnabled = true
                self.headerView.isUserInteractionEnabled = true
                self.isShowPreSentView = false
            }
        }
    }
    
    private func showNoticeView(with role: ROLE_TYPE) {
        let noticeView = VMNoticeView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 220~))
        noticeView.roleType = role
        noticeView.resBlock = {[weak self] (flag, str) in
            self?.dismiss(animated: true)
            guard let str = str else {return}
            
        }
        noticeView.noticeStr = "Welcome to Agora Chat Room 2.0 I am therobot Agora Red. Can you see the robot assistant at the right coner? Click it and experience the new features"
        let vc = VoiceRoomAlertViewController.init(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 220~)), custom: noticeView)
        self.presentViewController(vc)
    }
    
    private func showEQView(with role: ROLE_TYPE) {
        preView = VMPresentView(frame: CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: 450~))
        self.view.addSubview(preView)
        self.isShowPreSentView = true
        self.sRtcView.isUserInteractionEnabled = false
        self.rtcView.isUserInteractionEnabled = false
        self.headerView.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.5, animations: {
            self.preView.frame = CGRect(x: 0, y: ScreenHeight - 450~, width: ScreenWidth, height: 450~)
        }, completion: nil)
    }
    
    private func charBarEvents() {
        self.chatBar.raiseKeyboard = { [weak self] in
            self?.inputBar.isHidden = false
            self?.inputBar.inputField.becomeFirstResponder()
        }
        self.inputBar.sendClosure = { [weak self] in
            guard let `self` = self else { return }
            guard let roomId = self.roomInfo?.room?.room_id  else { return }
            guard let userName = VoiceRoomUserInfo.shared.user?.name  else { return }
            VoiceRoomIMManager.shared?.sendMessage(roomId: roomId, text: $0,ext: ["userName":userName]) { message, error in
                self.inputBar.endEditing(true)
                if error == nil,message != nil {
                    self.showMessage(message: message!)
                } else {
                    self.view.makeToast("\(error?.errorDescription ?? "")")
                }
            }
        }
        self.chatBar.events = { [weak self] in
            switch $0 {
            case .mic:
                self?.chatBar.refresh(event: .mic, state: .unSelected, asCreator: false)
            case .handsUp:
                self?.showUsers()
            case .gift:
                self?.showGiftAlert()
            case .eq:
                self?.showEQView(with: .audience)
            default: break
            }
        }
    }
    
    private func showUsers() {
        let tmp = VoiceRoomUserView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 420),controllers: [VoiceRoomGiftersViewController.init(),VoiceRoomAudiencesViewController.init()]).cornerRadius(20, [.topLeft,.topRight], .white, 0)
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 420)), custom: tmp)
        self.presentViewController(vc)
    }
    
    private func showGiftAlert() {
        let gift = VoiceRoomGiftsView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 300), gifts: self.gifts()).backgroundColor(.white).cornerRadius(20, [.topLeft,.topRight], .clear, 0)
        gift.sendClosure = { [weak self] in
            self?.sendGift(gift: $0)
        }
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 300)), custom: gift)
        self.presentViewController(vc)
    }
    
    private func sendGift(gift: VoiceRoomGiftEntity) {
        if let roomId = self.roomInfo?.room?.room_id,let uid = self.roomInfo?.room?.owner?.uid,let id = gift.gift_id,let name = gift.gift_name,let value = gift.gift_value,let count = gift.gift_count {
            VoiceRoomIMManager.shared?.sendCustomMessage(roomId: roomId, event: VoiceRoomGift, customExt: ["gift_id":id,"gift_name":name,"gift_value":value,"gift_count":count], completion: { message, error in
                if error == nil,message != nil {
                    self.giftList.gifts.append(gift)
                    VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .giftTo(roomId: roomId), params: ["gift_id":id,"num":Int(count) ?? 1,"to_uid":uid]) { dic, error in
                        if let result = dic?["result"] as? Bool,error == nil,result {
                            debugPrint("result:\(result)")
                        }
                    }
                } else {
                    self.view.makeToast("Send failed \(error?.errorDescription ?? "")")
                }
            })
        }
    }
    
    private func gifts() -> [VoiceRoomGiftEntity] {
        var gifts = [VoiceRoomGiftEntity]()
        for dic in giftMap {
            var data = Data()
            do {
                data = try JSONSerialization.data(withJSONObject: dic, options: [])
                let entity = try JSONDecoder().decode(VoiceRoomGiftEntity.self, from: data)
                gifts.append(entity)
            } catch {
                assert(false, "\(error.localizedDescription)")
            }
        }
        return gifts
    }
    
    func reLogin() {
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .login(()), params: ["deviceId":UIDevice.current.deviceUUID,"portrait":VoiceRoomUserInfo.shared.user?.portrait ?? "","name":VoiceRoomUserInfo.shared.user?.name ?? ""],classType:VRUser.self) { [weak self] user, error in
            if error == nil {
                VoiceRoomUserInfo.shared.user = user
                VoiceRoomBusinessRequest.shared.userToken = user?.authorization ?? ""
                AgoraChatClient.shared().renewToken(user?.im_token ?? "")
            } else {
                self?.view.makeToast("\(error?.localizedDescription ?? "")")
            }
        }
    }
    
    //MARK: - VoiceRoomIMDelegate
    func chatTokenDidExpire(code: AgoraChatErrorCode) {
        if code == .tokenExpire {
            self.reLogin()
        }
    }
    
    func chatTokenWillExpire(code: AgoraChatErrorCode) {
        if code == .tokeWillExpire {
            self.reLogin()
        }
    }
    
    func receiveTextMessage(roomId: String, message: AgoraChatMessage) {
        self.showMessage(message: message)
    }
    
    private func showMessage(message: AgoraChatMessage) {
        if let body = message.body as? AgoraChatTextMessageBody,let userName = message.ext?["userName"] as? String {
            let dic = ["userName":userName,"content":body.text]
            self.chatView.messages?.append(self.chatView.getItem(dic: dic, join: false))
            DispatchQueue.main.async {
                self.perform(#selector(VoiceRoomViewController.refreshChatView), with: nil, afterDelay: 1)
            }
        }
    }
    
    @objc func refreshChatView() {
        self.chatView.chatView.reloadData()
        let row = (self.chatView.messages?.count ?? 0) - 1
        self.chatView.chatView.scrollToRow(at: IndexPath(row: row, section: 0), at: .bottom, animated: true)
    }
    
    func receiveGift(roomId: String, meta: [String : String]?) {
        guard let dic = meta else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: dic, options: [])
            let entity = try JSONDecoder().decode(VoiceRoomGiftEntity.self, from: data)
            self.giftList.gifts.append(entity)
        } catch {
            assert(false, "\(error.localizedDescription)")
        }
    }
    
    func receiveApplySite(roomId: String, meta: [String : String]?) {
        
    }
    
    func receiveInviteSite(roomId: String, meta: [String : String]?) {
        
    }
    
    func refuseInvite(roomId: String, meta: [String : String]?) {
        
    }
    
    func userJoinedRoom(roomId: String, username: String) {
        
    }
    
    func announcementChanged(roomId: String, content: String) {
        
    }
    
    func userBeKicked(roomId: String, reason: AgoraChatroomBeKickedReason) {
        VoiceRoomIMManager.shared?.userQuitRoom(completion: nil)
        VoiceRoomIMManager.shared?.delegate = nil
        var message = ""
        switch reason {
        case .beRemoved: message = "you be removed by owner"
        case .destroyed: message = "VoiceRoom is destroyed"
        case .offline: message = "you are offline"
        @unknown default:
            break
        }
        self.view.makeToast(message)
    }
    
    func roomAttributesDidUpdated(roomId: String, attributeMap: [String : String]?, from fromId: String) {
        
    }
    
    func roomAttributesDidRemoved(roomId: String, attributes: [String]?, from fromId: String) {
        
    }
    
}


