//
//  CapturePreview.h
//  SDKForExpop_Sample
//
//  Created by JT Ma on 08/02/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureVideoPreviewLayer;
@class AVCaptureSession;

@interface CapturePreview : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;

@end
