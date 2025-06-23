//|------------------------------------------------------------------+
//|                                                        Unity.mq5 |
//|                                    Copyright (c) 2018, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                           https://www.mql5.com/en/articles/5473/ |
//|                           https://www.mql5.com/en/code/26112     |
//|------------------------------------------------------------------+
#property copyright "2018 © Marketeer"
#property link      "https://www.mql5.com/en/users/marketeer"
#property version   "1.0"
#property description "Multi-asset cluster indicator taking all currencies as a sum of squares forming market unity (1.0)"


#define BUF_NUM 15


#property indicator_separate_window
#property indicator_buffers BUF_NUM
#property indicator_plots BUF_NUM

#property indicator_color1 Green
#property indicator_color2 DarkBlue
#property indicator_color3 Red
#property indicator_color4 Gray
#property indicator_color5 Peru
#property indicator_color6 Gold
#property indicator_color7 Purple
#property indicator_color8 Teal

#property indicator_color9 LightGreen
#property indicator_color10 LightBlue
#property indicator_color11 Orange
#property indicator_color12 LightGray
#property indicator_color13 Brown
#property indicator_color14 Yellow
#property indicator_color15 Magenta


input string _1 = ""; // Cluster Indicator Settings
input string Instruments = "EURUSD,GBPUSD,USDCHF,USDJPY,AUDUSD,USDCAD,NZDUSD"; // ·    Instruments
input int BarLimit = 500; // ·    BarLimit
input ENUM_DRAW_TYPE Draw = DRAW_LINE; // ·    Draw
input ENUM_APPLIED_PRICE PriceType = PRICE_CLOSE; // ·    PriceType
input bool AbsoluteValues = false; // ·    AbsoluteValues

input string _2 = ""; // Data Export to CSV
input string SaveToFile = ""; // ·    SaveToFile
input bool ShiftLastBuffer = false; // ·    ShiftLastBuffer
input int BarLookback = 1; // ·    BarLookback

int ShiftedBuffer = -1;

bool initDone = false;

#include <CSOM/IndArray.mqh>
#include <CSOM/HashMapTemplate.mqh>

IndicatorArray buffers(BUF_NUM);
IndicatorArrayGetter getter(buffers);

string Symbols[];
int Direction[];
double Contracts[];
int SymbolCount;

HashMapTemplate<string,int> workCurrencies;
int baseIndex = 0;
string BaseCurrency;
int LastBarCount;

bool initSymbols()
{
  SymbolCount = StringSplit(Instruments, ',', Symbols);
  if(SymbolCount >= BUF_NUM)
  {
    SymbolCount = BUF_NUM - 1;
    ArrayResize(Symbols, SymbolCount);
  }
  else if(SymbolCount == 0)
  {
    SymbolCount = 1;
    ArrayResize(Symbols, SymbolCount);
    Symbols[0] = Symbol();
  }
  
  ArrayResize(Direction, SymbolCount);
  ArrayInitialize(Direction, 0);
  ArrayResize(Contracts, SymbolCount);
  ArrayInitialize(Contracts, 1);
  
  string base = NULL;
  
  for(int i = 0; i < SymbolCount; i++)
  {
    if(!SymbolSelect(Symbols[i], true))
    {
      Print("Can't select ", Symbols[i]);
      return false;
    }
    
    string first, second;
    first = SymbolInfoString(Symbols[i], SYMBOL_CURRENCY_BASE);
    second = SymbolInfoString(Symbols[i], SYMBOL_CURRENCY_PROFIT);
    
    if(first != second)
    {
      workCurrencies.inc(first, 1);
      workCurrencies.inc(second, 1);
    }
    else
    {
      workCurrencies.inc(Symbols[i], 1);
    }
  }
  
  if(workCurrencies.getSize() >= BUF_NUM)
  {
    Print("Too many symbols, max ", (BUF_NUM - 1));
    return false;
  }
  
  if(ShiftLastBuffer)
  {
    ShiftedBuffer = workCurrencies.getSize() - 1;
  }
  
  for(int i = 0; i < workCurrencies.getSize(); i++)
  {
    if(workCurrencies[i] > 1)
    {
      if(base == NULL)
      {
        base = workCurrencies.getKey(i);
        baseIndex = i;
      }
      else
      {
        Print("Collision: multiple base symbols: ", base, "[", workCurrencies[base], "] ", workCurrencies.getKey(i), "[", workCurrencies[i], "]");
        return false;
      }
    }
  }
  
  BaseCurrency = base;
  
  for(int i = 0; i < SymbolCount; i++)
  {
    if(SymbolInfoString(Symbols[i], SYMBOL_CURRENCY_PROFIT) == base) Direction[i] = +1;
    else if(SymbolInfoString(Symbols[i], SYMBOL_CURRENCY_BASE) == base) Direction[i] = -1;
    else
    {
      Print("Ambiguous symbol direction ", Symbols[i], ", defaults used");
      Direction[i] = +1;
    }
    
    Contracts[i] = SymbolInfoDouble(Symbols[i], SYMBOL_TRADE_CONTRACT_SIZE);
  }
  
  return true;
}

