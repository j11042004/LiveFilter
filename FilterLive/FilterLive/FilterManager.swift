//
//  FilterManager.swift
//  BlurredVideo
//
//  Created by Uran on 2019/6/27.
//  Copyright © 2019 Greg Niemann. All rights reserved.
//

import UIKit
import CoreImage
//enum ColorMatrixInfo  {
//    case red(Int , Int , Int , Int)
//    case green(Int , Int , Int , Int)
//    case blue(Int , Int , Int , Int)
//    case alpha(Int , Int , Int , Int)
//    case bias(Int , Int , Int , Int)
//}

enum ColorMatrixInfo : String   {
    case red = "inputRVector"
    case green = "inputGVector"
    case blue = "inputBVector"
    case alpha = "inputAVector"
    case bias = "inputBiasVector"
}

class FilterManager: NSObject {
    static let shared = FilterManager()
    public private (set) var redVector : CIVector = CIVector(x: 1, y: 0, z: 0, w: 0)
    public private (set) var greenVector : CIVector = CIVector(x: 0, y: 1, z: 0, w: 0)
    public private (set) var blueVector : CIVector = CIVector(x: 0, y: 0, z: 1, w: 0)
    public private (set) var alphaVector : CIVector = CIVector(x: 0, y: 0, z: 0, w: 1)
    public private (set) var biasVector : CIVector = CIVector(x: 0, y: 0, z: 0, w: 0)
    
    
    /// 對指定的 CIImage 進行 CIColorMatrix 濾鏡
    ///
    /// - Parameter image: 要處理的 CIImage
    /// - Returns: 處理完畢的 CIImage
    public func colorMatrix(on image : CIImage) -> CIImage{
        guard let filter = CIFilter(name: "CIColorMatrix") else {
            return image
        }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(redVector, forKey: ColorMatrixInfo.red.rawValue)
        filter.setValue(greenVector, forKey: ColorMatrixInfo.green.rawValue)
        filter.setValue(blueVector, forKey: ColorMatrixInfo.blue.rawValue)
        filter.setValue(alphaVector, forKey: ColorMatrixInfo.alpha.rawValue)
        filter.setValue(biasVector, forKey: ColorMatrixInfo.bias.rawValue)
        guard let outputImg = filter.outputImage else {
            return image
        }
        return outputImg
    }
    
    /// 更換 Matrix 濾鏡上的 Vector
    ///
    /// - Parameters:
    ///   - type: 要套用的 Vector Type，分別為：
    ///
    ///     - red
    ///     - green
    ///     - blue
    ///     - alpha
    ///     - bias
    ///
    ///   - x: x 值，CGFloat
    ///   - y: y 值，CGFloat
    ///   - z: z 值，CGFloat
    ///   - w:w 值，CGFloat
    func changeVector(type : ColorMatrixInfo ,
                      x : CGFloat ,
                      y : CGFloat ,
                      z : CGFloat ,
                      w : CGFloat){
        switch type {
        case .red:
            NSLog("change red")
            self.redVector = CIVector(x: x, y: y, z: z, w: w)
            break
        case .green:
            NSLog("change green")
            self.greenVector = CIVector(x: x, y: y, z: z, w: w)
            break
        case .blue:
            NSLog("change blue")
            self.blueVector = CIVector(x: x, y: y, z: z, w: w)
            break
        case .alpha:
            NSLog("change alpha")
            self.alphaVector = CIVector(x: x, y: y, z: z, w: w)
            break
        default:
            NSLog("change bias")
            self.biasVector = CIVector(x: x, y: y, z: z, w: w)
            break
        }
    }
}
