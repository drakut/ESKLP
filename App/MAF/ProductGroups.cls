/// Группы товаров СКМТР
Class App.MAF.ProductGroups Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

Parameter XMLTYPE = "App-MAF-ProductGroups";

Storage Default
{
<Data name="ProductGroupsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Code</Value>
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
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^App.MAF.ProductGroupsD</DataLocation>
<DefaultData>ProductGroupsDefaultData</DefaultData>
<IdLocation>^App.MAF.ProductGroupsD</IdLocation>
<IndexLocation>^App.MAF.ProductGroupsI</IndexLocation>
<StreamLocation>^App.MAF.ProductGroupsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

