//+------------------------------------------------------------------+
//|                                                     WmiFor35.mq5 |
//|                        Copyright (c) 2012-2019, wmlab, Marketeer |
//|                          https://www.mql5.com/en/users/wmlab     |
//|                          https://www.mql5.com/en/users/marketeer |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019 (c) Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "3.5"
#property description "Forecasting indicator based on WmiFor30 for MetaTrader 4\n"
#property description "Originally developed by Murad Ismayilov (wmlab@hotmail.com, https://www.mql5.com/en/users/wmlab)."


#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots 5

#property indicator_style1 STYLE_DOT
#property indicator_width1 1
#property indicator_color1 Sienna
 
#property indicator_style2 STYLE_DOT
#property indicator_width2 1
#property indicator_color2 Sienna

#property indicator_style3 STYLE_SOLID
#property indicator_width3 2
#property indicator_color3 Sienna

#property indicator_style4 STYLE_SOLID
#property indicator_width4 2
#property indicator_color4 DarkKhaki

#property indicator_style5 STYLE_SOLID
#property indicator_width5 3
#property indicator_color5 DodgerBlue
 
#property indicator_style6 STYLE_SOLID
#property indicator_width6 3
#property indicator_color6 DodgerBlue
 
#property indicator_style7 STYLE_SOLID
#property indicator_width7 1
#property indicator_color7 DodgerBlue
 
#property indicator_style8 STYLE_SOLID
#property indicator_width8 1
#property indicator_color8 DodgerBlue

 
#include <MT4Bridge/ind4to5.mqh>
#include <MT4Bridge/MT4time.mqh>
#include <MT4Bridge/MT4MarketInfo.mqh>
 
// Input parameters
 
input bool IsTopCorner = true; /*IsTopCorner*/ // Info panel in upper corner
input int _OffsetInBars = 1; /*OffsetInBars*/ // Offset backward in bars (to check forecast) [1..]
input bool IsOffsetStartFixed = false; /*IsOffsetStartFixed*/ // Fixed offset of the start of the pattern
input bool IsOffsetEndFixed = false; /*IsOffsetEndFixed*/ // Fixed offset of the end of the pattern
input int _PastInBars = 12; /*PastInBars*/ // Length of the pattern to search (in bars) [3..]
input int _VarShiftInBars = 4; /*VarShiftInBars*/ // Variation of the found candidates' length (in bars) [0..]
input int _ForecastInBars = 4; /*ForecastInBars*/ // Forecast bars [1..]
input int MaxAgeInDays = 365; /*MaxAgeInDays*/ // Maximal history age to search (in days) [1..]
input double MaxVarInPercents = 95; /*MaxVarInPercents*/ // Maximal allowed tolerance in candidates (%) [0..100]
input int MaxAlts = 10; /*MaxAlts*/ // Maximal number of candidates to find [1..]
input bool ShowPastAverage = true; /*ShowPastAverage*/ // Show average from history
input bool ShowForecastAverage = true; /*ShowForecastAverage*/ // Show average forecast
input bool ShowBestPattern = false; /*ShowBestPattern*/ // Show the best candidate (disables average)
input bool ShowTip = true; /*ShowTip*/ // Show trading tip
input color IndicatorPastAverageColor = DarkKhaki; /*IndicatorPastAverageColor*/ // Color of the average line on history
input color IndicatorCloudColor = Orange; /*IndicatorCloudColor*/ // Color of the range of candidates (high and low)
input color IndicatorBestPatternColor = DodgerBlue; /*IndicatorBestPatternColor*/ // Color of the best candidate
input color IndicatorVLinesColor = Orange; /*IndicatorVLinesColor*/ // Color of vertical boundaries of the pattern
input color IndicatorTextColor = DodgerBlue; /*IndicatorTextColor*/ // Color of the info panel
input color IndicatorTakeProfitColor = Crimson; /*IndicatorTakeProfitColor*/ // TakeProfit and StopLoss color
input int XCorner = 5; /*XCorner*/ // Margin from left/right borders of the chart
input int YCorner = 5; /*YCorner*/ // Margin from upper/lower borders of the chart

 
// Global variables
 
string IndicatorName = "WmiFor";
string IndicatorVersion = "3.5";
bool Debug = true;
datetime OffsetStart, OffsetEnd;
bool IsRedraw;
datetime LastRedraw;
double PastAverage[];
double ForecastCloudHigh[];
double ForecastCloudLow[];
double ForecastCloudAverage[];
double ForecastBestPatternOpen[];
double ForecastBestPatternClose[];
double ForecastBestPatternHigh[];
double ForecastBestPatternLow[];

