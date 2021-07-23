Application demonstrates using Python and InterSystems IRIS to resolve
linear regression in task of checking similarity of two text strings. Strings contain descriptions of some goods.

**Problem**: To get an analogue of directory B for the nomenclature of
directory A automatically. For example, price list of some pharmacy
company and some dictionary, Like ESKLP (federal single structured
reference directory of drugs in Russia).

This example is available at https://paramon.esc.ru/csp/maf/index.html
in guest mode (Choose: Инструменты / Распознавание )

![](media/image1.png){width="6.496527777777778in"
height="5.045138888888889in"}

**Input data**:

1.  Price list (left part on screen),

2.  Some dictionary (ESKLP for example)

3.  Sorted by similarity candidates from ESKLP for every string from
    price list: many candidates to one position from price list.

4.  Information about every pair "Price list -- candidate ESKLP"

Similarity is a classic linear regression function, where we calculate
metrics values from two strings, and if the full value of function is
the same more, then minimum we want -- then we can say that positions
are the same.

Metrics:

1.  Country - similarity of Country;

2.  Decimal - similarity of two number list, especially prepared;

3.  LekForm - similarity of dosage form, especially prepared;

4.  ManufName - similarity of manufacturer\'s name;

5.  Ngramm - similarity of two strings by n-gramm method;

6.  Nomer - similarity of tablet\'s count in pack;

7.  ProdName - similarity of production name;

8.  Simber - similarity of two number list, especially prepared;

9.  Translit - similarity of two strings in translit;

10. Trigram - similarity of two strings in translit by n-gramm method;

11. BarcodeSimilarity (new) - similarity of two strings that contain (o not) barcodes$

Some of these metrics getting-values-methods are shown in
App.MAF.Metric.

Information about every pair: is collected in App_MAF.LinkML, it
contains:

1.  Code from organization's nomenclature dictionary

2.  ESKLP-code (federal single structured reference directory of drugs
    in Russia)

3.  Similarity value

4.  Each of metric values.

5.  Every link marked by human - if this link right or not.

At start all weights of all metrics = 1. And for example from print
screen (code = 3045_1 )the final value of candidates are 96.38 and 95.5.
The second candidate (95.5) is wrong, but the difference is not very
big.

**Solution**

Get weights of all metrics, because some of them are not so effective to
make our choice: if string from our organization's dictionary and string
from ESKLP are the same or not. And when we will compare another
organization's nomenclature, there will be much less error.

1.  Reset coefficients: in terminal d ##class(App.MAF.Plan).ResetMetricsWeights(1)

2.  Start production: ( Interoperability \> Configure \> Production
    Configuration \> Category: Match)\
    ml.match.RgrCoefProcess -\>Start button

3.  Test Production: ml.match.RgrCoefProcess \> Actions \> Test button

4.  Choose "Ens.Request" in Request Type and press button "Invoke Testing Service". Please wait for finish.

5.  Get result, see column "weight": (IRIS-Management Portal: System \>
    SQL)

SELECT m.id AS metricId, link.weight, link.id AS linkId, link.Order AS
Ord FROM App_MAF.Plan plan LEFT JOIN app_maf.PlanMetric link ON plan.id
= link.plan RIGHT JOIN app_maf.Metric m ON link.Metric = m.id WHERE
plan.id = 1 AND link.active = 1 ORDER BY Ord

Now we have anover values of weight for every metric. Why it's good: one metric began to express the similarity of strings more than another, and we could see another values of similarity function for different types of goods. For example - barcode for computer goods is less important, than for medicaments, and weight for BarcodeSimilarity metric when checking computer goods must be less then value for it's metric, when we check similarity of two strings containig description of medicaments goods.
So, we could save different plans of checking similarity for different types of goods.


(In web-example Choose Plan **Лексредства V2** in Options)
