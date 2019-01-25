//+------------------------------------------------------------------+
//|                               Indicator: TradingIT-0.1.0beta.mq4 |
//+------------------------------------------------------------------+
#property version   "1.00"
#property description "Sistema tradingIT telegram"

#include <stdlib.mqh>
#include <stderror.mqh>

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 2
#property indicator_color1 0x40A82D
#property indicator_label1 "Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 2
#property indicator_color2 0x1515E6
#property indicator_label2 "Sell"

//--- indicator buffers
double Buffer1[];
double Buffer2[];

int TOD_From_Hour = 07; //time of the day
int TOD_From_Min = 00; //time of the day
int TOD_To_Hour = 21; //time of the day
int TOD_To_Min = 00; //time of the day
datetime time_alert; //used when sending alert
bool Audible_Alerts = true;
double myPoint; //initialized in OnInit

bool inTimeInterval(datetime t, int TOD_From_Hour, int TOD_From_Min, int TOD_To_Hour, int TOD_To_Min)
  {
   string TOD = TimeToString(t, TIME_MINUTES);
   string TOD_From = StringFormat("%02d", TOD_From_Hour)+":"+StringFormat("%02d", TOD_From_Min);
   string TOD_To = StringFormat("%02d", TOD_To_Hour)+":"+StringFormat("%02d", TOD_To_Min);
   return((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, TOD_To) <= 0)
     || (StringCompare(TOD_From, TOD_To) > 0
       && ((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, "23:59") <= 0)
         || (StringCompare(TOD, "00:00") >= 0 && StringCompare(TOD, TOD_To) <= 0))));
  }

void myAlert(string type, string message)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | TradingIT-0.1.0beta @ "+Symbol()+","+Period()+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
   else if(type == "indicator")
     {
      Print(type+" | TradingIT-0.1.0beta @ "+Symbol()+","+Period()+" | "+message);
      if(Audible_Alerts) Alert(type+" | TradingIT-0.1.0beta @ "+Symbol()+","+Period()+" | "+message);
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   IndicatorBuffers(2);
   SetIndexBuffer(0, Buffer1);
   SetIndexEmptyValue(0, 0);
   SetIndexArrow(0, 241);
   SetIndexBuffer(1, Buffer2);
   SetIndexEmptyValue(1, 0);
   SetIndexArrow(1, 242);
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   ArraySetAsSeries(Buffer2, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, 0);
      ArrayInitialize(Buffer2, 0);
     }
   else
      limit++;
   
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      //Indicator Buffer 1
      if(iDeMarker(NULL, PERIOD_CURRENT, 4, i) == 0 //DeMarker is equal to fixed value
      && iMFI(NULL, PERIOD_CURRENT, 4, i) == 0 //Money Flow Index is equal to fixed value
      && iRSI(NULL, PERIOD_CURRENT, 4, PRICE_CLOSE, i) <= 13 //Relative Strength Index <= fixed value
      )
        {
         if(!inTimeInterval(Time[i], TOD_From_Hour, TOD_From_Min, TOD_To_Hour, TOD_To_Min)) continue; //draw indicator only at specific times of the day
         if (iRSI(NULL, PERIOD_CURRENT, 4, PRICE_CLOSE, i) <= 10)
         Buffer1[i] = Low[i-1]; //Set indicator value at Candlestick Low
         if(i == 0 && Time[0] != time_alert) { myAlert("indicator", "Buy"); time_alert = Time[0]; } //Instant alert, only once per bar
        }
      else
        {
         Buffer1[i] = 0;
        }
      //Indicator Buffer 2
      if(iMFI(NULL, PERIOD_CURRENT, 4, i) == 100 //Money Flow Index is equal to fixed value
      && iRSI(NULL, PERIOD_CURRENT, 4, PRICE_CLOSE, i) >= 87 //Relative Strength Index >= fixed value
      && iDeMarker(NULL, PERIOD_CURRENT, 4, i) == 1 //DeMarker is equal to fixed value
      )
        {
         if(!inTimeInterval(Time[i], TOD_From_Hour, TOD_From_Min, TOD_To_Hour, TOD_To_Min)) continue; //draw indicator only at specific times of the day
         if (iRSI(NULL, PERIOD_CURRENT, 4, PRICE_CLOSE, i) >= 90)
         Buffer2[i] = High[i]; //Set indicator value at Candlestick High
         if(i == 0 && Time[0] != time_alert) { myAlert("indicator", "Sell"); time_alert = Time[0]; } //Instant alert, only once per bar
        }
      else
        {
         Buffer2[i] = 0;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+