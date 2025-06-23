//+------------------------------------------------------------------+
//|                                                      WaveMTF.mq5 |
//|                           Copyright 2020, Roberto Jacobs (3rjfx) |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, Roberto Jacobs (3rjfx) ~ By 3rjfx ~ Created: 2020/06/10"
#property link        "https://www.mql5.com/en/users/3rjfx"
#property version     "2.00"
#property strict
#property description "Indicator WaveMTF Bull and Bear System with Signal and Alert"
#property description "for MetaTrader 5 with options to display signal on the chart."
#property description "version: 2.00 ~ Last update 27/08/2020"
/*
Update version 2.00
  ~ Fix buffers error
*/
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_NONE
#property indicator_type2   DRAW_NONE
//--
//--
enum YN
 {
   No,
   Yes
 };
//--
enum corner
 {  
   NotShow=-1,     // Not Show Arrow
   topchart=0,     // On Top Chart
   bottomchart=1   // On Bottom Chart
 };
//--
enum StrTF
 {
   M1,  // TF-M1
   M5,  // TF-M5
   M15, // TF-M15
   M30, // TF-M30
   H1,  // TF-H1
   H4,  // TF-H4
   D1,  // TF-D1
   W1,  // TF-W1
   MN   // TF-MN
 };
//--
//--
input StrTF                  stf = M5;         // Time Frames Calculation Signal Starts
input StrTF                  etf = D1;         // Last Time Frames Calculation Signal
input corner                 cor = topchart;   // Arrow Move Position
input YN                  alerts = Yes;        // Display Alerts / Messages (Yes) or (No)
input YN              EmailAlert = No;         // Email Alert (Yes) or (No)
input YN              sendnotify = No;         // Send Notification (Yes) or (No)
input YN             displayinfo = Yes;        // Display Trade Info
input color            textcolor = clrSnow;    // Text Color
input color              ArrowUp = clrLime;    // Arrow Up Color
input color              ArrowDn = clrRed;     // Arrow Down Color
input color              NTArrow = clrYellow;  // Arrow No Signal
//---
//---- indicator buffers
double BufferUp[];
double BufferDn[];
//--
//--- spacing
int scaleX=35,scaleY=40,scaleYt=18,offsetX=250,offsetY=3,fontSize=7; // coordinate
int txttf,
    arrtf;
color arclr;
ENUM_BASE_CORNER bcor;
//--- arrays for various things
ENUM_TIMEFRAMES BBTF[]={PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
int XBB[10];
string periodStr[]={"M1","M5","M15","M30","H1","H4","D1","W1","MN","MOVE"}; // Text Timeframes
//--
double 
   pricepos;
datetime 
   cbartime;
int cur,prv;
int imnn,imnp;
int cmnt,pmnt;
int arr;
long CI;
static int fbar;
string posisi,
       sigpos,
       iname,
       msgText;
string frtext="wave";
#define MAX_BAR 120
//---------//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
    SetIndexBuffer(0,BufferUp,INDICATOR_DATA);
    PlotIndexSetString(0,PLOT_LABEL,"Bullish");
    PlotIndexSetInteger(0,PLOT_SHOW_DATA,true);
    //--
    SetIndexBuffer(1,BufferDn,INDICATOR_DATA);
    PlotIndexSetString(1,PLOT_LABEL,"Bearish");
    PlotIndexSetInteger(1,PLOT_SHOW_DATA,true);
    //--
    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
    PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
    //--
//---- indicator short name
    iname="WaveMTF";
    IndicatorSetString(INDICATOR_SHORTNAME,iname+"_("+Symbol()+")");
    IndicatorSetInteger(INDICATOR_DIGITS,Digits());
    //--
    CI=ChartID();
    arr=ArraySize(XBB);
    //--
    if(cor>=0)
      {
        if(cor==topchart) {bcor=CORNER_LEFT_UPPER; txttf=45; arrtf=-20;}
        if(cor==bottomchart) {bcor=CORNER_LEFT_LOWER; txttf=45; arrtf=-12;}
      }
    else
     {
       string name;
       for(int i=ObjectsTotal(CI,0,-1)-1; i>=0; i--)
         {
           name=ObjectName(CI,i,0,-1);
           if(StringFind(name,frtext,0)>-1) ObjectDelete(CI,name);
         }
     }
   //--
//---
   return(INIT_SUCCEEDED);
  }
