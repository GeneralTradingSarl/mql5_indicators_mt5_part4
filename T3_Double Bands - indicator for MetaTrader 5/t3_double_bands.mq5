//+------------------------------------------------------------------+
//|                                              T3 double bands.mq5 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"
#property version   "1.00"

//
//
//
//
//

#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   5

#property indicator_label1  "Upper bands"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  PowderBlue,MistyRose
#property indicator_label2  "Lower bands"
#property indicator_type2   DRAW_FILLING
#property indicator_color2  PowderBlue,MistyRose

#property indicator_label3  "High band"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  SteelBlue,PaleVioletRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label4  "Middle band"
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  SteelBlue,PaleVioletRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_label5  "Low band"
#property indicator_type5   DRAW_COLOR_LINE
#property indicator_color5  SteelBlue,PaleVioletRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

//
//
//
//
//

input int     T3Period        = 30;    // Calculation period
input double  T3Hot           = 0.7;   // T3 hot value
input bool    T3Original      = false; // T3 original Tillson calculation?
input bool    ShowLines       = true;  // Draw T3 lines?
input bool    MultiColorLines = true;  // Multi color mode for lines?
input bool    MultiColorBand  = true;  // Multi color mode for bands?

//
//
//
//
//
//

double UpFaBuffer[];
double UpFbBuffer[];
double DnFaBuffer[];
double DnFbBuffer[];
double UpBuffer[];
double UpColorBuffer[];
double MiBuffer[];
double MiColorBuffer[];
double DnBuffer[];
double DnColorBuffer[];
double trends[][5];
double c1,c2,c3,c4,t3Alpha;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer( 0,UpFaBuffer,INDICATOR_DATA);
   SetIndexBuffer( 1,UpFbBuffer,INDICATOR_DATA);
   SetIndexBuffer( 2,DnFaBuffer,INDICATOR_DATA);
   SetIndexBuffer( 3,DnFbBuffer,INDICATOR_DATA);
   SetIndexBuffer( 4,UpBuffer,INDICATOR_DATA);
   SetIndexBuffer( 5,UpColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 6,MiBuffer,INDICATOR_DATA);
   SetIndexBuffer( 7,MiColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 8,DnBuffer,INDICATOR_DATA);
   SetIndexBuffer( 9,DnColorBuffer,INDICATOR_COLOR_INDEX);

      if (ShowLines)
            for (int i=2; i<5; i++) PlotIndexSetInteger(i,PLOT_DRAW_TYPE,DRAW_COLOR_LINE);
      else  for (int i=2; i<5; i++) PlotIndexSetInteger(i,PLOT_DRAW_TYPE,DRAW_NONE);
      
   //
   //
   //
   //
   //
   
   double a  = MathMax(MathMin(T3Hot,1),0.0001);;
          c1 = -a*a*a;
          c2 =  3*(a*a+a*a*a);
          c3 = -3*(2*a*a+a+a*a*a);
          c4 = 1+3*a+a*a*a+3*a*a;
          double t3period  = T3Period; 
               if (!T3Original) t3period = 1.0 + (t3period-1.0)/2.0;
               t3Alpha = 2.0/(1.0 + t3period);
            
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{
   if (ArrayRange(trends,0)!=rates_total) ArrayResize(trends,rates_total);

   //
   //
   //
   //
   //
      
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
      {
         UpBuffer[i]   = calcT3( 0,High[i] ,i,rates_total);
         MiBuffer[i]   = calcT3( 6,Close[i],i,rates_total);
         DnBuffer[i]   = calcT3(12,Low[i]  ,i,rates_total);
         UpFaBuffer[i] = EMPTY_VALUE;
         UpFbBuffer[i] = EMPTY_VALUE;
         DnFaBuffer[i] = EMPTY_VALUE;
         DnFbBuffer[i] = EMPTY_VALUE;

         //
         //
         //
         //
         //
         
         if (i>0)
            {
               for (int k=0;k<5;k++) trends[i][k] = trends[i-1][k];

               if (UpBuffer[i]>UpBuffer[i-1])            trends[i][0] =  1;
               if (UpBuffer[i]<UpBuffer[i-1])            trends[i][0] = -1;
               if (MiBuffer[i]>MiBuffer[i-1])            trends[i][1] =  1;
               if (MiBuffer[i]<MiBuffer[i-1])            trends[i][1] = -1;
               if (DnBuffer[i]>DnBuffer[i-1])            trends[i][2] =  1;
               if (DnBuffer[i]<DnBuffer[i-1])            trends[i][2] = -1;
               if (trends[i][0]== 1 && trends[i][1]== 1) trends[i][3] =  1;
               if (trends[i][0]==-1 && trends[i][1]==-1) trends[i][3] = -1;
               if (trends[i][2]== 1 && trends[i][1]== 1) trends[i][4] =  1;
               if (trends[i][2]==-1 && trends[i][1]==-1) trends[i][4] = -1;
            }
         else  for (int k=0;k<5;k++) trends[i][k] = 0;
            
         //
         //
         //
         //
         //
                     
         UpColorBuffer[i] = MultiColorLines && trends[i][0]==-1 ? 1 : 0;
         MiColorBuffer[i] = MultiColorLines && trends[i][1]==-1 ? 1 : 0;
         DnColorBuffer[i] = MultiColorLines && trends[i][2]==-1 ? 1 : 0;
         if (MultiColorBand)
            {
               if (trends[i][3] ==-1)
                     { UpFaBuffer[i] = MiBuffer[i]; UpFbBuffer[i] = UpBuffer[i]; }                  
               else  { UpFbBuffer[i] = MiBuffer[i]; UpFaBuffer[i] = UpBuffer[i]; }                  
               if (trends[i][4] ==-1)
                     { DnFaBuffer[i] = DnBuffer[i]; DnFbBuffer[i] = MiBuffer[i]; }                  
               else  { DnFbBuffer[i] = DnBuffer[i]; DnFaBuffer[i] = MiBuffer[i]; }                  
           }
      }
   
   //
   //
   //
   //
   //
   
   return(rates_total);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double t3Values[][18];
double calcT3(int s, double price, int r, int bars)
{
   if (ArrayRange(t3Values,0)!=bars) ArrayResize(t3Values,bars);
      
   //
   //
   //
   //
   //
   //

   if (r < 2)
      {
         t3Values[r][s+0] = price;
         t3Values[r][s+1] = price;
         t3Values[r][s+2] = price;
         t3Values[r][s+3] = price;
         t3Values[r][s+4] = price;
         t3Values[r][s+5] = price;
      }
   else
      {
         t3Values[r][s+0] = t3Values[r-1][s+0]+t3Alpha*(price           -t3Values[r-1][s+0]);
         t3Values[r][s+1] = t3Values[r-1][s+1]+t3Alpha*(t3Values[r][s+0]-t3Values[r-1][s+1]);
         t3Values[r][s+2] = t3Values[r-1][s+2]+t3Alpha*(t3Values[r][s+1]-t3Values[r-1][s+2]);
         t3Values[r][s+3] = t3Values[r-1][s+3]+t3Alpha*(t3Values[r][s+2]-t3Values[r-1][s+3]);
         t3Values[r][s+4] = t3Values[r-1][s+4]+t3Alpha*(t3Values[r][s+3]-t3Values[r-1][s+4]);
         t3Values[r][s+5] = t3Values[r-1][s+5]+t3Alpha*(t3Values[r][s+4]-t3Values[r-1][s+5]);
      }
   return(c1*t3Values[r][s+5] + c2*t3Values[r][s+4] + c3*t3Values[r][s+3] + c4*t3Values[r][s+2]);
}