
import UIKit

extension UIFont {
    convenience init ? (
        familyName: String,
        size: CGFloat = UIFont.systemFontSize,
        variantName: String? = nil
    ) {
        guard let name = UIFont.familyNames
                .filter({ $0.contains(familyName) })
                .flatMap({ UIFont.fontNames(forFamilyName: $0) })
                .filter({ variantName != nil ?
                    $0.contains(variantName!) : true
                })
                .first else { return nil }
        
        self.init(name: name, size: size)
    }
}

struct Theme {
    static func apply() {
        guard let headerFont = UIFont(familyName: "Lobster", size: UIFont.systemFontSize * 2) else {
            NSLog("Failed to load header font")
            return
        }
        guard let primaryFont = UIFont(familyName: "Quicksand") else {
            NSLog("Failed to load application font")
            return
        }
        
        let tintColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        UIApplication.shared.delegate?.window??.tintColor = tintColor
        
        let navBarLabel = UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        
        let barButton = UIBarButtonItem.appearance()
        
        let buttonLabel = UILabel.appearance(whenContainedInInstancesOf: [UIButton.self])
        
        let navBar = UINavigationBar.appearance()
        
        let label = UILabel.appearance()
        
        navBar.titleTextAttributes = [.font: headerFont]
        
        navBarLabel.font = primaryFont
        
        label.font = primaryFont
        
        barButton.setTitleTextAttributes([.font: primaryFont], for: .normal)
        barButton.setTitleTextAttributes([.font: primaryFont], for: .highlighted)
    }
}
