//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
#property copyright "Created by TheCoder"
#property link      "https://www.mql5.com/en/users/brazilianguy3"
#property version   "1.00"
#property description ""

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots 1

#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_color1 0xFFAA00
#property indicator_label1 "Ratio"

//--- indicator buffers
double Buffer1[];

input int Periods = 2000; // Amount of candles to be considered
input bool ShowCalculationLimits=true; // Show range of candles on the screen
double myPoint; //initialized in OnInit
int ATR_handle;
double ATR[];

void myAlert(string type, string message)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | Volatility_x_Range @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
  }

void DrawLine(string objname, double price, int count, int start_index) //creates or modifies existing object if necessary
  {
   if((price < 0) && ObjectFind(0, objname) >= 0)
     {
      ObjectDelete(0, objname);
     }
   else if(ObjectFind(0, objname) >= 0 && ObjectGetInteger(0, objname, OBJPROP_TYPE) == OBJ_TREND)
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectSetInteger(0, objname, OBJPROP_TIME, cTime[start_index]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, price);
      ObjectSetInteger(0, objname, OBJPROP_TIME, 1, cTime[start_index+count-1]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, 1, price);
     }
   else
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectCreate(0, objname, OBJ_TREND, 0, cTime[start_index], price, cTime[start_index+count-1], price);
      ObjectSetInteger(0, objname, OBJPROP_RAY_LEFT, 0);
      ObjectSetInteger(0, objname, OBJPROP_RAY_RIGHT, 0);
      ObjectSetInteger(0, objname, OBJPROP_COLOR, C'0x00,0x00,0xFF');
      ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
     }
  }

double Support(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / PeriodSeconds();
   if(fixed_tod)
     {
      datetime start_time;
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, Bars(Symbol(), Period())-count, cTime);
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = cTime[shift-1];
      datetime dt = StringToTime(TimeToString(start_time, TIME_DATE)+" "+IntegerToString(hh)+":"+IntegerToString(mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(Symbol(), Period(), dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > cTime[Bars(Symbol(), Period())-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(Symbol(), Period(), dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(Symbol(), Period(), dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double cLow[];
   ArraySetAsSeries(cLow, true);
   CopyLow(Symbol(), Period(), start_index, count, cLow);
   double ret = cLow[ArrayMinimum(cLow, 0, count)];
   if (draw) DrawLine("Support", ret, count, start_index);
   return(ret);
  }

double Resistance(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / PeriodSeconds();
   if(fixed_tod)
     {
      datetime start_time;
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, Bars(Symbol(), Period())-count, cTime);
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = cTime[shift-1];
      datetime dt = StringToTime(TimeToString(start_time, TIME_DATE)+" "+IntegerToString(hh)+":"+IntegerToString(mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(Symbol(), Period(), dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > cTime[Bars(Symbol(), Period())-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(Symbol(), Period(), dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(Symbol(), Period(), dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double cHigh[];
   ArraySetAsSeries(cHigh, true);
   CopyHigh(Symbol(), Period(), start_index, count, cHigh);
   double ret = cHigh[ArrayMaximum(cHigh, 0, count)];
   if (draw) DrawLine("Resistance", ret, count, start_index);
   return(ret);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
     }
   ATR_handle = iATR(NULL, PERIOD_CURRENT, Periods);
   if(ATR_handle < 0)
     {
      Print("The creation of iATR has failed: ATR_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, 0);
     }
   else
      limit++;
   
   if(BarsCalculated(ATR_handle) <= 0) 
      return(0);
   if(CopyBuffer(ATR_handle, 0, 0, rates_total, ATR) <= 0) return(rates_total);
   ArraySetAsSeries(ATR, true);
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(true //no conditions!
      )
        {
         Buffer1[i] = (Resistance(Periods * PeriodSeconds(), false, 00, 00, ShowCalculationLimits, i) - Support(Periods * PeriodSeconds(), false, 00, 00, ShowCalculationLimits, i)) / (ATR[i] * Periods); //Set indicator value at Average True Range * fixed value / Resistance - Support
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+