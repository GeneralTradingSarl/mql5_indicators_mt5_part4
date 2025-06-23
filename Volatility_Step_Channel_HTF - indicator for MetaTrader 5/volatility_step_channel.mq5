//+---------------------------------------------------------------------+
//|                                         Volatility_Step_Channel.mq5 | 
//|                                            Copyright © 2015, fxborg | 
//|                                      http://fxborg-labo.hateblo.jp/ | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2015, fxborg"
#property link "http://fxborg-labo.hateblo.jp/"
#property description "Volatility Step Channel"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 3
#property indicator_buffers 3 
//---- использовано всего 5 графических построений
#property indicator_plots   3
//+-----------------------------------+
//| Параметры отрисовки индикатора    |
//+-----------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета линии индикатора использован сине-фиолетовый цвет
#property indicator_color1 clrBlueViolet
//---- линия индикатора - сплошная линия
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "Median Line"
//+--------------------------------------------+
//| Параметры отрисовки индикатора BB уровней  |
//+--------------------------------------------+
//---- отрисовка уровней в виде линий
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
//---- ввыбор цветов уровней
#property indicator_color2  clrLime
#property indicator_color3  clrRed
//---- уровни канала - сплошные линии
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
//---- толщина уровней равна 3
#property indicator_width2  3
#property indicator_width3  3
//---- отображение меток уровней Боллинджера
#property indicator_label2  "Upper Channel"
#property indicator_label3  "Lower Channel"
//+-----------------------------------+
//| Описание классов усреднений       |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- объявление переменных классов CXMA и CStdDeviation из файла SmoothAlgorithms.mqh
CXMA XMA1,XMA2,XMA3,XMA4,XMA5,XMA6,XMA7,XMA8;
CStdDeviation STD;
//+-----------------------------------+
//| Объявление перечислений           |
//+-----------------------------------+
enum Applied_price_ //тип константы
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
//+-----------------------------------+
//| Объявление перечислений           |
//+-----------------------------------+
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
   MODE_AMA    //AMA
  }; */
//+-----------------------------------+
//| Объявление перечислений           |
//+-----------------------------------+
enum MODE //тип константы
  {
   ENAM_SIMPLE = 1,     //Simple Mode
   ENAM_HIBRID          //hybrid Mode
  };
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+
input Smooth_Method MA_Method0=MODE_SMA; // Метод усреднения таймсерий
input int Length0=3; // Глубина усреднения таймсерий
input int Phase0=15; // Параметр усреднения таймсерий
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
input Smooth_Method MA_Method1=MODE_SMMA; // Метод усреднения скользящей средней
input int Length1=10; // Глубина усреднения скользящей средней
input int Phase1=15;  // Параметр усреднения скользящей средней
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
input Smooth_Method MA_Method2=MODE_SMA; // Метод сглаживания стандартного отклонения
input int Length2=70; // Глубина сглаживания стандартного отклонения
input int Phase2=100; // Параметр сглаживания стандартного отклонения
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE;//ценовая константа
//---- 
input Smooth_Method MA_Method3=MODE_SMA; // Метод сглаживания канала
input int Length3=3; // Глубина сглаживания канала
input int Phase3=100;  // Параметр сглаживания канала
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
//----
input double BandsDeviation=2.0; // Отклонение
input MODE Mode=ENAM_HIBRID; // Вариант алгоритма
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//---- объявление динамического массива, который будет в 
//---- дальнейшем использован в качестве индикаторного буфера
double ExtLineBuffer0[];
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов уровней
double ExtLineBuffer1[],ExtLineBuffer2[];
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,min_rates_1,min_rates_2,min_rates_3;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_1=GetStartBars(MA_Method1,Length1,Phase1)+1;
   min_rates_2=min_rates_1+int(Length1);
   min_rates_total=min_rates_2+GetStartBars(MA_Method2,Length2,Phase2);
   int  min_rates_0=GetStartBars(MA_Method0,Length0,Phase0)+1;
   min_rates_3=MathMax(min_rates_total,min_rates_0);
   min_rates_total=min_rates_3+GetStartBars(MA_Method3,Length3,Phase3)+1;
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,ExtLineBuffer0,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(1,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer2,INDICATOR_DATA);
//---- установка позиции, с которой начинается отрисовка уровней Боллинджера
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- инициализация переменной для короткого имени индикатора
   string shortname="Volatility_Step_Channel";
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(0);
//---- объявление переменных с плавающей точкой  
   double price,xma,stdev,xstdev,xlow,xhigh,xclose,base,base2,Middle=0.0,Upper,Lower,iLow,iHigh,iClose;
   static double iLow_prev,iHigh_prev,iClose_prev;
