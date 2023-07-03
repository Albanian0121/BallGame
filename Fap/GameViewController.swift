import UIKit
import SpriteKit
import GoogleMobileAds

class GameViewController: UIViewController, GADBannerViewDelegate, GADFullScreenContentDelegate {

    var bannerView: GADBannerView!
    var rewardedAd: GADRewardedAd?
    var userDidEarnReward: Bool = false

    
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
        
        // Load a rewarded ad.
        loadRewardedAd()
        
        if let view = self.view as? SKView {
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                scene.scaleMode = .aspectFill
                scene.gameViewController = self  // Set the gameViewController property of your GameScene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    func loadRewardedAd() {
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: "ca-app-pub-3940256099942544/1712485313", request: request) { (ad, error) in
            if let error = error {
                print("Loading failed: \(error)")
            } else {
                print("Loading Succeeded")
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present ad with error: \(error.localizedDescription)")
    }
    
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("Ad was shown.")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad was dismissed.")
        userDidEarnReward = true
        loadRewardedAd()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
