//+------------------------------------------------------------------+
//|                                               SimpleZZLevels.mq5 |
//|                                        Copyright 2016, Oschenker |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Oschenker"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

// plot MyZigZag
#property indicator_label1  "MyZigZag"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrBlack
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

// input parameters
input int      TotalPoints = 15; // Number of ZZ points analyzed
input int      TouchNum = 3;     // Number of times the price touches the level
input int      Deviation = 10;    // High/low max. deviation around level
input int      Retracement = 10; // Typical retracement size
/*
input int      ScaleMN  = 700;   // Typical retracement size for MN
input int      ScaleW1  = 600;   // Typical retracement size for W1
input int      ScaleD1  = 400;   // Typical retracement size for D1
input int      ScaleH4  = 200;   // Typical retracement size for H4
input int      ScaleH1  = 100;   // Typical retracement size for H1
input int      ScaleM30 = 030;   // Typical retracement size for M30
input int      ScaleM15 = 030;   // Typical retracement size for M15
input int      ScaleM5  = 020;   // Typical retracement size for M5
input int      ScaleM1  = 010;   // Typical retracement size for M1
*/
int            Goal;
int            LastExtrBar;

// indicator buffers
double         ZZPoints[];

// other parameters
double         Scale;
double         LLow;
double         LHigh;
double         PLow;
double         PHigh;
double         Level;

string         com;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // indicator buffers mapping
   SetIndexBuffer(0, ZZPoints, INDICATOR_DATA);

   // set short name and digits   
   PlotIndexSetString(0,PLOT_LABEL,"SimpleZigZag("+(string)Scale+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
      
   // set plot empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   
   // setup Scale value
   Scale = Retracement * Point();
/*   switch(_Period)
     {
      case  PERIOD_M1:
         Scale = ScaleM1 * Point();
        break;
      case  PERIOD_M5:
         Scale = ScaleM5 * Point();
        break;
      case  PERIOD_M15:
         Scale = ScaleM15 * Point();
        break;
      case  PERIOD_M30:
         Scale = ScaleM30 * Point();
        break;
      case  PERIOD_H1:
         Scale = ScaleH1 * Point();
        break;
      case  PERIOD_H4:
         Scale = ScaleH4 * Point();
        break;
      case  PERIOD_D1:
         Scale = ScaleD1 * Point();
        break;
      case  PERIOD_W1:
         Scale = ScaleW1 * Point();
        break;
      case  PERIOD_MN1:
         Scale = ScaleMN * Point();
        break;
     }*/
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // remove all line objects
   ObjectsDeleteAll( 0, "Level_", 0, OBJ_TREND);
   
   // remove comments, if any
   ChartSetString( 0, CHART_COMMENT, "");
   Scale = 0;
  }  

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int        rates_total,
                const int        prev_calculated,
                const datetime   &time[],
                const double     &open[],
                const double     &high[],
                const double     &low[],
                const double     &close[],
                const long       &tick_volume[],
                const long       &volume[],
                const int        &spread[])
  {
   int Start;
   
   if(rates_total < 3) return(0);
   
   if(prev_calculated == 0)  // in case there is no previous calculations
     {
      ArrayInitialize(ZZPoints,0.0); // initialize buffer with zero volues

      Start = 2;
      if(low[0] < high[1])
             {
              PLow = LLow = low[0];
              PHigh = LHigh = high[1];
              Goal     = 1;
             }
      else
             {
              PHigh = LHigh = high[0];
              PLow = LLow  = low[1];
              Goal     = 2;
             }      
     }
   else Start = prev_calculated - 1;

   // searching for Last High and Last Low
   for(int bar = Start; bar < rates_total - 1; bar++)
     {
      switch(Goal)
           {

            case 1 : // Last was a low - goal is high
                if(low[bar] <= LLow)
                     {
                      LLow = low[bar];
                      ZZPoints[LastExtrBar] = 0;
                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LLow;
                      break;
                     }
                if(high[bar] > (LLow + Scale))
                     {
                      PHigh = LHigh;
                      LHigh = high[bar];
                      
                    // check if LLow touches any level
                      Level = CheckLevel( Goal, TotalPoints, TouchNum, LastExtrBar, Deviation, time);

                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LHigh;
                      Goal = 2;
                     }
                break;

            case 2: // Last was a high - goal is low
                   if(high[bar] >= LHigh)
                     {
                      LHigh = high[bar];
                      ZZPoints[LastExtrBar] = 0;
                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LHigh;
                      break;

                     }
                   if(low[bar] < (LHigh - Scale))
                     {
                      PLow = LLow;
                      LLow  = low[bar];
                      
                    // check if LHigh touches any level
                      Level = CheckLevel( Goal, TotalPoints, TouchNum, LastExtrBar, Deviation, time);

                      LastExtrBar = bar;
                      ZZPoints[LastExtrBar] = LLow;
                      Goal = 1;
                     }
                   break;
           }
     }
   
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Custom indicator CheckLevel  function                            |
//+------------------------------------------------------------------+
   double   CheckLevel(int                par_Goal,
                       int                par_TotalPoints,
                       int                par_TouchNum,
                       int                par_LastExtrBar,
                       int                par_Deviation,
                       const datetime     &time[])
      {
       int     points = 0;
       int     touch_num = 0;
       int     touch_bar;
       int     shift = 1;
       double  level = 0;
       color   level_color;
       
       // searchin for non-zero ZZ points
       while(points < par_TotalPoints && shift <= par_LastExtrBar)
         {
          if(ZZPoints[par_LastExtrBar - shift] != 0)
            {
             if(fabs(ZZPoints[par_LastExtrBar] - ZZPoints[par_LastExtrBar - shift]) < Point() * par_Deviation)
               {
                // in case non-zero point is close enough to current point - increase touch counter by one and store the bar index
                touch_num++;
                touch_bar = par_LastExtrBar - shift;
               }
             points++;
            }
          shift++;
         }
       level_color = clrGray;
       if(touch_num >= par_TouchNum)
         {
          level = ZZPoints[LastExtrBar];
          
          if(ObjectCreate( 0, "Level_" + IntegerToString(par_LastExtrBar, 4, '0'), OBJ_TREND, 0, time[touch_bar], level, time[par_LastExtrBar], level))
            {
             switch(par_Goal)
               {
                case 1:
                  level_color = clrBlue;
                  break;
                case 2:
                  level_color = clrRed;
                  break;
               }
             ObjectSetInteger( 0, "Level_" + IntegerToString(par_LastExtrBar, 4, '0'), OBJPROP_COLOR, level_color);
             ObjectSetInteger( 0, "Level_" + IntegerToString(par_LastExtrBar, 4, '0'), OBJPROP_WIDTH, 3);
            }
         }
       return(level);
      }
                        

//+------------------------------------------------------------------+
