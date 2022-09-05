//
//  AgoraChatRoomHeaderView.swift
//  VoiceChat4Swift
//
//  Created by CP on 2022/8/29.
//

import UIKit
import SnapKit

class AgoraChatRoomHeaderView: UIView {
    
    private var backBtn: UIButton = UIButton()
    private var iconImgView: UIImageView = UIImageView()
    private var titleLabel: UILabel = UILabel()
    private var roomLabel: UILabel = UILabel()
    private var infoView: UIView = UIView()
    private var richView: UIView = UIView()
    private var totalCountLabel: UILabel = UILabel()
    private var giftBtn: UIButton = UIButton()
    private var lookBtn: UIButton = UIButton()
    private var noticeView: UIView = UIView()
    private var configView: UIView = UIView()
    private var soundSetLabel: UILabel = UILabel()

    override func draw(_ rect: CGRect) {
        // Drawing code
        SwiftyFitsize.reference(width: 375, iPadFitMultiple: 0.6)
        layoutUI()
    }
    
    private func layoutUI() {
        self.backBtn.setBackgroundImage(UIImage(named: "icon／outline／left"), for: .normal)
        self.backBtn.addTarget(self, action: #selector(back), for: .touchUpInside)
        self.addSubview(self.backBtn)
 
        self.iconImgView.layer.cornerRadius = 16~;
        self.iconImgView.layer.masksToBounds = true;
        self.iconImgView.image = UIImage(named: "longkui")
        self.addSubview(self.iconImgView)
        
        self.titleLabel.textColor = .white;
        self.titleLabel.text = "Susan Stark"
        self.titleLabel.font = UIFont.systemFont(ofSize: 15)~
        self.addSubview(self.titleLabel)
        
        self.roomLabel.textColor = .white
        self.roomLabel.font = UIFont.systemFont(ofSize: 10)~
        self.roomLabel.text = "Chatroom-0728-001"
        self.addSubview(self.roomLabel)
        
        self.totalCountLabel.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        self.totalCountLabel.layer.cornerRadius = 13~
        self.totalCountLabel.text = "2.8K"
        self.totalCountLabel.font = UIFont.systemFont(ofSize: 10)~
        self.totalCountLabel.textColor = .white
        self.totalCountLabel.layer.masksToBounds = true;
        self.addSubview(self.totalCountLabel)
        
        self.addSubview(self.richView)
        
        self.configView.layer.cornerRadius = 19~;
        self.configView.layer.masksToBounds = true;
        self.configView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        self.addSubview(self.configView)
        
        let tipLabel = UILabel()
        tipLabel.text = "Best Agora Sound:"
        tipLabel.textColor = .white
        tipLabel.font = UIFont.systemFont(ofSize: 9)~
        self.configView.addSubview(tipLabel)
        
        let soundSetView = UIView()
        self.configView.addSubview(soundSetView)

        self.soundSetLabel.text = "SNS Chat Sound"
        self.soundSetLabel.textColor = .white
        self.soundSetLabel.font = UIFont.systemFont(ofSize: 10)~
        self.configView.addSubview(self.soundSetLabel)
        
        let soundImgView = UIImageView()
        soundImgView.image = UIImage(named: "icons／outlined／arrow_down")
        self.configView.addSubview(soundImgView)

        self.giftBtn.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        self.giftBtn.layer.cornerRadius = 13~
        self.giftBtn.setImage(UIImage(named: "icons／Stock／gift"), for: .normal)
        self.giftBtn.setTitle(" 2000", for: .normal)
        self.giftBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        self.giftBtn.isUserInteractionEnabled = false
        self.addSubview(self.giftBtn)

        self.lookBtn.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        self.lookBtn.layer.cornerRadius = 13~
        self.lookBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10)~
        self.lookBtn.setTitle(" 1000", for: .normal)
        self.lookBtn.isUserInteractionEnabled = false
        self.lookBtn.setImage(UIImage(named:"icons／Stock／look"), for: .normal)
        self.addSubview(self.lookBtn)
        
        self.noticeView.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        self.noticeView.layer.cornerRadius = 13~;
        self.addSubview(self.noticeView)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(click))
        self.noticeView.addGestureRecognizer(tap)
        self.noticeView.isUserInteractionEnabled = true
        
        let imgView = UIImageView()
        imgView.image = UIImage(named: "icons／Stock／notice")
        self.noticeView.addSubview(imgView)
        
        let notiLabel = UILabel()
        notiLabel.text = "Notice"
        notiLabel.font = UIFont.systemFont(ofSize: 12)~
        notiLabel.textColor = .white
        self.noticeView.addSubview(notiLabel)
        
        let arrowImgView = UIImageView()
        arrowImgView.image = UIImage(named: "icons／outlined／arrow_right")
        self.noticeView.addSubview(arrowImgView)
        
