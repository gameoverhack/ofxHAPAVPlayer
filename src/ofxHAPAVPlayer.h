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
    
    virtual void load(string path);
    
    void update();
    void draw();
    
protected:
    
    ofShader shader;
    
    bool bNeedsShader;
    GLenum internalFormats[2];
    ofTexture videoTextures[2];
    
#ifdef __OBJC__
    ofxHAPAVPlayerDelegate      *delegate;
#endif
    
    bool bIsSetup;
};

#endif
