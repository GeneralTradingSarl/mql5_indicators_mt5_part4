// https://www.mql5.com/ru/blogs/post/665093

#property strict

#define AMOUNT_BUFFERS 0

#property indicator_chart_window
#property indicator_buffers AMOUNT_BUFFERS

#ifdef __MQL5__
  #property indicator_plots AMOUNT_BUFFERS
#endif

input color exColorBid = ::clrBlue;      // Цвет Bid
input color exColorAsk = ::clrRed;       // Цвет Ask
input color exColorSpread = ::clrYellow; // Цвет Spread
input uchar exTransparency = 0x7F;       // Прозрачность (0 - 255)

#include <fxsaber\ChartObjects\ChartObjectTicks.mqh>

CHARTOBJECTTICKS ChartObject(0, exColorBid, exColorAsk, exColorSpread, exTransparency);

void OnChartEvent( const int id, const long& lparam, const double& dparam, const string& sparam )
{
  EVENTBASE::MyEvent(id, lparam, dparam, sparam);

  return;
}

int OnCalculate( const int rates_total,
                 const int prev_calculated,
                 const datetime &time[],
                 const double &open[],
                 const double &high[],
                 const double &low[],
                 const double &close[],
                 const long &tick_volume[],
                 const long &volume[],
                 const int &spread[] )
{
  if (::ChartGetInteger(0, ::CHART_FIRST_VISIBLE_BAR) <= ::ChartGetInteger(0, ::CHART_VISIBLE_BARS))
    ChartObject.Visual();

  return(rates_total);
}
