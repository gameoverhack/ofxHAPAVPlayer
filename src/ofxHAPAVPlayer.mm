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
    delegate = [[ofxHAPAVPlayerDelegate alloc] init];
    for (int i=0; i<2; ++i)	{
        videoTextures[i].clear();
//        backingHeights[i] = 0;
//        backingWidths[i] = 0;
        internalFormats[i] = 0;
    }
    bNeedsShader = false;
}

//--------------------------------------------------------------
ofxHAPAVPlayer::~ofxHAPAVPlayer(){
    close();
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::close(){
    if(delegate == nil) return;
    [delegate close];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::load(string path){
    bFrameNew = false;
    NSString *nsPath = [NSString stringWithCString:path.c_str() encoding:[NSString defaultCStringEncoding]];
    [delegate load:nsPath];
}

//--------------------------------------------------------------
int	ofxHAPAVPlayer::getCurrentFrame() const{
    if(delegate == nil) 0;
    return currentFrame;
}

//--------------------------------------------------------------
int	ofxHAPAVPlayer::getTotalNumFrames() const{
    if(delegate == nil) 0;
    return CMTimeGetSeconds([delegate getDuration]) * [delegate getFrameRate];
}

//--------------------------------------------------------------
bool ofxHAPAVPlayer::isFrameNew() const{
    if(delegate == nil) false;
    return bFrameNew;
}

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
void ofxHAPAVPlayer::setSpeed(float speed){
    if(delegate == nil) return;
    [delegate setSpeed:speed];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setPaused(bool bPause){
    if(delegate == nil) return;
    [delegate setPaused:bPause];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setFrame(int frame){
    if(delegate == nil) return;
    [delegate setFrame:frame];
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::setPosition(float pct){
    if(delegate == nil) return;
    [delegate setPosition:pct];
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
void ofxHAPAVPlayer::update(){

    if(delegate == nil) return;
    AVPlayerItemVideoOutput * nativeAVFOutput = [delegate getAVFOutput];
    
    CVOpenGLTextureCacheRef _videoTextureCache = [delegate getTextureCacheRef];
    CVOpenGLTextureRef _videoTextureRef = [delegate getTextureRef];
    
    AVPlayerItemHapDXTOutput* hapOutput = [delegate getHAPOutput];
    if(hapOutput == nil) return;
    
    CMTime frameTime;
    
    //[[delegate getPlayer] currentTime];
    frameTime = [hapOutput itemTimeForMachAbsoluteTime:mach_absolute_time()];
    //cout << [[delegate getPlayer] rate] << " : " << frameTime.value << " == " << [[delegate getPlayer] currentTime].value << endl;
    HapDecoderFrame	*dxtFrame = [hapOutput allocFrameClosestToTime:frameTime];
    
    bFrameNew = false;
    
    if (dxtFrame != nil) {
        
        bFrameNew = true;
        currentFrame = CMTimeGetSeconds(frameTime) * [delegate getFrameRate];
        
        BOOL valid = false;
        
        NSSize tmpSize = [dxtFrame imgSize];
        int width = tmpSize.width;
        int height = tmpSize.height;
        
        tmpSize = [dxtFrame dxtImgSize];
        GLuint roundedWidth = tmpSize.width;
        GLuint roundedHeight = tmpSize.height;
        if (roundedWidth % 4 != 0 || roundedHeight % 4 != 0)	{
            NSLog(@"\t\terr: width isn't a multiple of 4, bailing. %s",__func__);
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
                    NSLog(@"\t\terr: unrecognized pixel format (%X) at index %d in %s",dxtPixelFormats[texIndex],texIndex,__func__);
                    FourCCLog(@"\t\tpixel format fourcc is",dxtPixelFormats[texIndex]);
                    valid = NO;
                    return;
                    break;
            }
            size_t			bytesPerRow = (roundedWidth * bitsPerPixel) / 8;
            GLsizei			newDataLength = (int)(bytesPerRow * roundedHeight);
            size_t			actualBufferSize = dxtDataSizes[texIndex];
            
            //	make sure the buffer's at least as big as necessary
            if (newDataLength > actualBufferSize)	{
                NSLog(@"\t\terr: new data length incorrect, %d vs %ld in %s",newDataLength,actualBufferSize,__func__);
                valid = NO;
                return;
            }
            
            //	if we got this far we're good to go
            
            valid = YES;
            
            glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT);
            glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
            glEnable(GL_TEXTURE_2D);
            
            GLvoid		*baseAddress = dxtBaseAddresses[texIndex];
            
            // Create a new texture if our current one isn't adequate
            
            if(bNeedsShader && !shader.isLoaded()){
                bool ok = shader.setupShaderFromSource(GL_VERTEX_SHADER, ofxHAPAVPlayerVertexShader);
                if(ok) ok = shader.setupShaderFromSource(GL_FRAGMENT_SHADER, ofxHAPAVPlayerFragmentShader);
                if(ok) ok = shader.linkProgram();
            }
            
            if (videoTextures[texIndex].isAllocated() == false	||
//                roundedWidth > backingWidths[texIndex] ||
//                roundedHeight > backingHeights[texIndex] ||
                newInternalFormat != internalFormats[texIndex]){
                ofLogNotice() << "Allocating texture: " << texIndex << " at " << width << " x " << height;
                
                int textureFormatType;
                int texturePixelType;
                
                ofTextureData texData;
                texData.width = width;
                texData.height = height;
                texData.textureTarget = GL_TEXTURE_2D;
                internalFormats[texIndex] = newInternalFormat;
                
                textureFormatType = GL_BGRA;
                texturePixelType = GL_UNSIGNED_INT_8_8_8_8_REV;
                ofSetPixelStoreiAlignment(GL_UNPACK_ALIGNMENT,width,1,4);
                texData.glInternalFormat = internalFormats[texIndex];
                videoTextures[texIndex].allocate(texData, textureFormatType, texturePixelType);
                videoTextures[texIndex].bind();
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_SHARED_APPLE);
                videoTextures[texIndex].unbind();
                
            }
            else
            {
                ofTextureData &texData = videoTextures[texIndex].getTextureData();
                glBindTexture(GL_TEXTURE_2D, texData.textureID);
            }
            
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
            
            glFlush();
            
        }
        [dxtFrame release];
    }
    
    if(nativeAVFOutput == nil) return;
    
    //	try to get a CV pixel buffer (returns immediately if we're not using the native AVF output side of things)
    
    frameTime = [nativeAVFOutput itemTimeForMachAbsoluteTime:mach_absolute_time()];
    
    if (nativeAVFOutput != nil && [nativeAVFOutput hasNewPixelBufferForItemTime:frameTime]){
        
        bFrameNew = true;
        currentFrame = CMTimeGetSeconds(frameTime) * [delegate getFrameRate];
        
        CMTime frameDisplayTime = kCMTimeZero;
        CVImageBufferRef imageBuffer = [nativeAVFOutput copyPixelBufferForItemTime:frameTime itemTimeForDisplay:&frameDisplayTime];
        if(imageBuffer == nil) {
            return;
        }
        
        bNeedsShader = false;
        
        CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
        
        if([delegate getWidth] != videoTextures[0].getWidth()
           || [delegate getHeight] != videoTextures[0].getHeight()
           || internalFormats[0] != GL_RGBA){
            internalFormats[0] = GL_RGBA;
            videoTextures[0].allocate([delegate getWidth], [delegate getHeight], GL_RGBA);
        }
        
        ofTextureData & texData = videoTextures[0].getTextureData();
        texData.tex_t = 1.0f;
        texData.tex_u = 1.0f;
        
        CVReturn err;
        unsigned int textureCacheID;
        
        err = CVOpenGLTextureCacheCreateTextureFromImage(nullptr,
                                                         _videoTextureCache,
                                                         imageBuffer,
                                                         nullptr,
                                                         &_videoTextureRef);
        
        textureCacheID = CVOpenGLTextureGetName(_videoTextureRef);
        
        videoTextures[0].setUseExternalTextureID(textureCacheID);
        videoTextures[0].setTextureMinMagFilter(GL_LINEAR, GL_LINEAR);
        videoTextures[0].setTextureWrap(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
        if(ofIsGLProgrammableRenderer() == false) {
            videoTextures[0].bind();
            glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
            videoTextures[0].unbind();
        }
        
        if(err) {
            ofLogError("ofAVFoundationPlayer") << "initTextureCache(): error creating texture cache from image " << err << ".";
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
        
        CVOpenGLTextureCacheFlush(_videoTextureCache, 0);
        if(_videoTextureRef) {
            CVOpenGLTextureRelease(_videoTextureRef);
            _videoTextureRef = nullptr;
        }
        
        CVPixelBufferRelease(imageBuffer);
    }
}

//--------------------------------------------------------------
void ofxHAPAVPlayer::draw(){
    if(delegate == nil) return;
    if(bNeedsShader) shader.begin();
    videoTextures[0].draw(0, 0); // for now just drawing texture [0] as I can't find an example with 2 textures!?!??
    if(bNeedsShader) shader.end();
}