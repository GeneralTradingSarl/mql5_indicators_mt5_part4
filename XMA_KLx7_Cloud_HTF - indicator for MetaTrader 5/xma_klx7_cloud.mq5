//+---------------------------------------------------------------------+
//|                                                  XMA_KLx7_Cloud.mq5 | 
//|                                  Copyright © 2016, Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2016, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "XMA Keltner Channel"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 11
#property indicator_buffers 11 
//---- использовано всего шесть графических построений
#property indicator_plots   6
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color1  clrAqua
//---- отображение метки индикатора
#property indicator_label1  "Upper Sigma3 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type2   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color2  clrPaleGreen
//---- отображение метки индикатора
#property indicator_label2  "Upper Sigma2 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type3   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color3  clrLavender
//---- отображение метки индикатора
#property indicator_label3  "Sigma1 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки мувинга                 |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type4   DRAW_LINE
//---- в качестве цвета линии индикатора использован синий цвет
#property indicator_color4 clrBlue
//---- линия индикатора - сплошная
#property indicator_style4  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width4  2
//---- отображение метки индикатора
#property indicator_label4  "XMA"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type5   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color5  clrLightPink
//---- отображение метки индикатора
#property indicator_label5  "Lower Sigma2 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type6   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color6  clrGold
//---- отображение метки индикатора
#property indicator_label6  "Lower Sigma3 Cloud"
//+--------------------------------------------+
//|  Описание классов усреднений               |
//+--------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+--------------------------------------------+

//---- объявление переменных классов CXMA и CStdDeviation из файла SmoothAlgorithms.mqh
CXMA XMA1;
//+--------------------------------------------+
//|  Объявление перечислений                   |
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
//|  Объявление перечислений                   |
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
   MODE_AMA    //AMA
  }; */
//+--------------------------------------------+
//|  Входные параметры индикатора              |
//+--------------------------------------------+
input Smooth_Method XMA_Method=MODE_SMA; //Метод усреднения
input uint XLength=100; //Глубина  усреднения
input int XPhase=15; //Параметр первого усреднения
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
//----
input uint KeltnerPeriod=20; //Период усреднения Кёлтнера
input double Ratio1 = 1.0; //Коэффициент первого уровня
input double Ratio2 = 2.0; //Коэффициент второго уровня
input double Ratio3 = 3.0; //Коэффициент третьего уровня
//----
input Applied_price_ IPC=PRICE_CLOSE;//Ценовая константа
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
// дальнейшем использованы в качестве индикаторных буферов уровней Кёлтнера
double UpBuffer1[],DnBuffer1[],UpBuffer2[],DnBuffer2[],UpBuffer3[],DnBuffer3[];
double UpBuffer4[],DnBuffer4[],UpBuffer5[],DnBuffer5[];
//---- Объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//---- Объявление целочисленных переменных начала отсчёта данных
int min_rates_total;
//---- Объявление строковых переменных для текстовых меток
string upper_name1,middle_name,lower_name1,upper_name2,lower_name2,upper_name3,lower_name3;
//+------------------------------------------------------------------+
//| вычисление половины ширины канала Кёлтнера                       |
//+------------------------------------------------------------------+ 
double GetKeltner(int period,int bar,const double &High[],const double &Low[])
  {
//----
   double Resalt,sum=0;
   for(int iii=0; iii<period; iii++)
      sum+=High[bar-iii] - Low[bar-iii];
   Resalt = sum / period;
   return(Resalt);
//----
  }
//+------------------------------------------------------------------+   
//| XMA Keltner Channel indicator initialization function            | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=GetStartBars(XMA_Method,XLength,XPhase)+1;
   min_rates_total+=int(KeltnerPeriod);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMALengthCheck("XLength",XLength);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMAPhaseCheck("XPhase",XPhase,XMA_Method);
//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
   if(Ratio1>=Ratio2)
     {
      Print("Входной параметр Коэффициент второго уровня всегда должен быть больше входного параметра Коэффициент первого уровня! Исправьте значения этих входных параметров индикатора!");
      return(INIT_FAILED);
     }
   if(Ratio2>=Ratio3)
     {
      Print("Входной параметр Коэффициент третьего уровня всегда должен быть больше входного параметра Коэффициент второго уровня! Исправьте значения этих входных параметров индикатора!");
      return(INIT_FAILED);
     }
