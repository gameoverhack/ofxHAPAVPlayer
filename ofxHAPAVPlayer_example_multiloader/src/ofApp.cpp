#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    
    ofSetFrameRate(1000);
    ofSetVerticalSync(true);
    ofBackground(0);
    
    vid.load("/Users/gameover/Code/openFrameworks/addons/ofxHAPAVPlayer/ofxHAPAVPlayer_example/bin/data/SampleHap.mov");
    vid.play();
    vid.setSpeed(1.0);
    
    dir.allowExt("mov");
    dir.listDir(ofToDataPath("/Users/gameover/Desktop/LAF")); //mediasmall/BLADIMIRSL

    maxPlayers = 16;
    videos.resize(maxPlayers);
    
    numLoaded = 0;
    
//    for(int i = 0; i < maxPlayers; i++){
//
//        videos[i].load(dir.getPath((int)ofRandom(dir.size())));
//        videos[i].play();
//        videos[i].setSpeed(3.0);
//        ofSleepMillis(5);
//        
//    }
    
    bRandomize = false;
    
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
        
//        if(ofGetFrameRate() > 50){
//            maxPlayers++;
//            videos.resize(maxPlayers);
//            videos[maxPlayers - 1].load(dir.getPath(ofRandom(dir.size())));
//            videos[maxPlayers - 1].play();
//            videos[maxPlayers - 1].setSpeed(3.0);
//        }else{
            int i = (int)ofRandom(maxPlayers);
            videos[i].load(dir.getPath(ofRandom(dir.size())));
            videos[i].play();
            videos[i].setSpeed(3.0);
            i = (int)ofRandom(maxPlayers);
            videos[i].setFrame((int)ofRandom(videos[i].getTotalNumFrames()));
            lastTime = ofGetElapsedTimeMillis();
//        }
        
    }
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    
    ofEnableBlendMode(OF_BLENDMODE_SCREEN);
    vid.draw(0, ofGetHeight() - vid.getHeight());
    
    int xM = 0; int yM = 0;
    int tilesWide = 4;
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
    
//    }
//    switch (key) {
//        case ' ':
//        {
//            currentFileIndex++;
//            if(currentFileIndex == dir.size()) currentFileIndex = 0;
//            vid.load(dir.getPath(currentFileIndex));
//            vid.play();
//        }
//            break;
//        case 'r':
//            vid.setFrame(0);
//            break;
//        case 't':
//            vid.setFrame(vid.getCurrentFrame() + 1);
//            break;
//        case 'p':
//        {
//            vid.play();
//        }
//            break;
//        case 's':
//        {
//            vid.stop();
//        }
//            break;
//        case 'b':
//        {
//            cout << "here" << endl;
//            vid.setPaused(true);
//        }
//            break;
//        case 'n':
//        {
//            vid.setPaused(false);
//        }
//            break;
//        case '1':
//        {
//            vid.setSpeed(+1.0);
//        }
//            break;
//        case '2':
//        {
//            vid.setSpeed(+2.0);
//        }
//            break;
//        case '3':
//        {
//            vid.setSpeed(-1.0);
//        }
//            break;
//        case '4':
//        {
//            vid.setSpeed(-2.0);
//        }
//            break;
//        default:
//            break;
//    }
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
