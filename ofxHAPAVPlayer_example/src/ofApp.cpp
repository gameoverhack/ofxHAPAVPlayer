#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    
    dir.allowExt("mov");
    dir.listDir(ofToDataPath(""));
    currentFileIndex = 0;
    vid.load(dir.getPath(currentFileIndex));
}

//--------------------------------------------------------------
void ofApp::update(){
    vid.update();
}

//--------------------------------------------------------------
void ofApp::draw(){
    vid.draw();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    currentFileIndex++;
    if(currentFileIndex == dir.size()) currentFileIndex = 0;
    vid.load(dir.getPath(currentFileIndex));
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

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
