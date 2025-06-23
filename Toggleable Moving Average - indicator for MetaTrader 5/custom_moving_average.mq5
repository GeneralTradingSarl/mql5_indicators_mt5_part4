//+------------------------------------------------------------------+
//|                                                     Demo_iMA.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "The indicator demonstrates how to obtain data"
#property description "of indicator buffers for the iMA technical indicator."
#property description "A symbol and timeframe used for calculation of the indicator,"
#property description "are set by the symbol and period parameters."
#property description "The method of creation of the handle1 is set through the 'type' parameter (function type)."
#property description "All other parameters like in the standard Moving Average."

#include <Controls\Button.mqh>
CButton MA1Button;
CButton MA2Button;
CButton MA3Button;

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3
//--- the iMA plot
#property indicator_label1  "iMA"


input int                  ma1_period=20;                 // Period of Short MA
input ENUM_MA_METHOD       ma1_method=MODE_SMA;           // Type of Short MA
input int                  ma1_shift=0;                   // Shift of Short MA
input color                indicator_color1=clrRed;       // Color of Short MA
input int                  indicator_width1=2;            // Width of Short MA
input ENUM_LINE_STYLE      indicator_style1=STYLE_SOLID;  // Style of Short MA
input ENUM_APPLIED_PRICE   applied1_price=PRICE_CLOSE;    // Applied Price of Short MA
input string               button1_text="MA20";            // Button Test of Short MA
//--- indicator buffer
double         iMA1Buffer[];
bool MA1_Ind=false;


input int                  ma2_period=50;                 // Period of Medium MA
input ENUM_MA_METHOD       ma2_method=MODE_SMA;           // Type of Medium MA
input int                  ma2_shift=0;                   // Shift of Medium MA
input color                indicator_color2=clrBlue;       // Color of Medium MA
input int                  indicator_width2=2;            // Width of Medium MA
input ENUM_LINE_STYLE      indicator_style2=STYLE_SOLID;  // Style of Medium MA
input ENUM_APPLIED_PRICE   applied2_price=PRICE_CLOSE;    // Applied Medium of Short MA
input string               button2_text="MA50";            // Button Test of Short MA

//--- indicator buffer
double         iMA2Buffer[];
bool MA2_Ind=false;


input int                  ma3_period=200;                 // Period of Long MA
input ENUM_MA_METHOD       ma3_method=MODE_SMA;           // Type of Long MA
input int                  ma3_shift=0;                   // Shift of Long MA
input color                indicator_color3=clrGreen;     // Color of Long MA
input int                  indicator_width3=2;            // Width of Long MA
input ENUM_LINE_STYLE      indicator_style3=STYLE_SOLID;  // Style of Long MA
input ENUM_APPLIED_PRICE   applied3_price=PRICE_CLOSE;    // Applied Price of Long MA
input string               button3_text="MA200";            // Button Test of Short MA
//--- indicator buffer
double         iMA3Buffer[];
bool MA3_Ind=false;


input string               symbol=" ";                   // symbol
input ENUM_TIMEFRAMES      period=PERIOD_CURRENT;        // timeframe
//--- variable for storing the handle1 of the iMA indicator
int    handle1;
int    handle2;
int    handle3;
//--- variable for storing
string name=symbol;
//--- name of the indicator on a chart
string short_name;
//--- we will keep the number of values in the Moving Average indicator
int    bars_calculated=0;
int bars_number;



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   int x1 = 25;
   int y1 = 100;
   int x2 = x1+70;
   int y2 = y1+30;

   MA1Button.Create(0,button1_text,0,x1,y1,x2,y2);//Create MA1Button
   MA1Button.Text(button1_text);                         //Label

   x1 = x1+85;
   x2 = x2+85;

   MA2Button.Create(0,button2_text,0,x1,y1,x2,y2);//Create MA1Button
   MA2Button.Text(button2_text);                         //Label

   x1 = x1+85;
   x2 = x2+85;

   MA3Button.Create(0,button3_text,0,x1,y1,x2,y2);//Create MA1Button
   MA3Button.Text(button3_text);                         //Label


//--- assignment of array to indicator buffer
   SetIndexBuffer(0,iMA1Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,iMA2Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,iMA3Buffer,INDICATOR_DATA);
//--- set shift
   PlotIndexSetInteger(0,PLOT_SHIFT,ma1_shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,ma2_shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,ma3_shift);
//--- determine the symbol the indicator is drawn for
   name=symbol;
//--- delete spaces to the right and to the left
   StringTrimRight(name);
   StringTrimLeft(name);
//--- if it results in zero length of the 'name' string
   if(StringLen(name)==0)
     {
      //--- take the symbol of the chart the indicator is attached to
      name=_Symbol;
     }

   bars_number==Bars(name,period);

   handle1=iMA(name,period,ma1_period,ma1_shift,ma1_method,applied1_price);
   handle2=iMA(name,period,ma2_period,ma2_shift,ma2_method,applied2_price);
   handle3=iMA(name,period,ma3_period,ma3_shift,ma3_method,applied3_price);

