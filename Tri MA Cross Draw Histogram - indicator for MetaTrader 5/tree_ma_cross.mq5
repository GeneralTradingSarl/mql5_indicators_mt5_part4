//+------------------------------------------------------------------+
//|                                                Tree MA Cross.mq5 |
//|                                                        Submarine |
//|                                      WeChart:ExpertAdvisorTrader |
//+------------------------------------------------------------------+
#property copyright "Submarine"
#property link      "WeChart:ExpertAdvisorTrader"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   5
//--- plot FastMA
#property indicator_label1  "FastMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot MidMA
#property indicator_label2  "MidMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot SLowMA
#property indicator_label3  "SLowMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot Long
#property indicator_label4  "Long"
#property indicator_type4   DRAW_HISTOGRAM2
#property indicator_color4  clrGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot Show
#property indicator_label5  "Show"
#property indicator_type5   DRAW_HISTOGRAM2
#property indicator_color5  clrRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

//--- indicator buffers
double         FastMABuffer[];
double         MidMABuffer[];
double         SlowMABuffer[];
double         LongBuffer1[];
double         LongBuffer2[];
double         ShowBuffer1[];
double         ShowBuffer2[];


//--- input Fast iMA parameters
input string             CommandFM            = "=====Fast_MA Paramater=====";
input ENUM_TIMEFRAMES    FastMA_timeframe     = 0;
input int                FastMA_period        = 50;
input int                FastMA_shift         = 0;
input ENUM_MA_METHOD     FastMA_method        = 0;
input ENUM_APPLIED_PRICE FastMA_applied_price = PRICE_CLOSE;

//--- input Slow iMA parameters
input string             CommandMM            = "=====Mid_MA Paramater=====";
input ENUM_TIMEFRAMES    MidMA_timeframe     = 0;
input int                MidMA_period        = 100;
input int                MidMA_shift         = 0;
input ENUM_MA_METHOD     MidMA_method        = 0;
input ENUM_APPLIED_PRICE MidMA_applied_price = PRICE_CLOSE;

//--- input Slow iMA parameters
input string             CommandSM            = "=====Slow_MA Paramater=====";
input ENUM_TIMEFRAMES    SlowMA_timeframe     = 0;
input int                SlowMA_period        = 200;
input int                SlowMA_shift         = 0;
input ENUM_MA_METHOD     SlowMA_method        = 0;
input ENUM_APPLIED_PRICE SlowMA_applied_price = PRICE_CLOSE;

int FastShift;
int MidShift;
int SlowShift;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,FastMABuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MidMABuffer,INDICATOR_DATA);
   SetIndexBuffer(2,SlowMABuffer,INDICATOR_DATA);
   SetIndexBuffer(3,LongBuffer1,INDICATOR_DATA);
   SetIndexBuffer(4,LongBuffer2,INDICATOR_DATA);
   SetIndexBuffer(5,ShowBuffer1,INDICATOR_DATA);
   SetIndexBuffer(6,ShowBuffer2,INDICATOR_DATA);
   
   FastShift=iMA(NULL,FastMA_timeframe,FastMA_period,FastMA_shift,FastMA_method,FastMA_applied_price);
   MidShift=iMA(NULL,MidMA_timeframe ,MidMA_period ,MidMA_shift ,MidMA_method ,MidMA_applied_price);
   SlowShift=iMA(NULL,SlowMA_timeframe,SlowMA_period,SlowMA_shift,SlowMA_method,SlowMA_applied_price);
   
   
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
   if(CopyBuffer(FastShift,0,0,rates_total,FastMABuffer)<=0)
      return(0);
      
   if(CopyBuffer(MidShift,0,0,rates_total,MidMABuffer)<=0)
      return(0);
      
   if(CopyBuffer(SlowShift,0,0,rates_total,SlowMABuffer)<=0)
      return(0);
      
   int start=100;
   if(prev_calculated>0)
      start=prev_calculated-1;
   for(int i=start; i<rates_total; i++)
      {
       
       if(FastMABuffer[i]>=MidMABuffer[i] && MidMABuffer[i]>=SlowMABuffer[i])
         {
          LongBuffer1[i]=FastMABuffer[i];
          LongBuffer2[i]=SlowMABuffer[i];
          ShowBuffer1[i]=0;
          ShowBuffer2[i]=0;
         }
       
       if(FastMABuffer[i]<=MidMABuffer[i] && MidMABuffer[i]<=SlowMABuffer[i])
         {
       
          ShowBuffer1[i]=SlowMABuffer[i];
          ShowBuffer2[i]=FastMABuffer[i];
          LongBuffer1[i]=0;
          LongBuffer2[i]=0;
          
         }
         
      }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
