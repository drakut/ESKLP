/// Класс различных метрик для стравнения строк и т.д.
Class App.MAF.Metric Extends %Persistent
{

/// Наименование метрики
Property Name As %Library.String(MAXLEN = 1024);

/// Описание метрики
Property Description As %Library.String(MAXLEN = 1024);

/// Наименование метода для обработки
Property MethodName As %Library.String(MAXLEN = 1024);

/// Параметры выполнения метода, массив JSON
Property Params As %Library.String(MAXLEN = 32000);

/// Класс таблицы словаря
Property DictClassName As %Library.String(MAXLEN = 1024);

/// Поле таблицы словаря со значением
Property DictFieldName As %Library.String(MAXLEN = 1024);

/// Вес метрики
Property Weight As %Library.Double;

Index Description On Description As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200);

Parameter XMLTYPE = "App-MAF-Metric";

Storage Default
{
<Data name="MetricDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Vers</Value>
</Value>
<Value name="5">
<Value>GUID</Value>
</Value>
<Value name="6">
<Value>MethodName</Value>
</Value>
<Value name="7">
<Value>DictClassName</Value>
</Value>
<Value name="8">
<Value>DictFieldName</Value>
</Value>
<Value name="9">
<Value>SourseSys</Value>
</Value>
<Value name="10">
<Value>SourceSys</Value>
</Value>
<Value name="11">
<Value>Weight</Value>
</Value>
<Value name="12">
<Value>Params</Value>
</Value>
</Data>
<DataLocation>^App.MAF.MetricD</DataLocation>
<DefaultData>MetricDefaultData</DefaultData>
<IdLocation>^App.MAF.MetricD</IdLocation>
<IndexLocation>^App.MAF.MetricI</IndexLocation>
<StreamLocation>^App.MAF.MetricS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

