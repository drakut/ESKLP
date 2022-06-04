/// Связь плана сравнения и метрик
Class App.MAF.PlanMetric Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

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

/// Связка активная или не активная
Property Active As Lib.DataTypes.Boolean(IndexValue = 1);

/// Метрика
Property Metric As App.MAF.Metric [ Required ];

/// Порядок вычисления
Property Order As Lib.DataTypes.Integer(IndexValue = 1);

/// План сравнения
Property Plan As App.MAF.Plan;

/// Учитывать метрику даже если значения не найдены
Property Strong As Lib.DataTypes.Boolean(IndexValue = 1);

/// Использовать результат для ключевых слов
Property UseInKeywords As Lib.DataTypes.String(DISPLAYLIST = ",Все значения,Самое короткое значение,Самое длинное значение,Не использовать", IndexValue = 1, MAXLEN = 100, VALUELIST = ",all,shortest,longest,no");

/// Вес метрики
Property Weight As Lib.DataTypes.Double [ Required ];

ForeignKey fkMetric(Metric) References App.MAF.Metric();

ForeignKey fkPlan(Plan) References App.MAF.Plan();

Index Active On Active [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Metric On Metric [ Type = bitmap ];

Index Order On Order [ Type = bitmap ];

Index Plan On Plan [ Type = bitmap ];

Index Strong On Strong [ Type = bitmap ];

Index UseInKeywords On UseInKeywords As Truncate(200) [ Type = bitmap ];

Parameter XMLTYPE = "App-MAF-PlanMetric";

}

