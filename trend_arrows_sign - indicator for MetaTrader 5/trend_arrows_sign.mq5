//+------------------------------------------------------------------+
//|                                            trend_arrows_sign.mq5 |
//|                               Copyright © 2012, Vladimir Mametov | 
//|                                                                  | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2012, Vladimir Mametov" 
#property link      "" 
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в основном окне
#property indicator_chart_window
//---- количество индикаторных буферов 2
#property indicator_buffers 2
//---- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки бычьего индикатора      |
//+----------------------------------------------+
//---- отрисовка индикатора в виде значка
#property indicator_type1 DRAW_ARROW
//---- в качестве окраски индикатора использован
#property indicator_color1 clrBlue
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки сигнальной линии
#property indicator_label1  "Buy trend_arrows signal"
//+----------------------------------------------+
//|  Параметры отрисовки медвежьего индикатора   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде значка
#property indicator_type2 DRAW_ARROW
//---- в качестве окраски индикатора использован
#property indicator_color2 clrRed
//---- линия индикатора - сплошная
#property indicator_style2 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width2 2
//---- отображение метки сигнальной линии
#property indicator_label2  "Sell trend_arrows signal"
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint iPeriod=15;  // Период индикатора
input uint iFullPeriods=1;
input int Shift=0;      // Сдвиг индикатора по горизонтали в барах 
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double SignUp[],SignDown[];
int arr[];
bool boolp1;
int ATR_Handle,min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=int(iPeriod+iFullPeriods);
   int ATR_Period=15;
   min_rates_total=MathMax(min_rates_total,ATR_Period);
   
//--- получение хендла индикатора ATR
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }

//---- распределение памяти под массивы переменных   
   ArrayResize(arr,min_rates_total);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"trend_arrows(",string(iPeriod),", ",string(iFullPeriods),", ",string(Shift),")");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SignUp,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,3*min_rates_total);
//---- индексация элементов в буферах, как в таймсериях   
   ArraySetAsSeries(SignUp,true);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,233);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,SignDown,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,3*min_rates_total);
//---- индексация элементов в буферах, как в таймсериях   
   ArraySetAsSeries(SignDown,true);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,234);
//---   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов цены для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

   int limit,bar,to_copy;
   double ATR[],TrendUp,TrendDown;
   static double TrendUp_prev,TrendDown_prev;

//---- индексация элементов в массивах, как в таймсериях  
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(ATR,true);

//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1;               // стартовый номер для расчета всех баров

      int tms1=rates_total-2-min_rates_total;
      while(!isDelimeter(Period(),time,tms1)) tms1--;
      boolp1=tms1;
      tms1--;
      for(int rrr=0; rrr<int(iPeriod); rrr++)
        {
         while(!isDelimeter(Period(),time,tms1)) tms1--;
         tms1--;
        }
      tms1++;
      limit=tms1;
     }
   else
     {
      limit=rates_total-prev_calculated;                 // стартовый номер для расчета новых баров
     }
   to_copy=limit+1;
     
   //--- копируем вновь появившиеся данные в массив ATR[]
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);

