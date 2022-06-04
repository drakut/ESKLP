/// Временный класс для сохранения номенклатуры Трансмашхолдинга и Локотех
Class App.MAF.Nomen Extends (%Persistent, Lib.Abstract.StorableTables)
{

Parameter XMLTYPE = "App-MAF-Nomen";

/// Код
Property Code As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Наименование
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Код СКМТР
Property CodeSKMTR As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Код АМТО
Property CodeAMTO As Lib.DataTypes.String(IndexSpecWord = 1, MAXLEN = 1024);

/// Группа
Property Group As Lib.DataTypes.String(IndexSpecWord = 1, MAXLEN = 1024);

/// Подгруппа
Property Subgroup As Lib.DataTypes.String(IndexSpecWord = 1, MAXLEN = 1024);

/// Вид
Property Kind As Lib.DataTypes.String(IndexSpecWord = 1, MAXLEN = 1024);

/// Коэфициент совпадения с лучшим кандидатом
Property Similarity As Lib.DataTypes.Double(IndexSpecWord = 1);

/// Назначенная позиция СКМТР
Property SKMTRNomen As App.MAF.SKMTRNomen;

/// SpecName
Property SpecName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index CodeSKMTR On CodeSKMTR As Truncate(200) [ Type = bitmap ];

Index CodeAMTO On CodeAMTO As Truncate(200) [ Type = bitmap ];

Index Group On Group As Truncate(200) [ Type = bitmap ];

Index Subgroup On Subgroup As Truncate(200) [ Type = bitmap ];

Index Kind On Kind As Truncate(200) [ Type = bitmap ];

Index Similarity On Similarity As Truncate(200) [ Type = bitmap ];

Index SpecName On SpecName As Truncate(200) [ Type = bitmap ];

/// Kalinin A.M.
/// Метод формирования описания для поиска и сравнения
/// !!! НЕ УДАЛЯТЬ !!!
/// s n=##class(App.MAK.Nomen).%OpenId(4792)  d n.setSpecName()
Method setSpecName()
{
	try {
		s err = ""
		
		s specName = ..Name
		
		s specName = $ZCVT(specName,"L")
		
		s specName = $ZSTRIP(specName,"=W")
		;w !,specName
		
		s matcher = ##class(%Regex.Matcher).%New("(?<=\D)\.(?=\d)",specName)
		s specName = matcher.ReplaceAll(". ") 								; сокращения с точками отделяем пробелами от чисел, "шамп.280 Пит.,укреп." => "шамп. 280 Пит.,укреп."
		;w !,specName
		
		;s specName = ##class(App.SPR.Synonym).OriginaliseStringV3(specName)	; Замена синонимов оригиналами
		;w !,specName
		
		s out = {}
		s ..SpecName = ##class(App.MAF.Linker).DeleteDublicateWords(specName, out) ; удаление повторяющихся пробелов
		;w !,..SpecName
		
		d ..%Save()
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		w err
	}
	q err
}

/// Установка специального наименования для поиска у всех позиций
/// d ##class(App.MAF.Nomen).SetAllSpecName()
ClassMethod SetAllSpecName()
{
	s ts1 = $ZTS
	s id = ""
	&SQL(DECLARE cur CURSOR FOR
		SELECT id INTO :id
		FROM App_MAF.Nomen
		--WHERE name IS NOT NULL
		)
	&SQL(OPEN cur)
	while (SQLCODE=0){
		&SQL(FETCH cur)
		w !,id
		s nomen = ..%OpenId(id)
		i $ISO(nomen) {
			d nomen.setSpecName()
			w $C(9),nomen.SpecName
		}
		else {
			w "No object"
		}
	}
	&SQL(CLOSE cur)
	
	s ts2 = $ZTS
	w !,"Time elapsed:", ##class(Lib.Util.DateTime).DeltaMS(ts1,ts2)
}

ClassMethod OpenCode(Code As %String)
{
	s res = ""
	i Code'="" {
		s ptr=""
		s status = ..indNEXT(["Code-v",(Code)],.ptr,.id) 
		s:id'="" res = ..%OpenId(id)
	}
	q res
}

Storage Default
{
<Data name="NomenDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Vers</Value>
</Value>
<Value name="3">
<Value>SourceSys</Value>
</Value>
<Value name="4">
<Value>GUID</Value>
</Value>
<Value name="5">
<Value>Code</Value>
</Value>
<Value name="6">
<Value>Name</Value>
</Value>
<Value name="7">
<Value>CodeSKMTR</Value>
</Value>
<Value name="8">
<Value>CodeAMTO</Value>
</Value>
<Value name="9">
<Value>Group</Value>
</Value>
<Value name="10">
<Value>Subgroup</Value>
</Value>
<Value name="11">
<Value>Kind</Value>
</Value>
<Value name="12">
<Value>Similarity</Value>
</Value>
<Value name="13">
<Value>SKMTRNomen</Value>
</Value>
<Value name="14">
<Value>SpecName</Value>
</Value>
</Data>
<DataLocation>^App.MAF.NomenD</DataLocation>
<DefaultData>NomenDefaultData</DefaultData>
<IdLocation>^App.MAF.NomenD</IdLocation>
<IndexLocation>^App.MAF.NomenI</IndexLocation>
<StreamLocation>^App.MAF.NomenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

