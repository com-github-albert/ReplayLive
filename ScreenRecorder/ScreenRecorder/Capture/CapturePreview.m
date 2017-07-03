//
//  CapturePreview.m
//  SDKForExpop_Sample
//
//  Created by JT Ma on 08/02/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

#import "CapturePreview.h"

#import <AVFoundation/AVFoundation.h>

@implementation CapturePreview

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session {
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    if (!self.videoPreviewLayer.session) {
        self.videoPreviewLayer.session = session;
    }
}

@end
