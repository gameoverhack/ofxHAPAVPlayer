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

static void *ItemStatusContext = &ItemStatusContext;

@synthesize player = _player;
@synthesize asset = _asset;
@synthesize playerItem = _playerItem;
@synthesize hapOutput = _hapOutput;
@synthesize nativeAVFOutput = _nativeAVFOutput;

- (id) init	{
    
	self = [super init];
    
    asyncLock = [[NSLock alloc] init];
    
    self.player = [[AVPlayer alloc] init];
    
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

- (void)dealloc {
    
    [asyncLock lock];

    //NSLog(@"release cvdisplaylink");
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
    displayLink = nil;
    
    [asyncLock unlock];
    
    if (self.player != nil){
        [self unloadVideo];
    }
    
    [asyncLock lock];

    //NSLog(@"release dxt frame");
    [_dedcodedFrame release];
    _dedcodedFrame = nil;

    //NSLog(@"release image buffer ");
    CVPixelBufferRelease(_imageBuffer);
    _imageBuffer = nil;

    [asyncLock unlock];
    
    // release locks
    [asyncLock autorelease];
    
    if (deallocCond != nil) {
        [deallocCond release];
        deallocCond = nil;
    }
    
    [super dealloc];
    
}

- (void)unloadVideo
{
    // create a condition
    deallocCond = [[NSCondition alloc] init];
    [deallocCond lock];
    
    // unload current video
    [self close];
    
    // wait for close to finish
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @autoreleasepool {
            
            [asyncLock lock];
            
            _bFrameNeedsRender = NO;
            
            // release asset
            if (currentAsset != nil) {
                //NSLog(@"release asset");
                [currentAsset cancelLoading];
                [currentAsset autorelease];
                currentAsset = nil;
            }

            // release current player item
            if(currentItem != nil) {
                //NSLog(@"release playerItem");
                [currentItem cancelPendingSeeks];
                //[currentItem removeObserver:self forKeyPath:kStatusKey context:&ItemStatusContext];
                
                NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
                [notificationCenter removeObserver:self
                                              name:AVPlayerItemDidPlayToEndTimeNotification
                                            object:currentItem];
                
                if(currentHAPVideoOutput != nil){
                    //NSLog(@"release hap output");
                    // remove output
                    [currentItem removeOutput:currentHAPVideoOutput];
                    
                    // release videouOutput
                    if (currentHAPVideoOutput != nil) {
                        [currentHAPVideoOutput autorelease];
                        currentHAPVideoOutput = nil;
                    }
                    
                }
                
                if(currentAVFVideoOutput != nil){
                    //NSLog(@"release native output");
                    // remove output
                    [currentItem removeOutput:currentAVFVideoOutput];
                    
                    // release videouOutput
                    if (currentAVFVideoOutput != nil) {
                        [currentAVFVideoOutput autorelease];
                        currentAVFVideoOutput = nil;
                    }
                    
                }
                
                [currentItem removeObserver:self forKeyPath:@"status"];
                [currentItem autorelease];
                currentItem = nil;
                
            }

            // destroy current player
            if (currentPlayer != nil) {
                //NSLog(@"release player");
                //[currentPlayer removeObserver:self forKeyPath:kRateKey context:&PlayerRateContext];
                
//                if (currentTimeObserver != nil) {
//                    [currentPlayer removeTimeObserver:currentTimeObserver];
//                    [currentTimeObserver release];
//                    currentTimeObserver = nil;
//                }
                [currentPlayer cancelPendingPrerolls];
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
            
        }
    });
    
}

