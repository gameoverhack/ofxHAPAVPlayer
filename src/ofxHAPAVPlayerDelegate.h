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
    
    CVOpenGLTextureCacheRef     _videoTextureCache;
    CVOpenGLTextureRef          _videoTextureRef;
    
    NSInteger _videoWidth;
    NSInteger _videoHeight;
    float _rate;
    float _frameRate;
    int _currentFrame;
    int _totalFrames;
    CMTime _duration;
    CMTime _minFrameDuration;
    BOOL _bReady;
    BOOL _bLoaded;
    BOOL _bFrameNeedsRender;
    BOOL _bHAPEncoded;
    id timeObserver;
}

@property (nonatomic, retain) AVAsset * asset;
@property (nonatomic, retain) AVPlayer * player;
@property (nonatomic, retain) AVPlayerItem * playerItem;
@property (nonatomic, retain) AVPlayerItemVideoOutput * nativeAVFOutput;
@property (nonatomic, retain) AVPlayerItemHapDXTOutput * hapOutput;

//@property (nonatomic, assign, readonly, getter = getDecodedFrame) HapDecoderFrame * dedcodedFrame;

@property (nonatomic, assign) CVOpenGLTextureCacheRef     videoTextureCache;
@property (nonatomic, assign) CVOpenGLTextureRef          videoTextureRef;

@property (nonatomic, assign, readonly, getter = isLoading) BOOL bLoaded;

@property (nonatomic, assign, readonly) float rate;
//@property (nonatomic, assign) int currentFrame;
@property (nonatomic, assign, readonly) int totalFrames;
@property (nonatomic, assign, readonly) CMTime duration;

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

//- (AVPlayer*) getPlayer;
//- (AVPlayerItemVideoOutput*) getAVFOutput;
//- (AVPlayerItemHapDXTOutput*) getHAPOutput;
- (CVOpenGLTextureCacheRef) getTextureCacheRef;
- (CVOpenGLTextureRef) getTextureRef;

- (CVImageBufferRef) getAVFDecodedFrame;
- (HapDecoderFrame*) getHAPDecodedFrame;

- (BOOL) isFrameReadyToRender;
- (BOOL) isHAPEncoded;

@end