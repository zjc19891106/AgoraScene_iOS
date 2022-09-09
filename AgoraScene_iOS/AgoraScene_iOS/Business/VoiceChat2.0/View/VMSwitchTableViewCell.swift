//
//  VMSwitchTableViewCell.swift
//  AgoraScene_iOS
//
//  Created by CP on 2022/9/7.
//

import UIKit

class VMSwitchTableViewCell: UITableViewCell {
    
    private var screenWidth: CGFloat = UIScreen.main.bounds.size.width
    private var iconView: UIImageView = UIImageView()
    private var titleLabel: UILabel = UILabel()
    private var swith: UISwitch = UISwitch()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutUI() {
        iconView.frame = CGRect(x: 20~, y: 17~, width: 20~, height: 20~)
        iconView.image = UIImage(named: "icons／set／jiqi")
        self.contentView.addSubview(iconView)
        
        titleLabel.frame = CGRect(x: 50~, y: 17~, width: 200~, height: 20~)
        titleLabel.text = "AgoraBlue"
        titleLabel.textColor = UIColor(red: 60/255.0, green: 66/255.0, blue: 103/255.0, alpha: 1)
        self.contentView.addSubview(titleLabel)
        
        swith.frame = CGRect(x: screenWidth - 65~, y: 13~, width: 45~, height: 28~)
        self.contentView.addSubview(swith)
    }
}