//
//  GameViewController.m
//  ScreenRecorder
//
//  Created by JT Ma on 03/07/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

#import "GameViewController.h"
#import "Renderer.h"

@interface GameViewController () <RPBroadcastActivityViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *liveButton;
@property (nonatomic, strong) RPBroadcastController *broadcastController;
@end

@implementation GameViewController {
    id<MTLDevice> _device;

    Renderer *_renderer;
    
    dispatch_queue_t _captureQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.backgroundColor = [UIColor clearColor];
    if (!RPScreenRecorder.sharedRecorder.isAvailable) {
        [self.recordButton removeFromSuperview];
    }
    if (![self broadcastIsAvailable]) {
        [self.liveButton removeFromSuperview];
    }
    
    // Set the view to use the default device
    _device = MTLCreateSystemDefaultDevice();
    NSParameterAssert(_device);
    self.mtkView.delegate = self;
    self.mtkView.device = _device;

    _renderer = [[Renderer alloc] initWithMetalDevice:_device
                            renderDestinationProvider:self];

    [_renderer drawRectResized:self.mtkView.bounds.size];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addActiveNotification];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self removeActiveNotification];
}

// Called whenever view changes orientation or layout is changed
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    [_renderer drawRectResized:view.bounds.size];
}

// Called whenever the view needs to render
- (void)drawInMTKView:(nonnull MTKView *)view {
    @autoreleasepool {
        [_renderer update];
    }
}

// Methods to get and set state of the our ultimate render destination (i.e. the drawable)
# pragma mark RenderDestinationProvider implementation
- (MTLRenderPassDescriptor*) currentRenderPassDescriptor {
    return self.mtkView.currentRenderPassDescriptor;
}

- (MTLPixelFormat) colorPixelFormat {
    return self.mtkView.colorPixelFormat;
}

- (void) setColorPixelFormat: (MTLPixelFormat) pixelFormat {
    self.mtkView.colorPixelFormat = pixelFormat;
}

- (MTLPixelFormat) depthStencilPixelFormat {
    return self.mtkView.depthStencilPixelFormat;
}

- (void) setDepthStencilPixelFormat: (MTLPixelFormat) pixelFormat {
    self.mtkView.depthStencilPixelFormat = pixelFormat;
}

- (NSUInteger) sampleCount {
    return self.mtkView.sampleCount;
}

- (void) setSampleCount:(NSUInteger) sampleCount {
    self.mtkView.sampleCount = sampleCount;
}

- (id<MTLDrawable>) currentDrawable {
    return self.mtkView.currentDrawable;
}

#pragma mark - ActiveNotification
- (void)addActiveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)removeActiveNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
}

- (void)didBecomeActive {

}

- (void)willResignActive {
    if (RPScreenRecorder.sharedRecorder.isRecording) {
        [self stopRecordingWithDiscarded:YES];
        [self record:self.recordButton];
    }
}

#pragma mark - ReplayKit
- (IBAction)record:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
         [self startRecording];
        [sender setTitle:@"Stop Record" forState:UIControlStateNormal];
    } else {
        [self stopRecordingWithDiscarded:NO];
        [sender setTitle:@"Record" forState:UIControlStateNormal];
    }
}

- (void)startRecording {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    recorder.delegate = self;
    [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
        if (!error) {

        } else {
            NSString *title = @"Start Record";
            [self alertWithTitle:title WithRecordError:error];
        }
    }];
}

- (void)stopRecordingWithDiscarded:(BOOL)isDiscard {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        if (!error) {
            if (previewViewController) {
                if (isDiscard) {
                    [recorder discardRecordingWithHandler:^{
                        
                    }];
                } else {
                    previewViewController.previewControllerDelegate = self;
                    [self presentViewController:previewViewController animated:YES completion:nil];
                }
            }
        } else {
            NSString *title = @"Stop Record";
            [self alertWithTitle:title WithRecordError:error];
        }
    }];
}

- (void)alertWithTitle:(NSString *)title WithRecordError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - RPPreviewViewControllerDelegate
- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    previewController.previewControllerDelegate = nil;
    [previewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)previewController:(RPPreviewViewController *)previewController didFinishWithActivityTypes:(NSSet<NSString *> *)activityTypes {
    NSLog(@"didFinishWithActivityTypes");
}

#pragma mark - RPScreenRecorderDelegate
- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder {
    NSLog(@"screenRecorderDidChangeAvailability");
}

- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithError:(NSError *)error previewViewController:(RPPreviewViewController *)previewViewController {
    if (error) {
        NSString *title = @"Record Error";
        [self alertWithTitle:title WithRecordError:error];
        if (previewViewController) {
            [previewViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - Broadcast
- (BOOL)broadcastIsAvailable {
    return UIDevice.currentDevice.systemVersion.doubleValue >= 10.0;
}

- (IBAction)broadcast:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self openLive];
        [sender setTitle:@"Close Live" forState:UIControlStateNormal];
    } else {
        [self closeLive];
        [sender setTitle:@"Live" forState:UIControlStateNormal];
    }
}

- (void)openLive {
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
        __weak typeof(self) weakSelf = self;
        if (error) {
            NSString *title = @"Open Live";
            [weakSelf alertWithTitle:title WithRecordError:error];
        } else {
            broadcastActivityViewController.delegate = self;
            [weakSelf presentViewController:broadcastActivityViewController animated:YES completion:nil];
        }
    }];
}

- (void)closeLive {
    [self.broadcastController finishBroadcastWithHandler:^(NSError * _Nullable error) {
        __weak typeof(self) weakSelf = self;
        if (error) {
            NSString *title = @"Close Live";
            [weakSelf alertWithTitle:title WithRecordError:error];
        }
        RPScreenRecorder.sharedRecorder.cameraEnabled = NO;
        RPScreenRecorder.sharedRecorder.microphoneEnabled = NO;
        [RPScreenRecorder.sharedRecorder.cameraPreviewView removeFromSuperview];
    }];
}

#pragma mark - RPBroadcastActivityViewControllerDelegate
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(RPBroadcastController *)broadcastController error:(NSError *)error {
    if (error) {
        NSString *title = @"Live Error";
        [self alertWithTitle:title WithRecordError:error];
    } else {
        RPScreenRecorder.sharedRecorder.cameraEnabled = YES;
        RPScreenRecorder.sharedRecorder.microphoneEnabled = YES;
        
        self.broadcastController = broadcastController;
        [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
            __weak typeof(self) weakSelf = self;
            if (error) {
                NSString *title = @"Start Broad";
                [weakSelf alertWithTitle:title WithRecordError:error];
            } else {
                RPScreenRecorder.sharedRecorder.cameraPreviewView.frame = CGRectMake(20, self.view.bounds.size.height - 150 - 20, 150, 150);
                [weakSelf.view addSubview:RPScreenRecorder.sharedRecorder.cameraPreviewView];
            }
        }];
    }
    [broadcastActivityViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
