//+------------------------------------------------------------------+
//|                                                   StepSto_v2.mq5 |
//|                           Copyright © 2005, TrendLaboratory Ltd. |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                       E-mail: igorad2004@list.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TrendLaboratory Ltd."
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- для расчёта и отрисовки индикатора использовано три буфера
#property indicator_buffers 3
//---- использовано два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки индикатора StepSto Fast |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветной гистограммы
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- в качестве цветов гистограммы использованы
#property indicator_color1 clrLime,clrGreen,clrGray,clrMaroon,clrRed
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение бычей метки индикатора
#property indicator_label1  "StepSto Fast"
//+----------------------------------------------+
//|  Параметры отрисовки индикатора StepSto Slow |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета медвежьей линии индикатора использован MediumSlateBlue цвет
#property indicator_color2  clrMediumSlateBlue
//---- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора 2 равна 1
#property indicator_width2  1
//---- отображение медвежьей метки индикатора
#property indicator_label2  "StepSto Slow"
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input double Kfast=1.0000;
input double Kslow=1.0000;
input int Shift=0;             // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в дальнейшем использованы в качестве индикаторных буферов
double FastBuffer[],ColorFastBuffer[];
double SlowBuffer[];
//---- Объявление целых переменных для хендлов индикаторов
int ATR_Handle;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total,PeriodATR;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   PeriodATR=10;
   min_rates_total=MathMax(2,PeriodATR);

//---- получение хендла индикатора iATR
   ATR_Handle=iATR(NULL,PERIOD_CURRENT,PeriodATR);
   if(ATR_Handle==INVALID_HANDLE) Print(" Не удалось получить хендл индикатора iATR");

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,FastBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 1 на min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(FastBuffer,true);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorFastBuffer,INDICATOR_COLOR_INDEX);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorFastBuffer,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,SlowBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 2 на min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SlowBuffer,true);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"StepSto(",Kfast,",",Kslow,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчёта индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчёта индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//---- объявления локальных переменных 
   int limit,to_copy,TrendMin0,TrendMax0,TrendMid0,clr;
   double ATR[],linemin=0.0,linemax=0.0,linemid=0.0,Sto1,Sto2,bsmin,bsmax,StepSizeMin,StepSizeMax;
   double SminMid0,SmaxMid0,SminMin0,SmaxMin0,SminMax0,SmaxMax0,ATRmax0,ATRmin0,StepSizeMid;
   static double SminMin1,SmaxMin1,SminMax1,SmaxMax1,SminMid1,SmaxMid1,ATRmax1,ATRmin1;
   static int TrendMin1,TrendMax1,TrendMid1;

//---- индексация элементов в массивах, как в таймсериях  
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(ATR,true);

//---- расчёт стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
      ATRmax1=0.0;
      ATRmin1=999999999.9;
      SminMin1=close[limit];
      SmaxMin1=close[limit];
      SminMax1=close[limit];
      SmaxMax1=close[limit];
      SminMid1=close[limit];
      SmaxMid1=close[limit];
      TrendMax1=+1;
      TrendMin1=-1;
      TrendMid1=+1;
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров
//----
   to_copy=limit+1;

//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);

//---- восстанавливаем значения переменных
   TrendMax0=TrendMax1;
   TrendMin0=TrendMin1;
   TrendMid0=TrendMid1;

//---- основной цикл расчёта индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ATRmax0=MathMax(ATR[bar],ATRmax1);
      ATRmin0=MathMin(ATR[bar],ATRmin1);
      //----
      StepSizeMin=(Kfast*ATRmin0);
      StepSizeMax=(Kfast*ATRmax0);
      StepSizeMid=Kfast*0.5*Kslow*(ATRmax0+ATRmin0);
      //----
      SmaxMin0=close[bar]+2*StepSizeMin;
      SminMin0=close[bar]-2*StepSizeMin;

      SmaxMax0=close[bar]+2*StepSizeMax;
      SminMax0=close[bar]-2*StepSizeMax;

      SmaxMid0=close[bar]+2*StepSizeMid;
      SminMid0=close[bar]-2*StepSizeMid;
      //----
      if(close[bar]>SmaxMin1) TrendMin0=+1;
      if(close[bar]<SminMin1) TrendMin0=-1;

      if(close[bar]>SmaxMax1) TrendMax0=+1;
      if(close[bar]<SminMax1) TrendMax0=-1;

      if(close[bar]>SmaxMid1) TrendMid0=+1;
      if(close[bar]<SminMid1) TrendMid0=-1;

      if(TrendMin0>0 && SminMin0<SminMin1) SminMin0=SminMin1;
      if(TrendMin0<0 && SmaxMin0>SmaxMin1) SmaxMin0=SmaxMin1;

      if(TrendMax0>0 && SminMax0<SminMax1) SminMax0=SminMax1;
      if(TrendMax0<0 && SmaxMax0>SmaxMax1) SmaxMax0=SmaxMax1;

      if(TrendMid0>0 && SminMid0<SminMid1) SminMid0=SminMid1;
      if(TrendMid0<0 && SmaxMid0>SmaxMid1) SmaxMid0=SmaxMid1;

      if(TrendMin0>0) linemin=SminMin0+StepSizeMin;
      if(TrendMin0<0) linemin=SmaxMin0-StepSizeMin;

      if(TrendMax0>0) linemax=SminMax0+StepSizeMax;
      if(TrendMax0<0) linemax=SmaxMax0-StepSizeMax;

      if(TrendMid0>0) linemid=SminMid0+StepSizeMid;
      if(TrendMid0<0) linemid=SmaxMid0-StepSizeMid;
      //----      
      bsmin=linemax-StepSizeMax;
      bsmax=linemax+StepSizeMax;

      Sto1=100*(linemin-bsmin)/(bsmax-bsmin);
      Sto2=100*(linemid-bsmin)/(bsmax-bsmin);
      Sto1-=50;
      Sto2-=50;
      FastBuffer[bar]=Sto1;
      SlowBuffer[bar]=Sto2;
      clr=2;

      if(Sto1>0)
        {
         if(Sto1>=Sto2) clr=0;
         else clr=1;
        }
      else
        {
         if(Sto1<=Sto2) clr=4;
         else clr=3;
        }
      ColorFastBuffer[bar]=clr;

      if(bar)
        {
         ATRmax1=ATRmax0;
         ATRmin1=ATRmin0;
         SminMin1=SminMin0;
         SmaxMin1=SmaxMin0;
         SminMax1=SminMax0;
         SmaxMax1=SmaxMax0;
         SminMid1=SminMid0;
         SmaxMid1=SmaxMid0;
         TrendMax1=TrendMax0;
         TrendMin1=TrendMin0;
         TrendMid1=TrendMid0;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
