# ofxHAPAVPlayer

Basic skeleton of a 64bit openFrameworks AVFoundation video player supporting the HAP codec.

Based on: https://github.com/Vidvox/hap-in-avfoundation
Project originally initiated by Joshua Batty: https://github.com/JoshuaBatty/ofxHapInAVFoundation

ofxHAPAVPlayer can be added to your project by using the project generator.
Once the project is generated you will need to add the following entries to the *Runpath Search Paths* in your *Build Settings*:

> @executable_path/../Frameworks
> @loader_path/../Frameworks

Please note this is just the beginning of an addon at the moment - it only loads and plays any HAP codec encoded video. If the video is not HAP encoded it falls back onto the normal AVFoundation decoder/s.

Only tested in 10.11.5 but should work in 10.10.+