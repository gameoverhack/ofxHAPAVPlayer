//
//  ofxHAPAVPlayerDelegate.cpp
//  AVFoundering
//
//  Created by gameover on 8/06/16.
//
//

#include "ofxHAPAVPlayerDelegate.h"
#include <mach/mach_time.h>
#import <QuartzCore/QuartzCore.h>

uint64_t getTickCount(void)
{
    static mach_timebase_info_data_t sTimebaseInfo;
    uint64_t machTime = mach_absolute_time();
    
    // Convert to nanoseconds - if this is the first time we've run, get the timebase.
    if (sTimebaseInfo.denom == 0 )
    {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    
    // Convert the mach time to milliseconds
    uint64_t millis = ((machTime / 1000000) * sTimebaseInfo.numer) / sTimebaseInfo.denom;
    return millis;
}

@implementation ofxHAPAVPlayerDelegate

static NSString * const kTracksKey = @"tracks";
static NSString * const kStatusKey = @"status";
static NSString * const kRateKey = @"rate";

static const void *ItemStatusContext = &ItemStatusContext;
static const void *PlayerRateContext = &ItemStatusContext;


- (id) init	{
    
	self = [super init];
    
    asyncLock = [[NSLock alloc] init];
    
    self.player = [[AVPlayer alloc] init];
    //[self.player autorelease];
    
    //[self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
    //_rate = 1.0;
    
    //	make the displaylink, which will drive rendering
    CVReturn				err = kCVReturnSuccess;
    CGOpenGLDisplayMask		totalDisplayMask = 0;
    GLint					virtualScreen = 0;
    GLint					displayMask = 0;
    NSOpenGLPixelFormat		*format = [self createGLPixelFormat];
    
    for (virtualScreen=0; virtualScreen<[format numberOfVirtualScreens]; ++virtualScreen){
        [format getValues:&displayMask forAttribute:NSOpenGLPFAScreenMask forVirtualScreen:virtualScreen];
        totalDisplayMask |= displayMask;
    }
    err = CVDisplayLinkCreateWithOpenGLDisplayMask(totalDisplayMask, &displayLink);
    if(err){
        NSLog(@"\t\terr %d creating display link in %s",err,__func__);
        displayLink = NULL;
    }else{
        CVDisplayLinkSetOutputCallback(displayLink, displayLinkCallback, self);
        CVDisplayLinkStart(displayLink);
    }
    
	return self;
}

//- (void) setParent:(ofxHAPAVPlayerInterOp*)_parent{
//    parent = _parent;
//}

//---------------------------------------------------------- cleanup / dispose.
- (void)dealloc
{

    if (self.player != nil){
        [self unloadVideo];
    }
    
    [asyncLock lock];
    
//    if(_dedcodedFrame != nil){
        NSLog(@"release dxt frame");
        [_dedcodedFrame release];
        _dedcodedFrame = nil;
//    }
    
//    if(_imageBuffer != nil){
        NSLog(@"release image buffer ");
        CVPixelBufferRelease(_imageBuffer);
        _imageBuffer = nil;
//    }

//    if(displayLink != nil){
        NSLog(@"release cvdisplaylink");
        CVDisplayLinkStop(displayLink);
        CVDisplayLinkRelease(displayLink);
        displayLink = nil;
//    }
    
//    if(videoTextureCache != nil){
        NSLog(@"release texture cache");
        CVOpenGLTextureCacheRelease(videoTextureCache);
        videoTextureCache = nil;
//    }
//    if(videoTextureRef != nil){
        NSLog(@"release texture ref");
        CVOpenGLTextureRelease(videoTextureRef);
        videoTextureRef = nil;
//    }
    
    [asyncLock unlock];
    

//    [asyncLock lock];
//    
//    [asyncLock unlock];
    
    // release locks
    [asyncLock autorelease];
    
    if (deallocCond != nil) {
        [deallocCond release];
        deallocCond = nil;
    }
    
    NSLog(@"dealloc kill");
    
    [super dealloc];
    
}

- (void)unloadVideo
{
    // create a condition
    deallocCond = [[NSCondition alloc] init];
    [deallocCond lock];
    
    // unload current video
    [self close];
    
    // wait for unloadVideoAsync to finish
    [deallocCond wait];
    [deallocCond unlock];
    
    [deallocCond release];
    deallocCond = nil;
}

- (void)close
{
    
    [self stop];
    
    // a reference to all the variables for the block
    __block AVAsset* currentAsset = self.asset;
    __block AVPlayerItem* currentItem = self.playerItem;
    __block AVPlayer* currentPlayer = self.player;
    //__block id currentTimeObserver = timeObserver;
    __block AVPlayerItemVideoOutput* currentAVFVideoOutput = self.nativeAVFOutput;
    __block AVPlayerItemHapDXTOutput* currentHAPVideoOutput = self.hapOutput;
    //    __block CVPixelBufferRef currentImageBuffer = _imageBuffer;
    //    __block HapDecoderFrame* currentDTXFrame = _dedcodedFrame;
    
    //    __block CVDisplayLinkRef currentDisplayLinkRef = displayLink;
    //    __block CVOpenGLTextureCacheRef currentVideoTextureCache = videoTextureCache;
    //    __block CVOpenGLTextureRef currentVideoTextureRef = videoTextureRef;
    
    //set all to nil
    //cleanup happens in the block
    _asset = nil;
    self.asset = nil;
    
    _playerItem = nil;
    self.playerItem = nil;
    
    _player = nil;
    self.player = nil;
    
    //    timeObserver = nil;
    
    _nativeAVFOutput = nil;
    self.nativeAVFOutput = nil;
    
    _hapOutput = nil;
    self.hapOutput = nil;
    
    //    _imageBuffer = nil;
    //    _dedcodedFrame = nil;
    
    //    displayLink = nil;
    //
    //    self.videoTextureCache = nil;
    //    videoTextureCache = nil;
    //
    //    self.videoTextureRef = nil;
    //    videoTextureRef = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @autoreleasepool {
            
            [asyncLock lock];
            
//            if(currentDTXFrame != nil){
//                NSLog(@"release dxt frame");
//                [currentDTXFrame release];
//                currentDTXFrame = nil;
//            }
//
//            if(currentImageBuffer != nil){
//                NSLog(@"release image buffer ");
//                CVPixelBufferRelease(currentImageBuffer);
//                currentImageBuffer = nil;
//            }

//            if(currentDisplayLinkRef != nil){
//                NSLog(@"release cvdisplaylink");
//                CVDisplayLinkStop(currentDisplayLinkRef);
//                CVDisplayLinkRelease(currentDisplayLinkRef);
//                currentDisplayLinkRef = nil;
//            }
//
//            if(currentVideoTextureCache != nil){
//                NSLog(@"release texture cache");
//                CVOpenGLTextureCacheRelease(currentVideoTextureCache);
//                currentVideoTextureCache = nil;
//            }
//            if(currentVideoTextureRef != nil){
//                NSLog(@"release texture ref");
//                CVOpenGLTextureRelease(currentVideoTextureRef);
//                currentVideoTextureRef = nil;
//            }
            
            _bFrameNeedsRender = NO;
            
            // release asset
            if (currentAsset != nil) {
                NSLog(@"release asset");
                [currentAsset cancelLoading];
                [currentAsset autorelease];
                currentAsset = nil;
            }
            
            
            // release current player item
            if(currentItem != nil) {
                NSLog(@"release playerItem");
                [currentItem cancelPendingSeeks];
                //[currentItem removeObserver:self forKeyPath:kStatusKey context:&ItemStatusContext];
                
                NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
                [notificationCenter removeObserver:self
                                              name:AVPlayerItemDidPlayToEndTimeNotification
                                            object:currentItem];
                
                if(currentHAPVideoOutput != nil){
                    NSLog(@"release hap output");
                    // remove output
                    [currentItem removeOutput:currentHAPVideoOutput];
                    
                    // release videouOutput
                    if (currentHAPVideoOutput != nil) {
                        [currentHAPVideoOutput autorelease];
                        currentHAPVideoOutput = nil;
                    }
                    
                }
                
                if(currentAVFVideoOutput != nil){
                    NSLog(@"release native output");
                    // remove output
                    [currentItem removeOutput:currentAVFVideoOutput];
                    
                    // release videouOutput
                    if (currentAVFVideoOutput != nil) {
                        [currentAVFVideoOutput autorelease];
                        currentAVFVideoOutput = nil;
                    }
                    
                }
                
                [currentItem autorelease];
                currentItem = nil;
                
            }

            // destroy current player
            if (currentPlayer != nil) {
                NSLog(@"release player");
                //[currentPlayer removeObserver:self forKeyPath:kRateKey context:&PlayerRateContext];
                
//                if (currentTimeObserver != nil) {
//                    [currentPlayer removeTimeObserver:currentTimeObserver];
//                    [currentTimeObserver release];
//                    currentTimeObserver = nil;
//                }
                [currentPlayer replaceCurrentItemWithPlayerItem:nil];
                [currentPlayer autorelease];
                currentPlayer = nil;
            }
            
            [asyncLock unlock];
            
            if (deallocCond != nil) {
                [deallocCond lock];
                [deallocCond signal];
                [deallocCond unlock];
            }
            NSLog(@"there kill");
        }
    });
    
    NSLog(@"here kill");



}

