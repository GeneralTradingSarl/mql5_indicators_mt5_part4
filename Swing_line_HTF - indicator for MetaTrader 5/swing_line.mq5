
//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Swing line"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrPaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

//
//
//
//
//

double swli[];
double colorBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,swli,INDICATOR_DATA); 
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//


double  work[][5];
#define hHi   0
#define hLo   1
#define lHi   2
#define lLo   3
#define trend 4


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

   //
   //
   //
   //
   //

   if (ArrayRange(work,0)!=rates_total) ArrayResize(work,rates_total);
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
      {
         if (i==0)
         {
            work[i][hHi]   = high[i]; work[i][hLo] = low[i];
            work[i][lHi]   = high[i]; work[i][lLo] = low[i];
            work[i][trend] = -1;
            continue; 
         }
      
         //
         //
         //
         //
         //
      
         work[i][trend] = work[i-1][trend];
         work[i][hHi]   = work[i-1][hHi]; work[i][hLo] = work[i-1][hLo];
         work[i][lHi]   = work[i-1][lHi]; work[i][lLo] = work[i-1][lLo];

               if (work[i-1][trend] == 1)
               {
                  work[i][hHi] = MathMax(work[i-1][hHi],high[i]);
                  work[i][hLo] = MathMax(work[i-1][hLo],low[i]);
                     if (high[i]<work[i][hLo]) { work[i][trend] = -1; work[i][lHi] = high[i]; work[i][lLo] = low[i]; }
               }
               if (work[i-1][trend] == -1)
               {
                  work[i][lHi] = MathMin(work[i-1][lHi],high[i]);
                  work[i][lLo] = MathMin(work[i-1][lLo],low[i]);
                     if (low[i]>work[i][lHi]) { work[i][trend] =  1; work[i][hHi] = high[i]; work[i][hLo] = low[i]; }
               }

         if (work[i][trend]==1)      
               swli[i] = work[i][hLo];
         else  swli[i] = work[i][lHi];
               colorBuffer[i] = colorBuffer[i-1];
               if (work[i][trend]== 1) colorBuffer[i]= 0;
               if (work[i][trend]==-1) colorBuffer[i]= 1;
   }
   return(rates_total);
}
    