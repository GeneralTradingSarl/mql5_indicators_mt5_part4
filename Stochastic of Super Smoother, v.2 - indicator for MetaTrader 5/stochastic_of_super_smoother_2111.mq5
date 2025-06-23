//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
// idea for chaninging lengths by sohocool
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_label1  "Super smoother stochastic"
#property indicator_type1   DRAW_COLOR_HISTOGRAM2
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "Super smoother stochastic"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
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

input int      StochasticPeriod = 32;           // Stochastic period
input enPrices Price            = pr_close;     // Price to use
input double   SmoothingPeriod  = 25;           // Smoothing period
input int      AdaptivePeriod   = 25;           // Period for adapting
input color    ColorFrom        = clrOrchid;    // Color down
input color    ColorTo          = clrLime;      // Color Up
double sto[];
double stohv[];
double stohm[];
double colorBuffer[];
double colorBufferh[];

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
   SetIndexBuffer(0,stohv,INDICATOR_DATA); 
   SetIndexBuffer(1,stohm,INDICATOR_DATA); 
   SetIndexBuffer(2,colorBufferh,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(3,sto,INDICATOR_DATA); 
   SetIndexBuffer(4,colorBuffer,INDICATOR_COLOR_INDEX); 
       cSteps = (StochasticPeriod>1) ? StochasticPeriod : 2;
       PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,cSteps+1);
       PlotIndexSetInteger(1,PLOT_COLOR_INDEXES,cSteps+1);
       for (int i=0;i<cSteps+1;i++) 
         {
               PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,gradientColor(i,cSteps+1,ColorFrom,ColorTo));
               PlotIndexSetInteger(1,PLOT_LINE_COLOR,i,gradientColor(i,cSteps+1,ColorFrom,ColorTo));
         }               
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

double ssm[];
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
    if (ArrayRange(ssm,0)!= rates_total) ArrayResize(ssm,rates_total);

   //
   //
   //
   //
   //

   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      ssm[i] = iSsm(getPrice(Price,open,close,high,low,i,rates_total),SmoothingPeriod,i,rates_total,0);
      double min = ssm[i];
      double max = ssm[i];
      for(int k=1;  k<StochasticPeriod && (i-k)>=0; k++)
      {
         min = (ssm[i-k]<min) ? ssm[i-k] : min;
         max = (ssm[i-k]>max) ? ssm[i-k] : max;
      }
      if((max-min) == 0)
            sto[i] = 50;
      else  sto[i] = 100 * (ssm[i]-min)/(max-min);         
      colorBuffer[i]  = MathFloor(sto[i]*cSteps/100.0);                                  
      colorBufferh[i] = colorBuffer[i];
      stohv[i]        = sto[i];
      stohm[i]        = 50;
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
//

double workSsm[][4];
#define _price  0
#define _ssm    1

double workSsmCoeffs[][4];
#define _period 0
#define _c1     1
#define _c2     2
#define _c3     3
#define Pi 3.14159265358979323846264338327950288

//
//
//
//
//

double iSsm(double price, double period, int i, int bars, int instanceNo=0)
{
   if (ArrayRange(workSsm,0) !=bars)                 ArrayResize(workSsm,bars);
   if (ArrayRange(workSsmCoeffs,0) < (instanceNo+1)) ArrayResize(workSsmCoeffs,instanceNo+1);
   if (workSsmCoeffs[instanceNo][_period] != period)
   {
      workSsmCoeffs[instanceNo][_period] = period;
      double a1 = MathExp(-1.414*Pi/period);
      double b1 = 2.0*a1*MathCos(1.414*Pi/period);
         workSsmCoeffs[instanceNo][_c2] = b1;
         workSsmCoeffs[instanceNo][_c3] = -a1*a1;
         workSsmCoeffs[instanceNo][_c1] = 1.0 - workSsmCoeffs[instanceNo][_c2] - workSsmCoeffs[instanceNo][_c3];
   }

   //
   //
   //
   //
   //

      int s = instanceNo*2;   
          workSsm[i][s+_price] = price;
          if (i<3) return(workSsm[i][s+_price]);
          workSsm[i][s+_ssm]   = workSsmCoeffs[instanceNo][_c1]*(workSsm[i][s+_price]+workSsm[i-1][s+_price])/2.0 + 
                                 workSsmCoeffs[instanceNo][_c2]*workSsm[i-1][s+_ssm]                              + 
                                 workSsmCoeffs[instanceNo][_c3]*workSsm[i-2][s+_ssm];
   return(workSsm[i][s+_ssm]);
}


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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