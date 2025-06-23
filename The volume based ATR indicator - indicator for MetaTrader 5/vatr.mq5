//+------------------------------------------------------------------+
//|                                                         VATR.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot VATR
#property indicator_label1  "VATR"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- enums
enum  ENUM_INPUT_YES_NO
  {
   INPUT_YES   =  1,       // Yes
   INPUT_NO    =  0        // No
  };
enum ENUM_TYPE_DRAWING
  {
   DRAWING_TYPE_LINE,      // Draw line
   DRAWING_TYPE_HISTOGRAMM // Draw hictogramm
  };
//--- input parameters
input int               InpPeriod      =  14;                  // Period of indicator
input ENUM_INPUT_YES_NO InpUseVolume   =  INPUT_YES;           // Use volume:
input ENUM_TYPE_DRAWING InpTypeDrawing =  DRAWING_TYPE_LINE;   // Type of indicator:
//--- indicator buffers
double         BufferVATR[];
double         BufferTEMP[];
//--- global variables
int            period_vatr;
//--- includes
#include <MovingAverages.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   period_vatr=(InpPeriod<1 ? 1 : InpPeriod);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferVATR,INDICATOR_DATA);
   SetIndexBuffer(1,BufferTEMP,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,(InpTypeDrawing ? DRAW_HISTOGRAM : DRAW_LINE));
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   IndicatorSetString(INDICATOR_SHORTNAME,"VATR("+(string)period_vatr+")");
//---
   return(INIT_SUCCEEDED);
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
//--- Checking for minimum number of bars
   if(rates_total<period_vatr+1) return 0;
//--- sets arrays as time series
   ArraySetAsSeries(BufferTEMP,true);
   ArraySetAsSeries(BufferVATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(tick_volume,true);
//--- Check for limits
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-2;
      ArrayInitialize(BufferVATR,0.0);
      ArrayInitialize(BufferTEMP,0.0);
     }
//--- calculated temp buffer
   for(int i=limit; i>=0; i--)
     {
      double hl=high[i]-low[i];
      double hc=fabs(high[i]-close[i+1]);
      double lc=fabs(low[i]-close[i+1]);
      double mn=fmin(fmin(hl,hc),lc);
      double tmp=mn*(InpUseVolume ? tick_volume[i]: 1.0);
      BufferTEMP[i]=(tmp<=0 ? DBL_MIN : tmp);
     }
//--- calculated VATR and return value of prev_calculated for next call
   return SimpleMAOnBuffer(rates_total,prev_calculated,0,period_vatr,BufferTEMP,BufferVATR);
  }
//+------------------------------------------------------------------+
