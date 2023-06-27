import UIKit
import SpriteKit
import GoogleMobileAds

class GameViewController: UIViewController, GADBannerViewDelegate {
    var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the banner view.
        let adSize = GADAdSizeFromCGSize(CGSize(width: 430, height: 60)) // Set the desired banner size
        bannerView = GADBannerView(adSize: adSize)
        bannerView.delegate = self

        // Set the ad unit ID and load an ad.
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())

        // Add the banner view to the view hierarchy.
        view.addSubview(bannerView)
        
        // Position the banner at the bottom of the screen with an offset.
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 40) // Adjust the constant value to move the banner lower
        ])
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
