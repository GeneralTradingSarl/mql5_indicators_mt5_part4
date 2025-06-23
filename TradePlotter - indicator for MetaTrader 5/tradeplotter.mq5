//+------------------------------------------------------------------+
//|                                                 TradePlotter.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
#property description "Agianto Simanullang"
#property indicator_chart_window
#property indicator_plots 0

input double HistoryInMonths = 3.00;

int count_current_ordes_flaq, count_history_orders_flaq;
string VariableIn[][8];
string VariableOut[][8];
/*
0. Ticket, 1. Symbol, 2. Order Type, 3. Time, 4. Price, 5. Profit, 6. Volume, 7. Position Id
*/

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() { OnDeinit(1); return (INIT_SUCCEEDED); }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
  {
   int i, count_current_ordes, count_history_orders;
   string obj_name = "", str_order_type;

// Curent orders
   count_current_ordes = PositionsTotal();
   if(count_current_ordes_flaq != count_current_ordes)
     {
      for(i = count_current_ordes - 1; i >= 0; i--)
        {
         if(PositionGetTicket(i) > 0)
           {
            if(PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_TYPE) <= 1)
              {
               str_order_type = PositionGetInteger(POSITION_TYPE) == ENUM_POSITION_TYPE(POSITION_TYPE_BUY) ? "buy" : "sell";
               obj_name = "#" + IntegerToString(PositionGetInteger(POSITION_TICKET)) + " " + str_order_type + " " + DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + " " + PositionGetString(POSITION_SYMBOL) + " at " + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), _Digits) + ", " + PositionGetString(POSITION_SYMBOL) + "";
               if(PositionGetInteger(POSITION_TYPE) == ENUM_POSITION_TYPE(POSITION_TYPE_BUY))
                 {
                  ObjectCreate(0, obj_name, OBJ_ARROW_BUY, 0, PositionGetInteger(POSITION_TIME), PositionGetDouble(POSITION_PRICE_OPEN));
                  ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrBlue);
                 }
               else
                 {
                  ObjectCreate(0, obj_name, OBJ_ARROW_SELL, 0, PositionGetInteger(POSITION_TIME), PositionGetDouble(POSITION_PRICE_OPEN));
                  ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrRed);
                 }
              }
           }
        }
      count_current_ordes_flaq = count_current_ordes;
      ChartRedraw(0);
     }

