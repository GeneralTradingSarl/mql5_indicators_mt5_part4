//+------------------------------------------------------------------+
//|                                                      Swings.mq5 |
//|                                      Rajesh Nait, Copyright 2023 |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Rajesh Nait, Copyright 2023"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot Bullish Marubozu
#property indicator_label1  "+S"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrSnow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Bearish Marubozu
#property indicator_label2  "-S"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrSnow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- input parameters
input group             "Swing Low"
uchar               InpSwingLowCode              = 110;         // Swing Low: code for style DRAW_ARROW (font Wingdings)
int                 InpSwingLowShift             = 10;          // Swing Low: vertical shift of arrows in pixels
input group             "Swing High"
uchar               InpSwingHighCode          = 110;            // SwingHigh: code for style DRAW_ARROW (font Wingdings)
int                 InpSwingHighShift         =10;              // SwingHigh: vertical shift of arrows in pixels
//--- indicator buffers
double   SwingLowBuffer[];
double   SwingHighBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
//--- indicator buffers mapping
   SetIndexBuffer(0,SwingLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SwingHighBuffer,INDICATOR_DATA);

   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,InpSwingLowCode);
   PlotIndexSetInteger(1,PLOT_ARROW,InpSwingHighCode);
//--- set the vertical shift of arrows in pixels
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,InpSwingLowShift);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-InpSwingHighShift);
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
   if(prev_calculated==0)
      limit=2;

   for(int i=limit; i<rates_total-2; i++) {
      SwingLowBuffer[i]=0.0;
      SwingHighBuffer[i]=0.0;
      if(i>0) {
         SwingHighBuffer[0]=EMPTY_VALUE;
         if(high[i+2]<high[i+1] && high[i+1]<high[i])
            if(high[i]>high[i-1] && high[i-1]>high[i-2])
               SwingHighBuffer[i]=high[i];

         SwingLowBuffer[0]=EMPTY_VALUE;
         if(low[i+2]>low[i+1] && low[i+1]>low[i])
            if(low[i]<low[i-1] && low[i-1]<low[i-2])
               SwingLowBuffer[i]=low[i];
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
