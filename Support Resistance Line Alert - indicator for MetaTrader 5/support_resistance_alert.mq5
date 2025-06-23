//+------------------------------------------------------------------+
//|                                     Support_Resistance_Alert.mq5 |
//|                                       Copyright 2022, D4rk Ryd3r |
//|                                    https://twitter.com/DarkRyd3r |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, D4rk Ryd3r"
#property link      "https://twitter.com/DarkRyd3r"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0
// Alert Methods
input bool popup_alerts = true; // Enable PopUp Alerts
input bool send_push = false; // Enable Push Notification
input color InpColorSupport = clrLimeGreen; // Support Color
input color InpColorResistance = clrCrimson; // Resistance Color
input ENUM_LINE_STYLE InpSupportStyle = STYLE_SOLID; // Support Line Style
input ENUM_LINE_STYLE InpResistanceStyle = STYLE_SOLID; // Resistance Line Style
input int SupportWidth = 3; // Support Width
input int ResistanceWidth = 3; // Resistance Width

MqlTick m_tick;
string now;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   EventSetTimer(1);
   if(!SymbolInfoTick(Symbol(),m_tick))
      return(INIT_SUCCEEDED);
   if(m_tick.bid==0.0)
      return(INIT_SUCCEEDED);
   HLineCreate(0,"Resistance",0,m_tick.bid+50*Point(),InpColorResistance,InpResistanceStyle,ResistanceWidth);
   HLineCreate(0,"Support",0,m_tick.bid-50*Point(),InpColorSupport,InpSupportStyle,SupportWidth);
//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   EventKillTimer();
//---
   HLineDelete(0,"Resistance");
   HLineDelete(0,"Support");
//---

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
                const int &spread[]) {

      return(rates_total);
   }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   now=TimeToString(TimeLocal(),TIME_SECONDS);
   double High = iHigh(Symbol(),PERIOD_M1,0);
   double Low = iLow(Symbol(),PERIOD_M1,0);
   if(ObjectFind(0,"Resistance")<0)
      HLineCreate(0,"Resistance",0,m_tick.bid+50*Point(),InpColorResistance,InpResistanceStyle,ResistanceWidth);
   if(ObjectFind(0,"Support")<0)
      HLineCreate(0,"Support",0,m_tick.bid-50*Point(),InpColorSupport,InpSupportStyle,SupportWidth);

   if(High>=ObjectGetDouble(0,"Resistance",OBJPROP_PRICE,0) && Low<=ObjectGetDouble(0,"Resistance",OBJPROP_PRICE,0)) {
      DoAlert(Symbol() +" Resistance touched at "+ DoubleToString(m_tick.bid,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)) + " " + now);
      HLineDelete(0,"Resistance");
   }
   if(High>=ObjectGetDouble(0,"Support",OBJPROP_PRICE,0) && Low<=ObjectGetDouble(0,"Support",OBJPROP_PRICE,0)) {
      DoAlert(Symbol() +" Support touched at "+ DoubleToString(m_tick.bid,(int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS)) + " " + now);
      HLineDelete(0,"Support");
   }
//---
}
//+------------------------------------------------------------------+
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_DASHDOTDOT,// line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0) {       // priority for mouse click
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
   }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}

//+------------------------------------------------------------------+
//| Delete a horizontal line                                         |
//+------------------------------------------------------------------+
bool HLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="HLine") { // line name
//--- reset the error value
   ResetLastError();
//--- delete a horizontal line
   if(!ObjectDelete(chart_ID,name)) {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
   }
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  DoAlert(string text) {
   if (popup_alerts==true)  Alert (text);
//if (Sound==true )  PlaySound (filename);
   if (send_push==true)  SendNotification(text);
}


//+------------------------------------------------------------------+