// History orders
   HistorySelect((datetime)(TimeCurrent() - PeriodSeconds(PERIOD_MN1) * HistoryInMonths), TimeCurrent());
   count_history_orders = HistoryDealsTotal();
   if(count_history_orders_flaq != count_history_orders)
     {
      ArrayFree(VariableIn);
      ArrayFree(VariableOut);
      ArrayResize(VariableIn, count_history_orders);
      ArrayResize(VariableOut, count_history_orders);
      obj_name = "";
      ulong ticket = 0;
      int x = 0, y = 0;
      for(i = count_history_orders - 1; i >= 0; i--)
        {
         ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
           {
            /*
            0. Ticket, 1. Symbol, 2. Order Type, 3. Time, 4. Price, 5. Profit, 6. Volume, 7. Position Id
            */
            if(HistoryDealGetString(ticket, DEAL_SYMBOL) == Symbol() && HistoryDealGetInteger(ticket, DEAL_TYPE) <= 1)
              {
               if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == ENUM_DEAL_ENTRY(DEAL_ENTRY_IN))
                 {
                  VariableIn[x][0] = IntegerToString(HistoryDealGetInteger(ticket, DEAL_TICKET));
                  VariableIn[x][1] = HistoryDealGetString(ticket, DEAL_SYMBOL);
                  VariableIn[x][2] = IntegerToString(HistoryDealGetInteger(ticket, DEAL_TYPE));
                  VariableIn[x][3] = TimeToString((datetime)HistoryDealGetInteger(ticket, DEAL_TIME), TIME_DATE | TIME_MINUTES);
                  VariableIn[x][4] = DoubleToString(HistoryDealGetDouble(ticket, DEAL_PRICE), _Digits);
                  VariableIn[x][5] = DoubleToString(HistoryDealGetDouble(ticket, DEAL_PROFIT), 2);
                  VariableIn[x][6] = DoubleToString(HistoryDealGetDouble(ticket, DEAL_VOLUME), 2);
                  VariableIn[x][7] = IntegerToString(HistoryDealGetInteger(ticket, DEAL_POSITION_ID));
                  x++;
                 }
               if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == ENUM_DEAL_ENTRY(DEAL_ENTRY_OUT))
                 {
                  VariableOut[y][0] = IntegerToString(HistoryDealGetInteger(ticket, DEAL_TICKET));
                  VariableOut[y][1] = HistoryDealGetString(ticket, DEAL_SYMBOL);
                  VariableOut[y][2] = IntegerToString(HistoryDealGetInteger(ticket, DEAL_TYPE));
                  VariableOut[y][3] = TimeToString((datetime)HistoryDealGetInteger(ticket, DEAL_TIME), TIME_DATE | TIME_MINUTES);
                  VariableOut[y][4] = DoubleToString(HistoryDealGetDouble(ticket, DEAL_PRICE), _Digits);
                  VariableOut[y][5] = DoubleToString(HistoryDealGetDouble(ticket, DEAL_PROFIT), 2);
                  VariableOut[y][6] = DoubleToString(HistoryDealGetDouble(ticket, DEAL_VOLUME), 2);
                  VariableOut[y][7] = IntegerToString(HistoryDealGetInteger(ticket, DEAL_POSITION_ID));
                  y++;
                 }
              }
           }
        }
      count_history_orders_flaq = count_history_orders;

      double profit_in = 0, profit_out = 0, price_in = 0, price_out = 0;
      double volume_in = 0, volume_out = 0;
      string symbol_in = "", symbol_out = "";
      ulong ticket_in = 0, ticket_out = 0;
      datetime time_in = 0, time_out = 0;
      ulong order_type_in = -1, order_type_out = -1;
      int j = 0;
      /*
      0. Ticket, 1. Symbol, 2. Order Type, 3. Time, 4. Price, 5. Profit, 6. Volume, 7. Position Id
      */
      for(i = 0; i < count_history_orders; i++)
        {
         if((ulong)VariableOut[i][0] == NULL || (ulong)VariableOut[i][0] == 0)
           {
            continue;
           }
         ticket_out = StringToInteger(VariableOut[i][0]);
         symbol_out = VariableOut[i][1];
         order_type_out = StringToInteger(VariableOut[i][2]);
         time_out = (datetime)VariableOut[i][3];
         price_out = StringToDouble(VariableOut[i][4]);
         profit_out = StringToDouble(VariableOut[i][5]);
         volume_out = StringToDouble(VariableOut[i][6]);
         obj_name = "#" + IntegerToString(ticket_out) + " " + (order_type_out == 0 ? "buy" : "sell") + " " + DoubleToString(volume_out, 2) + " " + symbol_out + " at " + DoubleToString(price_out, _Digits) + ", profit " + DoubleToString(profit_out, 2) + "";
         if(order_type_out == 0)
           {
            if(ObjectFind(0, obj_name) < 0)
              {
               ObjectCreate(0, obj_name, OBJ_ARROW_BUY, 0, time_out, price_out);
               ObjectSetInteger(0, obj_name, OBJPROP_COLOR, C'3,95,172');
              }
           }
         else
           {
            if(ObjectFind(0, obj_name) < 0)
              {
               ObjectCreate(0, obj_name, OBJ_ARROW_SELL, 0, time_out, price_out);
               ObjectSetInteger(0, obj_name, OBJPROP_COLOR, C'225,68,29');
              }
           }
        }

      for(j = 0; j < count_history_orders; j++)
        {
         if((ulong)VariableIn[j][0] == NULL || (ulong)VariableIn[j][0] == 0)
           {
            continue;
           }
         ticket_in = StringToInteger(VariableIn[j][0]);
         symbol_in = VariableIn[j][1];
         order_type_in = StringToInteger(VariableIn[j][2]);
         time_in = (datetime)VariableIn[j][3];
         price_in = StringToDouble(VariableIn[j][4]);
         profit_in = StringToDouble(VariableIn[j][5]);
         volume_in = StringToDouble(VariableIn[j][6]);
         obj_name = "#" + IntegerToString(ticket_in) + " " + (order_type_in == 0 ? "buy" : "sell") + " " + DoubleToString(volume_in, 2) + " " + symbol_in + " at " + DoubleToString(price_in, _Digits) + ", " + symbol_in + "";
         if(order_type_in == 0)
           {
            if(ObjectFind(0, obj_name) < 0)
              {
               ObjectCreate(0, obj_name, OBJ_ARROW_BUY, 0, time_in, price_in);
               ObjectSetInteger(0, obj_name, OBJPROP_COLOR, C'3,95,172');
              }
           }
         else
           {
            if(ObjectFind(0, obj_name) < 0)
              {
               ObjectCreate(0, obj_name, OBJ_ARROW_SELL, 0, time_in, price_in);
               ObjectSetInteger(0, obj_name, OBJPROP_COLOR, C'225,68,29');
              }
           }
        }
      /*
      0. Ticket, 1. Symbol, 2. Order Type, 3. Time, 4. Price, 5. Profit, 6. Volume, 7. Position Id
      */
      for(i = 0; i < count_history_orders; i++)
        {
         if((ulong)VariableOut[i][0] == NULL || (ulong)VariableOut[i][0] == 0)
           {
            continue;
           }
         for(j = 0; j < count_history_orders; j++)
           {
            if((ulong)VariableIn[j][0] == NULL || (ulong)VariableIn[j][0] == 0)
              {
               continue;
              }
            if(VariableOut[i][7] == VariableIn[j][7])
              {
               obj_name = "#" + VariableIn[j][0] + " -> #" + VariableOut[i][0] + ", profit " + DoubleToString((double)VariableOut[i][5], 2) + ", " + VariableOut[i][1];
               if(ObjectFind(0, obj_name) < 0)
                 {
                  ObjectCreate(0, obj_name, OBJ_TREND, 0, StringToTime(VariableIn[j][3]), StringToDouble(VariableIn[j][4]), StringToTime(VariableOut[i][3]), StringToDouble(VariableOut[i][4]));
                  ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_DOT);
                  ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 1);
                  ObjectSetInteger(0, obj_name, OBJPROP_RAY_RIGHT, false);
                  ObjectSetInteger(0, obj_name, OBJPROP_COLOR, StringToInteger(VariableIn[j][2]) == 0 ? C'3,95,172' : C'225,68,29');
                 }
              }
           }
        }

      ArrayFree(VariableIn);
      ArrayFree(VariableOut);
      ChartRedraw(0);
     }

   return (rates_total);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   int ObjTotal = ObjectsTotal(0);
   for(int i = ObjTotal; i >= 0; i--)
     {
      if(StringSubstr(ObjectName(0, i), 0, 2) == "#")
        {
         ObjectDelete(0, ObjectName(0, i));
        }
     }
  }
//+------------------------------------------------------------------+
