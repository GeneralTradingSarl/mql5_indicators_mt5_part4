//+-------------------------------------------------------------------------------------+
//|                                                                  ENTRY.TimedMAs.mq5 |
//| (CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License|
//|                                                          http://www.MinionsLabs.com |
//+-------------------------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Descriptors                                                      |
//+------------------------------------------------------------------+
#property copyright   "www.MinionsLabs.com"
#property link        "http://www.MinionsLabs.com"
#property version     "1.0"
#property description "Minions in the quest for showing you the Perfect Timing through MAs"
#property description " "
#property description "(CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License"


//+------------------------------------------------------------------+
//| Indicator Settings                                               |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

#property indicator_label1  "MA1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_DOT
#property indicator_width1  1

#property indicator_label2  "MA2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_label3  "MA3"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrOrange
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

#property indicator_label4  "MA4"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDodgerBlue
#property indicator_style4  STYLE_DOT
#property indicator_width4  1

#property indicator_label5  "MA5"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrDarkOrchid
#property indicator_style5  STYLE_DOT
#property indicator_width5  1

#property indicator_label6  "MA6"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrDarkGray
#property indicator_style6  STYLE_DASH
#property indicator_width6  1

//+------------------------------------------------------------------+
//| Inputs from User Interface                                       |
//+------------------------------------------------------------------+
input int                inpMA1Period    = 15;             // MA1 Period (M1=15/M5=0/M15=0)
input int                inpMA2Period    = 30;             // MA2 Period (M1=30/M5=0/M15=0)
input int                inpMA3Period    = 60;             // MA3 Period (M1=60/M5=12/M15=0)
input int                inpMA4Period    = 120;            // MA4 Period (M1=120/M5=24/M15=8)
input int                inpMA5Period    = 180;            // MA5 Period (M1=180/M5=36/M15=12)
input int                inpMA6Period    = 540;            // MA6 Period (M1=540/M5=108/M15=36)
input ENUM_MA_METHOD     inpMethod       = MODE_EMA;       // Smoothing Method
input ENUM_APPLIED_PRICE inpAppliedPrice = PRICE_CLOSE;    // MA Price used


//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
//... buffer identifiers (for easy reading)
int bufferMA1_ID=0;
int bufferMA2_ID=1;
int bufferMA3_ID=2;
int bufferMA4_ID=3;
int bufferMA5_ID=4;
int bufferMA6_ID=5;

//... indicator buffers
double bufferMA1[]; 
double bufferMA2[]; 
double bufferMA3[]; 
double bufferMA4[];
double bufferMA5[];
double bufferMA6[]; 

int hMA1;                 // MAs indicators handles
int hMA2;
int hMA3;
int hMA4;
int hMA5;
int hMA6;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()   {

    // BUFFER ASSIGNMENTS...
    SetIndexBuffer( bufferMA1_ID,  bufferMA1, INDICATOR_DATA );
    SetIndexBuffer( bufferMA2_ID,  bufferMA2, INDICATOR_DATA );
    SetIndexBuffer( bufferMA3_ID,  bufferMA3, INDICATOR_DATA );
    SetIndexBuffer( bufferMA4_ID,  bufferMA4, INDICATOR_DATA );
    SetIndexBuffer( bufferMA5_ID,  bufferMA5, INDICATOR_DATA );
    SetIndexBuffer( bufferMA6_ID,  bufferMA6, INDICATOR_DATA );


    // sets the starting point for all 3 MAs plotting buffers...
    PlotIndexSetInteger( bufferMA1_ID, PLOT_DRAW_BEGIN, inpMA1Period );
    PlotIndexSetInteger( bufferMA2_ID, PLOT_DRAW_BEGIN, inpMA2Period );
    PlotIndexSetInteger( bufferMA3_ID, PLOT_DRAW_BEGIN, inpMA3Period );
    PlotIndexSetInteger( bufferMA4_ID, PLOT_DRAW_BEGIN, inpMA4Period );
    PlotIndexSetInteger( bufferMA5_ID, PLOT_DRAW_BEGIN, inpMA5Period );
    PlotIndexSetInteger( bufferMA6_ID, PLOT_DRAW_BEGIN, inpMA6Period );

    // opens the indicators...
    if (inpMA1Period>0)  { hMA1 = iMA( Symbol(), Period(), inpMA1Period, 0, inpMethod, inpAppliedPrice ); }
    if (inpMA2Period>0)  { hMA2 = iMA( Symbol(), Period(), inpMA2Period, 0, inpMethod, inpAppliedPrice ); }
    if (inpMA3Period>0)  { hMA3 = iMA( Symbol(), Period(), inpMA3Period, 0, inpMethod, inpAppliedPrice ); }
    if (inpMA4Period>0)  { hMA4 = iMA( Symbol(), Period(), inpMA4Period, 0, inpMethod, inpAppliedPrice ); }
    if (inpMA5Period>0)  { hMA5 = iMA( Symbol(), Period(), inpMA5Period, 0, inpMethod, inpAppliedPrice ); }
    if (inpMA6Period>0)  { hMA6 = iMA( Symbol(), Period(), inpMA6Period, 0, inpMethod, inpAppliedPrice ); }


    if(hMA1==INVALID_HANDLE || hMA2==INVALID_HANDLE || hMA3==INVALID_HANDLE || hMA4==INVALID_HANDLE || hMA5==INVALID_HANDLE || hMA6==INVALID_HANDLE) { // is there anything wrong?
        Print("Error starting MA indicators!");
        return(INIT_FAILED);
    }

    return(INIT_SUCCEEDED);
}



