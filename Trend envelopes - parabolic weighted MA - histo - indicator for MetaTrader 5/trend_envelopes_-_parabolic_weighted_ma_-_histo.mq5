//------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "Trend envelopes - of parabolic weighted MA - histo"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Trend envelope histo"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDodgerBlue,clrCrimson
#property indicator_width1  2
#property indicator_minimum 0
#property indicator_maximum 1
//
//--- input parameters
//
input double    inpDeviation = 0.1;     // Trend envelopes deviation %
input int       inpPwmaPeriod = 14;     // PWMA period (<=1 for no smoothing)
input double    inpPwmaPower  = 2;      // PWMA power
                                        //
//--- indicator buffers
//

double histo[],histoc[];
//
//--- custom structures
//

struct sTrendEnvelope
  {
   double            upline;
   double            downline;
   int               trend;
   bool              trendChange;
  };
  
//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
int OnInit()
  {
   SetIndexBuffer(0,histo,INDICATOR_DATA);
   SetIndexBuffer(1,histoc,INDICATOR_COLOR_INDEX);
   IndicatorSetString(INDICATOR_SHORTNAME,"PWMA Trend envelopes ("+(string)inpDeviation+")("+(string)inpPwmaPeriod+" "+(string)inpPwmaPower+")");
   return(INIT_SUCCEEDED);
  }
//------------------------------------------------------------------
// Custom indicator de-initialization function
//------------------------------------------------------------------
void OnDeinit(const int reason) { return; }
//------------------------------------------------------------------
// Custom iteration function
//------------------------------------------------------------------
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total) return(-1);

//
//---
//

   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !_StopFlag; i++)
     {
      double _high = iPwma(high[i],inpPwmaPeriod,inpPwmaPower,i,rates_total,0);
      double _low  = iPwma(low[i] ,inpPwmaPeriod,inpPwmaPower,i,rates_total,1);
      sTrendEnvelope _result=iTrendEnvelope(_high,_low,close[i],inpDeviation,i,rates_total);
      histo[i] = 1;
      histoc[i] = (_result.trend==1) ? 0 : 1;
     }
   return(rates_total);
  }
//------------------------------------------------------------------
// Custom functions
//------------------------------------------------------------------
#define _pwmaInstances 2
#define _pwmaInstancesSize 1
double workPwma[][_pwmaInstances*_pwmaInstancesSize];
//
//---
//
double iPwma(double price, double period, double power, int i, int bars, int instanceNo=0)
{
   if (ArraySize(workPwma)!= bars) ArrayResize(workPwma,bars);
   
   //
   //---
   //
   
   workPwma[i][instanceNo] = price;
      double sum  = 0;
      double sumw = 0;

      for(int k=0; k<period && (i-k)>=0; k++)
      {
         double weight = MathPow((period-k),power);
                sumw  += weight;
                sum   += weight*workPwma[i-k][instanceNo];  
      }             
      return(sumw!=0?sum/sumw:price);
}
//
//---
//
#define _trendEnvelopesInstances 1
#define _trendEnvelopesInstancesSize 3
double workTrendEnvelopes[][_trendEnvelopesInstances*_trendEnvelopesInstancesSize];
#define _teSmin  0
#define _teSmax  1 
#define _teTrend 2
//
//---
//

sTrendEnvelope iTrendEnvelope(double valueh,double valuel,double value,double deviation,int i,int bars,int instanceNo=0)
  {
   if(ArrayRange(workTrendEnvelopes,0)!=bars) ArrayResize(workTrendEnvelopes,bars); instanceNo*=_trendEnvelopesInstancesSize;

//
//---
//

   workTrendEnvelopes[i][instanceNo+_teSmax]  = (1+deviation/100)*valueh;
   workTrendEnvelopes[i][instanceNo+_teSmin]  = (1-deviation/100)*valuel;
   workTrendEnvelopes[i][instanceNo+_teTrend] = (i>0) ? (value>workTrendEnvelopes[i-1][instanceNo+_teSmax]) ? 1 : (value<workTrendEnvelopes[i-1][instanceNo+_teSmin]) ? -1 : workTrendEnvelopes[i-1][instanceNo+_teTrend] : 0;
   if(i>0 && workTrendEnvelopes[i][instanceNo+_teTrend]>0 && workTrendEnvelopes[i][instanceNo+_teSmin]<workTrendEnvelopes[i-1][instanceNo+_teSmin]) workTrendEnvelopes[i][instanceNo+_teSmin] = workTrendEnvelopes[i-1][instanceNo+_teSmin];
   if(i>0 && workTrendEnvelopes[i][instanceNo+_teTrend]<0 && workTrendEnvelopes[i][instanceNo+_teSmax]>workTrendEnvelopes[i-1][instanceNo+_teSmax]) workTrendEnvelopes[i][instanceNo+_teSmax] = workTrendEnvelopes[i-1][instanceNo+_teSmax];

//
//---
//

   sTrendEnvelope _result;
   _result.trend       = (int)workTrendEnvelopes[i][instanceNo+_teTrend];
   _result.trendChange = (i>0) ? ( workTrendEnvelopes[i][instanceNo+_teTrend]!=workTrendEnvelopes[i-1][instanceNo+_teTrend]) : false;
   _result.upline      = (workTrendEnvelopes[i][instanceNo+_teTrend]== 1) ? workTrendEnvelopes[i][instanceNo+_teSmin] : EMPTY_VALUE;
   _result.downline    = (workTrendEnvelopes[i][instanceNo+_teTrend]==-1) ? workTrendEnvelopes[i][instanceNo+_teSmax] : EMPTY_VALUE;
   return(_result);
  };
//+------------------------------------------------------------------+
