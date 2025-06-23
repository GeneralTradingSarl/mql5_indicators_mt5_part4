//+------------------------------------------------------------------+
//|                                                          YMA.mq5 |
//|                                                     Yuriy Tokman |
//|                                                http://ytg.com.ua |
//+------------------------------------------------------------------+
#property copyright "Yuriy Tokman"
#property link      "http://ytg.com.ua"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots   1
#property indicator_width1   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkViolet
//--- input parameters
input int            YMA_Period=21;         // Period
//--- indicator buffers
double Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,Buffer);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,YMA_Period);
   string short_name="YMA";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(YMA_Period)+")");
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
//----
   int i,limit;
//--- check for rates
   if(rates_total<YMA_Period) return(0);
//--- preliminary calculations
   if(prev_calculated==0)limit=YMA_Period;
   else limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      double res =0;
      for(int j=i;j>i-YMA_Period && j>0;j--)
       {
        res += (close[j]+open[j]+high[j]+low[j])/4;
       }
      Buffer[i]=res/YMA_Period;
     }
 //----
   return(rates_total);
  }
//+------------------------------------------------------------------+