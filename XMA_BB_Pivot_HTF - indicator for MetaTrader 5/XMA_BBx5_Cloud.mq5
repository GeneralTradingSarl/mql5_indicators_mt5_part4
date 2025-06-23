//+---------------------------------------------------------------------+
//|                                                  XMA_BBx5_Cloud.mq5 | 
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
//---- использовано всего четыре графических построения
#property indicator_plots   4
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color1  clrDeepSkyBlue
//---- отображение метки индикатора
#property indicator_label1  "Upper Sigma2 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type2   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color2  clrLavender
//---- отображение метки индикатора
#property indicator_label2  "Sigma1 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки мувинга                 |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type3   DRAW_LINE
//---- в качестве цвета линии индикатора использован сине-фиолетовый цвет
#property indicator_color3 clrBlueViolet
//---- линия индикатора - сплошная
#property indicator_style3  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width3  2
//---- отображение метки индикатора
#property indicator_label3  "XMA"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type4   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color4  clrHotPink
//---- отображение метки индикатора
#property indicator_label4  "Lower Sigma2 Cloud"
//+--------------------------------------------+
//|  Описание классов усреднений               |
//+--------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+--------------------------------------------+
//---- объявление переменных классов CXMA и CStdDeviation из файла SmoothAlgorithms.mqh
CXMA XMA1;
CStdDeviation STD1,STD2;
//+--------------------------------------------+
//|  объявление перечислений                   |
//+--------------------------------------------+
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
//+--------------------------------------------+
//|  объявление перечислений                   |
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
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА              |
//+--------------------------------------------+
input Smooth_Method XMA_Method=MODE_SMA_; //метод усреднения
input uint XLength=100; //глубина  усреднения                    
input int XPhase=15; //параметр первого усреднения,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input double BandsDeviation1=2.0; //девиация 1
input double BandsDeviation2=4.0; //девиация 2
input Applied_price_ IPC=PRICE_CLOSE_;//ценовая константа
input int Shift=0; // сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // cдвиг индикатора по вертикали в пунктах
//---- цвета ценовых меток
input color  Middle_color=clrBlue;
input color  Upper_color1=clrMediumSeaGreen;
input color  Lower_color1=clrRed;
input color  Upper_color2=clrDodgerBlue;
input color  Lower_color2=clrMagenta;
//+--------------------------------------------+
//---- объявление динамического массива, который будет в 
// дальнейшем использован в качестве индикаторного буфера
double ExtLineBuffer0[];
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов уровней Боллинджера
double UpBuffer1[],DnBuffer1[],UpBuffer2[],DnBuffer2[],UpBuffer3[],DnBuffer3[];
//---- Объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total,min_rates_1;
//---- Объявление стрингов для текстовых меток
string upper_name1,middle_name,lower_name1,upper_name2,lower_name2;
//+------------------------------------------------------------------+   
//| X2MA BBx5 indicator initialization function                      | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_1=GetStartBars(XMA_Method,XLength,XPhase)+1;
   min_rates_total=min_rates_1+int(XLength);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMALengthCheck("XLength",XLength);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMAPhaseCheck("XPhase",XPhase,XMA_Method);
//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
   if(BandsDeviation1>=BandsDeviation2)
    {
     Print("Входной параметр Девиация 2 всегда должен быть больше входного параметра Девиация 1! Исправьте значения этих входных параметров индикатора!");
     return(INIT_FAILED);
    }

//---- Инициализация стрингов
   upper_name1="Price_Channel_Central upper text lable 1";
   middle_name="Price_Channel_Central middle text lable";
   lower_name1="Price_Channel_Central lower text lable 1";
   upper_name2="Price_Channel_Central upper text lable 2";
   lower_name2="Price_Channel_Central lower text lable 2";

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpBuffer2,INDICATOR_DATA);
   SetIndexBuffer(1,DnBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,UpBuffer1,INDICATOR_DATA);
   SetIndexBuffer(3,DnBuffer1,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLineBuffer0,INDICATOR_DATA);
   SetIndexBuffer(5,UpBuffer3,INDICATOR_DATA);
   SetIndexBuffer(6,DnBuffer3,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   string Smooth=XMA1.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"XMA_Bollinger Bands(",Smooth,", ",XLength,", ",DoubleToString(BandsDeviation1,2),", ",DoubleToString(BandsDeviation2,2),")");
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
//----
  }
//+------------------------------------------------------------------+ 
//| X2MA BBx5 iteration function                                     | 
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
   double price,xma,line,stdev;
//---- Объявление целых переменных и получение уже посчитанных баров
   int first,bar;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
      first=0; // стартовый номер для расчёта всех баров
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- Основной цикл расчёта индикатора
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
      DnBuffer3[bar]=line-stdev;
     }
   int bar0=rates_total-1;
   SetRightPrice(0,middle_name,0,time[bar0],ExtLineBuffer0[bar0],Middle_color,"Georgia");
   SetRightPrice(0,upper_name1,0,time[bar0],UpBuffer1[bar0],Upper_color1,"Georgia");
   SetRightPrice(0,lower_name1,0,time[bar0],DnBuffer1[bar0],Lower_color1,"Georgia");
   SetRightPrice(0,upper_name2,0,time[bar0],UpBuffer2[bar0],Upper_color2,"Georgia");
   SetRightPrice(0,lower_name2,0,time[bar0],DnBuffer3[bar0],Lower_color2,"Georgia");
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  RightPrice creation                                             |
//+------------------------------------------------------------------+
void CreateRightPrice(long chart_id,// chart ID
                      string   name,              // object name
                      int      nwin,              // window index
                      datetime time,              // price level time
                      double   price,             // price level
                      color    Color,             // Text color
                      string   Font               // Text font
                      )
//---- 
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
//|  RightPrice reinstallation                                       |
//+------------------------------------------------------------------+
void SetRightPrice(long chart_id,// chart ID
                   string   name,              // object name
                   int      nwin,              // window index
                   datetime time,              // price level time
                   double   price,             // price level
                   color    Color,             // Text color
                   string   Font               // Text font
                   )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRightPrice(chart_id,name,nwin,time,price,Color,Font);
   else ObjectMove(chart_id,name,0,time,price);
//----
  }
//+------------------------------------------------------------------+
