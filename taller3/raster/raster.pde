import nub.primitives.*;
import nub.core.*;
import nub.processing.*;

// 1. Nub objects
Scene scene;
Node node;
Vector v1, v2, v3;
// timing
TimingTask spinningTask;
boolean yDirection;
// scaling is a power of 2
int n = 4;

// 2. Hints
boolean triangleHint = true;
boolean gridHint = true;
boolean debug = true;
boolean shadeHint = false;

// 3. Use FX2D, JAVA2D, P2D or P3D
String renderer = P2D;

// 4. Window dimension
int dim = 9;

void settings() {
  size(int(pow(2, dim)), int(pow(2, dim)), renderer);
}

void setup() {
  rectMode(CENTER);
  scene = new Scene(this);
  if (scene.is3D())
    scene.setType(Scene.Type.ORTHOGRAPHIC);
  scene.setRadius(width/2);
  scene.fit(1);

  // not really needed here but create a spinning task
  // just to illustrate some nub timing features. For
  // example, to see how 3D spinning from the horizon
  // (no bias from above nor from below) induces movement
  // on the node instance (the one used to represent
  // onscreen pixels): upwards or backwards (or to the left
  // vs to the right)?
  // Press ' ' to play it
  // Press 'y' to change the spinning axes defined in the
  // world system.
  spinningTask = new TimingTask(scene) {
    @Override
    public void execute() {
      scene.eye().orbit(scene.is2D() ? new Vector(0, 0, 1) :
        yDirection ? new Vector(0, 1, 0) : new Vector(1, 0, 0), PI / 100);
    }
  };
  node = new Node();
  node.setScaling(width/pow(2, n));

  // init the triangle that's gonna be rasterized
  randomizeTriangle();
}
void draw() {
  background(0);
  stroke(0, 255, 0);
  if (gridHint)
    scene.drawGrid(scene.radius(), (int)pow(2, n));
  if (triangleHint)
    drawTriangleHint();
  push();
  scene.applyTransformation(node);
  triangleRaster();
  pop();
}

void randomizeTriangle() {
  int low = -width/2;
  int high = width/2;
  v1 = new Vector(random(low, high), random(low, high));
  v2 = new Vector(random(low, high), random(low, high));
  v3 = new Vector(random(low, high), random(low, high));
}

void drawTriangleHint() {
  push();

  if(shadeHint){

    strokeWeight(2);
    noStroke();
  }else {
    strokeWeight(2);
    noFill();
  }
  beginShape(TRIANGLES);
  if(shadeHint)
    fill(255, 0, 0);
  else
    stroke(255, 0, 0);
  vertex(v1.x(), v1.y());
  if(shadeHint)
    fill(0, 255, 0);
  else
    stroke(0, 255, 0);
  vertex(v2.x(), v2.y());
  if(shadeHint)
    fill(0, 0, 255);
  else
    stroke(0, 0, 255);
  vertex(v3.x(), v3.y());
  endShape();

  strokeWeight(5);
  stroke(255, 0, 0);
  point(v1.x(), v1.y());
  stroke(0, 255, 0);
  point(v2.x(), v2.y());
  stroke(0, 0, 255);
  point(v3.x(), v3.y());

  pop();
}

void keyPressed() {
  if (key == 'g')
    gridHint = !gridHint;
  if (key == 't')
    triangleHint = !triangleHint;
  if (key == 's')
    shadeHint = !shadeHint;
  if (key == 'd')
    debug = !debug;
  if (key == '+') {
    n = n < 7 ? n+1 : 2;
    node.setScaling(width/pow( 2, n));
  }
  if (key == '-') {
    n = n >2 ? n-1 : 7;
    node.setScaling(width/pow( 2, n));
  }
  if (key == 'r')
    randomizeTriangle();
  if (key == ' ')
    if (spinningTask.isActive())
      spinningTask.stop();
    else
      spinningTask.run();
  if (key == 'y')
    yDirection = !yDirection;
}

//////////////
float edgeFuction(float v1x, float v1y, float v2x, float v2y, float px, float py) {
  return (((v2x-v1x)*(py-v1y))-((v2y-v1y)*(px-v1x)));
}

boolean inside_triangle(float v1x, float v1y, float v2x, float v2y, float v3x, float v3y, float px, float py) {
  boolean edge10, edge20, edge30,edge11, edge21, edge31;
  edge10 = ((((px-v1x)*(v2y-v1y))-((py-v1y)*(v2x-v1x)))>= 0) ?  true :  false;
  edge20 = ((((px-v2x)*(v3y-v2y))-((py-v2y)*(v3x-v2x)))>= 0) ?  true :  false;
  edge30 = ((((px-v3x)*(v1y-v3y))-((py-v3y)*(v1x-v3x)))>= 0) ?  true :  false;
  
  edge11 = ((((px-v1x)*(v3y-v1y))-((py-v1y)*(v3x-v1x)))>= 0) ?  true :  false;
  edge21 = ((((px-v3x)*(v2y-v3y))-((py-v3y)*(v2x-v3x)))>= 0) ?  true :  false;
  edge31 = ((((px-v2x)*(v1y-v2y))-((py-v2y)*(v1x-v2x)))>= 0) ?  true :  false;
  return (edge10 && edge20 && edge30)||(edge11 && edge21 && edge31);
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the node system which has a dimension of 2^n
void triangleRaster() {
  // node.location converts points from world to node
  // here we convert v1 to illustrate the idea
  float v1x = node.location(v1).x();
  float v1y = node.location(v1).y();
  float v2x = node.location(v2).x();
  float v2y = node.location(v2).y();
  float v3x = node.location(v3).x();
  float v3y = node.location(v3).y();

  int minx=round(min(v1x, v2x, v3x));
  int miny=round(min(v1y, v2y, v3y));
  int maxx=round(max(v1x, v2x, v3x));
  int maxy=round(max(v1y, v2y, v3y));

  if (debug) {
    pushStyle();
    noStroke();
    int paso;
    //se recorre el rectangulo que bordea el triangulo
    for (int x=minx; x<maxx; x++) {
      for (int y=miny; y<maxy; y++) {
        float f12, f23, f31, area, w1, w2, w3;
        float color1=0.0, color2=0.0, color3 =0.0;
          paso=1;
          if (inside_triangle(v1x, v1y, v2x, v2y, v3x, v3y, (x), (y))) {
              f12 = edgeFuction(v1x, v1y, v2x, v2y, (x), (y));
              f23 = edgeFuction(v2x, v2y, v3x, v3y, (x), (y));
              f31 = edgeFuction(v3x, v3y, v1x, v1y, (x), (y));
              area=abs(f12)+abs(f23)+abs(f31);
              
              w1=(f23)/area;
              w2=(f31)/area;
              w3=(f12)/area;
              color1+= abs(w1*255);
              color2+= abs(w2*255);
              color3+= abs(w3*255);
            }
          color1 /= Math.pow(paso, 2);
          color2 /= Math.pow(paso, 2);
          color3 /= Math.pow(paso, 2);
        if(shadeHint){
          if(inside_triangle(v1x, v1y, v3x, v3y, v2x, v2y, (x), (y))){
          fill(round(color1), round(color2), round(color3));
          rect(x, y, 1, 1);
          }
        }else{
          if(inside_triangle(v1x, v1y, v3x, v3y, v2x, v2y, (x), (y))){
          fill(255, 255, 255);
          rect(x, y, 1, 1);
          }
        }
      }
    } 
    popStyle();
  }
}
