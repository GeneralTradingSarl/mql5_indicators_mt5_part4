//properties
   #property copyright "Copyright 2016, quebralim"
   #property link      "https://www.mql5.com/en/users/quebralim"
   #property version   "1.4"
   #property description  "Trends Accumulator"
   #property indicator_separate_window
   #property indicator_buffers 2
   #property indicator_plots   1
   #property indicator_type1   DRAW_HISTOGRAM
   #property indicator_color1  clrBlueViolet
   #property indicator_width1  10
   #property indicator_label1  "Trends Accumulator"
//inputs
   input uint                 Threshold   =20;              //Threshold (in points)
   input uint                 MA_Period   =6;               //MA Period (in bars)
   input ENUM_MA_METHOD       MA_Method   =MODE_EMA;        //MA Method
   input ENUM_APPLIED_PRICE   MA_Price    =PRICE_TYPICAL;   //MA Price
//globals
   double bTA[];  // TA Buffer
   double bMA[];  // MA Buffer
   int hMA;       // MA Handler


//+------------------------------------------------------------------+
//|         Indicador Initialization Function                        |
//+------------------------------------------------------------------+
int OnInit()
  {
   //inputs checks
   if(MA_Period<1)
      return INIT_PARAMETERS_INCORRECT;

   //index inits
   SetIndexBuffer(0,bTA,INDICATOR_DATA);
   SetIndexBuffer(1,bMA,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,MA_Period);
   
   //indicator name init
   IndicatorSetString(INDICATOR_SHORTNAME,"Trend Accumulator ("+(string)Threshold+","+(string)MA_Period+")");

   //MA init
   hMA=iMA(_Symbol,_Period,MA_Period,0,MA_Method,MA_Price);
   if (hMA == INVALID_HANDLE){
      Print("Failed to initilize the MA indicator!");
      return INIT_FAILED;
   }
   
   //success!
   return INIT_SUCCEEDED;
  }
  
  
//+------------------------------------------------------------------+
//|         Calculation function                                     |
//+------------------------------------------------------------------+
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
   //is there enough data?
   if(rates_total<=(int)MA_Period)
     {
      return 0;
     }

   //is MA ready for copy?
   ResetLastError();
   if(BarsCalculated(hMA)<rates_total)
     {
      Print("Not all data of MA is calculated. Error #",GetLastError());
      return prev_calculated;
     }

   //how much of MA shall we copy?
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      to_copy=rates_total;
     }
   else
     {
      to_copy=rates_total-prev_calculated+2;
     }

   //test if stopped before large operation
   if(IsStopped())
     {
      return 0;
     }

   //copy MA buffer
   ResetLastError();
   if(CopyBuffer(hMA,0,0,to_copy,bMA)<=0)
     {
      Print("Failed getting MA! Error #",GetLastError());
      return prev_calculated;
     }

   //calculate start
   int i;
   if(prev_calculated<=(int)MA_Period)
     {
      i=(int)MA_Period;
     }
   else
     {
      i=prev_calculated-1;
     }

   //calculate TA through start...i...rates_total
   int iMax;
   while(i<rates_total-1)
     {
      //stop clause
      if(IsStopped())
        {
         return 0;
        }

      //first value
      bTA[i]=bTA[i-1]+bMA[i]-bMA[i-1];

      //last max value
      if(bTA[i]*bTA[i-1]>0)
        {
         iMax=MaxAround(i);
        }
      else
        {
         iMax=MaxAround(i-1);
        }

      //rewrite if necessary
      if((bTA[iMax]>0 && bTA[iMax]-bTA[i]>=Threshold*_Point) //if it's fallen too low
      || (bTA[iMax]<0 && bTA[i]-bTA[iMax]>=Threshold*_Point))
        { //if it's risen too high
         bTA[iMax+1]=bMA[iMax+1]-bMA[iMax];
         for(int k=iMax+2; k<=i;++k)
           {
            bTA[k]=bTA[k-1]+bMA[k]-bMA[k-1];
           }
        }

      //increment
      ++i;
     }
   //only estimate the last signal
   bTA[i]=bTA[i-1]+bMA[i]-bMA[i-1];

   //done
   return i;
  }
  
  
//+------------------------------------------------------------------+
//|         Max Around                                               |                                                                  |
//+------------------------------------------------------------------+
//Returns: the index to the absolute max value within the current Trend
int MaxAround(int i)
  {
   int iMax=i;
   //positive version
   if(bTA[i]>0)
     {
      while(i > 0 && bTA[--i]>0)
        {
         if(bTA[i]>bTA[iMax])
           {
            iMax=i;
           }
        }
     }
   //negative version
   else if(bTA[i]<0)
     {
      while(i > 0 && bTA[--i]<0)
        {
         if(bTA[i]<bTA[iMax])
           {
            iMax=i;
           }
        }
     }
   //return
   return iMax;
  }
//+------------------------------------------------------------------+
