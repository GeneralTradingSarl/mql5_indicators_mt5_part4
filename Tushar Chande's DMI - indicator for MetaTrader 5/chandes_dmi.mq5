//------------------------------------------------------------------
   #property copyright "mladen"
   #property link      "www.tradcode.com"
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1

#property indicator_label1  "Chande DMI"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrOrange,clrGray
#property indicator_width1  2
#property indicator_minimum 0
#property indicator_maximum 100

//
//
//
//
//

enum enAvgType
{
   avgSma,    // Simple moving average
   avgEma,    // Exponential moving average
   avgSmma,   // Smoothed MA
   avgLwma    // Linear weighted MA
};
enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average
};

input enPrices  Price           = pr_close;  // Price to use
input int       StdDevPeriod    =  5;        // Period of Standard Deviation
input int       MAStdDevPeriod  = 10;        // Period of smoothing
input enAvgType MAStdDevMode    =  0;        // Mode of smoothing MA
input int       DMIPeriod       = 15;        // Dynamic Momentum Index Period
input int       DmiLowerLimit   = 10;        // Dynamic Periods Lower Bound
input int       DmiUpperLimit   = 50;        // Dynamic Periods Upper Bound
input double    LevelUp         = 70;        // Lower level
input double    LevelDown       = 30;        // Upper level

double dmi[];
double colorBuffer[];

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,dmi,INDICATOR_DATA);
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 

   //
   //
   //
   //
   //
   
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,LevelUp);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,LevelDown);
   IndicatorSetString(INDICATOR_SHORTNAME,"Chandes DMI ("+DoubleToString(DMIPeriod,1)+")");
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

int totalBars;
double trend[];
double avgma[];
double prics[];
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
   totalBars = rates_total;
   if (ArraySize(trend)!=rates_total)
   {
      ArrayResize(trend,rates_total);
      ArrayResize(avgma,rates_total);
      ArrayResize(prics,rates_total);
      ArrayResize(wrkBuffer,rates_total);
   }      

   //
   //
   //
   //
   //
   
      for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
      {
         prics[i] = getPrice(Price,open,close,high,low,i,rates_total);
         avgma[i] = iSma(prics[i],MAStdDevPeriod,i,1);
         
         //
         //
         //
         //
         //
            
         double deviation = iDeviationPlus(prics,avgma,MAStdDevPeriod,i);
         double deviatioa = iCustomMa(MAStdDevMode,deviation,MAStdDevPeriod,i,0);
         double vi        = 0;
         int    td        = 1;
            
         if (deviatioa != 0) vi       = deviation/deviatioa;
         if (vi != 0)        td       = (int)MathRound(DMIPeriod/vi); 
                             td       = MathMax(MathMin(td,DmiUpperLimit),DmiLowerLimit);
            double Kg = (3.0)/(2.0+td);
            double Hg = 1.0-Kg;
               wrkBuffer[i][12] = prics[i];
                  if (i==0) { for (int c=0; c<12; c++) wrkBuffer[i][c] = 0; continue; }  

         //
         //
         //
         //
         //
         
         double roc = wrkBuffer[i][12]-wrkBuffer[i-1][12];
         double roa = MathAbs(roc);
         for (int k=0; k<3; k++)
         {
            int kk = k*2;
               wrkBuffer[i][kk+0] = Kg*roc                + Hg*wrkBuffer[i-1][kk+0];
               wrkBuffer[i][kk+1] = Kg*wrkBuffer[i][kk+0] + Hg*wrkBuffer[i-1][kk+1]; roc = 1.5*wrkBuffer[i][kk+0] - 0.5 * wrkBuffer[i][kk+1];
               wrkBuffer[i][kk+6] = Kg*roa                + Hg*wrkBuffer[i-1][kk+6];
               wrkBuffer[i][kk+7] = Kg*wrkBuffer[i][kk+6] + Hg*wrkBuffer[i-1][kk+7]; roa = 1.5*wrkBuffer[i][kk+6] - 0.5 * wrkBuffer[i][kk+7];
         }
         if (roa != 0)
              dmi[i] = MathMax(MathMin((roc/roa+1.0)*50.0,100.00),0.00); 
         else dmi[i] = 50;
             
         //             
         //             
         //             
         //             
         //             

             trend[i] = 0;
               if (dmi[i] > LevelUp  ) trend[i] =  1;
               if (dmi[i] < LevelDown) trend[i] = -1;
               if (trend[i] == 1) colorBuffer[i]=0;
               if (trend[i] ==-1) colorBuffer[i]=1;
               if (trend[i] == 0) colorBuffer[i]=2;
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

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double iDeviationPlus(double& array[], double& ma[], int period, int i)
{
   double sum = 0;
         for(int k=0; k<period && (i-k)>=0; k++) sum += (array[i-k]-ma[i])  *(array[i-k]-ma[i]);
   return(MathSqrt(sum/period));
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workRsi[][3];
#define _price  0
#define _change 1
#define _changa 2

//
//
//
//

double iRsi(double price, double period, int bars, int i, int forInstance=0)
{
   if (ArrayRange(workRsi,0)!=bars) ArrayResize(workRsi,bars);
   int z    = forInstance*3; double alpha = 1.0 /(double)period; 

   //
   //
   //
   //
   //
   
      workRsi[i][_price+z] = price;
      if (i<period)
      {
         int k; double sum = 0; for (k=0; k<period && (i-k-1)>=0; k++) sum += MathAbs(workRsi[i-k][_price+z]-workRsi[i-k-1][_price+z]);
            workRsi[i][_change+z] = (workRsi[i][_price+z]-workRsi[0][_price+z])/MathMax(k,1);
            workRsi[i][_changa+z] =                                         sum/MathMax(k,1);
      }
      else
      {
         double change = workRsi[i][_price+z]-workRsi[i-1][_price+z];
            workRsi[i][_change+z] = workRsi[i-1][_change+z] + alpha*(        change  - workRsi[i-1][_change+z]);
            workRsi[i][_changa+z] = workRsi[i-1][_changa+z] + alpha*(MathAbs(change) - workRsi[i-1][_changa+z]);
      }
      if (workRsi[i][_changa+z] != 0)
            return(50.0*(workRsi[i][_change+z]/workRsi[i][_changa+z]+1));
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

double iCustomMa(int mode, double price, double length, int r, int instanceNo=0)
{
   switch (mode)
   {
      case avgSma   : return(iSma(price,(int)length,r,instanceNo));
      case avgEma   : return(iEma(price,length,r,instanceNo));
      case avgSmma  : return(iSmma(price,(int)length,r,instanceNo));
      case avgLwma  : return(iLwma(price,(int)length,r,instanceNo));
      default       : return(price);
   }
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workSma[][4];
double iSma(double price, int period, int r, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= totalBars) ArrayResize(workSma,totalBars); instanceNo *= 2;

   //
   //
   //
   //
   //

   int k;      
      workSma[r][instanceNo]    = price;
      workSma[r][instanceNo+1]  = 0; for(k=0; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo];  
      workSma[r][instanceNo+1] /= (double)k;
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][1];
double iEma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= totalBars) ArrayResize(workEma,totalBars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workSmma[][1];
double iSmma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= totalBars) ArrayResize(workSmma,totalBars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][1];
double iLwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= totalBars) ArrayResize(workLwma,totalBars);
   
   //
   //
   //
   //
   //
   
   workLwma[r][instanceNo] = price;
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}