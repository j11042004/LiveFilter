//
//  ViewController.swift
//  FilterLive
//
//  Created by Uran on 2019/6/25.
//  Copyright © 2019 Uran. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var filterLiveView: FilterLiveView!
    @IBOutlet weak var msgTextView: UITextView!
    let streamURL = URL(string: "https://camerabaymbr-walkgame.cdn.hinet.net/walkgame-camerabaymbr/smil:cbch000066live4.smil/playlist.m3u8")!
    let streamOtherURL = URL(string:"http://camerabaymbr-walkgame.cdn.hinet.net/walkgame-camerabaymbr/smil:cbsi000051auto.smil/playlist.m3u8")!
    var currentPlayingUrl : URL!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.filterLiveView.liveDelegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentPlayingUrl = streamURL
        self.filterLiveView.play(stream: currentPlayingUrl)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2)
        segue.destination.popoverPresentationController?.delegate = self
    }
    
    @IBAction func changeVideo(_ sender: Any) {
        switch currentPlayingUrl {
        case streamURL:
            currentPlayingUrl = streamOtherURL
            break
        default:
            currentPlayingUrl = streamURL
            break
        }
        self.filterLiveView.play(stream: currentPlayingUrl)

    }
}

extension ViewController : UIPopoverPresentationControllerDelegate{
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .formSheet
    }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.filterLiveView.play(stream: streamURL)
    }
}

extension ViewController : FilterLiveDelegate{
    func filterLiveGetQRCode(info: String?) {
        self.msgTextView.text = info
    }
}
