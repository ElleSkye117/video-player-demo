import UIKit

class PlaylistItemTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var availabilityStatusLabel: UILabel!
    
    var isPlaying: Bool = false {
        didSet {
            self.backgroundColor = isPlaying ? .cyan : .white
        }
    }
    
    weak var viewModel: PlaylistItemViewModel! {
        didSet {
            titleLabel.text = viewModel.title
            availabilityStatusLabel.text = viewModel.statusText
            selectionStyle = viewModel.available ? .blue : .none
        }
    }
    
    
}
