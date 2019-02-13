/*******************************************************************************
* Copyright 2018 ROBOTIS CO., LTD.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

/* Authors: Darby Lim, Hye-Jong KIM, Ryan Shim, Yong-Ho Na */


/**
 * this code is compatible with open_manipulator_planar.ino
**/

// Multiple Window
ChildApplet child;

// Control Interface
import controlP5.*;

// Init serial
import processing.serial.*;

// Shape variables
PShape base_shape;
PShape goal_link1_shape, goal_link2_shape, goal_link3_shape, 
       goal_link4_shape, goal_link5_shape, goal_link6_shape, 
       goal_tool_shape;
PShape ctrl_link1_shape, ctrl_link2_shape, ctrl_link3_shape, 
       ctrl_link4_shape, ctrl_link5_shape, ctrl_link6_shape, 
       ctrl_tool_shape;

// Model pose
float model_trans_x, model_trans_y, model_trans_z, model_scale_factor;

// World pose
float world_rot_x, world_rot_y;

// Serial variable
Serial opencr_port;

// Angle variable
float[] current_joint_angle = new float[7]; // active + passive joints
float[] receive_joint_angle = new float[7];
float   receive_tool_pos = 0.0;

float[] ctrl_joint_angle = new float[7];
float   ctrl_tool_pos = 0.0;

int tabFlag = 1;

float[] visual_target_pose_x = new float[50];
float[] visual_target_pose_y = new float[50];
float[] visual_target_pose_z = new float[50];

/*******************************************************************************
* Setting window size
*******************************************************************************/
void settings()
{
  size(900, 900, OPENGL);
}

/*******************************************************************************
* Setup
*******************************************************************************/
void setup()
{
  surface.setTitle("OpenManipulator Planar");
  child = new ChildApplet();

  initShape();
  initView();

  connectOpenCR(0); // Inside the brackets depends on a laptop enviroment.
}

/*******************************************************************************
* Draw (loop function)
*******************************************************************************/
void draw()
{
  setWindow();

  drawTitle();
  drawWorldFrame();

  drawManipulator();
}

/*******************************************************************************
* Connect OpenCR
*******************************************************************************/
void connectOpenCR(int port_num)
{
  printArray(Serial.list());

  String port_name = Serial.list()[port_num];
  opencr_port = new Serial(this, port_name, 57600);
  opencr_port.bufferUntil('\n');
}

/*******************************************************************************
* Serial Interrupt
*******************************************************************************/
void serialEvent(Serial opencr_port)
{
  String opencr_string = opencr_port.readStringUntil('\n');
  opencr_string = trim(opencr_string);

  String[] cmd = split(opencr_string, ',');

  if (cmd[0].equals("joint"))
  {
    for (int cmd_cnt = 1; cmd_cnt < cmd.length; cmd_cnt++)
    {
      receive_joint_angle[cmd_cnt-1] = float(cmd[cmd_cnt]);
    }
  }
  else
  {
    println("Error");
  }

  /*******************************************************************************
  * Set Active and Passive Joint Values
  *******************************************************************************/
  for(int i=0; i<7; i++)
  {
    current_joint_angle[i] = receive_joint_angle[i];
  }
}

/*******************************************************************************
* Init viewpoint and camera
*******************************************************************************/
void initView()
{
  float camera_y = height/2.0;
  float fov = 200/float(width) * PI/2;
  float camera_z = camera_y / tan(fov / 2.0);
  float aspect = float(width)/float(height);

  perspective(fov, aspect, camera_z/10.0, camera_z*10.0);

  // Eye position
  // Scene center
  // Upwards axis
  camera(width/2.0, height/2.0, height/2.0 * 4,
         width/2, height/2, 0,
         0, 1, 0);
}

