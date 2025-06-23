//+---------------------------------------------------------------------+
//|                                                        XMA_BBx7.mq5 | 
//|                                  Copyright © 2016, Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2016, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "XMA Bollinger Bands"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 7
#property indicator_buffers 7
//---- использовано всего семь графических построений
#property indicator_plots   7
//+----------------------------------------------+
//| Параметры отрисовки уровня                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета уровня использован
#property indicator_color1  clrDeepSkyBlue
//---- отображение метки индикатора
#property indicator_label1  "Upper Sigma3"
//+----------------------------------------------+
//| Параметры отрисовки уровня                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета уровня использован
#property indicator_color2  clrLime
//---- отображение метки индикатора
#property indicator_label2  "Upper Sigma2"
//+----------------------------------------------+
//| Параметры отрисовки уровня                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type3   DRAW_LINE
//---- в качестве цвета уровня использован
#property indicator_color3  clrTeal
//---- отображение метки индикатора
#property indicator_label3  "Upper Sigma1"
//+----------------------------------------------+
//| Параметры отрисовки мувинга                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type4   DRAW_LINE
//---- в качестве цвета линии индикатора использован сине-фиолетовый цвет
#property indicator_color4 clrBlueViolet
//---- линия индикатора - сплошная
#property indicator_style4  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width4  2
//---- отображение метки индикатора
#property indicator_label4  "XMA"
//+----------------------------------------------+
//| Параметры отрисовки уровня                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type5   DRAW_LINE
//---- в качестве цвета уровня использован
#property indicator_color5  clrRed
//---- отображение метки индикатора
#property indicator_label5  "Lower Sigma1"
//+----------------------------------------------+
//| Параметры отрисовки уровня                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type6   DRAW_LINE
//---- в качестве цвета уровня использован
#property indicator_color6  clrHotPink
//---- отображение метки индикатора
#property indicator_label6  "Lower Sigma2"
//+----------------------------------------------+
//| Параметры отрисовки уровня                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type7   DRAW_LINE
//---- в качестве цвета уровня использован
#property indicator_color7  clrMagenta
//---- отображение метки индикатора
#property indicator_label7  "Lower Sigma3"
//+--------------------------------------------+
//| Описание классов усреднений                |
//+--------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+--------------------------------------------+
//---- объявление переменных классов CXMA и CStdDeviation из файла SmoothAlgorithms.mqh
CXMA XMA1;
CStdDeviation STD1,STD2,STD3;
//+--------------------------------------------+
//| Объявление перечислений                    |
//+--------------------------------------------+
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
//+--------------------------------------------+
//| Объявление перечислений                    |
//+--------------------------------------------+
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
//+--------------------------------------------+
//| Входные параметры индикатора               |
//+--------------------------------------------+
input Smooth_Method XMA_Method=MODE_SMA; // Метод усреднения
input uint XLength=100; // Глубина  усреднения
input int XPhase=15; // Параметр первого усреднения
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
input double BandsDeviation1=2.0; // Девиация 1
input double BandsDeviation2=3.0; // Девиация 2
input double BandsDeviation3=4.0; // Девиация 3
input Applied_price_ IPC=PRICE_CLOSE;// Ценовая константа
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // Сдвиг индикатора по вертикали в пунктах
//---- цвета ценовых меток
input color  Middle_color=clrBlue;
input color  Upper_color1=clrMediumSeaGreen;
input color  Lower_color1=clrRed;
input color  Upper_color2=clrDodgerBlue;
input color  Lower_color2=clrMagenta;
input color  Upper_color3=clrBlue;
input color  Lower_color3=clrOrange;
//+--------------------------------------------+
//---- объявление динамического массива, который будет в 
// дальнейшем использован в качестве индикаторного буфера
double ExtLineBuffer0[];
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов уровней Боллинджера
double UpBuffer1[],DnBuffer1[],UpBuffer2[],DnBuffer2[],UpBuffer3[],DnBuffer3[];
//---- объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,min_rates_1;
//---- объявление строковых переменных для текстовых меток
string upper_name1,middle_name,lower_name1,upper_name2,lower_name2,upper_name3,lower_name3;
//+------------------------------------------------------------------+   
//| X2MA BBx7 indicator initialization function                      | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_1=GetStartBars(XMA_Method,XLength,XPhase)+1;
   min_rates_total=min_rates_1+int(XLength);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMALengthCheck("XLength",XLength);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMAPhaseCheck("XPhase",XPhase,XMA_Method);
//---- инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
   if(BandsDeviation1>=BandsDeviation2)
     {
      Print("Входной параметр Девиация 2 всегда должен быть больше входного параметра Девиация 1! Исправьте значения этих входных параметров индикатора!");
      return(INIT_FAILED);
     }
   if(BandsDeviation2>=BandsDeviation3)
     {
      Print("Входной параметр Девиация 3 всегда должен быть больше входного параметра Девиация 2! Исправьте значения этих входных параметров индикатора!");
      return(INIT_FAILED);
     }
