//
//  Capture.h
//  SDKForExpop_Sample
//
//  Created by JT Ma on 08/02/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM( NSInteger, AVCaptureSetupResult ) {
    AVCaptureSetupResultSuccess,
    AVCaptureSetupResultCameraNotAuthorized,
    AVCaptureSetupResultSessionConfigurationFailed
};

@interface Capture : NSObject

@property (nonatomic, assign, readwrite) AVCaptureDevicePosition position;
@property (nonatomic, strong, readonly) AVCaptureSession *session;
@property (nonatomic, copy, readonly) NSString *sessionPreset;
@property (nonatomic, assign, readwrite) AVCaptureSetupResult setupResult;

@property (nonatomic, assign, readwrite) NSInteger activeVideoFrame;

@property (nonatomic, assign, readwrite) AVCaptureFlashMode flashMode;
@property (nonatomic, assign, readwrite) AVCaptureTorchMode torchMode;
@property (nonatomic, assign, readwrite) AVCaptureFocusMode focusMode;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSessionPreset:(NSString *)sessionPreset
                       devicePosition:(AVCaptureDevicePosition)position
                         sessionQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

- (void)start;
- (void)pause;
- (void)stop;

@end