/*******************************************************************************
* Get shape
*******************************************************************************/
void initShape()
{
  base_shape = loadShape("meshes/planar_base.obj");
  goal_link1_shape = loadShape("meshes/link_120.obj");
  goal_link2_shape = loadShape("meshes/link_120.obj");
  goal_link3_shape = loadShape("meshes/link_120.obj");
  goal_link4_shape = loadShape("meshes/link_98.obj");
  goal_link5_shape = loadShape("meshes/link_98.obj");
  goal_link6_shape = loadShape("meshes/link_98.obj");
  goal_tool_shape  = loadShape("meshes/laser_gripper.obj");

  ctrl_link1_shape = loadShape("meshes/link_120.obj");
  ctrl_link2_shape = loadShape("meshes/link_120.obj");
  ctrl_link3_shape = loadShape("meshes/link_120.obj");
  ctrl_link4_shape = loadShape("meshes/link_98.obj");
  ctrl_link5_shape = loadShape("meshes/link_98.obj");
  ctrl_link6_shape = loadShape("meshes/link_98.obj");
  ctrl_tool_shape  = loadShape("meshes/laser_gripper.obj");

  goal_link1_shape.setFill(color(255,255,255));
  goal_link2_shape.setFill(color(255,255,255));
  goal_link3_shape.setFill(color(255,255,255));
  goal_link4_shape.setFill(color(255,255,255));
  goal_link5_shape.setFill(color(255,255,255));
  goal_link6_shape.setFill(color(255,255,255));
  goal_tool_shape.setFill(color(255,255,255));

  ctrl_link1_shape.setFill(color(200));
  ctrl_link2_shape.setFill(color(200));
  ctrl_link3_shape.setFill(color(200));
  ctrl_link4_shape.setFill(color(200));
  ctrl_link5_shape.setFill(color(200));
  ctrl_link6_shape.setFill(color(200));
  ctrl_tool_shape.setFill(color(200));

  setJointAngle(0, 0, 0);
  gripperOn();
}

/*******************************************************************************
* Set window characteristic
*******************************************************************************/
void setWindow()
{
  lights();
  smooth();
  background(30);

  translate(width/2, height/2+100, 0);

  rotateX(radians(0));
  rotateZ(radians(-90));
}

/*******************************************************************************
* Draw sphere
*******************************************************************************/
void drawSphere(int x, int y, int z, int r, int g, int b, int size)
{
  translate(x, y, z);
  stroke(r,g,b);
  sphere(size);
}

void saveSpherePose()
{
  for (int i = 0; i < visual_target_pose_x.length - 1; i++)
  {
    visual_target_pose_x[i] = visual_target_pose_x[i + 1];
    visual_target_pose_y[i] = visual_target_pose_y[i + 1];
    visual_target_pose_z[i] = visual_target_pose_z[i + 1];
  }

  visual_target_pose_x[visual_target_pose_x.length - 1] = modelX(0,0,0);
  visual_target_pose_y[visual_target_pose_y.length - 1] = modelY(0,0,0);
  visual_target_pose_z[visual_target_pose_z.length - 1] = modelZ(0,0,0);
}

void drawSphereAfterEffect()
{
  for (int i = 0; i < visual_target_pose_x.length; i++)
  { 
    pushMatrix();
    rotateZ(radians(90));
    rotateX(radians(0));
    translate(-width/2, -height/2-200, 0);
    
    translate(visual_target_pose_x[i], visual_target_pose_y[i], visual_target_pose_z[i]);
    stroke(255,255,255);
    sphere(1.5);
    popMatrix();
  }
}

/*******************************************************************************
* Draw title
*******************************************************************************/
void drawTitle()
{
  pushMatrix();
  rotateX(radians(0));
  rotateZ(radians(90));
  textSize(45);
  fill(255,204,102);
  text("OpenManipulator Planar", -300,-350,0);
  textSize(20);
  fill(102,255,255);
  text("Move manipulator 'Q,A','W,S','E,D'", -300,-310,0);
  text("Initial view 'I'", -300,-280,0);
  popMatrix();
}

