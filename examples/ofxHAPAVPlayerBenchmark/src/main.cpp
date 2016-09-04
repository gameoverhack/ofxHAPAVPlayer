#include "ofMain.h"
#include "ofApp.h"

//========================================================================
int main( ){
    ofGLWindowSettings settings;
    settings.setGLVersion(2, 1);  // Fixed pipeline
    //settings.setGLVersion(4, 1);  // Programmable pipeline
    settings.width = 1920;
    settings.height = 1080;
    ofCreateWindow(settings);
	//ofSetupOpenGL(1920,1080,OF_WINDOW);			// <-------- setup the GL context

	// this kicks off the running of my app
	// can be OF_WINDOW or OF_FULLSCREEN
	// pass in width and height too:
	ofRunApp(new ofApp());

}
