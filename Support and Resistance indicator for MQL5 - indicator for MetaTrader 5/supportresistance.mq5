//+------------------------------------------------------------------+
//|                                                          Box.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mueller Peter"
#property link      "https://www.mql5.com/en/users/mullerp04"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_label1 "Support"
#property indicator_label2 "Resistance"
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_color1 clrRed
#property indicator_color2 clrGreen
#property indicator_width1 2
#property indicator_width2 2
input int period = 20; //The period of the indicator
input int overlook =  10; //The overlook of period

bool Box = false;
double ResBuffer[];
double SuppBuffer[];

double Resistance(int starting, const double &high[])  //The resistance calculation function
{
      double high1 = high[ArrayMaximum(high,starting,period)];
      double high2 = high[ArrayMaximum(high,starting ,period + overlook)];
      if (high1 == high2) return high1;
      else return 0;
}

double Support(int starting, const double &low[])   // Support calculation
{
      double low1 = low[ArrayMinimum(low,starting,period)];
      double low2 = low[ArrayMinimum(low,starting,period + overlook)];
      if (low1 == low2) return low1;
      else return 0;
}

int OnInit()
   {
   SetIndexBuffer(0,ResBuffer);        // Initialising buffers
   SetIndexBuffer(1,SuppBuffer);
   int Start = (int) MathMax(period,overlook);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,Start);      
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,Start);
   ArraySetAsSeries(ResBuffer,false);
   ArraySetAsSeries(SuppBuffer,false);
   return(INIT_SUCCEEDED);
  }
  
  
bool IsNewCandle()
  {
   static datetime saved_candle_time;
   if(iTime(Symbol(),PERIOD_CURRENT,0) == saved_candle_time)
      return false;
   else
      saved_candle_time = iTime(Symbol(),PERIOD_CURRENT,0);
   return true;
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
   if(IsStopped())
         return 0;
   int i;
   double Savedmin = 0.0, Savedmax = 0.0;
   ArraySetAsSeries(ResBuffer,false);     // The indicator itself will go from last bar to first bar(we have to check "past bars" in order to calculate properly)
   ArraySetAsSeries(SuppBuffer,false);    // --> Buffers will not be series
   ArraySetAsSeries(high,true);     // high and low have to be series arrays so that they can be passed down to Support and Resistance functions
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(open,true);
   if((rates_total<= period + overlook) || (period <= 0) || (overlook < 0))
      return(0);
   for(i = 0; i < period+overlook;i++)
   {
       SuppBuffer[i] = EMPTY_VALUE;
       ResBuffer[i] = EMPTY_VALUE;
   }
   i = MathMax(period+overlook, rates_total-3000);
   for(i; i<rates_total; i++)
      { 
      bool BounceUp = (Support(rates_total-i,high)*3 + Resistance(rates_total-i,high))/4 < close[rates_total-i];     //bounceup check
      bool BounceBack = (Support(rates_total-i,low) + Resistance(rates_total-i,low)*3)/4 > close[rates_total-i]; //bounceback check
      if ((Support(rates_total-i,low) != NULL) && (Resistance(rates_total-i,high) != NULL) && !Box && BounceBack && BounceUp) // checking wether we should start displaying the levels
      {
         SuppBuffer[i] = Support(rates_total-i,low);
         ResBuffer[i] = Resistance(rates_total-i,high);
         Savedmin = Support(rates_total-i,low);
         Savedmax = Resistance(rates_total-i,high);
         Box = true;
      }
      else if ((low[rates_total-i] > Savedmin) && (high[rates_total-i] < Savedmax) && Box) // if there are levels displayed and there were no breakouts we will still display the levels
         { 
            SuppBuffer[i] = Savedmin;
            ResBuffer[i] = Savedmax;
            Box = true;
         }    
      
      else // If there is nothing to display
         {
         SuppBuffer[i] = EMPTY_VALUE;
         ResBuffer[i] = EMPTY_VALUE;
         Box = false;   
         } 
      }
   return(rates_total);
  }
//+------------------------------------------------------------------