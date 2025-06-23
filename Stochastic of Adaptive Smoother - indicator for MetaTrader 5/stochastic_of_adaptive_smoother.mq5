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

input int      StochasticPeriod = 25;           // Stochastic period
input enPrices Price            = pr_close;     // Price to use
input double   SmoothingPeriod  = 25;           // Smoothing period
input int      AdaptivePeriod   = 25;           // Period for smoother adapting
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
      double price  = getPrice(Price,open,close,high,low,i,rates_total); 
      double dev    = iDeviation(price,iSma(price,AdaptivePeriod,rates_total,i,0),AdaptivePeriod,rates_total,i);
      double avg    = iSma(dev,AdaptivePeriod,rates_total,i,1);
      double period = SmoothingPeriod;
        if (dev!=0) period = SmoothingPeriod*avg/dev;
                if (period<3) period = 3;
   
      //
      //
      //
      //
      //
      
      ssm[i] = iSmooth(price,period,i,rates_total,0);
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

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workSmooth[][5];
double iSmooth(double price,double length,int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workSmooth,0)!=bars) ArrayResize(workSmooth,bars); instanceNo *= 5;
 	if(r<=2) { workSmooth[r][instanceNo] = price; workSmooth[r][instanceNo+2] = price; workSmooth[r][instanceNo+4] = price; return(price); }
   
   //
   //
   //
   //
   //
   
	double alpha = 0.45*(length-1.0)/(0.45*(length-1.0)+2.0);
   	  workSmooth[r][instanceNo+0] =  price+alpha*(workSmooth[r-1][instanceNo]-price);
	     workSmooth[r][instanceNo+1] = (price - workSmooth[r][instanceNo])*(1-alpha)+alpha*workSmooth[r-1][instanceNo+1];
	     workSmooth[r][instanceNo+2] =  workSmooth[r][instanceNo+0] + workSmooth[r][instanceNo+1];
	     workSmooth[r][instanceNo+3] = (workSmooth[r][instanceNo+2] - workSmooth[r-1][instanceNo+4])*MathPow(1.0-alpha,2) + MathPow(alpha,2)*workSmooth[r-1][instanceNo+3];
	     workSmooth[r][instanceNo+4] =  workSmooth[r][instanceNo+3] + workSmooth[r-1][instanceNo+4]; 
   return(workSmooth[r][instanceNo+4]);
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

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workDev[];
double iDeviation(double price, double dMA, int period, int totalBars, int i)
{
   if (ArrayRange(workDev,0)!= totalBars) ArrayResize(workDev,totalBars); workDev[i] = price;
   double dSum = 0;
      for(int k=0; (i-k)>=0 && k<period; k++) dSum += (workDev[i-k]-dMA)*(workDev[i-k]-dMA);
   return(MathSqrt(dSum/period));
}

//
//
//
//
//

double workSma[][4];
double iSma(double price, int period, int totalBars, int r, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= totalBars) ArrayResize(workSma,totalBars); instanceNo *= 2;

   //
   //
   //
   //
   //

   int k;      
   workSma[r][instanceNo] = price;
   if (r>=period)
          workSma[r][instanceNo+1] = workSma[r-1][instanceNo+1]+(workSma[r][instanceNo]-workSma[r-period][instanceNo])/period;
   else { workSma[r][instanceNo+1] = 0; for(k=0; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo];  
          workSma[r][instanceNo+1] /= k; }
   return(workSma[r][instanceNo+1]);
}