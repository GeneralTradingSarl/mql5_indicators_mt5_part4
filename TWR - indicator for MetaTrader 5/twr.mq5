//+------------------------------------------------------------------+
//|                                                          TWR.mq5 |
//|                  Copyright 2018, MetaQuotes Software Corp.Jianye |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp.Jianye"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   3
#include <MovingAverages.mqh>
//--- plot RiseBar
#property indicator_label1  "T1 Open;T1 Close"
#property indicator_type1   DRAW_COLOR_HISTOGRAM2
#property indicator_style1  STYLE_SOLID
#property indicator_width1  8

#property indicator_label2  "T2 Open;T2 Close"
#property indicator_type2   DRAW_COLOR_HISTOGRAM2
#property indicator_style2  STYLE_SOLID
#property indicator_width2  8

#property indicator_label3  "T Ema"
#property indicator_type3   DRAW_LINE
#property indicator_style3  STYLE_SOLID
#property indicator_color3  clrBlue
#property indicator_width3  1

//--- input parameters
input int      EmaPeriod=12;
//--- indicator buffers
int hema;
double         BarBuffer1[];                          
double         BarBuffer2[];
double         ColorBuffer[];
double         SignalBuffer[];
double         turn1[];
double         turn2[];
double         turn_color[]; 
double         EmaBuffer[]; 
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BarBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,BarBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,turn1,INDICATOR_DATA);
   SetIndexBuffer(4,turn2,INDICATOR_DATA); 
   SetIndexBuffer(5,turn_color,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,EmaBuffer,INDICATOR_DATA); 
   SetIndexBuffer(7,SignalBuffer,INDICATOR_CALCULATIONS);
     
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,2);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,clrRed);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,clrGreen);
   
   PlotIndexSetInteger(1,PLOT_COLOR_INDEXES,2);
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,0,clrRed);
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,1,clrGreen);
   
   hema=iMA(Symbol(),0,EmaPeriod,0,MODE_EMA,PRICE_CLOSE);
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
   CopyBuffer(hema,0,0,rates_total,EmaBuffer);
   int start;
   start=prev_calculated;
   if(prev_calculated==0)
     {
      BarBuffer1[0]=open[0];
      BarBuffer2[0]=close[0];
      turn1[0]=BarBuffer1[0];
      turn2[0]=BarBuffer2[0];
      if(close[0]>=open[0])
        {
         SignalBuffer[0]=0;
         ColorBuffer[0]=0; 
         turn_color[0]=0;
        }
      else
        {
         SignalBuffer[0]=1;
         ColorBuffer[0]=1;
         turn_color[0]=1;
        }  
      start=1;  
     }

   for(int i=start;i<rates_total;i++)
     {
      if(SignalBuffer[i-1]==0)
        {
         if(BarBuffer1[i-1]<=BarBuffer2[i-1])
           {
            BarBuffer1[i]=BarBuffer2[i-1];
            BarBuffer2[i]=close[i];
            turn1[i]=BarBuffer1[i];
            turn2[i]=BarBuffer2[i];
            if(close[i]>=BarBuffer1[i-1])
              {
               SignalBuffer[i]=0; 
               ColorBuffer[i]=0;
               turn_color[i]=0;
              }
            if(close[i]<BarBuffer1[i-1])
              {
               SignalBuffer[i]=1;
               ColorBuffer[i]=0;
               turn1[i]=BarBuffer1[i-1];
               turn_color[i]=1;
              }  
           }
         if(BarBuffer1[i-1]>BarBuffer2[i-1])
           {
            if(close[i]>=BarBuffer1[i-1])
              {
               BarBuffer1[i]=BarBuffer2[i-1];
               BarBuffer2[i]=close[i];   
               turn1[i]=BarBuffer1[i];
               turn2[i]=BarBuffer2[i];      
               SignalBuffer[i]=0; 
               ColorBuffer[i]=0;
               turn_color[i]=0;
              }
            if(close[i]<BarBuffer1[i-1] && close[i]>=BarBuffer2[i-1])
              {
               BarBuffer1[i]=BarBuffer1[i-1];
               BarBuffer2[i]=close[i];  
               turn1[i]=BarBuffer1[i];
               turn2[i]=BarBuffer2[i];            
               SignalBuffer[i]=0; 
               ColorBuffer[i]=0;
               turn_color[i]=0;
              }  
            if(close[i]<BarBuffer2[i-1])
              {
               BarBuffer1[i]=BarBuffer1[i-1];
               BarBuffer2[i]=close[i]; 
               turn1[i]=BarBuffer2[i-1];
               turn2[i]=BarBuffer2[i];
               SignalBuffer[i]=1;
               ColorBuffer[i]=0;
               turn_color[i]=1;
              }  
           }  
           
        } 
      if(SignalBuffer[i-1]==1)
        {
         if(BarBuffer1[i-1]>=BarBuffer2[i-1])
           {
            BarBuffer1[i]=BarBuffer2[i-1];
            BarBuffer2[i]=close[i];
            turn1[i]=BarBuffer1[i];
            turn2[i]=BarBuffer2[i];
            if(close[i]<=BarBuffer1[i-1])
              {
               SignalBuffer[i]=1; 
               ColorBuffer[i]=1;
               turn_color[i]=1;
              }
            if(close[i]>BarBuffer1[i-1])
              {
               SignalBuffer[i]=0; 
               ColorBuffer[i]=1;
               turn1[i]=BarBuffer1[i-1];
               turn_color[i]=0;
              }  
           }
         if(BarBuffer1[i-1]<BarBuffer2[i-1])
           {
            if(close[i]<=BarBuffer1[i-1])
              {
               BarBuffer1[i]=BarBuffer2[i-1];
               BarBuffer2[i]=close[i];
               turn1[i]=BarBuffer1[i];
               turn2[i]=BarBuffer2[i];
               SignalBuffer[i]=1;
               ColorBuffer[i]=1;
               turn_color[i]=1;
              }
            if(close[i]>BarBuffer1[i-1] && close[i]<=BarBuffer2[i-1])
              {
               BarBuffer1[i]=BarBuffer1[i-1];
               BarBuffer2[i]=close[i];
               turn1[i]=BarBuffer1[i];
               turn2[i]=BarBuffer2[i];
               SignalBuffer[i]=1;
               ColorBuffer[i]=1;
               turn_color[i]=1;
              }  
            if(close[i]>BarBuffer2[i-1])
              {
               BarBuffer1[i]=BarBuffer1[i-1];
               BarBuffer2[i]=close[i];
               turn1[i]=BarBuffer2[i-1];
               turn2[i]=BarBuffer2[i];
               SignalBuffer[i]=0;
               ColorBuffer[i]=1;
               turn_color[i]=0;
              }  
           }  
        }  
     }
      
//--- return value of prev_calculated for next call
   return(rates_total-1);
  }
//+------------------------------------------------------------------+