- (void) load:(NSString *)path{

    NSLog(@"yeah kill");

    _bLoaded = false;
    
    //NSLog(@"%s %@",__func__,path);
    
	//	make url
	NSURL *url = (path==nil) ? nil : [NSURL fileURLWithPath:path];
    
    if (self.asset != nil) {
        [self.asset cancelLoading];
    }
    
    // make asset
    NSDictionary *options = @{(id)AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    self.asset = (url==nil) ? nil : [AVURLAsset URLAssetWithURL:url options:options];
    
    // error check url and asset creation
    if(self.asset == nil) {
        NSLog(@"error loading asset: %@", [url description]);
        return;
        //return NO;
    }
    
    // for now always async
    BOOL bAsync = YES;
    
    // setup dispatch queue
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t queue;
    if(bAsync == YES){
        queue = dispatch_get_main_queue();
    } else {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }

    // dispatch the queue
    dispatch_async(queue, ^{
        [self.asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:kTracksKey] completionHandler:^{
            
//            if(self.player == nil){
//                self.player = [[AVPlayer alloc] init];
//                //[self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
//            }
            
            double startTime = getTickCount();
            
            NSError * error = nil;
            AVKeyValueStatus status = [self.asset statusOfValueForKey:kTracksKey error:&error];
            
            if(status != AVKeyValueStatusLoaded) {
                NSLog(@"error loading asset tracks: %@", [error localizedDescription]);
                // reset
                //bReady = false;//_bReady;
                _bLoaded = false;//_bLoaded;
                //bPlayStateBeforeLoad = _bPlayStateBeforeLoad;
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                return;
            }
            
            _duration = [self.asset duration];
            
            if(CMTimeCompare(_duration, kCMTimeZero) == 0) {
                NSLog(@"track loaded with zero duration.");
                // reset
                //bReady = false;//_bReady;
                _bLoaded = false;//_bLoaded;
                //bPlayStateBeforeLoad = _bPlayStateBeforeLoad;
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                return;
            }
            
            NSArray * videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
            if([videoTracks count] == 0) {
                NSLog(@"no video tracks found.");
                // reset
                //bReady = false;//_bReady;
                _bLoaded = false;//_bLoaded;
                //bPlayStateBeforeLoad = _bPlayStateBeforeLoad;
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                return;
            }
            
            [asyncLock lock];
            
//            if (_bIsUnloaded) {
//                NSLog(@"Unload error");
//                // player was unloaded before we could load everting
//                _bIsUnloaded = NO;
//                if(bAsync == NO){
//                    dispatch_semaphore_signal(sema);
//                }
//                [asyncLock unlock];
//                return;
//            }
            
            _bLoading = YES;
            
            
            // create asset reader
            // do we need one here? Lukasz does this and seems to maybe have something to do with time?

            if (self.playerItem != nil){
                [self.playerItem cancelPendingSeeks];
                //unregister as an observer for the "old" item's play-to-end notifications
                [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                                              object:self.playerItem];
            }
            
            //	make a player item
            self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
            
            if (self.playerItem == nil)	{
                NSLog(@"\t\terr: couldn't make AVPlayerItem in %s",__func__);
                return;
            }

            // get info from track (assume just one video track at position 0 - is this wise?
            // otherwise use: for (AVAssetTrack *trackPtr in videoTracks) etc....
            AVAssetTrack * videoTrack = videoTracks.firstObject;
            _frameRate = videoTrack.nominalFrameRate;
            _videoWidth = [videoTrack naturalSize].width;
            _videoHeight = [videoTrack naturalSize].height;
            _totalFrames = floor((float)CMTimeGetSeconds(_duration) * _frameRate);
            _minFrameDuration = videoTrack.minFrameDuration;
            _rate = 1.0; // reset rate to normal forward playback
            
            // extract codec subtype
            OSType fourcc;
            NSArray	*trackFormatDescs = [videoTrack formatDescriptions];
            CMFormatDescriptionRef desc = (trackFormatDescs==nil || [trackFormatDescs count]<1) ? nil : (CMFormatDescriptionRef)[trackFormatDescs objectAtIndex:0];
            if (desc==nil){
                NSLog(@"\t\terr: desc nil in %s",__func__);
            }else{
                fourcc = CMFormatDescriptionGetMediaSubType(desc);
                char destChars[5];
                destChars[0] = (fourcc>>24) & 0xFF;
                destChars[1] = (fourcc>>16) & 0xFF;
                destChars[2] = (fourcc>>8) & 0xFF;
                destChars[3] = (fourcc) & 0xFF;
                destChars[4] = 0;
                //NSLog(@"codec sub-type is '%@'", [NSString stringWithCString:destChars encoding:NSASCIIStringEncoding]);
            }
            
            @synchronized (self) {
                
                if (self.playerItem != nil && self.hapOutput != nil){
                    [_dedcodedFrame release];
                    _dedcodedFrame = nil;
                    [self.playerItem removeOutput:self.hapOutput];
                }
                if (self.playerItem != nil && self.nativeAVFOutput != nil){
                    CVPixelBufferRelease(_imageBuffer);
                    _imageBuffer = nil;
                    [self.playerItem removeOutput:self.nativeAVFOutput];
                }
                
                switch (fourcc) {
                    case kHapCodecSubType:
                    case kHapAlphaCodecSubType:
                    case kHapYCoCgCodecSubType:
                    case kHapYCoCgACodecSubType:
                    case kHapAOnlyCodecSubType:
                    {

                        if(self.hapOutput == nil){
                            self.hapOutput = [[AVPlayerItemHapDXTOutput alloc] init];
                            [self.hapOutput setSuppressesPlayerRendering:YES];
                        }
                        
                        //	add the outputs to the new player item
                        [self.playerItem addOutput:self.hapOutput];
                        _bHAPEncoded = YES;
                        
                    }
                        break;
                    default:
                    {

                        if(self.nativeAVFOutput == nil){
                            NSDictionary *pba = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, [NSNumber numberWithBool:YES], kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey, nil];
                            //NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
                            self.nativeAVFOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pba];
                            [self.nativeAVFOutput setSuppressesPlayerRendering:YES];
                        }

                        //	add the outputs to the new player item
                        [self.playerItem addOutput:self.nativeAVFOutput];
                        _bHAPEncoded = NO;
                    }
                        
                        break;
                }
                
                //register to receive notifications that the new player item has played to its end
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(itemDidPlayToEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:self.playerItem];

                //	tell the player to start playing the new player item
                if ([NSThread isMainThread]){
                    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                }else{
                    [self.player performSelectorOnMainThread:@selector(replaceCurrentItemWithPlayerItem:) withObject:self.playerItem waitUntilDone:NO]; // change this to NO to make it really non-block!!????
                }
            
                // loaded
                _bLoaded = YES;
                _bLoading = NO;
                _bFrameNeedsRender = NO;
                
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                
                [asyncLock unlock];
                
                [self.player seekToTime:kCMTimeZero];
                [self.player setRate:1.0f];
            }
            
        }];
    });
    
    if (_videoTextureCache == nil) {
        CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                                                  nullptr,
                                                  CGLGetCurrentContext(),
                                                  CGLGetPixelFormat(CGLGetCurrentContext()),
                                                  nullptr,
                                                  &_videoTextureCache);
        
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLTextureCacheCreate %d", err);
        }
        
    }
    
    
    // Wait for the dispatch semaphore signal
    if(bAsync == NO){
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
        return _bLoaded;
    } else {
        dispatch_release(sema);
        return YES;
    }
    
}

