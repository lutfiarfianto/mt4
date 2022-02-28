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
input ENUM_TIMEFRAMES      initTF=60;  // TF
input int      STPeriod=30;            // SuperTrend Main Period
input double   STMultiplier=9.0;       // SuperTrend Main Multiplier
input int      SubTPeriod=10;          // SuperTrend Sub Period
input double   SubTMultiplier=3.0;     // SuperTrend Sub Multiplie
input int      SubPipGaps=1000;        // Main Sub Gaps
input int      Dch=240;                // Donchian Period
input int      TP=2000;                // Main TP
input int      SL=1000;                // Main SL
input int      SubTP=1200;             // Sub TP
input int      SubSL=1000;             // Sub SL
input int      SubTimesMax=1;          // Sub Level Max
input int      InitSubTimes=0;         // Starting Sub Level
input int      MACDFastEma=12;         // MACD Fast EMA
input int      MACDSlowEma=26;         // MACD Slow EMA
input int      MACDSMA=9;              // MACD SMA
input int      MACDTP=800;             // MACD TP
input int      MACDSL=400;             // MACD SL
input double   MACDMinLevel=0.001;     // MACD Min Level
input double   PFactor=10;             // Pips Multiplier
input double   RiskFactor=5.0;         // Risk Factor in percent
//input int      initFilter=0;           // Trend Filter
input bool     useST=true;             // Use SuperTrend
input bool     useMACD=true;           // Use MACD
input double   reservedEquity=0;       // Reserved Equity
input string   tComment="";            // Comment
input bool     isTester=false;

int TF;
int SubTimes;
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
      logData();
     }



   TF = initTF;
   if(isTester)
     {
      TF = PERIOD_CURRENT;
     }


//---

   double clr=iCustom("Grid_V2",0,TF,10,100,clrDimGray,clrDarkGreen,0,1);
//filter = initFilter;
   SubTimes = InitSubTimes;

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
      logData();
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

   int action = getAction(STMultiplier,STPeriod);
   int filter = getFilter(STMultiplier,STPeriod,1);

   if(useST)
     {

      execAction(action,SL,TP);

     }

   if(action!=0)
     {
      //filter = action;
      SubTimes = 0;
      logOrder("ST Main");
      //Print("_main/ filter:",filter);
     }

   if(useST)
     {

      if(SubTimes<=SubTimesMax)
        {
         int subAction = getAction(SubTMultiplier,SubTPeriod);
         if(subAction != 0)
           {
            if(subAction == filter)
              {
               logOrder("Sub ST: " + SubTimes);
               SubTimes++;
              }
            //Print("_main/ SubTimes:",SubTimes," SubAction:",subAction," filter:",filter);
           }
         execAction(subAction,SubSL,SubTP,filter);
        }

     }
