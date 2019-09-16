//
//  OpenCVWrapper.h
//  FilterLive
//
//  Created by Uran on 2019/8/29.
//  Copyright © 2019 Uran. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (instancetype) sharedInstance;
/**
 將 Image 轉成 灰階影像
 
 @param image 要轉換的 image
 @return 轉換成功的 灰階 image
 */
-(UIImage *)grayTransform:(UIImage *)image;




/**
 OpenCV QRcode 辨識，目前還有多個限制：
 
    1.只有 QRCode 的圖片會無法辨識出來
 
    2.無法辨識同時存在 2 個以上的 QRCode 的 Image
 
 @param image 要辨識的 QRCode Image
 @return 顯示的 QRCode Image
 */
-(UIImage *)readQRCode:(UIImage *)image;



-(UIImage *__nullable)convert:(UIImage * _Nonnull )image;
@end

NS_ASSUME_NONNULL_END
