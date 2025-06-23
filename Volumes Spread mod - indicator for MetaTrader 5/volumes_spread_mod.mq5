//+------------------------------------------------------------------+
//|                                                      Volumes.mq5 |
//|                   Copyright 2009-2020, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2020, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  Aqua
#property indicator_style1  0
#property indicator_width1  3
#property indicator_minimum 0.0
//--- input data
input ENUM_APPLIED_VOLUME InpVolumeType=VOLUME_TICK; // Volumes
input bool spreadchoice = true; // Use Spread?
//--- indicator buffers
double ExtVolumesBuffer[];
double ExtColorsBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- buffers
   SetIndexBuffer(0,ExtVolumesBuffer,INDICATOR_DATA);
   ArraySetAsSeries(ExtVolumesBuffer,true);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"Volumes");
//--- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,0);
  }
//+------------------------------------------------------------------+
//|  Volumes                                                         |
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
   if(InpVolumeType==VOLUME_TICK)
  ArraySetAsSeries(tick_volume,true);
  else ArraySetAsSeries(volume,true);
  ArraySetAsSeries(spread,true);
   if(rates_total<2)
      return(0);
//--- starting work
   int pos=prev_calculated-1;
//--- correct position
   if(pos<1)
     {
      ExtVolumesBuffer[0]=0;
      pos=1;
     }
//--- main cycle
   if(InpVolumeType==VOLUME_TICK)
      CalculateVolume(pos,rates_total,tick_volume,spread);
   else
      CalculateVolume(pos,rates_total,volume,spread);
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateVolume(const int pos,const int rates_total,const long& volume[],const int &spread[])
  {
   ExtVolumesBuffer[0]=(double)volume[0];
//---
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {
      double curr_volume;
      int curr_spread=(int)spread[i];
      if(spread[i]==0) curr_spread=1;
      if(spreadchoice==true)
        curr_volume=(double)volume[i]/curr_spread;
      else
        curr_volume=(double)volume[i];
      //--- calculate indicator
      ExtVolumesBuffer[i]=curr_volume;
     }
//---
  }
//+------------------------------------------------------------------+
