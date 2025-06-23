//+------------------------------------------------------------------+
//|                                               TrendLinearReg.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 2
#property indicator_plots 2
#property indicator_color1 LimeGreen
#property indicator_type1 DRAW_HISTOGRAM
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_color2 Red
#property indicator_type2 DRAW_HISTOGRAM
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

extern int barsToCount=34;    // Bars to calculate

double     buffer0[];
double     buffer1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,buffer0);
   SetIndexBuffer(1,buffer1);
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

   double  b, c, sumy, sumx, sumxy, sumx2;
   double  prev;
   double  current;

   if(rates_total <= barsToCount)
      return rates_total;

   int start = prev_calculated;
   if(prev_calculated < barsToCount)
      start = barsToCount;

   for(int index = start; index < rates_total; index++)
     {

      sumy=0.0;
      sumx=0.0;
      sumxy=0.0;
      sumx2=0.0;
      for(int i=0; i < barsToCount ; i++)
        {
         sumy+=close[index-i];
         sumxy+=close[index-i]*(1+i);
         sumx+=(1+i);
         sumx2+=(1+i)*(1+i);
        }

      c=sumx2*barsToCount-sumx*sumx;

      if(c==0)
         c=0.1;

      b=(sumxy*barsToCount-sumx*sumy)/c;

      current=-1000*b;
      prev=current;


      if(buffer1[index-1] !=EMPTY_VALUE)
         prev=buffer1[index-1];
      else
         if(buffer0[index-1] !=EMPTY_VALUE)
            prev=buffer0[index-1];

      if(current>=prev)
        {
         buffer0[index]= current;
         buffer1[index]= EMPTY_VALUE;
        }
      else
         if(current<prev)
           {
            buffer1[index]= current;
            buffer0[index]= EMPTY_VALUE;
           }
      /*
            */
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
