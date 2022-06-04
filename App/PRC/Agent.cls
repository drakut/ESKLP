/// Контрагенты
Class App.PRC.Agent Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.PRC.Agent).%OpenId(11) d obj.addCheckSet({},{})  ; Запуск из терминала
Method addCheckSet(ByRef in, ByRef out)
{
	// На входе :
	//		in.oldRec.ИмяПоля -> Поле из старого тела записи
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование,"delete"-удаление,"reindex"- переиндексация записи)
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=s id=..%Id()
	//	s name=in.oldRec.Name	// Получить поле из Старого тела записи
	//	s name=..Name			// Получить поле из Нового тела записи
	s err=""
	try {
		
		 // !!! Здесь писать свой код
         ;-- Проверки         
         ;i что-то не так s out.error="Нестандартная ЕИ короче 3-х символов" q  ; Ошибка
         ;  ... и т.д
         ; 
         ;-- Преобразования.
 		 ;  ... и т.д
         ;
		} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Получить вычислимое поле для форм
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
	s out={"error":""}
	try {
		s out.value=""
		//     !!! Здесь писать свой код
		;=== Для форм ...
        if in.form="AppPRCAgent"                                            ;-- Для формы "AppPRCAgent"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(..%Id(),.out)    ; Поле "Кол-во номенклатуры"
			; ...           
           }		
		//=== 2. и т.д.
		//  .....
		
		// Конец. 
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// 
/// Кол-во номенклатуры
/// k  s val=##class(App.PRC.Agent).GetCntUsed(1) w !,val
ClassMethod GetCntUsed(id As %Integer, ByRef out) As %String
{
	; На входе :
	;   id -> id записи "App.PRC.Agent"

	; На выходе :
	;   val <- Значение
	;   out. <-
	try {
		s val=""
		s filter=[{"field":"idAgent", "type":"равно", "data":(id)}]    ; все "App..." с idEi
	    s out.error=##class(App.PRC.Nomen).Filter(.filter,.ind)        ;
		s val=..indCOUNT(.ind)                                         ; Кол-во записей App.CTN.NomenVol по idEi
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}

	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-PRC-Agent";

Storage Default
{
<CounterLocation>^App.PRC.AgentC</CounterLocation>
<Data name="AgentDefaultData">
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
<Value>GUID</Value>
</Value>
<Value name="5">
<Value>Com</Value>
</Value>
<Value name="6">
<Value>ConstCode</Value>
</Value>
<Value name="7">
<Value>ConstOper</Value>
</Value>
<Value name="8">
<Value>CounterCode</Value>
</Value>
<Value name="9">
<Value>Name</Value>
</Value>
<Value name="10">
<Value>Temp1</Value>
</Value>
<Value name="11">
<Value>Type</Value>
</Value>
<Value name="12">
<Value>idGroup</Value>
</Value>
<Value name="13">
<Value>SourseSys</Value>
</Value>
<Value name="14">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.PRC.AgentD</DataLocation>
<DefaultData>AgentDefaultData</DefaultData>
<IdLocation>^App.PRC.AgentD</IdLocation>
<IndexLocation>^App.PRC.AgentI</IndexLocation>
<StreamLocation>^App.PRC.AgentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// Константа кода номенклатуры
Property ConstCode As Lib.DataTypes.String(MAXLEN = 1024);

/// Операция с константой
Property ConstOper As Lib.DataTypes.String(DISPLAYLIST = ",Приклеить слева,Сложить,Приклеить к коду справа", MAXLEN = 1024, VALUELIST = ",1,2,3");

/// Счетчик для кода
Property CounterCode As %Library.Counter;

/// Временное поле
Property Temp1 As Lib.DataTypes.String(MAXLEN = 1024);

/// Тип контрагента
Property Type As Lib.DataTypes.String(DISPLAYLIST = ",Поставщик,Аптека-клиент,Список номенклатуры", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",1,2,3") [ Required ];

/// Группа Контрагентов
Property idGroup As App.PRC.AgentGroup;

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CounterCode On CounterCode [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index Type On Type As Truncate(200) [ Type = bitmap ];

Index idGroup On idGroup [ Type = bitmap ];

ForeignKey fkidGroup(idGroup) References App.PRC.AgentGroup();

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

