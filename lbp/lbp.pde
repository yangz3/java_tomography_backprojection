PImage myImgPad;
int degreeResolution = 5;

void setup(){
  myImgPad = loadImage("myImgPad.png");
  
  size(725, 725, P2D);
  
  // calculate sinogram (measurements)
  float[][] sinogram = getSinogram(myImgPad);
  PImage result = reconstructImage(sinogram);
  
  //image(myImgPad, 0, 0);
}

void draw(){
  
  
}

/* 
 A forward process, use ground truth data to get measurements.
 Specifically, it rotates the input image with a step resolution defined by degreeResolution.
 Then it takes projection at each step, which is used to assemble the result sinogram.
*/

float[][] getSinogram(PImage input){ 
  if(input.width != input.height){
    println("input image to the getSinogram function has to be padded!");
    exit();
  }
  int iSize = input.width;
  
  for(int i = 0; i < iSize; i++){
    for (int j = 0; j < iSize; j++){
      color c = input.get(j, i);
      float pixelV = red(c); // gray scale image rgb channels are the same
    }
  }
  
  // use PGraphics to rotate an image
  PGraphics pg = rotateImg(input);
  image(pg, 0, 0);
  
  for(int i = 0; i < pg.width*pg.height; i++){
      color c = pg.pixels[i];
      float pixelV = red(c); // gray scale image rgb channels are the same
      if(pixelV != 0) println(pixelV);
  }
  
  float[][] rst = new float[1][1];
  
  return rst;
}

PGraphics rotateImg(PImage input){
  PGraphics pg = createGraphics(input.width, input.height, P2D);
  pg.pushMatrix();
  pg.beginDraw();
  pg.background(0); // fill margins due to rotation with 0s
  pg.translate(pg.width/2, pg.height/2);
  pg.rotate(radians(45));
  pg.imageMode(CENTER);
  pg.image(input, 0, 0);
  pg.loadPixels();
  pg.endDraw();
  pg.popMatrix();
  return pg;
}

void showImg(PGraphics pg){
  PImage myImg = new PImage(pg.width, pg.height);
  myImg.loadPixels();
  for (int i = 0; i < pg.width*pg.height; i++) {
    myImg.pixels[i] = pg.pixels[i];
  }
   myImg.updatePixels();
  //image(myImg, 0, 0);
}

// an inverse process, use measurements to reconstruct an image
PImage reconstructImage (float[][] sinogram){ 
  PImage rst = new PImage();
  return rst;
}
