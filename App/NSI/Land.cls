/// Страны
Class App.NSI.Land Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.NSI.Land).%OpenId(11) d obj.addCheckSet({},{})  ; Запуск из терминала
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
         s ..NrFullName=##class(Lib.Util.Str).NormKitWords(..FullName)   ; Нормализованное полное наименование
         s ..NrName    =##class(Lib.Util.Str).NormKitWords(..Name)       ; Нормализованное наименование
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
        if in.form="AppNSILand"                                              ;-- Для формы "AppNSILand"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)    ; Поле "Кол-во использований"
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
/// Кол-во использований
/// k  s val=##class(App.NSI.Land).GetCntUsed(7) w !,val
Method GetCntUsed(ByRef out) As %String
{
	; На входе :
	;   id -> id записи "App.NSI.Land"

	; На выходе :
	;   val <- Значение

	s val=""
	try {
		
		s filter=[{"field":"idLand", "type":"равно", "data":(..%Id())}]       ; все "App..." с idEi
	    s out.error=##class(App.NSI.Firm).Filter(.filter,.ind)     ;
		s val=..indCOUNT(.ind)                                 ; Кол-во записей App.CTN.NomenVol по idEi
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

Storage Default
{
<Data name="LandDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Vers</Value>
</Value>
<Value name="3">
<Value>Code</Value>
</Value>
<Value name="4">
<Value>alpha2</Value>
</Value>
<Value name="5">
<Value>alpha3</Value>
</Value>
<Value name="6">
<Value>FullName</Value>
</Value>
<Value name="7">
<Value>Source</Value>
</Value>
<Value name="8">
<Value>Import</Value>
</Value>
<Value name="9">
<Value>Name</Value>
</Value>
<Value name="10">
<Value>%Edited</Value>
</Value>
<Value name="11">
<Value>GUID</Value>
</Value>
<Value name="12">
<Value>NrFullName</Value>
</Value>
<Value name="13">
<Value>NrName</Value>
</Value>
<Value name="14">
<Value>Temp1</Value>
</Value>
<Value name="15">
<Value>SourseSys</Value>
</Value>
<Value name="16">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.NSI.LandD</DataLocation>
<DefaultData>LandDefaultData</DefaultData>
<IdLocation>^App.NSI.LandD</IdLocation>
<IndexLocation>^App.NSI.LandI</IndexLocation>
<StreamLocation>^App.NSI.LandS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

Parameter XMLTYPE = "App-NSI-Land";

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 0;

/// Виртуальный
Parameter Virtual = 0;

/// Полное наименование
Property FullName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Импорт / Отечественный
Property Import As Lib.DataTypes.String(DISPLAYLIST = ",Импорт,Отечественный", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",1,0") [ Required ];

/// Нормализованное полное наименование
Property NrFullName As Lib.DataTypes.String(IndexSpecWord = 1, MAXLEN = 1024, SortingType = "P");

/// Нормализованное наименование
Property NrName As Lib.DataTypes.String(IndexSpecWord = 1, MAXLEN = 1024, SortingType = "P");

/// Источник
Property Source As Lib.DataTypes.String(DISPLAYLIST = ",ОКСМ,РЛС,Видаль", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",ОКСМ,РЛС,ВДЛ");

/// Временное поле
Property Temp1 As Lib.DataTypes.String(MAXLEN = 1024, SortingType = "P");

/// Обозначение альфа-2
Property alpha2 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Обозначение альфа-3
Property alpha3 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index FullName On FullName As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Import On Import As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index Source On Source As Truncate(200) [ Type = bitmap ];

Index alpha2 On alpha2 As Truncate(200) [ Type = bitmap ];

Index alpha3 On alpha3 As Truncate(200) [ Type = bitmap ];

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

