//------------------------------------------------------------------

   #property copyright "mladen"
   #property link      "www.forex-tsd.com"

//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3

#property indicator_label1  "Volume veighted MACD OSMA"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'216,237,243',MistyRose
#property indicator_label2  "Volume veighted MACD"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "Volume veighted MACD Signal"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGold
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

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
   pr_average,    // Average (high+low+oprn+close)/4
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage   // Heiken ashi average
};

//
//
//
//
//

input int       FastPeriod   = 12;       // Fast period
input int       SlowPeriod   = 26;       // Slow period
input int       SignalPeriod =  9;       // Signal period
input enPrices  Price        = pr_close; // Price to use
input bool      RealV        = false;    // Use real volume

//
//
//
//
//

double osmau[];
double osmad[];
double macd[];
double signal[];

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
   SetIndexBuffer(0,osmau,INDICATOR_DATA);
   SetIndexBuffer(1,osmad,INDICATOR_DATA);
   SetIndexBuffer(2,macd,INDICATOR_DATA); 
   SetIndexBuffer(3,signal,INDICATOR_DATA); 

   //
   //
   //
   //
   //
            
   IndicatorSetString(INDICATOR_SHORTNAME," VEMA MACD ("+string(FastPeriod)+","+string(SlowPeriod)+","+string(SignalPeriod)+")");
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


double vemas[][6];
#define _numf 0
#define _denf 1
#define _emaf 2
#define _nums 3
#define _dens 4
#define _emas 5

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
   if (ArrayRange(vemas,0)!=rates_total) ArrayResize(vemas,rates_total);

   //
   //
   //
   //
   //

   double alphaf = 2.0/(1.0+FastPeriod);
   double alphas = 2.0/(1.0+SlowPeriod);
   double alphag = 2.0/(1.0+SignalPeriod);
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      double vol, price = getPrice(Price,open,close,high,low,i,rates_total);
      if (RealV)
            vol = (double)volume[i];
      else  vol = (double)tick_volume[i];          
      if (i<2)
      {
         vemas[i][_numf] = (vol*price);
         vemas[i][_denf] = (vol);
         vemas[i][_nums] = (vol*price);
         vemas[i][_dens] = (vol);
         continue;
      }            
      vemas[i][_numf] = vemas[i-1][_numf]+alphaf*(vol*price-vemas[i-1][_numf]);
      vemas[i][_denf] = vemas[i-1][_denf]+alphaf*(vol      -vemas[i-1][_denf]);
      vemas[i][_emaf] = vemas[i][_numf]/vemas[i][_denf];
      vemas[i][_nums] = vemas[i-1][_nums]+alphas*(vol*price-vemas[i-1][_nums]);
      vemas[i][_dens] = vemas[i-1][_dens]+alphas*(vol      -vemas[i-1][_dens]);
      vemas[i][_emas] = vemas[i][_nums]/vemas[i][_dens];

         macd[i]   = vemas[i][_emaf]-vemas[i][_emas];
         signal[i] = signal[i-1]+alphag*(macd[i]-signal[i-1]);
         osmau[i]  = macd[i]-signal[i];
         osmad[i]  = 0;
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


double workHa[][4];
double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
{
  if (price>=pr_haclose && price<=pr_haaverage)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars);

         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][2] + workHa[i-1][3])/2.0;
         else   haOpen  = open[i]+close[i];
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][0] = haLow;  workHa[i][1] = haHigh; } 
         else                 { workHa[i][0] = haHigh; workHa[i][1] = haLow;  } 
                                workHa[i][2] = haOpen;
                                workHa[i][3] = haClose;
         //
         //
         //
         //
         //
         
         switch (price)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
         }
   }
   
   //
   //
   //
   //
   //
   
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