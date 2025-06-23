//---------------------------------------------------------------------------------------------------------------------
#define     MName          "Wilder's Relative Strength Index (RSI)"
#define     MVersion       "1.0"
#define     MBuild         "2023-01-22 17:00 WET"
#define     MCopyright     "Copyright \x00A9 2023, Fernando M. I. Carreiro, All rights reserved"
#define     MProfile       "https://www.mql5.com/en/users/FMIC"
//---------------------------------------------------------------------------------------------------------------------
#property   strict
#property   version        MVersion
#property   description    MName
#property   description    "An implementation of the original Relative Strength Index by John Welles Wilder Jr."
#property   description    "as described in his book, New Concepts in Technical Trading Systems [1978]."
#property   description    "MetaTrader Indicator (Build "MBuild")"
#property   copyright      MCopyright
#property   link           MProfile
//---------------------------------------------------------------------------------------------------------------------

//--- Setup

   #property indicator_separate_window

   // Define number of buffers and plots
      #define MPlots    1
      #define MBuffers  3
      #ifdef __MQL4__
         #property indicator_buffers   MPlots
      #else
         #property indicator_buffers   MBuffers
         #property indicator_plots     MPlots
      #endif
   // Display properties for plots
      #property   indicator_label1        "Relative strength index"
      #property   indicator_type1         DRAW_LINE
      #property   indicator_style1        STYLE_SOLID
      #property   indicator_width1        1
      #property   indicator_color1        C'38,166,154'
   // Display levels for plots
      #property   indicator_level1        30
      #property   indicator_level2        70
      #property   indicator_levelstyle    STYLE_DOT

//--- Parameter settings

   input double                  i_dbAveragingPeriod  = 14;             // Averaging period
   #ifdef __MQL4__
      input ENUM_APPLIED_PRICE   i_ePriceApplied      = PRICE_CLOSE;    // Applied price
   #endif

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
   // Define applied price macro (MQL4 only)
      #ifdef __MQL4__
         #define MSetAppliedPrice( _type, _where, _index ) { switch( _type ) {                                \
            case PRICE_WEIGHTED: _where = ( high[ _index ] + low[ _index ] + close[ _index ]                  \
                                                                           + close[ _index ] ) * 0.25; break; \
            case PRICE_TYPICAL:  _where = ( high[ _index ] + low[ _index ] + close[ _index ] ) / 3.0;  break; \
            case PRICE_MEDIAN:   _where = ( high[ _index ] + low[ _index ]                   ) * 0.5;  break; \
            case PRICE_HIGH:     _where = high[  _index ];                                             break; \
            case PRICE_LOW:      _where = low[   _index ];                                             break; \
            case PRICE_OPEN:     _where = open[  _index ];                                             break; \
            case PRICE_CLOSE:                                                                                 \
            default:             _where = close[ _index ];                                                 }; }
      #endif
   // Define macro for calculating and assigning exponential moving average
      #define MCalcEma( _var, _value, _weight ) \
         _var = _var##Prev + ( ( _value ) - _var##Prev ) * ( _weight )
   // Define macro for invalid parameter values
      #define MCheckParameter( _condition, _text ) if( _condition ) \
         { Print( "Error: Invalid ", _text ); return INIT_PARAMETERS_INCORRECT; }

//--- Global variable declarations

   // Indicator buffers
      double      g_adbUpAverage[],                // Buffer for average of up movements
                  g_adbDownAverage[],              // Buffer for average of down movements
                  g_adbRSI[];                      // Buffer for relative strength index
      #ifdef __MQL4__
         double   price[];                         // Buffer for applied price (MQL4 only)
      #endif

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
            int iBuffer = 0;
            #ifdef __MQL4__
               IndicatorBuffers( MBuffers + 1 );                     // Set total number of buffers (MQL4 Only)
            #endif
            SetIndexBuffer(    iBuffer++, g_adbRSI,         INDICATOR_DATA         );  // Releative strength index
            SetIndexBuffer(    iBuffer++, g_adbUpAverage,   INDICATOR_CALCULATIONS );  // Average price up changes
            SetIndexBuffer(    iBuffer++, g_adbDownAverage, INDICATOR_CALCULATIONS );  // Average price down changes
            #ifdef __MQL4__
               SetIndexBuffer( iBuffer++, price,            INDICATOR_CALCULATIONS );  // Applied price buffer (MQL4 Only)
            #endif
         // Set indicator name
            IndicatorSetString( INDICATOR_SHORTNAME, StringFormat(
               MName " ( %.2f )", i_dbAveragingPeriod ) );
         return INIT_SUCCEEDED;  // Successful initialisation of indicator
      };

   // Calculation event handler
      #ifdef __MQL4__
         int OnCalculate( const int rates_total, const int prev_calculated, const datetime &time[],
                          const double &open[], const double &high[], const double &low[], const double &close[],
                          const long &tick_volume[], const long &volume[], const int &spread[] ) {
      #else
         int OnCalculate( const int rates_total, const int prev_calculated,
                          const int begin, const double& price[] ) {
      #endif
         // Main loop: calculate values and apply data to buffers
            for( int iCur = MOnCalcStart, iPrev = MOnCalcBack( iCur, 1 );
                 !IsStopped() && MOnCalcCheck( iCur ); MOnCalcNext( iCur ), MOnCalcNext( iPrev ) ) {
               // Get (or calculate) current applied price
                  #ifdef __MQL4__
                     double dbPriceCur;
                     MSetAppliedPrice( i_ePriceApplied, dbPriceCur, iCur );
                     price[ iCur ] = dbPriceCur;
                  #else
                     double dbPriceCur = price[ iCur ];
                  #endif
               // Calculate the remaining values
                  double dbUpAverage = 0.0, dbDownAverage = 0.0;
                  if( MOnCalcValid( iPrev ) ) {
                     double dbPriceChange     = dbPriceCur - price[ iPrev ],
                            dbUpChange        = dbPriceChange > 0.0 ? dbPriceChange : 0.0,
                            dbDownChange      = dbPriceChange < 0.0 ? dbPriceChange : 0.0,
                            dbUpAveragePrev   = g_adbUpAverage[   iPrev ],
                            dbDownAveragePrev = g_adbDownAverage[ iPrev ];
                     MCalcEma( dbUpAverage,   dbUpChange,   g_dbEmaWeight );
                     MCalcEma( dbDownAverage, dbDownChange, g_dbEmaWeight );
                  };
               // Set buffer values
                  double          dbAbsSum = dbUpAverage - dbDownAverage;
                  g_adbRSI[         iCur ] = ( dbAbsSum > 0.0 ? dbUpAverage / dbAbsSum : 1.0 ) * 100.0;
                  g_adbUpAverage[   iCur ] = dbUpAverage;
                  g_adbDownAverage[ iCur ] = dbDownAverage;
            };
         return rates_total;  // Return value for prev_calculated of next call
      };

//---------------------------------------------------------------------------------------------------------------------
