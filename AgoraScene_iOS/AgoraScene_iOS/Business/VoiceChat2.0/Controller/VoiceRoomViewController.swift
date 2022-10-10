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
import SVGAPlayer
import KakaJSON
import AgoraRtcKit

public enum ROLE_TYPE {
    case owner
    case audience
}


fileprivate let giftMap = [["gift_id":"VoiceRoomGift1","gift_name":LanguageManager.localValue(key: "Sweet Heart"),"gift_price":"1","gift_count":"1","selected":true],["gift_id":"VoiceRoomGift2","gift_name":LanguageManager.localValue(key: "Flower"),"gift_price":"2","gift_count":"1","selected":false],["gift_id":"VoiceRoomGift3","gift_name":LanguageManager.localValue(key: "Crystal Box"),"gift_price":"10","gift_count":"1","selected":false],["gift_id":"VoiceRoomGift4","gift_name":LanguageManager.localValue(key: "Super Agora"),"gift_price":"20","gift_count":"1","selected":false],["gift_id":"VoiceRoomGift5","gift_name":LanguageManager.localValue(key: "Star"),"gift_price":"50","gift_count":"1","selected":false],["gift_id":"VoiceRoomGift6","gift_name":LanguageManager.localValue(key: "Lollipop"),"gift_price":"100","gift_count":"1","selected":false],["gift_id":"VoiceRoomGift7","gift_name":LanguageManager.localValue(key: "Diamond"),"gift_price":"500","gift_count":"1","selected":false],["gift_id":"VoiceRoomGift8","gift_name":LanguageManager.localValue(key: "Crown"),"gift_price":"1000","gift_count":"1","selected":false],["gift_id":"VoiceRoomGift9","gift_name":LanguageManager.localValue(key: "Rocket"),"gift_price":"1500","gift_count":"1","selected":false]]

class VoiceRoomViewController: VRBaseViewController {
    
    lazy var toastPoint: CGPoint = {
        CGPoint(x: self.view.center.x, y: self.view.center.y+70)
    }()
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
    
    private var headerView: AgoraChatRoomHeaderView!
    private var rtcView: AgoraChatRoomNormalRtcView!
    private var sRtcView: AgoraChatRoom3DRtcView!
    
    @UserDefault("VoiceRoomUserAvatar", defaultValue: "") var userAvatar
    
    private lazy var chatView: VoiceRoomChatView = {
        VoiceRoomChatView(frame: CGRect(x: 0, y: ScreenHeight - CGFloat(ZBottombarHeight) - (ScreenHeight/667)*210 - 50, width: ScreenWidth, height:(ScreenHeight/667)*210))
    }()
    
    private lazy var chatBar: VoiceRoomChatBar = {
        VoiceRoomChatBar(frame: CGRect(x: 0, y: ScreenHeight-CGFloat(ZBottombarHeight)-50, width: ScreenWidth, height: 50),style:self.roomInfo?.room?.type ?? 0 == 1 ? .spatialAudio:.normal)
    }()
    
    private lazy var inputBar: VoiceRoomInputBar = {
        VoiceRoomInputBar(frame: CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: 60)).backgroundColor(.white)
    }()
    
    private var preView: VMPresentView!
    private var noticeView: VMNoticeView!
    private var isShowPreSentView: Bool = false
    private var rtckit: ASRTCKit = ASRTCKit.getSharedInstance()
    private var isOwner: Bool = false
    private var ains_state: AINS_STATE = .mid
    private var local_index: Int? = nil
    private var alienCanPlay: Bool = true
    private var vmType: VMMUSIC_TYPE = .social
    
    public var roomInfo: VRRoomInfo? {
        didSet {
            if let entity = roomInfo?.room {
                if headerView == nil {return}
                headerView.entity = entity
            }
            VoiceRoomUserInfo.shared.currentRoomOwner = self.roomInfo?.room?.owner
            if let mics = roomInfo?.mic_info {
                if let type = roomInfo?.room?.type {
                    if type == 0 && self.rtcView != nil {
                        self.rtcView.micInfos = mics
                    } else if type == 1 && self.sRtcView != nil {
                        
                    }
                }
            }
        }
    }
        
    convenience init(info: VRRoomInfo) {
        self.init()
        self.roomInfo = info
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigation.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = VoiceRoomUserInfo.shared.user else {return}
        guard let owner = self.roomInfo?.room?.owner else {return}
        guard let type = self.roomInfo?.room?.sound_effect else {return}
        isOwner = user.uid == owner.uid
        local_index = isOwner ? 0 : nil
        vmType = getSceneType(type)
        
        VoiceRoomIMManager.shared?.delegate = self
        VoiceRoomIMManager.shared?.addChatRoomListener()
        //获取房间详情
        requestRoomDetail()
        
        //加载RTC+IM
        loadKit()
        //布局UI
        layoutUI()
        //处理底部事件
        self.charBarEvents()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigation.isHidden = false
    }
    
    deinit {
        leaveRoom()
        VoiceRoomUserInfo.shared.currentRoomOwner = nil
        VoiceRoomIMManager.shared?.delegate = nil
        VoiceRoomIMManager.shared?.userQuitRoom(completion: nil)
    }
    
}