int OnInit()
{
  ShiftedBuffer = -1;
  initDone = false;
  
  if(!initSymbols()) return INIT_PARAMETERS_INCORRECT;
  
  string base = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
  string profit = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
  
  int replaceIndex = -1;
  for(int i = 0; i <= SymbolCount; i++)
  {
    string name;
    if(i == 0)
    {
      name = BaseCurrency;
      if(name != workCurrencies.getKey(i))
      {
        replaceIndex = i;
      }
    }
    else
    {
      if(BaseCurrency == workCurrencies.getKey(i) && replaceIndex > -1)
      {
        name = workCurrencies.getKey(replaceIndex);
      }
      else
      {
        name = workCurrencies.getKey(i);
      }
    }
    
    PlotIndexSetString(i, PLOT_LABEL, name);
    int width = (name == base || name == profit) ? 2 : 1;
    PlotIndexSetInteger(i, PLOT_DRAW_TYPE, Draw);
    PlotIndexSetInteger(i, PLOT_LINE_WIDTH, width);
    PlotIndexSetInteger(i, PLOT_SHOW_DATA, true);
  }
  
  for(int i = SymbolCount + 1; i < BUF_NUM; i++)
  {
    PlotIndexSetInteger(i, PLOT_SHOW_DATA, false);
  }
  
  if(!AbsoluteValues)
  {
    IndicatorSetInteger(INDICATOR_LEVELS, 1);
    IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0.0);
  }
  
  IndicatorSetString(INDICATOR_SHORTNAME, "Unity [" + (string)workCurrencies.getSize() + "] " + EnumToString(PriceType));
  IndicatorSetInteger(INDICATOR_DIGITS, 5);
  
  LastBarCount = 0;
  initDone = true;
  
  EventSetTimer(1);

  Print("Unity ", __FUNCTION__, " ", Bars(_Symbol, PERIOD_CURRENT));

  return INIT_SUCCEEDED;
}

#define CopyXYZ(N, S, B, A) if(Copy##N(S, PERIOD_CURRENT, B, 1, A) != 1) {Print("Failed Copy", #N, " ", S, " ", B, " ", GetLastError()); return false;}
#define CopyXYZS(N, B, A) if(Copy##N(_Symbol, PERIOD_CURRENT, B, 1, A) != 1) {Print("Failed Copy", #N, " ", _Symbol, " ", B, " ", GetLastError()); return false;}
#define CopyXYZN(N, B, C, A) if(Copy##N(_Symbol, PERIOD_CURRENT, B, C, A) != C) {Print("Failed Copy", #N, " ", _Symbol, " ", B, " ", GetLastError()); return false;}
#define CopyXYZSN(N, S, B, C, A) if(Copy##N(S, PERIOD_CURRENT, B, C, A) != C) {Print("Failed Copy", #N, " ", S, " ", B, " ", GetLastError()); return false;}

#define TOSTRING(A) #A + " = " + (string)(A) + " "