//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
                const int &spread[])   {

    int  values_to_copy;                  //number of values to be copied from the indicator


    // if it is the first start of calculation of the indicator or if the number of values in the indicator changed
    // or if it is necessary to calculate the indicator for two or more bars (it means something has changed in the price history)
    if (prev_calculated == 0 || rates_total > prev_calculated+1) {
        values_to_copy = rates_total;
    } else {
        // it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
        // for calculation not more than one bar is added
        values_to_copy = (rates_total-prev_calculated) + 1;
    }

    // fill the MA buffers arrays with values of the Moving Average indicators...
    // if FillArrayFromBuffer returns false, it means the information is nor ready yet, quit operation
    if (inpMA1Period>0 && !FillArrayFromBuffer( hMA1, 0, values_to_copy, bufferMA1 ) )    {  return(0);  }
    if (inpMA2Period>0 && !FillArrayFromBuffer( hMA2, 0, values_to_copy, bufferMA2 ) )    {  return(0);  }
    if (inpMA3Period>0 && !FillArrayFromBuffer( hMA3, 0, values_to_copy, bufferMA3 ) )    {  return(0);  }
    if (inpMA4Period>0 && !FillArrayFromBuffer( hMA4, 0, values_to_copy, bufferMA4 ) )    {  return(0);  }
    if (inpMA5Period>0 && !FillArrayFromBuffer( hMA5, 0, values_to_copy, bufferMA5 ) )    {  return(0);  }
    if (inpMA6Period>0 && !FillArrayFromBuffer( hMA6, 0, values_to_copy, bufferMA6 ) )    {  return(0);  }




   // return the prev_calculated value for the next call
   return(rates_total);
}




//+------------------------------------------------------------------+
//| Filling indicator buffers from the MA indicator                  |
//+------------------------------------------------------------------+
bool FillArrayFromBuffer( int indicatorHandle,          // handle of the instantiated Indicator
                          int indicatorInternalBuffer,  // internal buffer # of the Indicator (iMAs == 0, just one!)
                          int itemsQty,                 // number of values to copy to buffer
                          double &bufferToCopyInto[]   // buffer to hold a copy of indicator's data
                         ) {

   ResetLastError();   // reset last error code

   // fill a part of the requested buffer array with values from the indicator buffer that has a 0 index
   if (CopyBuffer(indicatorHandle, indicatorInternalBuffer, 0, itemsQty, bufferToCopyInto) < 0) {  // if the copying fails, tell the error code
      Print( "Failed to copy data from the Indicator. Error Code:", GetLastError());
      return(false);  // quit with zero result - it means that the indicator is considered as not calculated
   }
   return(true);  // everything is fine
}




//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    IndicatorRelease(hMA1);
    IndicatorRelease(hMA2);
    IndicatorRelease(hMA3);
    IndicatorRelease(hMA4);
    IndicatorRelease(hMA5);
    IndicatorRelease(hMA6);
}

//+------------------------------------------------------------------+
