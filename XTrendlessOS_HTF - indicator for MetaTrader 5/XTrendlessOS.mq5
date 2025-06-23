//+---------------------------------------------------------------------+
//|                                                    XTrendlessOS.mq5 | 
//|                                       Copyright © 2010,   LenIFCHIK | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2010, LenIFCHIK"
#property link ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//| Параметры отрисовки индикатора               |
//+----------------------------------------------+
//---- отрисовка индикатора в виде семицветной гистограммы
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- в качестве цветов четырёхцветной гистограммы использованы
#property indicator_color1 clrBlue,clrLime,clrGray,clrGreen,clrMediumVioletRed,clrRed,clrMagenta
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 3
#property indicator_width1  3
//---- отображение метки индикатора
#property indicator_label1  "XTrendlessOS"

//+----------------------------------------------+
//| Описание класса CXMA                         |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA;
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
enum Applied_price_ //Тип константы
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price
   PRICE_DEMARK_         //Demark Price
  };
//+----------------------------------------------+
//| объявление перечислений                      |
//+----------------------------------------------+
/*enum Smooth_Method - перечисление объявлено в файле SmoothAlgorithms.mqh
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+----------------------------------------------+
//| объявление перечислений                      |
//+----------------------------------------------+
enum ENUM_WIDTH //Тип константы
  {
   w_1 = 1,   //1
   w_2,       //2
   w_3,       //3
   w_4,       //4
   w_5        //5
  };
//+----------------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА                |
//+----------------------------------------------+
input Smooth_Method TMA_Method=MODE_JurX; //метод усреднения
input int TLength=7; //глубина  усреднения      
input int TPhase=100; //параметр усреднения,
input Applied_price_ IPC=PRICE_CLOSE_;//ценовая константа
input double OBLevel=0.00473;   //граница уровня перекупленности
input double OSLevel=-0.00473; //граница уровня перепроданности 
input color LevelsColor=Red; //цвет уровней
input ENUM_LINE_STYLE LevelsStyle=STYLE_DASHDOTDOT; //стиль уровней
input ENUM_WIDTH LevelsWidth=w_1; //толщина дневной линии
input int Shift=0; // сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[],ColorIndBuffer[];
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//----
double OBLevel06,OBLevel08,OSLevel06,OSLevel08;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=XMA.GetStartBars(TMA_Method,TLength,TPhase);

//---- установка алертов на недопустимые значения внешних переменных
   XMA.XMALengthCheck("TLength", TLength);
   XMA.XMAPhaseCheck("TPhase", TPhase, TMA_Method);

//---- Инициализация переменных  
   OBLevel06=0.6*OBLevel;
   OBLevel08=0.8*OBLevel;
   OSLevel06=0.6*OSLevel;
   OSLevel08=0.8*OSLevel;

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   string Smooth=XMA.GetString_MA_Method(TMA_Method);
   StringConcatenate(shortname,"XTrendlessOS(",TLength,", ",TLength,", ",Smooth,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---- параметры отрисовки линий
   IndicatorSetInteger(INDICATOR_LEVELS,6);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,LevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,LevelsStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,0,LevelsWidth);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,LevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,LevelsStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,1,LevelsWidth);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,LevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,LevelsStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,2,LevelsWidth);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,3,LevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,3,LevelsStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,3,LevelsWidth);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,4,LevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,4,LevelsStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,4,LevelsWidth);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,5,LevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,5,LevelsStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,5,LevelsWidth);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,OBLevel06);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,OBLevel08);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,OSLevel06);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,3,OSLevel08);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,4,OSLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,5,OBLevel);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- Объявление переменных с плавающей точкой  
   double price_,xma,current;
//---- Объявление целых переменных и получение уже посчитанных баров
   int first,bar;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
      first=0; // стартовый номер для расчёта всех баров
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- Основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //---- Вызов функции PriceSeries для получения входной цены price_
      price_=PriceSeries(IPC,bar,open,low,high,close);
      xma=XMA.XMASeries(0,prev_calculated,rates_total,TMA_Method,TPhase,TLength,price_,bar,false);
      IndBuffer[bar]=price_-xma;
     }

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
      first=min_rates_total;

//---- Основной цикл раскраски индикатора IndBuffer
   for(bar=first; bar<rates_total; bar++)
     {
      ColorIndBuffer[bar]=0;
      current=IndBuffer[bar];

      if(current>OBLevel) ColorIndBuffer[bar]=6; else if(current>OBLevel08) ColorIndBuffer[bar]=5; else if(current>OBLevel06) ColorIndBuffer[bar]=4;
      if(current<OSLevel) ColorIndBuffer[bar]=1; else if(current<OSLevel08) ColorIndBuffer[bar]=2; else if(current<OSLevel06) ColorIndBuffer[bar]=3;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
