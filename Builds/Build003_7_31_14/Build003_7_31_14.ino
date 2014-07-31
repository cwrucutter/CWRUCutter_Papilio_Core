//Note to self: Check and set minimum and maximum RC commands
//Note to self: change startup delay back to 10s


/*CWRUCutter Papilio ZPUino Core
Consists of a scheduler and various sub-functions run by the scheduler


The scheduler checks how much time has passed since a function has run.
If the time is greater than desired, the function is run again and the counter is reset
*/

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

    //Define communication on wishbone slot 6 for PWM inputs
    #define RCINPUT IO_SLOT(6)
    #define PWMIN(x) REGISTER(RCINPUT,x)

    //Wheel spacing constant
    float b = 0.53;
	
    //Constants defining RC maximum, minimum, center, time-out, and EStop Threshold
    int k_RCCenter = 144500;
    int k_RCMax = 193000;
    int k_RCMin = 96000;
    int k_RCTimeout = 1930000;
    int k_EStopThreshold = 180000;
    //Variables pulled from the RC input registers
    int ForwardPulse;
    int ForwardCycle;
    int AngularPulse;
    int AngularCycle;
    int EStopPulse;
    int EStopCycle;
    
    //Time-out checking
    int ConsecutiveRCInvalidCheck = 0; //Used to disable RC control if we receive time-outs from any two consecutive inputs
    int ConsecutiveRCValidCheck = 0; //Checks to ensure we have five consecutive valid commands before resuming control

    //Calculated motor commands and related variables
    int RCForwardCommand = 0;//negative is reverse, positive is forward
    int RCAngularCommand = 0;//negative is left, positive is right
    int SignedRCLeftSpeed = 0;
    int SignedRCRightSpeed = 0;
	
    int RCLeftMotorSpeed = 0;
    int RCLeftMotorDirection = 0;
    int RCRightMotorSpeed = 0;
    int RCRightMotorDirection = 0;



//ROS Serial variables

//PID variables - until a new PID loop is written it will be used as a simple RC passthrough

	//Motor commands
	int LeftMotorSpeed;
	int RightMotorSpeed;
	int LeftMotorDirection;
	int RightMotorDirection;

//Roboteq Motor controller command variables

	//Set up serial communication over the wishbone bus for the Roboteq
	HardwareSerial RoboteqSerial(10);
	
	//Motor nibbles - we break the motor speeds into two commands for the Roboteq
	char LeftMotorFirstNibble;
	char LeftMotorSecondNibble;
	char RightMotorFirstNibble;
	char RightMotorSecondNibble;
	
	
	
	
//Heartbeat variables




void setup()
{
  RoboteqSerial.begin(9600);
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
  //Temp set to 2 seconds for testing
  delay(2000);
  
  //run all of the various sub-functions and establish an initial run time
  SafetyStateMachine();
  RCPolling();
  ROSSerial();
  PIDLoop();
  RoboteqMotorCommandLoop();
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
    RoboteqMotorCommandLoop();
  }
  
  // check to see if enough time has passed to run the heartbeat loop
  if ((millis() - LastHeartbeatTime) > (k_Heartbeat))
  {
	Heartbeat();
  }
  
  
}

//--------------------------------------------------------------------------------------------------------------
//Subfunctions handling all of the control loops
//These should be retooled to use structs once the general scheduler structure is complete.
//--------------------------------------------------------------------------------------------------------------

//SafetyStateMachine handles safety 
//------------------------------------
void SafetyStateMachine()
{
  SafetyStateMachineLastTime = millis();

}



