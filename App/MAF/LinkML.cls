Class App.MAF.LinkML Extends %Persistent
{

/// Код связки
Property Code As %Library.String(MAXLEN = 1024);

/// Код левой стороны
Property CodeLeft As %Library.String(MAXLEN = 1024);

/// Код правой стороны
Property CodeRight As %Library.String(MAXLEN = 1024);

/// Общий коэфициент сходимости
Property CommonValue As %Library.Double;

/// Признак установленной связи для номенклатуры и аналога
Property Linked As %Library.Boolean;

/// Пометка связки верная, исправленная, неверно
Property Mark As %Library.String(DISPLAYLIST = ",верно,исправлено,неверно,импорт", VALUELIST = ",right,fixed,wrong,import");

/// План (метод), по которому проводилось сравнение
Property Plan As App.MAF.Plan [ Required ];

/// Признак установленной связи для номенклатуры и аналога на основе логистической регрессии
Property LinkedLogReg As %Library.Boolean;

Property Simber As %Library.Double;

Property Ngramm As %Library.Double;

Property ProdName As %Library.Double;

Property ManufName As %Library.Double;

Property Nomer As %Library.Double;

Property Decimal As %Library.Double;

Property Translit As %Library.Double;

Property Trigram As %Library.Double;

Property LekForm As %Library.Double;

Property Country As %Library.Double;

Property BarcodeSimilarity As %Library.Double;

Index CodeLeft On CodeLeft As Truncate(200) [ Type = bitmap ];

Index CodeRight On CodeRight As Truncate(200) [ Type = bitmap ];

Index CommonValue On CommonValue [ Type = bitmap ];

Index Linked On Linked [ Type = bitmap ];

Index Mark On Mark [ Type = bitmap ];

ForeignKey fkPlan(Plan) References App.MAF.Plan();

Parameter XMLTYPE = "App-MAF-LinkML";

Storage Default
{
<Data name="LinkMLDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Code</Value>
</Value>
<Value name="3">
<Value>CodeLeft</Value>
</Value>
<Value name="4">
<Value>CodeRight</Value>
</Value>
<Value name="5">
<Value>CommonValue</Value>
</Value>
<Value name="6">
<Value>Linked</Value>
</Value>
<Value name="7">
<Value>Mark</Value>
</Value>
<Value name="8">
<Value>Plan</Value>
</Value>
<Value name="9">
<Value>Simber</Value>
</Value>
<Value name="10">
<Value>Ngramm</Value>
</Value>
<Value name="11">
<Value>ProdName</Value>
</Value>
<Value name="12">
<Value>ManufName</Value>
</Value>
<Value name="13">
<Value>Nomer</Value>
</Value>
<Value name="14">
<Value>Decimal</Value>
</Value>
<Value name="15">
<Value>Translit</Value>
</Value>
<Value name="16">
<Value>Trigram</Value>
</Value>
<Value name="17">
<Value>LekForm</Value>
</Value>
<Value name="18">
<Value>Country</Value>
</Value>
<Value name="19">
<Value>BarcodeSimilarity</Value>
</Value>
</Data>
<DataLocation>^App.MAF.LinkMLD</DataLocation>
<DefaultData>LinkMLDefaultData</DefaultData>
<IdLocation>^App.MAF.LinkMLD</IdLocation>
<IndexLocation>^App.MAF.LinkMLI</IndexLocation>
<StreamLocation>^App.MAF.LinkMLS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

