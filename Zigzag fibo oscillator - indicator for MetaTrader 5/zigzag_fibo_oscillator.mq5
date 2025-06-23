//+------------------------------------------------------------------+
//|                                      Zigzag Color Oscillator.mq5 |
//|                             Copyright 2000-2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2025, MetaQuotes Ltd. // advancements by phade 2025"
#property link      "https://www.mql5.com"
#property version   "1.02"

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   2

#property indicator_type1   DRAW_COLOR_ZIGZAG
#property indicator_color1  clrDodgerBlue, clrRed, clrGray
#property indicator_width1  2

#property indicator_type2   DRAW_COLOR_CANDLES
#property indicator_color2  clrDodgerBlue, clrRed, clrGray 
#property indicator_width2  1

enum EnZigZagStyle
 {
   Oscillator,
   HighLow
 };  

enum EnPriceType
 {
   PR_OPEN, // Open
   PR_CLOSE, // Close
   PR_HIGH, // High
   PR_LOW, // Low
   PR_WEIGHTED, // Weighted 
   PR_TYPICAL // Typical
 };

//--- input parameters
input int InpDepth    =12;  // Depth
input int InpDeviation=5;   // Deviation
input int InpBackstep =3;   // Back Step
input EnZigZagStyle zzStyle = HighLow; // Type of ZigZag
input bool useFibLevels = true; // Fibonacci Retracement Levels
input bool trackCurrentBar = true; // Track current price
input EnPriceType priceType = PR_OPEN; // Current price tracking
input long vol = 60; // Volume threshold (for unconfirmed leg color)
input double scaling_offset = 0.2; // Window scaling offset

//--- indicator buffers
double ZigzagPeakBuffer[];
double ZigzagBottomBuffer[];
double HighMapBuffer[];
double LowMapBuffer[];
double ColorBuffer[];

double opens[], closes[], highs[], lows[], candleColor[];

int ExtRecalc=3; // recounting's depth

enum EnSearchMode
  {
   Extremum=0, // searching for the first extremum
   Peak=1,     // searching for the next ZigZag peak
   Bottom=-1   // searching for the next ZigZag bottom
  };
  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
