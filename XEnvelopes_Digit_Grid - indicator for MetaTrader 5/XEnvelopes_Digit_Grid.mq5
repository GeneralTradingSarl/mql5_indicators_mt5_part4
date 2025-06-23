//+---------------------------------------------------------------------+
//|                                           XEnvelopes_Digit_Grid.mq5 |
//|                                  Copyright © 2016, Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2016, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 4
#property indicator_buffers 4 
//---- использовано всего три графических построения
#property indicator_plots   3
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color1  clrLavender
//---- отображение метки индикатора
#property indicator_label1  "XEnvelopes Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки индикатора уровней      |
//+----------------------------------------------+
//---- отрисовка уровней в виде линий
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
//---- ввыбор цветов уровней
#property indicator_color2  clrLimeGreen
#property indicator_color3  clrDeepPink
//---- уровни - непрерывные кривые
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
//---- толщина уровней равна 2
#property indicator_width2  2
#property indicator_width3  2
//---- отображение меток уровней
#property indicator_label2  "Upper XEnvelopes"
#property indicator_label3  "Lower XEnvelopes"
//+----------------------------------------------+
//|  Описание класса CXMA                        |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA1;
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
enum Applied_price_      //Тип константы
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
//|  объявление перечислений                     |
//+----------------------------------------------+
/*enum SmoothMethod - перечисление объявлено в файле SmoothAlgorithms.mqh
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
//|  объявление перечислений                     |
//+----------------------------------------------+
enum WIDTH
  {
   Width_1=1, //1
   Width_2,   //2
   Width_3,   //3
   Width_4,   //4
   Width_5    //5
  };
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
enum STYLE
  {
   SOLID_,//Сплошная линия
   DASH_,//Штриховая линия
   DOT_,//Пунктирная линия
   DASHDOT_,//Штрих-пунктирная линия
   DASHDOTDOT_   //Штрих-пунктирная линия с двойными точками
  };
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input string  SirName="XEnvelopes_Digit_Grid";     //Первая часть имени графических объектов
input Smooth_Method XMA_Method=MODE_SMA_; //метод усреднения
input uint XLength=12;                    //глубина сглаживания                    
input int XPhase=15;                      //параметр сглаживания,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE_;    //ценовая константа
input double Deviation=0.1;               // Девиация
input uint Digit=2;                       //количество разрядов округления
input int Shift=0;                        //сдвиг индикатора по горизонтали в барах
input int PriceShift=0;                   //cдвиг индикатора по вертикали в пунктах
input bool ShowPrice=true;                //показывать ценовые метки
//---- цвета ценовых меток
input color  Upper_color=clrMediumSeaGreen;
input color  Lower_color=clrRed;
//---- Параметры ценовой сетки
input uint  Total=200;                       //количество блоков сетки сверху или снизу от цены
//----
input color  Color_A = clrSlateBlue;         //цвет уровня 1 
input STYLE  Style_A = DASHDOTDOT_;          //стиль линии уровня 1
input WIDTH  Width_A = Width_1;              //толщина линии уровня 1
//----
input color  Color_B = clrDarkOrange;        //цвет уровня 2
input STYLE  Style_B = DASH_;                //стиль линии уровня 2
input WIDTH  Width_B = Width_1;              //толщина линии уровня 2
//----
input color  Color_C = clrMagenta;           //цвет уровня 3
input STYLE  Style_C = SOLID_;               //стиль линии уровня 3
input WIDTH  Width_C = Width_1;              //толщина линии уровня 3
//----
input color  Color_D = clrRed;               //цвет уровня 4
input STYLE  Style_D = SOLID_;               //стиль линии уровня 4
input WIDTH  Width_D = Width_1;              //толщина линии уровня 4
//----
input color  Color_E = clrLime;              //цвет уровня 5
input STYLE  Style_E = SOLID_;               //стиль линии уровня 5
input WIDTH  Width_E = Width_1;              //толщина линии уровня 5
//----
input bool ShowLineInfo = true;              //отображение значения уровня на ценовом графике
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double UpBuffer[],DnBuffer[],UpLineBuffer[],DnLineBuffer[];
//---- Объявление переменных значения вертикального сдвига мувинга и коэффициентов девиации
double dPriceShift,UpKdev,DnKdev;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- Объявление стрингов для текстовых меток
string upper_name,lower_name;
//---- Объявление переменных ценовой сетки
color clr;
STYLE Style;
WIDTH Width;
bool ShowPriceLable;
int middle,sizex,Normalize,Count;
string ObjectNames[];
double PointPow10,PointPow100,PointPow1000,PointPow10000,PointPow100000,PriceGrid[],Price[];
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=XMA1.GetStartBars(XMA_Method,XLength,XPhase);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMALengthCheck("XLength",XLength);
   XMA1.XMAPhaseCheck("XPhase",XPhase,XMA_Method);
//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---- Инициализация коэффициента девиации  
   UpKdev=(1+Deviation/100.0);
   DnKdev=(1-Deviation/100.0);
   PointPow10=_Point*MathPow(10,Digit);
//---- Инициализация стрингов
   upper_name="XEnvelopes upper text lable";
   lower_name="XEnvelopes lower text lable";
//---- распределение памяти под массивы переменных ценовой сетки 
   sizex=int(Total*2);
   ArrayResize(ObjectNames,sizex);
   ArrayResize(PriceGrid,sizex);
   ArrayResize(Price,sizex);
//---- инициализация имён
   for(Count=0; Count<sizex; Count++) ObjectNames[Count]=SirName+" PriceLine "+string(Count);
//---- инициализация переменных         
   PointPow10=_Point*MathPow(10,Digit);
   PointPow100=PointPow10*10;
   PointPow1000=PointPow10*100;
   PointPow10000=PointPow10*1000;
   PointPow100000=PointPow10*10000;
   middle=(sizex/2)-1;
   Normalize=int(_Digits-Digit);
//---- инициализация переменных         
   for(Count=middle; Count<sizex; Count++) PriceGrid[Count]=+NormalizeDouble(PointPow10*(Count-middle),Normalize);
   for(Count=middle-1; Count>=0; Count--) PriceGrid[Count]=-NormalizeDouble(PointPow10*(middle-Count),Normalize);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(2,UpLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,DnLineBuffer,INDICATOR_DATA);
//---- установка позиции, с которой начинается отрисовка уровней
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"Env("+string(XLength)+")");
   PlotIndexSetString(0,PLOT_LABEL,"Env("+string(XLength)+")Cloud");
   PlotIndexSetString(1,PLOT_LABEL,"Env("+string(XLength)+")Upper");
   PlotIndexSetString(2,PLOT_LABEL,"Env("+string(XLength)+")Lower");

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,upper_name);
   ObjectDelete(0,lower_name);
   for(Count=0; Count<sizex; Count++) ObjectDelete(0,ObjectNames[Count]);
//----
   ChartRedraw(0);
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
//---- индексация элементов в массивах как в таймсериях
   ArraySetAsSeries(close,false);
   ArraySetAsSeries(time,false);

   double res=NormalizeDouble(PointPow10*MathCeil(close[rates_total-1]/PointPow10),Normalize);
   if(prev_calculated!=rates_total)
     {
      for(Count=0; Count<sizex; Count++) ObjectDelete(0,ObjectNames[Count]);
     }
   for(Count=0; Count<sizex; Count++) Price[Count]=NormalizeDouble(res+PriceGrid[Count],Normalize);
   datetime time0=time[rates_total-1]+PeriodSeconds()*Shift;
   datetime timeX=time[0];
   for(Count=0; Count<sizex; Count++)
     {
      string info="";
      if(ShowLineInfo) info=ObjectNames[Count]+" "+DoubleToString(Price[Count],Normalize);
      
      if(!NormalizeDouble(Price[Count]-PointPow100000*MathCeil(Price[Count]/PointPow100000),Normalize))
        {
         SetTline(0,ObjectNames[Count],0,timeX,Price[Count],time0,Price[Count],Color_E,Style_E,Width_E,info);
        }
      else if(!NormalizeDouble(Price[Count]-PointPow10000*MathCeil(Price[Count]/PointPow10000),Normalize))
        {
         SetTline(0,ObjectNames[Count],0,timeX,Price[Count],time0,Price[Count],Color_D,Style_D,Width_D,info);
        }
      else if(!NormalizeDouble(Price[Count]-PointPow1000*MathCeil(Price[Count]/PointPow1000),Normalize))
        {
         SetTline(0,ObjectNames[Count],0,timeX,Price[Count],time0,Price[Count],Color_C,Style_C,Width_C,info);
        }
      else  if(!NormalizeDouble(Price[Count]-PointPow100*MathCeil(Price[Count]/PointPow100),Normalize))
        {
         SetTline(0,ObjectNames[Count],0,timeX,Price[Count],time0,Price[Count],Color_B,Style_B,Width_B,info);
        }
      else
        {
         SetTline(0,ObjectNames[Count],0,timeX,Price[Count],time0,Price[Count],Color_A,Style_A,Width_A,info);
        }
     }

//---- индексация элементов в массивах не как в таймсериях
   ArraySetAsSeries(close,false);
   ArraySetAsSeries(time,false);

//---- Объявление переменных с плавающей точкой  
   double price,xma;
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
      UpBuffer[bar]=UpLineBuffer[bar]=PointPow10*MathCeil((UpKdev*xma)/PointPow10)+dPriceShift;
      DnBuffer[bar]=DnLineBuffer[bar]=PointPow10*MathFloor((DnKdev*xma)/PointPow10)+dPriceShift;
     }
   if(ShowPrice)
     {
      int bar0=rates_total-1;
      time0=time[bar0]+Shift*PeriodSeconds();
      SetRightPrice(0,upper_name,0,time0,UpBuffer[bar0],Upper_color);
      SetRightPrice(0,lower_name,0,time0,DnBuffer[bar0],Lower_color);
     }
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
                      color    Color              // Text color
                      )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW_RIGHT_PRICE,nwin,time,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
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
                   color    Color              // Text color
                   )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRightPrice(chart_id,name,nwin,time,price,Color);
   else ObjectMove(chart_id,name,0,time,price);
//----
  }
//+------------------------------------------------------------------+
//|  Создание трендовой линии                                        |
//+------------------------------------------------------------------+
void CreateTline(
                 long     chart_id,      // идентификатор графика
                 string   name,          // имя объекта
                 int      nwin,          // индекс окна
                 datetime time1,         // время 1 ценового уровня
                 double   price1,        // 1 ценовой уровень
                 datetime time2,         // время 2 ценового уровня
                 double   price2,        // 2 ценовой уровень
                 color    Color,         // цвет линии
                 int      style,         // стиль линии
                 int      width,         // толщина линии
                 string   text           // текст
                 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_TREND,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//----
  }
//+------------------------------------------------------------------+
//|  Переустановка трендовой линии                                   |
//+------------------------------------------------------------------+
void SetTline(
              long     chart_id,      // идентификатор графика
              string   name,          // имя объекта
              int      nwin,          // индекс окна
              datetime time1,         // время 1 ценового уровня
              double   price1,        // 1 ценовой уровень
              datetime time2,         // время 2 ценового уровня
              double   price2,        // 2 ценовой уровень
              color    Color,         // цвет линии
              int      style,         // стиль линии
              int      width,         // толщина линии
              string   text           // текст
              )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateTline(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
      ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
     }
//----
  }
//+------------------------------------------------------------------+
