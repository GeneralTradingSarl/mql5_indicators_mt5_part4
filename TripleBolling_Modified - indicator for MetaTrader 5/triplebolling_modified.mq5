//+------------------------------------------------------------------+
//|                                                    TripleBolling |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright   "Snail000"
#property link        "https://login.mql5.com/ru/users/Snail000"
#property description "Modified by Rudinei Felipetto to accept full Bollinger params."
#property version     "2.00"

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7

#property indicator_label1  "Bollinger line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Bollinger line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label3  "Bollinger line"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label4  "Bollinger line"
#property indicator_type4   DRAW_LINE
#property indicator_color4  LightSalmon
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label5  "Bollinger line"
#property indicator_type5   DRAW_LINE
#property indicator_color5  LightSalmon
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
#property indicator_label6  "Bollinger line"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrYellow
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
#property indicator_label7  "Bollinger line"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrYellow
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1


//--- input parameters
input ENUM_TIMEFRAMES    timeframe=PERIOD_CURRENT;
input int                period=50;
input int                ma_shift=0;
input double             deviation=2.0;
input ENUM_APPLIED_PRICE price=PRICE_WEIGHTED;

//--- indicator buffers
double        MABuffer[];
double        Bolinger2h[];
double        Bolinger2l[];
double        Bolinger3h[];
double        Bolinger3l[];
double        Bolinger4h[];
double        Bolinger4l[];

double        eq;
int           ma_handle;
string symbol;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- indicator buffers mapping
   SetIndexBuffer(0,MABuffer,INDICATOR_DATA);

   SetIndexBuffer(1,Bolinger2h,INDICATOR_DATA);
   SetIndexBuffer(2,Bolinger2l,INDICATOR_DATA);
   SetIndexBuffer(3,Bolinger3h,INDICATOR_DATA);
   SetIndexBuffer(4,Bolinger3l,INDICATOR_DATA);
   SetIndexBuffer(5,Bolinger4h,INDICATOR_DATA);
   SetIndexBuffer(6,Bolinger4l,INDICATOR_DATA);

   IndicatorSetInteger(INDICATOR_DIGITS,5);
//   SetIndexBuffer(7,MABuffer2,INDICATOR_CALCULATIONS);

//---
   ma_handle=iBands(Symbol(),timeframe,period,ma_shift,deviation,price);
   return(0);
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
//--- check if all data calculated
   if(BarsCalculated(ma_handle)<rates_total) return(0);
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<=0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      //--- last value is always copied
      to_copy++;
     }
//--- try to copy
   CopyBuffer(ma_handle,0,0,to_copy,MABuffer);
   CopyBuffer(ma_handle,1,0,to_copy,Bolinger2h);
//--- calculate 
   for(int i=0;i<rates_total && !IsStopped();i++)
     {
      // BolingerBuffer[i]=StringToInteger(DoubleToString((MABuffer2[i]-MABuffer[i])*10000));
      eq=(Bolinger2h[i]-MABuffer[i]);
      Bolinger2l[i]=MABuffer[i]-eq;
      Bolinger3h[i]=MABuffer[i]+eq*1.5;
      Bolinger3l[i]=MABuffer[i]-eq*1.5;
      Bolinger4h[i]=MABuffer[i]+eq*2;
      Bolinger4l[i]=MABuffer[i]-eq*2;
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
