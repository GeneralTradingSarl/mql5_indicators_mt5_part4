//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers   9
#property indicator_plots     2

#property indicator_label1  "T3 velocity"
#property indicator_type1   DRAW_COLOR_BARS
#property indicator_color1  clrDeepSkyBlue,clrBurlyWood,clrNONE
#property indicator_width1  2
#property indicator_label2  "T3 velocity"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrLimeGreen,clrSandyBrown,clrSilver
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

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
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
};
enum enStyles
{
   st_automatic, // automatically adjust style
   st_bars,      // view as bars
   st_candles,   // view as candles
   st_line       // view as line
};

input double   T3Period    = 32;             // T3 velocity calculation period
input double   T3Hot       = 0.7;            // T3 hot value
input bool     T3Original  = false;          // T3 original Tillson calculation?
input enPrices Price       = pr_close;       // Price to use
input int      ColorNorm   = 20;             // Colors normalization period
input color    ColorFrom   = clrSandyBrown;  // Color down
input color    ColorTo     = clrDeepSkyBlue; // Color Up
input int      ColorSteps  = 20;             // Color steps for drawing
input enStyles Style       = st_automatic;   // Style

//
//
//
//
//
//

double vel[];
double barh[];
double barl[];
double baro[];
double barc[];
double colorBuffer[];
double line[];
double cololBuffer[];

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
   SetIndexBuffer(0,baro            ,INDICATOR_DATA); 
   SetIndexBuffer(1,barh            ,INDICATOR_DATA);
   SetIndexBuffer(2,barl            ,INDICATOR_DATA);
   SetIndexBuffer(3,barc            ,INDICATOR_DATA);
   SetIndexBuffer(4,colorBuffer     ,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(5,line            ,INDICATOR_DATA); 
   SetIndexBuffer(6,cololBuffer     ,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(7,vel             ,INDICATOR_CALCULATIONS); 
   cSteps = (ColorSteps>1) ? ColorSteps : 2;
      PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,cSteps+1);
      PlotIndexSetInteger(1,PLOT_COLOR_INDEXES,cSteps+1);
      for (int i=0;i<cSteps+1;i++) PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,gradientColor(i,cSteps+1,ColorFrom,ColorTo));
      for (int i=0;i<cSteps+1;i++) PlotIndexSetInteger(1,PLOT_LINE_COLOR,i,gradientColor(i,cSteps+1,ColorFrom,ColorTo));
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
   
      static bool styleSetUp = false;
      static int  styleInUse = -1;
      static int  styleToUse; int calculated = prev_calculated;
             int  style = (int)ChartGetInteger(0,CHART_MODE,0);
      
      //
      //
      //
      //
      //
      
      if (!styleSetUp || (Style==st_automatic && styleInUse!=style))
      {
         if (Style==st_automatic)
            switch(style)
            {
               case CHART_BARS:    styleToUse = DRAW_COLOR_BARS;    break;
               case CHART_CANDLES: styleToUse = DRAW_COLOR_CANDLES; break;
               case CHART_LINE:    styleToUse = DRAW_COLOR_LINE;    break;
            }
         else
            switch(Style)
            {
               case st_bars:    styleToUse = DRAW_COLOR_BARS;    break;
               case st_candles: styleToUse = DRAW_COLOR_CANDLES; break;
               case st_line:    styleToUse = DRAW_COLOR_LINE; break;
            }
            styleInUse = style;
            if (styleToUse==DRAW_COLOR_LINE)
                  PlotIndexSetInteger(1,PLOT_DRAW_TYPE,styleToUse);
            else  PlotIndexSetInteger(0,PLOT_DRAW_TYPE,styleToUse);
            calculated = 0;
      }            

   //
   //
   //
   //
   //

   for (int i=(int)MathMax(calculated-1,0); i<rates_total; i++)
   {
      double price = getPrice(Price,open,close,high,low,i,rates_total);
             vel[i]  = iT3(price,T3Period,T3Hot,T3Original,i,rates_total,0)-iT3(price,T3Period,T3Hot/2.0,T3Original,i,rates_total,1);      
             line[i] = EMPTY_VALUE;
             baro[i] = EMPTY_VALUE;
             barc[i] = EMPTY_VALUE;
             barh[i] = EMPTY_VALUE;
             barl[i] = EMPTY_VALUE;
             if (styleToUse==DRAW_COLOR_LINE)
                  line[i] = close[i];
             else
               {                  
                  baro[i] = open[i];
                  barc[i] = close[i];
                  barh[i] = high[i];         
                  barl[i] = low[i];         
               }
             double min = vel[i];
             double max = vel[i];
             double sto = 50;
             for (int k=1; k<ColorNorm && (i-k)>=0; k++)
               {
                  min = MathMin(min,vel[i-k]);
                  max = MathMax(max,vel[i-k]);
               }
               if (max!=min)
                  sto = 100*(vel[i]-min)/(max-min);
                  cololBuffer[i] = MathFloor(sto*cSteps/100.0);                                  
                  colorBuffer[i] = MathFloor(sto*cSteps/100.0);                                  
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

double workT3[][12];
double workT3Coeffs[][12];
#define _period 0
#define _c1     1
#define _c2     2
#define _c3     3
#define _c4     4
#define _alpha  5

//
//
//
//
//

double iT3(double price, double period, double hot, bool original, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workT3,0) != bars)                ArrayResize(workT3,bars);
   if (ArrayRange(workT3Coeffs,0) < (instanceNo+1)) ArrayResize(workT3Coeffs,instanceNo+1);

   if (workT3Coeffs[instanceNo][_period] != period)
   {
     workT3Coeffs[instanceNo][_period] = period;
        double a = hot;
            workT3Coeffs[instanceNo][_c1] = -a*a*a;
            workT3Coeffs[instanceNo][_c2] = 3*a*a+3*a*a*a;
            workT3Coeffs[instanceNo][_c3] = -6*a*a-3*a-3*a*a*a;
            workT3Coeffs[instanceNo][_c4] = 1+3*a+a*a*a+3*a*a;
            if (original)
                 workT3Coeffs[instanceNo][_alpha] = 2.0/(1.0 + period);
            else workT3Coeffs[instanceNo][_alpha] = 2.0/(2.0 + (period-1.0)/2.0);
   }
   
   //
   //
   //
   //
   //
   
   int buffer = instanceNo*6;
   if (r == 0)
      {
         workT3[r][0+buffer] = price;
         workT3[r][1+buffer] = price;
         workT3[r][2+buffer] = price;
         workT3[r][3+buffer] = price;
         workT3[r][4+buffer] = price;
         workT3[r][5+buffer] = price;
      }
   else
      {
         workT3[r][0+buffer] = workT3[r-1][0+buffer]+workT3Coeffs[instanceNo][_alpha]*(price              -workT3[r-1][0+buffer]);
         workT3[r][1+buffer] = workT3[r-1][1+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][0+buffer]-workT3[r-1][1+buffer]);
         workT3[r][2+buffer] = workT3[r-1][2+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][1+buffer]-workT3[r-1][2+buffer]);
         workT3[r][3+buffer] = workT3[r-1][3+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][2+buffer]-workT3[r-1][3+buffer]);
         workT3[r][4+buffer] = workT3[r-1][4+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][3+buffer]-workT3[r-1][4+buffer]);
         workT3[r][5+buffer] = workT3[r-1][5+buffer]+workT3Coeffs[instanceNo][_alpha]*(workT3[r][4+buffer]-workT3[r-1][5+buffer]);
      }

   //
   //
   //
   //
   //
   
   return(workT3Coeffs[instanceNo][_c1]*workT3[r][5+buffer] + 
          workT3Coeffs[instanceNo][_c2]*workT3[r][4+buffer] + 
          workT3Coeffs[instanceNo][_c3]*workT3[r][3+buffer] + 
          workT3Coeffs[instanceNo][_c4]*workT3[r][2+buffer]);
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
double getPrice(int price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars, int instanceNo=0)
{
  if (price>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars);
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;
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
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
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
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
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