- (void) load:(NSString *)path{

    _bLoaded = NO;
    
    // we use these to check if a different value is set during the async load process
    _loadRate =_loadPosition = _loadFrame = INFINITY;

    if (self.asset != nil) {
        [self.asset cancelLoading];
    }
    
    // make asset
    NSDictionary *options = @{(id)AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    self.asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:options];
    
    // error check url and asset creation
    if(self.asset == nil) {
        NSLog(@"error loading asset: %@", [[NSURL fileURLWithPath:path] description]);
        return NO;
    }

    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    // dispatch the queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:kTracksKey] completionHandler:^{
            
            double startTime = getTickCount();
            
            NSError * error = nil;
            AVKeyValueStatus status = [self.asset statusOfValueForKey:kTracksKey error:&error];
            
            if(status != AVKeyValueStatusLoaded) {
                NSLog(@"error loading asset tracks: %@", [error localizedDescription]);
                _bLoaded = NO;
                return;
            }

            _duration = [self.asset duration];
            
            if(CMTimeCompare(_duration, kCMTimeZero) == 0) {
                NSLog(@"track loaded with zero duration.");
                _bLoaded = NO;
                return;
            }
            
            NSArray * videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
            if([videoTracks count] == 0) {
                NSLog(@"no video tracks found.");
                _bLoaded = NO;;
                return;
            }
            
            [asyncLock lock];
            
            if (self.playerItem != nil){
                [self.playerItem cancelPendingSeeks];
                
                //unregister as an observer for the "old" item's play-to-end notifications
                [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                name:AVPlayerItemDidPlayToEndTimeNotification
                                                              object:self.playerItem];
                
                [self.playerItem removeObserver:self forKeyPath:@"status"];
            }
            
            //	make a player item
            self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset]; // I think this leaks on ctor/dtor
            
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
            //_minFrameDuration = videoTrack.minFrameDuration;
            _rate = 0.0; // reset rate to not autoplay
            
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
                
                // epic leak chase comes down to this:
                if(_player != nil) {
                    //[self removeTimeObserverFromPlayer];
                    //[self.player removeObserver:self forKeyPath:kRateKey context:&PlayerRateContext];
                    [_player cancelPendingPrerolls];
                    self.player = nil;
                    [_player release];
                }
                
                _player = [[AVPlayer alloc] init];
                
                //register to receive notifications that the new player item has played to its end
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(itemDidPlayToEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:self.playerItem];

                //	tell the player to start playing the new player item
                [self.player performSelectorOnMainThread:@selector(replaceCurrentItemWithPlayerItem:) withObject:self.playerItem waitUntilDone:NO]; // change this to NO to make it really non-block!!????
            
                [self.playerItem addObserver:self
                                  forKeyPath:@"status"
                                     options:(NSKeyValueObservingOptions)0
                                     context:ItemStatusContext];
                
                [asyncLock unlock];
                
            }
            
        }];
    });

    dispatch_release(sema);
    return YES;
    
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context == ItemStatusContext) {
        AVPlayerItem* player_item = (AVPlayerItem*)object;
        AVPlayerItemStatus status = [player_item status];
        switch (status) {
            case AVPlayerItemStatusUnknown:
                
                break;
            case AVPlayerItemStatusReadyToPlay:
                [asyncLock lock];
                
                _bLoaded = YES;
                _bFrameNeedsRender = NO;
                
                [asyncLock unlock];
                
                if(_loadPosition != INFINITY){
                    [self setPosition:_loadPosition];
                }else{
                    if(_loadFrame != INFINITY){
                        [self setFrame:_loadFrame];
                    }else{
                        [self.player seekToTime:kCMTimeZero]; // load from frame 0
                    }
                }
                
                if(_loadRate != INFINITY){
                    [self setSpeed:_loadRate];
                }else{
                    [self.player setRate:_rate]; // load paused?
                }
//                [self.player prerollAtRate:1.0 completionHandler:^(BOOL finished){
//                    if (finished) {
//                        
//                        [asyncLock lock];
//                        
//                        _bLoaded = YES;
//                        _bFrameNeedsRender = NO;
//
//                        [asyncLock unlock];
//                        
//                        if(_loadPosition != INFINITY){
//                            [self setPosition:_loadPosition];
//                        }else{
//                            if(_loadFrame != INFINITY){
//                                [self setFrame:_loadFrame];
//                            }else{
//                                [self.player seekToTime:kCMTimeZero]; // load from frame 0
//                            }
//                        }
//
//                        if(_loadRate != INFINITY){
//                            [self setSpeed:_loadRate];
//                        }else{
//                            [self.player setRate:_rate]; // load paused?
//                        }
//                        
//                        
//                    }
//                }];
//                NSLog(@"PlayerItem status ready to play");
                break;
            case AVPlayerItemStatusFailed:
                _bLoaded = NO;
                NSLog(@"PlayerItem status failed");
                break;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) itemDidPlayToEnd:(NSNotification *)note {
    [self.player seekToTime:kCMTimeZero];
    [self.player setRate:_rate];
}

- (void) play{
    if(!_bLoaded){
        _loadRate = 1.0f;
    }else{
        [self.player setRate:_rate];
    }
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
    if(!_bLoaded){
        _loadRate = speed;
    }else{
        _rate = speed;
        [self.player setRate:_rate];
    }
}

- (void)setPosition:(float)position {
    
    if(!_bLoaded){
        _loadPosition = position;
    }else{
        CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(_duration) * position, NSEC_PER_SEC);
        time = CMTimeMaximum(time, kCMTimeZero);
        time = CMTimeMinimum(time, _duration);
        [self.player seekToTime:time
                toleranceBefore:kCMTimeZero
                 toleranceAfter:kCMTimeZero
              completionHandler:^(BOOL finished)
        {
//             int nFrame = CMTimeGetSeconds([self.player currentTime]) * _frameRate;
//             NSLog(@"setPosComp: %d", nFrame);
        }];
    }
    
}

- (void)setFrame:(int)frame {

    if(!_bLoaded){
        NSLog(@"load frame %i", frame);
        _loadFrame = frame;
    }else{
        NSLog(@"setframe %i", frame);
        float position = (float)frame / (float)_totalFrames;
        [self setPosition:position];
    }
    
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

- (float) getRate{
    if(!_bLoaded) return 0;
    return _rate;
}

- (int) getTotalNumFrames{
    if(!_bLoaded) return 0;
    return _totalFrames;
}

- (float) getPosition{
    if(!_bLoaded) return 0;
    return (float)_currentFrame / (float)_totalFrames;
}

- (float) getDuration{
    if(!_bLoaded) return 0;
    return CMTimeGetSeconds(_duration);
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

- (BOOL) isLoaded{
    return _bLoaded;
}

- (void) renderCallback	{
    
    //NSLog(@"Displaylink!");
    
    [asyncLock lock];
    
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