extension VoiceRoomViewController {
    //加载RTC
    private func loadKit() {
        
        guard let channel_id = self.roomInfo?.room?.channel_id else {return}
        guard let roomId = self.roomInfo?.room?.chatroom_id  else { return }
        guard let rtcUid = VoiceRoomUserInfo.shared.user?.rtc_uid else {return}
        rtckit.setClientRole(role: isOwner ? .owner : .audience)
        rtckit.delegate = self
        
        var rtcJoinSuccess: Bool = false
        var IMJoinSuccess: Bool = false
        
        let VMGroup = DispatchGroup()
        let VMQueue = DispatchQueue(label: "com.agora.vm.www")
        
        VMGroup.enter()
        VMQueue.async {[weak self] in
            rtcJoinSuccess = self?.rtckit.joinVoicRoomWith(with: "\(channel_id)", rtcUid: Int(rtcUid) ?? 0, type: self?.vmType ?? .social) == 0
            VMGroup.leave()
        }
        
        VMGroup.enter()
        VMQueue.async {[weak self] in
            
            VoiceRoomIMManager.shared?.joinedChatRoom(roomId: roomId, completion: {[weak self] room, error in
                guard let `self` = self else { return }
                if error == nil {
                    IMJoinSuccess = true
                    VMGroup.leave()
                    self.view.makeToast("join IM success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                } else {
                    self.view.makeToast("\(error?.errorDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
                    IMJoinSuccess = false
                    VMGroup.leave()
                    self.view.makeToast("join IM failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            })
            
        }
        
        VMGroup.notify(queue: VMQueue){[weak self] in
            DispatchQueue.main.async {
                let joinSuccess = rtcJoinSuccess && IMJoinSuccess
                //上传登陆信息到服务器
                self?.uploadStatus(status: joinSuccess)
            }
        }
        
    }
    
    private func getSceneType(_ type: String) -> VMMUSIC_TYPE {
        switch type {
        case LanguageManager.localValue(key: "Karaoke"):
            return .ktv
        case LanguageManager.localValue(key: "Gaming Buddy"):
            return .game
        case LanguageManager.localValue(key: "Professional Bodcaster"):
            return .anchor
        default:
            return .social
        }
    }
    
    //加入房间获取房间详情
    private func requestRoomDetail() {
        
        //如果不是房主。需要主动获取房间详情
        guard let room_id = self.roomInfo?.room?.room_id else {return}
        VoiceRoomBusinessRequest.shared.sendGETRequest(api: .fetchRoomInfo(roomId: room_id), params: [:], classType: VRRoomInfo.self) {[weak self] room, error in
            if error == nil {
                guard let info = room else { return }
                self?.roomInfo = info
            } else {
                self?.view.makeToast("\(error?.localizedDescription ?? "")",point: self?.toastPoint ?? .zero, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    private func layoutUI() {
        
        SwiftyFitsize.reference(width: 375, iPadFitMultiple: 0.6)
        
        let bgImgView = UIImageView()
        bgImgView.image = UIImage(named: "lbg")
        self.view.addSubview(bgImgView)
        
        headerView = AgoraChatRoomHeaderView()
        headerView.completeBlock = {[weak self] action in
            self?.didHeaderAction(with: action)
        }
        self.view.addSubview(headerView)
        
        self.sRtcView = AgoraChatRoom3DRtcView()
        self.view.addSubview(self.sRtcView)
        
        self.rtcView = AgoraChatRoomNormalRtcView()
        self.rtcView.clickBlock = {[weak self] (type, tag) in
            self?.didRtcAction(with: type, tag: tag)
        }
        self.view.addSubview(self.rtcView)
        
        if let entity = self.roomInfo?.room {
            self.sRtcView.isHidden = entity.type == 0
            self.rtcView.isHidden = entity.type == 1
            headerView.entity = entity
        }
        
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
        if self.roomInfo?.room?.type ?? 0 == 1 {
            self.view.addSubViews([self.chatBar])
            self.inputBar.isHidden = true
        } else {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(resignKeyboard))
            pan.minimumNumberOfTouches = 1
            self.rtcView.addGestureRecognizer(pan)
            self.view.addSubViews([self.chatView,self.giftList(),self.chatBar,self.inputBar])
            self.inputBar.isHidden = true
        }
        self.chatView.messages?.append(self.startMessage())
    }
    
    private func giftList() -> VoiceRoomGiftView {
        VoiceRoomGiftView(frame: CGRect(x: 10, y: self.chatView.frame.minY - (ScreenWidth/9.0*2), width: ScreenWidth/3.0*2, height: ScreenWidth/9.0*1.8)).backgroundColor(.clear).tag(1111)
    }
    
    private func startMessage() -> VoiceRoomChatEntity {
        VoiceRoomUserInfo.shared.currentRoomOwner = self.roomInfo?.room?.owner
        let entity = VoiceRoomChatEntity()
        entity.userName = self.roomInfo?.room?.owner?.name
        entity.content = "Welcome to Agora Chat Room! Sexual or violent content is strictly prohibited. Speak kindly, friendship muchly."
        entity.attributeContent = entity.attributeContent
        entity.uid = self.roomInfo?.room?.owner?.uid
        entity.width = entity.width
        entity.height = entity.height
        return entity
    }
    
    private func uploadStatus( status: Bool) {
        guard let roomId = self.roomInfo?.room?.room_id  else { return }
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .joinRoom(roomId: roomId), params: [:]) { dic, error in
            if let result = dic?["result"] as? Bool,error == nil,result {
                self.view.makeToast("Joined successful!",point: self.toastPoint, title: nil, image: nil, completion: nil)
            } else {
                self.didHeaderAction(with: .back)
            }
        }
    }
    
    @objc private func resignKeyboard() {
        self.inputBar.hiddenInputBar()
    }

    private func didHeaderAction(with action: HEADER_ACTION) {
        if action == .back {
            self.notifySeverLeave()
            self.rtckit.leaveChannel()

            //giveupStage()
            cancelRequestSpeak(index: nil)
            if self.isOwner {
                if let vc = self.navigationController?.viewControllers.filter({ $0 is VRRoomsViewController
                }).first {
                    self.navigationController?.popToViewController(vc, animated: true)
                }
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else if action == .notice {
            showNoticeView(with: self.isOwner ? .owner : .audience)
        } else if action == .rank {
            //展示土豪榜
            self.showUsers()
        } else if action == .soundClick {
            showSoundView()
        }
    }
    
    private func didRtcAction(with type: AgoraChatRoomBaseUserCellType, tag: Int) {
        if type == .AgoraChatRoomBaseUserCellTypeAdd {
            //这里需要区分观众与房主
            if isOwner {
               showApplyAlert(tag - 200)
            } else {
                if local_index != nil {
                    changeMic(from: local_index!, to: tag - 200)
                } else {
                    userApplyAlert(tag - 200)
                }
            }
        } else if type == .AgoraChatRoomBaseUserCellTypeAlienActive {
            showActiveAlienView(true)
        } else if type == .AgoraChatRoomBaseUserCellTypeAlienNonActive {
            showActiveAlienView(false)
        } else if type == .AgoraChatRoomBaseUserCellTypeNormalUser {
               //用户下麦或者mute自己
            if tag - 200 == local_index {
                showMuteView(with: tag - 200)
            } else {
                if isOwner {
                    showApplyAlert(tag - 200)
                }
            }
        } else if type == .AgoraChatRoomBaseUserCellTypeLock {
            if isOwner {
               showApplyAlert(tag - 200)
            } else {
               //用户下麦或者mute自己
            }
        } else if type == .AgoraChatRoomBaseUserCellTypeMute {
            if tag - 200 == local_index {
                showMuteView(with: tag - 200)
            } else {
                if isOwner {
                    showApplyAlert(tag - 200)
                }
            }
        } else if type == .AgoraChatRoomBaseUserCellTypeMuteAndLock {
            if isOwner {
               showApplyAlert(tag - 200)
            } else {
               //用户下麦或者mute自己
            }
        } else if type == .AgoraChatRoomBaseUserCellTypeForbidden {
            if tag - 200 == local_index {
                showMuteView(with: tag - 200)
            } else {
                if isOwner {
                    showApplyAlert(tag - 200)
                }
            }
        }
    }
    
    private func notifySeverLeave() {
        guard let roomId = self.roomInfo?.room?.chatroom_id  else { return }
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .leaveRoom(roomId: roomId), params: [:]) { dic, error in
            if let result = dic?["result"] as? Bool,error == nil,result {
                debugPrint("result:\(result)")
            }
        }
        VoiceRoomIMManager.shared?.userQuitRoom(completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.inputBar.hiddenInputBar()
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
        noticeView.noticeStr = roomInfo?.room?.announcement ?? ""
        noticeView.resBlock = {[weak self] (flag, str) in
            self?.dismiss(animated: true)
            guard let str = str else {return}
            //修改群公告
            self?.updateNotice(with: str)
        }
        let noticeStr = self.roomInfo?.room?.announcement ?? ""
        noticeView.noticeStr = noticeStr
        let vc = VoiceRoomAlertViewController.init(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 220~)), custom: noticeView)
        self.presentViewController(vc)
    }
    
    private func showSoundView() {
        guard let soundEffect = self.roomInfo?.room?.sound_effect else {return}
        let soundView = VMSoundView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 220~))
        soundView.soundEffect = soundEffect
        let vc = VoiceRoomAlertViewController.init(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 220~)), custom: soundView)
        self.presentViewController(vc)
    }
    
    private func showActiveAlienView(_ active: Bool) {
        if !isOwner {
            self.view.makeToast("只有房主才能操作agora机器人")
            return
        }
        let confirmView = VMConfirmView(frame: CGRect(x: 0, y: 0, width: ScreenWidth - 40~, height: 220~))
        var compent = PresentedViewComponent(contentSize: CGSize(width: ScreenWidth - 40~, height: 220~))
        compent.destination = .center
        let vc = VoiceRoomAlertViewController(compent: compent, custom: confirmView)
        confirmView.resBlock = {[weak self] (flag) in
            self?.dismiss(animated: true)
            if flag == false {return}
            self?.activeAlien(active)
        }
        self.presentViewController(vc)
    }
    
    private func activeAlien(_ flag: Bool) {
        if isOwner == false {return}
        guard let roomId = roomInfo?.room?.room_id else {return}
        guard let mic: VRRoomMic = roomInfo?.mic_info![6] else {return}
        let params: Dictionary<String, Bool> = ["use_robot":flag]
        VoiceRoomBusinessRequest.shared.sendPUTRequest(api: .modifyRoomInfo(roomId: roomId), params: params) { map, error in
            if map != nil {
                //如果返回的结果为true 表示上麦成功
                if let result = map?["result"] as? Bool,error == nil,result {
                    if result == true {
                        print("激活机器人成功")
                        
                        if self.alienCanPlay {
                            self.rtckit.playMusic(with: .alien)
                        }
                        
                        var mic_info = mic
                        mic_info.status = flag == true ? 5 : -2
                        self.roomInfo?.room?.use_robot = flag
                        self.roomInfo?.mic_info![6] = mic_info
                        self.rtcView.micInfos = self.roomInfo?.mic_info
                    }
                } else {
                    print("激活机器人失败")
                }
            } else {
                
            }
        }
    }
   // announcement
    private func updateNotice(with str: String) {
        guard let roomId = roomInfo?.room?.room_id else {return}
        let params: Dictionary<String, String> = ["announcement":str]
        VoiceRoomBusinessRequest.shared.sendPUTRequest(api: .modifyRoomInfo(roomId: roomId), params: params) { map, error in
            if map != nil {
                //如果返回的结果为true 表示上麦成功
                if let result = map?["result"] as? Bool,error == nil,result {
                    if result == true {
                        print("修改群公告成功")
                        self.roomInfo?.room?.announcement = str
                    }
                } else {
                    print("修改群公告失败")
                }
            } else {
                
            }
        }
    }
    
    private func updateVolume(_ Vol: Int) {
        if isOwner == false {return}
        guard let roomId = roomInfo?.room?.room_id else {return}
        let params: Dictionary<String, Int> = ["robot_volume": Vol]
        VoiceRoomBusinessRequest.shared.sendPUTRequest(api: .modifyRoomInfo(roomId: roomId), params: params) { map, error in
            if map != nil {
                //如果返回的结果为true 表示上麦成功
                if let result = map?["result"] as? Bool,error == nil,result {
                    if result == true {
                        print("调节机器人音量成功")
                        guard let room = self.roomInfo?.room else {return}
                        var newRoom = room
                        newRoom.robot_volume = UInt(Vol)
                        self.roomInfo?.room = newRoom
                        self.rtckit.adjustAudioMixingPublishVolume(with: Vol)
                    }
                } else {
                    print("调节机器人音量失败")
                }
            } else {
                
            }
        }
    }
    
//    private func leaveRoom() {
//        guard let roomId = roomInfo?.room?.room_id else {return}
//        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .leaveRoom(roomId: roomId), params: [:]) {[weak self] map, error in
//            if map != nil {
//                //如果返回的结果为true 表示上麦成功
//                if let result = map?["result"] as? Bool,error == nil,result {
//                    debugPrint("--- giveupStage :result:\(result)")
//                    self?.requestRoomDetail()
//                } else {
//                    self?.view.makeToast("leaveRoom failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
//                }
//            } else {
//
//            }
//        }
//    }
    
    private func getApplyList() {
        guard let roomId = roomInfo?.room?.room_id else {return}
        
    }
    
    private func showEQView() {
        preView = VMPresentView(frame: CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: 450~))
        preView.isAudience = !isOwner
        preView.roomInfo = roomInfo
        preView.ains_state = ains_state
        preView.selBlock = {[weak self] state in
            self?.ains_state = state
            self?.rtckit.setAINS(with: state)
            if self?.isOwner == false {return}
            if let use_robot = self?.roomInfo?.room?.use_robot{
                if use_robot == false {
                    self?.view.makeToast("请房主先激活机器人")
                    return
                }
                if state == .high {
                    self?.rtckit.playMusic(with: .ainsHigh)
                } else if state == .mid {
                    self?.rtckit.playMusic(with: .ainsMid)
                } else {
                    self?.rtckit.playMusic(with: .ainsOff)
                }
            }
        }
        preView.useRobotBlock = {[weak self] flag in
            if self?.alienCanPlay == true && flag == true {
                self?.rtckit.playMusic(with: .alien)
            }
            
            if self?.alienCanPlay == true && flag == false {
                self?.rtckit.stopPlayMusic()
            }

            self?.activeAlien(flag)
        }
        preView.volBlock = {[weak self] vol in
            self?.updateVolume(vol)
        }
        preView.eqView.effectClickBlock = {[weak self] in
            guard let effect = self?.roomInfo?.room?.sound_effect else {return}
            self?.rtckit.playMusic(with: self?.getSceneType(effect) ?? .social)
        }
        preView.eqView.soundBlock = {[weak self] index in
            if self?.isOwner == false {return}
            if let use_robot = self?.roomInfo?.room?.use_robot{
                if use_robot == false {
                    self?.view.makeToast("请房主先激活机器人")
                    return
                }
            }
            let count = (index - 1000) / 10
            let tag = (index - 1000) % 10
            self?.rtckit.playSound(with: count, type: tag == 1 ? .ainsOff : .ainsHigh)
            self?.rtcView.showAlienMicView = .blue
        }
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
            self?.sendTextMessage(text: $0)
        }
        self.chatBar.events = { [weak self] in
            guard let `self` = self else { return }
            switch $0 {
            case .eq: self.showEQView()
            case .mic: self.changeMicState()
            case .gift: self.showGiftAlert()
            case .handsUp: self.changeHandsUpState()
            default: break
            }
        }
    }
    
    private func sendTextMessage(text: String) {
        self.inputBar.endEditing(true)
        self.inputBar.inputField.text = ""
        guard let roomId = self.roomInfo?.room?.chatroom_id  else { return }
        guard let userName = VoiceRoomUserInfo.shared.user?.name  else { return }
        self.showMessage(message: AgoraChatMessage(conversationID: roomId, body: AgoraChatTextMessageBody(text: text), ext: ["userName":VoiceRoomUserInfo.shared.user?.name ?? ""]))
        VoiceRoomIMManager.shared?.sendMessage(roomId: roomId, text: text,ext: ["userName":userName]) { message, error in
            if error == nil,message != nil {
            } else {
                self.view.makeToast("\(error?.errorDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    private func changeHandsUpState() {
        if self.isOwner {
            self.applyMembersAlert()
            self.chatBar.refresh(event: .handsUp, state: .selected, asCreator: true)
        } else {
            if self.chatBar.handsState == .unSelected {
                self.userApplyAlert(nil)
            } else if self.chatBar.handsState == .selected {
                self.userCancelApplyAlert()
            }
        }
    }
    
    private func changeMicState() {
        self.chatBar.micState = !self.chatBar.micState
        self.chatBar.refresh(event: .mic, state: self.chatBar.micState ? .selected:.unSelected, asCreator: false)
        //需要根据麦位特殊处理
        self.chatBar.micState == true ? self.muteLocal(with: 0):self.unmuteLocal(with: 0)
    }
    
    private func showUsers() {
        let contributes = VoiceRoomUserView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 420),controllers: [VoiceRoomGiftersViewController(roomId: self.roomInfo?.room?.room_id ?? "")],titles: [LanguageManager.localValue(key: "Contribution List")]).cornerRadius(20, [.topLeft,.topRight], .white, 0)
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 420)), custom: contributes)
        self.presentViewController(vc)
    }
    
