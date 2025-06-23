//------------------------------------------------------------------

   #property copyright "mladen"
   #property link      "www.forex-tsd.com"

//------------------------------------------------------------------

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   3

#property indicator_label1  "ZlTema long"
#property indicator_type1   DRAW_LINE
#property indicator_color1  DarkGray
#property indicator_style1  STYLE_DOT
#property indicator_label2  "ZlTema short"
#property indicator_type2   DRAW_LINE
#property indicator_color2  DarkGray
#property indicator_style2  STYLE_DOT
#property indicator_label3  "ZlTemaTrend"
#property indicator_type3   DRAW_COLOR_BARS
#property indicator_color3  DeepSkyBlue,PaleVioletRed
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
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage   // Heiken ashi average
};
enum enLinesVisible
{
   lv_visible,   // ZeroLag lines visible
   lv_invisible, // ZeroLag lines not visible
};

//
//
//
//
//

input ENUM_TIMEFRAMES    TimeFrame        = PERIOD_CURRENT; // Time frame
input int                LongPeriod       = 55;             // Long period
input enPrices           LongPrice        = pr_haweighted;  // Long price
input int                ShortPeriod      = 55;             // Short period
input enPrices           ShortPrice       = pr_typical;     // Short price
input enLinesVisible     LinesVisible     = lv_visible;     // Lines 
input bool               Interpolate      = true;           // Interpolate mtf data
input bool               ViewAsCandles    = false;          // View as candles ?
input bool               alertsOn         = false;          // Alert on trend change
input bool               alertsOnCurrent  = true;           // Alert on current bar
input bool               alertsMessage    = true;           // Display messageas on alerts
input bool               alertsSound      = false;          // Play sound on alerts
input bool               alertsEmail      = false;          // Send email on alerts

//
//
//
//
//

