//
//  NoteListCellView.swift
//  TalkNotes
//
//  Created by David Tran on 2020. 03. 21..
//  Copyright © 2020. David Tran. All rights reserved.
//

import UIKit

class NoteUITableViewCell : UITableViewCell {
    private(set) var noteTitle : String = ""
    private(set) var noteText  : String = ""
    private(set) var noteDate  : String = ""
 
    @IBOutlet weak var noteTitleLabel: UILabel!
    @IBOutlet weak var noteTextLabel: UILabel!
    @IBOutlet weak var noteDateLabel: UILabel!
}
