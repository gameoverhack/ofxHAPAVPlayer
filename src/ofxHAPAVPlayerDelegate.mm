//
//  ofxHAPAVPlayerDelegate.cpp
//  AVFoundering
//
//  Created by gameover on 8/06/16.
//
//

#include "ofxHAPAVPlayerDelegate.h"
#include <mach/mach_time.h>

@implementation ofxHAPAVPlayerDelegate

- (id) init	{
	self = [super init];
//	if (self!=nil)	{
//		displayLink = NULL;
//    }
    player = [[AVPlayer alloc] init];
    [player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
    [player play];
    
//    //	make the displaylink, which will drive rendering
//    CVReturn				err = kCVReturnSuccess;
//    CGOpenGLDisplayMask		totalDisplayMask = 0;
//    GLint					virtualScreen = 0;
//    GLint					displayMask = 0;
//    NSOpenGLPixelFormat		*format = [self createGLPixelFormat];
//    
//    for (virtualScreen=0; virtualScreen<[format numberOfVirtualScreens]; ++virtualScreen)	{
//        [format getValues:&displayMask forAttribute:NSOpenGLPFAScreenMask forVirtualScreen:virtualScreen];
//        totalDisplayMask |= displayMask;
//    }
//    err = CVDisplayLinkCreateWithOpenGLDisplayMask(totalDisplayMask, &displayLink);
//    if (err)	{
//        NSLog(@"\t\terr %d creating display link in %s",err,__func__);
//        displayLink = NULL;
//        return FALSE;
//    }
//    else	{
//        CVDisplayLinkSetOutputCallback(displayLink, displayLinkCallback, self);
//        CVDisplayLinkStart(displayLink);
//    }
	return self;
}

//- (void) renderCallback	{
//    
//    @synchronized (self){
//
//    }
//}

- (void) load:(NSString *)path{
    
    NSLog(@"%s %@",__func__,path);
	//	make an asset
	NSURL				*newURL = (path==nil) ? nil : [NSURL fileURLWithPath:path];
	AVAsset				*newAsset = (newURL==nil) ? nil : [AVAsset assetWithURL:newURL];
	//	make a player item
	AVPlayerItem		*newPlayerItem = (newAsset==nil) ? nil : [[[AVPlayerItem alloc] initWithAsset:newAsset] autorelease];
	if (newPlayerItem == nil)	{
		NSLog(@"\t\terr: couldn't make AVPlayerItem in %s",__func__);
		return;
	}
	//	update the status label
	NSArray				*vidTracks = [newAsset tracksWithMediaType:AVMediaTypeVideo];
	for (AVAssetTrack *trackPtr in vidTracks)	{
		NSArray					*trackFormatDescs = [trackPtr formatDescriptions];
		CMFormatDescriptionRef	desc = (trackFormatDescs==nil || [trackFormatDescs count]<1) ? nil : (CMFormatDescriptionRef)[trackFormatDescs objectAtIndex:0];
		if (desc==nil)
			NSLog(@"\t\terr: desc nil in %s",__func__);
		else	{
			OSType		fourcc = CMFormatDescriptionGetMediaSubType(desc);
			char		destChars[5];
			destChars[0] = (fourcc>>24) & 0xFF;
			destChars[1] = (fourcc>>16) & 0xFF;
			destChars[2] = (fourcc>>8) & 0xFF;
			destChars[3] = (fourcc) & 0xFF;
			destChars[4] = 0;
            videoWidth = [trackPtr naturalSize].width;
			videoHeight = [trackPtr naturalSize].height;
			NSLog(@"%s codec sub-type is '%@'",__func__, [NSString stringWithCString:destChars encoding:NSASCIIStringEncoding]);
			break;
		}
	}
	
	@synchronized (self)	{
		//	if there's an output, remove it from the "old" item
		if (nativeAVFOutput != nil)	{
			if (playerItem != nil)
				[playerItem removeOutput:nativeAVFOutput];
		}
		//	else there's no output- create one
		else	{
			NSDictionary				*pba = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                [NSNumber numberWithBool:YES], kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey,
                                                //NUMINT(dims.width), kCVPixelBufferWidthKey,
                                                //NUMINT(dims.height), kCVPixelBufferHeightKey,
                                                nil];
//            NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)};
			nativeAVFOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pba];
			[nativeAVFOutput setSuppressesPlayerRendering:YES];
		}
		
		//	if there's a hap output, remove it from the "old" item
		if (hapOutput != nil)	{
			if (playerItem != nil)
				[playerItem removeOutput:hapOutput];
		}
		//	else there's no hap output- create one
		else	{
			hapOutput = [[AVPlayerItemHapDXTOutput alloc] init];
			[hapOutput setSuppressesPlayerRendering:YES];
			//	if the user's displaying the the NSImage/CPU tab, we want this output to output as RGB
			//if ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]]==1)
            // gameover: you have to set this true if you want the pixels!!!
            [hapOutput setOutputAsRGB:YES];
		}
		
		//	unregister as an observer for the "old" item's play-to-end notifications
		NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
		if (playerItem != nil)
			[nc removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
		
//		if (hapTexture!=nil)	{
//			[hapTexture release];
//			hapTexture = nil;
//		}
		
		//	add the outputs to the new player item
		[newPlayerItem addOutput:nativeAVFOutput];
		[newPlayerItem addOutput:hapOutput];
		//	tell the player to start playing the new player item
		if ([NSThread isMainThread])
			[player replaceCurrentItemWithPlayerItem:newPlayerItem];
		else
			[player performSelectorOnMainThread:@selector(replaceCurrentItemWithPlayerItem:) withObject:newPlayerItem waitUntilDone:YES];
		//	register to receive notifications that the new player item has played to its end
		if (newPlayerItem != nil)
			[nc addObserver:self selector:@selector(itemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:newPlayerItem];
		
		//	release the "old" player item, retain a ptr to the "new" player item
		if (playerItem!=nil)
			[playerItem release];
		playerItem = (newPlayerItem==nil) ? nil : [newPlayerItem retain];
		
        CVReturn err;
        
        err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                                         nullptr,
                                         CGLGetCurrentContext(),
                                         CGLGetPixelFormat(CGLGetCurrentContext()),
                                         nullptr,
                                         &_videoTextureCache);
        
		[player seekToTime:kCMTimeZero];
        [player setRate:1.0];
	}
}