//---------//
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//----
    Comment("");
    string name;
    for(int i=ObjectsTotal(CI,0,-1)-1; i>=0; i--)
      {
        name=ObjectName(CI,i,0,-1);
        if(StringFind(name,frtext,0)>-1) ObjectDelete(CI,name);
      }
    //--
//----
   return;
  }
//---------//
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
//---
//--- Set Last error value to Zero
    ResetLastError();
//---
    int limit=0,barc;
//--- check for rates total
    if(rates_total>MAX_BAR) limit=MAX_BAR;
    barc=limit-1;
    //--
    ArrayResize(BufferUp,limit);
    ArrayResize(BufferDn,limit);
    ArraySetAsSeries(open,true);
    ArraySetAsSeries(high,true);
    ArraySetAsSeries(low,true);
    ArraySetAsSeries(close,true);
    ArraySetAsSeries(time,true);
    ArraySetAsSeries(BufferUp,true);
    ArraySetAsSeries(BufferDn,true);
    //--
    int tfcnt=etf-stf;
    arclr=NTArrow;
    //--
    imnn=Seconds();
    if(imnn!=imnp)
      {
        for(int w=barc; w>=0; w--)
          {
            int tr=0,xbup=0,xbdn=0,i;
            cbartime=time[w];
            if(cor>=0)
              {
                for(int x=0; x<arr; x++)
                  {
                    CreateArrowLabel(CI,frtext+"_tfx_arrow_"+string(x),periodStr[x],"Bodoni MT Black",fontSize,textcolor,bcor,
                                     txttf+x*scaleX+offsetX,scaleY+offsetY+7,true); //"Georgia" "Bodoni MT Black" "Verdana" "Arial Black"
                  }
              }
            //--
            for(i=0; i<arr-1; i++)
              {
                XBB[i]=GetDirection(BBTF[i],w);
                if(cor>=0)
                  {
                    if(XBB[i]>0) arclr=ArrowUp;
                    if(XBB[i]<0) arclr=ArrowDn;
                    CreateArrowLabel(CI,frtext+"_win_arrow_"+string(i),CharToString(108),"Wingdings",14,arclr,bcor,
                                     txttf+i*scaleX+offsetX,arrtf+scaleY+offsetY+7,true);
                  }
                if(i>=stf && i<=etf)
                  {
                    if(XBB[i]>0) xbup++; 
                    if(XBB[i]<0) xbdn++;
                  }
              }
            if(i==9)
              {
                if(xbup>=tfcnt) 
                  {
                    tr=1;
                    XBB[i]=xbup; 
                    arclr=ArrowUp; 
                    BufferUp[w]=GetPrice(Period(),tr,w); 
                    pricepos=BufferUp[w]; 
                    BufferDn[w]=0.0;
                    cur=1;
                    fbar=iBarShift(Symbol(),Period(),cbartime,false);
                  }
                else
                if(xbdn>=tfcnt) 
                  {
                    tr=-1;
                    XBB[i]=xbdn; 
                    arclr=ArrowDn; 
                    BufferDn[w]=GetPrice(Period(),tr,w); 
                    pricepos=BufferDn[w]; 
                    BufferUp[w]=0.0;
                    cur=-1;
                    fbar=iBarShift(Symbol(),Period(),cbartime,false);
                  }
                else
                  {
                    XBB[i]=0; 
                    arclr=NTArrow; 
                    BufferDn[w]=0.0; 
                    BufferUp[w]=0.0; 
                    pricepos=close[w];
                    cur=0;
                    fbar=iBarShift(Symbol(),Period(),cbartime,false);
                  }
                //--
                if(cor>=0) CreateArrowLabel(CI,frtext+"_win_arrow_"+string(i),CharToString(108),"Wingdings",14,arclr,bcor,
                                            txttf+i*scaleX+offsetX+8,arrtf+scaleY+offsetY+7,true);
              }
          }
        //--
        imnp=imnn;
      }
    //--   
    if(alerts==Yes||EmailAlert==Yes||sendnotify==Yes) Do_Alerts(cur,fbar);
    if(displayinfo==Yes) ChartComm();
    //--
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//---------//

