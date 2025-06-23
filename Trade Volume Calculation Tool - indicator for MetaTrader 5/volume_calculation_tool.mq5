//+------------------------------------------------------------------+
//|                               Position Risk Calculation Tool.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1

#property indicator_label1 "Virtual SL"
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_color1 clrPurple

enum PositionType{
    buy,  // Buy
    sell  // Sell
};

input double riskPercent = 2.0;    // Percentage to risk
input PositionType posType = buy;  // Position Type

double virtSL[];
double bid, ask, BidAsk, stopLoss, lotSize;
   
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, virtSL, INDICATOR_DATA);
   
   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);  
   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 
   ArraySetAsSeries(virtSL, true);
   
   Comment("Click on the chart at the desired stop loss level...");
   
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
                const int &spread[])
  {

   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 
      
   posType == buy ? BidAsk = ask : BidAsk = bid; // Determine bid/ask based on buy/sell
   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Chart event processing                                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if (id == CHARTEVENT_CLICK)
   {
      // Get the total bars available
      int all_bars = Bars(_Symbol, _Period);
      
      // Record mouse click location as the virtual stop loss level
      for (int x = 10; x >= 0; x--)
      {
         virtSL[x] = GetMouseY(dparam);
      }
      for (int x = 11; x < all_bars; x++)
      {
         virtSL[x] = EMPTY_VALUE;
      }
      
      // Calculate stop loss distance in points
      stopLoss = MathAbs(BidAsk - GetMouseY(dparam));
      
      // Calculate lot size based on the input risk percentage
      lotSize = LotSizeCalc(riskPercent, stopLoss); // stoploss value (not the number of points)
      
      // Display risk calculation
      string calculation =
         ".:: Position Volume Calculator ::."
         + "\n\n"
         + "Risking: " + DoubleToString(riskPercent, 2) + "%"
         + "\n\n"
         + "Lot size to use: " + DoubleToString(lotSize, 2)
         + "\n"
         + "Stop loss points: " + DoubleToString(stopLoss/_Point, 2);
      
      Comment(calculation);
   }
}


double GetMouseY(const double &dparam)
{
   long chartHeightInPixels = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
   double priceRange = ChartGetDouble(0, CHART_PRICE_MAX) - ChartGetDouble(0, CHART_PRICE_MIN);
   double pixelsPerPrice = chartHeightInPixels / priceRange;
   double mouseYValue = ChartGetDouble(0, CHART_PRICE_MAX) - dparam / pixelsPerPrice;
   
   return mouseYValue;
}


double LotSizeCalc(double riskPct, double SLDistance)
{
    if (riskPct < 0 || riskPct > 100) {
        Print("Error: Invalid risk percentage");
        return -1;
    }
    
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);    // Free margin on the account in the deposit currency
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE); // Minimal price change of ticks
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);  // Value per tick in the deposit currency
    double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);    // Minimum lot step
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);         // Minimum allowed lot size
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);         // Maximum allowed lot size
    
    double riskVolumeStep = (SLDistance / tickSize) * tickValue * volumeStep;

    double risk = (riskPct * freeMargin) / 100;

    // calculate lot size by dividing risk by risk per volume step
    double lots = MathFloor(risk / riskVolumeStep) * volumeStep;
    
    if (lots < minLot) lots = minLot;
    if (lots > maxLot) lots = maxLot;

    return lots;
}


//+------------------------------------------------------------------+
//| De-initialization function                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
}