- (void) itemDidPlayToEnd:(NSNotification *)note	{
    @synchronized (self)	{
        [player seekToTime:kCMTimeZero];
        [player setRate:1.0];
    }
}

//- (NSOpenGLPixelFormat *) createGLPixelFormat	{
//	GLuint				glDisplayMaskForAllScreens = 0;
//	CGDirectDisplayID	dspys[10];
//	CGDisplayCount		count = 0;
//	if (CGGetActiveDisplayList(10,dspys,&count)==kCGErrorSuccess)	{
//		for (int i=0; i<count; ++i)
//			glDisplayMaskForAllScreens |= CGDisplayIDToOpenGLDisplayMask(dspys[i]);
//	}
//	
//	NSOpenGLPixelFormatAttribute	attrs[] = {
//		NSOpenGLPFAAccelerated,
//		NSOpenGLPFAScreenMask,glDisplayMaskForAllScreens,
//		NSOpenGLPFANoRecovery,
//		NSOpenGLPFAAllowOfflineRenderers,
//		0};
//	return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
//}

- (NSInteger) getWidth{
    return videoWidth;
}

- (NSInteger) getHeight{
    return videoHeight;
}

- (AVPlayerItemVideoOutput*) getAVFOutput{
    return nativeAVFOutput;
}

- (AVPlayerItemHapDXTOutput*) getHAPOutput{
    return hapOutput;
}

- (CVOpenGLTextureCacheRef) getTextureCacheRef{
    return _videoTextureCache;
}

- (CVOpenGLTextureRef) getTextureRef{
    return _videoTextureRef;
}

@end

//CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
//                             const CVTimeStamp *inNow,
//                             const CVTimeStamp *inOutputTime,
//                             CVOptionFlags flagsIn,
//                             CVOptionFlags *flagsOut,
//                             void *displayLinkContext)
//{
//	NSAutoreleasePool		*pool =[[NSAutoreleasePool alloc] init];
//	[(ofxHAPAVPlayerDelegate *)displayLinkContext renderCallback];
//	[pool release];
//	return kCVReturnSuccess;
//}
//void pixelBufferReleaseCallback(void *releaseRefCon, const void *baseAddress)	{
////	HapDecoderFrame		*decoderFrame = (HapDecoderFrame *)releaseRefCon;
////	[decoderFrame release];
//}