// getting the price direction
int GetDirection(ENUM_TIMEFRAMES xtf,int bar) 
  {
//---
    int ret=0;
    //--
    double ptpc1=(iHigh(Symbol(),xtf,bar+1)+iLow(Symbol(),xtf,bar+1)+iClose(Symbol(),xtf,bar+1))/3;
    double ptpc0=(iHigh(Symbol(),xtf,bar)+iLow(Symbol(),xtf,bar)+iClose(Symbol(),xtf,bar))/3;
    //--
    double mapw1=IMA(Symbol(),xtf,13,0,MODE_SMMA,PRICE_WEIGHTED,bar+1);
    double mapw0=IMA(Symbol(),xtf,13,0,MODE_SMMA,PRICE_WEIGHTED,bar);
    //--
    double bb1=ptpc1-mapw1;
    double bb0=ptpc0-mapw0;
    //--
    if(bb0>bb1) ret=1;
    if(bb0<bb1) ret=-1;
    //--
    return(ret);
//---
  }
//---------//

// getting the price position
double GetPrice(ENUM_TIMEFRAMES xtf,int bb,int bx)
  {
//---
    int bar=30;
    double ppos=0;
    //--
    int HH=iHighest(Symbol(),xtf,MODE_HIGH,bar,bx);
    int LL=iLowest(Symbol(),xtf,MODE_LOW,bar,bx);
    //--
    if(bb>0) {ppos=iLow(Symbol(),xtf,LL); cbartime=iTime(Symbol(),xtf,LL);}
    if(bb<0) {ppos=iHigh(Symbol(),xtf,HH); cbartime=iTime(Symbol(),xtf,HH);}
    //--
    return(ppos);
//---
  }
//---------//

double IMA(string symbol,
           ENUM_TIMEFRAMES tf,
           int period,
           int ma_shift,
           ENUM_MA_METHOD method,
           ENUM_APPLIED_PRICE mprice,
           int shift)
  {
//---
    int handle=iMA(symbol,tf,period,ma_shift,method,mprice);
    double buf[];
    //--
    if(handle<0)
      {
        Print("The iMA object is not created: Error",GetLastError());
        return(-1);
      }
    else
      {
        CopyBuffer(handle,0,shift,1,buf);
      }
    return(buf[0]);
//---
  } //-end IMA()
//---------//

