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
//#include "ofxHAPAVPlayerInterOp.h"


@interface ofxHAPAVPlayerDelegate : NSObject {
    CVDisplayLinkRef			displayLink;
    AVAsset                     * asset;
    AVPlayer                    * player;
	AVPlayerItem				* playerItem;
    AVPlayerItemVideoOutput		* nativeAVFOutput;
    AVPlayerItemHapDXTOutput	* hapOutput;
    HapDecoderFrame             * _dedcodedFrame;
    CVImageBufferRef              _imageBuffer;
    
    CVOpenGLTextureCacheRef     videoTextureCache;
    CVOpenGLTextureRef          videoTextureRef;
    
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
    BOOL _bReady;
    BOOL _bLoaded;
    BOOL _bFrameNeedsRender;
    BOOL _bHAPEncoded;
    BOOL _bLoading;
    id timeObserver;
    
    //ofxHAPAVPlayerInterOp * parent;
    
}

@property (strong, nonatomic) AVAsset * asset;
@property (strong, nonatomic) AVPlayer * player;
@property (strong, nonatomic) AVPlayerItem * playerItem;
@property (strong, nonatomic) AVPlayerItemVideoOutput * nativeAVFOutput;
@property (strong, nonatomic) AVPlayerItemHapDXTOutput * hapOutput;

//@property (nonatomic, assign, readonly, getter = getDecodedFrame) HapDecoderFrame * dedcodedFrame;

@property (nonatomic, assign) CVOpenGLTextureCacheRef     videoTextureCache;
@property (nonatomic, assign) CVOpenGLTextureRef          videoTextureRef;

//@property (nonatomic, assign, readonly, getter = isLoading) BOOL bLoaded;

//@property (nonatomic, assign, readonly) float rate;
//@property (nonatomic, assign) int currentFrame;
//@property (nonatomic, assign, readonly) int totalFrames;
//@property (nonatomic, assign, readonly) CMTime duration;

//- (void) setParent:(ofxHAPAVPlayerInterOp*)_parent;

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
- (void) frameWasRendered;
- (BOOL) isHAPEncoded;

@end