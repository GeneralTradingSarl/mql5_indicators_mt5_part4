//+------------------------------------------------------------------+
//|                                               UPDN Volume MA.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots 3
#property indicator_color1 clrRed
#property indicator_color2 clrGreen
#property indicator_color3 clrSilver
#property indicator_width3 2

enum ENUM_MA_TYPE{
 sma=0, //SMA
 ema=1, //EMA
 smma=2, //SMMA
 lwma=3 //LWMA
};

// User input
input int MA_Period = 50;
input int MA_Shift = 0;
input ENUM_MA_TYPE MA_Method = 3;

// Buffers
double VolBuffer1[];  // value down
double VolBuffer2[];  // value up
double VolBuffer3[];  // moving average
//----
int ExtCountedBars=0;
int lastcolor=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   int    draw_begin;
   string short_name;
// indicator buffers mapping, drawing settings and Shift
// Histogram downArrow Red
   SetIndexBuffer(0,VolBuffer1);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);
   PlotIndexSetInteger(0,PLOT_SHIFT,MA_Shift);
// Histogram upArrow Green
   SetIndexBuffer(1,VolBuffer2);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_HISTOGRAM);
   PlotIndexSetInteger(1,PLOT_SHIFT,MA_Shift);
// Moving average line white
   SetIndexBuffer(2,VolBuffer3);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(2,PLOT_SHIFT,MA_Shift);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   draw_begin=MA_Period-1;
//----
   switch(MA_Method)
     {
      case 1  : short_name="UD Vol EMA"; draw_begin=0; break;
      case 2  : short_name="UD Vol SMMA";                break;
      case 3  : short_name="UD Vol LWMA";                break;
      default : short_name="UD Vol SMA";
     }
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+IntegerToString(MA_Period)+")");
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,draw_begin);

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
   if(rates_total<=MA_Period) return(rates_total);

   int start = (prev_calculated < MA_Period) ? MA_Period + 1 : prev_calculated - 1;
   
   for(int i = start; i<rates_total; i++)
    {
      switch(MA_Method)
       {
         case 0 : sma(tick_volume, open, close, i);  break;
         case 1 : ema(tick_volume, open, close, i);  break;
         case 2 : smma(tick_volume, open, close, i); break;
         case 3 : lwma(tick_volume, open, close, i); break;
         default: Print("Invalid MA_Method value: ", MA_Method); break;
       }

    }  
   return(rates_total);
  }
//+------------------------------------------------------------------+


void sma(const long &Volume[], const double &Open[], const double &Close[], int pos)
{
   double sum = 0;
   
   if (pos < MA_Period)
    {
      VolBuffer3[pos] = 0;
    }     
   // Initial accumulation
   if (pos < MA_Period) pos = MA_Period;
   for (int i = 1; i < MA_Period && (pos - i) > 0; i++)
      sum += (double)Volume[pos - i];

   VolBuffer3[pos] = sum / MA_Period;
   Vcolor(pos, Open, Close, Volume);
}


void ema(const long &Volume[], const double &Open[], const double &Close[], int pos)
{
   if (pos < MA_Period)
    {
      VolBuffer3[pos] = 0;
    }

   double alpha = 2.0 / (MA_Period + 1);

   VolBuffer3[pos] = (Volume[pos] * alpha) + (VolBuffer3[pos - 1] * (1 - alpha));
   Vcolor(pos, Open, Close, Volume);
}

void smma(const long &Volume[], const double &Open[], const double &Close[], int pos)
{
   if (pos < MA_Period)
    {
      VolBuffer3[pos] = 0;
    }

   if (pos == MA_Period)  // Initial SMMA setup
    {
      double sum = 0;
      for (int i = 0; i < MA_Period; i++)
         sum += (double)Volume[pos - i];

      VolBuffer3[pos] = sum / MA_Period;
    }
   else
    {
      VolBuffer3[pos] = ((VolBuffer3[pos - 1] * (MA_Period - 1)) + Volume[pos]) / MA_Period;
    }

   Vcolor(pos, Open, Close, Volume);
}

void lwma(const long &Volume[], const double &Open[], const double &Close[], int pos)
{
   if (pos < MA_Period)
    {
      VolBuffer3[pos] = 0;
    }

   double sum = 0, weighted_sum = 0;

   for (int i = 0; i < MA_Period; i++)
    {
      sum += (double)Volume[pos - i] * (MA_Period - i);
      weighted_sum += (MA_Period - i);
    }

   VolBuffer3[pos] = sum / weighted_sum;

   Vcolor(pos, Open, Close, Volume);
}

//+------------------------------------------------------------------+
//| Color depends on Candle up or Candle down                        |
//+------------------------------------------------------------------+
// 1 - candle down red
// 2 - candle up green
void Vcolor(int p, const double &Open[], const double &Close[], const long &Volume[])
  {
   if(Close[p]<Open[p])
     {
      VolBuffer1[p]=(double)Volume[p];
      VolBuffer2[p]=0.0;
      lastcolor=Red;
     }
   if(Close[p]>=Open[p])
     {
      VolBuffer1[p]=0.0;
      VolBuffer2[p]=(double)Volume[p];
      lastcolor=Green;
     }
  }