void Do_Alerts(int fcur,int fb)
  {
    //--
    cmnt=Minutes();
    if(cmnt!=pmnt)
      {
        //--
        if(fcur==1)
          {
            msgText="Wave Price Up Start"+" at bars: "+string(fb);
            posisi="Bullish"; 
            sigpos="Open BUY Order";
          }
        else
        if(fcur==-1)
          {
            msgText="Wave Price Down Start"+" at bars: "+string(fb);
            posisi="Bearish"; 
            sigpos="Open SELL Order";
          }
        else
          {
            msgText="Wave Price Not Found!";
            posisi="Not Found!"; 
            sigpos="Wait for Confirmation!";
          }
        //--
        if(fcur!=prv)
          {
            Print(iname,"--- "+Symbol()+" "+TF2Str(Period())+": "+msgText+
                  "\n--- at: ",TimeToString(iTime(Symbol(),0,0),TIME_DATE|TIME_MINUTES)+" - "+sigpos);
            //--
            if(alerts==Yes)
              Alert(iname,"--- "+Symbol()+" "+TF2Str(Period())+": "+msgText+
                    "--- at: ",TimeToString(iTime(Symbol(),0,0),TIME_DATE|TIME_MINUTES)+" - "+sigpos);
            //--
            if(EmailAlert==Yes) 
              SendMail(iname,"--- "+Symbol()+" "+TF2Str(Period())+": "+msgText+
                               "\n--- at: "+TimeToString(iTime(Symbol(),0,0),TIME_DATE|TIME_MINUTES)+" - "+sigpos);
            //--
            if(sendnotify==Yes) 
              SendNotification(iname+"--- "+Symbol()+" "+TF2Str(Period())+": "+msgText+
                               "\n--- at: "+TimeToString(iTime(Symbol(),0,0),TIME_DATE|TIME_MINUTES)+" - "+sigpos);                
            //--
            prv=fcur;
          }
        //--
        pmnt=cmnt;
      }
    //--
    return;
    //---
  }
//---------//

string TF2Str(int period)
  {
   switch(period)
     {
       //--
       case PERIOD_M1: return("M1");
       case PERIOD_M5: return("M5");
       case PERIOD_M15: return("M15");
       case PERIOD_M30: return("M30");
       case PERIOD_H1: return("H1");
       case PERIOD_H4: return("H4");
       case PERIOD_D1: return("D1");
       case PERIOD_W1: return("W1");
       case PERIOD_MN1: return("MN");
       //--
     }
   return(string(period));
  }  
//---------//

string AccountMode() // function: to known account trade mode
   {
//----
//--- Demo, Contest or Real account 
   ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
 //---
   string trade_mode;
   //--
   switch(account_type) 
     { 
      case  ACCOUNT_TRADE_MODE_DEMO: 
         trade_mode="Demo"; 
         break; 
      case  ACCOUNT_TRADE_MODE_CONTEST: 
         trade_mode="Contest"; 
         break; 
      default: 
         trade_mode="Real"; 
         break; 
     }
   //--
   return(trade_mode);
//----
   } //-end AccountMode()
//---------//

void ChartComm() // function: write comments on the chart
  {
//----
   //--
   Comment("\n     :: Server Date Time : ",(string)Year(),".",(string)Month(),".",(string)Day(), "   ",TimeToString(TimeCurrent(),TIME_SECONDS), 
      "\n     ------------------------------------------------------------", 
      "\n      :: Broker             :  ",TerminalInfoString(TERMINAL_COMPANY), 
      "\n      :: Acc. Name       :  ",AccountInfoString(ACCOUNT_NAME),
      "\n      :: Acc, Number    :  ",(string)AccountInfoInteger(ACCOUNT_LOGIN),
      "\n      :: Acc,TradeMode :  ",AccountMode(),
      "\n      :: Acc. Leverage   :  1 : ",(string)AccountInfoInteger(ACCOUNT_LEVERAGE), 
      "\n      :: Acc. Balance     :  ",DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2),
      "\n      :: Acc. Equity       :  ",DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2), 
      "\n      --------------------------------------------",
      "\n      :: Indicator Name  :  ",iname,
      "\n      :: Currency Pair    :  ",Symbol(),
      "\n      :: Current Spread  :  ",IntegerToString(SymbolInfoInteger(Symbol(),SYMBOL_SPREAD),0),
      "\n      :: Signal Start       : at bar ",string(iBarShift(Symbol(),0,cbartime,false)),
      "\n      :: Wave Start       :  ",DoubleToString(pricepos,Digits()), 
      "\n      :: Indicator Signal :  ",posisi,
      "\n      :: Suggested        :  ",sigpos);
   //---
   ChartRedraw();
   return;
//----
  } //-end ChartComm()  
//---------//

