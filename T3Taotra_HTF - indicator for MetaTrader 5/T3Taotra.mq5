//+------------------------------------------------------------------+
//|                                                     T3Taotra.mq5 |
//|                         MQL5: Copyright © 2010, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//| Для работы  индикатора файл SmoothAlgorithms.mqh                 |
//| следует положить в папку: каталог_данных_терминала\\MQL5\Include |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- номер версии индикатора
#property version   "1.10"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов 6
#property indicator_buffers 6 
//---- использовано всего 6 графических построений
#property indicator_plots   6
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- цвета индикатора
#property indicator_color1 clrYellow
#property indicator_color2 clrRed
#property indicator_color3 clrMagenta
#property indicator_color4 clrAqua
#property indicator_color5 clrLimeGreen
#property indicator_color6 clrBlue
//---- отрисовка индикатора в виде линий
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3 DRAW_LINE
#property indicator_type4 DRAW_LINE
#property indicator_type5 DRAW_LINE
#property indicator_type6 DRAW_LINE
//---- линии индикатора - непрерывные кривые
#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
#property indicator_style4 STYLE_SOLID
#property indicator_style5 STYLE_SOLID
#property indicator_style6 STYLE_SOLID
//---- толщина линий индикатора равна 1
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1
#property indicator_width5 1
#property indicator_width6 1
//---- отображение метки индикатора
#property indicator_label1  "T3Taotra1"
#property indicator_label2  "T3Taotra2" 
#property indicator_label3  "T3Taotra3" 
#property indicator_label4  "T3Taotra4" 
#property indicator_label5  "T3Taotra5" 
#property indicator_label6  "T3Taotra6" 
//+----------------------------------------------+
//| Объявление перечисления                      |
//+----------------------------------------------+
enum Applied_price_ //Тип ценовой константы
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPL_,         //PRICE_SIMPL
   PRICE_QUARTER_,       //PRICE_QUARTER
   PRICE_TRENDFOLLOW0_,  //PRICE_TRENDFOLLOW0
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price 
   PRICE_DEMARK_         //Demark Price
  };
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input int T3_Period_1 = 3; // период индикатора 1
input int T3_Period_2 = 5; // период индикатора 2
input int T3_Period_3 = 8; // период индикатора 3
input int T3_Period_4 = 12;// период индикатора 4
input int T3_Period_5 = 21;// период индикатора 5
input int T3_Period_6 = 34;// период индикатора 6
input int Smooth_Curvature=100;
input  Applied_price_  IPC=PRICE_CLOSE_;//ценовая константа
input int Shift1 = 0;  // cдвиг индикатора 1 вдоль оси времени 
input int Shift2 = 0;  // cдвиг индикатора 2 вдоль оси времени
input int Shift3 = 0;  // cдвиг индикатора 3 вдоль оси времени
input int Shift4 = 0;  // cдвиг индикатора 6 вдоль оси времени
input int Shift5 = 0;  // cдвиг индикатора 5 вдоль оси времени
input int Shift6 = 0;  // cдвиг индикатора 6 вдоль оси времени
//+----------------------------------------------+
//---- индикаторные буферы
double Ind_Buffer1[];
double Ind_Buffer2[];
double Ind_Buffer3[];
double Ind_Buffer4[];
double Ind_Buffer5[];
double Ind_Buffer6[];
//+------------------------------------------------------------------+
// Описание функции iPriceSeries()                                   |
// Описание функции iPriceSeriesAlert()                              |
// Описание класса  CT3                                              |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+   
//| T3Taotra initialization function                                 |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,Ind_Buffer1,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift1);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,1);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,Ind_Buffer2,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift2);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,1);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,Ind_Buffer3,INDICATOR_DATA);
//---- осуществление сдвига индикатора 3 по горизонтали
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift3);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,1);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(3,Ind_Buffer4,INDICATOR_DATA);
//---- осуществление сдвига индикатора 4 по горизонтали
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift4);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,1);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(4,Ind_Buffer5,INDICATOR_DATA);
//---- осуществление сдвига индикатора 5 по горизонтали
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift5);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,1);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(5,Ind_Buffer6,INDICATOR_DATA);
//---- осуществление сдвига индикатора 6 по горизонтали
   PlotIndexSetInteger(5,PLOT_SHIFT,Shift6);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,1);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"T3Taotra( ",T3_Period_1,", ",T3_Period_2,", ",T3_Period_3,
                     ", ",T3_Period_4,", ",T3_Period_5,", ",T3_Period_6," )");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+
//| T3.Taotra iteration function                                     |
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
   if(rates_total<0)return(0);

//---- Объявление переменных с плавающей точкой
   double series;

//---- Объявление целых переменных
   int first,bar;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
      first=0; // стартовый номер для расчёта всех баров
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- объявление массива переменных класса CT3 из файла T3Series_Cls.mqh
   static CT3 T3_[6];

//---- Основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      series=PriceSeries(IPC,bar,open,low,high,close); 
      Ind_Buffer1[bar]=T3_[0].T3Series(0,prev_calculated,rates_total,0,Smooth_Curvature,T3_Period_1,series,bar,false);
      Ind_Buffer2[bar]=T3_[1].T3Series(0,prev_calculated,rates_total,0,Smooth_Curvature,T3_Period_2,series,bar,false);
      Ind_Buffer3[bar]=T3_[2].T3Series(0,prev_calculated,rates_total,0,Smooth_Curvature,T3_Period_3,series,bar,false);
      Ind_Buffer4[bar]=T3_[3].T3Series(0,prev_calculated,rates_total,0,Smooth_Curvature,T3_Period_4,series,bar,false);
      Ind_Buffer5[bar]=T3_[4].T3Series(0,prev_calculated,rates_total,0,Smooth_Curvature,T3_Period_5,series,bar,false);
      Ind_Buffer6[bar]=T3_[5].T3Series(0,prev_calculated,rates_total,0,Smooth_Curvature,T3_Period_6,series,bar,false);
     }
//---- завершение вычислений значений индикатора 
   return(rates_total);
  }
//+------------------------------------------------------------------+
