//+------------------------------------------------------------------+
//|                                                     ZZ_Alert.mq5 |
//|                                       Copyright 2021, Dark Ryd3r |
//|                                           https://t.me/DarkRyd3r |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Dark Ryd3r"
#property link      "https://t.me/DarkRyd3r"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_ZIGZAG
#property indicator_label1  "ZigZag_NK"
#property indicator_color1  clrMagenta,clrAliceBlue
#property indicator_style1  STYLE_DASH
#property indicator_width1  1

enum ENUM_SOUNDS {
   alert       = 0,  // alert
   alert2      = 1,  // alert2
   connect     = 2,  // connect
   disconnect  = 3,  // disconnect
   email       = 4,  // email
   expert      = 5,  // expert
   news        = 6,  // news
   ok          = 7,  // ok
   request     = 8,  // request
   stops       = 9,  // stops
   tick        = 10, // tick
   timeout     = 11, // timeout
   wait        = 12, // wait
};

input ENUM_SOUNDS sound=alert2; // Choose Sound
input bool _sound = true; // Play Sound?
input bool _alert = true; // Show Alerts?
input bool        notification=false;  // Send Push Notificatoin?
string filename="";
input string InpText = "ZZ Bar Changed "; // Enter Alert Text
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

//--- indicator buffers mapping
input int ExtDepth=12;
input int ExtDeviation=5;
input int ExtBackstep =3;

int bar1,bar2,sign;
double price1,price2;

//---- declaration of dynamic arrays that
// will be used as indicator buffers
double HighestBuffer[];
double LowestBuffer[];

//---- declaration of memory variables for recalculation of the indiator only at the previously not calculated bars
int LASTlowpos,LASThighpos;
double LASTlow0,LASTlow1,LASThigh0,LASThigh1;

//---- Declaration of the integer variables for the start of data calculation
int StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   switch(sound) {
   case 0:
      filename="alert.wav";
      break;
   case 1:
      filename="alert2.wav";
      break;
   case 2:
      filename="connect .wav";
      break;
   case 3:
      filename="disconnect.wav";
      break;
   case 4:
      filename="email.wav";
      break;
   case 5:
      filename="expert.wav";
      break;
   case 6:
      filename="news.wav";
      break;
   case 7:
      filename="ok.wav";
      break;
   case 8:
      filename="request.wav";
      break;
   case 9:
      filename="stops.wav";
      break;
   case 10:
      filename="tick.wav";
      break;
   case 11:
      filename="timeout.wav";
      break;
   case 12:
      filename="wait.wav";
      break;
   }
   StartBars=ExtDepth+ExtBackstep;

   SetIndexBuffer(0,LowestBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighestBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetString(0,PLOT_LABEL,"ZigZag Lowest");
   PlotIndexSetString(1,PLOT_LABEL,"ZigZag Highest");
   ArraySetAsSeries(LowestBuffer,true);
   ArraySetAsSeries(HighestBuffer,true);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   string shortname;
   StringConcatenate(shortname,"ZZ_Alert (ExtDepth=",
                     ExtDepth,"ExtDeviation = ",ExtDeviation,"ExtBackstep = ",ExtBackstep,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//----
//---
   return(INIT_SUCCEEDED);
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
                const int &spread[]) {
//---
   //---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBars) return(0);

//---- declarations of local variables
   int limit,bar,back,lasthighpos,lastlowpos;
   double curlow,curhigh,lasthigh0=0.0,lastlow0=0.0,lasthigh1,lastlow1,val,res;

//---- calculate the limit starting number for loop of bars recalculation and start initialization of variables
   if(prev_calculated>rates_total || prev_calculated<=0) { // checking for the first start of the indicator calculation
      limit=rates_total-StartBars; // starting index for calculation of all bars

      lastlow1=-1;
      lasthigh1=-1;
      lastlowpos=-1;
      lasthighpos=-1;
   } else {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars

      //---- restore values of the variables
      lastlow0=LASTlow0;
      lasthigh0=LASThigh0;

      lastlow1=LASTlow1;
      lasthigh1=LASThigh1;

      lastlowpos=LASTlowpos+limit;
      lasthighpos=LASThighpos+limit;
   }

//---- indexing elements in arrays as timeseries
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- first big indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--) {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0) {
         LASTlow0=lastlow0;
         LASThigh0=lasthigh0;
      }

      //---- low
      val=low[ArrayMinimum(low,bar,ExtDepth)];
      if(val==lastlow0) val=0.0;
      else {
         lastlow0=val;
         if((low[bar]-val)>(ExtDeviation*_Point))val=0.0;
         else {
            for(back=1; back<=ExtBackstep; back++) {
               res=LowestBuffer[bar+back];
               if((res!=0) && (res>val))LowestBuffer[bar+back]=0.0;
            }
         }
      }
      LowestBuffer[bar]=val;

      //---- high
      val=high[ArrayMaximum(high,bar,ExtDepth)];
      if(val==lasthigh0) val=0.0;
      else {
         lasthigh0=val;
         if((val-high[bar])>(ExtDeviation*_Point))val=0.0;
         else {
            for(back=1; back<=ExtBackstep; back++) {
               res=HighestBuffer[bar+back];
               if((res!=0) && (res<val))HighestBuffer[bar+back]=0.0;
            }
         }
      }
      HighestBuffer[bar]=val;

   }

