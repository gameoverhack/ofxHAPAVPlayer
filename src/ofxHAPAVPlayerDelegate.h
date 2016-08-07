//
//  ofxHAPAVPlayerDelegate.h
//  AVFoundering
//
//  Created by gameover on 8/06/16.
//
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <AVFoundation/AVFoundation.h>
#import <HapInAVFoundation/HapInAVFoundation.h>

typedef enum{
    LOOP_NONE=0x01,
    LOOP_PALINDROME=0x02,
    LOOP_NORMAL=0x03
} LoopType;

@interface ofxHAPAVPlayerDelegate : NSObject {
    
    CVDisplayLinkRef			displayLink;
    
    AVAsset                     * _asset;
    AVPlayer                    * _player;
	AVPlayerItem				* _playerItem;
    AVPlayerItemVideoOutput		* _nativeAVFOutput;
    AVPlayerItemHapDXTOutput	* _hapOutput;
    
    HapDecoderFrame             * _dedcodedFrame;
    CVImageBufferRef              _imageBuffer;
    
    NSLock* asyncLock;
    NSCondition* deallocCond;
    
    NSInteger _videoWidth;
    NSInteger _videoHeight;
    
    float _loadRate;
    float _loadPosition;
    float _loadFrame;
    
    float _rate;
    float _frameRate;
    
    int _currentFrame;
    int _totalFrames;
    
    CMTime _duration;
    
    BOOL _bLoaded;
    BOOL _bFrameNeedsRender;
    BOOL _bHAPEncoded;
    
    LoopType loopType;
    
    //CMTime _minFrameDuration;
    
}

@property (strong, nonatomic) AVAsset * asset;
@property (strong, nonatomic) AVPlayer * player;
@property (strong, nonatomic) AVPlayerItem * playerItem;
@property (strong, nonatomic) AVPlayerItemVideoOutput * nativeAVFOutput;
@property (strong, nonatomic) AVPlayerItemHapDXTOutput * hapOutput;

- (void) load:(NSString *)path;

- (void) play;
- (void) stop;
- (void) close;
- (void) setPaused:(BOOL)bPaused;
- (void) setSpeed:(float)speed;
- (void) setPosition:(float)position;
- (void) setFrame:(int)frame;
- (void) setLoopType:(LoopType)state;
- (LoopType) getLoopType;

- (NSInteger) getWidth;
- (NSInteger) getHeight;
- (float) getRate;
- (int) getCurrentFrame;
- (int) getTotalNumFrames;
- (float) getPosition;
- (float) getDuration;
- (BOOL) isLoaded;
- (BOOL) isMovieDone;

- (CVImageBufferRef) getAVFDecodedFrame;
- (HapDecoderFrame*) getHAPDecodedFrame;

- (BOOL) isFrameReadyToRender;
- (void) frameWasRendered;
- (BOOL) isHAPEncoded;
- (void) unloadVideo;

@end