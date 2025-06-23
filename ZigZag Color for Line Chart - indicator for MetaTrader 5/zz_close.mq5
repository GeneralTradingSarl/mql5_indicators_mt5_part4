//+------------------------------------------------------------------+
//|                                                     ZZ_Close.mq5 |
//|                                       Copyright 2022, D4rk Ryd3r |
//|                                    https://twitter.com/DarkRyd3r |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, D4rk Ryd3r"
#property link      "https://twitter.com/DarkRyd3r"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 5
#property indicator_plots 1
#property description "ZigZag"
#property version   "1.00"


#property indicator_type1   DRAW_COLOR_ZIGZAG
#property indicator_label1  "ZigZag"
#property indicator_color1 clrDeepPink,clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

input uint ExtDepth=12;
int min_rates_total;

double LowestBuffer[];
double HighestBuffer[];
double ColorBuffer[];
double ZZLBuffer[];
double ZZHBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   min_rates_total=int(ExtDepth);
   SetIndexBuffer(0,LowestBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighestBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,ZZLBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ZZHBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   ArraySetAsSeries(LowestBuffer,true);
   ArraySetAsSeries(HighestBuffer,true);
   ArraySetAsSeries(ColorBuffer,true);
   ArraySetAsSeries(ZZLBuffer,true);
   ArraySetAsSeries(ZZHBuffer,true);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   string shortname;
   StringConcatenate(shortname,"ZZ_Close(ExtDepth=",ExtDepth,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
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
   if(rates_total<min_rates_total) return(0);
   int limit,climit,bar,curlowpos,curhighpos,pos;
   static int lasthighpos,lastlowpos;
   double curlow,curhigh,min,max;
   static double lasthigh,lastlow;
   
   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      limit=rates_total-min_rates_total; 
      climit=limit; 

      lasthighpos=limit;
      lastlowpos=limit;
      lastlow=close[limit];
      lasthigh=close[limit];
     }
   else
     {
      limit=rates_total-prev_calculated; 
      climit=limit+min_rates_total; 

      int lim=rates_total-prev_calculated;
      limit=lim+MathMax(lasthighpos,lastlowpos);
      lasthighpos+=lim;
      lastlowpos+=lim;
     }

   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);


   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- low
      LowestBuffer[bar]=NULL;
      ZZLBuffer[bar]=NULL;
      curlowpos=ArrayMinimum(close,bar,ExtDepth);
      curlow=close[curlowpos];
      if(lasthighpos>curlowpos)
        {
         ZZLBuffer[curlowpos]=curlow;
         min=999999999;
         pos=lasthighpos;
         for(int rrr=lasthighpos; rrr>=curlowpos; rrr--)
           {
            if(!ZZLBuffer[rrr]) continue;
            if(ZZLBuffer[rrr]<min)
              {
               min=ZZLBuffer[rrr];
               pos=rrr;
              }
            LowestBuffer[rrr]=NULL;
           }
         LowestBuffer[pos]=min;
        }
      lastlowpos=curlowpos;
      lastlow=curlow;

      //--- high
      HighestBuffer[bar]=NULL;
      ZZHBuffer[bar]=NULL;
      curhighpos=ArrayMaximum(close,bar,ExtDepth);
      curhigh=close[curhighpos];
      if(curhigh<=lasthigh) lasthigh=curhigh;
      else
        {
         if(lastlowpos>curhighpos)
           {
            ZZHBuffer[curhighpos]=curhigh;
            max=-999999999;
            pos=lastlowpos;
            for(int rrr=lastlowpos; rrr>=curhighpos; rrr--)
              {
               if(!ZZHBuffer[rrr]) continue;
               if(ZZHBuffer[rrr]>max)
                 {
                  max=ZZHBuffer[rrr];
                  pos=rrr;
                 }
               HighestBuffer[rrr]=NULL;
              }
            HighestBuffer[pos]=max;
           }
         lasthighpos       =  curhighpos;
         lasthigh          =  curhigh;
        }
     }

   for(bar=climit; bar>=0 && !IsStopped(); bar--)
     {
      max=HighestBuffer[bar];
      min=LowestBuffer[bar];

      if(!max && !min) ColorBuffer[bar]=ColorBuffer[bar+1];
      if(max && min)
        {
         if(ColorBuffer[bar+1]==0) ColorBuffer[bar]=1;
         else                      ColorBuffer[bar]=0;
        }

      if( max && !min) ColorBuffer[bar]=1;
      if(!max &&  min) ColorBuffer[bar]=0;
     }

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
