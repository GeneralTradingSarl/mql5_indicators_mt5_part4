//+------------------------------------------------------------------+
//|                                             Strong_Levels_V0.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                          https://www.pipcrop.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.pipcrop.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0
#property version   "1.00"

#property description "Rule 1(bull candle on sup. level): if close - low > Jump Factor"
#property description "Rule 2(bull candle on res. level): if close - low > Jump Factor & (close-low)/(high-low)>ratio"

#include <..\include\Math\Alglib\dataanalysis.mqh>
CKMeans *Cclustering;

enum filterrules {
                  rule1,                  // Rule 1
                  rule12,                 // Rule 1+2
                  rule2                   // Rule 2
                  };

input filterrules myfilters = 1;          // Rule(s) for data gather
input int LNo = 15;                       // Number of Levels to extract
input ENUM_TIMEFRAMES tf0 = PERIOD_M1;    // Analysing TF
input double Jumpmulti = 100.0;           // Min. Jump after touch (Percent of ATR)
input double ratio = 0.6667;              // Ratio
input int ATRPer = 55;                    // ATR Period
input color ResColor = clrPink;           // Resistance color for Panel
input color SupColor = clrPowderBlue;     // Support color for Panel
input color BGColor = C'23,27,38';        // Back-ground
input color ResColor0 = clrRed;           // Resistance Levels color 
input color SupColor0 = clrBlue;          // Support Levels color
input int LevelsInt = 2;                  // Levels Width

int ATRHndler, size0, xini=5, yini=20, maxbar, minbar=10, Ysize = 30, dyy=5, xdis = 0, lastbars = 0, LastLNo=0, minLN=3;
int sup_xyz[], res_xyz[];
long NextChart;
string ToolName = "SH_Levels_", OBJName;
double atr[], Jmulti;
CMatrixDouble res_mat, sup_mat, supclusters, resclusters;
bool startCluster = false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0, ToolName);
   Jmulti = Jumpmulti/100.0;

   ATRHndler  = iATR(Symbol(), tf0, ATRPer);
   SetScreen();
   
   maxbar = 100000;
   
   OBJName = ToolName + "Analyse"; xdis = xini;
   ObjectCreate(0, OBJName, OBJ_BUTTON, 0, 0, 0);
   OBJSet(OBJName, "Analyse Sup./Res.", xini, yini, 180, 2*Ysize+dyy,12,  C'240,240,240', clrNONE, clrBlack, ALIGN_CENTER, CORNER_LEFT_UPPER, true);

   OBJName = ToolName + " Loadbar"; xdis+= (int)ObjectGetInteger(ChartID(), ToolName + "Analyse", OBJPROP_XSIZE) + dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, "0.0 %", xdis, yini, 50, Ysize, 10, clrGold, clrGold, BGColor, ALIGN_LEFT, CORNER_LEFT_UPPER, true);
   
   OBJName = ToolName + "clusterLoadbar"; xdis = xini+(int)ObjectGetInteger(ChartID(), ToolName + "Analyse", OBJPROP_XSIZE) + dyy; yini += Ysize + dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0); 
   OBJSet(OBJName, "0.0 %", xdis, yini, 50, Ysize, 10, clrGold, clrGold, BGColor, ALIGN_LEFT, CORNER_LEFT_UPPER, true);

   OBJName = ToolName + " LN"; yini+=Ysize+dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, "Level No.", xini, yini, 80, Ysize, 10, clrGold, clrGold, BGColor, ALIGN_LEFT, CORNER_LEFT_UPPER, true);

   OBJName = ToolName + " LN.e"; xdis=xini+80+dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, IntegerToString(LNo), xdis, yini, 100-dyy, Ysize, 10, BGColor, clrGold, clrGold, ALIGN_RIGHT, CORNER_LEFT_UPPER, false);
   LastLNo = LNo;
   
   OBJName = ToolName + " bars"; xdis=xini; yini+=Ysize+dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, "Bar count", xdis, yini, 80, Ysize, 10, clrGold, clrGold, BGColor, ALIGN_LEFT, CORNER_LEFT_UPPER, true);

   OBJName = ToolName + " bars.e"; xdis+=80+dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, IntegerToString(maxbar), xdis, yini, 100-dyy, Ysize, 10, BGColor, clrGold, clrGold, ALIGN_RIGHT, CORNER_LEFT_UPPER, false);
   lastbars = maxbar;

   OBJName = ToolName + " TotalRes"; yini+=Ysize+3*dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, "Res. Count: ", xini, yini, 180, Ysize, 12, ResColor, ResColor, BGColor, ALIGN_LEFT, CORNER_LEFT_UPPER, true);

   OBJName = ToolName + " TotalSup"; yini+=Ysize+dyy;
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, "Sup. Count: ", xini, yini, 180, Ysize, 12, SupColor, SupColor, BGColor, ALIGN_LEFT, CORNER_LEFT_UPPER, true);
   
   EventSetMillisecondTimer(5);
   
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
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if (reason==1 || reason==4)
      {
      ObjectsDeleteAll(0, ToolName);
      EventKillTimer();
      }
  }
