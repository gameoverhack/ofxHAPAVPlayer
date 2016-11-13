//
//  ofxHAPAVPlayer.cpp
//  AVFoundering
//
//  Created by gameover on 8/06/16.
//
//

#include "ofxHAPAVPlayer.h"

#define FourCCLog(n,f) NSLog(@"%@, %c%c%c%c",n,(int)((f>>24)&0xFF),(int)((f>>16)&0xFF),(int)((f>>8)&0xFF),(int)((f>>0)&0xFF))

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

//--------------------------------------------------------------
ofxHAPAVPlayer::ofxHAPAVPlayer(){
    
}

//--------------------------------------------------------------
ofxHAPAVPlayer::~ofxHAPAVPlayer(){
    close();
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::load(string path){
    
    @autoreleasepool {
        if(delegate == nil){
            delegate = [[ofxHAPAVPlayerDelegate alloc] init];
            
            ofPixels p;
            p.allocate(1, 1, OF_IMAGE_COLOR_ALPHA);
            p[0] = p[1] = p[2] = p[3] = 0;
            
            for (int i=0; i<2; ++i)	{
                videoTextures[i].clear();
                videoTextures[i].allocate(1, 1, GL_RGBA);
                videoTextures[i].loadData(p.getData(), 1, 1, GL_RGBA); // get some black pixel in there
                internalFormats[i] = 0;
            }
            bNeedsShader = false;
            setLoopState(OF_LOOP_NORMAL);
        }
        
    }
    
    if (videoTextureCache == nil) {
        CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                                                  nullptr,
                                                  CGLGetCurrentContext(),
                                                  CGLGetPixelFormat(CGLGetCurrentContext()),
                                                  nullptr,
                                                  &videoTextureCache);
        
        if (err != noErr) {
            ofLogError() << "Error at CVOpenGLTextureCacheCreate " << err;
        }
    }
    
    bFrameNew = false;
    
    NSString *nsPath = [NSString stringWithUTF8String:ofToDataPath(path).c_str()];
    [delegate load:nsPath];
    
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::close(){
    
    if (delegate != nil) {
        
        // clear pixels
        pixels.clear();
        for (int i=0; i<2; ++i)	{
            videoTextures[i].clear();
            internalFormats[i] = 0;
        }
        
        // dispose videoplayer
        __block ofxHAPAVPlayerDelegate *currentDelegate = delegate;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            @autoreleasepool {
                [currentDelegate unloadVideo]; // synchronious call to unload video
                [currentDelegate autorelease]; // release
            }
        });
        
        delegate = nil;
        
        if(videoTextureCache != nullptr){
            CVOpenGLTextureCacheRelease(videoTextureCache);
            videoTextureCache = nullptr;
        }
        if(videoTextureRef != nullptr){
            CVOpenGLTextureRelease(videoTextureRef);
            videoTextureRef = nullptr;
        }
        
        
    }
    
    bFrameNew = false;
    
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::update(){
    
    if(delegate == nil) return;
    if(![delegate isLoaded]) return;
    
    bFrameNew = false;
    
    if([delegate isFrameReadyToRender]){
        
        if([delegate isHAPEncoded]){
            
            HapDecoderFrame	* dxtFrame = [delegate getHAPDecodedFrame];
            
            if(dxtFrame != nil){
                
                bFrameNew = true;
                
                NSSize tmpSize = [dxtFrame imgSize];
                int width = tmpSize.width;
                int height = tmpSize.height;
                
                tmpSize = [dxtFrame dxtImgSize];
                GLuint roundedWidth = tmpSize.width;
                GLuint roundedHeight = tmpSize.height;
                if (roundedWidth % 4 != 0 || roundedHeight % 4 != 0)	{
                    ofLogError() << "Width isn't a multiple of 4, bailing: " << __func__;
                    return;
                }
                
                int textureCount = [dxtFrame dxtPlaneCount];
                OSType *dxtPixelFormats = [dxtFrame dxtPixelFormats];
                GLenum newInternalFormat;
                size_t *dxtDataSizes = [dxtFrame dxtDataSizes];
                void **dxtBaseAddresses = [dxtFrame dxtDatas];
                
                bNeedsShader = false;
                
                for (int texIndex=0; texIndex<textureCount; ++texIndex)	{
                    unsigned int bitsPerPixel = 0;
                    switch (dxtPixelFormats[texIndex]) {
                        case kHapCVPixelFormat_RGB_DXT1:
                            newInternalFormat = HapTextureFormat_RGB_DXT1;
                            bitsPerPixel = 4;
                            break;
                        case kHapCVPixelFormat_RGBA_DXT5:
                            newInternalFormat = HapTextureFormat_RGBA_DXT5;
                            bitsPerPixel = 8;
                            break;
                        case kHapCVPixelFormat_YCoCg_DXT5:
                            newInternalFormat = HapTextureFormat_RGBA_DXT5;
                            bitsPerPixel = 8;
                            bNeedsShader = true;
                            break;
                        case kHapCVPixelFormat_CoCgXY:
                            if (texIndex==0)	{
                                newInternalFormat = HapTextureFormat_RGBA_DXT5;
                                bitsPerPixel = 8;
                            }
                            else	{
                                newInternalFormat = HapTextureFormat_A_RGTC1;
                                bitsPerPixel = 4;
                            }
                            bNeedsShader = true;
                            break;
                        case kHapCVPixelFormat_YCoCg_DXT5_A_RGTC1:
                            if (texIndex==0)	{
                                newInternalFormat = HapTextureFormat_RGBA_DXT5;
                                bitsPerPixel = 8;
                            }else{
                                newInternalFormat = HapTextureFormat_A_RGTC1;
                                bitsPerPixel = 4;
                            }
                            bNeedsShader = true;
                            break;
                        case kHapCVPixelFormat_A_RGTC1:
                            newInternalFormat = HapTextureFormat_A_RGTC1;
                            bitsPerPixel = 4;
                            break;
                        default:
                            // we don't support non-DXT pixel buffers
                            ofLogError() << "Unrecognized pixel format " << dxtPixelFormats[texIndex] << " at index " << texIndex << " in " << __func__;
                            FourCCLog(@"\t\tpixel format fourcc is",dxtPixelFormats[texIndex]);
                            
                            return;
                            break;
                    }
                    size_t			bytesPerRow = (roundedWidth * bitsPerPixel) / 8;
                    GLsizei			newDataLength = (int)(bytesPerRow * roundedHeight);
                    size_t			actualBufferSize = dxtDataSizes[texIndex];
                    
                    //	make sure the buffer's at least as big as necessary
                    if (newDataLength > actualBufferSize)	{
                        NSLog(@"\t\terr: new data length incorrect, %d vs %ld in %s",newDataLength,actualBufferSize,__func__);
                        
                        return;
                    }
                    
                    //	if we got this far we're good to go
                    
                    glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT);
                    glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
                    glEnable(GL_TEXTURE_2D);
                    
                    GLvoid		*baseAddress = dxtBaseAddresses[texIndex];
                    if(baseAddress == NULL) return;
                    
                    // Create a new texture/shader if our current one isn't adequate
                    
                    if(bNeedsShader && !shader.isLoaded()){
                        bool ok = shader.setupShaderFromSource(GL_VERTEX_SHADER, ofxHAPAVPlayerVertexShader);
                        if(ok) ok = shader.setupShaderFromSource(GL_FRAGMENT_SHADER, ofxHAPAVPlayerFragmentShader);
                        if(ok) ok = shader.linkProgram();
                    }
                    
                    if (videoTextures[texIndex].isAllocated() == false	||
                        //                roundedWidth > backingWidths[texIndex] ||
                        //                roundedHeight > backingHeights[texIndex] ||
                        newInternalFormat != internalFormats[texIndex]){
                        if(roundedWidth != width || roundedHeight != height){
                            ofLogVerbose() << "Video dimension is not multiple of 4 so texture is different size to width and height...";
                            // ... but we handle it automagically... ;)
                        }
                        ofLogVerbose() << "Allocating texture: " << texIndex << " at " << roundedWidth << " x " << roundedHeight;
                        
                        int textureFormatType;
                        int texturePixelType;
                        
                        ofTextureData texData;
                        texData.width = roundedWidth;
                        texData.height = roundedHeight;
                        texData.textureTarget = GL_TEXTURE_2D;
                        internalFormats[texIndex] = newInternalFormat;
                        
                        textureFormatType = GL_BGRA;
                        texturePixelType = GL_UNSIGNED_INT_8_8_8_8_REV;
                        ofSetPixelStoreiAlignment(GL_UNPACK_ALIGNMENT,roundedWidth,1,4);
                        texData.glInternalFormat = internalFormats[texIndex];
                        videoTextures[texIndex].allocate(texData, textureFormatType, texturePixelType);
                        videoTextures[texIndex].bind();
                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_SHARED_APPLE);
                        videoTextures[texIndex].unbind();
                        
                    }

                    ofTextureData &texData = videoTextures[texIndex].getTextureData();
                    glBindTexture(GL_TEXTURE_2D, texData.textureID);
                    
                    glTextureRangeAPPLE(GL_TEXTURE_2D, newDataLength, baseAddress);
                    glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
                    
                    glCompressedTexSubImage2D(GL_TEXTURE_2D,
                                              0,
                                              0,
                                              0,
                                              roundedWidth,
                                              roundedHeight,
                                              newInternalFormat,
                                              newDataLength,
                                              baseAddress);
                    
                    glPopClientAttrib();
                    glPopAttrib();
                    
                    //glFlush();
                    
                }
                
                [delegate frameWasRendered];
                
            }
            
        }else{ // is AVFoundation encoded
            
            if(videoTextureCache == nil) return;
            
            CVImageBufferRef imageBuffer = [delegate getAVFDecodedFrame];
            
            if(imageBuffer != nil){
                
                bNeedsShader = false;
                
                CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
                
                if([delegate getWidth] != videoTextures[0].getWidth()
                   || [delegate getHeight] != videoTextures[0].getHeight()
                   || internalFormats[0] != GL_RGBA){
                    internalFormats[0] = GL_RGBA;
                    videoTextures[0].allocate([delegate getWidth], [delegate getHeight], GL_RGBA);
                    videoTextures[0].getTextureData().tex_t = 1.0f;
                    videoTextures[0].getTextureData().tex_u = 1.0f;
                    videoTextures[0].setTextureMinMagFilter(GL_LINEAR, GL_LINEAR);
                    videoTextures[0].setTextureWrap(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
                }
                
                CVReturn err = CVOpenGLTextureCacheCreateTextureFromImage(nullptr,
                                                                          videoTextureCache,
                                                                          imageBuffer,
                                                                          nullptr,
                                                                          &videoTextureRef);
                
                unsigned int textureCacheID = CVOpenGLTextureGetName(videoTextureRef);
                
                videoTextures[0].setUseExternalTextureID(textureCacheID);
                if(ofIsGLProgrammableRenderer() == false) {
                    videoTextures[0].bind();
                    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                    videoTextures[0].unbind();
                }
                if(err) {
                    ofLogError("ofAVFoundationPlayer") << "initTextureCache(): error creating texture cache from image " << err << ".";
                }
                
                CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
                
                CVOpenGLTextureCacheFlush(videoTextureCache, 0);
                
                if(videoTextureRef) {
                    CVOpenGLTextureRelease(videoTextureRef);
                    videoTextureRef = nil;
                }
                
                //CVPixelBufferRelease(imageBuffer); // we do this in the CVDisplayLink renderCallback
                
            }
            
            [delegate frameWasRendered];
            
        }
        
    }
    
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::draw(){
    draw(0, 0, getWidth(), getHeight());
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::draw(float x, float y){
    draw(x, y, getWidth(), getHeight());
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::draw(const ofRectangle & rect){
    draw(rect.x, rect.y, rect.width, rect.height);
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::draw(float x, float y, float w, float h){
    if(delegate == nil) return;
    if(bNeedsShader && !shader.isLoaded()) return;
    ofPushMatrix();
    ofTranslate(x, y);
    //ofScale(w / getWidth(), h / getHeight());
    if(bNeedsShader) shader.begin();
    videoTextures[0].draw(0, 0, w, h); // for now just drawing texture [0] as I can't find an example with 2 textures!?!??
    if(bNeedsShader) shader.end();
    ofPopMatrix();
}

////--------------------------------------------------------------
//bool ofxHAPAVPlayer::setPixelFormat(ofPixelFormat pixelFormat){
//    
//}
//
////--------------------------------------------------------------
//ofPixelFormat ofxHAPAVPlayer::getPixelFormat() const{
//    
//}

//--------------------------------------------------------------
void ofxHAPAVPlayer::play(){
    if(delegate == nil) return;
    [delegate play];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::stop(){
    if(delegate == nil) return;
    [delegate stop];
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::isFrameNew() const{
    if(delegate == nil) return false;
    return bFrameNew;
}

////--------------------------------------------------------------
//void ofxHAPAVPlayer::setUsePixels(bool bUsePixels){
//    
//}
//
////--------------------------------------------------------------
//const ofxHAPAVPlayer::ofPixels & getPixels() const{
//    
//}
//
////--------------------------------------------------------------
//ofPixels & ofxHAPAVPlayer::getPixels(){
//    
//}

//--------------------------------------------------------------
ofTexture * ofxHAPAVPlayer::getTexturePtr(){
    return &videoTextures[0];
}

//--------------------------------------------------------------
ofTexture &	ofxHAPAVPlayer::getTexture(){
    return videoTextures[0];
}

//--------------------------------------------------------------
const ofTexture & ofxHAPAVPlayer::getTexture() const{
    return videoTextures[0];
}

//--------------------------------------------------------------
float ofxHAPAVPlayer::getWidth() const{
    if(delegate == nil) return 0;
    return [delegate getWidth];
}

//--------------------------------------------------------------
float ofxHAPAVPlayer::getHeight() const{
    if(delegate == nil) return 0;
    return [delegate getHeight];
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::isPaused() const{
    if(delegate == nil) return true;
    return [delegate getRate] == 0.0f;
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::isLoaded() const{
    if(delegate == nil) return false;
    return [delegate isLoaded];
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::isLoading() const{
    if(delegate == nil) return false;
    return [delegate isLoading];
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::isSeeking() const{
    if(delegate == nil) return false;
    return [delegate isSeeking];
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::isPlaying() const{
    return !isPaused();
}

//--------------------------------------------------------------
float ofxHAPAVPlayer::getPosition() const{
    if(delegate == nil) return 0;
    return [delegate getPosition];
}

////--------------------------------------------------------------
//float ofxHAPAVPlayer::getVolume() const{
//    
//}

//--------------------------------------------------------------
float ofxHAPAVPlayer::getSpeed() const{
    if(delegate == nil) return 0;
    return [delegate getRate];
}

//--------------------------------------------------------------
float ofxHAPAVPlayer::getDuration() const{
    if(delegate == nil) return 0;
    return [delegate getDuration];
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::getIsMovieDone() const{
    if(delegate == nil) return false;
    return [delegate isMovieDone];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setPaused(bool bPause){
    if(delegate == nil) return;
    [delegate setPaused:bPause];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setPosition(float pct){
    if(delegate == nil) return;
    [delegate setPosition:pct];
}

////--------------------------------------------------------------
//void ofxHAPAVPlayer::setVolume(float volume){
//    
//}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setLoopState(ofLoopType state){
    if(delegate == nil) return;
    [delegate setLoopType:(LoopType)state];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setSpeed(float speed){
    if(delegate == nil) return;
    [delegate setSpeed:speed];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setFrame(int frame){
    if(delegate == nil) return;
    [delegate setFrame:frame];
}

//--------------------------------------------------------------
int	ofxHAPAVPlayer::getCurrentFrame() const{
    if(delegate == nil) return 0;
    return [delegate getCurrentFrame];
}

//--------------------------------------------------------------
int	ofxHAPAVPlayer::getTotalNumFrames() const{
    if(delegate == nil) return 0;
    return [delegate getTotalNumFrames];
}

//--------------------------------------------------------------
ofLoopType ofxHAPAVPlayer::getLoopState() const{
    if(delegate == nil) return OF_LOOP_NORMAL;
    return (ofLoopType)[delegate getLoopType];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::firstFrame(){
    setFrame(0);
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::nextFrame(){
    if(delegate == nil) return;
    [delegate stepForward];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::previousFrame(){
    if(delegate == nil) return;
    [delegate stepBackward];
}

////--------------------------------------------------------------
//string ofxHAPAVPlayer::getMovieName(){
//    
//}
//
////--------------------------------------------------------------
//string ofxHAPAVPlayer::getMoviePath(){
//    
//}