//--- if the handle1 is not created
   if(handle1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle for Short MA of the iMA indicator for the symbol %s/%s, error code %d",
                  name,
                  EnumToString(period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
   if(handle2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle for Medium MA of the iMA indicator for the symbol %s/%s, error code %d",
                  name,
                  EnumToString(period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
   if(handle3==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle for Long MA of the iMA indicator for the symbol %s/%s, error code %d",
                  name,
                  EnumToString(period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }



//--- show the symbol/timeframe the Moving Average indicator is calculated for
   short_name="Custom Toggelable Moving Average";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- normal initialization of the indicator

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


//--- number of values copied from the iMA indicator
   int values_to_copy;
//--- determine the number of values calculated in the indicator
   int calculated=BarsCalculated(handle1);
//   Print("Calculated:"+calculated);
   if(calculated<=0)
     {
      PrintFormat("BarsCalculated() returned %d, error code %d",calculated,GetLastError());
      return(0);
     }
//--- if it is the first start of calculation of the indicator or if the number of values in the iMA indicator changed
//---or if it is necessary to calculated the indicator for two or more bars (it means something has changed in the price history)
   if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1)
     {
      //--- if the iMA1Buffer array is greater than the number of values in the iMA indicator for symbol/period, then we don't copy everything
      //--- otherwise, we copy less than the size of indicator buffers
      if(calculated>rates_total)
         values_to_copy=rates_total;
      else
         values_to_copy=calculated;
     }
   else
     {
      //--- it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
      //--- for calculation not more than one bar is added
      values_to_copy=(rates_total-prev_calculated)+1;
     }
//--- fill the iMA1Buffer array with values of the Moving Average indicator
//--- if FillArrayFromBuffer returns false, it means the information is nor ready yet, quit operation
//   bars_number==Bars(name,period);
//   Print("Bars:"+bars_number);
//   if (bars_number>=ma1_period)
   if(!FillArrayFromBuffer(iMA1Buffer,ma1_shift,handle1,values_to_copy))
      Print("Error in MA1");
//      return(0);
//   if (bars_number>=ma2_period)
   if(!FillArrayFromBuffer(iMA2Buffer,ma2_shift,handle2,values_to_copy))
      Print("Error in MA2");
//      return(0);
//   if (bars_number>=ma3_period)
   if(!FillArrayFromBuffer(iMA3Buffer,ma3_shift,handle3,values_to_copy))
      Print("Error in MA3");
//      return(0);

//--- form the message
   string comm=StringFormat("%s ==>  Updated value in the indicator %s: %d",
                            TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
                            short_name,
                            values_to_copy);
//--- display the service message on the chart
   Comment(comm);
//--- memorize the number of values in the Moving Average indicator
   bars_calculated=calculated;
//--- return the prev_calculated value for the next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Filling indicator buffers from the MA indicator                  |
//+------------------------------------------------------------------+
bool FillArrayFromBuffer(double &values[],   // indicator buffer of Moving Average values
                         int shift,          // shift
                         int ind_handle1,     // handle1 of the iMA indicator
                         int amount          // number of copied values
                        )
  {
//--- reset error code
   ResetLastError();
//--- fill a part of the iMA1Buffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(ind_handle1,0,-shift,amount,values)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }



//--- everything is fine
   return(true);
  }

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---Observes cursor position, Highlight button and detect Click event



   if(MA1Button.Contains(lparam,dparam))
      MA1Button.Pressed(true);   //Dtect cursor on the button
   else
      MA1Button.Pressed(false);
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == button1_text)
     {
      Print("Button 1 Pressed");
      Print("MA1_Ind Before:"+MA1_Ind);
      if(MA1_Ind==false)
         MA1_Ind=true;
      else
         MA1_Ind=false;
      Print("MA1_Ind After:"+MA1_Ind);

      switch(MA1_Ind)
        {
         case(true):
            PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
            PlotIndexSetInteger(0,PLOT_LINE_STYLE,indicator_style1);
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,indicator_color1);
            PlotIndexSetInteger(0,PLOT_LINE_WIDTH,indicator_width1);
            break;

         case(false):
            PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
            PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID);
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrNONE);
            break;
        }
     }



   if(MA2Button.Contains(lparam,dparam))
      MA2Button.Pressed(true);   //Dtect cursor on the button
   else
      MA2Button.Pressed(false);
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == button2_text)
     {
      Print("Button 2 Pressed");
      Print("MA2_Ind:"+MA2_Ind);
      if(MA2_Ind==false)
         MA2_Ind=true;
      else
         MA2_Ind=false;

      switch(MA2_Ind)
        {
         case(true):
            PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
            PlotIndexSetInteger(1,PLOT_LINE_STYLE,indicator_style2);
            PlotIndexSetInteger(1,PLOT_LINE_COLOR,indicator_color2);
            PlotIndexSetInteger(1,PLOT_LINE_WIDTH,indicator_width2);
            break;

         case(false):
            PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
            PlotIndexSetInteger(1,PLOT_LINE_STYLE,STYLE_SOLID);
            PlotIndexSetInteger(1,PLOT_LINE_COLOR,clrNONE);
            break;
        }
     }



   if(MA3Button.Contains(lparam,dparam))
      MA3Button.Pressed(true);   //Dtect cursor on the button
   else
      MA3Button.Pressed(false);
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == button3_text)
     {
      Print("Button 3 Pressed");
      Print("MA3_Ind:"+MA3_Ind);
      if(MA3_Ind==false)
         MA3_Ind=true;
      else
         MA3_Ind=false;

      switch(MA3_Ind)
        {
         case(true):
            PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
            PlotIndexSetInteger(2,PLOT_LINE_STYLE,indicator_style3);
            PlotIndexSetInteger(2,PLOT_LINE_COLOR,indicator_color3);
            PlotIndexSetInteger(2,PLOT_LINE_WIDTH,indicator_width3);
            break;

         case(false):
            PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
            PlotIndexSetInteger(2,PLOT_LINE_STYLE,STYLE_SOLID);
            PlotIndexSetInteger(2,PLOT_LINE_COLOR,clrNONE);
            break;
        }
     }
   ChartRedraw();

  }


//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle1!=INVALID_HANDLE)
      IndicatorRelease(handle1);
//--- clear the chart after deleting the indicator
   Comment("");
  }

//+------------------------------------------------------------------+
