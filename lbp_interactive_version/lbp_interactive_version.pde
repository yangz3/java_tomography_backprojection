import ddf.minim.*;
import ddf.minim.analysis.*;

PImage myImgPad;
int degreeResolution = 2;
int displaySize = 300;

// for interactive obstacles
int xc = 100;
int yc = 100;
int sz = 50;
int xr = 200;
int yr = 200;

// for display reconstructions
PImage sinogramImg;
PImage filteredSinogramImg;
PImage result;
PImage filteredResult;

void setup(){
  size(960, 630, P2D);
  performBackProjection("save.png");
}

void draw(){
  background(0);
  fill(0, 255, 0);
  textAlign(LEFT, TOP);
  image(myImgPad, 0, 0, displaySize, displaySize);
  text("Original", 0, 0);
  
  image(sinogramImg, displaySize+30, 0, displaySize, displaySize);
  text("Projection measurements (sinogram)", displaySize+30, 0);
  image(filteredSinogramImg, displaySize+30, displaySize+30, displaySize, displaySize);
  text("Filtered projection measurements (sinogram)", displaySize+30, displaySize+30);
  
  image(result, displaySize*2+60,  0, displaySize, displaySize);
  text("Reconstructed image", displaySize*2+60, 0);
  image(filteredResult, displaySize*2+60,  displaySize+30, displaySize, displaySize);
  text("Filtered reconstructed image", displaySize*2+60, displaySize+30);
  
  noFill();
  stroke(255);
  rect(0,0, displaySize, displaySize);
  // check circle drag
  if(dist(xc,yc, mouseX, mouseY) < sz / 2) {
    cursor(HAND);
    if(mousePressed) {
      xc = mouseX;
      yc = mouseY;
      strokeWeight(5);
    } else {
      strokeWeight(2);
    }
    stroke(255);
  } else {
    noStroke();
  }
  fill(255,0,0);
  ellipse(xc, yc, sz, sz);
  
  // check rectangle drag
  if(dist(xr,yr, mouseX, mouseY) < sz / 2) {
    cursor(HAND);
    if(mousePressed) {
      xr = mouseX;
      yr = mouseY;
      strokeWeight(5);
    } else {
      strokeWeight(2);
    }
    stroke(255);
  } else {
    noStroke();
  }
  fill(255,0,0);
  rect(xr-sz/2, yr-sz/2, sz, sz);
  
  if(dist(xr,yr, mouseX, mouseY) > sz / 2 && dist(xc,yc, mouseX, mouseY) > sz / 2){
    cursor(ARROW);
  }
}

void mouseReleased(){
  PGraphics savePG = createGraphics(displaySize, displaySize);
  savePG.beginDraw();
  savePG.background(0);
  savePG.fill(255);
  savePG.noStroke();
  savePG.ellipse(xc, yc, sz, sz);
  savePG.rect(xr-sz/2, yr-sz/2, sz, sz);
  savePG.endDraw();
  // scale up from displaySize to 512
  PGraphics savePG2 = createGraphics(512, 512);
  savePG2.beginDraw();
  savePG2.image(savePG, 0, 0, 512, 512);
  savePG2.endDraw();
  savePG2.save("save.png");
  
  performBackProjection("save.png");
}

/* Initiate backprojection calculation based on an input image
*/

void performBackProjection(String fn){
  
  myImgPad = loadImage(fn);
  if(!isPowerOfTwo(myImgPad.width) || !isPowerOfTwo(myImgPad.height)){
    println("Input image has to have a size of power of 2!");
    exit();
  }
  
  // calculate sinogram (measurements)
  float[][] sinogram = getSinogram(myImgPad);
  
  // normalize sinogram for visualization
  float[][] sinogramNormalized = myNormalize(sinogram);
  
  sinogramImg = new PImage(sinogramNormalized.length, sinogramNormalized[0].length);
  sinogramImg.loadPixels();
  for(int i = 0; i< sinogramImg.width; i++){
    for(int j = 0; j < sinogramImg.height; j++){
      sinogramImg.pixels[j*sinogramImg.width + i] = color(sinogramNormalized[i][j]);
    }
  }
  sinogramImg.updatePixels();
  
  float[][] filteredSinogram = filterSinogram(sinogram);
  float[][] filteredSinogramNormalized = myNormalize(filteredSinogram);
  
  filteredSinogramImg = new PImage(filteredSinogramNormalized.length, filteredSinogramNormalized[0].length);
  filteredSinogramImg.loadPixels();
  for(int i = 0; i< filteredSinogramImg.width; i++){
    for(int j = 0; j < filteredSinogramImg.height; j++){
      filteredSinogramImg.pixels[j*filteredSinogramImg.width + i] = color(filteredSinogramNormalized[i][j]);
    }
  }
  filteredSinogramImg.updatePixels();
  
  result = backProjection(sinogram);
  filteredResult = backProjection(filteredSinogram);
}


