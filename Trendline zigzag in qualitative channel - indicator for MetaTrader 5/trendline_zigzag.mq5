//+------------------------------------------------------------------+
//|                                         Trendline Channel Zigzag |
//|                                            Copyright 2025, phade |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "phade"
#property link      "https://www.mql5.com"
#property description "Continuous trendlines from channel pivot to current extreme"
#property version   "1.02"

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots 6

#property indicator_label1  "Pivot Point A"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrDarkGray
#property indicator_width1  1
#property indicator_label2  "Pivot Point B"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDarkGray
#property indicator_width2  1
#property indicator_label3  "Middle"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDarkSlateGray
#property indicator_width3  1
#property indicator_label4  "High Shifts"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSilver
#property indicator_width4  1
#property indicator_label5  "Low Shifts"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrSilver
#property indicator_width5  1
#property indicator_label6 "Trendline Zigzag"
#property indicator_type6  DRAW_ZIGZAG
#property indicator_color6 clrLightGray
#property indicator_width6 1

input int iPeriods = 50;          // Channel Period
input int zigzag_depth = 30;       // Depth
input int min_swing_distance  = 5;  // Swing Deviation
input bool drawing_trendline = true; // Draw trend line
input bool pivot_correction = true; // Correct invalid pivots

// Buffers
double high_shifts[];
double low_shifts[];
double arr_buf_up[];
double arr_buf_down[];
double middle_band[];
double mid_trend_up[];
double mid_trend_down[];


double ZigzagStart[], ZigzagEnd[];

int state = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
  SetIndexBuffer(0, arr_buf_up, INDICATOR_DATA);
  SetIndexBuffer(1, arr_buf_down, INDICATOR_DATA);
  SetIndexBuffer(2, middle_band, INDICATOR_DATA);
  SetIndexBuffer(3, high_shifts, INDICATOR_DATA);
  SetIndexBuffer(4, low_shifts, INDICATOR_DATA);
  SetIndexBuffer(5, ZigzagStart, INDICATOR_DATA);
  SetIndexBuffer(6, ZigzagEnd, INDICATOR_DATA);

  PlotIndexSetInteger(0,PLOT_ARROW,33);
  PlotIndexSetInteger(1,PLOT_ARROW,33);
  PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,10);
  PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);


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
                const int &spread[])
  {

  int depth = zigzag_depth;

  int start = (prev_calculated == 0) ? iPeriods + 1 : prev_calculated - (depth + 1);

  static int lastUpIndex = -1;
  static int lastDownIndex = -1;

  static double lastSwingLow = -1;
  static double lastSwingHigh = -1;

  static double cur_highest;
  static double cur_lowest;

  // calculate the channel
  for(int i = start; i < rates_total; i++)
    {
    double highest = high[ArrayMaximum(high, i - iPeriods + 1, iPeriods)];
    double lowest = low[ArrayMinimum(low, i - iPeriods + 1, iPeriods)];

    high_shifts[i] = highest;
    low_shifts[i] = lowest;
    middle_band[i] = (highest + lowest) / 2.0;
    }

  // intialize buffers with empty values
  for(int i = rates_total - 1; i >= start; i--)
    {
    arr_buf_up[i] = EMPTY_VALUE;
    arr_buf_down[i] = EMPTY_VALUE;
    ZigzagStart[i] = EMPTY_VALUE;
    ZigzagEnd[i] = EMPTY_VALUE;
    }

  bool upwardsDir = false, downwardsDir = false;
  bool leg_search = true;


  for(int i = rates_total-1-(depth+1); i >= start; i--)
    {
    if(state != 1) // state could be 0 or 2
      {
      if(low_shifts[i-1] > low_shifts[i] && low_shifts[i] == low_shifts[i+depth+1])
        {
        lastUpIndex = i;
        double currentLow = low[lastUpIndex];
        upwardsDir = true;
        leg_search = false;
        state = 1;

        if(lastSwingLow < 0 || fabs(currentLow - lastSwingLow)/_Point > min_swing_distance)
          {
          arr_buf_up[i] = low_shifts[lastUpIndex];
          ZigzagStart[i] = currentLow;
          lastSwingLow = currentLow;
          }
        else
          {
          if(lastUpIndex >= 0)
            {
            for(int j = i; j > lastUpIndex; j--)
              {
              arr_buf_up[j] = EMPTY_VALUE;
              ZigzagStart[j] = EMPTY_VALUE;
              }
            }
          }
        }
      }
    else
      {
      leg_search = true;  // searching for swing high when state is 1 (or 0 on first run)
      }

    if(state != 2) // state could be 0 or 1
      {
      if(high_shifts[i-1] < high_shifts[i] && high_shifts[i] == high_shifts[i+depth+1])
        {
        lastDownIndex = i;
        double currentHigh = high[lastDownIndex];
        downwardsDir = true;
        leg_search = false;
        state = 2;

        if(lastSwingHigh < 0 || fabs(currentHigh - lastSwingHigh)/_Point > min_swing_distance)
          {
          arr_buf_down[i] = high_shifts[lastDownIndex];
          ZigzagEnd[i] = currentHigh;
          lastSwingHigh = currentHigh;
          }
        else
          {
          if(lastDownIndex >= 0)
            {
            for(int j = i; j > lastDownIndex; j--)
              {
              arr_buf_down[j] = EMPTY_VALUE;
              ZigzagEnd[j] = EMPTY_VALUE;
              }
            }
          }
        }
      }
    else
      {
      leg_search = true;   // searching for swing low when state is 2 (or on first run)
      }

    }

  // handle leg invalidation case
  if(pivot_correction)
    {
    for(int i = start; i<rates_total; i++)
      {
      if(state == 1)
        {
        if(lastSwingLow >= 0 && low[i] < lastSwingLow)
          {
          if(lastUpIndex >= 0)
            {

            for(int j=lastUpIndex; j<i; j++)
              {
              arr_buf_up[j] = EMPTY_VALUE;
              ZigzagStart[j] = EMPTY_VALUE;
              }

            state = 2; // change to low swing search
            }
          }
        }

      if(state == 2)
        {
        if(lastSwingHigh >= 0 && high[i] > lastSwingHigh)
          {
          if(lastDownIndex >= 0)
            {
            for(int j=lastDownIndex; j<i; j++)
              {
              arr_buf_down[j] = EMPTY_VALUE;
              ZigzagEnd[j] = EMPTY_VALUE;
              }

            state = 1; // change to high swing search
            }
          }
        }
      }
    }

  // calculate local highs and local lows for the dynamic trend line
  if(drawing_trendline)
    {
    for(int i = start; i<rates_total; i++)
      {
      cur_highest = high[ArrayMaximum(high, i - 10, 10)];
      cur_lowest = low[ArrayMinimum(low, i - 10, 10)];


      if(leg_search)
        {
        if(state == 1 && !downwardsDir)
          {
          ZigzagEnd[i] = cur_lowest;// connect unconfirmed upward leg to current low extreme
          ZigzagEnd[i-1] = EMPTY_VALUE;
          arr_buf_down[i-1] = EMPTY_VALUE;
          }
        if(state == 2 && !upwardsDir)
          {

          ZigzagStart[i] =  cur_highest; // connect unconfirmed downward leg to current high extreme
          ZigzagStart[i-1] = EMPTY_VALUE;
          arr_buf_up[i-1] = EMPTY_VALUE;
          }
        }
      }
    }


  return rates_total;
  }


//+------------------------------------------------------------------+
//|                         Cleanup
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  Comment("");
  }
//+------------------------------------------------------------------+
