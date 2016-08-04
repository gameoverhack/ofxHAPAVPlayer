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
    float _rate;
    float _frameRate;
    int _currentFrame;
    int _totalFrames;
    CMTime _duration;
    CMTime _minFrameDuration;
    BOOL _bLoaded;
    BOOL _bLoading;
    BOOL _bFrameNeedsRender;
    BOOL _bHAPEncoded;
    
}

@property (strong, nonatomic) AVAsset * asset;
@property (strong, nonatomic) AVPlayer * player;
@property (strong, nonatomic) AVPlayerItem * playerItem;
@property (strong, nonatomic) AVPlayerItemVideoOutput * nativeAVFOutput;
@property (strong, nonatomic) AVPlayerItemHapDXTOutput * hapOutput;

- (void) load:(NSString *)path;

- (void) play;
- (void) setPaused:(BOOL)bPaused;
- (void) setSpeed:(float)speed;
- (void) setPosition:(float)position;
- (void) setFrame:(int)frame;
- (void) stop;
- (void) close;

- (NSInteger) getWidth;
- (NSInteger) getHeight;

- (int) getCurrentFrame;
- (void) setCurrentFrame:(CMTime)frameTime;
- (float) getFrameRate;
- (int) getTotalNumFrames;
- (CMTime) getDuration;
- (BOOL) isLoaded;

- (CVImageBufferRef) getAVFDecodedFrame;
- (HapDecoderFrame*) getHAPDecodedFrame;

- (BOOL) isFrameReadyToRender;
- (void) frameWasRendered;
- (BOOL) isHAPEncoded;
- (void) unloadVideo;

@end