//---------------------------------------------------------------------------------------------------------------------
#define     MName          "Time Segmented Volume (TSV)"
#define     MVersion       "1.01"
#define     MBuild         "2023-03-27 21:02 WET"
#define     MCopyright     "Copyright \x00A9 2023, Fernando M. I. Carreiro, All rights reserved"
#define     MProfile       "https://www.mql5.com/en/users/FMIC"
//---------------------------------------------------------------------------------------------------------------------
#property   strict
#property   version        MVersion
#property   description    MName
#property   description    "MetaTrader Indicator (Build "MBuild")"
#property   copyright      MCopyright
#property   link           MProfile
//---------------------------------------------------------------------------------------------------------------------

//--- Setup

   #property indicator_separate_window

   // Define number of buffers and plots
      #define MPlots    3
      #define MBuffers  7
      #ifdef __MQL4__
         #property indicator_buffers   ( MPlots + 1 )
      #else
         #property indicator_buffers   MBuffers
         #property indicator_plots     MPlots
      #endif

   // Define plot colours and respective indices
      #define     MClrCandleNone    C'239,166,117'
      #define     MClrCandleUp      C'38,166,154'
      #define     MClrCandleDown    C'239,83,80'

   // Display properties for plots
      #ifdef __MQL4__
         // Summation plots
            #property   indicator_label1  "Summation (positive)"
            #property   indicator_type1   DRAW_HISTOGRAM
            #property   indicator_style1  STYLE_SOLID
            #property   indicator_width1  3
            #property   indicator_color1  MClrCandleUp
            #property   indicator_label2  "Summation (negative)"
            #property   indicator_type2   DRAW_HISTOGRAM
            #property   indicator_style2  STYLE_SOLID
            #property   indicator_width2  3
            #property   indicator_color2  MClrCandleDown
         // Simple averaging plot
            #property   indicator_label3  "Averaging (simple)"
            #property   indicator_type3   DRAW_LINE
            #property   indicator_style3  STYLE_SOLID
            #property   indicator_width3  2
            #property   indicator_color3  MClrCandleNone
         // Exponential averaging plot
            #property   indicator_label4  "Averaging (exponential)"
            #property   indicator_type4   DRAW_LINE
            #property   indicator_style4  STYLE_SOLID
            #property   indicator_width4  1
            #property   indicator_color4  MClrCandleNone
      #else
         // Define colour index for plots
            #define     MIdxCandleNone    0.0
            #define     MIdxCandleUp      1.0
            #define     MIdxCandleDown    2.0
         // Summation plot
            #property   indicator_label1  "Summation"
            #property   indicator_type1   DRAW_COLOR_HISTOGRAM
            #property   indicator_style1  STYLE_SOLID
            #property   indicator_width1  5
            #property   indicator_color1  MClrCandleNone, MClrCandleUp, MClrCandleDown
         // Simple averaging plot
            #property   indicator_label2  "Averaging (simple)"
            #property   indicator_type2   DRAW_LINE
            #property   indicator_style2  STYLE_SOLID
            #property   indicator_width2  2
            #property   indicator_color2  MClrCandleNone
         // Exponential averaging plot
            #property   indicator_label3  "Averaging (exponential)"
            #property   indicator_type3   DRAW_LINE
            #property   indicator_style3  STYLE_SOLID
            #property   indicator_width3  1
            #property   indicator_color3  MClrCandleNone
      #endif

//--- Enumarations

   // Volume weight enumaraton
      enum EVolumeWeight
      {
         EVW_None = 0,        // No volume weighting
         EVW_TickVolume,      // Tick volume
         #ifndef __MQL4__
            EVW_RealVolume,   // Real volume
         #endif
         EVW_PriceRange       // True price range (pseudo volume)
      };

//--- Parameter settings

   input uint                 i_nSummationPeriod   = 13,             // Summation period
                              i_nAveragingPeriod   = 7;              // Averaging period
   input ENUM_APPLIED_PRICE   i_ePriceApplied      = PRICE_CLOSE;    // Applied price
   input EVolumeWeight        i_eVolumeWeight      = EVW_TickVolume; // Applied volume

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

   // Define applied price macro
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

   // Define macro for invalid parameter values
      #define MCheckParameter( _condition, _text ) if( _condition ) \
         { Print( "Error: Invalid ", _text ); return INIT_PARAMETERS_INCORRECT; }

