//+------------------------------------------------------------------+
//|                                          CustomHorizontalLine.mq5 |
//|                                                     Copyright 2023, |
//|                                              https://www.example.com |
//+------------------------------------------------------------------+
#property indicator_chart_window

bool isMouseClicked = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{

   // Return INIT_SUCCEEDED to indicate successful initialization
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


   return 0;
  }
//+------------------------------------------------------------------+


void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
                  
                  
    if (id == CHARTEVENT_CLICK){
        isMouseClicked = true;
    }

    if (isMouseClicked){
        // Print the mouse click coordinates (X and Y) on the chart
        Print("Clicked on grid at: x =", lparam, " y =", dparam, " => Price Level =", GetMouseY(dparam));
    }
}


double GetMouseY(const double &dparam){

        double chartHeightInPixels = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        double priceRange = ChartGetDouble(0, CHART_PRICE_MAX) - ChartGetDouble(0, CHART_PRICE_MIN);
        double pixelsPerPrice = chartHeightInPixels / priceRange;
        double mouseYValue = ChartGetDouble(0, CHART_PRICE_MAX) - dparam / pixelsPerPrice;
        
        return mouseYValue;
}