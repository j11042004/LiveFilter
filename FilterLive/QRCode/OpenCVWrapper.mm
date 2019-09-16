//
//  OpenCVWrapper.m
//  FilterLive
//
//  Created by Uran on 2019/8/29.
//  Copyright © 2019 Uran. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <CoreFoundation/CoreFoundation.h>


@implementation OpenCVWrapper

+ (instancetype) sharedInstance
{
    static OpenCVWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OpenCVWrapper alloc] init];
    });
    return instance;
}
-(UIImage *__nullable)convert:(UIImage * _Nonnull )image {
    cv::Mat mat = [self cvMatFrom:image];
    UIImage * resultimg = [self convertImageFrom:mat];
    
//    cv::Mat mat;
//    UIImageToMat(image, mat);
//    UIImage * resultimg = MatToUIImage(mat);
    return resultimg;
}
/**
 將 Image 轉成 灰階影像
 
 @param image 要轉換的 image
 @return 轉換成功的 灰階 image
 */
-(UIImage *)grayTransform:(UIImage *)image{
    cv::Mat bgrMat = [self cvMatFrom:image];
    cv::Mat resultMat ;
    switch (bgrMat.type()) {
        case CV_8UC1:{
            cv::Mat convertMat;
            cv::cvtColor(bgrMat, convertMat, cv::COLOR_GRAY2RGB);
            cv::cvtColor(convertMat, resultMat, cv::COLOR_RGB2GRAY);
            NSLog(@"mat type is CV_8UC1");
        }
            break;
        case CV_8UC2:
            NSLog(@"mat type is CV_8UC2");
            break;
        case CV_8UC3:
            NSLog(@"mat type is CV_8UC3");
            break;
        case CV_8UC4:
            cv::cvtColor(bgrMat, resultMat, cv::COLOR_RGB2GRAY);
            NSLog(@"mat type is CV_8UC4");
            break;
        default:
            std::cout<<"mat type is "<<bgrMat.type()<<std::endl;
            break;
    }
    UIImage *grayImage = [self convertImageFrom:resultMat];
    return grayImage;
}
-(UIImage *)readQRCode:(UIImage *)image{
    cv::Mat sourceMat = [self cvMatFrom:image];
    // 把 image Mat 轉成 灰階 Mat
    cv::Mat grayImgMat;
    if(sourceMat.type() == CV_8UC1){
        cv::Mat convertMat;
        cv::cvtColor(sourceMat, convertMat, cv::COLOR_GRAY2BGR);
        cv::cvtColor(convertMat, grayImgMat, cv::COLOR_BGR2GRAY);
        
    }else {
        cv::cvtColor(sourceMat, grayImgMat, cv::COLOR_BGR2GRAY);
    }
    // 影像反色
//    cv::bitwise_not(grayImgMat, grayImgMat);
    // 進行 高斯模糊化
    cv::Mat gaussianMat;
    cv::GaussianBlur(grayImgMat, gaussianMat, cv::Size(5,5), 0);
    // 進行邊緣檢測，若是只使用此就會描繪 image 得線條
    cv::Mat cannyEdageMat ;
    cv::Canny(grayImgMat, cannyEdageMat, 100, 200);
    // 定位標記搜尋
    // 階層
    std::vector<cv::Vec4i> hierarchy;
    // 輪廓
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(cannyEdageMat, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);
    
    
    // 使用 opencv 提供的 QRCodeDetector 去進行辨識
    // 但只能辨識只有一個 QRcode 的 Image
    [self qrcodeDetector:grayImgMat];
    return [self convertImageFrom:cannyEdageMat];
}

-(void)qrcodeDetector:(cv::Mat)grayImgMat{
    cv::QRCodeDetector detector = cv::QRCodeDetector();
    std::vector<cv::Point> detectPoints;
    bool allowDetect = detector.detect(grayImgMat, detectPoints);
    if (allowDetect) {
        std::vector<cv::Point> points;
        cv::Mat qrcodeInfoMat;
        std::string codeInfo = detector.detectAndDecode(grayImgMat ,points ,qrcodeInfoMat);
        NSArray<NSValue *> * getPoints = [self pointsFrom:points];
        NSString *infoMsg = [NSString stringWithCString:codeInfo.c_str() encoding:[NSString defaultCStringEncoding]];
        NSLog(@"取出的 QRCode 資訊 :%@",infoMsg);
        NSLog(@"get points count : %lu",getPoints.count);
    } else {
        NSLog(@"不允許辨識");
    }
}
//MARK:- Private Function

/**
 將 UIImage 轉換成 OpenCV 能使用的 cv::Mat
 
 @param image 要轉換的 Image
 @return Image 對應的 cv::Mat
 */
-(cv::Mat)cvMatFrom:(UIImage *)image{
    // 這是 opencv2/imgcodecs/ios.h 下所包裝的 function
    cv::Mat mat ;
    UIImageToMat(image, mat);
    return mat;
/*
    // 這是 OpenCV 提供的方法
    // 因有些 Image 的組成只有 #fff 與 #000
    // 所以 MatType 應該為 CV_8UC1，若是設定為 CV_8UC4 就會出現 image 變窄問題
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
*/
}
/**
 將 cv::Mat 檔案轉換成 UIImage
 
 @return 轉換完成的 UIImage
 */
-(UIImage *)convertImageFrom:(cv::Mat)cvMat{
    return MatToUIImage(cvMat);
/*
    // 這是 OpenCV 2.x 版提供的方法
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentSaturation                //intent
                                        );
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
*/
}


//MARK:- Open CV 格式轉成 Objective-c 的 Function
/**
 目前是將 image 得到的 4*1 的 matrix 轉換成能用的 NSArray;
 
 @return NSArray<NSNumber*>*
 */
-(NSArray<NSNumber*>*)arrayChangeFrom:(cv::Vec4i)vecMatrix {
    int rows = vecMatrix.rows;
    NSMutableArray<NSNumber*>* resultArray = [NSMutableArray array];
    for(int row=0 ; row<rows ; row++){
        int element = vecMatrix.cv::Matx<int, 4, 1>::operator()(row, 0);
        NSNumber* value = [NSNumber numberWithInt:element];
        [resultArray addObject:value];
    }
    return resultArray;
}

/**
 將 std::Vector<cv::Point> 格式轉換成 NSArray<NSNumber>，
 
 NSNumber 內是 CGPoint

 @return NSArray<NSNumber>
 */
-(NSArray<NSValue *>*)pointsFrom:(std::vector<cv::Point>)pointsVecMatrix{
    NSMutableArray<NSValue *>* pointsArray = [NSMutableArray array];
    for(int i=0; i<pointsVecMatrix.size(); i++){
        cv::Point point = pointsVecMatrix.at(i);
        int x = point.x;
        int y = point.y;
        float floatX = [[NSNumber numberWithInteger:x] floatValue];
        float floatY = [[NSNumber numberWithFloat:y] floatValue];
        CGPoint resultPoint = CGPointMake(floatX, floatY);
        NSValue * pointValue = [NSValue valueWithCGPoint:resultPoint];
        [pointsArray addObject:pointValue];
    }
    return pointsArray;
}
@end
