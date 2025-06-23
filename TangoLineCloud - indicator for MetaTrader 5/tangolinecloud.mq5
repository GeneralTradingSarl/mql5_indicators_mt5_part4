//+------------------------------------------------------------------+
//|                                               TangoLineCloud.mq5 |
//|                                         Copyright © 2015, fxborg | 
//|                                   http://fxborg-labo.hateblo.jp/ | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property description ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 9
#property indicator_buffers 9 
//---- использовано всего пять графических построений
#property indicator_plots   5
//+----------------------------------------------+
//| Параметры отрисовки облака                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color1  clrLightSkyBlue
//---- отображение метки индикатора
#property indicator_label1  "Upper TangoLineCloud Cloud"
//+----------------------------------------------+
//| Параметры отрисовки облака                   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type2   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color2  clrPink
//---- отображение метки индикатора
#property indicator_label2  "Lower TangoLineCloud Cloud"
//+--------------------------------------------+
//| Параметры отрисовки индикатора             |
//+--------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type3   DRAW_LINE
//---- в качестве цвета линии индикатора использован BlueViolet цвет
#property indicator_color3 clrBlueViolet
//---- линия индикатора - сплошная кривая
#property indicator_style3  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width3  2
//---- отображение метки индикатора
#property indicator_label3  "TangoLine"
//+--------------------------------------------+
//| Параметры отрисовки индикатора уровней     |
//+--------------------------------------------+
//---- отрисовка уровней  в виде линий
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
//---- выбор цветов уровней
#property indicator_color4  clrLimeGreen
#property indicator_color5  clrRed
//---- уровни - сплошные кривые
#property indicator_style4 STYLE_SOLID
#property indicator_style5 STYLE_SOLID
//---- толщина уровней равна 2
#property indicator_width4  2
#property indicator_width5  2
//---- отображение меток уровней
#property indicator_label4  "Upper"
#property indicator_label5  "Lower"
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+
input  int InpPeriod=20;   // Period
input  double MinSpread=5; // Min Spread 
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double LineBuffer[],HighesBuffer[],LowesBuffer[],HighBuffer[],LowBuffer[];
double UpHighesBuffer[],DnHighesBuffer[],UpLowesBuffer[],DnLowesBuffer[];
//---- объявление переменной значения максимального спреда
double dMinSpread;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=int(InpPeriod)+3;
//---- инициализация сдвига по вертикали
   dMinSpread=MinSpread*_Point;
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpHighesBuffer,INDICATOR_DATA);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,DnHighesBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,UpLowesBuffer,INDICATOR_DATA);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(3,DnLowesBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(4,LineBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(5,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,LowBuffer,INDICATOR_DATA);
//---- установка позиции, с которой начинается отрисовка уровней
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0.0);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(7,HighesBuffer,INDICATOR_CALCULATIONS);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(8,LowesBuffer,INDICATOR_CALCULATIONS);

//---- инициализация переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"TangoLine(",InpPeriod,", ",MinSpread,", ",Shift,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
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
   double  dmin,dmax;
//---- объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar;
   static int top_bar,btm_bar;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=0; // стартовый номер для расчета всех баров
      top_bar=0;
      btm_bar=0;
     }
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//----
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      LowesBuffer[bar]=0.0;
      HighesBuffer[bar]=0.0;
      HighBuffer[bar]=0.0;
      LowBuffer[bar]=0.0;
      LineBuffer[bar]=0.0;
     }
//----
   if(prev_calculated>rates_total || prev_calculated<=0) first=min_rates_total;
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //--- calculate range spread
      dmin=1000000.0;
      dmax=-1000000.0;
      for(int kkk=bar-int(InpPeriod)+1; kkk<=bar; kkk++)
        {
         if(dmin>low[kkk]) dmin=low[kkk];
         if(dmax<high[kkk]) dmax=high[kkk];
        }
      //--- hook
      if((LowesBuffer[bar-2]-dMinSpread)>LowesBuffer[bar-1] && LowesBuffer[bar-1]==dmin)
        {
         top_bar=bar-1;
         btm_bar=bar-1;
        }
      if((HighesBuffer[bar-2]+dMinSpread)<HighesBuffer[bar-1] && HighesBuffer[bar-1]==dmax)
        {
         btm_bar=bar-1;
         top_bar=bar-1;
        }
      LowesBuffer[bar]=dmin;
      HighesBuffer[bar]=dmax;
      if(MathMax(top_bar,btm_bar)>bar-int(InpPeriod)+1)
        {
         //--- calculate range spread
         dmin=1000000.0;
         dmax=-1000000.0;
         //---
         for(int kkk=bar-int(InpPeriod)+1; kkk<=bar; kkk++)
           {
            //---
            if(kkk>=btm_bar && dmin>low[kkk]) dmin=low[kkk];
            if(kkk>=top_bar && dmax<high[kkk]) dmax=high[kkk];
           }
        }
      LowBuffer[bar]=DnLowesBuffer[bar]=dmin;
      HighBuffer[bar]=UpHighesBuffer[bar]=dmax;
      LineBuffer[bar]=DnHighesBuffer[bar]=UpLowesBuffer[bar]=(dmax+dmin)/2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
