//+------------------------------------------------------------------+
//|                                              step stochastic.mq5 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"
#property version   "1.00"

//
//
//
//
//

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3

#property indicator_type1   DRAW_FILLING
#property indicator_color1  DeepSkyBlue,PaleVioletRed
#property indicator_label1  "Step stochastic filling"
#property indicator_type2   DRAW_LINE
#property indicator_color2  DimGray
#property indicator_width2  2
#property indicator_label2  "Step stochastic"
#property indicator_type3   DRAW_LINE
#property indicator_color3  DimGray
#property indicator_width3  2
#property indicator_label3  "Step stochastic signal"
#property indicator_minimum 0
#property indicator_maximum 100

//
//
//
//
//

input ENUM_APPLIED_PRICE Price      = PRICE_MEDIAN; // Price to use in calculations
input int                AtrPeriod  = 10;           // ATR calculation period
input double             K_Slow     = 1.0;          // K slow 
input double             K_Fast     = 1.0;          // K fast
input int                Window     = 256;          // ATR minimum maximum window size

//
//
//
//
//
//

double stoch1[];
double stoch2[];
double fill1[];
double fill2[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer( 0,fill1,INDICATOR_DATA);
   SetIndexBuffer( 1,fill2,INDICATOR_DATA);
   SetIndexBuffer( 2,stoch1,INDICATOR_DATA);
   SetIndexBuffer( 3,stoch2,INDICATOR_DATA);
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

double work[][13];
#define k_SminMin   0
#define k_SmaxMin   1
#define k_SminMid   2
#define k_SmaxMid   3
#define k_SminMax   4
#define k_SmaxMax   5
#define k_TrendMin  6
#define k_TrendMid  7
#define k_TrendMax  8
#define k_linemin   9 
#define k_linemid  10
#define k_linemax  11
#define k_atr      12
#define bigValue   99999999

//
//
//
//
//

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{

   //
   //
   //
   //
   //
  
      if (ArrayRange(work,0)!=rates_total) ArrayResize(work,rates_total);
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
      {
         double nPrice;
         switch (Price)
         {
            case PRICE_CLOSE    : nPrice = Close[i]; break;
            case PRICE_OPEN     : nPrice = Open[i];  break;
            case PRICE_HIGH     : nPrice = High[i];  break;
            case PRICE_LOW      : nPrice = Low[i];   break;
            case PRICE_MEDIAN   : nPrice = (High[i]+Low[i])/2.0; break;
            case PRICE_TYPICAL  : nPrice = (High[i]+Low[i]+Close[i])/3.0; break;
            case PRICE_WEIGHTED : nPrice = (High[i]+Low[i]+Close[i]+Close[i])/4.0; break;
            default : nPrice = 0;
         }            
                
         //
         //
         //
         //
         //

         double atr = 0; for (int k=0; k<AtrPeriod && (i-k-1)>=0; k++) atr += MathMax(High[i-k],Low[i-k-1])-MathMin(Low[i-k],High[i-k-1]);
             work[i][k_atr] = atr/AtrPeriod;         
             if (i<Window)
             {
                  work[i][k_TrendMin] = 0;
                  work[i][k_TrendMid] = 0;
                  work[i][k_TrendMax] = 0;
                  work[i][k_linemin]  = 0;
                  work[i][k_linemid]  = 0;
                  work[i][k_linemax]  = 0;
                  work[i][k_SminMin]  = bigValue;
                  work[i][k_SmaxMin]  = bigValue;
                  work[i][k_SminMax]  = 0;
                  work[i][k_SmaxMax]  = 0;
                  work[i][k_SminMid]  = 0;
                  work[i][k_SmaxMid]  = 0;
                  stoch1[i] = EMPTY_VALUE;
                  stoch2[i] = EMPTY_VALUE;
                  fill1[i]  = EMPTY_VALUE;
                  fill2[i]  = EMPTY_VALUE;
                  continue;
             }

      //
      //
      //
      //
      //
      
         double nATRmax = work[i][k_atr];
         double nATRmin = work[i][k_atr];
            for (int k=1; k<Window && (i-k)>=0; k++)
               {
                  nATRmax = MathMax(nATRmax,work[i-k][k_atr]); 
                  nATRmin = MathMin(nATRmin,work[i-k][k_atr]); 
               }                  
         double StepSizeMin = (K_Fast * nATRmin);
         double StepSizeMax = (K_Fast * nATRmax);
         double StepSizeMid = (K_Fast * 0.5 * K_Slow * (nATRmax + nATRmin));

            work[i][k_SmaxMin] = nPrice + 2.0 * StepSizeMin;
            work[i][k_SminMin] = nPrice - 2.0 * StepSizeMin;
            work[i][k_SmaxMax] = nPrice + 2.0 * StepSizeMax;
            work[i][k_SminMax] = nPrice - 2.0 * StepSizeMax;
            work[i][k_SmaxMid] = nPrice + 2.0 * StepSizeMid;
            work[i][k_SminMid] = nPrice - 2.0 * StepSizeMid;

            //
            //
            //
            //
            //
         
            double TrendMin = work[i-1][k_TrendMin];
            double TrendMid = work[i-1][k_TrendMid];
            double TrendMax = work[i-1][k_TrendMax];
            double linemin  = work[i-1][k_linemin];
            double linemid  = work[i-1][k_linemid];
            double linemax  = work[i-1][k_linemax];

            //
            //
            //
            //
            //
                        
            if (nPrice > work[i-1][k_SmaxMin]) TrendMin =  1;
            if (nPrice < work[i-1][k_SminMin]) TrendMin = -1;
            if (nPrice > work[i-1][k_SmaxMax]) TrendMax =  1;
            if (nPrice < work[i-1][k_SminMax]) TrendMax = -1;
            if (nPrice > work[i-1][k_SmaxMid]) TrendMid =  1;
            if (nPrice < work[i-1][k_SminMid]) TrendMid = -1;

            if (TrendMin > 0 && work[i][k_SminMin] < work[i-1][k_SminMin]) work[i][k_SminMin] = work[i-1][k_SminMin];
            if (TrendMin < 0 && work[i][k_SmaxMin] > work[i-1][k_SmaxMin]) work[i][k_SmaxMin] = work[i-1][k_SmaxMin];
            if (TrendMax > 0 && work[i][k_SminMax] < work[i-1][k_SminMax]) work[i][k_SminMax] = work[i-1][k_SminMax];
            if (TrendMax < 0 && work[i][k_SmaxMax] > work[i-1][k_SmaxMax]) work[i][k_SmaxMax] = work[i-1][k_SmaxMax];
            if (TrendMid > 0 && work[i][k_SminMid] < work[i-1][k_SminMid]) work[i][k_SminMid] = work[i-1][k_SminMid];
            if (TrendMid < 0 && work[i][k_SmaxMid] > work[i-1][k_SmaxMid]) work[i][k_SmaxMid] = work[i-1][k_SmaxMid];

            if (TrendMin > 0) linemin = work[i][k_SminMin] + StepSizeMin;
            if (TrendMin < 0) linemin = work[i][k_SmaxMin] - StepSizeMin;
            if (TrendMax > 0) linemax = work[i][k_SminMax] + StepSizeMax;
            if (TrendMax < 0) linemax = work[i][k_SmaxMax] - StepSizeMax;
            if (TrendMid > 0) linemid = work[i][k_SminMid] + StepSizeMid;
            if (TrendMid < 0) linemid = work[i][k_SmaxMid] - StepSizeMid;

         //
         //
         //
         //
         //
               
         work[i][k_TrendMin] = TrendMin;
         work[i][k_TrendMid] = TrendMid;
         work[i][k_TrendMax] = TrendMax;
         work[i][k_linemin]  = linemin;
         work[i][k_linemid]  = linemid;
         work[i][k_linemax]  = linemax;
            
         //
         //
         //
         //
         //
         
         double bsmin = linemax - StepSizeMax;
         double bsmax = linemax + StepSizeMax;
         if (bsmax!=bsmin)
         {
            stoch1[i] = ((linemin - bsmin) / (bsmax - bsmin)) * 100.0;
            stoch2[i] = ((linemid - bsmin) / (bsmax - bsmin)) * 100.0;
         }
         else               
         {
            stoch1[i] = 0;
            stoch2[i] = 0;
         }
         fill1[i] = stoch1[i];
         fill2[i] = stoch2[i];
      }
   //
   //
   //
   //
   //
   
   return(rates_total);
}