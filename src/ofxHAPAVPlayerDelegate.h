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
    AVAsset                     * _asset;
    AVPlayer                    * _player;
	AVPlayerItem				* _playerItem;
    AVPlayerItemVideoOutput		* nativeAVFOutput;
    AVPlayerItemHapDXTOutput	* hapOutput;
    
    CVOpenGLTextureCacheRef     _videoTextureCache;
    CVOpenGLTextureRef          _videoTextureRef;
    
    NSInteger videoWidth;
    NSInteger videoHeight;
    float rate;
    float frameRate;
    CMTime duration;
    BOOL bReady;
    BOOL bLoaded;
    
    id timeObserver;
}

@property (nonatomic, retain) AVAsset * asset;
@property (nonatomic, retain) AVPlayer * player;
@property (nonatomic, retain) AVPlayerItem * playerItem;

- (void) load:(NSString *)path;

- (void) play;
- (void) setPaused:(BOOL)bPaused;
- (void) setSpeed:(float)speed;
- (void)setPosition:(float)position;
- (void) setFrame:(int)frame;
- (void) stop;
- (void) close;

- (NSInteger) getWidth;
- (NSInteger) getHeight;

- (float) getFrameRate;
- (CMTime) getDuration;

- (AVPlayer*) getPlayer;
- (AVPlayerItemVideoOutput*) getAVFOutput;
- (AVPlayerItemHapDXTOutput*) getHAPOutput;
- (CVOpenGLTextureCacheRef) getTextureCacheRef;
- (CVOpenGLTextureRef) getTextureRef;

@end