#property strict

#define AMOUNT_BUFFERS 0

#property indicator_separate_window
#property indicator_buffers AMOUNT_BUFFERS

#ifdef __MQL5__
  #property indicator_plots AMOUNT_BUFFERS
#endif

input uint exVelocityScale = 5;          // Скорость изменения масштаба
input color exColorCross = ::clrSienna;  // Цвет Cross
input color exColorBid = ::clrBlue;      // Цвет Bid
input color exColorAsk = ::clrRed;       // Цвет Ask
input color exColorSpread = ::clrYellow; // Цвет Spread
input uchar exTransparency = 0x7F;       // Прозрачность (0 - 255)

#include <fxsaber\ChartObjects\ChartObject_ZoomPrice.mqh>

CHARTOBJECT_ZOOMPRICE ChartObject(0, ChartWindowFind(), exVelocityScale, exColorCross, exColorBid, exColorAsk, exColorSpread, exTransparency);

void OnInit( void )
{
  IndicatorSetInteger(INDICATOR_DIGITS, 0);
}

void OnChartEvent( const int id, const long& lparam, const double& dparam, const string& sparam )
{
  EVENTBASE::MyEvent(id, lparam, dparam, sparam);
}

void OnTimer( void )
{
  EVENTBASE::MyEventTimer();
}

int OnCalculate( const int rates_total, const int prev_calculated, const int begin, const double& price[] )
{
  EVENTBASE::MyEventTick();

  return(rates_total);
}