double zlth[];
double zltl[];
double zlto[];
double zltc[];
double colorBuffer[];
double countBuffer[];
double longb[];
double shortb[];
ENUM_TIMEFRAMES timeFrame;
int             mtfHandle;
int             atrHandle;
bool            calculating;

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
   int style;
      style = DRAW_NONE; if (LinesVisible==lv_visible) style = DRAW_LINE;

         SetIndexBuffer(0,longb ,INDICATOR_DATA);  PlotIndexSetInteger(0,PLOT_DRAW_TYPE,style);
         SetIndexBuffer(1,shortb,INDICATOR_DATA);  PlotIndexSetInteger(1,PLOT_DRAW_TYPE,style);

      style = DRAW_COLOR_BARS; if (ViewAsCandles) style = DRAW_COLOR_CANDLES; 

         SetIndexBuffer(2,zlto,INDICATOR_DATA); PlotIndexSetInteger(2,PLOT_DRAW_TYPE,style);
         SetIndexBuffer(3,zlth,INDICATOR_DATA); PlotIndexSetInteger(3,PLOT_DRAW_TYPE,style);
         SetIndexBuffer(4,zltl,INDICATOR_DATA); PlotIndexSetInteger(4,PLOT_DRAW_TYPE,style);
         SetIndexBuffer(5,zltc,INDICATOR_DATA); PlotIndexSetInteger(5,PLOT_DRAW_TYPE,style);
         SetIndexBuffer(6,colorBuffer,INDICATOR_COLOR_INDEX); 
         SetIndexBuffer(7,countBuffer,INDICATOR_CALCULATIONS); 

   //
   //
   //
   //
   //
         
   timeFrame   = MathMax(_Period,TimeFrame);
   calculating = (timeFrame==_Period);
   if (!calculating)
         mtfHandle = iCustom(NULL,timeFrame,getIndicatorName(),PERIOD_CURRENT,LongPeriod,LongPrice,ShortPeriod,ShortPrice);

   IndicatorSetString(INDICATOR_SHORTNAME,getPeriodToString(timeFrame)+" ZeroLag tema trend ("+string(LongPeriod)+","+string(ShortPeriod)+")");
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


   if (calculating)
   {
         for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
         {
            if (LongPeriod > 1)
            {
               double tema10   = iTema(getPrice(LongPrice,open,close,high,low,i,rates_total),LongPeriod,i,rates_total,0);
               double tema11   = iTema(tema10                                               ,LongPeriod,i,rates_total,1);
                      longb[i] = 2.0*tema10-tema11; 
            }
            if (ShortPeriod > 1)
            {
               double tema20    = iTema(getPrice(ShortPrice,open,close,high,low,i,rates_total),ShortPeriod,i,rates_total,2);
               double tema21    = iTema(tema20                                                ,ShortPeriod,i,rates_total,3);
                      shortb[i] = 2.0*tema20-tema21; 
            }
            if (LongPeriod > 1 && ShortPeriod>1)
            {
               if (longb[i]>shortb[i]) colorBuffer[i] = 1;
               if (longb[i]<shortb[i]) colorBuffer[i] = 0;
                  zltc[i] = close[i];
                  zlto[i] = open[i];
                  zlth[i] = high[i];
                  zltl[i] = low[i];
            }
         }      
      
         //
         //
         //
         //
         //
         
         countBuffer[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
         manageAlerts(time[rates_total-1],time[rates_total-2],colorBuffer,rates_total);
      return(rates_total);
   }
   
   //
   //
   //
   //
   //
   
      if (BarsCalculated(mtfHandle)<LongPeriod) return(0);
         datetime times[]; 
         datetime startTime = time[0]-PeriodSeconds(timeFrame);
         datetime endTime   = time[rates_total-1];
         int bars = CopyTime(NULL,timeFrame,startTime,endTime,times);
        
         if (times[0]>time[0] || bars<1) return(rates_total);
               double tlong[]; CopyBuffer(mtfHandle,0,0,bars,tlong);
               double tshor[]; CopyBuffer(mtfHandle,1,0,bars,tshor);
               double tcolo[]; CopyBuffer(mtfHandle,6,0,bars,tcolo);
               double count[]; CopyBuffer(mtfHandle,7,0,bars,count);
         int maxb = (int)MathMax(MathMin(count[bars-1]*PeriodSeconds(timeFrame)/PeriodSeconds(_Period),rates_total-1),1);

         //
         //
         //
         //
         //
         
         bool drawLines = (LinesVisible==lv_visible && (LongPeriod>1 || ShortPeriod>1));
         for(int i=(int)MathMax(prev_calculated-maxb,0); i<rates_total; i++)
         {
            int d = dateArrayBsearch(times,time[i],bars);
            if (d > -1 && d < bars)
            {
               zltc[i]        = close[i];
               zlto[i]        = open[i];
               zlth[i]        = high[i];
               zltl[i]        = low[i];
               colorBuffer[i] = tcolo[d];
               if (drawLines)
               {
                  longb[i]  = tlong[d];
                  shortb[i] = tshor[d];
               }
            }
            
            if (!Interpolate || !drawLines) continue;
        
            //
            //
            //
            //
            //
         
            int j=MathMin(i+1,rates_total-1);

            if (d!=dateArrayBsearch(times,time[j],bars) || i==j)
            {
               int n,k;
                  for(n = 1; (i-n)> 0 && time[i-n] >= times[d] && n<(PeriodSeconds(timeFrame)/PeriodSeconds(_Period)); n++) continue;	
                  for(k = 1; (i-k)>=0 && k<n; k++)
                  {
                     if (LongPeriod>1)  longb[i-k]  = longb[i]  + (longb[i-n]  - longb[i] )*(double)k/n;
                     if (ShortPeriod>1) shortb[i-k] = shortb[i] + (shortb[i-n] - shortb[i])*(double)k/n;
                  }                  
            }
            
         }

   //
   //
   //
   //
   //
   
   manageAlerts(times[bars-1],times[bars-2],tcolo,bars);
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

void manageAlerts(datetime currTime, datetime prevTime, double& trend[], int bars)
{
   if (alertsOn)
   {
      datetime time     = currTime;
      int      whichBar = bars-1; if (!alertsOnCurrent) { whichBar = bars-2; time = prevTime; }
         
      //
      //
      //
      //
      //
         
      if (trend[whichBar] != trend[whichBar-1])
      {
         if (trend[whichBar] == 0) doAlert(time,"up");
         if (trend[whichBar] == 1) doAlert(time,"down");
      }         
   }
}   

//
//
//
//
//

void doAlert(datetime forTime, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      message = getPeriodToString(timeFrame)+" "+_Symbol+" at : "+TimeToString(TimeLocal(),TIME_SECONDS)+" Zero Lag tema trend changed to "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" Zero lag tema trend",message);
         if (alertsSound)   PlaySound("alert2.wav");
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


double workHa[][4];
double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
{

   //
   //
   //
   //
   //
   
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
   }
   return(0);
}

