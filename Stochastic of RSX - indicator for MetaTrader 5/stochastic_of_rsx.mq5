//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Stochastic of RSX"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_level1  10
#property indicator_level2  90
#property indicator_level3  100

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average     // Average (high+low+oprn+close)/4
};

input int      StochasticPeriod  = 32;           // Stochastic period
input int      StochasticSlowing =  9;           // Stochastic slowing period
input enPrices Price             = pr_close;     // Price to use
input double   RsxPeriod         = 32;           // Rsx period
input color    ColorFrom         = clrOrangeRed; // Color down
input color    ColorTo           = clrLimeGreen; // Color Up
double sto[];
double colorBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int cSteps;
int OnInit()
{
   SetIndexBuffer(0,sto,INDICATOR_DATA); 
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
       cSteps = (StochasticPeriod>1) ? StochasticPeriod : 2;
       PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,cSteps+1);
         for (int i=0;i<cSteps+1;i++) 
               PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,gradientColor(i,cSteps+1,ColorFrom,ColorTo));
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

double wrkBuffer[][13];
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
   if (Bars(_Symbol,_Period)<rates_total) return(-1);
   if (ArrayRange(wrkBuffer,0)!=rates_total) ArrayResize(wrkBuffer,rates_total);

   //
   //
   //
   //
   //

   double Kg = (3.0)/(2.0+RsxPeriod);
   double Hg = 1.0-Kg;
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      for (int c=0; c<12; c++) wrkBuffer[i][c] = 0; wrkBuffer[i][12] = getPrice(Price,open,close,high,low,rates_total,i);

      //
      //
      //
      //
      //
      
      double roc = (i>0) ? wrkBuffer[i][12]-wrkBuffer[i-1][12] : 0;
      double roa = MathAbs(roc);
      if (i>0) for (int k=0; k<3; k++)
      {
         int kk = k*2;
            wrkBuffer[i][kk+0] = Kg*roc                + Hg*wrkBuffer[i-1][kk+0];
            wrkBuffer[i][kk+1] = Kg*wrkBuffer[i][kk+0] + Hg*wrkBuffer[i-1][kk+1]; roc = 1.5*wrkBuffer[i][kk+0] - 0.5 * wrkBuffer[i][kk+1];
            wrkBuffer[i][kk+6] = Kg*roa                + Hg*wrkBuffer[i-1][kk+6];
            wrkBuffer[i][kk+7] = Kg*wrkBuffer[i][kk+6] + Hg*wrkBuffer[i-1][kk+7]; roa = 1.5*wrkBuffer[i][kk+6] - 0.5 * wrkBuffer[i][kk+7];
      }
      double rsi = (roa != 0) ? MathMax(MathMin((roc/roa+1.0)*50.0,100.00),0.00) : 0; 
               sto[i]         = iStoch(rsi,rsi,rsi,StochasticPeriod,StochasticSlowing,rates_total,i);
               colorBuffer[i] = MathFloor(sto[i]*cSteps/100.0);                                  
   }
   return(rates_total);
}


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//

double workSto[][5];
#define _hi 0
#define _lo 1
#define _re 2
#define _ma 3
#define _mi 4
double iStoch(double priceR, double priceH, double priceL, int period, int slowing, int bars, int i, int instanceNo=0)
{
   if (ArrayRange(workSto,0)!=bars) ArrayResize(workSto,bars); instanceNo *= 5;
   
   //
   //
   //
   //
   //
   
   workSto[i][_hi+instanceNo] = priceH;
   workSto[i][_lo+instanceNo] = priceL;
   workSto[i][_re+instanceNo] = priceR;
   workSto[i][_ma+instanceNo] = priceH;
   workSto[i][_mi+instanceNo] = priceL;
      for (int k=1; k<period && (i-k)>=0; k++)
      {
         workSto[i][_mi+instanceNo] = MathMin(workSto[i][_mi+instanceNo],workSto[i-k][instanceNo+_lo]);
         workSto[i][_ma+instanceNo] = MathMax(workSto[i][_ma+instanceNo],workSto[i-k][instanceNo+_hi]);
      }                   
      double sumlow  = 0.0;
      double sumhigh = 0.0;
      for(int k=0; k<slowing && (i-k)>=0; k++)
      {
         sumlow  += workSto[i-k][_re+instanceNo]-workSto[i-k][_mi+instanceNo];
         sumhigh += workSto[i-k][_ma+instanceNo]-workSto[i-k][_mi+instanceNo];
      }

   //
   //
   //
   //
   //
   
   if(sumhigh!=0.0) 
         return(100.0*sumlow/sumhigh);
   else  return(0);    
}


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int bars, int i)
{
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
   }
   return(0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

color getColor(int stepNo, int totalSteps, color from, color to)
{
   double stes = (double)totalSteps-1.0;
   double step = (from-to)/(stes);
   return((color)round(from-step*stepNo));
}
color gradientColor(int step, int totalSteps, color from, color to)
{
   color newBlue  = getColor(step,totalSteps,(from & 0XFF0000)>>16,(to & 0XFF0000)>>16)<<16;
   color newGreen = getColor(step,totalSteps,(from & 0X00FF00)>> 8,(to & 0X00FF00)>> 8) <<8;
   color newRed   = getColor(step,totalSteps,(from & 0X0000FF)    ,(to & 0X0000FF)    )    ;
   return(newBlue+newGreen+newRed);
}