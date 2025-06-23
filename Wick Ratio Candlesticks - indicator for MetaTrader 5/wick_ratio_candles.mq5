//+------------------------------------------------------------------+
//|                                           Wick_Ratio_Candles.mq5 |
//|                                      Rajesh Nait, Copyright 2023 |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Rajesh Nait, Copyright 2023"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_label1 "Open;High;Low;Close"
#property indicator_plots 1             
#property indicator_type1 DRAW_COLOR_CANDLES
#property indicator_width1 1

input color clr_Green=clrGreen;
input color clr_Red=clrRed;
input color clr_Snow=clrSnow;

double buf_open[],buf_high[],buf_low[],buf_close[],buf_color[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,buf_open,INDICATOR_DATA);
   SetIndexBuffer(1,buf_high,INDICATOR_DATA);
   SetIndexBuffer(2,buf_low,INDICATOR_DATA);
   SetIndexBuffer(3,buf_close,INDICATOR_DATA);

   SetIndexBuffer(4,buf_color,INDICATOR_COLOR_INDEX);
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,clr_Green);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,clr_Red);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,2,clr_Snow);
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
     for(int i=prev_calculated; i<=rates_total-1; i++) {
      buf_open[i]=open[i];
      buf_high[i]=high[i];
      buf_low[i]=low[i];
      buf_close[i]=close[i];

      if(open[i]<close[i] && (high[i]-close[i] < open[i]-low[i])) 
         buf_color[i]=0;
      if(open[i]<close[i] && (high[i]-close[i] > open[i]-low[i]))
         buf_color[i]=1;

      if(open[i]>close[i] && (high[i]-open[i] > close[i]-low[i]))
         buf_color[i]=1;
      if(open[i]>close[i] && (high[i]-open[i] < close[i]-low[i]))
         buf_color[i]=0;

      if((open[i]>close[i] || open[i]<close[i] )&& (high[i]-open[i] == close[i]-low[i] )  )
         buf_color[i]=2;

   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
