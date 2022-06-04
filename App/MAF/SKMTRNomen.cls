/// Номенклатура СКМТР
Class App.MAF.SKMTRNomen Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Код СКМТР
Property Code As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Наименование
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Марка, № чертежа
Property Mark As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// ГОСТ, ТУ
Property NormDoc As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Сорт, размер
Property Sort As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Код единицы измерения
Property EI As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Дополнительно
Property Comment As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Кр. Наименование
Property ShName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// СИЗ
Property SIZ As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Товарная группировка
Property Group As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// ОКПД2
Property OKPD2 As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// SpecName
Property SpecName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Флаг актуальной позиции - не содержит в начале наименования символов:
/// @	- неактуальная
/// #1	- архивная
/// &	- ошибочная
/// #	- снято с производства
Property Active As Lib.DataTypes.Boolean(IndexValue = 1);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index Mark On Mark As Truncate(200) [ Type = bitmap ];

Index NormDoc On NormDoc As Truncate(200) [ Type = bitmap ];

Index Sort On Sort As Truncate(200) [ Type = bitmap ];

Index EI On EI As Truncate(200) [ Type = bitmap ];

Index Group On Group As Truncate(200) [ Type = bitmap ];

Index OKPD2 On OKPD2 As Truncate(200) [ Type = bitmap ];

Index Comment On Comment As Truncate(200) [ Type = bitmap ];

Index SpecName On SpecName As Truncate(200) [ Type = bitmap ];

Index Active On Active [ Type = bitmap ];

Parameter XMLTYPE = "App-MAF-SKMTRNomen";

/// Kalinin A.M.
/// Метод формирования описания для поиска и сравнения
/// !!! НЕ УДАЛЯТЬ !!!
/// s n=##class(App.MAK.Nomen).%OpenId(4792)  d n.setSpecName()
Method setSpecName()
{
	try {
		s err = ""
		
		s specName = ..Name_" "_..Code_" "_..Mark_" "_..NormDoc_" "_..Sort
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
/// d ##class(App.MAF.SKMTRNomen).SetAllSpecName()
ClassMethod SetAllSpecName()
{
	s ts1 = $ZTS
	s id = ""
	&SQL(DECLARE cur CURSOR FOR
		SELECT id INTO :id
		FROM App_MAF.SKMTRNomen
		WHERE specname IS NOT NULL
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

/// Выставление флага активности
/// d ##class(App.MAF.SKMTRNomen).ReActivate()
ClassMethod ReActivate()
{
	s id = ""
	&SQL(DECLARE cur2 CURSOR FOR
		SELECT id INTO :id
		FROM App_MAF.SKMTRNomen
		WHERE specname IS NOT NULL
		order by id desc
		)
	&SQL(OPEN cur2)
	while (SQLCODE=0){
		&SQL(FETCH cur2)
		w !,id
		s nomen = ..%OpenId(id)
		s first3symbols = $E(nomen.Name,1,3)
		i (first3symbols["@") ! (first3symbols["#") ! (first3symbols["&") {
			s nomen.Active = 0
		}
		else {
			s nomen.Active = 1
		}
		w $c(9),nomen.Active,$c(9),nomen.Name
		d nomen.%Save()
	}
	&SQL(CLOSE cur2)
}

Storage Default
{
<Data name="SKMTRNomenDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Code</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Mark</Value>
</Value>
<Value name="5">
<Value>NormDoc</Value>
</Value>
<Value name="6">
<Value>Sort</Value>
</Value>
<Value name="7">
<Value>EI</Value>
</Value>
<Value name="8">
<Value>Comment</Value>
</Value>
<Value name="9">
<Value>ShName</Value>
</Value>
<Value name="10">
<Value>SIZ</Value>
</Value>
<Value name="11">
<Value>Group</Value>
</Value>
<Value name="12">
<Value>OKPD2</Value>
</Value>
<Value name="13">
<Value>SourceSys</Value>
</Value>
<Value name="14">
<Value>GUID</Value>
</Value>
<Value name="15">
<Value>Vers</Value>
</Value>
<Value name="16">
<Value>SpecName</Value>
</Value>
<Value name="17">
<Value>Active</Value>
</Value>
</Data>
<DataLocation>^App.MAF.SKMTRNomenD</DataLocation>
<DefaultData>SKMTRNomenDefaultData</DefaultData>
<IdLocation>^App.MAF.SKMTRNomenD</IdLocation>
<IndexLocation>^App.MAF.SKMTRNomenI</IndexLocation>
<StreamLocation>^App.MAF.SKMTRNomenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