/*******************************************************************************
* Draw manipulator
*******************************************************************************/
void drawManipulator()
{
  scale(1.0 + model_scale_factor);

  // Base
  pushMatrix();
  translate(-model_trans_x, -model_trans_y, -model_trans_z);
  shape(base_shape);

  popMatrix();

  // First Set
  pushMatrix();
  translate(-model_trans_x, -model_trans_y, -model_trans_z);
  translate(-0.1705*1000, 0, 0);
  rotateZ(-current_joint_angle[0]+PI/4);
  shape(goal_link1_shape);
  drawLocalFrame();

  translate(0.120*1000, 0, 0);
  rotateZ(-current_joint_angle[3]-PI*7/12);
  shape(goal_link4_shape);

  translate(0.098*1000, 0, 0);
  rotateZ(-current_joint_angle[6]+PI/3);
  translate(0.0366*1000, 0, 0);
  shape(goal_tool_shape);
  
  popMatrix();
  
  // Second Set
  pushMatrix();
  translate(-model_trans_x, -model_trans_y, -model_trans_z);
  rotateZ(-PI*2/3);  
  translate(-0.1705*1000, 0, 0);

  rotateZ(-current_joint_angle[1]+PI/4);
  shape(goal_link2_shape);
  drawLocalFrame();
 
  translate(0.120*1000, 0, 0);
  rotateZ(-current_joint_angle[4]-PI*7/12);
  shape(goal_link5_shape);

  popMatrix();
    
  //// Third Set
  pushMatrix();
  translate(-model_trans_x, -model_trans_y, -model_trans_z);
  rotateZ(-PI*4/3);  
  translate(-0.1705*1000, 0, 0);

  rotateZ(-current_joint_angle[2]+PI/4);
  shape(goal_link3_shape);
  drawLocalFrame();

  translate(0.120*1000, 0, 0);
  rotateZ(-current_joint_angle[5]-PI*7/12);
  shape(goal_link6_shape);

  popMatrix();
 
  drawSphereAfterEffect();
  
  ////----------------------- Control
  if (tabFlag == 1)
  {
    // First Set
    pushMatrix();
    translate(-model_trans_x, -model_trans_y, -model_trans_z);
    translate(-0.1705*1000, 0, 0);
    
    rotateZ(-ctrl_joint_angle[0]+PI/4);
    shape(goal_link1_shape);
    drawLocalFrame();

    translate(0.120*1000, 0, 0);
    rotateZ(-ctrl_joint_angle[3]-PI*7/12);
    shape(goal_link4_shape);
    
    translate(0.098*1000, 0, 0);
    rotateZ(-ctrl_joint_angle[6]+PI/3);
    translate(0.0366*1000, 0, 0);
    shape(goal_tool_shape);
    drawLocalFrame();
    
    popMatrix();
    
    //// Second Set
    pushMatrix();
    translate(-model_trans_x, -model_trans_y, -model_trans_z);
    rotateZ(-PI*2/3);  
    translate(-0.1705*1000, 0, 0);

    rotateZ(-ctrl_joint_angle[1]+PI/4);
    shape(goal_link2_shape);
    drawLocalFrame();
  
    translate(0.120*1000, 0, 0);
    rotateZ(-ctrl_joint_angle[4]-PI*7/12);
    shape(goal_link5_shape);

    popMatrix();
      
    //// Third Set
    pushMatrix();
    translate(-model_trans_x, -model_trans_y, -model_trans_z);
    rotateZ(-PI*4/3);  
    translate(-0.1705*1000, 0, 0);

    rotateZ(-ctrl_joint_angle[2]+PI/4);
    shape(goal_link3_shape);
    drawLocalFrame();

    translate(0.120*1000, 0, 0);
    rotateZ(-ctrl_joint_angle[5]-PI*7/12);
    shape(goal_link6_shape);

    popMatrix();
  }
}

/*******************************************************************************
* Draw world frame
*******************************************************************************/
void drawWorldFrame()
{
  strokeWeight(10);
  stroke(255, 0, 0, 500);
  line(0, 0, 0, 100, 0, 0);

  strokeWeight(10);
  stroke(0, 255, 0, 100);
  line(0, 0, 0, 0, -100, 0);

  stroke(0, 0, 255, 100);
  strokeWeight(10);
  line(0, 0, 0, 0, 0, 100);
}

/*******************************************************************************
* Draw local frame
*******************************************************************************/
void drawLocalFrame()
{
  strokeWeight(10);
  stroke(255, 0, 0, 100);
  line(0, 0 ,0 , 60, 0, 0);

  strokeWeight(10);
  stroke(0, 255, 0, 100);
  line(0, 0, 0, 0, -60, 0);

  stroke(0, 0, 255, 100);
  strokeWeight(10);
  line(0, 0, 0, 0, 0, 60);
}

/*******************************************************************************
* Set joint angle
*******************************************************************************/
void setJointAngle(float angle1, float angle2, float angle3)
{
  ctrl_joint_angle[0] = angle1;
  ctrl_joint_angle[1] = angle2;
  ctrl_joint_angle[2] = angle3;
}

/*******************************************************************************
* Gripper on
*******************************************************************************/
void gripperOn()
{
  ctrl_tool_pos = radians(0.0);
}

/*******************************************************************************
* Gripper off
*******************************************************************************/
void gripperOff()
{
  ctrl_tool_pos = radians(-1.0);
}

/*******************************************************************************
* Mouse drag event
*******************************************************************************/
void mouseDragged()
{
  world_rot_x -= (mouseX - pmouseX) * 2.0;
  world_rot_y -= (mouseY - pmouseY) * 2.0;

  // Eye position
  // Scene center
  // Upwards axis
  camera(width/2.0 + world_rot_x, height/2.0 + world_rot_y, height/2.0 * 4,
         width/2, height/2, 0,
         0, 1, 0);
}

