/// Фирмы
Class App.NSI.Firm Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.NSI.Firm).%OpenId(11) d obj.addCheckSet({},{})  ; Запуск из терминала
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
         s ..NrName    =##class(Lib.Util.Str).NormKitWords(..Name)      ; Нормализованное наименование
         s ..NrShName  =##class(Lib.Util.Str).NormKitWords(..ShName)    ; Нормализованное наименование для нотации
         s ..NrAltName =##class(Lib.Util.Str).NormKitWords(..AltName)   ; Нормализованное альтернативное наименование
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
        if in.form="AppNSIFirm"                                            ;-- Для формы "AppNSIFirm"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)    ; Поле "Кол-во использований" в значениях свойств по фирмам
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
/// Кол-во использований в значениях свойств по фирмам
/// k  s val=##class(App.NSI.Firm).GetCntUsed(7) w !,val
Method GetCntUsed(ByRef out) As %String
{
	; На входе :

	; На выходе :
	;   val <- Значение

	s val=""
	try {
		
		s filter=[{"field":"idFirm", "type":"равно", "data":(..%Id())}]          ; все "App..." с id..
	    s out.error=##class(App.CTN.NomenVolFirm).Filter(.filter,.ind)      ;
		s val=..indCOUNT(.ind)                                              ; Кол-во записей App... по id..
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 0;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-NSI-Firm";

Storage Default
{
<Data name="FirmDefaultData">
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
<Value>AltName</Value>
</Value>
<Value name="6">
<Value>Com</Value>
</Value>
<Value name="7">
<Value>FinWords</Value>
</Value>
<Value name="8">
<Value>Name</Value>
</Value>
<Value name="9">
<Value>NrAltName</Value>
</Value>
<Value name="10">
<Value>NrName</Value>
</Value>
<Value name="11">
<Value>NrShName</Value>
</Value>
<Value name="12">
<Value>ShName</Value>
</Value>
<Value name="13">
<Value>Temp1</Value>
</Value>
<Value name="14">
<Value>idLand</Value>
</Value>
<Value name="15">
<Value>SourseSys</Value>
</Value>
<Value name="16">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.NSI.FirmD</DataLocation>
<DefaultData>FirmDefaultData</DefaultData>
<IdLocation>^App.NSI.FirmD</IdLocation>
<IndexLocation>^App.NSI.FirmI</IndexLocation>
<StreamLocation>^App.NSI.FirmS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Наименование альтернативное
Property AltName As Lib.DataTypes.String(MAXLEN = 1024);

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// Набор поисковых слов
Property FinWords As Lib.DataTypes.String(MAXLEN = 1024);

/// Нормализ.наимен. альтернативное
Property NrAltName As Lib.DataTypes.String(MAXLEN = 1024);

/// Нормализ.наимен.
Property NrName As Lib.DataTypes.String(MAXLEN = 1024);

/// Нормализ.наимен. для нотации
Property NrShName As Lib.DataTypes.String(MAXLEN = 1024);

/// Наименование краткое для нотации
Property ShName As Lib.DataTypes.String(MAXLEN = 1024);

/// Временное поле
Property Temp1 As Lib.DataTypes.String(MAXLEN = 1024);

/// Страна по умолчанию
Property idLand As App.NSI.Land;

ForeignKey fkidLand(idLand) References App.NSI.Land();

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index idLand On idLand [ Type = bitmap ];

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