//---- инициализация строковых переменных
   upper_name1="Price_Channel_Central upper text lable 1";
   middle_name="Price_Channel_Central middle text lable";
   lower_name1="Price_Channel_Central lower text lable 1";
   upper_name2="Price_Channel_Central upper text lable 2";
   lower_name2="Price_Channel_Central lower text lable 2";
   upper_name3="Price_Channel_Central upper text lable 3";
   lower_name3="Price_Channel_Central lower text lable 3";
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpBuffer3,INDICATOR_DATA);
   SetIndexBuffer(1,UpBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,UpBuffer1,INDICATOR_DATA);
   SetIndexBuffer(3,ExtLineBuffer0,INDICATOR_DATA);
   SetIndexBuffer(4,DnBuffer1,INDICATOR_DATA);
   SetIndexBuffer(5,DnBuffer2,INDICATOR_DATA);
   SetIndexBuffer(6,DnBuffer3,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(5,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(6,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,min_rates_total);
//---- инициализация переменной для короткого имени индикатора
   string shortname;
   string Smooth=XMA1.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"XMA_Bollinger Bands(",Smooth,", ",XLength,", ",DoubleToString(BandsDeviation1,2),", ",
                     DoubleToString(BandsDeviation2,2),", ",DoubleToString(BandsDeviation3,2),")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,upper_name1);
   ObjectDelete(0,middle_name);
   ObjectDelete(0,lower_name1);
   ObjectDelete(0,upper_name2);
   ObjectDelete(0,lower_name2);
   ObjectDelete(0,upper_name3);
   ObjectDelete(0,lower_name3);
//----
  }
//+------------------------------------------------------------------+ 
//| X2MA BBx5 iteration function                                     | 
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
   double price,xma,line,stdev;
//---- объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      first=0; // стартовый номер для расчета всех баров
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(IPC,bar,open,low,high,close);
      xma=XMA1.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,XLength,price,bar,false);
      line=xma+dPriceShift;
      ExtLineBuffer0[bar]=xma+dPriceShift;
      stdev=STD1.StdDevSeries(min_rates_1,prev_calculated,rates_total,XLength,BandsDeviation1,price,xma,bar,false);
      UpBuffer1[bar]=DnBuffer2[bar]=line+stdev;
      DnBuffer1[bar]=UpBuffer3[bar]=line-stdev;
      stdev=STD2.StdDevSeries(min_rates_1,prev_calculated,rates_total,XLength,BandsDeviation2,price,xma,bar,false);
      UpBuffer2[bar]=line+stdev;
      DnBuffer2[bar]=line-stdev;
      stdev=STD3.StdDevSeries(min_rates_1,prev_calculated,rates_total,XLength,BandsDeviation3,price,xma,bar,false);
      UpBuffer3[bar]=line+stdev;
      DnBuffer3[bar]=line-stdev;
     }
   int bar0=rates_total-1;
   SetRightPrice(0,middle_name,0,time[bar0],ExtLineBuffer0[bar0],Middle_color,"Georgia");
   SetRightPrice(0,upper_name1,0,time[bar0],UpBuffer1[bar0],Upper_color1,"Georgia");
   SetRightPrice(0,lower_name1,0,time[bar0],DnBuffer1[bar0],Lower_color1,"Georgia");
   SetRightPrice(0,upper_name2,0,time[bar0],UpBuffer2[bar0],Upper_color2,"Georgia");
   SetRightPrice(0,lower_name2,0,time[bar0],DnBuffer2[bar0],Lower_color2,"Georgia");
   SetRightPrice(0,upper_name3,0,time[bar0],UpBuffer3[bar0],Upper_color3,"Georgia");
   SetRightPrice(0,lower_name3,0,time[bar0],DnBuffer3[bar0],Lower_color3,"Georgia");
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| RightPrice creation                                              |
//+------------------------------------------------------------------+
void CreateRightPrice(long chart_id,// chart ID
                      string   name,              // object name
                      int      nwin,              // window index
                      datetime time,              // price level time
                      double   price,             // price level
                      color    Color,             // Text color
                      string   Font               // Text font
                      )
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW_RIGHT_PRICE,nwin,time,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,2);
//----
  }
//+------------------------------------------------------------------+
//| RightPrice reinstallation                                        |
//+------------------------------------------------------------------+
void SetRightPrice(long chart_id,// chart ID
                   string   name,              // object name
                   int      nwin,              // window index
                   datetime time,              // price level time
                   double   price,             // price level
                   color    Color,             // Text color
                   string   Font               // Text font
                   )
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRightPrice(chart_id,name,nwin,time,price,Color,Font);
   else ObjectMove(chart_id,name,0,time,price);
//----
  }
//+------------------------------------------------------------------+
