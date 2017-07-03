//
//  GameViewController.h
//  ScreenRecorder
//
//  Created by JT Ma on 03/07/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "Renderer.h"
#import <ReplayKit/ReplayKit.h>

// Our view controller.  Implements the MTKViewDelegate protocol, which allows it to accept
//   per-frame update and drawable resize callbacks.  Also implements the RenderDestinationProvider
//   protocol, which allows our renderer object to get and set drawable properties such as pixel
//   format and sample count

@interface GameViewController : UIViewController<MTKViewDelegate, RenderDestinationProvider, RPPreviewViewControllerDelegate, RPScreenRecorderDelegate>

@property (weak, nonatomic) IBOutlet MTKView *mtkView;

@end


