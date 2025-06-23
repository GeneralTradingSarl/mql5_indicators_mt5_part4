//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
// idea for chaninging lengths by sohocool
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Super smoother"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

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

input enPrices Price           = pr_close;       // Price to use
input int      SmoothingPeriod = 25;             // Smoothing period
input int      AdaptivePeriod  = 25;             // Period for adapting
input color    ColorFrom       = clrRed;         // Color down
input color    ColorTo         = clrYellowGreen; // Color Up
input int      ColorSteps      = 50;             // Color steps for drawing
double ssm[];
double colorBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

#define Pi 3.14159265358979323846264338327950288
double c1,c2,c3;
int cSteps;
int OnInit()
{
   SetIndexBuffer(0,ssm,INDICATOR_DATA); 
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
      double a1 = MathExp(-1.414*Pi/(double)SmoothingPeriod);
      double b1 = 2.0*a1*MathCos(1.414*Pi/(double)SmoothingPeriod);
             c2 = b1;
             c3 = -a1*a1;
             c1 = 1.0 - c2 - c3;
             cSteps = (ColorSteps>1) ? ColorSteps : 2;
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

double work[][1];
#define _price 0
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
    if (ArrayRange(work,0)!= rates_total) ArrayResize(work,rates_total);

   //
   //
   //
   //
   //

   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      work[i][_price] = getPrice(Price,open,close,high,low,i,rates_total);
      if (i<3)
            ssm[i] = work[i][_price];
      else  ssm[i] = c1*(work[i][_price]+work[i-1][_price])/2.0 + c2*ssm[i-1] + c3*ssm[i-2];
      double min = ssm[i];
      double max = ssm[i];
      double col = 0;
      for(int k=1;  k<ColorSteps && (i-k)>=0; k++)
      {
         min = (ssm[i-k]<min) ? ssm[i-k] : min;
         max = (ssm[i-k]>max) ? ssm[i-k] : max;
      }
      if((max-min) == 0)
            col = 50;
      else  col = 100 * (ssm[i]-min)/(max-min);         
      colorBuffer[i] = MathFloor(col*cSteps/100.0);                                  
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