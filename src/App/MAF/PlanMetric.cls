/// Связь плана сравнения и метрик
Class App.MAF.PlanMetric Extends %Persistent
{

/// План сравнения
Property Plan As App.MAF.Plan;

/// Метрика
Property Metric As App.MAF.Metric [ Required ];

/// Связка активная или не активная
Property Active As %Library.Boolean;

/// Вес метрики
Property Weight As %Library.Double [ Required ];

/// Использовать результат для ключевых слов
Property UseInKeywords As %Library.String(DISPLAYLIST = ",Все значения,Самое короткое значение,Самое длинное значение,Не использовать", MAXLEN = 100, VALUELIST = ",all,shortest,longest,no");

/// Порядок вычисления
Property Order As %Library.Integer;

/// Учитывать метрику даже если значения не найдены
Property Strong As %Library.Boolean;

Index Active On Active;

Parameter XMLTYPE = "App-MAF-PlanMetric";

Storage Default
{
<Data name="PlanMetricDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Plan</Value>
</Value>
<Value name="3">
<Value>Metric</Value>
</Value>
<Value name="4">
<Value>Active</Value>
</Value>
<Value name="5">
<Value>Vers</Value>
</Value>
<Value name="6">
<Value>SourceSys</Value>
</Value>
<Value name="7">
<Value>GUID</Value>
</Value>
<Value name="8">
<Value>Weight</Value>
</Value>
<Value name="9">
<Value>UseInKeywords</Value>
</Value>
<Value name="10">
<Value>Order</Value>
</Value>
<Value name="11">
<Value>Strong</Value>
</Value>
</Data>
<DataLocation>^App.MAF.PlanMetricD</DataLocation>
<DefaultData>PlanMetricDefaultData</DefaultData>
<IdLocation>^App.MAF.PlanMetricD</IdLocation>
<IndexLocation>^App.MAF.PlanMetricI</IndexLocation>
<StreamLocation>^App.MAF.PlanMetricS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