//---- the second big indicator calculation loop
   for(bar=limit; bar>=0; bar--) {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0) {
         LASTlow1=lastlow1;
         LASThigh1=lasthigh1;

         LASTlowpos=lastlowpos;
         LASThighpos=lasthighpos;
      }

      curlow=LowestBuffer[bar];
      curhigh=HighestBuffer[bar];
      //----
      if((curlow==0) && (curhigh==0))continue;
      //----
      if(curhigh!=0) {
         if(lasthigh1>0) {
            if(lasthigh1<curhigh)HighestBuffer[lasthighpos]=0;
            else HighestBuffer[bar]=0;
         }
         //----
         if(lasthigh1<curhigh || lasthigh1<0) {
            lasthigh1=curhigh;
            lasthighpos=bar;
         }
         lastlow1=-1;
      }
      //----
      if(curlow!=0) {
         if(lastlow1>0) {
            if(lastlow1>curlow) LowestBuffer[lastlowpos]=0;
            else LowestBuffer[bar]=0;
         }
         //----
         if((curlow<lastlow1) || (lastlow1<0)) {
            lastlow1=curlow;
            lastlowpos=bar;
         }
         lasthigh1=-1;
      }
   }
   bar1=FindFirstExtremum(0,rates_total,HighestBuffer,LowestBuffer,sign,price1);
   bar2=FindSecondExtremum(sign,bar1,rates_total,HighestBuffer,LowestBuffer,sign,price2);

   string now = TimeToString(TimeLocal(),TIME_SECONDS);


   static double _price2=price2;
   if(price2!=_price2) {
      if(_sound)
         PlaySound(filename);
         
         if(_alert)
         Alert(InpText);

      if(notification) {
         string text = _Symbol + ": " +  InpText + " at " + now;
         SendNotification(text);
      }
      _price2 = price2;
   }

//--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Searching for the very first ZigZag high in time series buffers  |
//+------------------------------------------------------------------+
int FindFirstExtremum(int StartPos,int Rates_total,double &UpArray[],double &DnArray[],int &Sign,double &Extremum) {
//----
   if(StartPos>=Rates_total)StartPos=Rates_total-1;

   for(int bar=StartPos; bar<Rates_total; bar++) {
      if(UpArray[bar]!=0.0 && UpArray[bar]!=EMPTY_VALUE) {
         Sign=+1;
         Extremum=UpArray[bar];
         return(bar);
         break;
      }

      if(DnArray[bar]!=0.0 && DnArray[bar]!=EMPTY_VALUE) {
         Sign=-1;
         Extremum=DnArray[bar];
         return(bar);
         break;
      }
   }
//----
   return(-1);
}
//+------------------------------------------------------------------+
//| Searching for the second ZigZag high in time series buffers      |
//+------------------------------------------------------------------+
int FindSecondExtremum(int Direct,int StartPos,int Rates_total,double &UpArray[],double &DnArray[],int &Sign,double &Extremum) {
//----
   if(StartPos>=Rates_total)StartPos=Rates_total-1;

   if(Direct==-1)
      for(int bar=StartPos; bar<Rates_total; bar++) {
         if(UpArray[bar]!=0.0 && UpArray[bar]!=EMPTY_VALUE) {
            Sign=+1;
            Extremum=UpArray[bar];
            return(bar);
            break;
         }

      }

   if(Direct==+1)
      for(int bar=StartPos; bar<Rates_total; bar++) {
         if(DnArray[bar]!=0.0 && DnArray[bar]!=EMPTY_VALUE) {
            Sign=-1;
            Extremum=DnArray[bar];
            return(bar);
            break;
         }
      }
//----
   return(-1);
}
//+------------------------------------------------------------------+
