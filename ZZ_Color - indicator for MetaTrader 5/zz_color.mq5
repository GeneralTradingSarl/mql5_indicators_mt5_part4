//+------------------------------------------------------------------+
//|                                                     ZZ_Color.mq5 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+ 
//---- авторство индикатора
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
//---- ссылка на сайт автора
#property link      "http://www.metaquotes.net/"
//---- номер версии индикатора
#property version   "1.00"
#property description "ZigZag" 
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчёта и отрисовки индикатора использовано 5 буферов
#property indicator_buffers 5
//---- использовано всего 2 графических построения
#property indicator_plots   1
//+----------------------------------------------+ 
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- в качестве индикатора использован ZIGZAG
#property indicator_type1   DRAW_COLOR_ZIGZAG
//---- отображение метки индикатора
#property indicator_label1  "ZigZag"
//---- в качестве цвета линии индикатора использованы
#property indicator_color1 clrDeepPink,clrDodgerBlue
//---- линия индикатора - длинный пунктир
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//+----------------------------------------------+ 
//| Входные параметры индикатора                 |
//+----------------------------------------------+ 
input uint ExtDepth=12;
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double LowestBuffer[];
double HighestBuffer[];
double ColorBuffer[];
double ZZLBuffer[];
double ZZHBuffer[];

//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(ExtDepth);

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0,LowestBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighestBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ColorBuffer,INDICATOR_COLOR_INDEX);
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(3,ZZLBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ZZHBuffer,INDICATOR_DATA);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- индексация элементов в буферах как в таймсериях   
   ArraySetAsSeries(LowestBuffer,true);
   ArraySetAsSeries(HighestBuffer,true);
   ArraySetAsSeries(ColorBuffer,true);
   ArraySetAsSeries(ZZLBuffer,true);
   ArraySetAsSeries(ZZHBuffer,true);
//---- установка позиции, с которой начинается отрисовка уровней Боллинджера
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и лэйба для субъокон 
   string shortname;
   StringConcatenate(shortname,"ZigZag (ExtDepth=",ExtDepth,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//----   
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,
                const int prev_calculated,
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

//---- объявления локальных переменных 
   int limit,climit,bar,curlowpos,curhighpos,pos;
   static int lasthighpos,lastlowpos;
   double curlow,curhigh,min,max;
   static double lasthigh,lastlow;

//---- расчёт стартового номера limit для цикла пересчёта баров и стартовая инициализация переменных
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total; // стартовый номер для расчёта всех баров
      climit=limit; // стартовый номер для раскраски индикатора

      lasthighpos=limit;
      lastlowpos=limit;
      lastlow=low[limit];
      lasthigh=high[limit];
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров
      climit=limit+min_rates_total; // стартовый номер для раскраски индикатора

      int lim=rates_total-prev_calculated;
      limit=lim+MathMax(lasthighpos,lastlowpos);
      lasthighpos+=lim;
      lastlowpos+=lim;
     }

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- Первый большой цикл расчёта индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- low
      LowestBuffer[bar]=NULL;
      ZZLBuffer[bar]=NULL;
      curlowpos=ArrayMinimum(low,bar,ExtDepth);
      curlow=low[curlowpos];
      if(lasthighpos>curlowpos)
        {
         ZZLBuffer[curlowpos]=curlow;
         min=999999999;
         pos=lasthighpos;
         for(int rrr=lasthighpos; rrr>=curlowpos; rrr--)
           {
            if(!ZZLBuffer[rrr]) continue;
            if(ZZLBuffer[rrr]<min)
              {
               min=ZZLBuffer[rrr];
               pos=rrr;
              }
            LowestBuffer[rrr]=NULL;
           }
         LowestBuffer[pos]=min;
        }
      lastlowpos=curlowpos;
      lastlow=curlow;

      //--- high
      HighestBuffer[bar]=NULL;
      ZZHBuffer[bar]=NULL;
      curhighpos=ArrayMaximum(high,bar,ExtDepth);
      curhigh=high[curhighpos];
      if(curhigh<=lasthigh) lasthigh=curhigh;
      else
        {
         if(lastlowpos>curhighpos)
           {
            ZZHBuffer[curhighpos]=curhigh;
            max=-999999999;
            pos=lastlowpos;
            for(int rrr=lastlowpos; rrr>=curhighpos; rrr--)
              {
               if(!ZZHBuffer[rrr]) continue;
               if(ZZHBuffer[rrr]>max)
                 {
                  max=ZZHBuffer[rrr];
                  pos=rrr;
                 }
               HighestBuffer[rrr]=NULL;
              }
            HighestBuffer[pos]=max;
           }
         lasthighpos       =  curhighpos;
         lasthigh          =  curhigh;
        }
     }

//---- Второй большой цикл раскраски индикатора
   for(bar=climit; bar>=0 && !IsStopped(); bar--)
     {
      max=HighestBuffer[bar];
      min=LowestBuffer[bar];

      if(!max && !min) ColorBuffer[bar]=ColorBuffer[bar+1];
      if(max && min)
        {
         if(ColorBuffer[bar+1]==0) ColorBuffer[bar]=1;
         else                      ColorBuffer[bar]=0;
        }

      if( max && !min) ColorBuffer[bar]=1;
      if(!max &&  min) ColorBuffer[bar]=0;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
