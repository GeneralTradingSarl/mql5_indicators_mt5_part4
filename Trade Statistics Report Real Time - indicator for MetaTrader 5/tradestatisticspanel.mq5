//+---------------------------------------------------------------------+
//|                                            TradeStatisticsPanel.mq5 |
//|                                                        jafferwilson |
//|                          https://www.mql5.com/en/users/jafferwilson |
//+---------------------------------------------------------------------+
#property copyright "jafferwilson"
#property link      "https://www.mql5.com/en/users/jafferwilson"
#property version   "1.00"

#property indicator_separate_window
#property indicator_plots 0
#property indicator_buffers 0

//+------------------------------------------------------------------+
//|   Include                                                        |
//+------------------------------------------------------------------+
#include <TradeStatisticsPanel.mqh>
#include <CTradeStatistics.mqh>

//+------------------------------------------------------------------+
//|   External parameters                                            |
//+------------------------------------------------------------------+
input string   InpFontName    =  "Consolas"; // Font Name
input int      InpFontSize    =  10;         // Font Size
input color    InpFontColor   =  clrBlack;   // Text Color

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CPanelDialog ExtDialog;
CTradeStatistics stat;
datetime last_visit = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialize struct
   Params param;

   param.chart= 0;
   param.name = "";
   param.subwin=0;
   param.x1 = 0;
   param.y1 = 0;
   param.x2 = (int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   param.y2 = MathMin(VALUE_ROWS*InpFontSize*2,(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS));
   param.font_name = InpFontName;
   param.font_size = InpFontSize;
   param.font_color= InpFontColor;

//--- create panel
   if(!ExtDialog.Create(param))
      return(INIT_SUCCEEDED);

//--- run panel
   if(!ExtDialog.Run())
      return(INIT_SUCCEEDED);

//--- calculate and print
   ClearData();
   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
      return(INIT_SUCCEEDED);

   if(stat.Calculate())
      PrintData();
   else
      PrintError();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- remove panel
   ExtDialog.Destroy();
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|   OnTrade - event                                                |
//+------------------------------------------------------------------+
void OnTrade()
  {
//--- block repeated requests at same sec.
   static datetime time_on_trade;
   if(time_on_trade==TimeCurrent())
      return;
   time_on_trade=TimeCurrent();

//--- calculate and print
   ClearData();
   if(stat.Calculate())
      PrintData();
   else
      PrintError();

   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|   OnChartEvent - Click button event                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);

   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      //--- Button "Calculate"
      if(ExtDialog.GetButtonName(0)==sparam)
        {
         ClearData();
         if(!TerminalInfoInteger(TERMINAL_CONNECTED))
            return;

         if(stat.Calculate())
            PrintData();
         else
            PrintError();
        }
     }
  }
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

   if(prev_calculated==0)
     {
      //--- first run
      ClearData();
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
         return(0);

      if(stat.Calculate())
         PrintData();
      else
         PrintError();
      last_visit = time[rates_total-1];
     }
   if(last_visit!=time[rates_total-1])
     {
      last_visit = time[rates_total-1];
      ClearData();
      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
         return(0);

      if(stat.Calculate())
         PrintData();
      else
         PrintError();
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|   PrintData()                                                    |
//+------------------------------------------------------------------+
void PrintData()
  {
   ExtDialog.Caption(StringFormat("Welcome %s ! Your EQUITY: %.2lf",AccountInfoString(ACCOUNT_NAME),AccountInfoDouble(ACCOUNT_EQUITY)));

//---col#1
   ExtDialog.SetLabelParam(0,0, StringFormat("%.2f",stat.InitialDeposit()));
   ExtDialog.SetLabelParam(1,0, StringFormat("%.2f",stat.Profit()));
   ExtDialog.SetLabelParam(2,0, StringFormat("%.2f",stat.GrossProfit()));
   ExtDialog.SetLabelParam(3,0, StringFormat("%.2f",stat.GrossLoss()));
   ExtDialog.SetLabelParam(4,0, StringFormat("%.2f",stat.ProfitFactor()));
   ExtDialog.SetLabelParam(5,0, StringFormat("%.2f",stat.RecoveryFactor()));
   ExtDialog.SetLabelParam(6,0, StringFormat("%.4f(%.2f%%)",stat.AHPR(),stat.AHPRPercent()));
   ExtDialog.SetLabelParam(7,0, StringFormat("%.4f(%.2f%%)",stat.GHPR(),stat.GHPRPercent()));
   ExtDialog.SetLabelParam(8,0,StringFormat("%.2f(%.2f%%)",stat.ZScore(),stat.ZScorePercent())); //???

   ExtDialog.SetLabelParam(10,0, StringFormat("%d",stat.Trades()));
   ExtDialog.SetLabelParam(11,0, StringFormat("%d",stat.Deals()));

//---col#2

   ExtDialog.SetLabelParam(0,1,StringFormat("%.2f",stat.ExpectedPayoff()));
   ExtDialog.SetLabelParam(1,1,StringFormat("%.2f",stat.SharpeRatio()));
   ExtDialog.SetLabelParam(2,1,StringFormat("%.2f",stat.LRCorrelation()));
   ExtDialog.SetLabelParam(3,1,StringFormat("%.2f",stat.LRStandardError()));

   ExtDialog.SetLabelParam(5, 1, StringFormat("%.d(%.2f%%)",stat.ShortTrades(),stat.Percent(stat.ProfitShortTrades(),stat.ShortTrades())));
   ExtDialog.SetLabelParam(6, 1, StringFormat("%.d(%.2f%%)",stat.ProfitTrades(),stat.Percent(stat.ProfitTrades(),stat.Trades())));
   ExtDialog.SetLabelParam(7, 1, StringFormat("%.2f",stat.LargestProfitTrade()));
   ExtDialog.SetLabelParam(8, 1, StringFormat("%.2f",stat.Divide(stat.GrossProfit(),stat.ProfitTrades())));
   ExtDialog.SetLabelParam(9, 1, StringFormat("%.d(%.2f)",stat.MaxConProfitTrades(),stat.MaxConWins()));
   ExtDialog.SetLabelParam(10,1, StringFormat("%.2f(%.d)",stat.ConProfitMax(),stat.ConProfitMaxTrades()));
   ExtDialog.SetLabelParam(11,1, StringFormat("%.d",stat.ProfitTradesAvgCon()));


//---col#3
   ExtDialog.SetLabelParam(1, 2, StringFormat("%.2f",stat.InitialDeposit()-stat.BalanceMin()));
   //Print(stat.BalanceMin(),"  ",stat.InitialDeposit());
   ExtDialog.SetLabelParam(2, 2, StringFormat("%.2f (%.2f%%)",stat.BalanceDD(),stat.BalanceDDPercent()));
   ExtDialog.SetLabelParam(3, 2, StringFormat("%.2f%% (%.2f)",stat.BalanceDDRelativePercent(),stat.BalanceDDRelative()));

   ExtDialog.SetLabelParam(5, 2, StringFormat("%.d(%.2f%%)",stat.LongTrades(),stat.Percent(stat.ProfitLongTrades(),stat.LongTrades())));
   ExtDialog.SetLabelParam(6, 2, StringFormat("%.d(%.2f%%)",stat.LossTrades(),stat.Percent(stat.LossTrades(),stat.Trades())));
   ExtDialog.SetLabelParam(7, 2, StringFormat("%.2f",stat.LargestLossTrade()));
   ExtDialog.SetLabelParam(8, 2, StringFormat("%.2f",stat.Divide(stat.GrossLoss(),stat.LossTrades())));
   ExtDialog.SetLabelParam(9, 2, StringFormat("%.d(%.2f)",stat.MaxConLossTrades(),stat.MaxConLosses()));
   ExtDialog.SetLabelParam(10,2, StringFormat("%.2f(%.d)",stat.ConLossMax(),stat.ConLossMaxTrades()));
   ExtDialog.SetLabelParam(11,2, StringFormat("%.d",stat.LossTradesAvgCon()));

   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|   ClearData()                                                    |
//+------------------------------------------------------------------+
void ClearData()
  {
   ExtDialog.Caption("");
   for(int c=0; c<=2; c++)
      for(int i=0; i<=11; i++)
         ExtDialog.SetLabelParam(i,c,"");
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|   PrintError()                                                   |
//+------------------------------------------------------------------+
void PrintError()
  {
   string msg=" Error: "+stat.GetLastErrorString();
   ExtDialog.Caption(msg);
  }
//+------------------------------------------------------------------+
