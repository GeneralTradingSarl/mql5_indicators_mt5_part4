//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   5

#property indicator_label1  "super passband level fill"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrDodgerBlue,clrSandyBrown
#property indicator_label2  "super passband level up"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_DOT
#property indicator_label3  "super passband middle level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DOT
#property indicator_label4  "super passband level down"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSandyBrown
#property indicator_style4  STYLE_DOT
#property indicator_label5  "supper passband"
#property indicator_type5   DRAW_COLOR_LINE
#property indicator_color5  clrSilver,clrDodgerBlue,clrSandyBrown
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

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
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};
enum enColorOn
{
   cc_onSlope,   // Change color on slope change
   cc_onMiddle,  // Change color on middle line cross
   cc_onLevels   // Change color on outer levels cross
};

input double             Period1             = 40;             // Period 1
input double             Period2             = 60;             // Period 2
input int                RmsCount            = 50;             // Calculation count
input enPrices           Price               = pr_close;       // Price to use
input enColorOn          ColorOn             = cc_onLevels;    // Color change :

double buffer[],levelup[],levelmi[],leveldn[],fill1[],fill2[],trend[],prices[];


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
   SetIndexBuffer(0,fill1  ,INDICATOR_DATA);
   SetIndexBuffer(1,fill2  ,INDICATOR_DATA);
   SetIndexBuffer(2,levelup,INDICATOR_DATA);
   SetIndexBuffer(3,levelmi,INDICATOR_DATA);
   SetIndexBuffer(4,leveldn,INDICATOR_DATA);
   SetIndexBuffer(5,buffer ,INDICATOR_DATA);
   SetIndexBuffer(6,trend  ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(7,prices ,INDICATOR_CALCULATIONS);
   return(0);
}

//
//
//
//
//

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
   double a1 = 5.0 / Period1 ;
   double a2 = 5.0 / Period2 ;
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
         prices[i] = getPrice(Price,open,close,high,low,i,rates_total);
            if (i<2) { buffer[i] = prices[i]; continue; }
            buffer[i]  = (a1-a2)*prices[i] + (a2*(1-a1)-a1*(1-a2))*prices[i-1] + ((1-a1)+(1-a2))*buffer[i-1]-(1-a1)*(1-a2)*buffer[i-2];
            double rms = 0; for (int k=0; k<RmsCount && (i-k)>=0; k++) rms += buffer[i-k]*buffer[i-k];
                   rms = MathSqrt(rms/RmsCount);
            
            levelup[i] = rms;
            levelmi[i] = 0;
            leveldn[i] = -rms;
            trend[i]   = 0;
            switch(ColorOn)
            {
               case cc_onLevels:
                  if (buffer[i]>levelup[i]) trend[i] = 1;
                  if (buffer[i]<leveldn[i]) trend[i] = 2;
                  break;
               case cc_onMiddle:                  
                  if (buffer[i]>levelmi[i]) trend[i] = 1;
                  if (buffer[i]<levelmi[i]) trend[i] = 2;
                  break;
               default :
                  if (i>0)
                  {
                     if (buffer[i]>buffer[i-1]) trend[i] = 1;
                     if (buffer[i]<buffer[i-1]) trend[i] = 2;
                  }                  
            }                  
         
         //
         //
         //
         //
         //
         
      fill1[i] = buffer[i];
      fill2[i] = buffer[i];
      if (buffer[i]>levelup[i]) fill2[i] = levelup[i]; 
      if (buffer[i]<leveldn[i]) fill2[i] = leveldn[i]; 
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
//

double workHa[][4];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int _bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) ArrayResize(workHa,_bars); int r=i;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (r>0)
                haOpen  = (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else                 { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                                workHa[r][instanceNo+2] = haOpen;
                                workHa[r][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
   }
   return(0);
}   