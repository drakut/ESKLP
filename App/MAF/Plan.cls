/// План (набор метрик) сравнения строк
Class App.MAF.Plan Extends (%Persistent, Lib.Abstract.StorableTables)
{

Parameter XMLTYPE = "App-MAF-Plan";

/// Создание одного метода по умолчанию
/// d ##class(App.MAF.Plan).Init()
ClassMethod Init()
{
	s plan = ..%New()
	s plan.Name = "Default"
	d plan.%Save()
}

/// d ##class(App.MAF.Plan).UpdateMetricsWeights(1,arr,0.1,84)
ClassMethod UpdateMetricsWeights(planId, arrCoef, numIntercept, numScore)
{
	try {
		s planId = $G(planId, "")
		s plan = ##class(App.MAF.Plan).%OpenId(planId)
		i '$ISO(plan) {
			s status = $$$ERROR("No plan with id:"_palnId)
			q
		}
		
		s plan.Intercept = numIntercept
		s plan.Score = numScore
		s status = plan.%Save() q:$$$ISERR(status)
		
		s:'$ISO(arrCoef) arrCoef = [].%FromJSON(arrCoef)
		s query = 	"SELECT m.id AS metricId, "_
					"	link.id AS linkId, "_
					"	link.Order AS Ord "_
					"FROM App_MAF.Plan plan "_
					"LEFT JOIN app_maf.PlanMetric link ON plan.id = link.plan "_
					"LEFT JOIN app_maf.Metric m ON link.Metric = m.id "_
					"WHERE plan.id = "_planId_
					" AND link.active = 1 "_
					" ORDER BY Ord"
		s statement	= ##class(%SQL.Statement).%New()
		s statement.%SelectMode = 1
		s status = statement.%Prepare(query) q:$$$ISERR(status)
		s resultSet = statement.%Execute() q:$$$ISERR(status)
		while resultSet.%Next() {
			s weight = 1
			s metricId = resultSet.%Get("metricId")
			s linkId = resultSet.%Get("linkId")
			s metric = ##class(App.MAF.Metric).%OpenId(metricId)
			s link = ##class(App.MAF.PlanMetric).%OpenId(linkId)
			
			s:metric.Name="Country" weight=arrCoef.%Get(0)
			s:metric.Name="Decimal" weight=arrCoef.%Get(1)
			s:metric.Name="LekForm" weight=arrCoef.%Get(2)
			s:metric.Name="ManufName" weight=arrCoef.%Get(3)
			s:metric.Name="N-gramm" weight=arrCoef.%Get(4)
			s:metric.Name="Nomer" weight=arrCoef.%Get(5)
			s:metric.Name="ProdName" weight=arrCoef.%Get(6)
			s:metric.Name="Simber" weight=arrCoef.%Get(7)
			s:metric.Name="Translit" weight=arrCoef.%Get(8)
			s:metric.Name="Trigram" weight=arrCoef.%Get(9)
			s weight = weight/100
			
			s link.Weight = weight
			s status = link.%Save()
			q:$$$ISERR(status)
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err)
	}
	q status
}

/// d ##class(App.MAF.Plan).ResetMetricsWeights(1)
ClassMethod ResetMetricsWeights(planId)
{
	try {
		s planId = $G(planId, "")
		s plan = ##class(App.MAF.Plan).%OpenId(planId)
		i '$ISO(plan) {
			s status = $$$ERROR("No plan with id:"_palnId)
			q
		}
		
		s query = 	"SELECT m.id AS metricId, "_
					"	link.id AS linkId, "_
					"	link.Order AS Ord "_
					"FROM App_MAF.Plan plan "_
					"LEFT JOIN app_maf.PlanMetric link ON plan.id = link.plan "_
					"LEFT JOIN app_maf.Metric m ON link.Metric = m.id "_
					"WHERE plan.id = "_planId_
					" AND link.active = 1 "_
					" ORDER BY Ord"
		s statement	= ##class(%SQL.Statement).%New()
		s statement.%SelectMode = 1
		s status = statement.%Prepare(query) q:$$$ISERR(status)
		s resultSet = statement.%Execute() q:$$$ISERR(status)
		while resultSet.%Next() {
			s weight = 1
			
			s linkId = resultSet.%Get("linkId")
			s link = ##class(App.MAF.PlanMetric).%OpenId(linkId)
			
			s link.Weight = weight
			s status = link.%Save()

			q:$$$ISERR(status)
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err)
	}
	q status
}

Storage Default
{
<Data name="PlanDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Vers</Value>
</Value>
<Value name="4">
<Value>SourceSys</Value>
</Value>
<Value name="5">
<Value>GUID</Value>
</Value>
<Value name="6">
<Value>Description</Value>
</Value>
<Value name="7">
<Value>MinCoef</Value>
</Value>
<Value name="8">
<Value>Intercept</Value>
</Value>
<Value name="9">
<Value>Score</Value>
</Value>
</Data>
<DataLocation>^App.MAF.PlanD</DataLocation>
<DefaultData>PlanDefaultData</DefaultData>
<IdLocation>^App.MAF.PlanD</IdLocation>
<IndexLocation>^App.MAF.PlanI</IndexLocation>
<StreamLocation>^App.MAF.PlanS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Описание
Property Description As Lib.DataTypes.String(MAXLEN = 30000);

/// Интерсепт
Property Intercept As Lib.DataTypes.Double;

/// Минимальный коэффициент для автоматического связывания
Property MinCoef As Lib.DataTypes.Double;

/// Наименование 
Property Name As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Точность модели
Property Score As Lib.DataTypes.Double;

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

}