//+------------------------------------------------------------------+
void Analyse()
{
   // Reset Graphics
   OBJName = ToolName + "Zone_";
   ObjectsDeleteAll(ChartID(), OBJName); ChartRedraw();

   OBJName = ToolName + " Loadbar";
   ObjectSetString(0, OBJName, OBJPROP_TEXT, "0.0 %");
   ObjectSetInteger(0, OBJName, OBJPROP_XSIZE, 50);

   OBJName = ToolName + "clusterLoadbar";
   ObjectSetInteger(0, OBJName, OBJPROP_XSIZE, 50);
   ObjectSetString(0, OBJName, OBJPROP_TEXT, "0.0 %");

   Ysize = 30;

   // Set data limits from screen
   int bars = lastbars, ctype[];
   double low[], high[], close[], open[], total[];
   ArrayResize(ctype, bars); ArrayInitialize(ctype, 0);

   int resi = (int) (bars / 1000.0)-1; 
   if (resi<=0) resi=2;

   // Copy bars data
   if (CopyBuffer(ATRHndler, 0, 0, bars, atr)<=0) return;
   if (CopyLow(Symbol(), tf0, 0, bars, low)<=0) return;
   if (CopyHigh(Symbol(), tf0, 0, bars, high)<=0) return;
   if (CopyClose(Symbol(), tf0, 0, bars, close)<=0) return;
   if (CopyOpen(Symbol(), tf0, 0, bars, open)<=0) return;

   bars = (int) MathMin(ArraySize(open), MathMin((double) bars, ArraySize(close)));

   // Fill candle type (Bull? Bear?)
   for (int i=bars-ATRPer-1; i>=0; i--)
      {
      Print(i,"  ",ArraySize(close));
      if (close[i]>open[i]) ctype[i] = +1;
      else if (close[i]<open[i]) ctype[i] = -1;
      }

   // Fill S/R matrixes base on selected time-frame candels OHLC data
   // Implementing Jump rules and candle type limits
   sup_mat.Resize(0, 0); supclusters.Resize(0, 0);
   res_mat.Resize(0, 0); resclusters.Resize(0,0);
   
   for (int i=bars-ATRPer-1; i>=0; i--)
      {
      if (myfilters<=1 && ctype[i]==+1 && close[i]-low[i]>=atr[i]*Jmulti) Addsup(low[i]);
      if (myfilters>=1 && ctype[i]==-1 && close[i]-low[i]>=atr[i]*Jmulti && (close[i]-low[i])/(high[i]-low[i])>=ratio) Addsup(low[i]);

      if (myfilters<=1 && ctype[i]==-1 && high[i]-close[i]>=atr[i]*Jmulti) Addres(high[i]);
      if (myfilters>=1 && ctype[i]==+1 && high[i]-close[i]>=atr[i]*Jmulti && (high[i]-close[i])/(high[i]-low[i])>=ratio) Addres(high[i]);      

      if (MathMod((double) i, resi) == 0)
         {
         ObjectSetString(0, ToolName + " Loadbar", OBJPROP_TEXT, DoubleToString(100*(double) (bars-ATRPer-1-i)/(bars-ATRPer-1),1) + " %");
         ObjectSetInteger(0, ToolName + " Loadbar", OBJPROP_XSIZE, 50 + (int) (300 * ((double) (bars-ATRPer-i+1)/(bars-ATRPer-1))));
         ObjectSetString(0, ToolName + " TotalRes", OBJPROP_TEXT, "Res. Count: " + IntegerToString(res_mat.Rows()));
         ObjectSetString(0, ToolName + " TotalSup", OBJPROP_TEXT, "Sup. Count: " + IntegerToString(sup_mat.Rows()));

         ChartRedraw();
         }
      }

   startCluster = true;
   OBJName = ToolName + "clusterLoadbar";
   ObjectSetInteger(0, OBJName, OBJPROP_XSIZE, 350);
   ObjectSetString(0, OBJName, OBJPROP_TEXT, "Wait for Cluster Calculation...");

   int supinfo, resinfo, Restarts=5;
   Cclustering.KMeansGenerate(sup_mat, sup_mat.Rows(), sup_mat.Cols(), LastLNo, Restarts, supinfo, supclusters, sup_xyz); 
   Cclustering.KMeansGenerate(res_mat, res_mat.Rows(), res_mat.Cols(), LastLNo, Restarts, resinfo, resclusters, res_xyz); 
   
   startCluster = false;
   ObjectSetString(0, OBJName, OBJPROP_TEXT, "Cluster Calculation done!");
   
   double LevelRes[], LevelSup[], LevelTotal[];
   ArrayResize(LevelRes, LastLNo); ArrayResize(LevelSup, LastLNo); ArrayResize(LevelTotal, LastLNo); 

   OBJName = ToolName + "clusterLoadbar";
   int stat_x = (int) ObjectGetInteger(ChartID(), OBJName, OBJPROP_XDISTANCE);
   OBJName = ToolName + " Loadbar";;
   stat_x += (int) ObjectGetInteger(ChartID(), OBJName, OBJPROP_XSIZE) + dyy;
   OBJName = ToolName + "Analyse";
   int stat_y = (int) ObjectGetInteger(ChartID(), OBJName, OBJPROP_YDISTANCE);

   // Closters Graphical
   OBJName = ToolName + "Zone_Res_Header";
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
   OBJSet(OBJName, "Res. Levels", stat_x, stat_y, 135, Ysize, 12, ResColor, ResColor, BGColor, ALIGN_CENTER, CORNER_LEFT_UPPER, true);

   OBJName = ToolName + "Zone_Sup_Header";
   ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0); stat_x+=135+dyy;
   OBJSet(OBJName, "Sup. Levels", stat_x, stat_y, 135, Ysize, 12, SupColor, SupColor, BGColor, ALIGN_CENTER, CORNER_LEFT_UPPER, true);

   stat_y+=Ysize+dyy;
   Ysize/=2;

   for (int i=0; i<LastLNo; i++)
      {
      stat_x -=135+dyy;
      OBJName = ToolName + "Zone_Res_" + IntegerToString(i);
      ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
      OBJSet(OBJName, DoubleToString(resclusters.Get(0, i), Digits()), stat_x, stat_y, 135, Ysize, 12, ResColor, ResColor, BGColor, ALIGN_CENTER, CORNER_LEFT_UPPER, true);

      stat_x +=135+dyy;
      OBJName = ToolName + "Zone_Sup_" + IntegerToString(i);
      ObjectCreate(0, OBJName, OBJ_EDIT, 0, 0, 0);
      OBJSet(OBJName, DoubleToString(supclusters.Get(0, i), Digits()), stat_x, stat_y, 135, Ysize, 12, SupColor, SupColor, BGColor, ALIGN_CENTER, CORNER_LEFT_UPPER, true);
      stat_y+=Ysize+dyy;
      }


   NextChart = ChartOpen(Symbol(), Period());
   datetime future = TimeCurrent()+ PeriodSeconds(PERIOD_MN1) * 100;
   double price;

   for (int i=0; i<LastLNo; i++)
      {
      price = NormalizeDouble(resclusters.Get(0, i), Digits());
      OBJName = ToolName + "Zone_Res_" + IntegerToString(i+LastLNo+1);
      ObjectCreate(NextChart, OBJName, OBJ_HLINE, 0, 0, 0);
      TrendSet(OBJName, 0, NextChart, price, price, ResColor0, LevelsInt, STYLE_SOLID, true);
      
      price = NormalizeDouble(supclusters.Get(0, i), Digits());
      OBJName = ToolName + "Zone_Sup_" + IntegerToString(i+LastLNo+1);
      ObjectCreate(NextChart, OBJName, OBJ_HLINE, 0, 0, 0);
      TrendSet(OBJName, 0, NextChart, price, price, SupColor0, LevelsInt, STYLE_SOLID, true);
      }

   ChartRedraw(NextChart);
   delete Cclustering;
   ArrayFree(sup_xyz); ArrayFree(res_xyz);
   ArrayFree(atr);

   Ysize = 30;
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
  if (startCluster)
     {
     OBJName = ToolName + "clusterLoadbar";
     
     if (ObjectGetString(0, OBJName, OBJPROP_TEXT)=="Wait for Cluster Calculation")
        ObjectSetString(0, OBJName, OBJPROP_TEXT, "Wait for Cluster Calculation.");
     else if (ObjectGetString(0, OBJName, OBJPROP_TEXT)=="Wait for Cluster Calculation.")
        ObjectSetString(0, OBJName, OBJPROP_TEXT, "Wait for Cluster Calculation..");
     else if (ObjectGetString(0, OBJName, OBJPROP_TEXT)=="Wait for Cluster Calculation..")
        ObjectSetString(0, OBJName, OBJPROP_TEXT, "Wait for Cluster Calculation...");
     else if (ObjectGetString(0, OBJName, OBJPROP_TEXT)=="Wait for Cluster Calculation..")
        ObjectSetString(0, OBJName, OBJPROP_TEXT, "Wait for Cluster Calculation");
      
     ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
void MeanNormalization(matrix &mat)
  {
   vector v = {};

   for(ulong i=0; i<mat.Cols(); i++)
     {
      v = mat.Col(i);
      MeanNormalization(v);
      mat.Col(v, i);
     }
  }
//+------------------------------------------------------------------+
void MeanNormalization(vector &v)
  {
   double mean = v.Mean(),
          max = v.Max(),
          min = v.Min();

   for(ulong i=0; i<v.Size(); i++)
      v[i] = (v[i] - mean) / (max - min);

  }
//+------------------------------------------------------------------+
void Addsup(double price)
{
   int msize = sup_mat.Rows();
   sup_mat.Resize(msize+1, 1);
   sup_mat.Set(msize, 0, price);
}
//+------------------------------------------------------------------+
void Addres(double price)
{
   int msize = res_mat.Rows();
   res_mat.Resize(msize+1, 1);
   res_mat.Set(msize, 0, price);
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if (id == CHARTEVENT_OBJECT_CLICK && sparam==ToolName + "Analyse")
      {
      Sleep(100);
      ObjectSetInteger(ChartID(), sparam, OBJPROP_STATE, false);
      ChartRedraw();
      Analyse();
      }
   
   if (id == CHARTEVENT_OBJECT_ENDEDIT && sparam==ToolName + " bars.e")
      {
      OBJName = sparam;
      int bar = (int) StringToInteger(ObjectGetString(ChartID(), OBJName, OBJPROP_TEXT));
      if (bar<0) bar=iBars(Symbol(), tf0)+1;
      
      if (bar<minbar) 
         {
         MessageBox("Min. bar to analyse is " + IntegerToString(minbar) + "!", "Min. bar limit", 0);
         ObjectSetString(0, OBJName, OBJPROP_TEXT, IntegerToString(minbar));
         }
      else if (bar>iBars(Symbol(), tf0)) 
         {
         MessageBox("Max. bar to analyse is " + IntegerToString(iBars(Symbol(), tf0)) + "!","Max. bar limit", 0);
         ObjectSetString(0, OBJName, OBJPROP_TEXT, IntegerToString(iBars(Symbol(), tf0)));
         }
      else if (bar>900000)
         {
         int mes = MessageBox(IntegerToString(bar) + " bars to analyse is so much and will take time more than 1 minute! Are you sure?", "Max. bar warning", 1);
         if (mes==2) ObjectSetString(0, OBJName, OBJPROP_TEXT, IntegerToString(lastbars));
         }
      
      lastbars = (int) StringToInteger(ObjectGetString(ChartID(), OBJName, OBJPROP_TEXT));
      }
   
   
   if (id == CHARTEVENT_OBJECT_ENDEDIT && sparam==ToolName + " LN.e")
      {
      OBJName = sparam;
      int bar = (int) StringToInteger(ObjectGetString(ChartID(), OBJName, OBJPROP_TEXT));
      if (bar<0) bar=LNo;
      
      if (bar<minLN) 
         {
         MessageBox("Min. Level No. to analyse is " + IntegerToString(minLN) + "!", "Min. Level No. limit", 0);
         ObjectSetString(0, OBJName, OBJPROP_TEXT, IntegerToString(minLN));
         }
      else if (bar>500) 
         {
         MessageBox("Max. Level No. to analyse is 500" + "!","Max. bar limit", 0);
         ObjectSetString(0, OBJName, OBJPROP_TEXT, IntegerToString(500));
         }
      else if (bar>100)
         {
         int mes = MessageBox(IntegerToString(bar) + " Level No. analyse is so much and will take time more than 1 minute! Are you sure?", "Max. Level No. warning", 1);
         if (mes==2) ObjectSetString(0, OBJName, OBJPROP_TEXT, IntegerToString(LastLNo));
         }

      LastLNo = (int) StringToInteger(ObjectGetString(ChartID(), OBJName, OBJPROP_TEXT));
      }

   ChartRedraw();
}
//+------------------------------------------------------------------+
void SetScreen()
{
   ChartSetInteger(ChartID(), CHART_FOREGROUND, false);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, BGColor);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, BGColor);
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, BGColor);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, BGColor);
   ChartSetInteger(0, CHART_COLOR_CHART_UP, BGColor);
   ChartSetInteger(0, CHART_COLOR_ASK, BGColor);
   ChartSetInteger(0, CHART_COLOR_BID, BGColor);
   ChartSetInteger(0, CHART_COLOR_GRID, BGColor);
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, BGColor);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, BGColor);
}
//+------------------------------------------------------------------+
void OBJSet(string OBJNameSet, string txt, int XDis, int YDis, int XSize, int YSize, int FSize, color Fill, color Border, color TColor, ENUM_ALIGN_MODE myAlign, ENUM_BASE_CORNER mycorner, bool myread)
{
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_CORNER, mycorner);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_XDISTANCE, XDis);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_YDISTANCE, YDis);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_XSIZE, XSize);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_YSIZE, YSize);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_FONTSIZE, FSize);
   ObjectSetString(ChartID(),  OBJNameSet, OBJPROP_TEXT,txt);
   ObjectSetString(ChartID(),  OBJNameSet, OBJPROP_FONT,"Calibri");
   
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_BGCOLOR, Fill);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_BORDER_COLOR, Border);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_COLOR, TColor);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_ALIGN, myAlign);
   
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_BACK, false);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_ZORDER,5);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_HIDDEN, true);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_READONLY, myread);
   ObjectSetInteger(ChartID(), OBJNameSet, OBJPROP_SELECTABLE, false);
}
//+------------------------------------------------------------------+
void TrendSet(string TrendName, datetime time0, datetime time1, double price1, double price2, color Tcolor, int Twidth, ENUM_LINE_STYLE Tstyle, int b)
{
   ObjectSetInteger(NextChart, TrendName, OBJPROP_TIME, 0, time0);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_TIME, 1, time1);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_COLOR, Tcolor);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_RAY, false);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_WIDTH, Twidth);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_STYLE, Tstyle);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_BACK, true);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(NextChart, TrendName, OBJPROP_TIMEFRAMES, b?OBJ_ALL_PERIODS:OBJ_NO_PERIODS);
   ObjectSetDouble(NextChart, TrendName, OBJPROP_PRICE, 0, price1);
   ObjectSetDouble(NextChart, TrendName, OBJPROP_PRICE, 1, price2);
}

