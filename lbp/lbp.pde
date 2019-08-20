PImage myImgPad;
int degreeResolution = 1;

void setup(){
  myImgPad = loadImage("myImgPad.png");
  
  size(725, 725, P2D);
  
  // calculate sinogram (measurements)
  float[][] sinogram = getSinogram(myImgPad);
  
  // normalize sinogram for visualization
  float[][] sinogramNormalized = myNormalize(sinogram);
  PImage sinogramImg = new PImage(sinogramNormalized.length, sinogramNormalized[0].length);
  sinogramImg.loadPixels();
  for(int i = 0; i< sinogramImg.width; i++){
    for(int j = 0; j < sinogramImg.height; j++){
      sinogramImg.pixels[j*sinogramImg.width + i] = color(sinogramNormalized[i][j]);
    }
  }
  sinogramImg.updatePixels();
  
  PImage result = reconstructImage(sinogram);
  
  image(sinogramImg, 0, 0);
}

void draw(){
  
  
}

float[][] myNormalize(float[][] sinogram){
  float max = Float.MIN_VALUE;
  
  for(int i = 0; i < sinogram.length; i++){
    for(int j = 0; j <sinogram[0].length; j++){
      if(sinogram[i][j] > max){ 
        max = sinogram[i][j];
      }
    }
  }
  
  float[][] rst = new float[sinogram.length][sinogram[0].length];
  
  for(int i = 0; i < sinogram.length; i++){
    for(int j = 0; j <sinogram[0].length; j++){
      rst[i][j] = (sinogram[i][j] / max) * 255;
    }
  }
  
  return rst;
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
  int step = (int)(180 / degreeResolution);
  float[][] sinogram = new float[step][iSize];

  for(int i = 0; i < step; i++){
    // use PGraphics to rotate an image
    PGraphics pg = rotateImg(input, i*degreeResolution);

    // take projections - summing pixel values along columns of the input image
    float[] oneProjectionMeasurements = new float [iSize];
    
    for(int c = 0; c < iSize; c++){
      float sumV = 0;
      for(int r = 0; r < iSize; r++){
        sumV += red(pg.pixels[r*iSize + c]);
      }
      oneProjectionMeasurements[c] = sumV;
    }
    sinogram[i] = oneProjectionMeasurements;
  }
  return sinogram;
}

PGraphics rotateImg(PImage input, float degreeAngle){
  PGraphics pg = createGraphics(input.width, input.height, P2D);
  pg.pushMatrix();
  pg.beginDraw();
  pg.background(0); // fill margins due to rotation with 0s
  pg.translate(pg.width/2, pg.height/2);
  pg.rotate(radians(degreeAngle));
  pg.imageMode(CENTER);
  pg.image(input, 0, 0);
  pg.loadPixels();
  pg.endDraw();
  pg.popMatrix();
  
  if(pg.width != input.width){
    println("image dimension changed after rotation!");
    exit();
  }
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
