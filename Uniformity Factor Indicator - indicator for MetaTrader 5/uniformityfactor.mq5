//+------------------------------------------------------------------+
//|                                             UniformityFactor.mq5 |
//|                                    Copyright (c) 2025, Marketeer |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright (c) 2025, Marketeer"
#property link        "https://www.mql5.com/en/users/marketeer"
#property description "Estimate an exponent/power factor for uniformity of price changes over distance."
#property version     "1.0"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrOrangeRed
#property indicator_width2  1

#property indicator_label1  "Stats"
#property indicator_label2  "Distance(0.bars)"

#include <Math/Stat/Math.mqh>

// inputs

enum METHOD
{
   variance,
   tripple_M,
   gini
};

input int Period = 200;
input double _Factor = 0; // Factor (0.0 ... 1.0)
input METHOD Method = variance;
input uint MaxBars = 0; // MaxBars (0 - all bars)
input bool Logarithm = false;

// globals

#define FACTOR_STEP_NUMBER 10
#define FACTOR_STEP_SIZE   0.1

const int BarNumScaleDown = 10; // squeeze bar numbering to keep main histogram prevailing (customize if necessary)

double Buffer1[], Buffer0[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   SetIndexBuffer(0, Buffer0, INDICATOR_DATA);
   SetIndexBuffer(1, Buffer1, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, Period);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + (int)MathRound(MathLog10(BarNumScaleDown)));
   IndicatorSetInteger(INDICATOR_LEVELS, 1);
   IndicatorSetInteger(INDICATOR_FIXED_MINIMUM, true);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0.0);
   IndicatorSetDouble(INDICATOR_MINIMUM, 0.0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double &price[])
{
   int limit;
   if(prev_calculated <= 0 || Period < 1)
   {
      ArrayInitialize(Buffer1, 0);
      ArraySetAsSeries(Buffer1, true);
      ArrayInitialize(Buffer0, 0);
      ArraySetAsSeries(Buffer0, true);
      limit = 0;
   }
   else
   {
      for(int i = prev_calculated; i < rates_total; i++)
      {
         Buffer1[i] = 0;
         Buffer0[i] = 0;
      }
      return rates_total;
   }
  
   if(limit < Period) limit = Period;
  
   const int N = (int)(MaxBars == 0 ? rates_total : fmin(rates_total, MaxBars));

   struct Moments
   {
      double factor;
      double mean;
      double variance;
      double skewness;
      double kurtosis;
      double median;
      double mode;
      double mmmse;
      double gini;
      Moments()
      {
         ZeroMemory(this);
      }
   };
   Moments m[FACTOR_STEP_NUMBER];

   // loop through different exponent/power factors and collect stats on bars
  
   for(int k = 1; k <= FACTOR_STEP_NUMBER; k++)
   {
      double Factor = _Factor != 0 ? fabs(_Factor) : FACTOR_STEP_SIZE * k;
      Comment(StringFormat("%.2f %.0f%%", Factor, k * (1.0 / FACTOR_STEP_SIZE)));

      ArrayInitialize(Buffer1, 0);
      ArrayInitialize(Buffer0, 0);
  
      for(int i = limit; i < N && !IsStopped(); i++)
      {
         for(int j = 0; j < Period; j++)
         {
            const double d = pow(j + 1, Factor);
            const double D = (price[i] - price[i - j - 1]) / d;
            Buffer1[j] += fabs(D);
            Buffer0[j]++;
         }
      }
     
      for(int j = 0; j < Period; j++)
      {
         if(Buffer0[j])
            Buffer0[j] = Buffer1[j] / Buffer0[j];
         Buffer1[j] = (j + 1) * _Point / BarNumScaleDown;
      }
      MathMoments(Buffer0, m[k - 1].mean, m[k - 1].variance, m[k - 1].skewness, m[k - 1].kurtosis, 0, Period);
      m[k - 1].factor = Factor;
      m[k - 1].median = MathMedianP(Buffer0, Period);
      m[k - 1].gini = MathGini(Buffer0, Period);
     
      double x[], probs[];
      MathProbabilityDensityEmpiricalP(Buffer0, 100, x, probs, Period);
      const int max = ArrayMaximum(probs);
      if(max > -1) m[k - 1].mode = x[max];
      // ArrayPrint(probs);
      if(_Factor != 0) break;
   }
  
   Comment("");
  
   // find most flat distribution and detect "optimal" step k
  
   double bestv[3] = {DBL_MAX, DBL_MAX, DBL_MAX};
   int bestk[3] = {};
   for(int k = 1; k <= FACTOR_STEP_NUMBER; k++)
   {
      if(m[k - 1].mean > 0)
      {
         if(m[k - 1].variance < bestv[variance])
         {
            bestv[variance] = m[k - 1].variance;
            bestk[variance] = k;
         }

         if(m[k - 1].gini < bestv[gini])
         {
            bestv[gini] = m[k - 1].gini;
            bestk[gini] = k;
         }
        
         double z = pow(m[k - 1].mean * m[k - 1].median * m[k - 1].mode, 1.0 / 3.0);
         double y = sqrt(pow(z - m[k - 1].mean, 2) + pow(z - m[k - 1].median, 2) + pow(z - m[k - 1].mode, 2));
         m[k - 1].mmmse = y;
         if(y < bestv[tripple_M])
         {
           bestv[tripple_M] = y;
           bestk[tripple_M] = k;
         }
      }
   }

   // print results in the log
  
   double Factor = _Factor != 0 ? fabs(_Factor) : bestk[Method] * FACTOR_STEP_SIZE;
   const static string star[2] = {"", "*"};
   const static string meth[3] = {"var", "mmm", "gini"};
  
   string title = "";
   for(int i = 0; i < 3; i++)
   {
      title += StringFormat(" %s(%.2g)%s", meth[i], bestk[i] * FACTOR_STEP_SIZE, star[Method == i]);
   }
  
   PrintFormat("%s %s, Max.Distance: %d, Bars: %d",
      _Symbol, StringSubstr(EnumToString(_Period), StringLen("PERIOD_")), Period, N);
   if(_Factor == 0) PrintFormat("Factor: %.3f, Result:%s", Factor, title);
   ArrayPrint(m, _Digits + 2, NULL, 0, _Factor != 0 ? 1 : WHOLE_ARRAY);
  
   // show results and best found (most uniform) distribution on the chart
  
   IndicatorSetString(INDICATOR_SHORTNAME, "Uniformity Factor:" +
      (_Factor != 0 ? " Selected=" + (string)_Factor : title));
   PlotIndexSetString(0, PLOT_LABEL, StringFormat("Avg.Pr.Ch./bar:f(%.2g)", Factor));

   ArrayInitialize(Buffer1, 0);
   ArrayInitialize(Buffer0, 0);
  
   for(int i = limit; i < N && !IsStopped(); i++)
   {
      for(int j = 0; j < Period; j++)
      {
         const double d = pow(j + 1, Factor);
         const double D = (price[i] - price[i - j - 1]) / d;
         Buffer1[j] += fabs(D);
         Buffer0[j]++;
      }
   }
  
   for(int j = 0; j < Period; j++)
   {
      if(Buffer0[j])
         Buffer0[j] = Buffer1[j] / Buffer0[j];
      Buffer1[j] = (j + 1) * _Point / BarNumScaleDown;
   }
  
   return N;
}

