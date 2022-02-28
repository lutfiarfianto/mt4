//+------------------------------------------------------------------+
//|                                             SuperTrendAutoSL.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <File.mqh>


//--- input parameters
input ENUM_TIMEFRAMES      initTF=15;   // TF
input double   SARStep=0.02;           // SAR Step
input double   SARMaximum=0.2;         // SAR Maximum
input int      SARTimesMax=3;          // SAR Times
input int      Dch=42;                 // Donchian Period
input int      EMASignal=38;           // EMA Signal
input int      EMAFilter=200;          // EMA Filter
input int      TP1=300;
input int      TP2=150;
input int      TP3=150;
input int      SL=100;
input double   PFactor=10;             // Pips Multiplier
input double   RiskFactor=5.0;         // Risk Factor in percent
//input int      initFilter=0;           // Trend Filter
input double   reservedEquity=0;       // Reserved Equity
input string   tComment="";            // Comment
input bool     isTester=true;

int TF;
int SarTimes;
int filter;
double superPrice;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);


   if(!isTester)
     {
      main();
      //logData();
     }



   TF = initTF;
   if(isTester)
     {
      TF = PERIOD_CURRENT;
     }


//---

//double clr=iCustom("Grid_V2",0,TF,10,100,clrDimGray,clrDarkGreen,0,1);
//filter = initFilter;

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(isTester)
     {
      main();
      autoSL();
     }

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if(fmod(Minute(), TF)==0)
     {
      main();
      autoSL();
      //logData();
     }



  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void main()
  {

   int action;

// Print("main");

   filter = getFilter(EMAFilter,1);

   int filter1 = getFilter(EMAFilter,1);
   int filter2 = getFilter(EMAFilter,2);

   Print("filter1:",filter1," filter2:",filter2);


   if(filter1*filter2==-1)
     {
      Print("trend changed");
      SarTimes=0;
     }

   if(SarTimes < SARTimesMax)
     {

      // get signal and sartimes++
      action = getSignal(filter);

      if(action!=0)
        {

         Print("Filter:",filter," action:",action," sarX:",SarTimes);

         switch(SarTimes)
           {

            case 1:
               execAction(action,SL,TP1,filter);
               break;

            case 2:
               execAction(action,SL,TP2,filter);
               break;

            case 3:
               execAction(action,SL,TP3,filter);
               break;
           }

         //logOrder("PSAR.EMA");

        }

     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getFilter(int period, int i=0)
  {

   int Filter = 0;
   double iEMA;

   iEMA = iMA(Symbol(),TF,period,0,MODE_EMA,PRICE_CLOSE,i);

   if(iClose(Symbol(),TF,i)>iEMA)
     {
      Filter = 1;
     }
   if(iClose(Symbol(),TF,i)<iEMA)
     {
      Filter = -1;
     }

   return Filter;

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getSarSignal(int i=1)
  {

   int signal = 0;
   double iEMA, iPSAR;

   iEMA = NormalizeDouble(iMA(Symbol(),TF,EMASignal,0,MODE_EMA,PRICE_CLOSE,i),Digits);
   iPSAR = NormalizeDouble(iSAR(Symbol(),TF,SARStep,SARMaximum,i),Digits);

   if(iPSAR > iEMA)
     {
      signal = 1;
     }

   if(iPSAR < iEMA)
     {
      signal = -1;
     }

// Print(" i:",i," sar signal:",signal," psar:",iPSAR," ema:",iEMA);

   return signal;

  }


//+------------------------------------------------------------------+
//|  PSAR crossed EMA
//+------------------------------------------------------------------+
int getSignal(int filter, int i=1)
  {

   int res = 0;

// detect cross
   if(getSarSignal(1)* getSarSignal(2) == -1)
     {

      // detect trend
      if(getSarSignal(1)==filter)
        {

         res = getSarSignal(1);

         SarTimes++;

        }

     }

   return res;

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateLots(int pips)
  {

   double lots = 0.0;

   lots = NormalizeDouble(AccountBalance() * RiskFactor / pips / 100 * PFactor, 2);
   if(lots<=0.01)
      lots = 0.01;

//Print("pips:",pips," lot:",lots);

   return lots;

  }
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getSL(int trend)
  {

   int i = 1;
   double res = iClose(0,TF,i);

   double dchUp,dchDn;

   dchUp = iCustom("DonchianChannels",TF,Dch,0,i);
   dchDn = iCustom("DonchianChannels",TF,Dch,2,i);

   if(trend==1)
     {
      res = dchDn;
     }

   if(trend==-1)
     {
      res = dchUp;
     }

   return res;

  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void execAction(int res, int sl, int tp, int filter  = 0)
  {

   double price,d,lots,stopLoss,takeProfit,STLine;
   int pips = 0;
   int i = 1;
   int ticket = 0;
   pips = sl;
   lots = calculateLots(pips);

   Print("pips: ",pips," SL:",sl," point:",Point," lots:",lots," filter:",filter);

// trend up
   if(res==1 && filter >0)
     {

      price = Ask;

      //STLine = NormalizeDouble(iCustom(0,0,"Supertrend Line","SPRTRND",STMultiplier,STPeriod,1000,0,i), Digits);



      //d =  MathAbs(price - STLine);
      stopLoss = NormalizeDouble(price - sl * Point, Digits);
      takeProfit = NormalizeDouble(price + tp * Point, Digits);
      //pips = SL/Point;
      //lots =  calculateLots(pips);

      ticket = OrderSend(Symbol(),OP_BUY,lots,price,3,stopLoss,takeProfit,tComment);

     }

// trend down

   if(res==-1 && filter < 0)
     {

      price = Bid;

      //STLine = NormalizeDouble(iCustom(0,0,"Supertrend Line","SPRTRND",STMultiplier,STPeriod,1000,1,i), Digits);
      //d =  NormalizeDouble(MathAbs(price - STLine),Digits);
      stopLoss = NormalizeDouble(price + sl * Point, Digits);
      takeProfit = NormalizeDouble(price - tp * Point, Digits);
      //pips = SL/Point;
      //lots =  calculateLots(pips);
      //Print("aset:",asset," risk:",risk," pips:",pips," lot:",lots);

      ticket = OrderSend(Symbol(),OP_SELL,lots,price,3,stopLoss,takeProfit,tComment);

     }
   Print("order success");

  }

//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void autoSL()
  {

   for(int index = 0 ; index < OrdersTotal(); index++)
     {
      OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol() == Symbol() && OrderComment() == tComment)
        {
         // Print("Ticket: ", OrderTicket());
         SetStopLoss(OrderTicket(), Dch);
        }

     }

  }



//+------------------------------------------------------------------+
void SetStopLoss(int tTicket, int Dch)
  {

   bool     result;
   double   price;
   int      cmd,error;
   double   tStopLoss,tTakeProfit,qTakeProfit;
   int      i=0;

   if(OrderSelect(tTicket,SELECT_BY_TICKET,MODE_TRADES))
     {
      cmd=OrderType();
      //---- first order is buy or sell
      if(cmd==OP_BUY || cmd==OP_SELL)
        {
         while(true)
           {

            //--- check cmd position to determine channel

            if(cmd==OP_BUY)
              {
               price=Bid;

               //--- stop loss on lower band
               tStopLoss = iCustom(0,TF,"DonchianChannels",Dch,2,i);//   iLow(Symbol(),TF,iLowest(Symbol(),TF,MODE_LOW,Dch,i));

               if(tStopLoss<=OrderStopLoss())
                 {
                  tStopLoss=OrderStopLoss();
                 }

              }
            else
              {
               price=Ask;
               //--- stop loss on upper band
               tStopLoss=  iCustom(0,TF,"DonchianChannels",Dch,0,i); //iHigh(Symbol(),TF,iHighest(Symbol(),TF,MODE_HIGH,Dch,i));

               if(tStopLoss>=OrderStopLoss())
                 {
                  tStopLoss=OrderStopLoss();
                 }

              }

            double iStopLoss = NormalizeDouble(tStopLoss,Digits);
            double iTakeProfit = NormalizeDouble(OrderTakeProfit(),Digits);

            //Comment(Symbol(),":",tTimeFrame);
            //Comment("EA Donchian Auto Stoploss: ", iStopLoss);
            //Comment("Take Profit: ",iTakeProfit);

            if(OrderStopLoss() != iStopLoss)
              {
               result=OrderModify(OrderTicket(),OrderOpenPrice(),iStopLoss,iTakeProfit,0,Blue);
              }
            else
              {
               //               Print("No Change");
               result = TRUE;
              }//---



            if(result!=TRUE)
              {
               error=GetLastError();
               Print("LastError = ",error);
              }
            else
               error=0;
            if(error==135)
               RefreshRates();
            else
               break;
           }
        }
     }
   else
      Print("Error when order select ", GetLastError());




  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void protectReserved()
  {

   for(int index = 0 ; index < OrdersTotal(); index++)
     {
      OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol() == Symbol())
        {
         // Print("Ticket: ", OrderTicket());
         doProtectReserved(OrderTicket());
        }

     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doProtectReserved(int ticket)
  {
   if(reservedEquity>0)
     {

      OrderClose(ticket,OrderLots(),OrderOpenPrice(),3,clrNONE);

     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void logData()
  {

   string fileName = "myea/" + AccountNumber()+"_"+ Symbol() + ".log";
   string str="",logStr="";
   int i = 0;

   str = File::Read(fileName);

   logStr = "time:" + TimeCurrent() + " ,O:" + iOpen(0,TF,i) + " ,H" + iHigh(0,TF,i)
            + " ,L:" + iLow(0,TF,i) + " ,C:" + iClose(0,TF,i) + " ,V:" + iVolume(0,TF,i)
            + " ,Balance:" + AccountBalance() + " ,Equity:" + AccountEquity()

            ;

   str = str + "\n" + logStr;

   File::Write(fileName, str);


  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void logOrder(string str)
  {

   string fileName = "myea/" + AccountNumber()+"_"+ Symbol() + ".order";
   string logStr="";
   int i = 0;

   str = File::Read(fileName);

   logStr = "time:" + TimeCurrent() + str

            ;

   str = str + "\n" + logStr;

   File::Write(fileName, str);



  }
//+------------------------------------------------------------------+