// Print("filter:",filter);
   if(useMACD && macdValidLevel(filter))
     {
      int macdAction = macd_entry(filter);
      if(macdAction==filter)
        {
         logOrder("MACD");
        }
      execAction(macdAction,MACDSL,MACDTP,filter);
     }

   autoSL();

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getFilter(double multiplier, int period, int i)
  {

   int STDir = 0;

   double spTrendUp = NormalizeDouble(iCustom(0,TF,"Supertrend Line","SPRTRND",multiplier,period,9000,0,i),Digits);
   double spTrendDn = NormalizeDouble(iCustom(0,TF,"Supertrend Line","SPRTRND",multiplier,period,9000,1,i),Digits);

   if(spTrendDn>2e9)
     {
      STDir = 1;
     }
   if(spTrendUp>2e9)
     {
      STDir = -1;
     }

   return STDir;

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getAction(double multiplier, int period)
  {

   int i = 1;

   int STDir = 0;
   int STDir2 = 0;
   int res = 0;

   /*
   double spTrendUp = NormalizeDouble(iCustom(0,TF,"Supertrend Line","SPRTRND",multiplier,period,9000,0,i),Digits);
   double spTrendDn = NormalizeDouble(iCustom(0,TF,"Supertrend Line","SPRTRND",multiplier,period,9000,1,i),Digits);

   double spTrendUp2 = NormalizeDouble(iCustom(0,TF,"Supertrend Line","SPRTRND",multiplier,period,9000,0,i+1),Digits);
   double spTrendDn2 = NormalizeDouble(iCustom(0,TF,"Supertrend Line","SPRTRND",multiplier,period,9000,1,i+1),Digits);


   if(spTrendDn>2e9)
     {
      STDir = 1;
     }
   if(spTrendUp>2e9)
     {
      STDir = -1;
     }

   if(spTrendDn2>2e9)
     {
      STDir2 = 1;
     }
   if(spTrendUp2>2e9)
     {
      STDir2 = -1;
     }
   */

   STDir = getFilter(multiplier,period,1);
   STDir2 = getFilter(multiplier,period,2);

   int changed = (STDir2!=STDir)?1:0;
//Print("p:",period," m:",multiplier," up:",spTrendUp," dn:",spTrendDn," upz:",spTrendUp2," dnz:",spTrendDn2,
//" STDir:",STDir," STDir2:",STDir2);
//Print("up:",spTrendUp," dn:",spTrendDn," STDir:",STDir," Changed:",changed);



// trend change to up
   if(STDir==1 && changed)
     {

      res = 1;

     }

// trend change to dn
   if(STDir==-1 && changed)
     {

      res = -1;

     }

   if(changed)
     {
      //Print("_getAction/ Res:",res);
     }

   return res;

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int macd_entry(int filter)
  {

   int result = 0, i = 0;

   double iMacd_Main_0 = iMACD(0,TF,MACDFastEma,MACDSlowEma,MACDSMA,PRICE_CLOSE,MODE_MAIN,i);
   double iMacd_Signal_0 = iMACD(0,TF,MACDFastEma,MACDSlowEma,MACDSMA,PRICE_CLOSE,MODE_SIGNAL,i);

   double iMacd_Main_1 = iMACD(0,TF,MACDFastEma,MACDSlowEma,MACDSMA,PRICE_CLOSE,MODE_MAIN,i+1);
   double iMacd_Signal_1 = iMACD(0,TF,MACDFastEma,MACDSlowEma,MACDSMA,PRICE_CLOSE,MODE_SIGNAL,i+1);

   if(filter==1)
     {

      if(iMacd_Main_1 < 0 && iMacd_Signal_1 < 0 && iMacd_Signal_1 > iMacd_Main_1 && iMacd_Signal_0 < iMacd_Main_0)
        {

         result = 1;

        }

     }

   if(filter==-1)
     {

      if(iMacd_Main_1 > 0 && iMacd_Signal_1 > 0 && iMacd_Signal_1 < iMacd_Main_1 && iMacd_Signal_0 > iMacd_Main_0)
        {

         result = -1;

        }

     }

   return result;

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
   lots =  calculateLots(pips);

//Print("pips: ",pips," SL:",sl," point:",Point," lots:",lots," filter:",filter);

// trend up
   if(res==1 && filter >=0)
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

   if(res==-1 && filter <= 0)
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
bool macdValidLevel(int filter)
  {

   bool isValid = false;
   int i=0;

   if(MathAbs(iMACD(0,TF,MACDFastEma,MACDSlowEma,MACDSMA,PRICE_CLOSE,MODE_SIGNAL,i)) > MACDMinLevel &&
      MathAbs(iMACD(0,TF,MACDFastEma,MACDSlowEma,MACDSMA,PRICE_CLOSE,MODE_MAIN,i)) > MACDMinLevel)
     {

      isValid = true;

     }

   return isValid;

  }

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
void logOrder(string signals)
  {

   string fileName = "myea/" + AccountNumber()+"_"+ Symbol() + ".order.log";
   string logStr="";
   int i = 0;

   string str = File::Read(fileName);

   logStr = "time:" + TimeCurrent()+ " - " + signals

            ;

   str = str + "\n" + logStr;

   File::Write(fileName, str);



  }
//+------------------------------------------------------------------+
