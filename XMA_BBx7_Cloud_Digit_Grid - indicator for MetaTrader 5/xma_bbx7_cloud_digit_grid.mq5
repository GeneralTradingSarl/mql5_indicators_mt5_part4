//+---------------------------------------------------------------------+
//|                                       XMA_BBx7_Cloud_Digit_Grid.mq5 | 
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
#property version   "1.01"
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
#property indicator_color1  clrDeepSkyBlue
//---- отображение метки индикатора
#property indicator_label1  "Upper Sigma3 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type2   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color2  clrLime
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
//---- в качестве цвета линии индикатора использован сине-фиолетовый цвет
#property indicator_color4 clrBlueViolet
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
#property indicator_color5  clrMagenta
//---- отображение метки индикатора
#property indicator_label5  "Lower Sigma2 Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type6   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color6  clrMediumOrchid
//---- отображение метки индикатора
#property indicator_label6  "Lower Sigma3 Cloud"
//+--------------------------------------------+
//|  Описание классов усреднений               |
//+--------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+--------------------------------------------+
//---- объявление переменных классов CXMA и CStdDeviation из файла SmoothAlgorithms.mqh
CXMA XMA1;
CStdDeviation STD1,STD2,STD3;
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
//|  Объявление перечисления                   |
//+--------------------------------------------+  
enum WIDTH
  {
   Width_1=1, //1
   Width_2,   //2
   Width_3,   //3
   Width_4,   //4
   Width_5    //5
  };
//+--------------------------------------------+
//|  Объявление перечисления                   |
//+--------------------------------------------+
enum STYLE
  {
   SOLID_,//Сплошная линия
   DASH_,//Штриховая линия
   DOT_,//Пунктирная линия
   DASHDOT_,//Штрих-пунктирная линия
   DASHDOTDOT_   //Штрих-пунктирная линия с двойными точками
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
   MODE_AMA,   //AMA
  }; */
//+--------------------------------------------+
//|  Входные параметры индикатора              |
//+--------------------------------------------+
input string  SirName="XMA_BBx7_Cloud_Digit_Grid";     //Первая часть имени графических объектов
input Smooth_Method XMA_Method=MODE_SMA_; //метод усреднения
input uint XLength=100; //глубина  усреднения                    
input int XPhase=15; //параметр первого усреднения,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input double BandsDeviation1=2.0; //девиация 1
input double BandsDeviation2=3.0; //девиация 2
input double BandsDeviation3=4.0; //девиация 3
input uint Digit=2; //количество разрядов округления
input Applied_price_ IPC=PRICE_CLOSE_;//ценовая константа
input int Shift=0; // сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // cдвиг индикатора по вертикали в пунктах
input bool ShowPrice=true; //показывать ценовые метки
//---- цвета ценовых меток
input color  Middle_color=clrBlue;
input color  Upper_color1=clrMediumSeaGreen;
input color  Lower_color1=clrRed;
input color  Upper_color2=clrDodgerBlue;
input color  Lower_color2=clrMagenta;
input color  Upper_color3=clrBlue;
input color  Lower_color3=clrOrange;
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
input uint Fontsizex= 2;                     //размер ценовых меток
input bool ShowLineInfo = true;              //отображение значения уровня на ценовом графике
//+--------------------------------------------+
//---- объявление динамического массива, который будет в 
// дальнейшем использован в качестве индикаторного буфера
double ExtLineBuffer0[];
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов уровней Боллинджера
double UpBuffer1[],DnBuffer1[],UpBuffer2[],DnBuffer2[],UpBuffer3[],DnBuffer3[];
double UpBuffer4[],DnBuffer4[],UpBuffer5[],DnBuffer5[];
//---- Объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//---- Объявление целочисленных переменных начала отсчета данных
int min_rates_total,min_rates_1;
//---- Объявление строковых переменных для текстовых меток
string upper_name1,middle_name,lower_name1,upper_name2,lower_name2,upper_name3,lower_name3;
//---- Объявление переменных ценовой сетки
color clr;
STYLE Style;
WIDTH Width;
bool ShowPriceLable;
int middle,sizex,Normalize,Count;
string ObjectNames[];
double PointPow10,PointPow100,PointPow1000,PointPow10000,PointPow100000,PriceGrid[],Price[];
//+------------------------------------------------------------------+   
//| X2MA BBx5 indicator initialization function                      | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- Инициализация переменных начала отсчета данных
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
   if(BandsDeviation2>=BandsDeviation3)
     {
      Print("Входной параметр Девиация 3 всегда должен быть больше входного параметра Девиация 2! Исправьте значения этих входных параметров индикатора!");
      return(INIT_FAILED);
     }
