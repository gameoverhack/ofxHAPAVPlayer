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

@synthesize asset = _asset;
@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize duration = _duration;

@synthesize nativeAVFOutput = _nativeAVFOutput;
@synthesize hapOutput = _hapOutput;

@synthesize videoTextureCache = _videoTextureCache;
@synthesize videoTextureRef = _videoTextureRef;

//@synthesize useTexture = _useTexture;
//@synthesize useAlpha = _useAlpha;

@synthesize bLoaded = _bLoaded;


@synthesize rate = _rate;


- (id) init	{
	self = [super init];
    self.player = [[AVPlayer alloc] init];
    [self.player autorelease];
    [self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
    _rate = 1.0;
	return self;
}

//---------------------------------------------------------- cleanup / dispose.
- (void)dealloc
{
    if (_player != nil){
        [self close];
    }
    
//    [asyncLock lock];
//    
//    [asyncLock unlock];
//    
//    // release locks
//    [asyncLock autorelease];
//    
//    if (deallocCond != nil) {
//        [deallocCond release];
//        deallocCond = nil;
//    }
    
    [super dealloc];
}

- (void)close
{
    [self stop];
    
    if (_videoTextureCache != NULL) {
        CVOpenGLTextureCacheRelease(self.videoTextureCache);
        _videoTextureCache = NULL;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // release player item
    if (self.playerItem != nil) {
        
        [self.playerItem cancelPendingSeeks];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter removeObserver:self
                                      name:AVPlayerItemDidPlayToEndTimeNotification
                                    object:self.playerItem];
        
//        [self.playerItem autorelease];
        self.playerItem = nil;
    }

//    __block AVPlayer* currentPlayer = _player;
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        
//        @autoreleasepool {
//            if (currentPlayer != nil){
//                [currentPlayer replaceCurrentItemWithPlayerItem:nil];
//                [currentPlayer autorelease];
//                currentPlayer = nil;
//            }
//        }
//        
//    });
    
    if (self.player != nil){
//        [self.player replaceCurrentItemWithPlayerItem:nil];
//        [self.player autorelease];
        self.player = nil;
    }

    
    if (self.nativeAVFOutput != nil){
        //[self.nativeAVFOutput autorelease];
        self.nativeAVFOutput = nil;
    }
    
    if (self.hapOutput != nil){
        //[self.hapOutput autorelease];
        self.hapOutput = nil;
    }


    
}

- (void) load:(NSString *)path{
    
    _bLoaded = false;
    
    //NSLog(@"%s %@",__func__,path);
    
	//	make url
	NSURL *url = (path==nil) ? nil : [NSURL fileURLWithPath:path];
    
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
            
            CMTime _duration = [self.asset duration];
            
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
            
            //NSLock* asyncLock;
            //[asyncLock lock];
            
            // set asset
            //self.asset = asset;
//            duration = _duration;
            
            // create asset reader
            // do we need one here? Lukasz does this and seems to maybe have something to do with time?
            
            //	make a player item
            AVPlayerItem *playerItem = [[[AVPlayerItem alloc] initWithAsset:self.asset] autorelease];
            if (playerItem == nil)	{
                NSLog(@"\t\terr: couldn't make AVPlayerItem in %s",__func__);
                return;
            }
            
            self.playerItem = playerItem;
            
            // get info from track (assume just one video track at position 0 - is this wise?
            // otherwise use: for (AVAssetTrack *trackPtr in videoTracks) etc....
            AVAssetTrack * videoTrack = videoTracks.firstObject;
            _frameRate = videoTrack.nominalFrameRate;
            _videoWidth = [videoTrack naturalSize].width;
            _videoHeight = [videoTrack naturalSize].height;
            _totalFrames = floor((float)CMTimeGetSeconds(_duration) * _frameRate);
            _minFrameDuration = videoTrack.minFrameDuration;
            
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
            
            double elapsedTime = getTickCount() - startTime;
            //NSLog(@"Time A: %f", elapsedTime);
            @synchronized (self) {
                
                switch (fourcc) {
                    case kHapCodecSubType:
                    case kHapAlphaCodecSubType:
                    case kHapYCoCgCodecSubType:
                    case kHapYCoCgACodecSubType:
                    case kHapAOnlyCodecSubType:
                    {
                        //	if there's a hap output, remove it from the "old" item
                        if (_hapOutput != nil)	{
                            if (self.playerItem != nil) [self.playerItem removeOutput:_hapOutput];
                        }
                        //	else there's no hap output- create one
                        else	{
                            _hapOutput = [[AVPlayerItemHapDXTOutput alloc] init];
                            [_hapOutput setSuppressesPlayerRendering:YES];
                            //	if the user's displaying the the NSImage/CPU tab, we want this output to output as RGB
                            //if ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]]==1)
                            // gameover: you have to set this true if you want the pixels!!!
                            //[_hapOutput setOutputAsRGB:YES];
                        }
                        
                        //	add the outputs to the new player item
                        [self.playerItem addOutput:_hapOutput];
                        
                    }
                        break;
                    default:
                    {
                        //	if there's an output, remove it from the "old" item
                        if (_nativeAVFOutput != nil)	{
                            if (self.playerItem != nil) [self.playerItem removeOutput:_nativeAVFOutput];
                        }else{
                            //	else there's no output- create one
                            NSDictionary *pba = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, [NSNumber numberWithBool:YES], kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey, nil];
                            //NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
                            _nativeAVFOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pba];
                            [_nativeAVFOutput setSuppressesPlayerRendering:YES];
                        }
                        
                        //	add the outputs to the new player item
                        [self.playerItem addOutput:_nativeAVFOutput];
                    }
                        
                        break;
                }
                
                
                NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
                if (self.playerItem != nil){
                    //	unregister as an observer for the "old" item's play-to-end notifications
                    [nc removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
                    //	register to receive notifications that the new player item has played to its end
                    [nc addObserver:self selector:@selector(itemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
                }

                
//                if(_player != nil) {
////                    [self removeTimeObserverFromPlayer];
////                    [self.player removeObserver:self forKeyPath:kRateKey context:&PlayerRateContext];
//                    self.player = nil;
//                    [_player release];
//                }
            
            //	tell the player to start playing the new player item
            if ([NSThread isMainThread]){
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            }else{
                [self.player performSelectorOnMainThread:@selector(replaceCurrentItemWithPlayerItem:) withObject:self.playerItem waitUntilDone:NO]; // change this to NO to make it really non-block!!????
            }
            
                // create new player
//                _player = [[AVPlayer playerWithPlayerItem:self.playerItem] retain];
//                [self.player addObserver:self
//                              forKeyPath:kRateKey
//                                 options:NSKeyValueObservingOptionNew
//                                 context:&PlayerRateContext];
 //                double interval = 1.0 / (double)frameRate;
//                
//                __block ofxHAPAVPlayerDelegate* refToSelf = self;
//                timeObserver = [[_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
//                                                                      queue:dispatch_get_main_queue() usingBlock:
//                                 ^(CMTime time) {
//                                     //[refToSelf update];
//                                 }] retain];
//                [self addTimeObserverToPlayer];
//
//                _player.volume = volume;
                
//                self.player = _player; //???
            
                

                
                // loaded
                _bLoaded = true;
                
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                
                //[asyncLock unlock];
                

                
                [self.player seekToTime:kCMTimeZero];
//                [self.player setRate:rate];
                //NSLog(@"Finished the load");
                
                
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
    
}

- (void) itemDidPlayToEnd:(NSNotification *)note {
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
//    @synchronized (self){
        [self.player seekToTime:kCMTimeZero];
        [self.player setRate:_rate];
//    }
    //[pool drain];
}

- (void) play{
//    if(!_bLoaded) return;
//    @synchronized (self){
        //[self.player seekToTime:kCMTimeZero];
        [self.player setRate:_rate];
//    }
}

- (void) stop{
//    if(!_bLoaded) return;
//    @synchronized (self){
        [self.player setRate:0.0f];
//    }
}

- (void) setPaused:(BOOL)bPaused{
//    if(!_bLoaded) return;
//    @synchronized (self){
        if(bPaused){
            [self.player setRate:0.0f];
        }else{
            [self.player setRate:_rate];
        }
//    }
}

- (void) setSpeed:(float)speed{
//    if(!_bLoaded) return;
//    @synchronized (self){
        _rate = speed;
        [self.player setRate:_rate];
//    }
}

- (void)setPosition:(float)position {
//    if(!_bLoaded) return;
//    @synchronized (self){
    
//        float tRate = [self.player rate];
//        [self.player setRate:0.0f];
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
        
        
//    }
}

- (void)setFrame:(int)frame {
//    if(!_bLoaded) return;
//    @synchronized (self){
        //NSLog(@"setFrame: %d", frame);
        float position = (float)frame / (float)_totalFrames;
        [self setPosition:position];
//    }
}

- (int) getCurrentFrame{
//    if(!_bLoaded) return;
    return _currentFrame;
}
- (void) setCurrentFrame:(CMTime)frameTime{
//    if(!_bLoaded) return;
    _currentFrame = CMTimeGetSeconds(frameTime) *  _frameRate;
}

- (NSInteger) getWidth{
//    if(!_bLoaded) return;
    return _videoWidth;
}

- (NSInteger) getHeight{
//    if(!_bLoaded) return;
    return _videoHeight;
}

- (float) getFrameRate{
//    if(!_bLoaded) return;
    return _frameRate;
}

- (int) getTotalNumFrames{
//    if(!_bLoaded) return;
    return _totalFrames;
}

- (CMTime) getDuration{
//    if(!_bLoaded) return;
    return _duration;
}

- (AVPlayer*) getPlayer{
//    if(!_bLoaded) return;
    return self.player;
}

- (AVPlayerItemVideoOutput*) getAVFOutput{
//    if(!_bLoaded) return;
    return self.nativeAVFOutput;
}

- (AVPlayerItemHapDXTOutput*) getHAPOutput{
//    if(!_bLoaded) return;
    return self.hapOutput;
}

- (CVOpenGLTextureCacheRef) getTextureCacheRef{
//    if(!_bLoaded) return;
    return self.videoTextureCache;
}

- (CVOpenGLTextureRef) getTextureRef{
//    if(!_bLoaded) return;
    return self.videoTextureRef;
}

- (BOOL) isLoaded{
    return self.bLoaded;
}

@end