//+------------------------------------------------------------------+
//| Computes the median of the values in array[] or part s of it     |
//+------------------------------------------------------------------+
double MathMedianP(const double &array[], const int s = WHOLE_ARRAY)
{
   int size = s == WHOLE_ARRAY ? ArraySize(array) : s;
   // check data range
   if(size == 0) return(QNaN);
   // prepare sorted values
   double sorted_values[];
   if(ArrayCopy(sorted_values, array, 0, 0, size) != size) return(QNaN);
   ArraySort(sorted_values);
   // calculate median for odd and even cases
   // data_count=odd
   if(size % 2 == 1) return(sorted_values[size / 2]);
   // data_count=even
   return(0.5 * (sorted_values[(size - 1) / 2] + sorted_values[(size + 1) / 2]));
}

//+------------------------------------------------------------------+
//| MathProbabilityDensityEmpirical                                  |
//+------------------------------------------------------------------+
//| The function calculates the empirical probability density        |
//| function (pdf) for random values from array[].                   |
//|                                                                  |
//| Arguments:                                                       |
//| array[]  : Array with random values                              |
//| count    : Otput data count, total count pairs (x,pdf(x))        |
//| x[]      : Output array for x values                             |
//| pdf[]    : Output array for empirical pdf(x) values              |
//| s        : custom size of elements in array to process           |
//|                                                                  |
//| Return value: true if successful, otherwise false                |
//+------------------------------------------------------------------+
bool MathProbabilityDensityEmpiricalP(const double &array[], const int count,
   double &x[], double &pdf[], const int s = WHOLE_ARRAY)
{
   if(count <= 1) return(false);
   int size = s == WHOLE_ARRAY ? ArraySize(array) : s;
   if(size == 0) return(false);
   // check NaN values
   for(int i = 0; i < size; i++)
   {
      if(!MathIsValidNumber(array[i])) return(false);
   }
   // prepare output arrays
   if(ArraySize(x) < count)
      if(ArrayResize(x, count) != count)
         return(false);
   if(ArraySize(pdf) < count)
      if(ArrayResize(pdf,count) != count)
         return(false);
   // search for min,max and range
   double minv = array[0];
   double maxv = array[0];
   for(int i = 1; i < size; i++)
   {
      minv = MathMin(minv, array[i]);
      maxv = MathMax(maxv, array[i]);
   }
   double range = maxv - minv;
   if(range == 0) return(false);
   // calculate probability density of the empirical distribution
   for(int i = 0; i < count; i++)
   {
      x[i] = minv + i * range / (count - 1);
      pdf[i] = 0;
   }
   for(int i = 0; i < size; i++)
   {
      double v = (array[i] - minv) / range;
      int ind = int((v * (count - 1)));
      pdf[ind]++;
   }
   // normalize values
   double dx = range / count;
   double sum = 0;
   for(int i = 0; i < count; i++)
      sum += pdf[i] * dx;
   if(sum == 0) return(false);
   double coef = 1.0 / sum;
   for(int i = 0; i < count; i++)
   {
      pdf[i] *= coef;
   }
   return(true);
}

//+------------------------------------------------------------------+
//| Calculate Gini coefficient for values in array[] or part s of it |
//+------------------------------------------------------------------+
double MathGini(const double &array[], const int s = WHOLE_ARRAY)
{
   int size = s == WHOLE_ARRAY ? ArraySize(array) : s;
   if(size <= 0) return 0;
   double diff = 0, sum = 0;
   for(int i = 0; i < size; i++)
   {
      for(int j = 0; j < size; j++)
      {
         if(i != j) diff += fabs(array[i] - array[j]);
      }
      sum += array[i];
   }
   return diff / (2 * size * sum);
}
//+------------------------------------------------------------------+
