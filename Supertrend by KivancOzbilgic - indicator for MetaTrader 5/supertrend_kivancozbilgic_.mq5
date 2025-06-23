//+------------------------------------------------------------------+
//|                                    Supertrend_KivancOzbilgic.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//|                                          Author: Yashar Seyyedin |
//|       Web Address: https://www.mql5.com/en/users/yashar.seyyedin |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   4
//--- plot UpLine
#property indicator_label1  "UpLine"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot DnLine
#property indicator_label2  "DnLine"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot UpArrow
#property indicator_label3  "UpArrow"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- plot DnArrow
#property indicator_label4  "DnArrow"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

static datetime lastTimeAlert=0;

enum ENUM_SOURCE {OPEN, CLOSE, HIGH, LOW, HL2, HLC3, OHLC4, HLCC4};
input int Periods = 10; //ATR Period
input ENUM_SOURCE src = HL2; //Source
input double Multiplier = 3; //ATR Multiplier
input bool changeATR= true; //Change ATR Calculation Method ?
input bool enable_alerts=false; //Enable Alerts

//--- indicator buffers
double         UpLineBuffer[];
double         DnLineBuffer[];
double         UpArrowBuffer[];
double         DnArrowBuffer[];
double         trBuffer[];
double         atr2Buffer[];
double         atrBuffer[];
double         upBuffer[];
double         downBuffer[];
double         trendBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,UpLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DnLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,UpArrowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,DnArrowBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,trBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,atr2Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,atrBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,upBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,downBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,trendBuffer,INDICATOR_CALCULATIONS);

   ArraySetAsSeries(UpLineBuffer,true);
   ArraySetAsSeries(DnLineBuffer,true);
   ArraySetAsSeries(UpArrowBuffer,true);
   ArraySetAsSeries(DnArrowBuffer,true);
   ArraySetAsSeries(trBuffer,true);
   ArraySetAsSeries(atr2Buffer,true);
   ArraySetAsSeries(atrBuffer,true);
   ArraySetAsSeries(upBuffer,true);
   ArraySetAsSeries(downBuffer,true);
   ArraySetAsSeries(trendBuffer,true);

//---
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
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
   //Not Available anymore
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+