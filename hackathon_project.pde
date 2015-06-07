
  
  //
  //GENERIC OSC BOILERPLATE CODE
  //
  
  import oscP5.*;
  import controlP5.*; // gui
  
  PFont f;   //text font to display message
 
  Status status; 
  
  float x = 0.00;
  float y = 100.00;
  
  boolean debug = false;
  boolean running = false;
  boolean finishedRunning = false;
  
  
  //osc parameters & ports----------------
  int recvPort = 5001;
  OscP5 oscP5;
  String[] out_targets = {"127.0.0.1"};
  int[] out_ports = {5000};
  
  int WIDTH = 1200;
  int HEIGHT = 700;
  
  int no_of_dimensions = 88;
  //centroid of each class
  float[] classOneMean = new float[no_of_dimensions];
  float[] classTwoMean = new float[no_of_dimensions];

  //an amount of data classified as a certain class
  ArrayList<float []> classOneData = new ArrayList <float[]>();
  
  ArrayList<float []> classTwoData = new ArrayList <float[]>();
  
  
  
  ArrayList<float []> CurrentLearningClass = new ArrayList <float[]>();
  
  //used in saving data from sensors to one vector
  int no_of_dimensions_saved = 0;
  float[] temp1 = new float [no_of_dimensions];
  boolean vectorCompleted = false;
  
  
  int count_to_recalculate_centroids = 0;
  int count_to_resort_data = 0;
  
  float errorPercentage = 100;
  int no_vectors_learned = 0;
  
  float middle_point = 0.00;
  
  void initialize_learning_info()
  {
    //CurrentLearningClass.add(temp1);
    temp1 = new float [no_of_dimensions];
    no_of_dimensions_saved=0;
    vectorCompleted = false;
  }
  //SETUP------------------------------------------------------------------
  void setup() {
    size(WIDTH,HEIGHT);
    rectMode(CORNER);
    frameRate(60);
    oscP5 = new OscP5(this, recvPort);
     f = createFont("Arial",16,true); //  Create Font
     
    status = Status.Start;
    
    for(int i =0; i <no_of_dimensions; i++)
    {
      classOneMean[i] = 0;
      classTwoMean[i] = 0;
    }
  }
  //----------------------------------------------------------------
  
  void sendOSCMessage(OscMessage msg)
  {
    for (int i=0; i<out_ports.length; i++)
    {
      oscP5.send(msg, out_targets[i], out_ports[i]);
    }
  }  
    
  
  //DRAW LOOP -----------------------------------------------------------
  void draw() {
    background(255);
    textFont(f,40);                 //  Specify font to be used
    fill(0);                        //  Specify font color 

   
       switch(status)
      {
        case Start:
            if(!running)
                text("press on the screen to start initializing first Class of signals\n and keep doing the signal until the process is done!",10,100);
            else
               text("collecting data.. keep doing the signal until the process is done!",10,100);
            break;
        case InitializeOne:
             if(!running)
             {
                 text("First Class of signals is initialized... do the same for the second Class! press on the screen to start. ",10,100);
             }
             else
                text("collecting data.. keep doing the signal until the process is done!",10,100);
             break;
        case InitializeTwo:
             if(!running)
             {
                 text("second class of signals is initialized.. now do each movement at a time in various ways",10,100);//TODO display press to start learning
             }
             else
               text("collecting data.. keep doing the signal until the process is done!",10,100);
             break;
        case Learn:
             if(!running)
             {
                text("START TESTING ",10,100);//TODO display press to start
             } 
             else
                text("running ",10,100);
             break;
        case Pause:
             if(!running)
             {
                text("pause ",10,100); //TODO display press to test
             }
             else
                {text("press to pause ",10,100);
               rect(x, y, 50, 50); 
              }
             break;
        case Test:
             if(running)
             {
               text("press to pause ",10,100);
               rect(x, y, 50, 50);
                //TODO display result and press to pause 
             }
             else
               {text("pause ",10,100);
               rect(x, y, 50,50);}
            break;
      
    }
  
  }
  
  //POUSE PRESS.................
  void mousePressed() 
  {
    if(!running)
    {println(" MOUSE PRESSED ");
      switch(status)
      {
        case Start:
            status = Status.InitializeOne;
            running = true;
            break;
        case InitializeOne:
            
           
            classOneMean = get_mean(CurrentLearningClass);
            CurrentLearningClass = new ArrayList <float[]>();
            initialize_learning_info();
            for(int i = 0 ; i<classOneMean.length;i++)
                System.out.println(classOneMean[i]);
            status = Status.InitializeTwo;
            running = true;
            finishedRunning = false;
            
            
            break;
        case InitializeTwo:
            status = Status.Learn;
            running = true;
            classTwoMean = get_mean(CurrentLearningClass);
            CurrentLearningClass = new ArrayList <float[]>();
            initialize_learning_info();
            
            break;
        case Learn:
            status = Status.Pause;
            initialize_learning_info();
            running = true;  //TODO review
            break;
        case Pause:
            status = Status.Test;
            running = true;
            break;
        case Test:
            initialize_learning_info();
            status = Status.Pause;
            running = false;
            break;
        
      }
    }
    else
    {
     //TODO if status is paused start testing 
     switch(status)
      {
        case Pause:
            status = Status.Test;
            running = true;
            //TODO start testing
            break;
       default:
            break;
      }
    }
  }
  

  
  //OSC HANDLER------------------------------------------------
  void oscEvent(OscMessage msg) 
  {
    
    /* print the address pattern and the typetag of the received OscMessage */
    if (debug) 
    {
      print("### received an osc message.");
      print(" addrpattern: "+msg.addrPattern());
      println(" typetag: "+msg.typetag());
    }
    
    
    
    switch(status)
    {
     case Start:
            break;
     case InitializeOne:
     case InitializeTwo:
        //the data of the four sensors are added.. start getting a new vector of data
        if(vectorCompleted)
        {
           CurrentLearningClass.add(temp1);
           initialize_learning_info();
        }
        
        get_new_data_vector(msg);
        if(CurrentLearningClass.size() == 300 && !finishedRunning)
              {running = false; finishedRunning = true;}
            
     break;
     
     case Learn:
        if(vectorCompleted)
        {
          System.out.println("push to nearest");
           push_to_nearest_centroid(temp1);
           System.out.println("initialize");
           no_vectors_learned++;
           initialize_learning_info();
           System.out.println("check for error"+ errorPercentage);
          if(errorPercentage <= 0.05 && no_vectors_learned > 1000 )
              running = false;
        }
        
        get_new_data_vector(msg);
        
        break;
     case Pause:
            
            break;
     case Test:
     if(middle_point < 0.1)
     {
       middle_point = get_distance(classTwoMean, classOneMean)/2.0;
     }
         if(vectorCompleted)
         {
       
            if(find_nearest_centroid(temp1) && abs(get_distance(classOneMean, temp1)-middle_point) > 2 && abs(get_distance(classOneMean, temp1)-middle_point) < 2)
            {
              x =500.00;
            }
            else if ( abs(get_distance(classTwoMean, temp1)-middle_point) > 2)
            {
              x = 100.00;
            }
            else
            {
              x = -200;
            }
           initialize_learning_info();
        }
             get_new_data_vector(msg);
            break;     
    }
    
    
    
    

    }
  
  
  /**
  //get the euclidean distance between two vectors 
  **/
  float get_distance(float a[], float b[])
  {
    if(a.length != b.length)
      return 0.00;
    else
    {
      float sum = 0;
      for(int i = 0; i<a.length; i++)
      {
        sum = (a[i]-b[i])*(a[i]-b[i]);
      }
      return sqrt(sum);
    }
  }
  
  /**
  //returns the mean of array vectors.. to recalculate the centroid
  **/
  float[] get_mean(ArrayList<float []> data)
  {
    float[] sum = new float[data.get(0).length];
   for(int i = 0; i < data.size() ; i++) 
   {
    for(int j = 0 ; j < data.get(0).length; j++)
       sum[j] = sum[j] + data.get(i)[j];
   } 
   for(int j = 0 ; j < data.get(0).length; j++)
       sum[j] = sum[j]/ data.size();
       
   return sum;
  }


  /**
  //getting data from the 4 ffts and saving the last 1/3 of each
  //to minimize the dimensions
  // every fft has 129 taking one third so we are left with 44 dimension 
  // the 44 is minimized to half so 22 from each fft
  // then the 4 arrays of results from each fft is combined to make an array of 88 dimensions
  **/
  void get_new_data_vector(OscMessage msg)
  {
     if (msg.checkAddrPattern("/muse/elements/raw_fft0")==true) 
      { 
      if(running)
      {
      //int no_of_dimensions_saved = 0;
       //System.out.println("new 0");
        for(int i = 0; i < 129; i++)
        {
          
          if(i > 84)
          {
           //System.out.println(msg.get(i).floatValue());
           //minimize the dimensions by taking average of each two
           temp1[no_of_dimensions_saved] = (msg.get(i).floatValue()+msg.get(i+1).floatValue())/2;
           i++;
          no_of_dimensions_saved++;
          }   
            
        }
      } 
       
    }
    if (msg.checkAddrPattern("/muse/elements/raw_fft1")==true) 
    { 
      if(running)
      {
       //System.out.println("new 1");
     
        for(int i = 0; i < 129; i++)
        {
          
          if(i > 84)
          {
           //System.out.println(msg.get(i).floatValue());
           //minimize the dimensions by taking average of each two
           temp1[no_of_dimensions_saved] = (msg.get(i).floatValue()+msg.get(i+1).floatValue())/2;
           i++;
          no_of_dimensions_saved++;
          }   
            
        }
       
      }  
    }
    if (msg.checkAddrPattern("/muse/elements/raw_fft2")==true) 
    { 
      if(running)
      {
       //System.out.println("new 2");
     
        for(int i = 0; i < 129; i++)
        {
          
            if(i > 84)
           {
           //System.out.println(msg.get(i).floatValue());
           //minimize the dimensions by taking average of each two
           temp1[no_of_dimensions_saved] = (msg.get(i).floatValue()+msg.get(i+1).floatValue())/2;
           i++;
            no_of_dimensions_saved++;
            }   
            
        }
  
      }
    }  
    if (msg.checkAddrPattern("/muse/elements/raw_fft3")==true) 
    { if(running) 
      { 
          //System.out.println("new 3");
     
          for(int i = 0; i < 129; i++)
          {
          
            if(i > 84)
            {
             //System.out.println(msg.get(i).floatValue());
             //minimize the dimensions by taking average of each two
             temp1[no_of_dimensions_saved] = (msg.get(i).floatValue()+msg.get(i+1).floatValue())/2;
             i++;
            no_of_dimensions_saved++;
            }   
            
          }
          vectorCompleted = true; 
         //System.out.println("vector completed ");
      } 
     
    }
  }
  
  
  /**
  //find the nearest centroid to the new point then add it to the new sample and increment the counts
  //i am not updating the data with every new vector due to the big amount of dimensions and big amount of data
  //every  new vectors recalculate new centroid of the class that was modified and every 20 new vectors resort points in the nearest Class list of data
  //
  **/
  void push_to_nearest_centroid(float vector_data[])
  {
      System.out.println("pushing to nearest distance ");
     count_to_resort_data++;
     if(find_nearest_centroid(vector_data))
     {
       classOneData.add(vector_data);
       classOneMean = get_mean(classOneData);
     }
     else
     {
       classTwoData.add(vector_data);
       classTwoMean = get_mean(classTwoData);
     }
     float error = 0.00 ;
     //resort data 
     if(count_to_resort_data == 20)
     {
       ArrayList<float []> classOneDataTemp = new ArrayList <float[]>();
       ArrayList<float []> classTwoDataTemp = new ArrayList <float[]>();
       for(int i=0;i<classOneData.size() ; i++)
       {
         if (find_nearest_centroid(classOneData.get(i)))
         {
             classOneDataTemp.add(classOneData.get(i));
             
             
         }   else 
         {  
             classTwoDataTemp.add(classOneData.get(i));
             error++;
         }
       }
       for(int i=0;i<classTwoData.size() ; i++)
       {
         if (!find_nearest_centroid(classTwoData.get(i)))
         {
             classTwoDataTemp.add(classTwoData.get(i));
         }  else
         {
             classOneDataTemp.add(classTwoData.get(i));
             error++;
         }  
       }
       
       classOneData = classOneDataTemp;
       classTwoData = classTwoDataTemp;
       count_to_resort_data = 0;
       
       //recalculate centroids.. 
       classOneMean = get_mean(classOneData);
       classTwoMean = get_mean(classTwoData);
       
       //recalculate error percentage
       errorPercentage = error/(classOneData.size() + classTwoData.size())*100; 
       
     }
   
  }
  
  /**
  //if classOne is nearest return true if classTwo is nearest return false
  //NOTE bad design in case you wanna increase the number of classes later on.. reuse your brain proparly when you have time
  **/
  boolean find_nearest_centroid(float vector_data[])
  {
   if(get_distance(classOneMean, vector_data) > get_distance(classTwoMean, vector_data))
       return false;
   else return true;
    
  }
  
  
  
