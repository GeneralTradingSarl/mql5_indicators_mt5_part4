//---------------------------------------------------------------------------------------------------------------------
#define     MName          "Wilder's Average True Range (ATR)"
#define     MVersion       "1.0"
#define     MBuild         "2023-01-22 11:50 WET"
#define     MCopyright     "Copyright \x00A9 2023, Fernando M. I. Carreiro, All rights reserved"
#define     MProfile       "https://www.mql5.com/en/users/FMIC"
//---------------------------------------------------------------------------------------------------------------------
#property   strict
#property   version        MVersion
#property   description    MName
#property   description    "An implementation of the original Average True Range indicator by John Welles Wilder Jr."
#property   description    "as described in his book, New Concepts in Technical Trading Systems [1978]."
#property   description    "MetaTrader Indicator (Build "MBuild")"
#property   copyright      MCopyright
#property   link           MProfile
//---------------------------------------------------------------------------------------------------------------------

//--- Setup

   #property indicator_separate_window

   // Define number of buffers and plots
      #define MPlots    1
      #define MBuffers  1
      #ifdef __MQL4__
         #property indicator_buffers   MPlots
      #else
         #property indicator_buffers   MBuffers
         #property indicator_plots     MPlots
      #endif
   // Display properties for plots
      #property   indicator_label1  "Average true range"
      #property   indicator_type1   DRAW_LINE
      #property   indicator_style1  STYLE_SOLID
      #property   indicator_width1  1
      #property   indicator_color1  C'38,166,154'

//--- Parameter settings

   input double   i_dbAveragingPeriod  = 7; // Averaging period

//--- Macro definitions

   // Define OnCalculate loop sequencing macros
      #define MOnCalcPrevTest ( prev_calculated < 1 || prev_calculated > rates_total )
      #ifdef __MQL4__   // for MQL4 (as series)
         #define MOnCalcNext(  _index          ) ( _index--             )
         #define MOnCalcBack(  _index, _offset ) ( _index + _offset     )
         #define MOnCalcCheck( _index          ) ( _index >= 0          )
         #define MOnCalcValid( _index          ) ( _index < rates_total )
         #define MOnCalcStart \
            ( rates_total - ( MOnCalcPrevTest ? 1 : prev_calculated ) )
      #else             // for MQL5 (as non-series)
         #define MOnCalcNext(  _index          ) ( _index++             )
         #define MOnCalcBack(  _index, _offset ) ( _index - _offset     )
         #define MOnCalcCheck( _index          ) ( _index < rates_total )
         #define MOnCalcValid( _index          ) ( _index >= 0          )
         #define MOnCalcStart \
            ( MOnCalcPrevTest ? 0 : prev_calculated - 1 )
      #endif
   // Define macro for invalid parameter values
      #define MCheckParameter( _condition, _text ) if( _condition ) \
         { Print( "Error: Invalid ", _text ); return INIT_PARAMETERS_INCORRECT; }

//--- Global variable declarations

   // Indicator buffers
      double      g_adbATR[];       // Buffer for average true range
   // Miscellaneous global variables
      double      g_dbEmaWeight;    // Weight to be used for exponential moving averages

//--- Event handling functions

   // Initialisation event handler
      int OnInit(void) {
         // Validate input parameters
            MCheckParameter( i_dbAveragingPeriod < 1.0, "averaging period" );
         // Calculate EMA alpha weight for Wilder's moving average, also known as smoothed moving average (SMMA)
            g_dbEmaWeight = 1.0 / i_dbAveragingPeriod;
         // Set number of significant digits (precision)
            IndicatorSetInteger( INDICATOR_DIGITS, _Digits );
         // Set buffers
            #ifdef __MQL4__
               IndicatorBuffers( MBuffers ); // Set total number of buffers (MQL4 Only)
            #endif
            SetIndexBuffer( 0, g_adbATR, INDICATOR_DATA );
         // Set indicator name
            IndicatorSetString( INDICATOR_SHORTNAME, StringFormat(
               MName " ( %.2f )", i_dbAveragingPeriod ) );
         return INIT_SUCCEEDED;  // Successful initialisation of indicator
      };

   // Calculation event handler
      int OnCalculate( const int rates_total, const int prev_calculated, const datetime &time[],
                       const double &open[], const double &high[], const double &low[], const double &close[],
                       const long &tick_volume[], const long &volume[], const int &spread[] ) {
         // Main loop: calculate values and apply data to buffers
            for( int iCur = MOnCalcStart, iPrev = MOnCalcBack( iCur, 1 );
                 !IsStopped() && MOnCalcCheck( iCur ); MOnCalcNext( iCur ), MOnCalcNext( iPrev ) ) {
               if( MOnCalcValid( iPrev ) ) {
                  double dbClosePrev = close[ iPrev ],
                         dbTrueRange = fmax( high[ iCur ], dbClosePrev )
                                     - fmin( low[  iCur ], dbClosePrev ),
                         dbATRPrev   = g_adbATR[ iPrev ];
                  g_adbATR[ iCur ] = dbATRPrev + ( dbTrueRange - dbATRPrev ) * g_dbEmaWeight;
               } else
                  g_adbATR[ iCur ] = high[ iCur ] - low[ iCur ];
            };
         return rates_total;  // Return value for prev_calculated of next call
      };

//---------------------------------------------------------------------------------------------------------------------
