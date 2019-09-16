//
//  OpenCVViewController.swift
//  FilterLive
//
//  Created by Uran on 2019/8/29.
//  Copyright © 2019 Uran. All rights reserved.
//

import UIKit
import CoreImage
class OpenCVViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!
    let image = UIImage(named: "qrsakura2.png")
    let sakura = UIImage(named: "qrsakura.png")
    let qrCodeImg = UIImage(named: "qrcode.png")
    let qrCode2Img = UIImage(named: "qrcode2.png")
    let openCVWrapper = OpenCVWrapper.sharedInstance()
    lazy var baseImg : UIImage? = self.qrCodeImg
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let img = baseImg {
            self.imageView.image = img
            let resultImg = self.openCVWrapper.convert(img)
            self.resultImageView.image = resultImg
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func convertImage(_ sender: UIButton) {
        guard let img = baseImg else {
            return
        }
        self.imageView.image = img
//        let grayInfo = openCVWrapper.grayTransform(img)
//        self.resultImageView.image = grayInfo
        let qrcodeInfo = openCVWrapper.readQRCode(self.imageView.image!)
        self.resultImageView.image = qrcodeInfo
        
        
        //MARK : CoreImage 辨識 QRcode
        guard let ciImg = CIImage(image: img) else { return }
        let qrcodeDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy : CIDetectorAccuracyLow])
        var options : [String : Any]
        if ciImg.properties.keys.contains(kCGImagePropertyOrientation as String) {
            options = [CIDetectorImageOrientation: ciImg.properties[(kCGImagePropertyOrientation as String)] ?? 1]
        }else {
            options = [CIDetectorImageOrientation: 1]
        }
        guard let features = qrcodeDetector?.features(in: ciImg, options: options) else {
            NSLog("CoreImage 辨識失敗")
            return
        }
        var qrCodeFeatures = [CIQRCodeFeature]()
        for case let feature as CIQRCodeFeature in features{
            qrCodeFeatures.append(feature)
            NSLog("CoreImage 辨識到的 message : \(feature.messageString)")
        }
        
    }
}
