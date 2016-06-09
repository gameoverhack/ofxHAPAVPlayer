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
    AVPlayer                    *player;
	AVPlayerItem				*playerItem;
    AVPlayerItemVideoOutput		*nativeAVFOutput;
    AVPlayerItemHapDXTOutput	*hapOutput;
    CVOpenGLTextureCacheRef     _videoTextureCache;
    CVOpenGLTextureRef          _videoTextureRef;
    
    NSInteger videoWidth;
    NSInteger videoHeight;
}



- (void) load:(NSString *)path;

- (NSInteger) getWidth;
- (NSInteger) getHeight;

- (AVPlayerItemVideoOutput*) getAVFOutput;
- (AVPlayerItemHapDXTOutput*) getHAPOutput;
- (CVOpenGLTextureCacheRef) getTextureCacheRef;
- (CVOpenGLTextureRef) getTextureRef;

@end