/*
  Normalize a 2D array of floats to 0-255 for rendering
*/
float[][] myNormalize(float[][] input){
  float max = Float.MIN_VALUE;
  
  for(int i = 0; i < input.length; i++){
    for(int j = 0; j <input[0].length; j++){
      if(input[i][j] > max){ 
        max = input[i][j];
      }
    }
  }
  
  float[][] rst = new float[input.length][input[0].length];
  
  for(int i = 0; i < input.length; i++){
    for(int j = 0; j <input[0].length; j++){
      rst[i][j] = (input[i][j] / max) * 255;
    }
  }
  
  return rst;
}

/* Filter sinogram with FFT high pass filter
*/

float[][] filterSinogram(float[][] input){
  
  FFT fft = new FFT(input[0].length, 1);

  float[][] rst = new float[input.length][input[0].length];

  
  for(int i = 0; i < input.length; i++){
    fft.forward(input[i]);
    
    // This is a very simple high pass filter which attenuates frequencies below fft.specSize()/2 to demonstrate the idea
    // Better high pass filters will yield better results with higher resolutions and lower noise
    // For more information on backprojection filters, refer to: https://www.clear.rice.edu/elec431/projects96/DSP/filters.html
    
    for(int j = 0; j < fft.specSize()/2; j++){
      float factor = 0.03;
      fft.setBand(j, fft.getBand(j) * factor);
    }
    
    fft.inverse(rst[i]);
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

/* 
 A helper function for the forward process
 to rotate an image by an arbitrary angle
*/
PGraphics rotateImg(PImage input, float degreeAngle){
  PGraphics pg = createGraphics(input.width, input.height, P2D);
  pg.pushMatrix();
  pg.beginDraw();
  pg.background(0); // fill margins due to rotation with 0s
  pg.translate(pg.width/2, pg.height/2);
  pg.rotate(radians(degreeAngle)); // rotate image clockwise (equivalent to rotating scan ray counterclockwise)
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


/* An inverse process, use measurements to reconstruct an image
   Reconstruct original image by projecting the measurements back (backprojection)
   sinogram is a n x m array with n equals to number of angular steps and m the size of original image
*/
PImage backProjection (float[][] sinogram){ 
  int iSize = sinogram[0].length;
  int steps = sinogram.length;
  
  // Rotation matrix (https://en.wikipedia.org/wiki/Rotation_matrix) applied to X dimension only, 
  // Sort of like radon transform where we transform x-y coordinates to alpha-s coordinates
  // Rotated X gives us s which is the position on projection measurements (a 1d array) 
  // With this information we can backproject the projection measurements back to reconstruction matrices 
  // Reconstruction matrices add up to a reconstruction image
  
  float[][] reconMatrix = new float[iSize][iSize];
  
  // generate x-y coordinates centered around the image center
  int[][] x = new int[iSize][iSize];
  int[][] y = new int[iSize][iSize];
  
  for(int i = 0; i < iSize; i++){
    for(int j = 0; j < iSize; j++){
      x[i][j] = (int)(j - iSize/2);
      y[i][j] = (int)(i - iSize/2);
    }
  }
  
  // back projection
  for(int i = 0; i < steps; i++){
    float alpha = i*degreeResolution;
    float alphaRadian = radians(alpha);
    int[][] xRot = new int[iSize][iSize];
    float[] projectionMeasurement = sinogram[i];
     
    // rotate x-y coordinates to get s (so we only care about rotated x)
    for(int n = 0; n < iSize; n++){
      for(int m = 0; m < iSize; m++){
        xRot[n][m] = (int)(x[n][m] * cos(alphaRadian) - y[n][m]*sin(alphaRadian) + iSize/2); // rotate x coordinates counterclockwise
      }
    }
    
    for(int n = 0; n < iSize; n++){
      for(int m = 0; m < iSize; m++){
        
        int s = xRot[n][m];
        
        if(s<0 || s>iSize-1){
          continue;
        }
        
        reconMatrix[n][m] += projectionMeasurement[s];
      }
    }
  }
  
  float[][] reconMatrixNormal = myNormalize(reconMatrix);
  
  PImage reconImg = new PImage(reconMatrixNormal.length, reconMatrixNormal[0].length);
  reconImg.loadPixels();
  for(int i = 0; i< reconImg.width; i++){
    for(int j = 0; j < reconImg.height; j++){
      reconImg.pixels[j*reconImg.width + i] = color(reconMatrixNormal[j][i]);
    }
  }
  reconImg.updatePixels();
  
  return reconImg;
}

/* My debug function to print out matrix
*/
void show(float[][] r){ 
  for(int i = 0; i < r.length; i++){
    for(int j = 0; j < r[0].length; j++){
      print(r[i][j]);
      print(" ");
    }
    println();
  }
  println();
}

/* A helper function to check if image size is power of 2 
   Minim FFT can only work with input with a length of power of 2
   So the input image has to have a size (width and length) of power of 2
*/
boolean isPowerOfTwo(int n) {
    if(n<=0) 
        return false;
 
    while(n>2){
        int t = n>>1;
        int c = t<<1;
 
        if(n-c != 0)
            return false;
 
        n = n>>1;
    }
 
    return true;
}
