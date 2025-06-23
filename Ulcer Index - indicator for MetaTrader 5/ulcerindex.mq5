//+------------------------------------------------------------------+
//|                                                   UlcerIndex.mq5 |
//|                                  Copyright 2018, Samuel Williams |
//|                          https://www.mql5.com/en/users/sambo3261 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Samuel Williams"
#property link      "https://www.mql5.com/en/users/sambo3261"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot UI
#property indicator_label1  "UI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkOrange
#property indicator_style1  STYLE_DASH
#property indicator_width1  3
//--- input parameters
input int      LookBackPeriod=14;
//--- indicator buffers
double         UIBuffer[];
double         DrawDownBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,UIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DrawDownBuffer,INDICATOR_CALCULATIONS);

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
//---
   int i=(int)MathMax(prev_calculated-1,1);  for(; i<rates_total && !_StopFlag; i++)
     {
      //---Body of calculations here 
      DrawDownBuffer[i]=((close[i]-close[ArrayMaximum(close,LookBackPeriod,i)])/close[ArrayMaximum(close,LookBackPeriod,i)]);
      double squaredDD = 0.0;
      double squaredAvg=0.0;
      if(i>LookBackPeriod)
        {
         for(int x=i-LookBackPeriod;x<i;x++)
           {
            squaredDD=squaredDD+MathPow(DrawDownBuffer[x],2);
           }
        }
      squaredAvg=squaredDD/LookBackPeriod;
      UIBuffer[i]=MathSqrt(squaredAvg);
     }

//--- return value of prev_calculated for next call
   return(i);
  }
//+------------------------------------------------------------------+
