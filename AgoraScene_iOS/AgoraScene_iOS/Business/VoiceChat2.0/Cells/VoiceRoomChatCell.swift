//
//  VoiceRoomChatCell.swift
//  Pods-VoiceRoomBaseUIKit_Example
//
//  Created by 朱继超 on 2022/8/30.
//

import UIKit
import ZSwiftBaseLib

public class VoiceRoomChatCell: UITableViewCell {
    
    var chat: VoiceRoomChatEntity? {
        willSet {
            if newValue != nil {
                DispatchQueue.main.async { self.refresh(chat: newValue!) }
            }
        }
    }
    
    lazy var container: UIImageView = {
        UIImageView(frame: CGRect(x: 15, y: 6, width: self.contentView.frame.width-30, height: self.frame.height-6)).image(UIImage("chatBg")!).backgroundColor(.clear)
    }()
    
    lazy var content: UILabel = {
        UILabel(frame: CGRect(x: 10, y: 9, width: self.container.frame.width-20, height: self.container.frame.height - 18)).backgroundColor(.clear).numberOfLines(0)
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.contentView.addSubview(self.container)
        self.container.addSubview(self.content)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh(chat: VoiceRoomChatEntity) {
        self.content.attributedText = chat.attributeContent
        self.container.frame = CGRect(x: 15, y: 6, width: chat.width!, height: chat.height!-6)
        self.content.frame = CGRect(x: 10, y: 9, width: self.container.frame.width-20, height: self.container.frame.height - 18)
        self.container.image = (chat.joined == true ? UIImage("joined_msg_bg")!:UIImage("chatBg")!)
    }
    
}
