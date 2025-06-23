//------------------------------------------------------------------
#property copyright   "Copyright 2017, mladen"
#property link        "mladenfx@gmail.com"
#property description "Swing line - adjusted display"
#property version     "1.00"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   3
#property indicator_label1  "Swing line"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrPaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
#property indicator_label2  "Swing line bars"
#property indicator_type2   DRAW_COLOR_HISTOGRAM2
#property indicator_color2  clrLimeGreen,clrPaleVioletRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3
#property indicator_label3  "Swing line candles"
#property indicator_type3   DRAW_COLOR_CANDLES
#property indicator_color3  clrLimeGreen,clrPaleVioletRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  3
//--- input parameters
enum enDisplayType
  {
   dis_line  =CHART_LINE,    // Display colored line
   dis_bars  =CHART_BARS,    // Display colored bars
   dis_candle=CHART_CANDLES, // Display colored candles
   dis_auto  =9999           // Adjust automatically depending on chart type
  };
input enDisplayType inpDisplayType=dis_auto; // Display type
//--- buffers
double swli[],swlicc[],baru[],bard[],barcc[],candleo[],candleh[],candlel[],candlec[],candlecc[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,swli,INDICATOR_DATA);
   SetIndexBuffer(1,swlicc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,baru,INDICATOR_DATA);
   SetIndexBuffer(3,bard,INDICATOR_DATA);
   SetIndexBuffer(4,barcc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,candleo,INDICATOR_DATA);
   SetIndexBuffer(6,candleh,INDICATOR_DATA);
   SetIndexBuffer(7,candlel,INDICATOR_DATA);
   SetIndexBuffer(8,candlec,INDICATOR_DATA);
   SetIndexBuffer(9,candlecc,INDICATOR_COLOR_INDEX);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
double  work[][5];
#define hHi   0
#define hLo   1
#define lHi   2
#define lLo   3
#define trend 4
//
//---
//
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
   int limit=(int)MathMax(prev_calculated-1,0);
   static long sChartStyle  = -1; long chartStyle; ChartGetInteger(0,CHART_MODE,0,chartStyle);
   if(inpDisplayType==dis_auto)
     {
      if(sChartStyle!=chartStyle) { sChartStyle=chartStyle; limit=0; }
     }
   else sChartStyle=inpDisplayType;
   if(ArrayRange(work,0)!=rates_total) ArrayResize(work,rates_total);

//
//---
//
   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      if(i==0)
        {
         work[i][hHi]   = high[i]; work[i][hLo] = low[i];
         work[i][lHi]   = high[i]; work[i][lLo] = low[i];
         work[i][trend] = -1;
         continue;
        }
      //
      //---
      //
      work[i][trend] = work[i-1][trend];
      work[i][hHi]   = work[i-1][hHi]; work[i][hLo] = work[i-1][hLo];
      work[i][lHi]   = work[i-1][lHi]; work[i][lLo] = work[i-1][lLo];

      if(work[i-1][trend]==1)
        {
         work[i][hHi] = MathMax(work[i-1][hHi],high[i]);
         work[i][hLo] = MathMax(work[i-1][hLo],low[i]);
         if(high[i]<work[i][hLo]) { work[i][trend]=-1; work[i][lHi]=high[i]; work[i][lLo]=low[i]; }
        }
      if(work[i-1][trend]==-1)
        {
         work[i][lHi] = MathMin(work[i-1][lHi],high[i]);
         work[i][lLo] = MathMin(work[i-1][lLo],low[i]);
         if(low[i]>work[i][lHi]) { work[i][trend]=1; work[i][hHi]=high[i]; work[i][hLo]=low[i]; }
        }

      //
      //---
      //

      swli[i] = EMPTY_VALUE;
      bard[i] = baru[i] = EMPTY_VALUE;
      candleo[i]=candleh[i]=candlel[i]=candlec[i]=EMPTY_VALUE;
      switch((int)sChartStyle)
        {
         case CHART_LINE :
            swli[i]=(work[i][trend]==1) ? work[i][hLo]: work[i][lHi];
            swlicc[i]=(work[i][trend]==1) ? 0 :(work[i][trend]==-1) ? 1 :(i>0) ? swlicc[i-1]: 0;
            break;
         case CHART_BARS :
            baru[i] = high[i];
            bard[i] = low[i];
            barcc[i]=(work[i][trend]== 1) ? 0 :(work[i][trend]==-1) ? 1 :(i>0) ? barcc[i-1] : 0;
            break;
         case CHART_CANDLES :
            candleh[i] = high[i];
            candlel[i] = low[i];
            candleo[i] = open[i];
            candlec[i] = close[i];
            candlecc[i]=(work[i][trend]== 1) ? 0 :(work[i][trend]==-1) ? 1 :(i>0) ? candlecc[i-1] : 0;
            break;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