//
//
//
//
//

double workTema[][12];
#define _ema1 0
#define _ema2 1
#define _ema3 2

double iTema(double price, double period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workTema,0)!= bars) ArrayResize(workTema,bars); instanceNo*=3;

   //
   //
   //
   //
   //

   if (r==0)
   {
      workTema[r][_ema1+instanceNo] = price;
      workTema[r][_ema2+instanceNo] = price;
      workTema[r][_ema3+instanceNo] = price;
      return(price);
   }      
   double alpha = 2.0 / (1.0+period);
          workTema[r][_ema1+instanceNo] = workTema[r-1][_ema1+instanceNo]+alpha*(price                        -workTema[r-1][_ema1+instanceNo]);
          workTema[r][_ema2+instanceNo] = workTema[r-1][_ema2+instanceNo]+alpha*(workTema[r][_ema1+instanceNo]-workTema[r-1][_ema2+instanceNo]);
          workTema[r][_ema3+instanceNo] = workTema[r-1][_ema3+instanceNo]+alpha*(workTema[r][_ema2+instanceNo]-workTema[r-1][_ema3+instanceNo]);
   return(workTema[r][_ema3+instanceNo]+3.0*(workTema[r][_ema1+instanceNo]-workTema[r][_ema2+instanceNo]));
}

 
//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

string getIndicatorName()
{
   string progPath    = MQL5InfoString(MQL5_PROGRAM_PATH);
   string toFind      = "MQL5\\Indicators\\";
   int    startLength = StringFind(progPath,toFind)+StringLen(toFind);
         
         string indicatorName = StringSubstr(progPath,startLength);
                indicatorName = StringSubstr(indicatorName,0,StringLen(indicatorName)-4);
   return(indicatorName);
}

//
//
//
//
//
 
string getPeriodToString(int period)
{
   int i;
   static int    _per[]={1,2,3,4,5,6,10,12,15,20,30,0x4001,0x4002,0x4003,0x4004,0x4006,0x4008,0x400c,0x4018,0x8001,0xc001};
   static string _tfs[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes",
                         "15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours",
                         "12 hours","daily","weekly","monthly"};
   
   if (period==PERIOD_CURRENT) 
       period = Period();   
            for(i=0;i<20;i++) if(period==_per[i]) break;
   return(_tfs[i]);   
}


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

int dateArrayBsearch(datetime& times[], datetime toFind, int total)
{
   int mid   = 0;
   int first = 0;
   int last  = total-1;
   
   while (last >= first)
   {
      mid = (first + last) >> 1;
      if (toFind == times[mid] || (mid < (total-1) && (toFind > times[mid]) && (toFind < times[mid+1]))) break;
      if (toFind <  times[mid])
            last  = mid - 1;
      else  first = mid + 1;
   }
   return (mid);
}