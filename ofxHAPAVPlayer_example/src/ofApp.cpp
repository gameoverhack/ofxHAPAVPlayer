#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    
    dir.allowExt("mov");
    dir.listDir(ofToDataPath(""));
    currentFileIndex = 0;
//    vid.load(dir.getPath(currentFileIndex));
//    vid.play();
    vidPtr = shared_ptr<ofxHAPAVPlayer>(new ofxHAPAVPlayer);
    vidPtr->load(dir.getPath(currentFileIndex));
    vidPtr->play();
}

//--------------------------------------------------------------
void ofApp::update(){
//    vid.update();
    vidPtr->update();
    //if(ofGetFrameNum() % 40 == 0) keyReleased(' ');
}

//--------------------------------------------------------------
void ofApp::draw(){
//    vid.draw(0,0);
    vidPtr->draw(640, 0);
    ostringstream os;
    os << "FPS: " << ofGetFrameRate() << endl;
    os << "Frame/Duration: " << vid.getCurrentFrame() << " / " << vid.getTotalNumFrames() << endl;
    os << "Press ' ' (SpaceBar) to load movies at random" << endl;
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
            currentFileIndex++;
            if(currentFileIndex == dir.size()) currentFileIndex = 0;
//            vid.load(dir.getPath(currentFileIndex));
//            vid.play();
            vidPtr = shared_ptr<ofxHAPAVPlayer>(new ofxHAPAVPlayer);
            vidPtr->load(dir.getPath(currentFileIndex));
            vidPtr->play();
            cout << dir.getPath(currentFileIndex) << endl;
//            vid.setFrame(15);
        }
            break;
        case 'z':
        {
            vidPtr = shared_ptr<ofxHAPAVPlayer>(new ofxHAPAVPlayer);
            vidPtr->load(dir.getPath(currentFileIndex));
            vidPtr->play();
        }
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
            cout << "here" << endl;
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
