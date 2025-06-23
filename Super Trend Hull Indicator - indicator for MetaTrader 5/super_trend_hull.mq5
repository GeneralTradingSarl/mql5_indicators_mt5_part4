//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Super trend hull"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrPaleVioletRed
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

input int      hullPeriod    = 12;        // Hull period
input enPrices Price         = pr_median; // Price
input int      atrPeriod     = 12;        // ATR period
input double   atrMultiplier = 0.66;      // ATR multiplier

double st[];
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
   SetIndexBuffer(0,st,INDICATOR_DATA); 
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
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

double Up[];
double Dn[];
double Direction[];
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
   if (ArraySize(Direction)!=rates_total)
   {
      ArrayResize(Up,rates_total);
      ArrayResize(Dn,rates_total);
      ArrayResize(Direction,rates_total);
   }      

   //
   //
   //
   //
   //

   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
   {
      double atr = 0; 
         for (int k=0;k<atrPeriod && (i-k-1)>=0; k++) 
               atr += MathMax(high[i-k],close[i-k-1])-MathMin(low[i-k],close[i-k-1]);
               atr /= atrPeriod;
      
         //
         //
         //
         //
         //
      
         double cprice = close[i];
         double mprice = iHull(getPrice(Price,open,close,high,low,i,rates_total),hullPeriod,i,rates_total);
                Up[i]  = mprice+atrMultiplier*atr;
                Dn[i]  = mprice-atrMultiplier*atr;
         
         //
         //
         //
         //
         //

         colorBuffer[i] = colorBuffer[i-1];
         Direction[i]   = Direction[i-1];
            if (cprice > Up[i-1]) Direction[i] =  1;
            if (cprice < Dn[i-1]) Direction[i] = -1;
            if (Direction[i] > 0) 
                  { Dn[i] = MathMax(Dn[i],Dn[i-1]); st[i] = Dn[i]; }
            else  { Up[i] = MathMin(Up[i],Up[i-1]); st[i] = Up[i]; }
            if (Direction[i]== 1) colorBuffer[i] = 0;
            if (Direction[i]==-1) colorBuffer[i] = 1;
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

double workHull[][2];
double iHull(double price, double period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workHull,0)!= bars) ArrayResize(workHull,bars);

   //
   //
   //
   //
   //

      int HmaPeriod  = (int)MathMax(period,2);
      int HalfPeriod = (int)MathFloor(HmaPeriod/2);
      int HullPeriod = (int)MathFloor(MathSqrt(HmaPeriod));
      double hma,hmw,weight; instanceNo *= 2;

         workHull[r][instanceNo] = price;

         //
         //
         //
         //
         //
               
         hmw = HalfPeriod; hma = hmw*price; 
            for(int k=1; k<HalfPeriod && (r-k)>=0; k++)
            {
               weight = HalfPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];  
            }             
            workHull[r][instanceNo+1] = 2.0*hma/hmw;

         hmw = HmaPeriod; hma = hmw*price; 
            for(int k=1; k<period && (r-k)>=0; k++)
            {
               weight = HmaPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][instanceNo];
            }             
            workHull[r][instanceNo+1] -= hma/hmw;

         //
         //
         //
         //
         //
         
         hmw = HullPeriod; hma = hmw*workHull[r][instanceNo+1];
            for(int k=1; k<HullPeriod && (r-k)>=0; k++)
            {
               weight = HullPeriod-k;
               hmw   += weight;
               hma   += weight*workHull[r-k][1+instanceNo];  
            }
   return(hma/hmw);
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
