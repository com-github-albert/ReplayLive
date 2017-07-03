//
//  GameViewController.m
//  ScreenRecorder
//
//  Created by JT Ma on 03/07/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

#import "GameViewController.h"
#import "Renderer.h"
#import "Capture.h"
#import "CapturePreview.h"

@interface GameViewController ()

@property (nonatomic, strong) Capture *capture;
@property (nonatomic, strong) CapturePreview *capturePreview;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;

@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@end

@implementation GameViewController {
    id<MTLDevice> _device;

    Renderer *_renderer;
    
    dispatch_queue_t _captureQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initCamera];
    self.mtkView.backgroundColor = [UIColor clearColor];
    if (!RPScreenRecorder.sharedRecorder.isAvailable) {
        self.recordButton.hidden = YES;
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
    
    [self checkCaptureSetupResult];
}

- (void)dealloc {
    [self deinitCamera];
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

#pragma mark - ReplayKit
- (IBAction)record:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
         [self startRecording];
        [sender setTitle:@"Stop Record" forState:UIControlStateNormal];
    } else {
        [self stopRecording];
        [sender setTitle:@"Start Record" forState:UIControlStateNormal];
    }
}

- (void)startRecording {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    recorder.delegate = self;
    [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
        if (!error) {

        } else {
            [self alertWithRecordError:error];
        }
    }];
}

- (void)stopRecording {
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        if (!error) {
            if (previewViewController) {
                previewViewController.previewControllerDelegate = self;
                [self presentViewController:previewViewController animated:YES completion:nil];
            }
        } else {
            [self alertWithRecordError:error];
        }
    }];
}

- (void)alertWithRecordError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warining"
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
        [self alertWithRecordError:error];
        if (previewViewController) {
            [previewViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - Camera Settings
- (void)initCamera {
    if (!self.capture) {
        _captureQueue = dispatch_queue_create("com.hiscene.jt.captureSesstionQueue", DISPATCH_QUEUE_SERIAL);
        self.capture = [[Capture alloc] initWithSessionPreset:AVCaptureSessionPreset640x480
                                                   devicePosition:AVCaptureDevicePositionBack
                                                     sessionQueue:_captureQueue];
        
        self.capturePreview = [[CapturePreview alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height / 4 * 3, self.view.bounds.size.height)];
        self.capturePreview.center = self.view.center;
        self.capturePreview.session = self.capture.session;
        self.capturePreview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:self.capturePreview atIndex:0];
        self.capturePreview.backgroundColor = [UIColor blackColor];
        
        dispatch_async( _captureQueue, ^{
            [self configCaptureVideoDataOutput];
        });
    }
}

- (void)configCaptureVideoDataOutput {
    if ( self.capture.setupResult != AVCaptureSetupResultSuccess ) {
        return;
    }
    
    [self.capture.session beginConfiguration];
    /*
     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
     handled by -[AVCamCameraViewController viewWillTransitionToSize:withTransitionCoordinator:].
     */
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
    if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
    }
    self.capturePreview.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
    
    self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureVideoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:
                                                        [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [self.captureVideoDataOutput setSampleBufferDelegate:nil queue:_captureQueue];
    
    if ([self.capture.session canAddOutput:self.captureVideoDataOutput]) {
        [self.capture.session addOutput:self.captureVideoDataOutput];
    } else {
#if DEBUG
        NSLog( @"Could not add video device output to the session" );
#endif
        self.capture.setupResult = AVCaptureSetupResultSessionConfigurationFailed;
        [self.capture.session commitConfiguration];
        return;
    }
    
    AVCaptureConnection *videoConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([videoConnection isVideoOrientationSupported]) {
        videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight; //  SDK only support landscape
    }
    
    [self.capture.session commitConfiguration];
}

- (void)checkCaptureSetupResult {
    dispatch_async( _captureQueue, ^{
        switch ( self.capture.setupResult ) {
            case AVCaptureSetupResultSuccess: {
                // Only setup observers and start the session running if setup succeeded.
                dispatch_async( dispatch_get_main_queue(), ^{
                    self.capture.activeVideoFrame = 30;
                    [self.capture start];
                });
                break;
            }
            case AVCaptureSetupResultCameraNotAuthorized: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"The app doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
            case AVCaptureSetupResultSessionConfigurationFailed: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
        }
    });
}

- (void)deinitCamera {
    dispatch_async( _captureQueue, ^{
        if (self.capture.setupResult != AVCaptureSetupResultSuccess) {
            [self.capture.session removeOutput:self.captureVideoDataOutput];
            self.captureVideoDataOutput = nil;
            self.capturePreview.session = nil;
            self.capturePreview = nil;
            [self.capture pause];
        }
    });
}

@end

