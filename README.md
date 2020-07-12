Application demonstrates using Python and Intersystems IRIS to resolve linear regression in task of checking similarity of two text strings


Input data:
Link table (all candidates for all positions of resource dictionary) App_MAF.LinkML, contain 2 codes from some organization nomeclature dictionary and ESKLP-code (federal single structured reference directory of drugs in Russia) and some information about these pair, such as full-coefficient value and each of metrics-coefficients values of two strings similarity. Every link marked by human - if this link right or not.

Metrics: 
Country   - similarity of Country;
Decimal   - similarity of two number list, especially prepared;
LekForm   - similarity of dosage form, especially prepared;
ManufName - similarity of manufacturer's name;
Ngramm	  - similarity of two strings by n-gramm method;
Nomer     - similaruty of tablet's count in pack;
ProdName  - similaruty of production name;
Simber    - similarity of two number list, especially prepared; 
Translit  - similarity of two strings in translit;
Trigram   - similarity of two strings in translit by n-gramm method;

So we need to get weights of all metrics, because some of them are not so effective to make our choice: if string from our organisation's dictionary and string from ESKLP are the same or not. And when we will compare another organisation's nomenclature, there wil be much less error.

1) Reset coefficients (IRIS-Management Portal:  System > SQL)
update App_maf.PlanMetric set weight=1

2) Start production: ( Interoperability > Production Configuration)


3) Get result, colunm weight: (IRIS-Management Portal:  System > SQL)

SELECT 
  m.id AS metricId, 
  link.weight,
  link.id AS linkId, 
  link.Order AS Ord 
FROM 
  App_MAF.Plan plan 
  LEFT JOIN app_maf.PlanMetric link ON plan.id = link.plan 
  RIGHT JOIN app_maf.Metric m ON link.Metric = m.id 
WHERE 
  plan.id = 1
  AND link.active = 1 
ORDER BY 
  Ord
