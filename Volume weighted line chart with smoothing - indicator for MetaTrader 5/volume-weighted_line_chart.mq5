//+------------------------------------------------------------------+
//|                                                  VWLineChart.mq5 |
//|                        Volume-Weighted Line Chart with Smoothing |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1 "VW Line Chart"
#property indicator_type1  DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_width1  2

//--- plot Bulls Arrow
#property indicator_label2  "Bulls"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrSkyBlue
#property indicator_width2  1

//--- plot Bears Arrow
#property indicator_label3  "Bears"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_width3  1

enum VolumeType
{
    Tick_Volume,  // Tick volume
    Real_Volume  // Real volume (only for stocks and futures)
};

input int SmoothingPeriod = 3; // Smoothing period
input double SmoothingFactor = 2.0; // Smoothing factor
input VolumeType VolumeOption = Tick_Volume; // Volume type
input bool drawDots = false; // Draw bull and bear indicator arrows
input bool UseDynamicSmoothing = true; // Use dynamic smoothing factor
input int ATRPeriod = 14;   // ATR period for dynamic smoothing factor

double MaxSmoothingFactor = 5.0; // Maximum smoothing factor
double MinSmoothingFactor = 2.0; // Minimum smoothing factor

double smoothingFactor = 0;

double VWLineBuffer[];
double atr_buf[];
double Bulls[], Bears[];

int atr_handle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Custom initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, VWLineBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, Bulls, INDICATOR_DATA);
    SetIndexBuffer(2, Bears, INDICATOR_DATA);
    
    PlotIndexSetInteger(1, PLOT_ARROW, 108);
    PlotIndexSetInteger(2, PLOT_ARROW, 108);
    
    atr_handle = iATR(Symbol(), 0, ATRPeriod);
        
    ArraySetAsSeries(atr_buf, true);
    
    return INIT_SUCCEEDED;
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
                const int &spread[])
{
    int start = prev_calculated > 0 ? prev_calculated - 1 : SmoothingPeriod;
         
    if (CopyBuffer(atr_handle, 0, 0, 1, atr_buf) < 0){
        Print("Failed to copy ATR values!");
        return 0;
    }   
    
    double atr = atr_buf[0];
    
    if(UseDynamicSmoothing){
    
      smoothingFactor = MinSmoothingFactor + (MaxSmoothingFactor - MinSmoothingFactor) * (atr / close[rates_total-1]);   
    }
    else{
      smoothingFactor = SmoothingFactor;
    }
    
    double alpha = smoothingFactor / (SmoothingPeriod + 1);

    for (int i = start; i < rates_total; i++)
    {
        // Calculate Volume-Weighted Price
        double vwPrice = 0.0;
        double totalVolume = 0.0;

        for (int j = i - SmoothingPeriod + 1; j <= i; j++)
        {
            if (j < 0) continue;
            
            double currentVolume = (VolumeOption == Tick_Volume) ? (double)tick_volume[j] : (double)volume[j];
            
            vwPrice += close[j] * currentVolume;
            totalVolume += currentVolume;
        }

        if (totalVolume != 0)
            vwPrice /= totalVolume; // sum of (closes * current volume) / current volume
            
        // Exponential Smoothing
        if (i == start)
            VWLineBuffer[i] = vwPrice;
        else
            VWLineBuffer[i] = VWLineBuffer[i - 1] + alpha * (vwPrice - VWLineBuffer[i - 1]);
        
        if(drawDots){ 
        
           if(VWLineBuffer[i] > VWLineBuffer[i-1]){
           
            Bulls[i] = VWLineBuffer[i];
            }
           else{
            Bulls[i] = EMPTY_VALUE;
           }
           
           if(VWLineBuffer[i] < VWLineBuffer[i-1]){
           
            Bears[i] = VWLineBuffer[i];
            }
           else{
            Bears[i] = EMPTY_VALUE;
           }  
        }
        else{
            Bulls[i] = EMPTY_VALUE;
            Bears[i] = EMPTY_VALUE;
        }   
    }

    return rates_total;
}
//+------------------------------------------------------------------+