//--- indicator buffers mapping
   SetIndexBuffer(0,ZigzagPeakBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ZigzagBottomBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,opens,INDICATOR_DATA); 
   SetIndexBuffer(4,closes,INDICATOR_DATA); 
   SetIndexBuffer(5,highs,INDICATOR_DATA); 
   SetIndexBuffer(6,lows,INDICATOR_DATA); 
   SetIndexBuffer(7,candleColor,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(8,HighMapBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,LowMapBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- name for DataWindow and indicator subwindow label
   string short_name=StringFormat("ZigZag Oscillator (%d,%d,%d)",InpDepth,InpDeviation,InpBackstep);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   PlotIndexSetString(0,PLOT_LABEL,short_name);
//--- set an empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
               
   if(useFibLevels && zzStyle == HighLow){
   
      IndicatorSetInteger(INDICATOR_LEVELS, 7);  
   
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrGray);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 1, clrGray);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 2, clrGray);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 3, clrGray);  
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 4, clrGray);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 5, clrGray);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, 6, clrGray); 
   }
   else if(zzStyle == Oscillator){
   
     IndicatorSetInteger(INDICATOR_LEVELS, 0);  
   }
   
   if(!useFibLevels){
   
     IndicatorSetInteger(INDICATOR_LEVELS, 0);   
   }
 
   ChartNavigate(0, CHART_END);
}
//+------------------------------------------------------------------+
//| ZigZag calculation                                               |
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

   int start = (prev_calculated > 0) ? prev_calculated - 1 : 1;
   

   if(zzStyle == HighLow){  

      for(int i = start; i<rates_total-1; i++){
   
         opens[i] = open[i];
         closes[i] = close[i];
         highs[i] = high[i];
         lows[i] = low[i];
         
         if(open[i] < close[i]) candleColor[i] = 0;
            
         else if(open[i] > close[i]) candleColor[i] = 1;
            
         else candleColor[i] = 2;
      }
      
      for(int i = rates_total-50; i>=0; i--){
         
         opens[i] = EMPTY_VALUE;
         closes[i] = EMPTY_VALUE;
         highs[i] = EMPTY_VALUE;
         lows[i] = EMPTY_VALUE;
      }        
      
   }
   else{  
   
      for(int i = 0; i<rates_total; i++){
         
         opens[i] = EMPTY_VALUE;
         closes[i] = EMPTY_VALUE;
         highs[i] = EMPTY_VALUE;
         lows[i] = EMPTY_VALUE;
      }
   }

 
   zigzag(rates_total, prev_calculated, open, low, high, close);  

   return rates_total;
}
  
  
int zigzag(int rates_total, int prev_calculated, const double &open[], const double &low[], const double &high[], const double &close[]){

   if(rates_total < 100)
      return(0);

   int i, start = 0, extreme_counter = 0, extreme_search = Extremum;
   int shift, back = 0, last_high_pos = 0, last_low_pos = 0;
   double val = 0, res = 0;
   double cur_low = 0, cur_high = 0, last_high = 0, last_low = 0;

   // --- initializing
   if (prev_calculated == 0) {
      ArrayInitialize(ZigzagPeakBuffer, 0.0);
      ArrayInitialize(ZigzagBottomBuffer, 0.0);
      ArrayInitialize(HighMapBuffer, 0.0);
      ArrayInitialize(LowMapBuffer, 0.0);
      start = InpDepth - 1;            
   }
 
   // --- ZigZag was already calculated before
   if (prev_calculated > 0) {
   
      i = rates_total - 1;
              
      while (extreme_counter < ExtRecalc && i > rates_total - 100) {
         res = (ZigzagPeakBuffer[i] + ZigzagBottomBuffer[i]);
                 
         if (res != 0)
            extreme_counter++;
         i--;
      }
      i++;
      start = i;

      if (LowMapBuffer[i] != 0) {
         cur_low = LowMapBuffer[i];                 
         extreme_search = Peak;
      } else {
         cur_high = HighMapBuffer[i];                        
         extreme_search = Bottom;
      }

      // Clear indicator values
      for (i = start + 1; i < rates_total && !IsStopped(); i++) {
         ZigzagPeakBuffer[i] = 0.0;
         ZigzagBottomBuffer[i] = 0.0;
         LowMapBuffer[i] = 0.0;
         HighMapBuffer[i] = 0.0;
      }
   }
   
   // --- Searching for high and low extremes
   for (shift = start; shift < rates_total && !IsStopped(); shift++) {
      
      // --- Low
      val = Lowest(low, InpDepth, shift);
      if (val == last_low)
         val = 0.0;
      else {
         last_low = val;
         if ((low[shift] - val) > (InpDeviation * _Point))
            val = 0.0;
         else {
            for (back = InpBackstep; back >= 1; back--) {
               res = LowMapBuffer[shift - back];
               if ((res != 0) && (res > val))
                  LowMapBuffer[shift - back] = 0.0;
            }
         }
      }
      if (low[shift] == val)
         LowMapBuffer[shift] = val;
      else
         LowMapBuffer[shift] = 0.0;

      // --- High
      val = Highest(high, InpDepth, shift);
      if (val == last_high)
         val = 0.0;
      else {
         last_high = val;
         if ((val - high[shift]) > (InpDeviation * _Point))
            val = 0.0;
         else {
            for (back = InpBackstep; back >= 1; back--) {
               res = HighMapBuffer[shift - back];
               if ((res != 0) && (res < val))
                  HighMapBuffer[shift - back] = 0.0;
            }
         }
      }
      if (high[shift] == val)
         HighMapBuffer[shift] = val;
      else
         HighMapBuffer[shift] = 0.0;
   }

   // --- Set last values
   if (extreme_search == 0) {
      last_low = 0;
      last_high = 0;
   } else {
      last_low = cur_low;
      last_high = cur_high;
   }

   static double bufMax = -DBL_MAX;
   static double bufMin = DBL_MAX;
   
   static double legStart = 0.0;
   static double legEnd = 0.0;
   double range = 0.0;
             
   double adaptiveScalingOffset = (ChartGetDouble(0, CHART_PRICE_MAX, 1) - ChartGetDouble(0, CHART_PRICE_MIN, 1)) * scaling_offset;
   
   double price_range = 0;  
   double normalized_high = 0;
   double normalized_low = 0;   
   
   // --- Move Zigzag line progressively
   for (shift = start; shift < rates_total && !IsStopped(); shift++) {
      res = 0.0;
      
     if(bufMax < ZigzagPeakBuffer[shift])
         bufMax = ZigzagPeakBuffer[shift];
         
     if(bufMin > ZigzagBottomBuffer[shift])
         bufMin = ZigzagBottomBuffer[shift];  
     
      if(zzStyle == HighLow){   
      
         if (extreme_search == Peak){
         
             if (LowMapBuffer[shift] != 0.0 && LowMapBuffer[shift] < last_low && HighMapBuffer[shift] == 0.0) {
                 // New low found, update legStart and legEnd
                 legStart = last_high;  // Previous high
                 legEnd = LowMapBuffer[shift];  // Current low
                 if(useFibLevels) CalculateBullFibLevels(legStart, legEnd);

                 double maxLevel = legStart + adaptiveScalingOffset;
                 double minLevel = legEnd - adaptiveScalingOffset;
                 IndicatorSetDouble(INDICATOR_MAXIMUM, MathMax(maxLevel, legStart));  // Prevent overshooting
                 IndicatorSetDouble(INDICATOR_MINIMUM, MathMin(minLevel, legEnd));    // Prevent undershooting
             }
         
             if (HighMapBuffer[shift] != 0.0 && LowMapBuffer[shift] == 0.0) {
                 // New high found, update legStart and legEnd
                 legStart = last_low;  // Previous low
                 legEnd = HighMapBuffer[shift];  // Current high
                 if(useFibLevels) CalculateBearFibLevels(legStart, legEnd);
                       
                 double maxLevel = legEnd + adaptiveScalingOffset;
                 double minLevel = legStart - adaptiveScalingOffset;
                 IndicatorSetDouble(INDICATOR_MAXIMUM, MathMax(maxLevel, legEnd));  // Prevent overshooting
                 IndicatorSetDouble(INDICATOR_MINIMUM, MathMin(minLevel, legStart));  // Prevent undershooting
             }
         } 
         else if (extreme_search == Bottom){
         
             if (HighMapBuffer[shift] != 0.0 && HighMapBuffer[shift] > last_high && LowMapBuffer[shift] == 0.0) {
                 // New high found, update legStart and legEnd
                 legStart = last_low;  // Previous low
                 legEnd = HighMapBuffer[shift];  // Current high
                 if(useFibLevels) CalculateBearFibLevels(legStart, legEnd);
                 
                 double maxLevel = legEnd + adaptiveScalingOffset;
                 double minLevel = legStart - adaptiveScalingOffset;
                 IndicatorSetDouble(INDICATOR_MAXIMUM, MathMax(maxLevel, legEnd));  // Prevent overshooting
                 IndicatorSetDouble(INDICATOR_MINIMUM, MathMin(minLevel, legStart));  // Prevent undershooting
             }
         
             if (LowMapBuffer[shift] != 0.0 && HighMapBuffer[shift] == 0.0) {
                 // New low found, update legStart and legEnd
                 legStart = last_high;  // Previous high
                 legEnd = LowMapBuffer[shift];  // Current low
                 if(useFibLevels) CalculateBullFibLevels(legStart, legEnd);           
         
                 double maxLevel = legStart + adaptiveScalingOffset;
                 double minLevel = legEnd - adaptiveScalingOffset;
                 IndicatorSetDouble(INDICATOR_MAXIMUM, MathMax(maxLevel, legStart));  // Prevent overshooting
                 IndicatorSetDouble(INDICATOR_MINIMUM, MathMin(minLevel, legEnd));    // Prevent undershooting
             }
         }
      }


      switch (extreme_search) {
      
         case Extremum:
            if (last_low == 0 && last_high == 0) {
               if (HighMapBuffer[shift] != 0) {
                  last_high = high[shift];
                  last_high_pos = shift;
                  extreme_search = -1;
                  ColorBuffer[shift] = 0;
                  res = 1;
               }
               if (LowMapBuffer[shift] != 0) {
                  last_low = low[shift];
                  last_low_pos = shift;
                  extreme_search = 1;
                  ColorBuffer[shift] = 1;
                  res = 1;
               }
            }
            break;

         case Peak:
            if (LowMapBuffer[shift] != 0.0 && LowMapBuffer[shift] < last_low && HighMapBuffer[shift] == 0.0){
                               
               ZigzagBottomBuffer[last_low_pos] = 0.0;
               last_low_pos = shift;
               last_low = LowMapBuffer[shift];
               
               if(zzStyle == Oscillator)         
                  ZigzagBottomBuffer[shift] = Point();   // defining the new low  
              
               if(zzStyle == HighLow)
                  ZigzagBottomBuffer[shift] = last_low;   // defining the new low  
                          
               ColorBuffer[shift] = 1; 
               res = 1;
            }
                      
            if (HighMapBuffer[shift] != 0.0 && LowMapBuffer[shift] == 0.0){
               last_high = HighMapBuffer[shift];
               last_high_pos = shift;
               
               price_range = HighMapBuffer[shift] - LowMapBuffer[shift-1];
               normalized_high = (HighMapBuffer[shift] - LowMapBuffer[shift-1]) / price_range; 
                       
               if(zzStyle == Oscillator)
                  ZigzagPeakBuffer[shift] = normalized_high;   // defining the new high                 
               
               if(zzStyle == HighLow)
                  ZigzagPeakBuffer[shift] = last_high;  // defining the new high   
       
               ColorBuffer[shift] = 0;
               extreme_search = Bottom;
               res = 1;                  
            }
            break;

         case Bottom:
            if (HighMapBuffer[shift] != 0.0 && HighMapBuffer[shift] > last_high && LowMapBuffer[shift] == 0.0){
               ZigzagPeakBuffer[last_high_pos] = 0.0;
               last_high_pos = shift;
               last_high = HighMapBuffer[shift];
               
               price_range = HighMapBuffer[shift] - LowMapBuffer[shift-1];
               normalized_high = (HighMapBuffer[shift] - LowMapBuffer[shift-1]) / price_range; 

               if(zzStyle == Oscillator)
                  ZigzagPeakBuffer[shift] = normalized_high;  // defining the new high            
               
               if(zzStyle == HighLow)
                  ZigzagPeakBuffer[shift] = last_high;  // defining the new high
                  
                  
               ColorBuffer[shift] = 0;
            }

            if (LowMapBuffer[shift] != 0.0 && HighMapBuffer[shift] == 0.0){
               last_low = LowMapBuffer[shift];  // last low
               last_low_pos = shift;
               
               if(zzStyle == Oscillator)         
                  ZigzagBottomBuffer[shift] = Point();   // defining the new low  
              
               if(zzStyle == HighLow)
                  ZigzagBottomBuffer[shift] = last_low;   // defining the new low

               ColorBuffer[shift] = 1;
               extreme_search = Peak;             
            }
            break;

         default:
            return(rates_total);
      } 
   }
   
   int current_bar_index = rates_total-1;
   
   if(trackCurrentBar && current_bar_index != 0){
   
      if(zzStyle == HighLow){
         // Current leg price tracking
         ZigzagPeakBuffer[current_bar_index] = GetPrice(priceType, current_bar_index, open, high, low, close);
         ZigzagBottomBuffer[current_bar_index] = GetPrice(priceType, current_bar_index, open, high, low, close); 
      }  
      
      if(zzStyle == Oscillator){
      
         double pr_range = MathAbs(high[current_bar_index] - low[current_bar_index]); 
         double normalized_range = (high[current_bar_index] - MathMin(low[current_bar_index], high[current_bar_index])) / pr_range;
      
         ZigzagPeakBuffer[current_bar_index] = normalized_range;
         ZigzagBottomBuffer[current_bar_index] = normalized_range;
      }
        
      long currentVolume = iVolume(_Symbol, 0, 0);
      
      long volumeThreshold = vol;
   
      for (shift = start; shift < rates_total && !IsStopped(); shift++) {
       
         if(shift == rates_total - 1){
   
            if(extreme_search == Peak && close[shift] < open[shift]) 
               ColorBuffer[shift] = 2; 
           
            else if(extreme_search == Bottom && close[shift] > open[shift]) 
               ColorBuffer[shift] = 2;  
            
            // override color during high volume market conditions
            if(close[shift] > open[shift] && currentVolume >= volumeThreshold)
               ColorBuffer[shift] = 0;   // force bullish color 
               
            else if(close[shift] < open[shift] && currentVolume >= volumeThreshold)          
               ColorBuffer[shift] = 1;   // force bearish color               
                                     
         } 
       }  
   }
   
   if(zzStyle == Oscillator){
      
      IndicatorSetDouble(INDICATOR_MINIMUM, Point()-adaptiveScalingOffset);
      IndicatorSetDouble(INDICATOR_MAXIMUM, 1.0+adaptiveScalingOffset); 
   }
   
   return rates_total;
}

  
//+------------------------------------------------------------------+
//| Return the selected price type for a given bar                   |
//+------------------------------------------------------------------+
double GetPrice(EnPriceType type, int barIndex,
                const double &open[], 
                const double &high[], 
                const double &low[], 
                const double &close[])
  {
   switch(type)
   {
      case PR_OPEN: return open[barIndex];
      case PR_CLOSE: return close[barIndex];
      case PR_HIGH: return high[barIndex];
      case PR_LOW: return low[barIndex];
      case PR_WEIGHTED: return (high[barIndex] + low[barIndex] + close[barIndex] * 2.0) / 4.0;
      case PR_TYPICAL: return (high[barIndex] + low[barIndex] + close[barIndex]) / 3.0;
      default: 
         return 0.0;
   }
  }
  