/*******************************************************************************
* Mouse wheel event
*******************************************************************************/
void mouseWheel(MouseEvent event) {
  float e = event.getCount() * 0.01;
  model_scale_factor += e;
}

/*******************************************************************************
* Key press event
*******************************************************************************/
void keyPressed()
{
  if      (key == 'q') model_trans_x      -= 0.0050 * 1000;
  else if (key == 'a') model_trans_x      += 0.0050 * 1000;
  else if (key == 'w') model_trans_y      += 0.0050 * 1000;
  else if (key == 's') model_trans_y      -= 0.0050 * 1000;
  else if (key == 'e') model_trans_z      -= 0.0050 * 1000;
  else if (key == 'd') model_trans_z      += 0.0050 * 1000;
  else if (key == 'i') 
  {
    model_trans_x = model_trans_y = model_trans_z = model_scale_factor = world_rot_x = world_rot_y = 0.0;
    camera(width/2.0, height/2.0, height/2.0 * 4,
           width/2, height/2, 0,
           0, 1, 0);
  }
}

/*******************************************************************************
* Controller Window
*******************************************************************************/
class ChildApplet extends PApplet
{
  ControlP5 cp5;

  Textlabel headLabel;
  Knob joint1, joint2, joint3, tool;
  Slider2D slider2d;

  float[] set_joint_angle = new float[3];
  float set_tool_pos;

  boolean onoff_flag = false;

