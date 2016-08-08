#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    
    dir.allowExt("mov");
    dir.listDir(ofToDataPath(""));
    currentFileIndex = 0;
    
    bLoadRandom = true;
    bTestDtor = false;
    
    vid.load(dir.getPath(currentFileIndex));
    vid.play();
    
    vidPtr = shared_ptr<ofxHAPAVPlayer>(new ofxHAPAVPlayer);
    vidPtr->load(dir.getPath(currentFileIndex));
    vidPtr->play();
    vidPtr->setPosition(0.5);
    vidPtr->setSpeed(3.0);
    vidPtr->setLoopState(OF_LOOP_PALINDROME);
}

//--------------------------------------------------------------
void ofApp::update(){
    vid.update();
    vidPtr->update();
    if(ofGetFrameNum() % 20 == 0 && bLoadRandom) keyReleased(' ');
}

//--------------------------------------------------------------
void ofApp::draw(){
    vid.draw(0,0);
    vidPtr->draw(640, 0);
    ostringstream os;
    os << "FPS: " << ofGetFrameRate() << endl;
    os << "Frame/Total: "   << vid.getCurrentFrame() << " / " << vid.getTotalNumFrames() << " "
                            //<< vid.getPosition() << " / " << vid.getDuration() << " "
                            << vidPtr->getCurrentFrame() << " / " << vidPtr->getTotalNumFrames() << " "
                            //<< vidPtr->getPosition() << " / " << vidPtr->getDuration() << " "
                            << endl;
    os << "Press ' ' (SpaceBar) to load movies at random" << endl;
    os << "Press 'r' to toggle auto load movies at random" << endl;
    os << "Press 'd' to toggle testing destructor/constructor loading" << endl;
    
    ofDrawBitmapString(os.str(), 20, ofGetHeight() - 80);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){
    switch (key) {
        case ' ':
        {
            currentFileIndex++;
            if(currentFileIndex == dir.size()) currentFileIndex = 0;
            vid.load(dir.getPath(currentFileIndex));
            vid.play();
            
            if(bTestDtor){
                vidPtr = shared_ptr<ofxHAPAVPlayer>(new ofxHAPAVPlayer);
                vidPtr->load(dir.getPath(currentFileIndex));
                vidPtr->play();
                vidPtr->setSpeed(3.0);
            }
            
            //cout << dir.getPath(currentFileIndex) << endl;
            
        }
            break;
        case 'r':
        {
            bLoadRandom = !bLoadRandom;
        }
            break;
        case 'd':
            bTestDtor = !bTestDtor;
            break;
        case 't':
            vid.setFrame(15);
            break;
        case 'p':
        {
            vid.play();
        }
            break;
        case 's':
        {
            vid.stop();
        }
            break;
        case 'b':
        {
            vid.setPaused(true);
        }
            break;
        case 'n':
        {
            vid.setPaused(false);
        }
            break;
        case '1':
        {
            vid.setSpeed(+1.0);
        }
            break;
        case '2':
        {
            vid.setSpeed(+2.0);
        }
            break;
        case '3':
        {
            vid.setSpeed(-1.0);
        }
            break;
        case '4':
        {
            vid.setSpeed(-2.0);
        }
            break;
        case OF_KEY_LEFT:
            if(vidPtr->getSpeed() != 0) vidPtr->setSpeed(0);
            vidPtr->previousFrame();
            break;
        case OF_KEY_RIGHT:
            if(vidPtr->getSpeed() != 0) vidPtr->setSpeed(0);
            vidPtr->nextFrame();
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