- (void) itemDidPlayToEnd:(NSNotification *)note {
    [self.player seekToTime:kCMTimeZero];
    [self.player setRate:_rate];
}

- (void) play{
    [self.player setRate:_rate];
}

- (void) stop{
    [self.player setRate:0.0f];
}

- (void) setPaused:(BOOL)bPaused{
    if(bPaused){
        [self.player setRate:0.0f];
    }else{
        [self.player setRate:_rate];
    }
}

- (void) setSpeed:(float)speed{
    _rate = speed;
    [self.player setRate:_rate];
}

- (void)setPosition:(float)position {
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(_duration) * position, NSEC_PER_SEC);
    time = CMTimeMaximum(time, kCMTimeZero);
    time = CMTimeMinimum(time, _duration);
    [self.player seekToTime:time
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero
          completionHandler:^(BOOL finished)
    {
//            int nFrame = CMTimeGetSeconds([self.player currentTime]) * frameRate;
//            NSLog(@"setPosComp: %d", nFrame);
//            [self.player setRate:tRate];
    }];
}

- (void)setFrame:(int)frame {
    float position = (float)frame / (float)_totalFrames;
    [self setPosition:position];
}

- (int) getCurrentFrame{
    if(!_bLoaded) return 0;
    return _currentFrame;
}
- (void) setCurrentFrame:(CMTime)frameTime{
    _currentFrame = CMTimeGetSeconds(frameTime) *  _frameRate;
}

