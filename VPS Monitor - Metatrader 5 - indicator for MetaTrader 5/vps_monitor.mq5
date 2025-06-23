//+------------------------------------------------------------------+
//|                                                  VPS Monitor.mq5 |
//|                                                 Stefanus Wardoyo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Stefanus Wardoyo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//--- input parameters
input bool     SendEmail=false; // Send Email
input bool     SendNotif=true; // Send Notification
input int      ScheduleHour=6; // Period Active in Hour
input string   Message="Account XXX is ON"; // Message
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
  OnTimer();
  EventSetTimer(ScheduleHour*60*60); 
//--- indicator buffers mapping
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if (SendNotif)
   {
      SendNotification(Message);
      Print("Send Notification Last Error:"+GetLastError());
   }
   
   if (SendEmail)
   {
      SendMail(Message,Message);
      Print("Send Email Last Error:"+GetLastError());
   }
   
   Print(Message);
  }
//+------------------------------------------------------------------+