//+------------------------------------------------------------------+
//| Get highest value for range                                      |
//+------------------------------------------------------------------+
double Highest(const double&array[],int count,int start)
  {
   double res=array[start];
//---
   for(int i=start-1; i>start-count && i>=0; i--)
      if(res<array[i])
         res=array[i];
//---
   return(res);
  }
  
//+------------------------------------------------------------------+
//| Get lowest value for range                                       |
//+------------------------------------------------------------------+
double Lowest(const double&array[],int count,int start)
  {
   double res=array[start];
//---
   for(int i=start-1; i>start-count && i>=0; i--)
      if(res>array[i])
         res=array[i];
//---
   return(res);
  }

//+------------------------------------------------------------------+
//| Calculate fibonacci levels for range                             |
//+------------------------------------------------------------------+
void CalculateBearFibLevels(double start, double end)
  {
    double range = MathAbs(end - start);
    
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, start);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, start + 0.236 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, start + 0.382 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 3, start + 0.5 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 4, start + 0.618 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 5, start + 0.764 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 6, end);
 }

//+------------------------------------------------------------------+
//| Calculate fibonacci levels for range                             |
//+------------------------------------------------------------------+
void CalculateBullFibLevels(double start, double end)
  {
    double range = MathAbs(start - end);
    
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, end);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, end + 0.236 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, end + 0.382 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 3, end + 0.5 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 4, end + 0.618 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 5, end + 0.764 * range);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 6, start);
 }