bool CreateArrowLabel(long   chart_id, 
                      string lable_name, 
                      string label_text,
                      string font_model,
                      int    font_size,
                      color  label_color,
                      int    chart_corner,
                      int    x_cor, 
                      int    y_cor,
                      bool   price_hidden)
  { 
//--- 
    //--
    ObjectDelete(chart_id,lable_name);
    //--
    if(!ObjectCreate(chart_id,lable_name,OBJ_LABEL,0,0,0,0,0)) 
      { 
        //Print(__FUNCTION__, 
        //    ": failed to create \"Arrow Label\" sign! Error code = ",GetLastError());
        return(false); 
      } 
    //--
    ObjectSetString(chart_id,lable_name,OBJPROP_TEXT,label_text);
    ObjectSetString(chart_id,lable_name,OBJPROP_FONT,font_model); 
    ObjectSetInteger(chart_id,lable_name,OBJPROP_FONTSIZE,font_size);
    ObjectSetInteger(chart_id,lable_name,OBJPROP_COLOR,label_color);
    ObjectSetInteger(chart_id,lable_name,OBJPROP_CORNER,chart_corner);
    ObjectSetInteger(chart_id,lable_name,OBJPROP_XDISTANCE,x_cor);
    ObjectSetInteger(chart_id,lable_name,OBJPROP_YDISTANCE,y_cor);
    ObjectSetInteger(chart_id,lable_name,OBJPROP_HIDDEN,price_hidden);
    //--- successful execution 
    return(true);
    //--
  }
//---------// 

int Year(void)
  {
//---
    return(MqlReturnDateTime(TimeCurrent(),TimeReturn(year)));
//---
  } //-end Hours()
//---------//

int Month(void)
  {
//---
    return(MqlReturnDateTime(TimeCurrent(),TimeReturn(mon)));
//---
  } //-end Hours()
//---------//

int Day(void)
  {
//---
    return(MqlReturnDateTime(TimeCurrent(),TimeReturn(day)));
//---
  } //-end Hours()
//---------//

int Hours(void)
  {
//---
    return(MqlReturnDateTime(TimeCurrent(),TimeReturn(hour)));
//---
  } //-end Hours()
//---------//

int Minutes(void)
  {
//---
    return(MqlReturnDateTime(TimeCurrent(),TimeReturn(min)));
//---
  } //-end Minutes()
//---------//

int Seconds(void)
  {
//---
    return(MqlReturnDateTime(TimeCurrent(),TimeReturn(sec)));
//---
  } //-end Seconds()
//---------//

enum TimeReturn
  {
//---
    year        = 0,   // Year 
    mon         = 1,   // Month 
    day         = 2,   // Day 
    hour        = 3,   // Hour 
    min         = 4,   // Minutes 
    sec         = 5,   // Seconds 
    day_of_week = 6,   // Day of week (0-Sunday, 1-Monday, ... ,6-Saturday) 
    day_of_year = 7    // Day number of the year (January 1st is assigned the number value of zero) 
//---
  };
//---------//

int MqlReturnDateTime(datetime reqtime,
                      const int mode) 
  {
//---
    MqlDateTime mqltm;
    TimeToStruct(reqtime,mqltm);
    int valdate=0;
    //--
    switch(mode)
      {
        case 0: valdate=mqltm.year; break;        // Return Year 
        case 1: valdate=mqltm.mon;  break;        // Return Month 
        case 2: valdate=mqltm.day;  break;        // Return Day 
        case 3: valdate=mqltm.hour; break;        // Return Hour 
        case 4: valdate=mqltm.min;  break;        // Return Minutes 
        case 5: valdate=mqltm.sec;  break;        // Return Seconds 
        case 6: valdate=mqltm.day_of_week; break; // Return Day of week (0-Sunday, 1-Monday, ... ,6-Saturday) 
        case 7: valdate=mqltm.day_of_year; break; // Return Day number of the year (January 1st is assigned the number value of zero) 
      }
    return(valdate);
//---
  } //-end MqlReturnDateTime()
//---------//
//+------------------------------------------------------------------+