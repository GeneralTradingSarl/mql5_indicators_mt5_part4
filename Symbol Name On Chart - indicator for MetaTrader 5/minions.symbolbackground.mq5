//+-------------------------------------------------------------------------------------+
//|                                                        Minions.SymbolBackground.mq5 |
//| (CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License|
//|                                                          http://www.MinionsLabs.com |
//+-------------------------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Descriptors                                                      |
//+------------------------------------------------------------------+
#property copyright   "www.MinionsLabs.com"
#property link        "http://www.MinionsLabs.com"
#property version     "1.0"
#property description "Minions showing the Symbol at the Chart background in an unobtrusive way"
#property description " "
#property description "(CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License"


//+------------------------------------------------------------------+
//| Indicator Settings                                               |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots   0


//+------------------------------------------------------------------+
// ENUMerations
//+------------------------------------------------------------------+
enum ML_WINPOSITION {
     ML_WINPOSITION_UPPER_LEFT=0,               //Upper Left of the chart
     ML_WINPOSITION_UPPER_CENTER=1,             //Upper Center of the chart
     ML_WINPOSITION_UPPER_RIGHT=2,              //Upper Right of the chart
     ML_WINPOSITION_LOWER_LEFT=3,               //Lower Left of the chart
     ML_WINPOSITION_LOWER_CENTER=4,             //Lower Center of the chart
     ML_WINPOSITION_LOWER_RIGHT=5               //Lower Right of the chart
};
enum ML_FONTTYPE {
     ML_FONTTYPE_ARIAL=0,                       //Arial
     ML_FONTTYPE_ARIALBLACK=1,                  //Arial Black
     ML_FONTTYPE_VERDANA=2,                     //Verdana
     ML_FONTTYPE_TAHOMA=3,                      //Tahoma
     ML_FONTTYPE_COURIERNEW=4,                  //Courier New
     ML_FONTTYPE_LUCIDACONSOLE=5                //Lucida Console

};


//+------------------------------------------------------------------+
// Inputs from User Interface                                        |
//+------------------------------------------------------------------+
input color           inpTextColor=C'45,45,45';                       // Symbol Text color
input ML_FONTTYPE     inpFontType=1;                                  // Font Type
input int             inpFontSize=24;                                 // Symbol Font size
input ML_WINPOSITION  inpWindowPosition=ML_WINPOSITION_UPPER_CENTER;  // Symbol position
input int             inpXOffSet=0;                                   // Reposition Symbol Offset on X axis (+/-)
input int             inpYOffSet=0;                                   // Reposition Symbol Offset on Y axis (+/-)


//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
string _SymbolName  = "MLabs_SymbolBackground";        // Namespacing the Symbol Background...
int    _CurWindowWidth;                                // holds the current Chart width


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()   {

    // creates the Clock...
    ObjectCreate(     0, _SymbolName, OBJ_LABEL, 0, 0, 0);
    ObjectSetString(  0, _SymbolName, OBJPROP_TEXT, _Symbol );
    ObjectSetInteger( 0, _SymbolName, OBJPROP_COLOR, inpTextColor );
    ObjectSetInteger( 0, _SymbolName, OBJPROP_FONTSIZE, inpFontSize );
    ObjectSetInteger( 0, _SymbolName, OBJPROP_BACK,true);

    if (inpFontType==ML_FONTTYPE_ARIAL)         {  ObjectSetString(  0, _SymbolName, OBJPROP_FONT, "Arial" );          }
    if (inpFontType==ML_FONTTYPE_ARIALBLACK)    {  ObjectSetString(  0, _SymbolName, OBJPROP_FONT, "Arial Black" );    }
    if (inpFontType==ML_FONTTYPE_VERDANA)       {  ObjectSetString(  0, _SymbolName, OBJPROP_FONT, "Verdana" );        }
    if (inpFontType==ML_FONTTYPE_TAHOMA)        {  ObjectSetString(  0, _SymbolName, OBJPROP_FONT, "Tahoma" );         }
    if (inpFontType==ML_FONTTYPE_COURIERNEW)    {  ObjectSetString(  0, _SymbolName, OBJPROP_FONT, "Courier New" );    }
    if (inpFontType==ML_FONTTYPE_LUCIDACONSOLE) {  ObjectSetString(  0, _SymbolName, OBJPROP_FONT, "Lucida Console" ); }

    updateXY();   // updates the initial X,Y coordinates for the Symbol name on the Chart...

    ChartRedraw();
}


//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit( const int reason ) {
    ObjectDelete( 0, _SymbolName );
}



//+------------------------------------------------------------------+
//| Custom indicator iteration function - DOES NOTHING!              |
//+------------------------------------------------------------------+
int OnCalculate( const int        rates_total,       // price[] array size
                 const int        prev_calculated,   // number of handled bars at the previous call
                 const int        begin,             // index number in the price[] array meaningful data starts from
                 const double&    price[]            // array of values for calculation
                ) {
   return 0;
}



//+------------------------------------------------------------------+
//| OnChart events
//+------------------------------------------------------------------+
void  OnChartEvent( const int       id,       // event ID 
                    const long&     lparam,
                    const double&   dparam,
                    const string&   sparam 
                   ) {

    int newWindowsWidth;

    // checks if the Chart size has changed...
    if (id==CHARTEVENT_CHART_CHANGE ) {
        newWindowsWidth = (int)ChartGetInteger( 0, CHART_WIDTH_IN_PIXELS, 0 );

        if (_CurWindowWidth != newWindowsWidth) {
            updateXY();                      // repaints the Symbol name into the new coordinate...
            _CurWindowWidth = newWindowsWidth;
        }
    }

}




//+------------------------------------------------------------------+
//| Updates X and Y coordinates of the Symbol Name on Chart...
//+------------------------------------------------------------------+
void  updateXY() {
    if (inpWindowPosition==ML_WINPOSITION_UPPER_LEFT) {
        ObjectSetInteger( 0, _SymbolName, OBJPROP_CORNER, CORNER_LEFT_UPPER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_UPPER_RIGHT) {
        ObjectSetInteger( 0, _SymbolName, OBJPROP_CORNER, CORNER_RIGHT_UPPER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_UPPER_CENTER) {
        ObjectSetInteger( 0, _SymbolName, OBJPROP_CORNER, CORNER_LEFT_UPPER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_XDISTANCE, inpXOffSet+ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0)/2 );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_LOWER_LEFT) {
        ObjectSetInteger( 0, _SymbolName, OBJPROP_CORNER, CORNER_LEFT_LOWER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_LOWER_RIGHT) {
        ObjectSetInteger( 0, _SymbolName, OBJPROP_CORNER, CORNER_RIGHT_LOWER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_LOWER_CENTER) {
        ObjectSetInteger( 0, _SymbolName, OBJPROP_CORNER, CORNER_LEFT_LOWER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_XDISTANCE, inpXOffSet+ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0)/2 );
        ObjectSetInteger( 0, _SymbolName, OBJPROP_YDISTANCE, inpYOffSet);
    }
}
//+------------------------------------------------------------------+
