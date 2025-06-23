//+------------------------------------------------------------------+
//|                                                          Taf.mq5 |
//|                               Copyright © 2004, Poul_Trade_Forum |
//|                                                         Aborigen |
//|                                          http://forex.kbpauk.ru/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, Poul_Trade_Forum"
#property link      "http://forex.kbpauk.ru/"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в основном окне
#property indicator_chart_window
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в виде секций
#property indicator_type1 DRAW_SECTION
//---- в качестве окраски индикатора использован
#property indicator_color1 clrDodgerBlue
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки сигнальной линии
#property indicator_label1  "TafHigh"
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в виде секций
#property indicator_type2 DRAW_SECTION
//---- в качестве окраски индикатора использован
#property indicator_color2 clrMagenta
//---- линия индикатора - сплошная
#property indicator_style2 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width2 2
//---- отображение метки сигнальной линии
#property indicator_label2  "TafLow"
//+-----------------------------------+
//|  Входные параметры индикатора     |
//+-----------------------------------+
input uint BQUALIFY=2;
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//---- Объявление целочисленных переменных начала отсчета данных
int  min_rates_total;
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtHighBuffer[];
double ExtLowBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- Инициализация переменных начала отсчета данных
   min_rates_total=int(BQUALIFY);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,ExtHighBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- осуществление сдвига индикатора по горизонтали на InpKijun
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtHighBuffer,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,ExtLowBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- осуществление сдвига индикатора по горизонтали на InpKijun
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtLowBuffer,true);

//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"Taf("+string(BQUALIFY)+")");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[]
                )
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(0);
//---- Объявление переменных с плавающей точкой  
   double;
//---- Объявление целочисленных переменных
   int limit;
   uint VALUE1,VALUE2;
   static uint VALUE1_prev,VALUE2_prev;
//---- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчета всех баров
      VALUE1_prev=NULL;
      VALUE2_prev=NULL;
     }
   else limit=rates_total-prev_calculated;  // стартовый номер для расчета только новых баров
   VALUE1=VALUE1_prev;
   VALUE2=VALUE2_prev;
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
//---- основной цикл расчета индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtLowBuffer[bar]=0;
      ExtHighBuffer[bar]=0;
      if(High[bar]>=High[bar+1] && Low[bar]>=Low[bar+1])
        {
         if(VALUE2>=BQUALIFY) ExtLowBuffer[bar]=Low[bar+1];
         VALUE1++;
         VALUE2=NULL;
        }
      //----
      if(Low[bar]<=Low[bar+1] && High[bar]<=High[bar+1])
        {
         if(VALUE1>=BQUALIFY) ExtHighBuffer[bar]=High[bar+1];
         VALUE2++;
         VALUE1=NULL;
        }
      if(bar)
        {
         VALUE1_prev=VALUE1;
         VALUE2_prev=VALUE2;
        }
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