- (NSInteger) getWidth{
    if(!_bLoaded) return 0;
    return _videoWidth;
}

- (NSInteger) getHeight{
    if(!_bLoaded) return 0;
    return _videoHeight;
}

- (float) getFrameRate{
    if(!_bLoaded) return 0;
    return _frameRate;
}

- (int) getTotalNumFrames{
    if(!_bLoaded) return 0;
    return _totalFrames;
}

- (CMTime) getDuration{
    if(!_bLoaded) return kCMTimeZero;
    return _duration;
}

- (AVPlayer*) getPlayer{
    return self.player;
}

- (AVPlayerItemVideoOutput*) getAVFOutput{
    return self.nativeAVFOutput;
}

- (AVPlayerItemHapDXTOutput*) getHAPOutput{
    return self.hapOutput;
}

- (CVOpenGLTextureCacheRef) getTextureCacheRef{
    return self.videoTextureCache;
}

- (CVOpenGLTextureRef) getTextureRef{
    return self.videoTextureRef;
}

- (BOOL) isLoaded{
    return _bLoaded;
}

- (void) renderCallback	{
    //NSLog(@"Displaylink!");
    [asyncLock lock];
    
    if(deallocCond != nil){
        [asyncLock unlock];
        _bFrameNeedsRender = NO;
        return;
    }
    
    if(_bFrameNeedsRender == YES){
        [asyncLock unlock];
        return;
    }
    
    if(self.hapOutput != nil && _bHAPEncoded) {
        CMTime frameTime = [self.hapOutput itemTimeForMachAbsoluteTime:mach_absolute_time()];
        HapDecoderFrame	*dxtFrame = [self.hapOutput allocFrameClosestToTime:frameTime];
        _currentFrame = CMTimeGetSeconds(frameTime) *  _frameRate;
        [dxtFrame retain];
        if(_dedcodedFrame != nil) [_dedcodedFrame release];
        _dedcodedFrame = dxtFrame;
        if(_dedcodedFrame != nil){
            _bFrameNeedsRender = YES;
            //parent->renderFrame();
        }else{
            _bFrameNeedsRender = NO;
        }
        [dxtFrame release];
    }
    
    if(self.nativeAVFOutput != nil && !_bHAPEncoded){
        CMTime frameTime = [self.nativeAVFOutput itemTimeForMachAbsoluteTime:mach_absolute_time()];
        
        if (self.nativeAVFOutput != nil && [self.nativeAVFOutput hasNewPixelBufferForItemTime:frameTime]){
            _currentFrame = CMTimeGetSeconds(frameTime) *  _frameRate;
            CMTime frameDisplayTime = kCMTimeZero;
            CVPixelBufferRef imageBuffer = [self.nativeAVFOutput copyPixelBufferForItemTime:frameTime itemTimeForDisplay:&frameDisplayTime];
            CVPixelBufferRetain(imageBuffer);
            if(_imageBuffer != nil) CVPixelBufferRelease(_imageBuffer);
            _imageBuffer = imageBuffer;
            if(_imageBuffer != nil){
                _bFrameNeedsRender = YES;
                //parent->renderFrame();
            }else{
                _bFrameNeedsRender = NO;
            }
            CVPixelBufferRelease(imageBuffer);
        }
    }
    [asyncLock unlock];
}

