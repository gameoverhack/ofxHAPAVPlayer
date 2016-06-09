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

const string ofxHAPAVPlayerVertexShader = "void main(void)\
{\
gl_Position = ftransform();\
gl_TexCoord[0] = gl_MultiTexCoord0;\
}";

const string ofxHAPAVPlayerFragmentShader = "uniform sampler2D cocgsy_src;\
const vec4 offsets = vec4(-0.50196078431373, -0.50196078431373, 0.0, 0.0);\
void main()\
{\
vec4 CoCgSY = texture2D(cocgsy_src, gl_TexCoord[0].xy);\
CoCgSY += offsets;\
float scale = ( CoCgSY.z * ( 255.0 / 8.0 ) ) + 1.0;\
float Co = CoCgSY.x / scale;\
float Cg = CoCgSY.y / scale;\
float Y = CoCgSY.w;\
vec4 rgba = vec4(Y + Co - Cg, Y + Cg, Y - Co - Cg, 1.0);\
gl_FragColor = rgba;\
}";

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
