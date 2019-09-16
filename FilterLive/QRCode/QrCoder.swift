//
//  QrCoder.swift
//  HellowQRCode
//
//  Created by Uran on 2019/7/29.
//  Copyright © 2019 Uran. All rights reserved.
//

import UIKit
import CoreImage


class QrCoder: NSObject {
    static let shared = QrCoder()
    fileprivate lazy var qrcodeDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy : CIDetectorAccuracyLow])
    /// 辨識 Image 看是否有 QRCode 在 Image
    ///
    /// 取得的 QRCode 所在的座標是以 數學座標軸的方向 為基準，
    /// 若要在 程式上做使用 就要用 圖片的座標軸作轉換
    ///
    /// - Parameter img: 要辨識的 UIImage
    /// - Returns: 辨識完畢的 QRCode 資料，[CIQRCideFeature]?
    public func decodeQRCode(_ img : UIImage?) -> [CIQRCodeFeature]?{
        guard let image = img else {return nil}
        return self.decodeQRCode(CIImage(image: image))
    }
    /// 辨識 Image 看是否有 QRCode 在 Image
    ///
    /// 取得的 QRCode 所在的座標是以 數學座標軸的方向 為基準，
    /// 若要在 程式上做使用 就要用 圖片的座標軸作轉換
    ///
    /// - Parameter img: 要辨識的 CIImage
    /// - Returns: 辨識完畢的 QRCode 資料，[CIQRCideFeature]?
    public func decodeQRCode(_ img : CIImage?) -> [CIQRCodeFeature]?{
        guard let ciImg = img else { return nil }
        var options : [String : Any]
        if ciImg.properties.keys.contains(kCGImagePropertyOrientation as String) {
            options = [CIDetectorImageOrientation: ciImg.properties[(kCGImagePropertyOrientation as String)] ?? 1]
        }else {
            options = [CIDetectorImageOrientation: 1]
        }
        guard
            let features = qrcodeDetector?.features(in: ciImg, options: options)
            else { return nil }
        var qrCodeFeatures = [CIQRCodeFeature]()
        for case let feature as CIQRCodeFeature in features{
            qrCodeFeatures.append(feature)
        }
        return qrCodeFeatures
    }
}
