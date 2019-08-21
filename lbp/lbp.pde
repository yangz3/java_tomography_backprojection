PImage myImgPad;
int degreeResolution = 10;
int displaySize = 300;

void setup(){
  myImgPad = loadImage("myImgPad.png");
  
  size(960, 300, P2D);
  
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
  
  PImage result = backProjection(sinogram);
  
  image(myImgPad, 0, 0, displaySize, displaySize);
  image(sinogramImg, displaySize+30, 0, displaySize, displaySize);
  image(result, displaySize*2+60, 0, displaySize, displaySize);
}

void draw(){
  
  
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

void showImg(PGraphics pg){
  PImage myImg = new PImage(pg.width, pg.height);
  myImg.loadPixels();
  for (int i = 0; i < pg.width*pg.height; i++) {
    myImg.pixels[i] = pg.pixels[i];
  }
   myImg.updatePixels();
  //image(myImg, 0, 0);
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

void show(float[][] r){ // my debug function to print out matrix
  for(int i = 0; i < r.length; i++){
    for(int j = 0; j < r[0].length; j++){
      print(r[i][j]);
      print(" ");
    }
    println();
  }
  println();
}
