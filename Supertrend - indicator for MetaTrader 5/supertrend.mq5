//+------------------------------------------------------------------+
//|                                                   supertrend.mq5 |
//|                                                Salman Soltaniyan |
//|                   https://www.mql5.com/en/users/salmansoltaniyan |
//+------------------------------------------------------------------+
#property copyright "Salman Soltaniyan"
#property link      "https://www.mql5.com/en/users/salmansoltaniyan"
#property version   "1.01"
#property indicator_chart_window
#property indicator_plots 2
#property indicator_buffers 3
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_color1  clrGreen, clrRed   // Green for uptrend, Red for downtrend

#property indicator_type2 DRAW_NONE

//+------------------------------------------------------------------+
//| DESCRIPTION:                                                     |
//| The SuperTrend indicator helps identify the current market trend |
//| and potential reversal points. It plots a line above or below    |
//| the price based on ATR volatility and serves as dynamic          |
//| support/resistance levels.                                       |
//+------------------------------------------------------------------+

//--- Input Parameters ---
input int    ATRPeriod       = 22;              // Period for ATR calculation
input double Multiplier      = 3.0;             // ATR multiplier for band calculation
input ENUM_APPLIED_PRICE SourcePrice = PRICE_MEDIAN; // Price source for calculations
input bool   TakeWicksIntoAccount = true;       // Include wicks in calculations

//--- Indicator Handles ---
int    atrHandle;                               // Handle for ATR indicator

