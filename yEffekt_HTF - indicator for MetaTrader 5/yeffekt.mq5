//+------------------------------------------------------------------+ 
//|                                                      yEffekt.mq5 | 
//|                                         Copyright © 2008, MNS777 | 
//|                                                mns777.ru@mail.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2008, MNS777"
#property link "mns777.ru@mail.ru" 
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
#property indicator_color1 Gray,Teal,DarkViolet,IndianRed,Magenta
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки индикатора
#property indicator_label1 "yEffekt"

//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1 +0.5
#property indicator_level2  0.0
#property indicator_level3 -0.5
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT

//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[],ColorIndBuffer[];
//+------------------------------------------------------------------+    
//| yEfekt indicator initialization function                         | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=5;

//---- превращение динамического массива IndBuffer в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(IndBuffer,true);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total+1);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorIndBuffer,true);

//---- инициализации переменной для короткого имени индикатора
   string shortname="yEffekt";
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| yEfekt iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
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
//---- Проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- Объявление целых переменных
   int limit1,limit2,bar;
//---- Объявление переменных с плавающей точкой  
   double Index;

//---- Инициализация индикатора в блоке OnCalculate()
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit1=rates_total-1-min_rates_total; // стартовый номер для расчёта всех баров первого цикла
      limit2=limit1-1; // стартовый номер для расчёта всех баров второго цикла
     }
   else // стартовый номер для расчёта новых баров
     {
      limit1=rates_total-prev_calculated;
      limit2=limit1;
     }

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- Основной цикл расчёта индикатора
   for(bar=limit1; bar>=0; bar--)
     {
      Index=(high[bar]-low[bar])+(high[bar+1]-low[bar+1])+(high[bar+2]-low[bar+2])+(high[bar+3]-low[bar+3])+(high[bar+4]-low[bar+4]);

      if(Index!=0.0)
        {
         if(high[bar] > low[bar+4] ) IndBuffer[bar]=(high[bar]-low[bar+4])/Index;
         if(low[bar]  < high[bar+4]) IndBuffer[bar]=(low[bar] - high[bar+4] )/Index;
        }
      else IndBuffer[bar]=0.0;

     }

//---- Основной цикл раскраски индикатора Ind
   for(bar=limit2; bar>=0; bar--)
     {
      ColorIndBuffer[bar]=0;

      if(IndBuffer[bar]>0)
        {
         if(IndBuffer[bar]>IndBuffer[bar+1]) ColorIndBuffer[bar]=1;
         if(IndBuffer[bar]<IndBuffer[bar+1]) ColorIndBuffer[bar]=2;
        }

      if(IndBuffer[bar]<0)
        {
         if(IndBuffer[bar]<IndBuffer[bar+1]) ColorIndBuffer[bar]=3;
         if(IndBuffer[bar]>IndBuffer[bar+1]) ColorIndBuffer[bar]=4;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
