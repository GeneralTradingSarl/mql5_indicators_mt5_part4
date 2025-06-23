//+------------------------------------------------------------------+
//|                                                 StodivCandle.mq5 |
//|                                          Copyright © 2006, RickD | 
//|                                                http://e2e-fx.net | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, RickD"
#property link "http://e2e-fx.net"
#property description "Индикатор окрашивает свечи на основе Стохастика"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- для расчета и отрисовки индикатора использовано пять буферов
#property indicator_buffers 5
//---- использовано всего одно графическое построение
#property indicator_plots   1
//---- в качестве индикатора использованы цветные свечи
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1   clrMagenta,clrPurple,clrGray,clrTeal,clrLime
//---- отображение метки индикатора
#property indicator_label1  "StodivCandle Open;StodivCandle High;StodivCandle Low;StodivCandle Close"
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА                |
//+----------------------------------------------+
input int KPeriod=5;
input int DPeriod=3;
input int Slowing=3;
input ENUM_MA_METHOD MA_Method=MODE_SMA;
input ENUM_STO_PRICE Price_field=STO_LOWHIGH;
input uint HighLevel=60;                       // уровень перезакупа
input uint LowLevel=40;                        // уровень перепроданности
input int Shift=0;                             // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorBuffer[];

//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- Объявление целых переменных для хендлов индикаторов
int Stochastic_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(KPeriod+DPeriod+Slowing);
//---- получение хендла индикатора iStochastic
   Stochastic_Handle=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MA_Method,Price_field);
   if(Stochastic_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iStochastic");
      return(INIT_FAILED);
     }  

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtCloseBuffer,INDICATOR_DATA);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);

//---- индексация элементов в буферах как в таймсериях
   ArraySetAsSeries(ExtOpenBuffer,true);
   ArraySetAsSeries(ExtHighBuffer,true);
   ArraySetAsSeries(ExtLowBuffer,true);
   ArraySetAsSeries(ExtCloseBuffer,true);
   ArraySetAsSeries(ExtColorBuffer,true);

//---- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и метка для субъокон 
   string short_name="StodivCandle";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- завершение инициализации
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
//---- проверка количества баров на достаточность для расчёта
   if(BarsCalculated(Stochastic_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//---- объявления локальных переменных
   int to_copy,limit,bar,clr;
   double Sto[],Sign[];
   
//---- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчета всех баров
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров

   to_copy=limit+1;

//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(Stochastic_Handle,MAIN_LINE,0,to_copy,Sto)<=0) return(RESET);
   if(CopyBuffer(Stochastic_Handle,SIGNAL_LINE,0,to_copy,Sign)<=0) return(RESET);
   if(CopyOpen(Symbol(),PERIOD_CURRENT,0,to_copy,ExtOpenBuffer)<=0) return(RESET);
   if(CopyHigh(Symbol(),PERIOD_CURRENT,0,to_copy,ExtHighBuffer)<=0) return(RESET);
   if(CopyLow(Symbol(),PERIOD_CURRENT,0,to_copy,ExtLowBuffer)<=0) return(RESET);
   if(CopyClose(Symbol(),PERIOD_CURRENT,0,to_copy,ExtCloseBuffer)<=0) return(RESET);

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(Sto,true);
   ArraySetAsSeries(Sign,true);

//---- Основной цикл окрашивания свечей
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      clr=2;
      if(Sto[bar]>HighLevel) clr=4;
      else if(Sto[bar]<LowLevel) clr=0;
      else if(Sto[bar]>Sign[bar]) clr=3;
      else if(Sto[bar]<Sign[bar]) clr=1;
      ExtColorBuffer[bar]=clr;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
