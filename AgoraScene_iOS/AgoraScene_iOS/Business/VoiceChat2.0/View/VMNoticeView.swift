//
//  VMNoticeView.swift
//  AgoraScene_iOS
//
//  Created by CP on 2022/9/6.
//

import UIKit
import SnapKit
import ZSwiftBaseLib
class VMNoticeView: UIView {

    private var lineImgView: UIImageView = UIImageView()
    private var canBtn: UIButton = UIButton()
    private var subBtn: UIButton = UIButton()
    private var titleLabel: UILabel = UILabel()
    private var tv: UITextView = UITextView()
    private var limLabel: UILabel = UILabel()
    
    var resBlock: ((Bool, String?) -> Void)?
    
    var roleType: ROLE_TYPE = .owner {
        didSet {
            if roleType == .owner {
                canBtn.isHidden = false
                subBtn.isHidden = false
                limLabel.isHidden = false
                tv.isEditable = true
                tv.textColor = UIColor(red: 151/255.0, green: 156/255.0, blue: 187/255.0, alpha: 1)
            } else {
                canBtn.isHidden = true
                subBtn.isHidden = true
                limLabel.isHidden = true
                tv.isEditable = false
                tv.textColor = .black
            }
        }
    }
    
    var noticeStr: String = "" {
        didSet {
            tv.text = noticeStr
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutUI() {
        
        let path: UIBezierPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 20.0, height: 20.0))
        let layer: CAShapeLayer = CAShapeLayer()
        layer.path = path.cgPath
        self.layer.mask = layer
        
        lineImgView.frame = CGRect(x: ScreenWidth / 2.0 - 20~, y: 8~, width: 40~, height: 4~)
        lineImgView.image = UIImage(named: "pop_indicator")
        self.addSubview(lineImgView)

        canBtn.frame = CGRect(x: 0, y: 20~, width: 80~, height: 40~)
        canBtn.setTitle("Cancel", for: .normal)
        canBtn.setTitleColor(.lightGray, for: .normal)
        canBtn.addTargetFor(self, action: #selector(can), for: .touchUpInside)
        self.addSubview(canBtn)

        subBtn.frame = CGRect(x: ScreenWidth - 80~, y: 20~, width: 80~, height: 40~)
        let img = UIImage(named: "createRoom")
        img!.stretchableImage(withLeftCapWidth: Int(img!.size.width / 2.0), topCapHeight: Int(img!.size.height / 2.0))
        subBtn.setBackgroundImage(img, for: .normal)
        subBtn.setTitle("Submit", for: .normal)
        subBtn.addTargetFor(self, action: #selector(sub), for: .touchUpInside)
        subBtn.setTitleColor(.lightGray, for: .normal)
        self.addSubview(subBtn)

        titleLabel.frame = CGRect(x: ScreenWidth / 2.0 - 40~, y: 20~, width: 80~, height: 40~)
        titleLabel.textAlignment = .center
        titleLabel.text = "Notice"
        titleLabel.textColor = .black
        self.addSubview(titleLabel)

        tv.frame = CGRect(x: 10, y: 60~, width: ScreenWidth - 20 , height: 160~)
        tv.text = "Announce to chatroom. 140 character limit"
        tv.textColor = UIColor(red: 151/255.0, green: 156/255.0, blue: 187/255.0, alpha: 1)
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.delegate = self
        self.addSubview(tv)

        limLabel.frame = CGRect(x: ScreenWidth - 80, y:170~, width: 80~, height: 20~)
        limLabel.textColor = UIColor(red: 151/255.0, green: 156/255.0, blue: 187/255.0, alpha: 1)
        limLabel.font = UIFont.systemFont(ofSize: 14)
        limLabel.textAlignment = .center
        limLabel.text = "0/140"
        self.addSubview(limLabel)
        
    }
    
   @objc private func can() {
        guard let block = resBlock else {return}
        block(false, nil)
    }
    
   @objc private func sub() {
        guard let block = resBlock else {return}
        block(true, tv.text.count == 0 ? nil : tv.text)
    }
}

extension VMNoticeView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text
        if text!.count >= 140 {
            let indexStart = text!.startIndex
            let indexEnd = text!.index(indexStart, offsetBy: 140)
            tv.text = String(text![indexStart..<indexEnd])
            limLabel.text = "140/140"
        } else {
            tv.text = text
            limLabel.text = "\(text!.count)/140"
        }
    }
    
}
