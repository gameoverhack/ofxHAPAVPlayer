#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    
    ofSetFrameRate(1000);
    ofSetVerticalSync(false);
    ofBackground(0);
    
    vid.load("../../../ofxHAPAVPlayerExample/bin/data/SampleHap.mov");
    vid.play();
    vid.setSpeed(1.0);
    
    dir.allowExt("mov");
    dir.listDir("");

    maxPlayers = 220;
    videos.resize(maxPlayers);
    
    numLoaded = 0;
    
    bRandomize = true;
    
}

//--------------------------------------------------------------
void ofApp::update(){
    
    vid.update();
    
    for(int i = 0; i < maxPlayers; i++){
        videos[i].update();
    }
    
    if(!bRandomize) return;
    
    if(ofGetElapsedTimeMillis() - lastTime > 40){ // every 40 millis!
        
        if(numLoaded < maxPlayers){
            videos[numLoaded].load(dir.getPath((int)ofRandom(dir.size())));
            videos[numLoaded].play();
            videos[numLoaded].setSpeed(3.0);
            numLoaded++;
        }
        
        int i = (int)ofRandom(maxPlayers);
        videos[i].load(dir.getPath(ofRandom(dir.size())));
        videos[i].play();
        videos[i].setSpeed(3.0);
        i = (int)ofRandom(maxPlayers);
        videos[i].setFrame((int)ofRandom(videos[i].getTotalNumFrames()));
        lastTime = ofGetElapsedTimeMillis();
        
    }
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    
    ofEnableBlendMode(OF_BLENDMODE_SCREEN);
    vid.draw(0, ofGetHeight() - vid.getHeight());
    
    int xM = 0; int yM = 0;
    int tilesWide = 20;
    for(int i = 0; i < maxPlayers; i++){

        float width = (ofGetWidth() / tilesWide);
        float height = width * (videos[i].getHeight() / videos[i].getWidth());
        
        if(xM == tilesWide - 1) yM++;
        xM = i%tilesWide;
        
        videos[i].draw(xM * width, yM * height, width, height);
//        videos[i].draw(0, 0, 1920, 1080);
    }
    
    ofDisableBlendMode();
    ostringstream os;
    os << "FPS : " << ofGetFrameRate() << endl;
    os << "MOVs: " << maxPlayers << endl;
    os << "Press ' ' (SpaceBar) to toggle loading and seeking frames of movies at random" << endl;
    ofDrawBitmapString(os.str(), 20, ofGetHeight() - 50);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){
    
    
    
    switch (key) {
        case ' ':
        {
            bRandomize = !bRandomize;
        }
            break;
        case 'a':
        {
            for(int i = 0; i < maxPlayers; i++){
                
                videos[i].load(dir.getPath(ofRandom(dir.size())));
                videos[i].play();
                
            }
        }
            break;
        default:
            break;
    }
    
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
