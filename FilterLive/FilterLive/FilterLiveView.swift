//
//  FilterLiveView.swift
//  BlurredVideo
//
//  Created by Uran on 2019/6/27.
//  Copyright © 2019 Greg Niemann. All rights reserved.
//

import UIKit
import AVKit
import CoreImage
import MetalKit
protocol FilterLiveDelegate : AnyObject {
    func filterLiveGetQRCode(info : String?)
}
// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCIContextOptionDictionary(_ input: [String: Any]?) -> [CIContextOption: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (CIContextOption(rawValue: key), value)})
}
// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCIContextOption(_ input: CIContextOption) -> String {
    return input.rawValue
}
class FilterLiveView: MTKView {
    var player: AVPlayer!
    private var output: AVPlayerItemVideoOutput!
    private var displayLink: CADisplayLink!
    private var context: CIContext =  CIContext(options: [CIContextOption.workingColorSpace : NSNull()])
        
//        CIContext(options: convertToOptionalCIContextOptionDictionary([convertFromCIContextOption(CIContextOption.workingColorSpace) : NSNull()]))
    public weak var liveDelegate : FilterLiveDelegate?
    
    //MARK: QRCode
    let webButton = UIButton(type: .custom)
    var qrcodeMsg : String? {
        didSet{
            self.liveDelegate?.filterLiveGetQRCode(info: self.qrcodeMsg)
        }
    }
    //MARK:- init
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self.customInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        self.customInit()
    }
    
    fileprivate func customInit(){
        // MTKView 的 drawable 的 texture 預設是只用來渲染用的
        // 所以要告知他要告知 他不能只用在 Frame buffer，否則會 Crash
        self.framebufferOnly = false
        self.isPaused = false
        
        self.player = AVPlayer()
        self.backgroundColor = .green
        
        self.addSubview(self.webButton)
        self.webButton.backgroundColor = UIColor(white: 1, alpha: 0.3)
        self.webButton.frame = CGRect.zero
        self.webButton.addTarget(self, action: #selector(openQRCodeWeb(_:)), for: .touchUpInside)
        self.webButton.layer.borderColor = UIColor.orange.cgColor
        self.webButton.layer.borderWidth = 2
        
        NotificationCenter.default.addObserver(self, selector: #selector(getNewAccessLog(note:)), name: NSNotification.Name.AVPlayerItemNewAccessLogEntry, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getNewErrorLog(note:)), name: NSNotification.Name.AVPlayerItemNewErrorLogEntry, object: nil)
    }
    //MARK:- Public Function
    public func play(stream: URL) {
        // 決定此 Layer 是否為不透明值
//        layer.isOpaque = true
        let item = AVPlayerItem(url: stream)
        // 建立 AVPlayer Video Output 去接收 AVPlayer Item 的輸出
        if #available(iOS 10.0, *) {
            output = AVPlayerItemVideoOutput(outputSettings: nil)
        } else {
            output = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
        }
        item.add(output)
        
        if let currentItem = self.player.currentItem{
            currentItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            currentItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.error))
        }
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new , .prior ], context: nil)
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.error), options: [.new , .initial , .old , .prior], context: nil)
        self.player.replaceCurrentItem(with: item)
    }
    public func stop() {
        player.rate = 0
        displayLink.invalidate()
    }
    //MARK:- IBACtion Function
    @objc fileprivate func openQRCodeWeb(_ sender : UIButton){
        NSLog("qrcode url : \(self.qrcodeMsg)")
        guard let urlStr = self.qrcodeMsg ,
            let url = URL(string: urlStr)
        else {return}
        UIApplication.shared.open(url, options: [:]) { (_) in
            NSLog("open url")
        }
    }
    //MARK:- Private Function
    private func setupDisplayLink(pause : Bool = false) {
        if self.displayLink != nil{
            self.displayLink.invalidate()
        }
        if pause {
            return
        }
        
        // 利用 displayLink 會去更新螢幕頻率的 Timer 設定
        // 去執行 產生 Filter image 並將其塞回指定的 Timer 的方式
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdated(link:)))
        let fpsNum = 60
        // 設定更新頻率
        if #available(iOS 10.0, *) {
            displayLink.preferredFramesPerSecond = fpsNum
        } else {
            displayLink.frameInterval = fpsNum
        }
        displayLink.add(to: .main, forMode: RunLoop.Mode.common)
    }
    
    /// 利用 displayLink 會去更新螢幕頻率
    ///
    /// - Parameter link: 要更新的 DisplayLink
    @objc private func displayLinkUpdated(link: CADisplayLink) {
        // 取得現在 AVPlayerItem 的 Time
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        // 取得 Time 所在的 Buffer
        guard output.hasNewPixelBuffer(forItemTime: time),
            let pixbuf = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }
        // 將 Buffer 轉換成 CIImage
        let baseImg = CIImage(cvImageBuffer: pixbuf)
        // 對 CIImage 做濾鏡功能
        let resultImg : CIImage = FilterManager.shared.colorMatrix(on: baseImg)
        
        // 此為兩種不同 顯示在 Layer 上的方式
        if 1 == 1 {
            self.updateInBuffer(with: resultImg)
        }else{
            // 將 image 放到 layer上
            guard let cgImg = self.context.createCGImage(resultImg, from: resultImg.extent) else { return }
            layer.contents = cgImg
            layer.displayIfNeeded()
        }
    }
    /// 將處理好的 image 更新到指定的 Buffer 上
    ///
    /// - Parameter img: 處理好的 image，CIImage
    fileprivate func updateInBuffer(with img : CIImage){
        guard let currentDrawable = currentDrawable ,
            let commandQueue = self.device?.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {return}
        let currendTexture = currentDrawable.texture
        // 可使用的面積
        let drawingBounds = CGRect(origin: .zero, size: drawableSize)
        // 將要放到 Buffer 上的 Image Resize Scale
        let scaleX = drawableSize.width / img.extent.width
        let scaleY = drawableSize.height / img.extent.height
        // 取得最小的 Scale
        let minScalse = CGFloat.minimum(scaleX, scaleY)
        let scaledImage = img.transformed(by: CGAffineTransform(scaleX: minScalse, y: minScalse))
        // 將畫面放到指定的 Buffer 上
        context.render(scaledImage, to: currendTexture, commandBuffer: commandBuffer, bounds: drawingBounds, colorSpace: CGColorSpaceCreateDeviceRGB())
        // 顯示 畫面
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
        
        // 對 image 做 QRCode 辨識
        guard
            self.qrcodeMsg == nil ,
            let qrCodeFeatures = QrCoder.shared.decodeQRCode(scaledImage)
        else { return }
        qrCodeFeatures.forEach { (feature) in
            self.qrcodeMsg = feature.messageString
            //設定 QRCode 所在位置
            let imageSize = UIImage(ciImage: scaledImage).size
            let qrCodeFrame = feature.bounds
            // 取得 Scale
            let scaleW = self.frame.width / imageSize.width
            let scaleH = self.frame.height / imageSize.height
            // 計算 x,y,width,height
            let resultX = qrCodeFrame.minX * scaleW
            let currentY = imageSize.height - qrCodeFrame.maxY
            let resultY = currentY * scaleH
            let resultHeight = qrCodeFrame.height * scaleH
            let resultWidth = qrCodeFrame.width * scaleW
            // 設定所在 Frame
            let resultFrame = CGRect(x: resultX-5, y: resultY-5, width: resultWidth+10, height: resultHeight+10)
            self.webButton.frame = resultFrame
        }
    }
}
//MARK:- Notification Func
extension FilterLiveView{
    @objc func getNewAccessLog(note : Notification){
        guard let event = self.player?.currentItem?.accessLog()?.events.last else{ return }
        print("收到新的 Access Log")
        // Player 現在使用的 Bitrate
        let usingBitrate = event.indicatedBitrate
        print("現在的 Bitrate : \(usingBitrate)")
        
        let droppedVideoFrames = event.numberOfDroppedVideoFrames
        let accessBilityFrame = event.accessibilityFrame
        
        print("droppedVideoFrames : \(droppedVideoFrames)")
        print("accessBilityFrame : \(accessBilityFrame)")
        print("segment 下載的 Duration :\(event.segmentsDownloadedDuration)")
        print("延遲的 download : \(event.downloadOverdue)")
        print("mediaRequestsWWAN : \(event.mediaRequestsWWAN)")
        var str = ""
        for _ in 0..<100{
            str.append("\\")
        }
        print(str)
    }
    
    @objc func getNewErrorLog(note : Notification){
        guard let event = self.player?.currentItem?.errorLog()?.events.last else{ return }
        
        print("收到 error Event")
        NSLog("error comment : \(event.errorComment)")
        var str = ""
        for _ in 0..<100{
            str.append("\\")
        }
        print(str)
    }
}


extension FilterLiveView{
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status){
            if let playItem = self.player.currentItem
            {
                switch playItem.status {
                case .readyToPlay:
                    NSLog("item read To play")
                    self.setupDisplayLink()
                    self.player.play()
                    break
                case .failed:
                    NSLog("item get Failed : \(playItem.error?.localizedDescription)")
                    self.setupDisplayLink(pause: true)
                    self.player.pause()
                    break
                default:
                    NSLog("item get unknown : \(playItem.error?.localizedDescription)")
                    self.setupDisplayLink(pause: true)
                    self.player.pause()
                    break
                }
            }
            else
            {
                NSLog("item is nil")
                self.setupDisplayLink(pause: true)
                self.player.pause()
            }
        }
        
        if keyPath == #keyPath(AVPlayerItem.error){
            NSLog("error : \(self.player.currentItem?.error?.localizedDescription)")
        }
    }
}