        self.backBtn.snp.makeConstraints { make in
            make.left.equalTo(12~);
            make.top.equalTo(54~);
            make.width.height.equalTo(30~);
        }
 
        self.iconImgView.snp.makeConstraints { make in
            make.left.equalTo(self.backBtn.snp.right).offset(5~);
            make.centerY.equalTo(self.backBtn);
            make.width.height.equalTo(38~);
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.iconImgView.snp.right).offset(5~);
            make.height.equalTo(22~);
            make.width.lessThanOrEqualTo(100~);
            make.top.equalTo(self.iconImgView);
        }
        
        self.roomLabel.snp.makeConstraints { make in
            make.left.equalTo(self.iconImgView.snp.right).offset(5~);
            make.height.equalTo(16~);
            make.width.lessThanOrEqualTo(100~);
            make.bottom.equalTo(self.iconImgView);
        }
        
        self.totalCountLabel.snp.makeConstraints { make in
            make.right.equalTo(self.snp.right).offset(-16~);
            make.centerY.equalTo(self.backBtn);
            make.width.height.equalTo(26~);
        }
        
        self.configView.snp.makeConstraints { make in
            make.right.equalTo(self.snp.right).offset(19~);
            make.width.equalTo(150~);
            make.height.equalTo(38~);
            make.top.equalTo(94~);
        }
        
        tipLabel.snp.makeConstraints { make in
            make.left.equalTo(self.configView).offset(20~);
            make.top.equalTo(self.configView);
            make.width.equalTo(85~);
            make.height.equalTo(13~);
        }
        
        soundSetView.snp.makeConstraints { make in
            make.left.equalTo(self.configView).offset(10~);
            make.top.equalTo(tipLabel.snp.bottom).offset(3~);
            make.width.equalTo(105~);
            make.height.equalTo(18~);
        }
        
        self.soundSetLabel.snp.makeConstraints { make in
            make.left.equalTo(soundSetView).offset(5~);
            make.centerY.equalTo(soundSetView);
        }
        
        soundSetView.layoutIfNeeded()
        // gradient
        let gl: CAGradientLayer = CAGradientLayer()
        gl.startPoint = CGPoint(x: 0.18, y: 0)
        gl.endPoint = CGPoint(x: 0.66, y: 1)
        gl.colors = [UIColor(red: 191/255.0, green: 92/255.0, blue: 1, alpha: 1).cgColor, UIColor(red: 141/255.0, green: 77/255.0, blue: 1, alpha: 1).cgColor]
        gl.locations = [0, 1.0]
        soundSetView.layer.cornerRadius = 9~;
        soundSetView.layer.masksToBounds = true;
        gl.frame = soundSetView.bounds;
        soundSetView.layer.addSublayer(gl)
        
        self.soundSetLabel.snp.makeConstraints { make in
            make.left.equalTo(soundSetView).offset(5~);
            make.centerY.equalTo(soundSetView);
        }
        
        soundImgView.snp.makeConstraints { make in
            make.right.equalTo(soundSetView.snp.right).offset(-5~);
            make.width.height.equalTo(10~);
            make.centerY.equalTo(soundSetView);
        }
        
        self.giftBtn.snp.makeConstraints { make in
            make.left.equalTo(self.snp.left).offset(15~);
            make.centerY.equalTo(self.configView);
            make.width.equalTo(58~);
            make.height.equalTo(26~);
        }
        
        self.lookBtn.snp.makeConstraints { make in
            make.left.equalTo(self.giftBtn.snp.right).offset(5~);
            make.centerY.equalTo(self.configView);
            make.width.equalTo(58~);
            make.height.equalTo(26~);
        }
        
        self.noticeView.snp.makeConstraints { make in
            make.left.equalTo(self.lookBtn.snp.right).offset(5~);
            make.centerY.equalTo(self.configView);
            make.width.equalTo(90~);
            make.height.equalTo(26~);
        }
        
        imgView.snp.makeConstraints { make in
            make.left.equalTo(self.noticeView).offset(5~);
            make.centerY.equalTo(self.noticeView);
            make.width.height.equalTo(15~);
        }
        
        arrowImgView.snp.makeConstraints { make in
            make.right.equalTo(self.noticeView).offset(-5~);
            make.centerY.equalTo(self.noticeView);
            make.width.height.equalTo(10~);
        }
        
        notiLabel.snp.makeConstraints { make in
            make.left.equalTo(imgView.snp.right).offset(5~);
            make.right.equalTo(arrowImgView.snp.left).offset(-5~);
            make.centerY.equalTo(self.noticeView);
        }

    }
    
    @objc private func back() {
        
    }
    
    @objc private func click() {
        
    }
}
