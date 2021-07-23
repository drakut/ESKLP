/// План (набор метрик) сравнения строк
Class App.MAF.Plan Extends %Persistent
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

/// Обработка ошибки
ClassMethod ErrorDetect(ByRef exp) As %String
{
	s err=""
	if exp.Code'=999{
		d exp.Log()
		if exp.Name["<PROTECT>" {s err="У пользователя "_$USERNAME_" нет прав на создание, изменение, удаление данных."}
		elseif exp.%IsA("%Exception.SystemException") {s err="Ошибка : "_$ZCVT(exp.Name,"O","HTML")_". Адрес : "_exp.Location_". Код : "}
		elseif exp.%IsA("%Exception.SQL") {s err="Ошибка SQL. Код : "}
		elseif exp.%IsA("%Exception.StatusException") {s err="Статус : "_$SYSTEM.Status.DisplayError($SYSTEM.Status.Error(exp.Code,exp.Data)) return}
		elseif exp.%IsA("%Exception.General") {s err="Глобальная ошибка : "_$ZCVT(exp.Name,"O","HTML")_". Код : "}
		else {s err="Неизвестная ошибка." return}
		//s st=$STACK($ST,"PLACE")
		//s st="" for i=0:1:$STACK(-1) {s st=st_$STACK(i,"PLACE")_", "}
		s:exp.Name'["<PROTECT>" err=err_exp.Code_". Строка : "_exp.Data //_". Стек : <br>"_st
	}
	else{s err=exp.Data}
	q err
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
					"RIGHT JOIN app_maf.Metric m ON link.Metric = m.id "_
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
			s:metric.Name="BarcodeSimilarity" weight=arrCoef.%Get(10) 
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
<Value>Description</Value>
</Value>
<Value name="3">
<Value>Intercept</Value>
</Value>
<Value name="4">
<Value>MinCoef</Value>
</Value>
<Value name="5">
<Value>Name</Value>
</Value>
<Value name="6">
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
Property Description As %Library.String(MAXLEN = 30000);

/// Интерсепт
Property Intercept As %Library.Double;

/// Минимальный коэффициент для автоматического связывания
Property MinCoef As %Library.Double;

/// Наименование 
Property Name As %Library.String(MAXLEN = 1024);

/// Точность модели
Property Score As %Library.Double;

Index Name On Name As Truncate(200) [ Type = bitmap ];

}