int OffsetInBars, PastInBars, ForecastInBars, VarShiftInBars;

#define MEGA_VALUE 1000000.0
#define NO_HIGH    -MEGA_VALUE
#define NO_LOW     +MEGA_VALUE

 
//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
 
int OnInit()
{
   OffsetInBars = _OffsetInBars;
   PastInBars = _PastInBars;
   ForecastInBars = _ForecastInBars;
   VarShiftInBars = _VarShiftInBars;

   if (OffsetInBars < 1)
   {
      OffsetInBars = 1;
   }
   
   if (PastInBars < 3)
   {
      PastInBars = 3;
   }   
   
   if (ForecastInBars < 1)
   {
      ForecastInBars = 1;
   }
   
   if (VarShiftInBars < 0)
   {
      VarShiftInBars = 0;
   }
   
   SetIndexBuffer(0, ForecastCloudHigh);
   SetIndexStyle(0, DRAW_LINE, EMPTY, EMPTY, IndicatorCloudColor);
   SetIndexShift(0, ForecastInBars - OffsetInBars);
   
   SetIndexBuffer(1, ForecastCloudLow);
   SetIndexStyle(1, DRAW_LINE, EMPTY, EMPTY, IndicatorCloudColor);
   SetIndexShift(1, ForecastInBars - OffsetInBars);
   
   SetIndexBuffer(2, ForecastCloudAverage);
   SetIndexStyle(2, DRAW_LINE, EMPTY, EMPTY, IndicatorCloudColor);
   SetIndexShift(2, ForecastInBars - OffsetInBars);          
         
   SetIndexBuffer(3, PastAverage);
   SetIndexStyle(3, DRAW_LINE, EMPTY, EMPTY, IndicatorPastAverageColor);
   SetIndexShift(3, ForecastInBars - OffsetInBars);

   SetIndexStyle(4, DRAW_BARS, STYLE_SOLID, EMPTY, IndicatorBestPatternColor);
   
   SetIndexBuffer(4, ForecastBestPatternOpen);
   SetIndexShift(4, ForecastInBars - OffsetInBars);
   SetIndexBuffer(5, ForecastBestPatternHigh);
   SetIndexBuffer(6, ForecastBestPatternLow);
   SetIndexBuffer(7, ForecastBestPatternClose);
 
   RemoveOurObjects();
   
   IsRedraw = true;
   
   if(!MQLInfoInteger(MQL_TESTER)) EventSetTimer(1);
   
   return INIT_SUCCEEDED;
}
 
//+------------------------------------------------------------------+
//| Deinit                                                           |
//+------------------------------------------------------------------+
 
void OnDeinit(const int r)
{
   RemoveOurObjects();
   ChartRedraw();
}
 
//+------------------------------------------------------------------+
//| Main                                                             |
//+------------------------------------------------------------------+

void OnTimer()
{
   double dummy[];
   OnCalculate(0, 0, 0, dummy);
}