//---- Инициализация строковых переменных
   upper_name1="Price_Channel_Central upper text lable 1";
   middle_name="Price_Channel_Central middle text lable";
   lower_name1="Price_Channel_Central lower text lable 1";
   upper_name2="Price_Channel_Central upper text lable 2";
   lower_name2="Price_Channel_Central lower text lable 2";
   upper_name3="Price_Channel_Central upper text lable 3";
   lower_name3="Price_Channel_Central lower text lable 3";
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpBuffer4,INDICATOR_DATA);
   SetIndexBuffer(1,DnBuffer4,INDICATOR_DATA);
   SetIndexBuffer(2,UpBuffer2,INDICATOR_DATA);
   SetIndexBuffer(3,DnBuffer2,INDICATOR_DATA);
   SetIndexBuffer(4,UpBuffer1,INDICATOR_DATA);
   SetIndexBuffer(5,DnBuffer1,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLineBuffer0,INDICATOR_DATA);
   SetIndexBuffer(7,UpBuffer3,INDICATOR_DATA);
   SetIndexBuffer(8,DnBuffer3,INDICATOR_DATA);
   SetIndexBuffer(9,UpBuffer5,INDICATOR_DATA);
   SetIndexBuffer(10,DnBuffer5,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(5,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- инициализация переменной для короткого имени индикатора
   string shortname;
   string Smooth=XMA1.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"XMA_KLx7_Cloud(",Smooth,", ",XLength,", ",KeltnerPeriod,", ",
                    DoubleToString(Ratio1,2),", ",DoubleToString(Ratio2,2),", ",DoubleToString(Ratio3,2),")");
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
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+ 
//| XMA Keltner Channel iteration function                           | 
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
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);
//---- Объявление переменных с плавающей точкой  
   double price,xma,line;
   double Keltner1,Keltner2,Keltner3,Keltner;
//---- Объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar;
//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=0; // стартовый номер для расчёта всех баров для мувинга
     }
   else
     {
      first=prev_calculated-1; // стартовый номер для расчёта новых баров для мувинга
     }
//---- Основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(IPC,bar,open,low,high,close);
      xma=XMA1.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,XLength,price,bar,false);
      line=xma+dPriceShift;
      ExtLineBuffer0[bar]=xma+dPriceShift; 
     }
   if(prev_calculated>rates_total || prev_calculated<=0) first=min_rates_total;  
   for(bar=first; bar<rates_total && !IsStopped(); bar++)  
     {     
      Keltner=GetKeltner(KeltnerPeriod,bar,high,low);
      Keltner1=Ratio1*Keltner;
      Keltner2=Ratio2*Keltner;
      Keltner3=Ratio3*Keltner;
      line=ExtLineBuffer0[bar];
      UpBuffer1[bar]=DnBuffer2[bar]=line+Keltner1;
      DnBuffer1[bar]=UpBuffer3[bar]=line-Keltner1;
      UpBuffer2[bar]=DnBuffer4[bar]=line+Keltner2;
      DnBuffer3[bar]=UpBuffer5[bar]=line-Keltner2;     
      UpBuffer4[bar]=line+Keltner3;
      DnBuffer5[bar]=line-Keltner3;
     }
   int bar0=rates_total-1;
   SetRightPrice(0,middle_name,0,time[bar0],ExtLineBuffer0[bar0],Middle_color,"Georgia");
   SetRightPrice(0,upper_name1,0,time[bar0],UpBuffer1[bar0],Upper_color1,"Georgia");
   SetRightPrice(0,lower_name1,0,time[bar0],DnBuffer1[bar0],Lower_color1,"Georgia");
   SetRightPrice(0,upper_name2,0,time[bar0],UpBuffer2[bar0],Upper_color2,"Georgia");
   SetRightPrice(0,lower_name2,0,time[bar0],DnBuffer3[bar0],Lower_color2,"Georgia");
   SetRightPrice(0,upper_name3,0,time[bar0],UpBuffer4[bar0],Upper_color3,"Georgia");
   SetRightPrice(0,lower_name3,0,time[bar0],DnBuffer5[bar0],Lower_color3,"Georgia");
//----
   ChartRedraw(0);     
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
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRightPrice(chart_id,name,nwin,time,price,Color,Font);
   else ObjectMove(chart_id,name,0,time,price);
//----
  }
//+------------------------------------------------------------------+
