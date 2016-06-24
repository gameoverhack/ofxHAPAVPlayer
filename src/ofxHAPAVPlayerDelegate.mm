//
//  ofxHAPAVPlayerDelegate.cpp
//  AVFoundering
//
//  Created by gameover on 8/06/16.
//
//

#include "ofxHAPAVPlayerDelegate.h"
#include <mach/mach_time.h>

@implementation ofxHAPAVPlayerDelegate

static NSString * const kTracksKey = @"tracks";
static NSString * const kStatusKey = @"status";
static NSString * const kRateKey = @"rate";

static const void *ItemStatusContext = &ItemStatusContext;
static const void *PlayerRateContext = &ItemStatusContext;

@synthesize asset = _asset;
@synthesize player = _player;
@synthesize playerItem = _playerItem;



- (id) init	{
	self = [super init];
    self.player = [[AVPlayer alloc] init];
    [self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
    rate = 1.0;
	return self;
}

- (void) load:(NSString *)path{
    
    NSLog(@"%s %@",__func__,path);
    
	//	make url
	NSURL *url = (path==nil) ? nil : [NSURL fileURLWithPath:path];
    
    // make asset
    NSDictionary *options = @{(id)AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    AVAsset	*asset = (url==nil) ? nil : [AVURLAsset URLAssetWithURL:url options:options];
    
    // error check url and asset creation
    if(asset == nil) {
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
        [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:kTracksKey] completionHandler:^{
            
            NSError * error = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:kTracksKey error:&error];
            
            if(status != AVKeyValueStatusLoaded) {
                NSLog(@"error loading asset tracks: %@", [error localizedDescription]);
                // reset
                bReady = false;//_bReady;
                bLoaded = false;//_bLoaded;
                //bPlayStateBeforeLoad = _bPlayStateBeforeLoad;
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                return;
            }
            
            CMTime _duration = [asset duration];
            
            if(CMTimeCompare(_duration, kCMTimeZero) == 0) {
                NSLog(@"track loaded with zero duration.");
                // reset
                bReady = false;//_bReady;
                bLoaded = false;//_bLoaded;
                //bPlayStateBeforeLoad = _bPlayStateBeforeLoad;
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                return;
            }
            
            NSArray * videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if([videoTracks count] == 0) {
                NSLog(@"no video tracks found.");
                // reset
                bReady = false;//_bReady;
                bLoaded = false;//_bLoaded;
                //bPlayStateBeforeLoad = _bPlayStateBeforeLoad;
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                return;
            }
            
            //NSLock* asyncLock;
            //[asyncLock lock];
            
            // set asset
            self.asset = asset;
            duration = _duration;
            
            // create asset reader
            // do we need one here? Lukasz does this and seems to maybe have something to do with time?
            
            //	make a player item
            AVPlayerItem *playerItem = [[[AVPlayerItem alloc] initWithAsset:asset] autorelease];
            if (playerItem == nil)	{
                NSLog(@"\t\terr: couldn't make AVPlayerItem in %s",__func__);
                return;
            }
            
            self.playerItem = playerItem;
            
            // get info from track (assume just one video track at position 0 - is this wise?
            // otherwise use: for (AVAssetTrack *trackPtr in videoTracks) etc....
            AVAssetTrack * videoTrack = [videoTracks objectAtIndex:0];
            frameRate = videoTrack.nominalFrameRate;
            videoWidth = [videoTrack naturalSize].width;
            videoHeight = [videoTrack naturalSize].height;
            
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
                NSLog(@"codec sub-type is '%@'", [NSString stringWithCString:destChars encoding:NSASCIIStringEncoding]);
            }
            
            @synchronized (self) {
                
                switch (fourcc) {
                    case kHapCodecSubType:
                    case kHapAlphaCodecSubType:
                    case kHapYCoCgCodecSubType:
                    case kHapYCoCgACodecSubType:
                    case kHapAOnlyCodecSubType:
                    {
                        //	if there's a hap output, remove it from the "old" item
                        if (hapOutput != nil)	{
                            if (self.playerItem != nil)
                                [self.playerItem removeOutput:hapOutput];
                        }
                        //	else there's no hap output- create one
                        else	{
                            hapOutput = [[AVPlayerItemHapDXTOutput alloc] init];
                            [hapOutput setSuppressesPlayerRendering:YES];
                            //	if the user's displaying the the NSImage/CPU tab, we want this output to output as RGB
                            //if ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]]==1)
                            // gameover: you have to set this true if you want the pixels!!!
                            //[hapOutput setOutputAsRGB:YES];
                        }
                        
                        //	add the outputs to the new player item
                        [self.playerItem addOutput:hapOutput];
                        
                    }
                        break;
                    default:
                    {
                        //	if there's an output, remove it from the "old" item
                        if (nativeAVFOutput != nil)	{
                            if (self.playerItem != nil)
                                [self.playerItem removeOutput:nativeAVFOutput];
                        }else{
                            //	else there's no output- create one
                            NSDictionary *pba = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, [NSNumber numberWithBool:YES], kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey, nil];
                            //NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
                            nativeAVFOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pba];
                            [nativeAVFOutput setSuppressesPlayerRendering:YES];
                        }
                        
                        //	add the outputs to the new player item
                        [self.playerItem addOutput:nativeAVFOutput];
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
                [self.player performSelectorOnMainThread:@selector(replaceCurrentItemWithPlayerItem:) withObject:self.playerItem waitUntilDone:YES];
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
                bLoaded = true;
                
                if(bAsync == NO){
                    dispatch_semaphore_signal(sema);
                }
                
                //[asyncLock unlock];
                

                
                [self.player seekToTime:kCMTimeZero];
//                [self.player setRate:rate];
            }
            
        }];
    });
    
    CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                                     nullptr,
                                     CGLGetCurrentContext(),
                                     CGLGetPixelFormat(CGLGetCurrentContext()),
                                     nullptr,
                                     &_videoTextureCache);
    
    bReady = true;
    
}

- (void) itemDidPlayToEnd:(NSNotification *)note	{
    @synchronized (self){
        [self.player seekToTime:kCMTimeZero];
        [self.player setRate:rate];
    }
}

- (void) play{
    @synchronized (self){
        [self.player seekToTime:kCMTimeZero];
        [self.player setRate:rate];
    }
}

- (void) setPaused:(BOOL)b{
    //dispatch_sync(dispatch_get_main_queue(), ^{
        @synchronized (self){
            if(b){
                [self.player setRate:0.0f];
            }else{
                [self.player setRate:rate];
            }
        }
    //});
    
}

- (void) setSpeed:(float)s{
    @synchronized (self){
        rate = s;
        [self.player setRate:rate];
    }
}

- (void) stop{
    @synchronized (self){
        [self.player setRate:0.0f];
    }
}

- (void) close{
    
}

- (NSInteger) getWidth{
    return videoWidth;
}

- (NSInteger) getHeight{
    return videoHeight;
}

- (float) getFrameRate{
    return frameRate;
}

- (CMTime) getDuration{
    return duration;
}

- (AVPlayer*) getPlayer{
    return self.player;
}

- (AVPlayerItemVideoOutput*) getAVFOutput{
    return nativeAVFOutput;
}

- (AVPlayerItemHapDXTOutput*) getHAPOutput{
    return hapOutput;
}

- (CVOpenGLTextureCacheRef) getTextureCacheRef{
    return _videoTextureCache;
}

- (CVOpenGLTextureRef) getTextureRef{
    return _videoTextureRef;
}

@end