int OnCalculate(const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[])
{
   if (IsRedraw)
   {
      ArrayInitialize(PastAverage, EMPTY_VALUE);
      ArrayInitialize(ForecastCloudHigh, EMPTY_VALUE);
      ArrayInitialize(ForecastCloudLow, EMPTY_VALUE);
      ArrayInitialize(ForecastCloudAverage, EMPTY_VALUE);
      ArrayInitialize(ForecastBestPatternOpen, EMPTY_VALUE);
      ArrayInitialize(ForecastBestPatternClose, EMPTY_VALUE);
      ArrayInitialize(ForecastBestPatternHigh, EMPTY_VALUE);
      ArrayInitialize(ForecastBestPatternLow, EMPTY_VALUE);

      ReCalculate();
   }
   
   // Check for vertical lines
   
   datetime time1;
   const string vlineOffsetStart = IndicatorName + "OffsetStart";
   if (ObjectFind(vlineOffsetStart) == -1)
   {
      time1 = iTime(NULL, 0, OffsetInBars + PastInBars - 1);
      ObjectCreate(vlineOffsetStart, OBJ_VLINE, 0, time1, 0);
      ObjectSetText(vlineOffsetStart, IndicatorName + ": Begin", 0);
      ObjectSet(vlineOffsetStart, OBJPROP_COLOR, IndicatorVLinesColor);
      ObjectSet(vlineOffsetStart, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet(vlineOffsetStart, OBJPROP_WIDTH, 1);
      ObjectSet(vlineOffsetStart, OBJPROP_SELECTABLE, true);
   }
   
   const string vlineOffsetEnd = IndicatorName + "OffsetEnd";
   if (ObjectFind(vlineOffsetEnd) == -1)
   {
      time1 = iTime(NULL, 0, OffsetInBars);
      ObjectCreate(vlineOffsetEnd, OBJ_VLINE, 0, time1, 0);
      ObjectSetText(vlineOffsetEnd, IndicatorName + ": End", 0);
      ObjectSet(vlineOffsetEnd, OBJPROP_COLOR, IndicatorVLinesColor);
      ObjectSet(vlineOffsetEnd, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet(vlineOffsetEnd, OBJPROP_WIDTH, 1);
      ObjectSet(vlineOffsetEnd, OBJPROP_SELECTABLE, true);
   }
   
   datetime datetimeOffsetStart = (datetime)ObjectGet(vlineOffsetStart, OBJPROP_TIME1);
   int indexOffsetStart = iBarShift(Symbol(), 0, datetimeOffsetStart);
   datetime datetimeOffsetEnd = (datetime)ObjectGet(vlineOffsetEnd, OBJPROP_TIME1);
   int indexOffsetEnd = iBarShift(Symbol(), 0, datetimeOffsetEnd);
   
   // Check for correct placement of the lines
   
   if (indexOffsetEnd < 1)
   {
      indexOffsetEnd  = 1;
      datetimeOffsetEnd = iTime(NULL, 0, indexOffsetEnd);
      ObjectSet(vlineOffsetEnd, OBJPROP_TIME1, datetimeOffsetEnd);
      ChangeOffset(1);
   }
      
   if ((indexOffsetStart - indexOffsetEnd + 1) < 3)
   {
      indexOffsetStart = indexOffsetEnd + 2;
      PastInBars = 3;
      datetimeOffsetStart = iTime(NULL, 0, indexOffsetStart);
      ObjectSet(vlineOffsetStart, OBJPROP_TIME1, datetimeOffsetStart);
   }
   
   if (datetimeOffsetEnd != OffsetEnd)
   {
      ChangeOffset(indexOffsetEnd);
   }
   
   if ((indexOffsetStart - indexOffsetEnd + 1) != PastInBars)
   {
      PastInBars = indexOffsetStart - indexOffsetEnd + 1;
   }
   
   if (IsNewBar())
   {
      if (!IsOffsetStartFixed && !IsOffsetEndFixed)
      {
         datetimeOffsetStart = iTime(NULL, 0, OffsetInBars + PastInBars - 1);
         ObjectSet(vlineOffsetStart, OBJPROP_TIME1, datetimeOffsetStart);
      }
      
      if (!IsOffsetEndFixed)
      {
         datetimeOffsetEnd = iTime(NULL, 0, OffsetInBars);
         ObjectSet(vlineOffsetEnd, OBJPROP_TIME1, datetimeOffsetEnd);
      }
      
      if(!IsRedraw)
      {
        PastAverage[0] = EMPTY_VALUE;
        ForecastCloudHigh[0] = EMPTY_VALUE;
        ForecastCloudLow[0] = EMPTY_VALUE;
        ForecastCloudAverage[0] = EMPTY_VALUE;
        ForecastBestPatternOpen[0] = EMPTY_VALUE;
        ForecastBestPatternClose[0] = EMPTY_VALUE;
        ForecastBestPatternHigh[0] = EMPTY_VALUE;
        ForecastBestPatternLow[0] = EMPTY_VALUE;
      }
      
   }
   
   if ((datetimeOffsetStart != OffsetStart) || (datetimeOffsetEnd != OffsetEnd))
   {
      OffsetStart = datetimeOffsetStart;
      OffsetEnd = datetimeOffsetEnd;
      
      IsRedraw = true;
      LastRedraw = 0;
   }      
      
   return rates_total;
}
 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
 
bool IsNewBar()
{
   static datetime prevTime = 0;
 
   datetime currentTime = iTime(NULL, 0, 0);
   if (prevTime == currentTime)
   {
      return (false);
   }
 
   prevTime = currentTime;
   return (true);
}
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
 
void RemoveOurObjects()
{
   for (int index = 0; index < ObjectsTotal(); index++)
   {
      if (StringFind(ObjectName(index), IndicatorName) == 0)
      {
         ObjectDelete(ObjectName(index));
         index--;
      }
   }
}
 
//+------------------------------------------------------------------+
//| Set shift for all plots                                          |
//+------------------------------------------------------------------+
 
void ChangeOffset(int newOffset)
{
   OffsetInBars = newOffset;
   for (int indexIndicator = 0; indexIndicator < 6; indexIndicator++)
   {
      SetIndexShift(indexIndicator, ForecastInBars - OffsetInBars);
   } 
}

//+------------------------------------------------------------------+
//| DTW                                                              |
//+------------------------------------------------------------------+

double Distance(double value1, double value2)
{
   double value = MathAbs(value1 - value2);
   return (value);
}

double dtw[1000][1000];

double DTWDistance(double &s[], double &t[]) 
{
   int slenght = ArraySize(s);
   int tlenght = ArraySize(t);
   int i, j;

   dtw[0, 0] = 0.0;
   for (j = 0; j < tlenght; j++)
   {
      dtw[0, j + 1] = MEGA_VALUE;
   }
   
   for (i = 0; i < slenght; i++)
   {
      dtw[i + 1, 0] = MEGA_VALUE;
   }

   for (i = 1; i < slenght; i++)
   {
      for (j = 1; j < tlenght; j++)
      {
         dtw[i, j] = Distance(s[i], t[j]) + MathMin(dtw[i - 1, j], MathMin(dtw[i, j - 1], dtw[i - 1, j - 1]));
      }
   }

   return (dtw[slenght - 1, tlenght - 1]);
}
 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
 
void ReCalculate()
{
   datetime currentTime = TimeCurrent();
   if ((currentTime - LastRedraw) < 1)
   {
      return;
   }
   
   LastRedraw = currentTime;
   IsRedraw = false;
   
   if (Bars < 100)
   {
      return;
   }
   
   int handleLog = 0;
   if (Debug)
   {
      handleLog = FileOpen(IndicatorName + ".log", FILE_WRITE);
      if (handleLog < 1)
      {
         Print ("handleLog = ", handleLog, ", error = ", GetLastError());
      }
   }
      
   datetime xtime = iTime(NULL, 0, OffsetInBars);
   datetime minDate = xtime - (MaxAgeInDays * 60 * 60 * 24);
   int baseHour = TimeHour(xtime);
   int baseMinute = TimeMinute(xtime);
   double x[];   
   ArrayResize(x, PastInBars);
   double x0 = iClose(NULL, 0, OffsetInBars);
   
   if (Debug)
   {
      FileWrite(handleLog, "xtime", TimeToStr(xtime));
      FileWrite(handleLog, "minDate", TimeToStr(minDate));
      FileWrite(handleLog, "baseHour", baseHour);
      FileWrite(handleLog, "baseMinute", baseMinute);  
      FileWrite(handleLog, "x0", x0);
   }
   
   for (int indexBar = OffsetInBars; indexBar < (OffsetInBars + PastInBars); indexBar++)
   {
      x[indexBar - OffsetInBars] = x0 - iClose(NULL, 0, indexBar);
      if (Debug)
      {
         FileWrite(handleLog, "x", indexBar - OffsetInBars, x[indexBar - OffsetInBars]);
      }
   }
   
   int foundAlts = 0;
   int iAlt[];
   ArrayResize(iAlt, MaxAlts);
   double dAlt[];
   ArrayResize(dAlt, MaxAlts);
   
   int patternscount = 0;
   
   for (int indexShift = ForecastInBars + OffsetInBars + 1; indexShift < Bars; indexShift++)
   {
      datetime ytimebase = iTime(NULL, 0, indexShift);
      
      if (ytimebase < minDate)
      {
         break;
      }
      
      if ((indexShift + PastInBars + VarShiftInBars) >= Bars)
      {
         break;
      }
      
      int currentHour = TimeHour(ytimebase);
      if (currentHour != baseHour)
      {
         continue;
      }
 
      int currentMinute = TimeMinute(ytimebase);
      if (currentMinute != baseMinute)
      {
         continue;
      }
      
      int iAltSingle = 0;
      double dAltSingle = MEGA_VALUE;
      double y[];
      ArrayResize(y, PastInBars);

      for (int indexVar = indexShift - VarShiftInBars; indexVar <= indexShift + VarShiftInBars; indexVar++)
      {
         patternscount++;
         datetime ytime = iTime(NULL, 0, indexVar);
         double y0 = iClose(NULL, 0, indexVar);
         for (int indexBar = indexVar; indexBar < (indexVar + PastInBars); indexBar++)
         {
            y[indexBar - indexVar] = y0 - iClose(NULL, 0, indexBar);
         }
         
         double _dtw = DTWDistance(x, y);
         if (_dtw < dAltSingle)
         {                      
            dAltSingle = _dtw;
            iAltSingle = indexVar;
         }
      }
      
      if (Debug)
      {
         FileWrite(handleLog, "");
         FileWrite(handleLog, "iAltSingle", iAltSingle);
         FileWrite(handleLog, "dAltSingle", dAltSingle);
      }
      
      bool altAdded = false;
      int j = 0;
      for (j = 0; j < foundAlts; j++)
      {
         if(iAltSingle == iAlt[j])
         {
           altAdded = true;
           break; // already logged
         }

         if (dAltSingle < dAlt[j])
         {
            if (foundAlts == MaxAlts)
            {
               foundAlts = MaxAlts - 1;   
            }
         
            for (int m = foundAlts; m >= (j + 1); m--)
            {
               iAlt[m] = iAlt[m - 1];
               dAlt[m] = dAlt[m - 1];
            }
         
            iAlt[j] = iAltSingle;
            dAlt[j] = dAltSingle;
            foundAlts++;
            
            altAdded = true;
            break;
         }
      }
      
      if (!altAdded)
      {
         if (foundAlts < MaxAlts && ArrayFind(iAlt, foundAlts, iAltSingle) == -1)
         {
            iAlt[j] = iAltSingle;
            dAlt[j] = dAltSingle;
            foundAlts++;
         }
      }
   }
   
   if (Debug)
   {
      FileWrite(handleLog, "");
      FileWrite(handleLog, "foundAlts", foundAlts);
      FileWrite(handleLog, "iAlt[0]", iAlt[0]);
      FileWrite(handleLog, "dAlt[0]", dAlt[0]);
   }

   /* // helper
   Print("Found patterns: ", foundAlts, (foundAlts == MaxAlts ? "*" : ""));
   for(int i = 0; i < foundAlts; i++)
   {
     Print(iTime(NULL, 0, iAlt[i]), " ", dAlt[i]);
   }
   */
   
   if (foundAlts > 1)
   {
      for (int a = 1; a < foundAlts; a++)
      {
         if(dAlt[a] == 0) continue;
         double sim = 100.0 - (((dAlt[a] - dAlt[0]) * 100.0) / dAlt[a]);
         if (Debug)
         {
            FileWrite(handleLog, "a", a, "dAlt", dAlt[a], "sim", sim);
         }
         
         if (sim < MaxVarInPercents)
         {
            foundAlts = a;
            break;
         }
      }
   }   
   
   double xcbase, ycbase;
   int altindex;
   
   if (ShowPastAverage && !ShowBestPattern)
   {
      if (Debug)
      {
         FileWrite(handleLog, "");
      }
      
      for (int indexBar = ForecastInBars; indexBar < (PastInBars + ForecastInBars); indexBar++)
      {
         PastAverage[indexBar] = iClose(NULL, 0, indexBar - ForecastInBars + OffsetInBars);
         if (Debug)
         {
            FileWrite(handleLog, "PastBar", indexBar - ForecastInBars, PastAverage[indexBar]);
         }
      }   
   }

   double forecastCloudHigh[];
   ArrayResize(forecastCloudHigh, ForecastInBars);
   ArrayInitialize(forecastCloudHigh, NO_HIGH);
   double forecastCloudLow[];
   ArrayResize(forecastCloudLow, ForecastInBars);
   ArrayInitialize(forecastCloudLow, NO_LOW);
   double forecastCloudAverage[];
   ArrayResize(forecastCloudAverage, ForecastInBars);
   ArrayInitialize(forecastCloudAverage, 0.0);
      
   xcbase = iClose(NULL, 0, OffsetInBars);
   int indexBar = 0;
   for (indexBar = 0; indexBar < ForecastInBars; indexBar++)
   {
      for (int a = 0; a < foundAlts; a++)
      {
         altindex = iAlt[a] - ForecastInBars + indexBar;
         ycbase = iClose(NULL, 0, iAlt[a]);            
         double yclose = xcbase + (iClose(NULL, 0, altindex) - ycbase);
         if (yclose > forecastCloudHigh[indexBar])
         {
            forecastCloudHigh[indexBar] = yclose;
         }
            
         if (yclose < forecastCloudLow[indexBar])
         {
            forecastCloudLow[indexBar] = yclose;
         }
            
         forecastCloudAverage[indexBar] += yclose;
      }
         
      forecastCloudAverage[indexBar] /= foundAlts;
      
      if (ShowForecastAverage && !ShowBestPattern)
      {
         if (foundAlts > 1)
         {
            if(forecastCloudHigh[indexBar] != NO_HIGH) ForecastCloudHigh[indexBar] = forecastCloudHigh[indexBar];
            if(forecastCloudLow[indexBar] != NO_LOW) ForecastCloudLow[indexBar] = forecastCloudLow[indexBar];
         }
         
         if(forecastCloudAverage[indexBar] != 0) ForecastCloudAverage[indexBar] = forecastCloudAverage[indexBar];
      }
   }
    
   if (ShowForecastAverage && !ShowBestPattern)
   {
      if (foundAlts > 1)
      {
         ForecastCloudHigh[indexBar] = xcbase;
         ForecastCloudLow[indexBar] = xcbase;
      }
      
      ForecastCloudAverage[indexBar] = xcbase;
   }

   xcbase = iClose(NULL, 0, OffsetInBars);
   if (ShowBestPattern)
   {   
      ycbase = iClose(NULL, 0, iAlt[0]);
      for (indexBar = 0; indexBar < (PastInBars + ForecastInBars - 1); indexBar++)
      {
         altindex = iAlt[0] - ForecastInBars + indexBar;
         ForecastBestPatternOpen[indexBar] = xcbase + (iOpen(NULL, 0, altindex) - ycbase);
         ForecastBestPatternClose[indexBar] = xcbase + (iClose(NULL, 0, altindex) - ycbase);
         ForecastBestPatternHigh[indexBar] = xcbase + (iHigh(NULL, 0, altindex) - ycbase);
         ForecastBestPatternLow[indexBar] = xcbase + (iLow(NULL, 0, altindex) - ycbase);
      }
   }
   
   int opsignal = 0;
   double ztp = 0.0, zsl = 0.0;
   int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   int spread = (int)MarketInfo(Symbol(), MODE_SPREAD);
   double point = MarketInfo(Symbol(), MODE_POINT);
   int stoplevel = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   if (stoplevel == 0.0)
   {
      // tester mode
      stoplevel = spread * 2;
   }
   
   double forecastBuy = forecastCloudLow[ArrayMaximum(forecastCloudLow)];
   double diffBuy = forecastBuy - xcbase;
   double forecastSell = forecastCloudHigh[ArrayMinimum(forecastCloudHigh)];
   double diffSell = xcbase - forecastSell;
   if ((diffBuy > 0.0) && (diffSell < 0.0))
   {
      opsignal = 1;
      ztp = forecastBuy;
      zsl = xcbase - diffBuy;
   }
   else
   {
      if ((diffBuy < 0.0) && (diffSell > 0.0))
      {
         opsignal = -1;
         ztp = forecastSell;
         zsl = xcbase + diffSell;
      }
      else
      {
         if ((diffBuy > 0.0) && (diffSell > 0.0))
         {
            if (diffBuy > diffSell)
            {
               opsignal = 1;
               ztp = forecastBuy;
               zsl = xcbase - diffBuy;
            }
            else
            {
               opsignal = -1;
               ztp = forecastSell;
               zsl = xcbase + diffSell;
            }
         }
      }
   }

   if (Debug)
   {
      FileWrite(handleLog, "");
      FileWrite(handleLog, "forecastBuy", forecastBuy);
      FileWrite(handleLog, "forecastSell", forecastSell);
      FileWrite(handleLog, "diffBuy", diffBuy);
      FileWrite(handleLog, "diffSell", diffSell);      
      FileWrite(handleLog, "opsignal", opsignal);
   }   
   
   if (ShowTip)
   {
      if (opsignal == 0)
      {
         DrawTrendTipLabel("NO TRADE SIGNAL");
      }
      else
      {
         if (opsignal > 0)
         {
            if (ztp > (xcbase + (stoplevel * point)))
            {
               DrawTrendTipLabel("BUY!  TP: " + DoubleToStr(ztp, digits));
               DrawTakeProfit(ztp, IndicatorTakeProfitColor);
               DrawStopLoss(zsl, IndicatorTakeProfitColor);
            }
            else
            {
               opsignal = 0;
               DrawTrendTipLabel("NO TRADE SIGNAL");
               DrawTakeProfit(0.0, IndicatorTakeProfitColor);
               DrawStopLoss(0.0, IndicatorTakeProfitColor);
            }
         }
         else
         {
            if (ztp < (xcbase - (stoplevel * point)))
            {
               DrawTrendTipLabel("SELL!  TP: " + DoubleToStr(ztp, digits));
               DrawTakeProfit(ztp, IndicatorTakeProfitColor);
               DrawStopLoss(zsl, IndicatorTakeProfitColor);
            }
            else
            {
               opsignal = 0;
               DrawTrendTipLabel("NO TRADE SIGNAL");
               DrawTakeProfit(0.0, IndicatorTakeProfitColor);
               DrawStopLoss(0.0, IndicatorTakeProfitColor);
            }
         }
      }
   }
   else
   {
      DrawTrendTipLabel(" ");
      DrawTakeProfit(0.0, IndicatorTakeProfitColor);
      DrawStopLoss(0.0, IndicatorTakeProfitColor);
   }
      
   DrawLabel("Name", IndicatorName + " " + IndicatorVersion + " | found patterns: " + (string)foundAlts + (foundAlts == MaxAlts ? "*" : ""), 0, 0, IndicatorTextColor, "Arial", 7);
   if (Debug)
   {
      FileClose(handleLog);
   }
   ChartRedraw();
}
 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
 
void DrawLabel(string label, string text, int x, int y, color clr, string fontName, int fontSize)
{
   int typeCorner = CORNER_RIGHT_UPPER;
   int anchor = ANCHOR_RIGHT_UPPER;
   if (!IsTopCorner)
   {
      typeCorner = CORNER_LEFT_LOWER;
      anchor = ANCHOR_LEFT_LOWER;
   }
 
   string labelIndicator = IndicatorName + "Label" + label;   
   if (ObjectFind(labelIndicator) == -1)
   {
      ObjectCreate(labelIndicator, OBJ_LABEL, 0, 0, 0);
   }
   
   ObjectSet(labelIndicator, OBJPROP_CORNER, typeCorner);
   ObjectSet(labelIndicator, OBJPROP_ANCHOR, anchor);
   ObjectSet(labelIndicator, OBJPROP_XDISTANCE, XCorner + x);
   ObjectSet(labelIndicator, OBJPROP_YDISTANCE, YCorner + y);
   ObjectSetText(labelIndicator, text, fontSize, fontName, clr);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
 
void DrawTrendTipLabel(string text)
{
   DrawLabel("TrendTip", text, 0, 10, IndicatorTextColor, "Impact", 18);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void DrawTakeProfit(double price, color clr)
{
   string labelHLine = IndicatorName + "TP"; 
   if (ObjectFind(labelHLine) == -1)
   {
      ObjectCreate(labelHLine, OBJ_HLINE, 0, 0, price);
   }
   else
   {
      ObjectSet(labelHLine, OBJPROP_PRICE1, price);
   }
   
   ObjectSet(labelHLine, OBJPROP_COLOR, clr);
   ObjectSet(labelHLine, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(labelHLine, OBJPROP_WIDTH, 1);   
   ObjectSetText(labelHLine, IndicatorName + ": T/P", 7, "Arial", clr);   
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void DrawStopLoss(double price, color clr)
{
   string labelHLine = IndicatorName + "SL"; 
   if (ObjectFind(labelHLine) == -1)
   {
      ObjectCreate(labelHLine, OBJ_HLINE, 0, 0, price);
   }
   else
   {
      ObjectSet(labelHLine, OBJPROP_PRICE1, price);
   }
   
   ObjectSet(labelHLine, OBJPROP_COLOR, clr);
   ObjectSet(labelHLine, OBJPROP_STYLE, STYLE_DOT);
   ObjectSet(labelHLine, OBJPROP_WIDTH, 1);   
   ObjectSetText(labelHLine, IndicatorName + ": S/L", 7, "Arial", clr);   
}

template<typename T>
int ArrayFind(const T &array[], const int n, const T value)
{
  for(int i = 0; i < n; i++)
  {
    if(array[i] == value) return i;
  }
  return -1;
}
