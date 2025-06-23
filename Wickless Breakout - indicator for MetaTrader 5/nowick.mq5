//+------------------------------------------------------------------+
//|                                             NoWick.mq5 |
//|                                      Rajesh Nait, Copyright 2023 |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Rajesh Nait, Copyright 2023"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot Bullish NoWick
#property indicator_label1  "+CI"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrSnow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Bearish NoWick
#property indicator_label2  "-CI"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrSnow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- input parameters
input group             "Bullish Candle Imbalance"
sinput uchar               InpBullishNoWickCode       = 251;         // Bullish Candle Imbalance: code for style DRAW_ARROW (font Wingdings)
input int                 InpBullishNoWickShift             = 10;          // Bullish NoWick: vertical shift of arrows in pixels
input group             "Bearish Candle Imbalance"
sinput uchar               InpBearishNoWickCode       = 251;         // Bearish Candle Imbalance: code for style DRAW_ARROW (font Wingdings)
input int                 InpBearishNoWickShift             = 10;          // Bearish Candle Imbalance: vertical shift of arrows in pixels
input double multiply = 2; // Multiplicator of Candle Wick
//--- indicator buffers
double   BullishNoWickBuffer[];
double   BearishNoWickBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
//--- indicator buffers mapping
   SetIndexBuffer(0,BullishNoWickBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BearishNoWickBuffer,INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,InpBullishNoWickCode);
   PlotIndexSetInteger(1,PLOT_ARROW,InpBearishNoWickCode);
//--- set the vertical shift of arrows in pixels
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,InpBullishNoWickShift);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-InpBearishNoWickShift);
//--- set as an empty value 0.0
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
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
                const int &spread[]) {
//---
   if(rates_total<3)
      return(0);
//---
   int limit=prev_calculated-1;
   if(prev_calculated==0) {
      limit=1;
      BullishNoWickBuffer[0]=0.0;
      BearishNoWickBuffer[0]=0.0;
   }
   for(int i=limit; i<rates_total; i++) {
      BullishNoWickBuffer[i]=0.0;
      BearishNoWickBuffer[i]=0.0;
      if(i>0) {


         if(open[i]<close[i]) { //bull
            if(high[i]==close[i])
               BearishNoWickBuffer[i]=high[i];

            if(low[i]==open[i])
               BullishNoWickBuffer[i]=low[i];


         }

         else { //bear
            if(high[i]==open[i])
               BearishNoWickBuffer[i]=high[i];

            if(low[i]==close[i])
               BullishNoWickBuffer[i]=low[i];

         }


      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
