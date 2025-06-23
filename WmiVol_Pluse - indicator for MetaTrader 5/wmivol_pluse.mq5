//+---------------------------------------------------------------------+ 
//|                                                    WmiVol_Pluse.mq5 | 
//|                                     Copyright 2014, Murad Ismayilov | 
//|                                  http://www.mql4.com/ru/users/wmlab | 
//+---------------------------------------------------------------------+ 
#property copyright "Copyright 2014, Murad Ismayilov"
#property link      "http://www.mql4.com/ru/users/wmlab" 
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- отрисовка индикатора в виде четырёхцветной гистограммы
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- в качестве цветов четырёхцветной гистограммы использованы
#property indicator_color1 clrDodgerBlue,clrMagenta
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки индикатора
#property indicator_label1 "WmiVol_Pluse"

#property indicator_maximum    1.1
#property indicator_minimum    0.0
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input ENUM_TIMEFRAMES TimeFrame=PERIOD_D1;         //Таймфрейм
//+-----------------------------------+
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[],ColorIndBuffer[];
double barVols[],avgVol;
int barsInDay,barCounts[];
//+------------------------------------------------------------------+
//| Получение таймфрейма в виде строки                               |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+    
//| WmiVol_Pluse indicator initialization function                   | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   if(Period()>=TimeFrame) 
     {
      Print(__FUNCTION__+"(): Период графика должен быть меньше, чем "+GetStringTimeframe(TimeFrame));
      Print(__FUNCTION__+"(): Следует уменьшить период графика либо увеличить значение входного параметра индикатора <<TimeFrame>>!");
      return(INIT_FAILED);
     }
   barsInDay=PeriodSeconds(TimeFrame)/(PeriodSeconds(PERIOD_CURRENT));
   if(!barsInDay) return(INIT_FAILED);
   min_rates_total=barsInDay;

//---- Распределение памяти под массивы переменных  
   if(ArrayResize(barCounts,barsInDay)<barsInDay) 
     {
      Print("Не удалось распределить память под массив barCounts[]");
      return(INIT_FAILED);
     }
   if(ArrayResize(barVols,barsInDay)<barsInDay)
     {
      Print("Не удалось распределить память под массив barVols[]");
      return(INIT_FAILED);
     }
//---- Инициализация массивов переменных
   ArrayInitialize(barCounts,0);
   ArrayInitialize(barVols,0.0);

//---- превращение динамического массива IndBuffer в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"WmiVol_Pluse(",GetStringTimeframe(TimeFrame),")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| WmiVol_Pluse iteration function                                  | 
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
//---- Проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

///---- объявления локальных переменных 
   int first,bar;
   double;

//---- расчёт стартового номера first для цикла пересчёта баров и инициализация переменных в блоке OnCalculate 
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=0;
      for(bar=rates_total-1; bar>0; bar--)
        {
         int barOfDay=iBarOfDay(time[bar]);
         barVols[barOfDay]+=high[bar]-low[bar];
         barCounts[barOfDay]++;
        }
      for(bar=0; bar<barsInDay; bar++) if(barCounts[bar]) barVols[bar]/=barCounts[bar];
      double minVol=barVols[ArrayMinimum(barVols)];
      double maxVol=barVols[ArrayMaximum(barVols)];
      avgVol=0.0;
      for(bar=0; bar<barsInDay; bar++) if(maxVol>minVol) avgVol+=barVols[bar]=(barVols[bar]-minVol)/(maxVol-minVol);
      avgVol/=barsInDay;  
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- Основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      int barOfDay=iBarOfDay(time[bar]);
      double vol=barVols[barOfDay];
      IndBuffer[bar]=vol;
      if(vol>=avgVol) ColorIndBuffer[bar]=0;
      else ColorIndBuffer[bar]=1;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  iBarOfDay()                                                     |
//+------------------------------------------------------------------+
int iBarOfDay(datetime timeOpenBar) 
  {
//----
   int minutesInPeriod=PeriodSeconds()/60;
   double minutesSinceMidnight=MathMod(timeOpenBar/60,PeriodSeconds(TimeFrame)/60);
   int barsSinceMidnight=(int)MathFloor(minutesSinceMidnight/minutesInPeriod);
//----
   return (barsSinceMidnight);
  }
//+------------------------------------------------------------------+
