/// Перечень классификаторов продукции
Class App.NSI.Classif Extends (%Persistent, Lib.Abstract.StorableTablesCodeName) [ Inheritance = right, Not ProcedureBlock ]
{

/// Получить вычислимое поле
Method addCalcField(ByRef in, ByRef out)
{
	// На входе :
	//		   in.form -> Имя формы
	//		in.section -> Тип секции ("findpanel" - панель поиска, "grid" - таблица, "editpanel" - панель редактирования)
	//		  in.field -> Имя поля
	//		 ..ИмяПоля -> Поле из тела записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//		out.value -> Вычесленное значение
	// Примеры :
	//	s id=..%Id()
	//	s name=..Name			// Получить поле из Нового тела записи
	s err=""
	try {
		s out.value=""
		//          !!! Здесь писать свой код
        ;-- Для любых форм по таблице "App.NSI.Classif", где есть секция "grid" а в ней поля ...
		if (in.section="grid")
			{if (in.field="gridCntNomen")      {s out.value=..CntNomen()}     ; Кол-во КП на классификаторе
			}
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

/// Кол-во Кол-во номенклатуры на классификаторе
/// k  s obj=##class(App.NSI.Classif).%OpenId(2) w obj.CntNomen() w  ; Запуск из терминала
Method CntNomen() As %String
{
	try {
		s val=""
		s val=##class(App.DGS.RefClassif).indCOUNT(["idClassif-v",(..%Id())]) ; Количество записей App.DGS.RefClassif по idClassif
		s:val=0 val=""
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Вызов функции с клиента
ClassMethod addCallClient(ByRef in, ByRef out)
{
	// На входе :
	//		   in.form -> Имя формы
	//	   in.typecall -> Источник вызова ("toolbar" - кнопка на панели задач и т.д.)
	//	   in.namecall -> Имя действия (Для "toolbar" - имя кнопки и т.д.)
	//	   in.actualid -> ID текущей строки в форме
	//		 in.jobnum -> Номер задания для фоновых задач
	//		 in.filter -> фильтр для поиска
	//		   in.data -> Дополнительные данные для задачи (определяются клиентом)
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//	  out.typejob -> Метод исполнения задачи ("fast" - задача исполняется быстро, не в фоне, "job" - задача исполняется медленно, в фоне)
	//	  out.message -> Сообщение для клиента (выводится в модальном окне)
	// Примеры : (см. также в Lib.App.ImportError)
	// if (TotCnt<100) {s out.typejob="fast" d ..Process()}
	// else			   {s out.typejob="job"  j ..Process()}
	s err=""
	try {
		s out.error=""
		// !!! Здесь писать свой код
		;-- Запуск формирования ракурса Классификаторы по одной "App.NSI.Classif" из формы:"AppNSIClassif", секции:"Sec-Toolbar-Edit" по кнопке:"MakeRefClassif"
		if in.namecall="MakeRefClassif" 
		    {s out.typejob="job"		// Задача исполняется в фоне
			 s idClassif=in.actualid
			 ; Запуск в фоне формирования ракурса Классификаторы по одной "App.NSI.Classif". 
			 ; При запуске в фоне параметры передать через JSON-строку
			 i idClassif'="" j ##class(App.DGS.RefClassif).MakeAllRefClassif(in.%ToJSON())   
			 s out.refresh=1    ; Обновить экран после транзакции
		    }
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Может Быть родителем
Parameter CanParent = 0;

/// Виртуальный
Parameter Virtual = 0;

/// Дата ввода в действие
Property DateBeg As Lib.DataTypes.Date(IndexValue = 1);

/// Дата окончания действия
Property DateEnd As Lib.DataTypes.Date(IndexValue = 1);

/// Краткое описание
Property Desc As Lib.DataTypes.String(MAXLEN = 1024);

/// Наименование полное
Property NameFull As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024) [ Required ];

/// Организация, ответственная за ведение
Property Organ As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

Index Code On Code [ Type = bitmap ];

Index DateBeg On DateBeg [ Type = bitmap ];

Index DateEnd On DateEnd [ Type = bitmap ];

Index Name On Name [ Type = bitmap ];

Index NameFull On NameFull [ Type = bitmap ];

Index Organ On Organ [ Type = bitmap ];

Storage Default
{
<Data name="ClassifDefaultData">
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
<Value>Name</Value>
</Value>
<Value name="5">
<Value>DateBeg</Value>
</Value>
<Value name="6">
<Value>DateEnd</Value>
</Value>
<Value name="7">
<Value>Desc</Value>
</Value>
<Value name="8">
<Value>NameFull</Value>
</Value>
<Value name="9">
<Value>Organ</Value>
</Value>
<Value name="10">
<Value>GUID</Value>
</Value>
<Value name="11">
<Value>SourseSys</Value>
</Value>
<Value name="12">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.NSI.ClassifD</DataLocation>
<DefaultData>ClassifDefaultData</DefaultData>
<IdLocation>^App.NSI.ClassifD</IdLocation>
<IndexLocation>^App.NSI.ClassifI</IndexLocation>
<StreamLocation>^App.NSI.ClassifS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

Parameter XMLTYPE = "App-NSI-Classif";

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

