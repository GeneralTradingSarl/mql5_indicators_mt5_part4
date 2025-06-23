//+------------------------------------------------------------------+
//|                                                   FiboZigZag.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window


//--- input parameters
input string   inpName           = "Fibo_01";      // Fibo Name
input int      inpDepth          = 34;             // ZigZag Depth
input int      inpDeviation      = 15;              // ZigZag Deviation
input int      inpBackStep       = 8;              // ZigZag BackStep
input int      inpLeg            = 1;              // ZigZag Leg
input color    inpLineColor      = clrRed;         // Line Color
input color    inpLevelsColor    = clrSteelBlue;   // Levels Color
input bool     inpRay            = false;          // Ray
input double   inpLevel1         = 0.0;            // Level 1
input double   inpLevel2         = 23.6;           // Level 2
input double   inpLevel3         = 38.2;           // Level 3
input double   inpLevel4         = 50.0;           // Level 4
input double   inpLevel5         = 61.8;           // Level 5
input double   inpLevel6         = 100.0;          // Level 6
input double   inpLevel7         = 161.8;          // Level 7
input double   inpLevel8         = 261.8;          // Level 8
input double   inpLevel9         = 423.6;          // Level 9
input int      inpMaxBars        = 1000;

//--- global variables
double   levels[9];     // Levels Array
int      handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
// Set Levels Array
   levels[0] = inpLevel1;  levels[1] = inpLevel2;  levels[2] = inpLevel3;  levels[3] = inpLevel4;  levels[4] = inpLevel5;
   levels[5] = inpLevel6;  levels[6] = inpLevel7;  levels[7] = inpLevel8;  levels[8] = inpLevel9;

   handle=iCustom(_Symbol, PERIOD_CURRENT, "examples\\ZigZag", inpDepth, inpDeviation, inpBackStep);
   
   if(handle == INVALID_HANDLE)
      return INIT_FAILED;

//---
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
//---

// To Delete Fibonacci
   ObjectDelete(0,inpName);

//---
  }  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   datetime times[2];
   double price[2];

   // Get Times and Price ZigZag Values.
   if(!GetZZ(times,price)) 
      return 0;

   if(ObjectFind(0,inpName)<0) 
      FiboDraw(inpName,times,price,inpLineColor,inpLevelsColor);    // Create new Fibonacci
   else 
      FiboMove(inpName,times,price,inpLevelsColor);                                        // Move current Fibonacci
   
   ChartRedraw();                                                                            // Refresh chart

//--- return value of prev_calculated for next call
   return(rates_total);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| FiboMove function                                                |
//+------------------------------------------------------------------+
void FiboMove(string name,datetime &time[],double &price[],color clrLevels)
  {
// Move current Fibonacci
   ObjectMove(0,name,0,time[1],price[1]);    // Move first point of the fibo
   ObjectMove(0,name,1,time[0],price[0]);    // Move second point of the fibo
   FiboSetLevels(name,price,clrLevels);      // Set Levels of the fibo
   ChartRedraw();                            // Refresh chart
  }

//+------------------------------------------------------------------+
//| FiboDraw function                                                |
//+------------------------------------------------------------------+
bool FiboDraw( const string      name,                   // object name
              datetime          &time[],                // array time
              double            &price[],               // array price
              const color       clrFibo=clrRed,         // object color
              const color       clrLevels=clrYellow)    // levels color
  {

   long chart_ID=0;
   int sub_window=0;

   ResetLastError();

// Create Fibonacci Object
   if(!ObjectCreate(chart_ID,name,OBJ_FIBO,sub_window,time[1],price[1],time[0],price[0]))
     {
      Print(__FUNCTION__,
            ": failed to create \"Fibonacci Retracement\"! Error code = ",GetLastError());
      return(false);
     }
//--- set fibonacci object properties
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrFibo);      // Set Fibo Color
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,STYLE_SOLID);  // Set Fibo Line Style
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,1);            // Set Fibo Line Width
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);         // Set Fibo To Front
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false);   // Set Fibo Not Selectable
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);     // Set Fibo Not Selected
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,inpRay);   // Set Fibo Ray
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,false);       // Set Fibo Hidden in Object List
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,0);

// Set Fibonacci Levels
   FiboSetLevels(name,price,clrLevels);

//--- successful execution
   return(true);
  }  
  
//+------------------------------------------------------------------+
//| FiboSetLevels function                                           |
//+------------------------------------------------------------------+
bool FiboSetLevels( const string      name,                   // object name
                   double            &price[],               // array price
                   const color       clrLevels=clrYellow)    // levels color
  {

   long chart_ID=0;
   int sub_window=0;
   int N=ArraySize(levels);
   string str="";

   ResetLastError();

// Define number of levels
   ObjectSetInteger(chart_ID,name,OBJPROP_LEVELS,N);

// Set Levels Properties
   for(int i=0;i<N;i++)
     {
      ObjectSetDouble(chart_ID,name,OBJPROP_LEVELVALUE,i,levels[i]/100.0);    // Set Level Value
      ObjectSetInteger(chart_ID,name,OBJPROP_LEVELCOLOR,i,clrLevels);         // Set Level Color
      ObjectSetInteger(chart_ID,name,OBJPROP_LEVELSTYLE,i,STYLE_DOT);         // Set Level Line Style
      ObjectSetInteger(chart_ID,name,OBJPROP_LEVELWIDTH,i,1);                 // Set Level Line Width
     }

// Set Levels descriptions
   for(int i=0;i<N;i++)
     {
      str = DoubleToString(levels[i],1) + "% = ";                                            // Set % levels value
      str += DoubleToString(price[0]+(levels[i]/100.0)*(price[1]-price[0]),_Digits) + "  ";  // Set price level value
      ObjectSetString(chart_ID,name,OBJPROP_LEVELTEXT,i,str);                                // Set Description Text
     }
//--- successful execution
   return(true);
  }

//+------------------------------------------------------------------+
//| GetZZ function                                                   |
//+------------------------------------------------------------------+
bool GetZZ(datetime &time[],double &price[])
  {
   bool ret= false;
   int leg = (int)MathMax(1,inpLeg);
   int cnt = 0;
   int idx = 0;
   double zz[];
   
   ArraySetAsSeries(zz, true);
   
   if(CopyBuffer(handle, 0, 0, inpMaxBars, zz) != inpMaxBars)
      return ret; 

   for(int i=1; i<inpMaxBars-1; i++) 
   {
      if(zz[i]<=0.0 || zz[i]==EMPTY_VALUE) 
         continue;
      
      cnt++;
      if(cnt<leg) 
         continue;
      
      datetime Time[];
      if(CopyTime(_Symbol,PERIOD_CURRENT, i, 1, Time) != 1)
         return false;
         
      time[idx]= Time[0];
      price[idx]=zz[i];
      idx++;
      
      if(idx>1) { 
         if(CopyTime(_Symbol,PERIOD_CURRENT, 0, 1, Time) != 1)
            return false;
            
         time[0]= Time[0];
         ret=true; 
         break; 
      }
     }

   return ret;
  }
//+------------------------------------------------------------------+