- (BOOL) isFrameReadyToRender{
    return _bFrameNeedsRender;
}

- (void) frameWasRendered{
     _bFrameNeedsRender = NO;
}

- (BOOL) isHAPEncoded{
    return _bHAPEncoded;
}

- (CVImageBufferRef) getAVFDecodedFrame{
    //_bFrameNeedsRender = NO;
    return _imageBuffer;
}

- (HapDecoderFrame*) getHAPDecodedFrame{
    //_bFrameNeedsRender = NO;
    return _dedcodedFrame;
}

- (NSOpenGLPixelFormat *) createGLPixelFormat	{
    GLuint				glDisplayMaskForAllScreens = 0;
    CGDirectDisplayID	dspys[10];
    CGDisplayCount		count = 0;
    if (CGGetActiveDisplayList(10,dspys,&count)==kCGErrorSuccess)	{
        for (int i=0; i<count; ++i)
            glDisplayMaskForAllScreens |= CGDisplayIDToOpenGLDisplayMask(dspys[i]);
    }
    
    NSOpenGLPixelFormatAttribute	attrs[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFAScreenMask,glDisplayMaskForAllScreens,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAllowOfflineRenderers,
        0};
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
}

CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                             const CVTimeStamp *inNow,
                             const CVTimeStamp *inOutputTime,
                             CVOptionFlags flagsIn,
                             CVOptionFlags *flagsOut,
                             void *displayLinkContext)
{
    NSAutoreleasePool		*pool =[[NSAutoreleasePool alloc] init];
    [(ofxHAPAVPlayerDelegate *)displayLinkContext renderCallback];
    [pool release];
    return kCVReturnSuccess;
}

@end