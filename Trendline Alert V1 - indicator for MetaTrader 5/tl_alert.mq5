//+------------------------------------------------------------------+
//|                                          Indicator: TL ALERT.mq5 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+
#property copyright "www.metatrader5software.store"
#property link      "www.metatrader5software.store"
#property version   "1.01"
#property description ""

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_HISTOGRAM
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_color1 0x006AFF
#property indicator_label1 "sell"

#property indicator_type2 DRAW_HISTOGRAM
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1
#property indicator_color2 0xFFF700
#property indicator_label2 "buy"

#define PLOT_MAXIMUM_BARS_BACK 5000
#define OMIT_OLDEST_BARS 50

//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
bool Send_Email = true;
bool Audible_Alerts = true;
bool Push_Notifications = true;
double myPoint; //initialized in OnInit
double Close[];
double Low[];

void myAlert(string type, string message)
  {
   int handle;
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | TL ALERT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
   else if(type == "indicator")
     {
      Print(type+" | TL ALERT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Audible_Alerts) Alert(type+" | TL ALERT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Send_Email) SendMail("TL ALERT", type+" | TL ALERT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      handle = FileOpen("TL ALERT.txt", FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE, ';');
      if(handle != INVALID_HANDLE)
        {
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, type+" | TL ALERT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
         FileClose(handle);
        }
      if(Push_Notifications) SendNotification(type+" | TL ALERT @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
  }

double TrendlinePriceUpper(int shift) //returns current price on the highest horizontal line or trendline found in the chart
  {
   int obj_total = ObjectsTotal(0);
   double maxprice = -1;
   for(int i = obj_total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      double price;
      if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_HLINE && StringFind(name, "#", 0) < 0
      && (price = ObjectGetDouble(0, name, OBJPROP_PRICE)) > maxprice
      && price > 0)
         maxprice = price;
      else if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_TREND && StringFind(name, "#", 0) < 0)
      {
         datetime cTime[];
         ArraySetAsSeries(cTime, true);
         CopyTime(Symbol(), Period(), 0, 1, cTime);
         price = ObjectGetValueByTime(0, name, cTime[0], 0);
         if(price > maxprice && price > 0)
            maxprice = price;		 
      }
     }
   return(maxprice); //not found => -1
  }

double TrendlinePriceLower(int shift) //returns current price on the lowest horizontal line or trendline found in the chart
  {
   int obj_total = ObjectsTotal(0);
   double minprice = MathPow(10, 308);
   for(int i = obj_total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      double price;
      if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_HLINE && StringFind(name, "#", 0) < 0
      && (price = ObjectGetDouble(0, name, OBJPROP_PRICE)) < minprice
      && price > 0)
         minprice = price;
      else if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_TREND && StringFind(name, "#", 0) < 0)
      {
         datetime cTime[];
         ArraySetAsSeries(cTime, true);
         CopyTime(Symbol(), Period(), 0, 1, cTime);
         price = ObjectGetValueByTime(0, name, cTime[0], 0);
         if(price < minprice && price > 0)
            minprice = price;		 
      }
     }
   if (minprice > MathPow(10, 307))
      minprice = -1; //not found => -1
   return(minprice);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   SetIndexBuffer(1, Buffer2);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
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
   ArraySetAsSeries(Buffer2, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
     }
   else
      limit++;
   datetime Time[];
   
   if(TrendlinePriceUpper(0) < 0 && TrendlinePriceLower(0) < 0) return(rates_total);
   if(CopyClose(Symbol(), PERIOD_CURRENT, 0, rates_total, Close) <= 0) return(rates_total);
   ArraySetAsSeries(Close, true);
   if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
   ArraySetAsSeries(Low, true);
   if(CopyTime(Symbol(), Period(), 0, rates_total, Time) <= 0) return(rates_total);
   ArraySetAsSeries(Time, true);
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(PLOT_MAXIMUM_BARS_BACK-1, rates_total-1-OMIT_OLDEST_BARS)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(Close[1+i] < TrendlinePriceLower(i) //Candlestick Close < Lower Trendline
      )
        {
         Buffer1[i] = Low[1+i]; //Set indicator value at Candlestick Low
         if(i == 1 && Time[1] != time_alert) myAlert("indicator", "sell"); //Alert on next bar open
         time_alert = Time[1];
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 2
      if(Close[1+i] > TrendlinePriceUpper(i) //Candlestick Close > Upper Trendline
      )
        {
         Buffer2[i] = Low[1+i]; //Set indicator value at Candlestick Low
         if(i == 1 && Time[1] != time_alert) myAlert("indicator", "buy"); //Alert on next bar open
         time_alert = Time[1];
        }
      else
        {
         Buffer2[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+