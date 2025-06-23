//+------------------------------------------------------------------+
//|                                                     SuperSR6.mq5 |
//|                                       Copyright © 2006, Scorpion |
//|            Scorpion@fxfisherman.com, http://www.fxfisherman.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Scorpion"
#property link      "http://www.fxfisherman.com/"
#property description "Индикатор для построения возможных линий поддержки и сопротивления"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчёта и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки медвежьего индикатора   |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//---- в качестве цвета уровней поддержки использован розовый цвет
#property indicator_color1  clrMagenta
//---- толщина линии индикатора 1 равна 1
#property indicator_width1  1
//---- отображение метки поддержки
#property indicator_label1  "Support"
//+----------------------------------------------+
//|  Параметры отрисовки бычьго индикатора       |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//---- в качестве цвета уровней сопротивления использован зелёный цвет
#property indicator_color2  clrLime
//---- толщина линии индикатора 2 равна 1
#property indicator_width2  1
//---- отображение медвежьей метки сопротивления
#property indicator_label2 "Resistance"

//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint Contract_Step=150;
input uint Precision=10;
input uint Shift_Bars=1;
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double SellBuffer[];
double BuyBuffer[];
//---
int min_rates_total;
double contract,dPrecision;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализация глобальных переменных 
   min_rates_total=int(6+Shift_Bars);
   contract=(Contract_Step+Precision)*_Point;
   dPrecision=Precision*_Point;

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Support");
//---- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,159);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SellBuffer,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"Resistance");
//---- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(BuyBuffer,true);

//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и лэйба для субъокон 
   string short_name="SuperSR6";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
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
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- объявления локальных переменных 
   int shift,limit,bar;
   bool fractal;
   double price,gap;
   
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- расчёт стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
      BuyBuffer[bar]=high[limit+1];
      SellBuffer[bar]=low[limit+1];
     }
   else
     {
      limit=rates_total-prev_calculated+2; // стартовый номер для расчёта новых баров
     }

//---- основной цикл расчёта индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      shift=int(bar+Shift_Bars);

      //---- Resistance
      price=high[shift+2];
      fractal=price>=high[shift+4] && price>=high[shift+3] && price>high[shift+1] && price>high[shift];
      gap=BuyBuffer[bar+1]-price;

      if(fractal && (gap>=contract || gap<0)) BuyBuffer[bar]=price+dPrecision;
      else BuyBuffer[bar]=BuyBuffer[bar+1];

      //---- Support
      price=low[shift+2];
      fractal=price<=low[shift+4] && price<=low[shift+3] && price<low[shift+1] && price<low[shift];
      gap=price-SellBuffer[bar+1];

      if(fractal && (gap>=contract || gap<0)) SellBuffer[bar]=price-dPrecision;
      else SellBuffer[bar]=SellBuffer[bar+1];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