//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      TrendUp=0.0;
      TrendDown=0.0;
      SignUp[bar]=0.0;
      SignDown[bar]=0.0;
      double HH=AverageHigh(high,time,bar);
      double LL=AverageLow(low,time,bar);

      if(close[bar]>HH) TrendUp=LL;
      else
        {
         if(close[bar]<LL) TrendDown=HH;
         else
           {
            if(TrendDown_prev) TrendDown=HH;
            if(TrendUp_prev) TrendUp=LL;
           }
        }

      if(!TrendUp_prev && TrendUp) SignUp[bar]=low[bar]-ATR[bar]*3/8;
      if(!TrendDown_prev && TrendDown) SignDown[bar]=high[bar]+ATR[bar]*3/8;
      
      if(bar)
        {
         TrendUp_prev=TrendUp;
         TrendDown_prev=TrendDown;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| AverageHigh                                                      |
//+------------------------------------------------------------------+
double AverageHigh(const double &High[],const datetime &Time[],int index)
  {
//----
   double hhv;
   double ret= 0.0;
   int nbars = index;
   int max=int(iPeriod+iFullPeriods);
   boolp1=false;
   for(int iii=0; iii<max; iii++)
     {
      while(!isDelimeter(Period(),Time,nbars)) nbars++;
      if(!boolp1) boolp1=nbars;
      arr[iii]=nbars;
      nbars++;
     }

   for(int count=int(iPeriod-1); count>0; count--)
     {
      hhv=High[ArrayMaximum(High,arr[count-1]+1,arr[count]-arr[count-1])];
      ret+=hhv;
     }
   if(iFullPeriods==1)
     {
      hhv=High[ArrayMaximum(High,arr[iPeriod-1]+1,arr[iPeriod]-arr[iPeriod-1])];
      ret += hhv;
      ret /= NormalizeDouble(iPeriod, 0);
     }
   else
     {
      hhv=High[ArrayMaximum(High,index,arr[0]-index)];
      ret += hhv;
      ret /= NormalizeDouble(iPeriod, 0);
     }
//----
   return (ret);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double AverageLow(const double &Low[],const datetime &Time[],int index)
  {
//----
   double llv;
   double ret= 0.0;
   int nbars = index;
   int max=int(iPeriod+iFullPeriods);
   boolp1=false;
   for(int iii=0; iii<max; iii++)
     {
      while(!isDelimeter(Period(),Time,nbars)) nbars++;
      if(!boolp1) boolp1=nbars;
      arr[iii]=nbars;
      nbars++;
     }
   for(int count=int(iPeriod-1); count>0; count--)
     {
      llv=Low[ArrayMinimum(Low,arr[count-1]+1,arr[count]-arr[count-1])];
      ret+=llv;
     }
   if(iFullPeriods==1)
     {
      llv=Low[ArrayMinimum(Low,arr[iPeriod-1]+1,arr[iPeriod]-arr[iPeriod-1])];
      ret += llv;
      ret /= NormalizeDouble(iPeriod, 0);
     }
   else
     {
      llv=Low[ArrayMinimum(Low,index,arr[0]-index)];
      ret += llv;
      ret /= NormalizeDouble(iPeriod, 0);
     }
//----
   return (ret);
  }
//+------------------------------------------------------------------+
//| isDelimeter()                                                    |
//+------------------------------------------------------------------+
bool isDelimeter(ENUM_TIMEFRAMES TimFrame,const datetime &Time[],int index)
  {
//----
   MqlDateTime tm;
   TimeToStruct(Time[index],tm);
   bool blper=false;
   switch(TimFrame)
     {
      case PERIOD_M1: blper=tm.min==0; break;
      case PERIOD_M2: blper=tm.min==0; break;
      case PERIOD_M3: blper=tm.min==0; break;
      case PERIOD_M4: blper=tm.min==0; break;
      case PERIOD_M5: blper=tm.min==0; break;
      case PERIOD_M6: blper=tm.min==0; break;
      case PERIOD_M10: blper=tm.min==0; break;
      case PERIOD_M12: blper=tm.min==0; break;
      case PERIOD_M15: blper=tm.min==0; break;
      case PERIOD_M20: blper=tm.min==0; break;
      case PERIOD_M30: blper=tm.min==0 && MathMod(tm.hour,4.0)==0.0; break;
      case PERIOD_H1: blper=tm.min==0 && MathMod(tm.hour,4.0)==0.0; break;
      case PERIOD_H2: blper=tm.min==0 && MathMod(tm.hour,4.0)==0.0; break;
      case PERIOD_H3: blper=tm.min==0 && MathMod(tm.hour,4.0)==0.0; break;
      case PERIOD_H4: blper=tm.min==0 && tm.hour==0; break;
      case PERIOD_H6: blper=tm.min==0 && tm.hour==0; break;
      case PERIOD_H8: blper=tm.min==0 && tm.hour==0; break;
      case PERIOD_H12: blper=tm.min==0 && tm.hour==0; break;
      case PERIOD_D1: blper=tm.day_of_week==1 && tm.hour==0; break;
      case PERIOD_W1:
        {
         MqlDateTime tm2;
         TimeToStruct(Time[index+1],tm2);
         blper=tm.day==1 || (tm.day==2 && tm2.day!=1) || (tm.day==3 && tm2.day!=2);
         break;
        }
      case PERIOD_MN1:
        {
         MqlDateTime tm2;
         TimeToStruct(Time[index+1],tm2);
         blper=tm.day==1 || (tm.day==2 && tm2.day!=1) || (tm.day==3 && tm2.day!=2);
         break;
        }
     }
//----
   return (blper);
  }
//+------------------------------------------------------------------+