    private func showApplyAlert(_ index: Int) {
        let isHairScreen = SwiftyFitsize.isFullScreen
        let manageView = VMManagerView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height:isHairScreen ? 264~ : 264~ - 34))
        guard let mic_info = roomInfo?.mic_info?[index] else {return}
        manageView.micInfo = mic_info
        manageView.resBlock = {[weak self] (state, flag) in
            self?.dismiss(animated: true)
            if state == .invite {
                if flag {
                    self?.applyMembersAlert()
                } else {
                    self?.kickoff(with: index)
                }
            } else if state == .mute {
                if flag {
                    self?.mute(with: index)
                } else {
                    self?.unMute(with: index)
                }
            } else {
                if flag {
                    self?.lock(with: index)
                } else {
                    self?.unLock(with: index)
                }
            }
        }
        let vc = VoiceRoomAlertViewController.init(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: isHairScreen ? 264~ : 264~ - 34)), custom: manageView)
        self.presentViewController(vc)
    }
    
    private func userApplyAlert(_ index: Int?) {
        let applyAlert = VoiceRoomApplyAlert(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: (205/375.0)*ScreenWidth),content: "Request to Speak?",cancel: "Cancel",confirm: "Confirm",position: .bottom).backgroundColor(.white).cornerRadius(20, [.topLeft,.topRight], .clear, 0)
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: (205/375.0)*ScreenWidth)), custom: applyAlert)
        applyAlert.actionEvents = { [weak self] in
            if $0 == 31 {
                self?.requestSpeak(index: index)
            }
            vc.dismiss(animated: true)
        }
        self.presentViewController(vc)
    }
    
    private func requestSpeak(index: Int?) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .submitApply(roomId: roomId), params: index != nil ? ["mic_index":index ?? 2]:[:]) { dic, error in
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.chatBar.refresh(event: .handsUp, state: .selected, asCreator: false)
                    self.view.makeToast("Apply success!", point: self.toastPoint, title: nil, image: nil, completion: nil)
                } else {
                    self.view.makeToast("Apply failed!", point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")", point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    private func cancelRequestSpeak(index: Int?) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .cancelApply(roomId: roomId), params: [:]) { dic, error in
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("Cancel Apply success!", point: self.toastPoint, title: nil, image: nil, completion: nil)
                    self.chatBar.refresh(event: .handsUp, state: .unSelected, asCreator: false)
                } else {
                    self.view.makeToast("Cancel Apply failed!", point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    private func userCancelApplyAlert() {
        let cancelAlert = VoiceRoomCancelAlert(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: (205/375.0)*ScreenWidth)).backgroundColor(.white).cornerRadius(20, [.topLeft,.topRight], .clear, 0)
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: (205/375.0)*ScreenWidth)), custom: cancelAlert)
        cancelAlert.actionEvents = { [weak self] in
            if $0 == 30 {
                self?.cancelRequestSpeak(index: nil)
            }
            vc.dismiss(animated: true)
        }
        self.presentViewController(vc)
    }
    
    //禁言指定麦位
    private func mute(with index: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .muteMic(roomId: roomId), params: ["mic_index": index]) { dic, error in
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("mute success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                } else {
                    self.view.makeToast("mute failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    //取消禁言指定麦位
    private func unMute(with index: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .unmuteMic(roomId: roomId, index: index), params: [:]) { dic, error in
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("unmute success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                    self.chatBar.refresh(event: .handsUp, state: .unSelected, asCreator: false)
                } else {
                    self.view.makeToast("unmute failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    //踢用户下麦
    private func kickoff(with index: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        guard let mic: VRRoomMic = self.roomInfo?.mic_info![index] else {return}
        let dic: Dictionary<String, Any> = [
            "uid":mic.member?.uid ?? 0,
            "mic_index": index
        ]
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .kickMic(roomId: roomId), params: dic) { dic, error in
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("kickoff success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                } else {
                    self.view.makeToast("kickoff failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    //锁麦
    private func lock(with index: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .lockMic(roomId: roomId), params: ["mic_index": index]) { dic, error in
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("lock success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                } else {
                    self.view.makeToast("lock failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    //取消锁麦
    private func unLock(with index: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .unlockMic(roomId: roomId, index: index), params: [:]) { dic, error in
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("unLock success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                } else {
                    self.view.makeToast("unLock failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    //下麦
    private func leaveMic(with index: Int) {
        self.chatBar.refresh(event: .mic, state: .selected, asCreator: false)
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .leaveMic(roomId: roomId, index: index), params: [:]) { dic, error in
            self.dismiss(animated: true)
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("leaveMic success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
//                    guard let mic: VRRoomMic = self.roomInfo?.mic_info![index] else {return}
//                    var mic_info = mic
//                    mic_info.status = -1
//                    self.roomInfo?.mic_info![index] = mic_info
//                    self.rtcView.micInfos = self.roomInfo?.mic_info
                } else {
                    self.view.makeToast("leaveMic failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    //mute自己
    private func muteLocal(with index: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .closeMic(roomId: roomId), params: ["mic_index": index]) { dic, error in
            self.dismiss(animated: true)
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.chatBar.refresh(event: .mic, state: .selected, asCreator: false)
                    self.view.makeToast("mute local success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
//                    guard let mic: VRRoomMic = self.roomInfo?.mic_info![index] else {return}
//                    var mic_info = mic
//                    mic_info.status = 1
//                    self.roomInfo?.mic_info![index] = mic_info
//                    self.rtcView.micInfos = self.roomInfo?.mic_info
                } else {
                    self.view.makeToast("unmute local failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }

    //unmute自己
    private func unmuteLocal(with index: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .cancelCloseMic(roomId: roomId, index: index), params: [:]) { dic, error in
            self.dismiss(animated: true)
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.chatBar.refresh(event: .mic, state: .unSelected, asCreator: false)
                    self.view.makeToast("unmuteLocal success!",point: self.toastPoint, title: nil, image: nil, completion: nil)
//                    guard let mic: VRRoomMic = self.roomInfo?.mic_info![index] else {return}
//                    var mic_info = mic
//                    mic_info.status = 0
//                    self.roomInfo?.mic_info![index] = mic_info
//                    self.rtcView.micInfos = self.roomInfo?.mic_info
                } else {
                    self.view.makeToast("unmuteLocal failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    private func changeMic(from: Int, to: Int) {
        guard let roomId = self.roomInfo?.room?.room_id else { return }
        let params: Dictionary<String, Int> = [
            "from": from,
            "to": to
        ]
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .exchangeMic(roomId: roomId), params: params) { dic, error in
            self.dismiss(animated: true)
            if error == nil,dic != nil,let result = dic?["result"] as? Bool {
                if result {
                    self.view.makeToast("changeMic success!")
                    self.local_index = to
                } else {
                    self.view.makeToast("changeMic failed!")
                }
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")")
            }
        }
    }
    
    private func showMuteView(with index: Int) {
        let isHairScreen = SwiftyFitsize.isFullScreen
        let muteView = VMMuteView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: isHairScreen ? 264~ : 264~ - 34))
        guard let mic_info = roomInfo?.mic_info?[index] else {return}
        muteView.isOwner = isOwner
        muteView.micInfo = mic_info
        muteView.resBlock = {[weak self] (state) in
            if state == .leave {
                self?.leaveMic(with: index)
            } else if state == .mute {
                self?.muteLocal(with: index)
            } else {
                self?.unmuteLocal(with: index)
            }
        }
        let vc = VoiceRoomAlertViewController.init(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: isHairScreen ? 264~ : 264~ - 34)), custom: muteView)
        self.presentViewController(vc)
    }
    
    private func applyMembersAlert() {
        let userAlert = VoiceRoomUserView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 420),controllers: [VoiceRoomApplyUsersViewController(roomId: self.roomInfo?.room?.room_id ?? ""),VoiceRoomInviteUsersController(roomId: self.roomInfo?.room?.room_id ?? "")],titles: [LanguageManager.localValue(key: "Raised Hands"),LanguageManager.localValue(key: "Invite On-Stage")]).cornerRadius(20, [.topLeft,.topRight], .white, 0)
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 420)), custom: userAlert)
        self.presentViewController(vc)
    }
    
    private func showGiftAlert() {
        let giftsAlert = VoiceRoomGiftsView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: (110/84.0)*((ScreenWidth-30)/4.0)+180), gifts: self.gifts()).backgroundColor(.white).cornerRadius(20, [.topLeft,.topRight], .clear, 0)
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: (110/84.0)*((ScreenWidth-30)/4.0)+180)), custom: giftsAlert)
        giftsAlert.sendClosure = { [weak self] in
            self?.sendGift(gift: $0)
            if $0.gift_id == "VoiceRoomGift9" {
                vc.dismiss(animated: true)
                self?.rocketAnimation()
            }
        }
        self.presentViewController(vc)
    }
    
    private func sendGift(gift: VoiceRoomGiftEntity) {
        gift.userName = VoiceRoomUserInfo.shared.user?.name ?? ""
        gift.portrait = VoiceRoomUserInfo.shared.user?.portrait ?? self.userAvatar
        var giftList: VoiceRoomGiftView? = self.view.viewWithTag(1111) as? VoiceRoomGiftView
        if giftList == nil {
            giftList = self.giftList()
            self.view.addSubview(giftList!)
        }
        giftList?.gifts.append(gift)
        giftList?.cellAnimation()
        if let chatroom_id = self.roomInfo?.room?.chatroom_id,let uid = self.roomInfo?.room?.owner?.uid,let id = gift.gift_id,let name = gift.gift_name,let value = gift.gift_price,let count = gift.gift_count {
            VoiceRoomIMManager.shared?.sendCustomMessage(roomId: chatroom_id, event: VoiceRoomGift, customExt: ["gift_id":id,"gift_name":name,"gift_price":value,"gift_count":count,"userNaem":VoiceRoomUserInfo.shared.user?.name ?? "","portrait":VoiceRoomUserInfo.shared.user?.portrait ?? self.userAvatar], completion: { message, error in
                if error == nil,message != nil {
                    if let c = Int(count),let v = Int(value),var amount = VoiceRoomUserInfo.shared.user?.amount {
                        amount += c*v
                        VoiceRoomUserInfo.shared.user?.amount = amount
                    }
                    self.notifyServerGiftInfo(id: id, count: count, uid: uid)
                } else {
                    self.view.makeToast("Send failed \(error?.errorDescription ?? "")",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            })
        }
    }
    
    private func notifyServerGiftInfo(id: String,count: String,uid: String) {
        if let roomId = self.roomInfo?.room?.room_id {
            VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .giftTo(roomId: roomId), params: ["gift_id":id,"num":Int(count) ?? 1,"to_uid":uid]) { dic, error in
                if let result = dic?["result"] as? Bool,error == nil,result {
                    debugPrint("result:\(result)")
                } else {
                    self.view.makeToast("Send failed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
                }
            }
        }
    }
    
    func rocketAnimation() {
        let player = SVGAPlayer(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight))
        player.loops = 1
        player.clearsAfterStop = true
        player.contentMode = .scaleAspectFill
        player.delegate = self
        player.tag(199)
        self.view.addSubview(player)
        let parser = SVGAParser()
        parser.parse(withNamed: "rocket", in: .main) { entitiy in
            player.videoItem = entitiy
            player.startAnimation()
        } failureBlock: { error in
            player.removeFromSuperview()
        }
    }
    
    private func gifts() -> [VoiceRoomGiftEntity] {
        var gifts = [VoiceRoomGiftEntity]()
        for dic in giftMap {
            gifts.append(model(from: dic, VoiceRoomGiftEntity.self))
        }
        return gifts
    }
    
    func reLogin() {
        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .login(()), params: ["deviceId":UIDevice.current.deviceUUID,"portrait":VoiceRoomUserInfo.shared.user?.portrait ?? self.userAvatar,"name":VoiceRoomUserInfo.shared.user?.name ?? ""],classType:VRUser.self) { [weak self] user, error in
            if error == nil {
                VoiceRoomUserInfo.shared.user = user
                VoiceRoomBusinessRequest.shared.userToken = user?.authorization ?? ""
                AgoraChatClient.shared().renewToken(user?.im_token ?? "")
            } else {
                self?.view.makeToast("\(error?.localizedDescription ?? "")",point: self?.toastPoint ?? .zero, title: nil, image: nil, completion: nil)
            }
        }
    }
    
    private func leaveRoom() {
        guard let room_id = roomInfo?.room?.room_id else {return}
        VoiceRoomBusinessRequest.shared.sendDELETERequest(api: .leaveRoom(roomId: room_id), params: [:]) { map, err in
            print(map?["result"] as? Bool ?? false)
        }
    }
    
    private func showMessage(message: AgoraChatMessage) {
        if let body = message.body as? AgoraChatTextMessageBody,let userName = message.ext?["userName"] as? String {
            self.convertShowText(userName: userName, content: body.text,joined: false)
        }
    }
    
    private func convertShowText(userName: String,content: String,joined: Bool) {
        let dic = ["userName":userName,"content":content]
        self.chatView.messages?.append(self.chatView.getItem(dic: dic, join: joined))
        DispatchQueue.main.async {
            self.refreshChatView()
        }
    }
    
    @objc func refreshChatView() {
        self.chatView.chatView.reloadData()
        let row = (self.chatView.messages?.count ?? 0) - 1
        self.chatView.chatView.scrollToRow(at: IndexPath(row: row, section: 0), at: .bottom, animated: true)
    }
    
    private func refuse() {
        if let roomId = self.roomInfo?.room?.room_id {
            VoiceRoomBusinessRequest.shared.sendGETRequest(api: .refuseInvite(roomId: roomId), params: [:]) { _, _ in
            }
        }
    }
    
    private func agreeInvite() {
        if let roomId = self.roomInfo?.room?.room_id {
            VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .agreeInvite(roomId: roomId), params: [:]) { _, _ in
                
            }
        }
    }
    
    private func showInviteMicAlert() {
        var compent = PresentedViewComponent(contentSize: CGSize(width: ScreenWidth-75, height: 200))
        compent.destination = .center
        let micAlert = VoiceRoomApplyAlert(frame: CGRect(x: 0, y: 0, width: ScreenWidth-75, height: 200), content: "Anchor Invited You On-Stage",cancel: "Decline",confirm: "Accept",position: .center).cornerRadius(16).backgroundColor(.white)
        let vc = VoiceRoomAlertViewController(compent: compent, custom: micAlert)
        micAlert.actionEvents = { [weak self] in
            if $0 == 30 {
                self?.refuse()
            } else {
                self?.agreeInvite()
            }
            vc.dismiss(animated: true)
        }
        self.presentViewController(vc)
    }
}
//MARK: - SVGAPlayerDelegate
extension VoiceRoomViewController: SVGAPlayerDelegate {
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer!) {
        let animation = self.view.viewWithTag(199)
        UIView.animate(withDuration: 0.3) {
            animation?.alpha = 0
        } completion: { finished in
            if finished { animation?.removeFromSuperview() }
        }
    }
}

//MARK: - VoiceRoomIMDelegate
extension VoiceRoomViewController: VoiceRoomIMDelegate {
    
    func memberLeave(roomId: String, userName: String) {
        
    }
    
    
    func voiceRoomUpdateRobotVolume(roomId: String, volume: String) {
        roomInfo?.room?.robot_volume = UInt(volume)
    }
    
    
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
    
    func receiveGift(roomId: String, meta: [String : String]?) {
        guard let dic = meta else { return }
        var giftList = self.view.viewWithTag(1111) as? VoiceRoomGiftView
        if giftList == nil {
            giftList = self.giftList()
            self.view.addSubview(giftList!)
        }
        giftList?.gifts.append(model(from: dic, VoiceRoomGiftEntity.self))
        giftList?.cellAnimation()
        if let id = meta?["gift_id"],id == "VoiceRoomGift9" {
            self.rocketAnimation()
        }
        self.requestRoomDetail()
    }
    
    func receiveApplySite(roomId: String, meta: [String : String]?) {
        if VoiceRoomUserInfo.shared.user?.uid  ?? "" != roomInfo?.room?.owner?.uid ?? "" {
            return
        }
        self.chatBar.refresh(event: .handsUp, state: .unSelected, asCreator: true)
    }
    
    func receiveInviteSite(roomId: String, meta: [String : String]?) {
        guard let map = meta?["user"] else { return }
        let user = model(from: map, VRUser.self)
        if VoiceRoomUserInfo.shared.user?.uid  ?? "" != user?.uid ?? "" {
            return
        }
        self.showInviteMicAlert()
    }
    
    func refuseInvite(roomId: String, meta: [String : String]?) {
        let user = model(from: meta ?? [:], VRUser.self)
        if VoiceRoomUserInfo.shared.user?.uid  ?? "" != user.uid ?? "" {
            return
        }
        self.view.makeToast("User \(user.name ?? "") refuse invite",point: self.toastPoint, title: nil, image: nil, completion: nil)
    }
    
    func userJoinedRoom(roomId: String, username: String) {
        self.convertShowText(userName: username, content: LanguageManager.localValue(key: "Joined"),joined: true)
    }
    
    func announcementChanged(roomId: String, content: String) {
        self.view.makeToast("Voice room announcement changed!",point: self.toastPoint, title: nil, image: nil, completion: nil)
        guard let _ = roomInfo?.room else {return}
        roomInfo?.room!.announcement = content
    }
    
    func userBeKicked(roomId: String, reason: AgoraChatroomBeKickedReason) {
        VoiceRoomIMManager.shared?.userQuitRoom(completion: nil)
        VoiceRoomIMManager.shared?.delegate = nil
        var message = ""
        switch reason {
        case .beRemoved: message = "you are removed by owner!"
        case .destroyed: message = "VoiceRoom was destroyed!"
        case .offline: message = "you are offline!"
        @unknown default:
            break
        }
        self.view.makeToast(message,point: self.toastPoint, title: nil, image: nil, completion: nil)
        if reason == .destroyed || reason == .beRemoved {
            if reason == .destroyed {
                NotificationCenter.default.post(name: NSNotification.Name("refreshList"), object: nil)
            }
            self.backAction()
        }
    }
    
    func roomAttributesDidUpdated(roomId: String, attributeMap: [String : String]?, from fromId: String) {
        guard let dic = getMicStatus(with: attributeMap) else {return}
        var index: Int = dic["index"] ?? 0
        let status: Int = dic["status"] ?? 0
        if index > 6 {index = 6}
        guard let mic: VRRoomMic = roomInfo?.mic_info?[index] else {return}
        var mic_info = mic
        mic_info.status = status
        if status == 5 || status == -2 {
            self.roomInfo?.room?.use_robot = status == 5
        }
        self.roomInfo?.mic_info?[index] = mic_info
        self.rtcView.micInfos = self.roomInfo?.mic_info
        requestRoomDetail()
    }
    
    func roomAttributesDidRemoved(roomId: String, attributes: [String]?, from fromId: String) {
        
    }
    
    private func getMicStatus(with map: [String : String]?) -> Dictionary<String, Int>? {
        guard let mic_info = map else {return nil}
        var first: Dictionary<String, Int>? = Dictionary()
        for mic in mic_info {
            let key: String = mic.key
            let value = mic.value.z.jsonToDictionary()
            guard let status: Int = value["status"] as? Int else {return nil}
            first?["status"] = status

            if key.contains("mic_") {
                if key.components(separatedBy: "mic_").count > 1 {
                    let index = key.components(separatedBy: "mic_")[1]
                    if let mic_index = Int(index) {
                       first?["index"] = mic_index
                       let uid = VoiceRoomUserInfo.shared.user?.uid
                        if !self.isOwner {
                            if value.keys.contains("status"),let status = value["status"] as? Int,status == -1 {
                                self.chatBar.refresh(event: .handsUp, state: .unSelected, asCreator: false)
                            } else {
                                self.chatBar.refresh(event: .handsUp, state: .disable, asCreator: false)
                            }
                        }
                       if value.keys.contains("uid") {
                          if uid == value["uid"] as? String ?? "" {
                              local_index = mic_index
                              //如果当前是0的状态  就设置成主播
                              if isOwner {
                                  self.rtckit.muteLocalAudioStream(mute: status != 0)
                              } else {
                                  self.rtckit.muteLocalAudioStream(mute: status != 0)
                                  self.rtckit.setClientRole(role: status == 0 ? .owner : .audience)
                              }
                                    
                          }
                       }
                    }
                    return first
                }
            }
        }
        return nil
    }

}
//MARK: - ASManagerDelegate
extension VoiceRoomViewController: ASManagerDelegate {
    
    func didRtcLocalUserJoinedOfUid(uid: UInt) {
        
    }
    
    func didRtcRemoteUserJoinedOfUid(uid: UInt) {
        
    }
    
    func didRtcUserOfflineOfUid(uid: UInt) {
        
    }
    
    func reportAlien(with type: ALIEN_TYPE, musicType: VMMUSIC_TYPE) {
        print("当前是：\(type.rawValue)在讲话")
        self.rtcView.showAlienMicView = type
        if type == .ended && self.alienCanPlay && musicType == .alien {
            self.alienCanPlay = false
        }
    }
    
    func reportAudioVolumeIndicationOfSpeakers(speakers: [AgoraRtcAudioVolumeInfo]) {
        guard let micinfo = self.roomInfo?.mic_info else {return}
        for speaker in speakers {
            for (index,mic) in micinfo.enumerated() {
                guard let user = mic.member else {return}
                guard let rtcUid = Int(user.rtc_uid ?? "0") else {return}
                if rtcUid == speaker.uid {
                    var mic = micinfo[index]
                    mic.member?.volume = Int(speaker.volume)
                    self.roomInfo?.mic_info![index] = mic
                    self.rtcView.micInfos = self.roomInfo?.mic_info
                }
            }
        }
    }
}