//RCPolling checks the RC input signals at 10 hz.
//It returns a speed command to be sent to the PID loop.
//-------------------------------------------------------
void RCPolling()
{
  RCPollingLastTime = millis();
  
  //get RC signal from registers
  AngularPulse = (int)PWMIN(0);
  AngularCycle = (int)PWMIN(1);
  ForwardPulse = (int)PWMIN(2);
  ForwardCycle = (int)PWMIN(3);
  EStopPulse = (int)PWMIN(4);
  EStopCycle = (int)PWMIN(5);
  

  

  //PWM input validity check. If signals are invalid twice in a row disable drive commands until they are valid five times in a row.

  
  //Check if any signals are invalid. If a signal is invalid increment the check by one. 
  //If two signals have been invalid in a row set the consecutive check to zero.
  if ((ForwardCycle == k_RCTimeout) || (AngularCycle == k_RCTimeout) || (EStopCycle == k_RCTimeout)){
    ConsecutiveRCInvalidCheck++;
    if (ConsecutiveRCInvalidCheck >= 2){
      ConsecutiveRCValidCheck = 0;
      
    }
  }
  
  //Check if the all current signals are valid. If all signals are valid 
  if ((ForwardCycle != k_RCTimeout) || (AngularCycle != k_RCTimeout) || (EStopCycle != k_RCTimeout)){
      ConsecutiveRCValidCheck++;
      ConsecutiveRCInvalidCheck = 0;
  }

      
  
  //Check to ensure current command is valid by checking that commands are within minimum and maximum values as well as ensuring we do not have a timeout case
  if (((ForwardCycle != k_RCTimeout) && (ForwardPulse >= k_RCMin) && (ForwardPulse <= k_RCMax)) 
  && ((AngularCycle != k_RCTimeout) && (AngularPulse >= k_RCMin) && (AngularPulse <= k_RCMax)) 
  && (EStopCycle != k_RCTimeout) && (EStopPulse >= k_RCMin) && (EStopPulse <= k_RCMax))
  {
        
	//if the RC commands have been valid for more than five checks run the RC control loop
    if ((ConsecutiveRCValidCheck >= 5) && (EStopPulse >= k_EStopThreshold))
    {
      //find the distance from the center for the forward and angular command and convert it into a signed left and right speed
      RCForwardCommand = (ForwardPulse - k_RCCenter);
      RCAngularCommand = (AngularPulse - k_RCCenter);
      SignedRCLeftSpeed = (RCForwardCommand + 0.5 * b * RCAngularCommand);
      SignedRCRightSpeed = (RCForwardCommand - 0.5 * b * RCAngularCommand);
	  
      //convert signed left and right wheel speeds into unsigned speeds and directions
      //speeds are capped at 115 due to steering adding to the values
      //and causing it to go over 127
      
      
      //make adjustments for left motor/wheel
      if (SignedRCLeftSpeed >= 0)
      {
        RCLeftMotorDirection = 0;//change based on motor controller
	RCLeftMotorSpeed = (115 * SignedRCLeftSpeed) / (k_RCMax - k_RCCenter);
      }
      else 
      {
        RCLeftMotorDirection = 1;//change based on motor controller
	RCLeftMotorSpeed = (-115 * SignedRCLeftSpeed) / (k_RCMax - k_RCCenter);
      } 
      
      //Make adjustments for the right motor/wheel
      if (SignedRCRightSpeed >= 0)
      {
        RCRightMotorDirection = 0;//change based on motor controller
	RCRightMotorSpeed = (115 * SignedRCRightSpeed) / (k_RCMax - k_RCCenter);
      }
      else 
      {
  	RCRightMotorDirection = 1;//change based on motor controller
	RCRightMotorSpeed = (-115 * SignedRCRightSpeed) / (k_RCMax - k_RCCenter);
      }  	 
	  //----------Resume code here
	  
    }
	else if((ConsecutiveRCValidCheck < 5) || (EStopPulse <= k_EStopThreshold))
	{
	RCRightMotorSpeed = 0;
	RCLeftMotorSpeed = 0;
	}

  
  }
}
void ROSSerial()
{
  ROSSerialLastTime = micros();
}

void PIDLoop()
{
  PIDLoopLastTime = millis();
  //Temporarily using the PID command as a pass-through
  LeftMotorSpeed = RCLeftMotorSpeed;
  LeftMotorDirection = RCLeftMotorDirection;
  RightMotorSpeed = RCRightMotorSpeed;
  RightMotorDirection = RCRightMotorDirection;
}  

void RoboteqMotorCommandLoop()
{
  MotorCommandLastSent = micros();
  
  //Left and right motor command processing

  //Pull left motor speed apart into two separate nibbles and convert them to ascii
  LeftMotorSecondNibble = char(LeftMotorSpeed & 0x0F) + '0';
  if (LeftMotorSecondNibble > 57)
  {
	LeftMotorSecondNibble = (LeftMotorSecondNibble + 7);
  }
  LeftMotorFirstNibble = char((LeftMotorSpeed & 0xF0) >> 4) + '0';
  if (LeftMotorFirstNibble > 57)
  {
	LeftMotorFirstNibble = (LeftMotorFirstNibble + 7);
  }
  
  //Pull right motor speed apart into two separate nibbles and convert them to ascii
  RightMotorSecondNibble = char(RightMotorSpeed & 0x0F) + '0';
  if (RightMotorSecondNibble > 57)
  {
	RightMotorSecondNibble = (RightMotorSecondNibble + 7);
  }
  RightMotorFirstNibble = char((RightMotorSpeed & 0xF0) >> 4) + '0';
  if (RightMotorFirstNibble > 57)
  {
	RightMotorFirstNibble = (RightMotorFirstNibble + 7);
  }
  
  //Send commands to Roboteq

  //send packet to left motor
  if (LeftMotorSpeed <= 127)
  {
    RoboteqSerial.write(addParity('!')); // initiate the command
	if (LeftMotorDirection == 0)			 // send forward or reverse command based on desired direction
	{
	  RoboteqSerial.write(addParity('A'));
	}
	else if (LeftMotorDirection == 1)
	{
	  RoboteqSerial.write(addParity('a'));
	}
	RoboteqSerial.write(addParity(LeftMotorFirstNibble)); 	//send command with the first nibble
	RoboteqSerial.write(addParity(LeftMotorSecondNibble));  //send command with the second nibble
	RoboteqSerial.write(addParity(13));							//send carriage return to finish the packet
  }
 
  //send packet to right motor
  if (RightMotorSpeed <= 127)
  {
    RoboteqSerial.write(addParity('!')); 	// initiate the command
	if (RightMotorDirection == 0)			// send forward or reverse command based on desired direction
	{
	  RoboteqSerial.write(addParity('B'));
	}
	else if (RightMotorDirection == 1)
	{
	  RoboteqSerial.write(addParity('b'));
	}
	RoboteqSerial.write(addParity(RightMotorFirstNibble)); 	//send command with the first nibble
	RoboteqSerial.write(addParity(RightMotorSecondNibble)); //send command with the second nibble
	RoboteqSerial.write(addParity(13)); 							//send carriage return to finish the packet
  }
}

void Heartbeat()
{
  LastHeartbeatTime = millis();

}


char addParity(char a)
{
  unsigned char p;
  p = a;
  p ^= (p >> 4);
  p ^= (p >> 2);
  p ^= (p >> 1);
  a |= (p<<7);
  return a;
}