//--- Indicator Buffers ---
double SuperTrendBuffer[];                      // Main SuperTrend line values
double SuperTrendColorBuffer[];                 // Color index buffer (0 = Green, 1 = Red)
double SuperTrendDirectionBuffer[];             // Direction buffer (1 = Up, -1 = Down)

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Create ATR indicator handle
    atrHandle = iATR(NULL, 0, ATRPeriod);
    if(atrHandle == INVALID_HANDLE)
    {
        Print("Error creating ATR indicator. Error code: ", GetLastError());
        return INIT_FAILED;
    }
    
    //--- Set indicator buffers mapping ---
    SetIndexBuffer(0, SuperTrendBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, SuperTrendColorBuffer, INDICATOR_COLOR_INDEX);
    SetIndexBuffer(2, SuperTrendDirectionBuffer, INDICATOR_DATA);

    //--- Set the indicator labels ---
    PlotIndexSetString(0, PLOT_LABEL, "SuperTrend");
    PlotIndexSetString(2, PLOT_LABEL, "SuperTrend direction");
    
    //--- Set array direction ---
    ArraySetAsSeries(SuperTrendBuffer, false);
    ArraySetAsSeries(SuperTrendDirectionBuffer, false);
    ArraySetAsSeries(SuperTrendColorBuffer, false);

    //--- Initialization is finished ---
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release ATR handle to free resources ---
    IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
    const int        rates_total,       // Size of input time series
    const int        prev_calculated,   // Number of handled bars at the previous call
    const datetime&  time[],            // Time array
    const double&    open[],            // Open array
    const double&    high[],            // High array
    const double&    low[],             // Low array
    const double&    close[],           // Close array
    const long&      tick_volume[],     // Tick Volume array
    const long&      volume[],          // Real Volume array
    const int&       spread[]           // Spread array
)
{
    // Set all arrays as not series (default indexing)
    ArraySetAsSeries(time, false);
    ArraySetAsSeries(open, false);
    ArraySetAsSeries(high, false);
    ArraySetAsSeries(low, false);
    ArraySetAsSeries(close, false);
    
    // Buffer for ATR values
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, false);
    
    // Variables for SuperTrend calculation
    double srcPrice;          // Source price based on input parameter
    double highPrice;         // High price (may consider wicks or not)
    double lowPrice;          // Low price (may consider wicks or not)
    double atr;               // Current ATR value
    double longStop;          // Support level (used during uptrend)
    double longStopPrev;      // Previous support level
    double shortStop;         // Resistance level (used during downtrend)
    double shortStopPrev;     // Previous resistance level
    int supertrend_dir = 1;   // Initial SuperTrend direction (1 = up, -1 = down)

    // Calculate for each bar starting from prev_calculated
    for(int i = prev_calculated; i < rates_total; i++)
    {
        //--- 1. Calculate source price based on selected price type ---
        switch(SourcePrice)
        {
            case PRICE_CLOSE:
                srcPrice = close[i];
                break;
            case PRICE_OPEN:
                srcPrice = open[i];
                break;
            case PRICE_HIGH:
                srcPrice = high[i];
                break;
            case PRICE_LOW:
                srcPrice = low[i];
                break;
            case PRICE_MEDIAN:
                srcPrice = (high[i] + low[i]) / 2.0;
                break;
            case PRICE_TYPICAL:
                srcPrice = (high[i] + low[i] + close[i]) / 3.0;
                break;
            default: // PRICE_WEIGHTED
                srcPrice = (high[i] + low[i] + close[i] + close[i]) / 4.0;
                break;
        }

        //--- 2. Define high and low prices based on "TakeWicksIntoAccount" setting ---
        highPrice = TakeWicksIntoAccount ? high[i] : close[i];
        lowPrice = TakeWicksIntoAccount ? low[i] : close[i];

        //--- 3. Get ATR value for the current bar ---
        if(CopyBuffer(atrHandle, 0, rates_total - i - 1, 1, atrBuffer) == -1)
        {
            Print("Error copying ATR buffer. Error code: ", GetLastError());
            // Continue calculation with potentially old ATR value
        }
        atr = atrBuffer[0];

        //--- 4. Calculate long stop (support during uptrend) ---
        longStop = srcPrice - Multiplier * atr;
        longStopPrev = i > 0 ? SuperTrendBuffer[i - 1] : longStop;

        // Adjust long stop based on previous values and current prices
        if(longStop > 0)
        {
            // If it's a doji (all prices are equal), use previous stop value
            if(open[i] == close[i] && open[i] == low[i] && open[i] == high[i])
                longStop = longStopPrev;
            else
                // Trailing stop logic - only move stop up, never down during uptrend
                longStop = (lowPrice > longStopPrev ? MathMax(longStop, longStopPrev) : longStop);
        }
        else
            longStop = longStopPrev;

        //--- 5. Calculate short stop (resistance during downtrend) ---
        shortStop = srcPrice + Multiplier * atr;
        shortStopPrev = i > 0 ? SuperTrendBuffer[i - 1] : shortStop;

        // Adjust short stop based on previous values and current prices
        if(shortStop > 0)
        {
            // If it's a doji (all prices are equal), use previous stop value
            if(open[i] == close[i] && open[i] == low[i] && open[i] == high[i])
                shortStop = shortStopPrev;
            else
                // Trailing stop logic - only move stop down, never up during downtrend
                shortStop = (highPrice < shortStopPrev ? MathMin(shortStop, shortStopPrev) : shortStop);
        }
        else
            shortStop = shortStopPrev;

        //--- 6. Determine SuperTrend direction based on price crossing stops ---
        if(i > 0)
        {
            // Get previous direction
            supertrend_dir = (i > 1) ? (int)SuperTrendDirectionBuffer[i-1] : 1;
            
            // Change from down to up if price breaks above the short stop
            if(supertrend_dir == -1 && highPrice > shortStopPrev)
                supertrend_dir = 1;
            // Change from up to down if price breaks below the long stop
            else if(supertrend_dir == 1 && lowPrice < longStopPrev)
                supertrend_dir = -1;
        }

        //--- 7. Set SuperTrend values based on the direction ---
        if(supertrend_dir == 1)
        {
            // Uptrend - use long stop as SuperTrend value
            SuperTrendBuffer[i] = longStop;
            SuperTrendDirectionBuffer[i] = 1;
            SuperTrendColorBuffer[i] = 0;  // Green color for uptrend
        }
        else
        {
            // Downtrend - use short stop as SuperTrend value
            SuperTrendBuffer[i] = shortStop;
            SuperTrendDirectionBuffer[i] = -1;
            SuperTrendColorBuffer[i] = 1;  // Red color for downtrend
        }
    }
    
    //--- Return value of prev_calculated for next call
    return(rates_total-1);
}
//+------------------------------------------------------------------+
//|                      MIT License                                 |
//+------------------------------------------------------------------+
//| Copyright (c) 2024 Salman Soltaniyan                             |
//|                                                                  |
//| Permission is hereby granted, free of charge, to any person      |
//| obtaining a copy of this software and associated documentation   |
//| files (the "Software"), to deal in the Software without          |
//| restriction, including without limitation the rights to use,     |
//| copy, modify, merge, publish, distribute, sublicense, and/or     |
//| sell copies of the Software, and to permit persons to whom the   |
//| Software is furnished to do so, subject to the following         |
//| conditions:                                                      |
//|                                                                  |
//| The above copyright notice and this permission notice shall be   |
//| included in all copies or substantial portions of the Software.  |
//|                                                                  |
//| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,  |
//| EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES  |
//| OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND         |
//| NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT      |
//| HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,     |
//| WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     |
//| FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR    |
//| OTHER DEALINGS IN THE SOFTWARE.                                  |
//+------------------------------------------------------------------+