//---- объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=0; // стартовый номер для расчета всех баров
      iLow_prev=low[first];
      iHigh_prev=high[first];
      iClose_prev=close[first];
      for(bar=0; bar<=min_rates_total && !IsStopped(); bar++)
        {
         ExtLineBuffer0[bar]=close[bar];
         ExtLineBuffer1[bar]=high[bar];
         ExtLineBuffer2[bar]=low[bar];
        }
     }
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      iLow=low[bar];
      iHigh=high[bar];
      iClose=close[bar];
      price=PriceSeries(IPC,bar,open,low,high,close);
      xma=XMA1.XMASeries(0,prev_calculated,rates_total,MA_Method1,Phase1,Length1,price,bar,false);
      stdev=STD.StdDevSeries(min_rates_1,prev_calculated,rates_total,Length1,1.0,price,xma,bar,false);
      xstdev=XMA2.XMASeries(min_rates_2,prev_calculated,rates_total,MA_Method2,Phase2,Length2,stdev,bar,false);
      base=xstdev*BandsDeviation;
      base2=base/2.0;
      xlow=XMA3.XMASeries(0,prev_calculated,rates_total,MA_Method0,Phase0,Length0,low[bar],bar,false);
      xhigh=XMA4.XMASeries(0,prev_calculated,rates_total,MA_Method0,Phase0,Length0,high[bar],bar,false);
      xclose=XMA5.XMASeries(0,prev_calculated,rates_total,MA_Method0,Phase0,Length0,close[bar],bar,false);
      //---
      if(xhigh-base>iHigh_prev) iHigh=xhigh;
      else if(xhigh+base<iHigh_prev) iHigh=xhigh+base;
      else iHigh=iHigh_prev;
      //---
      if(xlow+base<iLow_prev) iLow=xlow;
      else if(xlow-base>iLow_prev) iLow=xlow-base;
      else iLow=iLow_prev;
      //---
      switch(Mode)
        {
         case ENAM_SIMPLE :
           {
            if(xclose-base>iClose_prev) iClose=xclose-base;
            else if(xclose+base<iClose_prev) iClose=xclose+base;
            else iClose=iClose_prev;
            Middle=(iHigh+iLow+iClose)/3;
            break;
           }
         case ENAM_HIBRID :
           {
            if(xclose-base2>iClose_prev) iClose=xclose-base2;
            else if(xclose+base2<iClose_prev) iClose=xclose+base2;
            else iClose=iClose_prev;
            Middle=(iHigh+iLow+2*iClose)/4;
           }
        }
      Upper=iHigh+base2;
      Lower=iLow-base2;
      //---      
      ExtLineBuffer2[bar]=XMA6.XMASeries(min_rates_3,prev_calculated,rates_total,MA_Method3,Phase3,Length3,Lower,bar,false);
      ExtLineBuffer1[bar]=XMA7.XMASeries(min_rates_3,prev_calculated,rates_total,MA_Method3,Phase3,Length3,Upper,bar,false);
      ExtLineBuffer0[bar]=XMA8.XMASeries(min_rates_3,prev_calculated,rates_total,MA_Method3,Phase3,Length3,Middle,bar,false);
      //---
      if(bar<rates_total-1)
        {
         iLow_prev=iLow;
         iHigh_prev=iHigh;
         iClose_prev=iClose;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
