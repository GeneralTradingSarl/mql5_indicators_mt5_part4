//+---------------------------------------------------------------------+
//|                                           VolatilityQualitySign.mq5 | 
//|                                          Copyright © 2008, raff1410 | 
//|                                                      raff1410@o2.pl | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2008, raff1410"
#property link "raff1410@o2.pl"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window
//---- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//| Параметры отрисовки медвежьего индикатора    |
//+----------------------------------------------+
//--- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//--- в качестве цвета медвежьей линии индикатора использован Magenta цвет
#property indicator_color1  clrMagenta
//--- толщина линии индикатора 1 равна 4
#property indicator_width1  4
//--- отображение медвежьей метки индикатора
#property indicator_label1  "VolatilityQuality Sell"
//+----------------------------------------------+
//| Параметры отрисовки бычьего индикатора       |
//+----------------------------------------------+
//--- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//--- в качестве цвета бычьей линии индикатора использован DodgerBlue цвет
#property indicator_color2  clrDodgerBlue
//--- толщина линии индикатора 2 равна 4
#property indicator_width2  4
//--- отображение бычьей метки индикатора
#property indicator_label2 "VolatilityQuality Buy"
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define RESET  0 // константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Описание класса CXMA                         |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XmaMH,XmaML,XmaMO,XmaMC,XmaMC1;
//+----------------------------------------------+
//| Объявление перечислений                      |
//+----------------------------------------------+
enum App_price //Тип константы
  {
   PRICE_CLOSE_=1,     //Close
   PRICE_MEDIAN_=5     //Median Price (HL/2)
  };
//+----------------------------------------------+
//| Объявление перечислений                      |
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
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input Smooth_Method XMA_Method=MODE_LWMA; // Метод усреднения
input int XLength=5; // Глубина  сглаживания
input int XPhase=15; // Параметр сглаживания
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
input uint Smoothing=1; // Глубина  пересчета 
input uint Filter=5; // Фильтрация в пунктах ценового графика
input App_price Price=PRICE_MEDIAN; // Цена
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double SellBuffer[],BuyBuffer[];
//----
int ATR_Handle;
//---- объявление переменной значения вертикального сдвига мувинга
double dFilter;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,min_rates,Len;
//---- объявление глобальных переменных
int Count[];
double Mc[];
//+------------------------------------------------------------------+
//| Пересчет позиции самого нового элемента в массиве                |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// возврат по ссылке номера текущего значения ценового ряда
                          int Size)
  {
//----
   int numb,Max1,Max2;
   static int count=1;
//----
   Max2=Size;
   Max1=Max2-1;
//----
   count--;
   if(count<0) count=Max1;
//----
   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
  }
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates=GetStartBars(XMA_Method,XLength,XPhase);
   min_rates_total=int(min_rates+Smoothing+1);
   int ATR_Period=10;
   min_rates_total=int(MathMax(min_rates_total+1,ATR_Period));
   Len=int(Smoothing+1);
//---- инициализация сдвига по вертикали
   dFilter=_Point*Filter;
//---- распределение памяти под массивы переменных  
   ArrayResize(Count,Len);
   ArrayResize(Mc,Len);
   ArrayInitialize(Count,0);
   ArrayInitialize(Mc,0.0);
//---- получение хендла индикатора ATR
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,175);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,175);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);

//---- инициализация переменной для короткого имени индикатора
   string shortname;
   string Smooth=XmaMC.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"VolatilityQualitySign(",XLength,", ",Smooth,")");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
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
   if(rates_total<min_rates_total) return(RESET);
//---- объявление переменных с плавающей точкой  
   double price,MH,ML,MC,MC1,MO,VQ,SumVQ,res1,res2,ATR[1];
   static double SumVQ_prev;
//---- объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar,trend;
   static int trend_prev;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=0; // стартовый номер для расчета всех баров
      SumVQ_prev=PriceSeries(Price,0,open,low,high,close);
      ArrayInitialize(Count,0);
      ArrayInitialize(Mc,SumVQ_prev);
      trend_prev=0;
     }
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(Price,bar,open,low,high,close);
      Mc[Count[0]]=XmaMC.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,XLength,price,bar,false);
      MC=Mc[Count[0]];
      MC1=Mc[Count[Smoothing]];
      if(bar==min_rates_total) SumVQ_prev=PriceSeries(Price,bar-1,open,low,high,close);
      MH=XmaMH.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,XLength,high[bar],bar,false);
      ML=XmaML.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,XLength,low[bar],bar,false);
      MO=XmaMO.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,XLength,open[bar],bar,false);
      res1=MathMax(MH-ML,MathMax(MH-MC1,MC1-ML));
      res2=MH-ML;
      if(res1 && res2) VQ=MathAbs(((MC-MC1)/res1+(MC-MO)/res2)*0.5)*((MC-MC1+(MC-MO))*0.5);
      else VQ=price;
      SumVQ=SumVQ_prev+VQ;
      if(Filter && MathAbs(SumVQ-SumVQ_prev)<dFilter) SumVQ=SumVQ_prev;
      //----
      if(SumVQ_prev<SumVQ) trend=+1;
      else if(SumVQ_prev>SumVQ) trend=-1;
      else trend=trend_prev;
      //----  
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      //----
      if(trend_prev<=0 && trend>0)
        {
         //---- копируем вновь появившиеся данные в массив
         if(CopyBuffer(ATR_Handle,0,time[bar],1,ATR)<=0) return(RESET);
         BuyBuffer[bar]=low[bar]-ATR[0]*3/8;
        }
      //----
      if(trend_prev>=0 && trend<0)
        {
         //---- копируем вновь появившиеся данные в массив
         if(CopyBuffer(ATR_Handle,0,time[bar],1,ATR)<=0) return(RESET);
         SellBuffer[bar]=high[bar]+ATR[0]*3/8;
        }
      //----
      if(bar<rates_total-1)
        {
         Recount_ArrayZeroPos(Count,Len);
         SumVQ_prev=SumVQ;
         if(trend) trend_prev=trend;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
