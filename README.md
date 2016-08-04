# ofxHAPAVPlayer

A 64bit AVFoundation video player supporting the HAP codec in openFrameworks.

Please note this is a work in progress. Most of the basic functionality of an ofVideoPlayer has been implemented, eg., getWidth, getHeight, play, pause, setFrame, getFrame etc but there are still some gaps!

Emphasis has been put on making the player truly block-free on loading - it's aimed at installations and real-time AV software that needs fast, non-block loading and can handle a *lot* of video.

On my MacBook Pro (Early 2013, El Capitan 10.11.5) I can get approximately 200+ 100 x 100 videos or 15+ 1920 x 1080 videos playing smoothly whilst still loading a new video and seeking to a random frame every 40 milliseconds.

To encode your video with HAP download the codec from: https://github.com/vidvox/hap-qt-codec/releases/

This addon was originally initiated by Joshua Batty: https://github.com/JoshuaBatty/ and is based on examples from https://github.com/Vidvox/hap-in-avfoundation

Known issues:

* Memory leak when creating and destroying instances of ofxHAPAVPlayer - might be related to this oF issue https://github.com/openframeworks/openFrameworks/issues/4414. However memory is stable memory when re-using/reloading an instance.
* Seeking to an exact frame may fail depending on video/codec. This means that stepping through frame-by-frame on a paused video will most likely not work. But seeking to a frame on a playing video is fine - it just might not go to *exactly* the frame you request.

ofxHAPAVPlayer can be added to your project by using the project generator.
Once the project is generated you will need to add the following entries to the *Runpath Search Paths* in your *Build Settings*:

> @executable_path/../Frameworks
> @loader_path/../Frameworks

Only tested in 10.11.5 but should work in 10.10.+
