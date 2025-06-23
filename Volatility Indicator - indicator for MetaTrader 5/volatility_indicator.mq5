//+------------------------------------------------------------------+
//|                                          True Strength Index.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
  
input int MAPeriod = 5;
input int MAShift = 0; 
  
double ExtLineBuffer[]; 
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
   SetIndexBuffer(0, ExtLineBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_SHIFT, MAShift);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MAPeriod - 1);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
  {
   if (rates_total < MAPeriod - 1)
    return(0);
    
   int first, bar, iii;
   double Sum, SMA;
   
   if (prev_calculated == 0)
    first = MAPeriod - 1 + begin;
   else first = prev_calculated - 1;

   for(bar = first; bar < rates_total; bar++)
    {
     Sum = 0.0;
     for(iii = 0; iii < MAPeriod; iii++)
      Sum += price[bar - iii];
     
     SMA = Sum / MAPeriod;
     SMA=SMA-price[bar];
     
     ExtLineBuffer[bar] = SMA;
    }
     
   return(rates_total);
  }
