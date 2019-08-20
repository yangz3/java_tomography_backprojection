
PImage myImgPad;

void setup(){
  myImgPad = loadImage("myImgPad.png");
  image(myImgPad, 0, 0);
  size(725, 725);
}

void draw(){
  
  
}

// a forward process, use ground truth data to get measurements
float[][] getSinogram(PImage input){ 
  
}

// an inverse process, use measurements to reconstruct an image
PImage reconstructedImage (float[][] sinogram){ 
  
}
