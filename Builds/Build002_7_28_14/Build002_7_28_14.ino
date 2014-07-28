//CWRUCutter Papilio Scheduler

//Checks how much time has passed since a function has run.
//If the time is greater than desired, the function is run again
//and the counter is reset


// Global constants

    //Constants defining how often functions should be run
    int k_SafetyStateMachine;
    int k_RCPolling;
    int k_ROSSerial;
    int k_PID;
    int k_MotorCommandSpeed;
    int k_Heartbeat;
    
    //variables containing the time each function was last called
    
    int SafetyStateMachineLastTime;
    int RCPollingLastTime;
    int ROSSerialLastTime;
    int PIDLoopLastTime;
    int MotorCommandLastSent;
    int LastHeartbeatTime;

//Safety State Machine variables

//RC Polling variables

//ROS Serial variables

//PID variables

//Motor command variables

//Heartbeat variables




void setup()
{
  
  Serial.begin(57600);
  //set constants to set number of times to run loops per second
  //values are equal to 1000/frequency to get the number of milliseconds to wait to run
  //in the case of loops that are intended to run more frequently than 100hz we take 1,000,000/frequency and use the micros instead of the millis function
  k_SafetyStateMachine = 100; // 10 hz
  k_RCPolling = 100; // 10hz
  k_ROSSerial = 1000; // 1000 hz, using micros
  k_PID = 10; // 100 hz
  k_MotorCommandSpeed = 1000; // 1000 hz, using micros
  k_Heartbeat = 5; // 200 hz
  
  //Delay 10 seconds to allow for initialization of other components
  delay(10000);
  
  //run all of the various subfunctions and establish an initial run time
  SafetyStateMachine();
  RCPolling();
  ROSSerial();
  PIDLoop();
  MotorCommandLoop();
  Heartbeat();
  
}

void loop()
{
  // check to see if enough time has passed to run the Safety State Machine loop
  if ((millis() - SafetyStateMachineLastTime) >= (k_SafetyStateMachine))
  {
    SafetyStateMachine();
  }
  
  // check to see if enough time has passed to run the RC polling loop
  if ((millis() - RCPollingLastTime) >= (k_RCPolling))
  {
    RCPolling();
  }
  
  // check to see if enough time has passed to run the ROS Serial Loop
  if ((micros() - ROSSerialLastTime) >= (k_ROSSerial)) 
  {
    ROSSerial();
  }
	
  // check to see if enough time has passed to run the PID loop
  if ((millis() - PIDLoopLastTime) >= (k_PID))
  {
    PIDLoop();
  }
  
  // check to see if enough time has passed to run motor command loop
  if ((micros() - MotorCommandLastSent) >= (k_MotorCommandSpeed))
  {
    MotorCommandLoop();
  }
  
  // check to see if enough time has passed to run the heartbeat loop
  if ((millis() - LastHeartbeatTime) > (k_Heartbeat))
  {
	Heartbeat();
  }
}


//Subfunctions handling all of the control loops
//These should be retooled to use structs once the general scheduler structure is complete.

void SafetyStateMachine()
{
  SafetyStateMachineLastTime = millis();

}

void RCPolling()
{
  RCPollingLastTime = millis();
}

void ROSSerial()
{
  ROSSerialLastTime = micros();
}

void PIDLoop()
{
  PIDLoopLastTime = millis();
}  

void MotorCommandLoop()
{
  MotorCommandLastSent = micros();
}

void Heartbeat()
{
  LastHeartbeatTime = millis();

}
