//+------------------------------------------------------------------+
//|                                     SimpleZZColorRetracement.mq5 |
//|                                        Copyright 2016, Oschenker |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Oschenker"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1

// plot MyZigZag
#property indicator_label1  "MyZigZag"
#property indicator_type1   DRAW_COLOR_SECTION
#property indicator_color1  clrBlue, clrGray, clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

// input parameters
input int      Retracement = 10; // Typical retracement size
input int      MAPeriod = 20;    // Moves averaging period
input int      Bound = 61;       // Moves percentage difference

int            Goal;
int            LastPoint;

// indicator buffers
double         ZZPoints[];
double         ZZColor[];
double         LMoves[];

// other parameters
double         Scale; // Typical retracement size
double         LLow;  // Last Low
double         LHigh; // Last High
double         PLow;  // Prior Low
double         PHigh; // Prior High
double         LMove; // Last Move
double         SumMove = 0; // sum of N last moves (N = MAPeriod)
double         MAMoves = 0; // moving average of N last moves (N = MAPeriod)
double         DoubleBound;

string         com;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   // indicator buffers mapping
   SetIndexBuffer(0, ZZPoints, INDICATOR_DATA);
   SetIndexBuffer(1, ZZColor,  INDICATOR_COLOR_INDEX);

   // set short name and digits   
   PlotIndexSetString(0,PLOT_LABEL,"Color Trend ZigZag("+(string)Scale+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
      
   // set plot empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   // setup Scale value
   Scale = Retracement * Point();
   DoubleBound = Bound * 0.01;

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
   int MAIndex = 0;
   if(rates_total < 3) return(0);
   
   // resize array to calculate average
   ArrayResize(LMoves, MAPeriod, 0);

   if(prev_calculated == 0)  // in case there is no previous calculations
     {
      ArrayInitialize(ZZPoints,EMPTY_VALUE); // initialize buffer with zero volues
      ArrayInitialize(ZZColor,EMPTY_VALUE);  // initialize buffer with zero volues
      ArrayInitialize(LMoves,0.0);// initialize MA array with zero values
      Start = 1;
      if(low[0] < high[1])
             {
              PLow = LLow = low[0];
              PHigh = LHigh = high[1];
              Goal     = 2;
             }
      else
             {
              PHigh = LHigh = high[0];
              PLow = LLow  = low[1];
              Goal     = 1;
             }      
      LMoves[0] = MAMoves = LHigh - LLow;
      LMoves[1] = 0;
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
                      ZZPoints[LastPoint] = EMPTY_VALUE;
                      ZZColor[LastPoint]  = EMPTY_VALUE;
                      LastPoint = bar;
                      ZZPoints[LastPoint] = LLow;
                      ZZColor[LastPoint]  = ColorCheck((LHigh - LLow) / MAMoves, DoubleBound);
                      break;
                     }
                if(high[bar] > (LLow + Scale))
                     {
                      MAIndex++;
                      if(MAIndex == MAPeriod) MAIndex = 0;
                      LMove = LHigh - LLow;
                      SumMove = SumMove + LMove - LMoves[MAIndex];
                      LMoves[MAIndex] = LMove;
                      MAMoves = SumMove / MAPeriod;
                      PHigh = LHigh;
                      LHigh = high[bar];
                      LastPoint = bar;
                      ZZPoints[LastPoint] = LHigh;
                      ZZColor[LastPoint]  = ColorCheck((LHigh - LLow) /  MAMoves, DoubleBound);
                      Goal = 2;
                     }
                break;

            case 2: // Last was a high - goal is low
                   if(high[bar] >= LHigh)
                     {
                      LHigh = high[bar];
                      ZZPoints[LastPoint] = EMPTY_VALUE;
                      ZZColor[LastPoint]  = EMPTY_VALUE;
                      LastPoint = bar;
                      ZZPoints[LastPoint] = LHigh;
                      ZZColor[LastPoint]  = ColorCheck((LHigh - LLow) / MAMoves, DoubleBound);
                      break;
                     }
                   if(low[bar] < (LHigh - Scale))
                     {
                      MAIndex++;
                      if(MAIndex == MAPeriod) MAIndex = 0;

                      LMove = LHigh - LLow;
                      SumMove = SumMove + LMove - LMoves[MAIndex];
                      LMoves[MAIndex] = LMove;
                      MAMoves = SumMove / MAPeriod;
                      PLow = LLow;
                      LLow  = low[bar];
                      LastPoint = bar;
                      ZZPoints[LastPoint] = LLow;
                      ZZColor[LastPoint]  = ColorCheck((LHigh - LLow) / MAMoves, DoubleBound);
                      Goal = 1;
                     }
                   break;
           }
     }
   
   return(rates_total);
  }
int ColorCheck( double p_ratio,
                double p_bound)
    {
    int color_check = 0;
    if(p_ratio > (1 + p_bound)) color_check = 0;
    else
      {
       if(p_ratio < (1 - p_bound)) color_check = 2;
       else color_check = 1;
      }
    return(color_check);
   }
//+------------------------------------------------------------------+