//--- Global variable declarations

   // Indicator buffers
      double      g_adbPriceApplied[],             // Buffer for applied price
                  g_adbVolumePriceDelta[],         // Buffer for volume weight price delta change
                  g_adbSummation[],                // Buffer for summation of volume weighte price change
                  g_adbSummationSimple[],          // Buffer for summation of summation for simple averaging
                  g_adbAveragingSimple[],          // Buffer for simple averaging
                  g_adbAveragingExponential[];     // Buffer for exponential averaging
      #ifdef __MQL4__
         double   g_adbSummationPositive[],        // Buffer for positive summation of volume weighte price change
                  g_adbSummationNegative[];        // Buffer for negative summation of volume weighte price change
      #else
         double   g_adbSummationColour[];          // Buffer for summation colourisation
      #endif

   // Miscellaneous global variables
      double      g_dbEmaWeight;                   // Weight to be used for exponential moving averages

//--- Event handling functions

   // Initialisation event handler
      int OnInit(void) {
         // Validate input parameters
            MCheckParameter( i_nSummationPeriod < 1,                  "summation period" );
            MCheckParameter( i_nAveragingPeriod < 1 ||
                             i_nAveragingPeriod > i_nSummationPeriod, "averaging period" );

         // Calculate parameter variables
            g_dbEmaWeight = 2.0 / ( i_nAveragingPeriod + 1.0 );

         // Set number of significant digits (precision)
            IndicatorSetInteger( INDICATOR_DIGITS, _Digits );

         // Set buffers
            int iBuffer = 0;
            #ifdef __MQL4__
               IndicatorBuffers( MBuffers + 1 ); // Set total number of buffers (MQL4 Only)
               SetIndexBuffer( iBuffer++, g_adbSummationPositive,    INDICATOR_DATA         );
               SetIndexBuffer( iBuffer++, g_adbSummationNegative,    INDICATOR_DATA         );
            #else
               SetIndexBuffer( iBuffer++, g_adbSummation,            INDICATOR_DATA         );
               SetIndexBuffer( iBuffer++, g_adbSummationColour,      INDICATOR_COLOR_INDEX  );
            #endif
            SetIndexBuffer(    iBuffer++, g_adbAveragingSimple,      INDICATOR_DATA         );
            SetIndexBuffer(    iBuffer++, g_adbAveragingExponential, INDICATOR_DATA         );
            SetIndexBuffer(    iBuffer++, g_adbPriceApplied,         INDICATOR_CALCULATIONS );
            SetIndexBuffer(    iBuffer++, g_adbVolumePriceDelta,     INDICATOR_CALCULATIONS );
            SetIndexBuffer(    iBuffer++, g_adbSummationSimple,      INDICATOR_CALCULATIONS );
            #ifdef __MQL4__
               SetIndexBuffer( iBuffer++, g_adbSummation,            INDICATOR_CALCULATIONS );
            #endif

         // Set indicator name
            IndicatorSetString( INDICATOR_SHORTNAME, StringFormat(
               MName " ( %d, %d )", i_nSummationPeriod, i_nAveragingPeriod ) );

         return INIT_SUCCEEDED;  // Successful initialisation of indicator
      };

   // Calculation event handler
      int
         OnCalculate(
            const int      rates_total,
            const int      prev_calculated,
            const datetime &time[],
            const double   &open[],
            const double   &high[],
            const double   &low[],
            const double   &close[],
            const long     &tick_volume[],
            const long     &volume[],
            const int      &spread[]
         )
      {
         // Main loop — fill in the arrays with data values
            for( int iCur     = MOnCalcStart,
                     iPrev    = MOnCalcBack( iCur, 1                        ),
                     iSumPrev = MOnCalcBack( iCur, (int) i_nSummationPeriod ),
                     iAvgPrev = MOnCalcBack( iCur, (int) i_nAveragingPeriod );
                 !IsStopped() && MOnCalcCheck( iCur );
                 MOnCalcNext( iCur ), MOnCalcNext( iPrev ), MOnCalcNext( iSumPrev ), MOnCalcNext( iAvgPrev ) )
            {
               // Calculate volume to apply
                  double dbVolume = 1.0;
                  switch( i_eVolumeWeight ) {
                     #ifndef __MQL4__
                        case EVW_RealVolume: dbVolume = (double) volume[      iCur ]; break;
                     #endif
                     case EVW_TickVolume:    dbVolume = (double) tick_volume[ iCur ]; break;
                     case EVW_PriceRange:    if( MOnCalcValid( iPrev ) ) {
                                                double dbClosePrev = close[ iPrev ];
                                                       dbVolume    = fmax( high[ iCur ], dbClosePrev )
                                                                   - fmin( low[  iCur ], dbClosePrev );
                                             } else    dbVolume    = high[ iCur ] - low[ iCur ];
                  };

               // Calculate price to apply
                  double dbPriceCur;
                  MSetAppliedPrice( i_ePriceApplied, dbPriceCur, iCur );

               // Calculate volume weighted price delta and sum
                  double dbPricePrev            = MOnCalcValid( iPrev ) ? g_adbPriceApplied [ iPrev ] : open[ iCur ],
                         dbPriceDelta           = dbPriceCur - dbPricePrev,
                         dbVolumePriceDelta     = dbPriceDelta * dbVolume,
                         dbSummation            = dbVolumePriceDelta
                                                + ( MOnCalcValid( iPrev    ) ? g_adbSummation[        iPrev    ] : 0.0 )
                                                - ( MOnCalcValid( iSumPrev ) ? g_adbVolumePriceDelta[ iSumPrev ] : 0.0 );
               // Define colourasation
                  #ifdef __MQL4__
                     double dbSummationPositive = dbSummation > 0.0 ? dbSummation : 0.0,
                            dbSummationNegative = dbSummation < 0.0 ? dbSummation : 0.0;
                  #else
                     double dbSummationColour   =   dbSummation > 0.0 ? MIdxCandleUp
                                                : ( dbSummation < 0.0 ? MIdxCandleDown
                                                :                       MIdxCandleNone );
                  #endif

               // Calculate simple summation and averaging
                  double dbSumSimpleCur        = dbSummation
                                               + ( MOnCalcValid( iPrev    ) ? g_adbSummationSimple[ iPrev    ] : 0.0 )
                                               - ( MOnCalcValid( iAvgPrev ) ? g_adbSummation[       iAvgPrev ] : 0.0 ),
                         dbAverageSimpleCur    = dbSumSimpleCur / i_nAveragingPeriod;

               // Calculate exponential averaging
                  double dbAverageExponentialPrev = MOnCalcValid( iPrev ) ? g_adbAveragingExponential[ iPrev ] : dbSummation,
                         dbAverageExponentialCur  = dbAverageExponentialPrev
                                                   + ( dbSummation - dbAverageExponentialPrev )
                                                   * g_dbEmaWeight;

               // Set buffer values
                  g_adbPriceApplied[         iCur ] = dbPriceCur;
                  g_adbVolumePriceDelta[     iCur ] = dbVolumePriceDelta;
                  g_adbSummation[            iCur ] = dbSummation;
                  g_adbSummationSimple[      iCur ] = dbSumSimpleCur;
                  g_adbAveragingSimple[      iCur ] = dbAverageSimpleCur;
                  g_adbAveragingExponential[ iCur ] = dbAverageExponentialCur;
                  #ifdef __MQL4__
                     g_adbSummationPositive[ iCur ] = dbSummationPositive;
                     g_adbSummationNegative[ iCur ] = dbSummationNegative;
                  #else
                     g_adbSummationColour[   iCur ] = dbSummationColour;
                  #endif
            };

         return rates_total;  // Return value for prev_calculated of next call
      };

//---------------------------------------------------------------------------------------------------------------------
