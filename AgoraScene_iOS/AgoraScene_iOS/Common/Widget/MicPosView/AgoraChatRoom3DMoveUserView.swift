//
//  AgoraChatRoom3DMoveUserView.swift
//  VoiceChat4Swift
//
//  Created by CP on 2022/9/2.
//

import UIKit
import SnapKit
import Kingfisher
import SVGAPlayer
class AgoraChatRoom3DMoveUserView: UIView {

    public var cellType: AgoraChatRoomBaseUserCellType = .AgoraChatRoomBaseUserCellTypeAdd {
        didSet {
            
            if cellType == .AgoraChatRoomBaseUserCellTypeAlienActive || cellType == .AgoraChatRoomBaseUserCellTypeAlienNonActive {
                self.bgColor = .white
            } else {
                self.bgColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
            }
            
            switch cellType {
            case .AgoraChatRoomBaseUserCellTypeAdd:
                self.iconView.isHidden = true
                self.micView.isHidden = true
                self.bgIconView.image = UIImage(named: "icons／solid／add(1)")
            case .AgoraChatRoomBaseUserCellTypeMute:
                self.iconView.isHidden = true
                self.micView.isHidden = false
                self.micView.setState(.forbidden)
                self.bgIconView.image = UIImage(named: "icons／solid／add(1)")
            case .AgoraChatRoomBaseUserCellTypeLock:
                self.iconView.isHidden = true
                self.micView.isHidden = true
                self.bgIconView.image = UIImage(named: "icons／solid／add")
            case .AgoraChatRoomBaseUserCellTypeNormalUser:
                self.iconView.isHidden = false
                self.micView.isHidden = false
                self.micView.setState(.on)
                self.nameBtn.setImage(UIImage(named: ""), for: .normal)
            case .AgoraChatRoomBaseUserCellTypeMuteAndLock:
                self.iconView.isHidden = true
                self.micView.isHidden = false
                self.micView.setState(.forbidden)
                self.bgIconView.image = UIImage(named: "icons／solid／add")
            case .AgoraChatRoomBaseUserCellTypeAdmin:
                self.iconView.isHidden = false
                self.micView.isHidden = false
                self.micView.setState(.on)
                self.nameBtn.setImage(UIImage(named: "fangzhu"), for: .normal)
            case .AgoraChatRoomBaseUserCellTypeAlienNonActive:
                self.iconView.isHidden = false
                self.micView.isHidden = false
                self.micView.setState(.on)
                self.micView.isHidden = true
                self.nameBtn.setImage(UIImage(named: "guanfang"), for: .normal)
                self.coverView.isHidden = false
                self.activeButton.isHidden = false
            case .AgoraChatRoomBaseUserCellTypeAlienActive:
                self.iconView.isHidden = false
                self.micView.isHidden = false
                self.nameBtn.setImage(UIImage(named: "guanfang"), for: .normal)
                self.coverView.isHidden = true
                self.activeButton.isHidden = true
            }
            
        }
    }
    
    public var iconImgUrl: String = "" {
        didSet {
            self.iconView.image = UIImage(named: iconImgUrl)
        }
    }
    
    public var nameStr: String = "" {
        didSet {
            self.nameBtn.setTitle(nameStr, for: .normal)
        }
    }
    
    public var bgColor: UIColor = .black {
        didSet {
            self.bgView.backgroundColor = bgColor
        }
    }
    
    private var bgView: UIView = UIView()
    private var iconView: UIImageView = UIImageView()
    private var bgIconView: UIImageView = UIImageView()
    private var micView: AgoraMicVolView = AgoraMicVolView()
    private var volImgView: UIImageView = UIImageView()
    private var volBgView: UIView = UIView()
    private var nameBtn: UIButton = UIButton()
    private var coverView: UIView = UIView()
    private var activeButton: UIButton = UIButton()
    
    private var arrowImgView: UIImageView = UIImageView()
    private var svgaPlayer: SVGAPlayer = SVGAPlayer()
    private var parser: SVGAParser = SVGAParser()
    public var angle: Double = 0 {
        didSet {
            UIView.animate(withDuration: 0.3) {[weak self] in
                self!.lineView.transform = self!.lineView.transform.rotated(by: self!.angle);
            }
            
        }
    }

    private var lineView: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        SwiftyFitsize.reference(width: 375, iPadFitMultiple: 0.6)
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func layoutUI() {
        
        lineView.backgroundColor = .clear
        lineView.layer.bounds = CGRect(x: 0, y: 0, width: 10~, height: 105~)
        lineView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        self.addSubview(lineView)
        
        self.bgView.layer.cornerRadius = 40~;
        self.bgView.layer.masksToBounds = true
        self.bgView.backgroundColor = UIColor(red: 104/255.0, green: 128/255.0, blue: 1, alpha: 1)
        self.addSubview(self.bgView)

        lineView.addSubview(svgaPlayer)
        svgaPlayer.loops = 0
        svgaPlayer.clearsAfterStop = true
        
        parser.parse(withNamed: "一个箭头", in: nil) {[weak self] videoItem in
            self?.svgaPlayer.videoItem = videoItem
            self?.svgaPlayer.startAnimation()
        }

        self.bgIconView.image = UIImage(named: "icons／solid／add(1)")
        self.bgIconView.layer.cornerRadius = 15~
        self.bgIconView.layer.masksToBounds = true
        self.addSubview(self.bgIconView)
        
        self.iconView.image = UIImage(named: "longkui")
        self.iconView.layer.cornerRadius = 37~
        self.iconView.layer.masksToBounds = true
        self.addSubview(self.iconView)
        
        self.addSubview(micView)
        
        self.nameBtn.setTitleColor(.white, for: .normal)
        self.nameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 11)~
        self.nameBtn.setTitle("jack ma", for: .normal)
        self.nameBtn.isUserInteractionEnabled = false;
        self.addSubview(self.nameBtn)
        
        lineView.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.height.equalTo(self).multipliedBy(0.5)
            make.width.equalTo(30~)
        }
        
        svgaPlayer.snp.makeConstraints { make in
            make.top.left.right.equalTo(lineView)
            make.height.equalTo(30~)
            make.width.equalTo(30~)
        }
        
        self.bgView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(40~);
            make.width.height.equalTo(82~)
        }
        
        self.bgIconView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self.bgView)
            make.width.height.equalTo(30~)
        }
        
        self.iconView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(44~);
            make.width.height.equalTo(74~)
        }
        
        self.micView.snp.makeConstraints { make in
            make.right.equalTo(self.iconView).offset(5~)
            make.width.height.equalTo(18~)
            make.bottom.equalTo(self.iconView.snp.bottom).offset(-5~)
        }
        
        self.nameBtn.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self.iconView.snp.bottom).offset(10~)
            make.height.equalTo(20~)
        }
    }
   

}