bool calculate(const int bar)
{
  datetime time[1];
  CopyXYZN(Time, bar, 1, time);
  
  double w[2] = {0};
  double v[][2];
  ArrayResize(v, SymbolCount);
  
  for(int j = 0; j < SymbolCount; j++)
  {
    if(PriceType == PRICE_OPEN)
    {
      CopyXYZSN(Open, Symbols[j], time[0], 2, w);
    }
    else
    if(PriceType == PRICE_CLOSE)
    {
      CopyXYZSN(Close, Symbols[j], time[0], 2, w);
    }

    if(Direction[j] == -1)
    {
      w[0] = 1.0 / w[0];
      w[1] = 1.0 / w[1];
    }

    w[1] *= Contracts[j];
    w[0] *= Contracts[j];
    
    v[j][0] = w[1];
    v[j][1] = w[0];
  }
  
  double sum[2] = {1.0, 1.0};
  
  for(int j = 0; j < SymbolCount; j++)
  {
    sum[0] += v[j][0] * v[j][0];
    sum[1] += v[j][1] * v[j][1];
  }
  
  double base2_0 = 1.0 / sum[0];
  double base2_1 = 1.0 / sum[1];
  
  double base_0 = MathSqrt(base2_0);
  double base_1 = MathSqrt(base2_1);
  
  if(AbsoluteValues)
  {
    buffers[0][bar] = base_0 * Contracts[0];
  }
  else
  {
    buffers[0][bar] = base_0 / base_1 - 1.0;
  }
  
  for(int j = 1; j <= SymbolCount; j++)
  {
    if(AbsoluteValues)
    {
      buffers[j][bar] = base_0 * v[j - 1][0];
    }
    else
    {
      buffers[j][bar] = base_0 * v[j - 1][0] / (base_1 * v[j - 1][1]) - 1.0;
    }
  }
  
  return true;
}

void OnTimer()
{
  const double price[] = {};
  
  if(LastBarCount != Bars(_Symbol, PERIOD_CURRENT))
  {
    int n = OnCalculate(Bars(_Symbol, PERIOD_CURRENT), 0, 0, price);
    if(n > 0)
    {
      EventKillTimer();
      ChartSetSymbolPeriod(0, _Symbol, PERIOD_CURRENT);
      ChartRedraw();
    }
  }
  else
  {
    EventKillTimer();
  }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double& price[])
{
  if(!initDone) return 0;
  
  if(LastBarCount == rates_total && prev_calculated == rates_total && PriceType != PRICE_CLOSE)
  {
    return prev_calculated;
  }
  
  if(prev_calculated == 0)
  {
    for(int i = 0; i < rates_total; i++)
    {
      for(int j = 0; j < BUF_NUM; j++)
      {
        buffers[j][i] = EMPTY_VALUE;
      }
    }
  }
  
  int limit = MathMin(rates_total - prev_calculated + 1, BarLimit);

  for(int i = 0; i < limit; i++)
  {
    if(!calculate(i))
    {
      return 0; // will retry on next tick
    }
  }
  
  static bool fileSaved = SaveToFile == "";
  if(!fileSaved && !AbsoluteValues)
  {
    SaveBuffersToFile(SaveToFile);
    fileSaved = true;
  }
  
  LastBarCount = rates_total;
  
  return LastBarCount;
}

double GetBuffer(int index, int bar)
{
  return getter[index][bar];
}

bool SaveBuffersToFile(const string filename)
{
  int h = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_ANSI, ';');
  if(h == INVALID_HANDLE) return false;
  
  string line = "datetime";
  for(int k = BarLookback - 1; k >= 0; k--)
  {
    for(int i = 0; i < workCurrencies.getSize(); i++)
    {
      line += ";" + workCurrencies.getKey(i) + (string)(k + 1);
    }
  }
  if(ShiftLastBuffer)
  {
    line += ";FORECAST";
  }
  FileWriteString(h, line + "\n");

  for(int i = BarLimit - BarLookback; i >= (ShiftedBuffer > -1 ? 1 : 0); i--)
  {
    datetime time[1];
    CopyXYZN(Time, i, 1, time);
    line = (string)time[0];
    for(int k = BarLookback - 1; k >= 0; k--)
    {
      for(int j = 0; j < workCurrencies.getSize(); j++)
      {
        line += ";" + (string)GetBuffer(j, i + k);
      }
    }
    if(ShiftLastBuffer)
    {
      line += ";" + (string)GetBuffer(ShiftedBuffer, i - 1); // look into the future for 1 bar
    }
    FileWriteString(h, line + "\n");
  }
  
  FileClose(h);

  Print("File saved ", filename);
  return true;
}