  public ChildApplet()
  {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  public void settings()
  {
    size(400, 600);
    smooth();
  }
  public void setup()
  {
    surface.setTitle("Control Interface");
    cp5 = new ControlP5(this);

/*******************************************************************************
* Init Tab
*******************************************************************************/
    cp5.addTab("Task Space Control")
       .setColorBackground(color(188, 188, 90))
       .setColorLabel(color(255))
       .setColorActive(color(0,128,0))
       ;

    cp5.addTab("Motion")
       .setColorBackground(color(0, 160, 100))
       .setColorLabel(color(255))
       .setColorActive(color(0,0,255))
       ;

    cp5.getTab("default")
       .activateEvent(true)
       .setLabel("Joint Space Control")
       .setId(1)
       ;

    cp5.getTab("Task Space Control")
       .activateEvent(true)
       .setId(2)
       ;

    cp5.getTab("Motion")
       .activateEvent(true)
       .setId(3)
       ;

/*******************************************************************************
* Init Joint Space Controller
*******************************************************************************/
    headLabel = cp5.addTextlabel("Label")
                   .setText("Controller for OpenManipulator Planar")
                   .setPosition(4,17)
                   .setColorValue(0xffffff00)
                   .setFont(createFont("arial",20))
                   ;

    cp5.addToggle("Controller_OnOff")
       .setCaptionLabel("      Controller Off             Controller On")
       .setPosition(0,50)
       .setSize(400,40)
       .setMode(Toggle.SWITCH)
       .setFont(createFont("arial",15))
       .setColorActive(color(196, 196, 196))
       .setColorBackground(color(255, 255, 153))
       ;

    cp5.addButton("Origin")
       .setValue(0)
       .setPosition(0,350)
       .setSize(80,40)
       .setFont(createFont("arial",13))
       .setColorForeground(color(150,150,0))
       .setColorBackground(color(100, 160, 0))
       ;

    cp5.addButton("Basic")
       .setValue(0)
       .setPosition(320,350)
       .setSize(80,40)
       .setFont(createFont("arial",13))
       .setColorForeground(color(150,150,0))
       .setColorBackground(color(100, 160, 0))
       ;

/*******************************************************************************
* Init Task Space Controller
*******************************************************************************/
    slider2d = cp5.addSlider2D("Drawing")
                  .setPosition(70,240)
                  .setSize(260,150)
                  .setMinMax(-200,-250,200,250)
                  .setValue(0,0)
                  ;

/*******************************************************************************
* Init Task Space Controller
*******************************************************************************/
    cp5.addButton("Motion_Start")
       .setCaptionLabel("Motion Start")
       .setValue(0)
       .setPosition(0,200)
       .setSize(400,100)
       .setFont(createFont("arial",15))
       ;

    cp5.addButton("Motion_Stop")
       .setCaptionLabel("Motion Stop")
       .setValue(0)
       .setPosition(0,400)
       .setSize(400,100)
       .setFont(createFont("arial",15))
       ;

/*******************************************************************************
* Set Tap UI
*******************************************************************************/
    cp5.getController("Label").moveTo("global");
    cp5.getController("Controller_OnOff").moveTo("global");

    cp5.getController("Drawing").moveTo("Task Space Control");

    cp5.getController("Motion_Start").moveTo("Motion");
    cp5.getController("Motion_Stop").moveTo("Motion");
  }

  public void draw()
  {
    background(0);
  }

  void controlEvent(ControlEvent theControlEvent) {
    if (theControlEvent.isTab()) {
      println("got an event from tab : "+theControlEvent.getTab().getName()+" with id "+theControlEvent.getTab().getId());
      tabFlag = theControlEvent.getTab().getId();
    }
  }

/*******************************************************************************
* Init Function of Joint Space Controller
*******************************************************************************/
  void Controller_OnOff(boolean flag)
  {
    onoff_flag = flag;
    if (onoff_flag)
    {
      joint1.setValue(ctrl_joint_angle[0]);
      joint2.setValue(ctrl_joint_angle[1]);
      joint3.setValue(ctrl_joint_angle[2]);

      opencr_port.write("actuator"   + ',' +
                        "on" + '\n');
      println("OpenManipulator Planar Ready!!!");
    }
    else
    {
      opencr_port.write("actuator"  + ',' +
                        "off"  + '\n');
      println("OpenManipulator Planar End...");
    }
  }

  public void Origin(int theValue)
  {
    if (onoff_flag)
    {
      ctrl_joint_angle[0] = 0.0;
      ctrl_joint_angle[1] = 0.0;
      ctrl_joint_angle[2] = 0.0;

      joint1.setValue(ctrl_joint_angle[0]);
      joint2.setValue(ctrl_joint_angle[1]);
      joint3.setValue(ctrl_joint_angle[2]);

      opencr_port.write("joint"        + ',' +
                       ctrl_joint_angle[0] + ',' +
                       ctrl_joint_angle[1] + ',' +
                       ctrl_joint_angle[2] + '\n');
    }
    else
    {
      println("Please, Set On Controller");
    }
  }

/*******************************************************************************
* Init Function of Task Space Controller
*******************************************************************************/
  public void Drawing()
  {
    float posX, posY;

    posX = slider2d.getArrayValue()[0] * (-0.0001);
    posY = slider2d.getArrayValue()[1] * (-0.0001);

    opencr_port.write("position" + ',' +
                      posY       + ',' +
                      posX       + '\n');
  }

  public void Forward(int theValue)
  {
    if (onoff_flag)
    {
      opencr_port.write("task"    + ',' +
                        "f" + '\n');
      println("Move Forward");
    }
    else
    {
      println("Please, Set On Controller");
    }
  }

  public void Back(int theValue)
  {
    if (onoff_flag)
    {
      opencr_port.write("task"    + ',' +
                        "b"    + '\n');
      println("Move Back");
    }
    else
    {
      println("Please, Set On Controller");
    }
  }

  public void Left(int theValue)
  {
    if (onoff_flag)
    {
      opencr_port.write("task"    + ',' +
                        "l"    + '\n');
      println("Move Left");
    }
    else
    {
      println("Please, Set On Controller");
    }
  }

  public void Right(int theValue)
  {
    if (onoff_flag)
    {
      opencr_port.write("task"    + ',' +
                        "r"   + '\n');
      println("Move Right");
    }
    else
    {
      println("Please, Set On Controller");
    }
  }

  public void Set(int theValue)
  {
    if (onoff_flag)
    {
      ctrl_joint_angle[0] = -60.0 * PI/180.0;
      ctrl_joint_angle[1] = 20.0 * PI/180.0;
      ctrl_joint_angle[2] = 40.0 * PI/180.0;

      opencr_port.write("joint"            + ',' +
                        ctrl_joint_angle[0] + ',' +
                        ctrl_joint_angle[1] + ',' +
                        ctrl_joint_angle[2] + '\n');
    }
    else
    {
      println("Please, Set On Controller");
    }
  }

/*******************************************************************************
* Init Function of Motion
*******************************************************************************/
  public void Motion_Start(int theValue)
  {
    if (onoff_flag)
    {
      opencr_port.write("demo"  + ',' +
                        "start"   + '\n');
    }
    else
    {
      println("Please, Set On Controller");
    }
  }

  public void Motion_Stop(int theValue)
  {
    if (onoff_flag)
    {
      opencr_port.write("demo"  + ',' +
                        "stop"    + '\n');
    }
    else
    {
      println("Please, Set On Controller");
    }
  }
}

