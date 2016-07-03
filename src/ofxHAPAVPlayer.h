//
//  ofxHAPAVPlayer.h
//  AVFoundering
//
//  Created by gameover on 8/06/16.
//
//

#ifndef __H_OFXHAPAVPLAYER
#define __H_OFXHAPAVPLAYER

#include "ofBaseTypes.h"
#include "ofPixels.h"
#include "ofTexture.h"
#include "ofThread.h"
#include "ofGraphics.h"
#include "ofShader.h"


#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <AVFoundation/AVFoundation.h>
#import <ofxHAPAVPlayerDelegate.h>
#include <mach/mach_time.h>
#endif

class ofxHAPAVPlayer{
    
public:
    
    ofxHAPAVPlayer();
    virtual ~ofxHAPAVPlayer();
    
    void load(string name);
    //void loadAsync(string name);
    void close();
    void update();
    
    void draw();
    void draw(float x, float y);
    void draw(const ofRectangle & rect);
    void draw(float x, float y, float w, float h);
    
    bool setPixelFormat(ofPixelFormat pixelFormat);
    ofPixelFormat getPixelFormat() const;
    
    void play();
    void stop();
    
    bool isFrameNew() const;
    const ofPixels & getPixels() const;
    ofPixels & getPixels();
    ofTexture * getTexturePtr();
    ofTexture &	getTexture();
    const ofTexture & getTexture() const;
    
    float getWidth() const;
    float getHeight() const;
    
    bool isPaused() const;
    bool isLoaded() const;
    bool isPlaying() const;
    
    float getPosition() const;
    float getVolume() const;
    float getSpeed() const;
    float getDuration() const;
    bool getIsMovieDone() const;
    
    void setPaused(bool bPause);
    void setPosition(float pct);
    void setVolume(float volume);
    void setLoopState(ofLoopType state);
    void setSpeed(float speed);
    void setFrame(int frame);
    
    int	getCurrentFrame() const;
    int	getTotalNumFrames() const;
    ofLoopType getLoopState() const;
    
    void firstFrame();
    void nextFrame();
    void previousFrame();
    
//    ofxHAPAVPlayer& operator=(ofxHAPAVPlayer other);
    
protected:
    
    bool bFrameNew;
    bool bNeedsShader;
    
    ofPixels pixels;
    ofPixelFormat pixelFormat;
    //ofTexture videoTexture;

    ofTexture videoTextures[2];
    GLenum internalFormats[2];
    
    ofShader shader;
    
#ifdef __OBJC__
    ofxHAPAVPlayerDelegate * delegate = nil;
#else
    void * delegate;
#endif
    
};

#endif