//---- Инициализация строковых переменных
   upper_name1=SirName+" upper text lable 1";
   middle_name=SirName+" middle text lable";
   lower_name1=SirName+" lower text lable 1";
   upper_name2=SirName+" upper text lable 2";
   lower_name2=SirName+" lower text lable 2";
   upper_name3=SirName+" upper text lable 3";
   lower_name3=SirName+" lower text lable 3";
//---- распределение памяти под массивы переменных ценовой сетки 
   sizex=int(Total*2);
   ArrayResize(ObjectNames,sizex);
   ArrayResize(PriceGrid,sizex);
   ArrayResize(Price,sizex);
//---- инициализация имен
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
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);

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
   for(Count=0; Count<sizex; Count++) ObjectDelete(0,ObjectNames[Count]);
//----
   ChartRedraw(0);
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
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(0);
//---- индексация элементов в массивах как в таймсериях
   ArraySetAsSeries(close,false);
   ArraySetAsSeries(time,false);
//----
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
   double price,xma,line,stdev;
//---- Объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      first=0; // стартовый номер для расчета всех баров
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- Основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(IPC,bar,open,low,high,close);
      xma=XMA1.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,XLength,price,bar,false);
      line=xma+dPriceShift;
      ExtLineBuffer0[bar]=PointPow10*MathRound((xma+dPriceShift)/PointPow10);
      //---- расчет и округление Боллинджера 1
      stdev=STD1.StdDevSeries(min_rates_1,prev_calculated,rates_total,XLength,BandsDeviation1,price,xma,bar,false);
      UpBuffer1[bar]=DnBuffer2[bar]=PointPow10*MathCeil((line+stdev)/PointPow10);
      DnBuffer1[bar]=UpBuffer3[bar]=PointPow10*MathFloor((line-stdev)/PointPow10);
      //---- исправление Боллинджера 1
      if(ExtLineBuffer0[bar]>=UpBuffer1[bar]) UpBuffer1[bar]=DnBuffer2[bar]=ExtLineBuffer0[bar]+PointPow10;
      if(ExtLineBuffer0[bar]<=DnBuffer1[bar]) DnBuffer1[bar]=UpBuffer3[bar]=ExtLineBuffer0[bar]-PointPow10;
      //---- расчет и округление Боллинджера 2
      stdev=STD2.StdDevSeries(min_rates_1,prev_calculated,rates_total,XLength,BandsDeviation2,price,xma,bar,false);
      UpBuffer2[bar]=DnBuffer4[bar]=PointPow10*MathCeil((line+stdev)/PointPow10);
      DnBuffer3[bar]=UpBuffer5[bar]=PointPow10*MathFloor((line-stdev)/PointPow10);
      //---- исправление Боллинджера 2
      if(UpBuffer1[bar]>=UpBuffer2[bar]) UpBuffer2[bar]=DnBuffer4[bar]=UpBuffer1[bar]+PointPow10;
      if(DnBuffer1[bar]<=DnBuffer3[bar]) DnBuffer3[bar]=UpBuffer5[bar]=DnBuffer1[bar]-PointPow10;
      //---- расчет и округление Боллинджера 3        
      stdev=STD3.StdDevSeries(min_rates_1,prev_calculated,rates_total,XLength,BandsDeviation3,price,xma,bar,false);
      UpBuffer4[bar]=PointPow10*MathCeil((line+stdev)/PointPow10);
      DnBuffer5[bar]=PointPow10*MathFloor((line-stdev)/PointPow10);
      //---- исправление Боллинджера 3
      if(UpBuffer2[bar]>=UpBuffer4[bar]) UpBuffer4[bar]=UpBuffer2[bar]+PointPow10;
      if(DnBuffer3[bar]<=DnBuffer5[bar]) DnBuffer5[bar]=DnBuffer3[bar]-PointPow10;
     }
   if(ShowPrice)
     {
      int bar0=rates_total-1;
      time0=time[bar0]+Shift*PeriodSeconds();
      SetRightPrice(0,middle_name,0,time0,ExtLineBuffer0[bar0],Middle_color,"Georgia");
      SetRightPrice(0,upper_name1,0,time0,UpBuffer1[bar0],Upper_color1,"Georgia");
      SetRightPrice(0,lower_name1,0,time0,DnBuffer1[bar0],Lower_color1,"Georgia");
      SetRightPrice(0,upper_name2,0,time0,UpBuffer2[bar0],Upper_color2,"Georgia");
      SetRightPrice(0,lower_name2,0,time0,DnBuffer3[bar0],Lower_color2,"Georgia");
      SetRightPrice(0,upper_name3,0,time0,UpBuffer4[bar0],Upper_color3,"Georgia");
      SetRightPrice(0,lower_name3,0,time0,DnBuffer5[bar0],Lower_color3,"Georgia");
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