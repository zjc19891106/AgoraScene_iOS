//
//  VRSoundEffectsViewController.swift
//  VoiceRoomBaseUIKit
//
//  Created by 朱继超 on 2022/8/26.
//

import UIKit
import ZSwiftBaseLib
import ProgressHUD

public class VRSoundEffectsViewController: VRBaseViewController {
    
    var code = ""
    
    var name = ""
    
    var type = 0
    
    lazy var background: UIImageView = {
        UIImageView(frame: self.view.frame).image(UIImage("roomList")!)
    }()
    
    lazy var effects: VRSoundEffectsList = {
        VRSoundEffectsList(frame: CGRect(x: 0, y: ZNavgationHeight, width: ScreenWidth, height: ScreenHeight - CGFloat(ZBottombarHeight) - CGFloat(ZTabbarHeight)), style: .plain)
    }()
    
    lazy var done: UIImageView = {
        UIImageView(frame: CGRect(x: 0, y: ScreenHeight - CGFloat(ZBottombarHeight)  - 70, width: ScreenWidth, height: 92)).image(UIImage("blur")!).isUserInteractionEnabled(true)
    }()
    
    lazy var toLive: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 30, y: 15, width: ScreenWidth - 60, height: 50)).title("Go Live", .normal).font(.systemFont(ofSize: 16, weight: .semibold)).setGradient([UIColor(0x219BFF),UIColor(0x345DFF)], [CGPoint(x: 0.25, y: 0.5),CGPoint(x: 0.75, y: 0.5)]).cornerRadius(25).addTargetFor(self, action: #selector(VRSoundEffectsViewController.goLive), for: .touchUpInside)
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubViews([self.background,self.effects,self.done])
        self.done.addSubview(self.toLive)
        self.view.bringSubviewToFront(self.navigation)
        self.navigation.title.text = LanguageManager.localValue(key: "Sound Selection")
    }
    
    @objc func goLive() {
        if self.name.isEmpty || self.effects.type.isEmpty {
            self.view.makeToast("param error!")
        }

        VoiceRoomBusinessRequest.shared.sendPOSTRequest(api: .createRoom(()), params: ["name":self.name,"is_private":!self.code.isEmpty,"password":self.code,"type":self.type,"sound_effect":self.effects.type,"allow_free_join_mic":true], classType: VRRoomInfo.self) { info, error in
            if error == nil,info != nil {
                let vc = VoiceRoomViewController()
                vc.roomInfo = info
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                self.view.makeToast("\(error?.localizedDescription ?? "")")
            }
        }
    }
    
    private func entryRoom() {
        ProgressHUD.show("Login IM",interaction: false)
        VoiceRoomIMManager.shared?.loginIM(userName: VoiceRoomUserInfo.shared.user?.chat_uid ?? "", token: VoiceRoomUserInfo.shared.user?.im_token ?? "", completion: { userName, error in
            ProgressHUD.dismiss()
            if error == nil {
                self.goLive()
            } else {
                self.view.makeToast("\(error?.errorDescription ?? "")")
            }
        })
    }
    
    
}
