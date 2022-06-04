/// Производители Контрагента
Class App.PRC.Firm Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.PRC.Firm).%OpenId(11) d obj.addCheckSet({},{})  ; Запуск из терминала
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
         s ..NameNorm =##class(Lib.Util.Str).NormKitWords(..Name)      ; Нормализованное наименование Производителя Контрагента
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
        if in.form="AppPRCFirm"                                            ;-- Для формы "AppPRCFirm"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)    ; Кол-во использования "Наименование от Контрагента" в Прайсах текущего Контрагента
			
			;... ;добавить Кол-во привязанных Фирм-ФЭ к нормализованному значению "Наименование .. "
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
/// Кол-во использования "Наименование от Контрагента" в Прайсах текущего Контрагента
/// k  s out="",obj=##class(App.PRC.Firm).%OpenId(12) w !, obj.GetCntUsed(.out)
/// 
Method GetCntUsed(ByRef out) As %String
{
	; На входе  : текущий объект
	; На выходе :
	;   val <- Значение
	s out={"error":""},val=""
	try {
		k ind 
		;  По текущему Контрагенту найти прайсы с таким же нормализованным ннаименованием Производителя
		s filter=[{"field":"idAgent",  "type":"равно", "data":(..idAgent.%Id())}, {"oper":"AND"},
		          {"field":"NameNorm", "type":"равно", "data":(..NameNorm)}]
	    d ..Filter(.filter,.ind)        ;
		s val=..indCOUNT(.ind)                                              ; Кол-во записей App... по id..
 	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Пересохранение по фильтру
/// d ##class(App.PRC.Firm).ReSaveFiltr()
/// k ^App.PRC.FirmD1 m ^App.PRC.FirmD1=^App.CTL.ClassClassListD
ClassMethod ReSaveFiltr()
{
 try {
 	;-- Записи по фильтру
	; .. 
    k ind s filter=[{"field":"IdClass", "type":"равно","data":"8254"}]
	s err=..Filter(.filter,.ind)  if err'="" w $c(9),err q
    w !,"cnt=",..indCOUNT(.ind)
    ;q 
 	;-- Проход по записям
 	s ptr="" while ..indNEXT(.ind,.ptr,.id) 
 		{s err=""
	 	 w !,"id=",id
	 	 ;d ..ReSaveOne(id) s err=..ObjError()    ;
	 	 d ..%DeleteId(id) s err=..ObjError()
		 if err'="" w $c(9),err q    
 		 ;else       w $c(9),"...исправлено" 
 		 else       w $c(9),"...удалено" 
 		}
 		
    	}
 catch exp {d ..ErrorDetect(.exp)} // catch 	
 q
}

/// Пересохранение всех записей
/// d ##class(App.PRC.Firm).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
 		{d ..ReSaveOne(id)}    ; Пересохранение одной записи
 		
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.PRC.Firm).ReSaveOne(12153)
/// Переиндексация:  k ^App.PRC.FirmI d ##class(App.PRC.Firm).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()

 ; --- Здесь что-то  ..
 ;s filter=[{"field":"IdClass","type":"равно","data":(id)}]
 ;s error=##class(App.CTL.Pattern).Filter(.filter,.ind) q:error'=""
 ;s cnt=##class(App.CTL.Pattern).indCOUNT(.ind)

 ;--- и пересохраняем
 d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Удаление одной записи
/// k  d ##class(App.PRC.Firm).ReDelOne(12153)
/// Переиндексация:  k ^App.PRC.FirmI d ##class(App.PRC.Firm).%BuildIndices()
/// k ^App.PRC.FirmD,^App.PRC.FirmI
ClassMethod ReDelOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 ;-- Удаление
 d obj.%DeleteId(id) s err=obj.ObjError() if err'="" w !,$c(9),err q   // Выход по ошибке
 q
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-PRC-Firm";

/// Список уникальных ссылочных полей
Parameter listUnique = ",idAgent";

Storage Default
{
<Data name="FirmDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Vers</Value>
</Value>
<Value name="3">
<Value>GUID</Value>
</Value>
<Value name="4">
<Value>Code</Value>
</Value>
<Value name="5">
<Value>Name</Value>
</Value>
<Value name="6">
<Value>NameNorm</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>Temp1</Value>
</Value>
<Value name="9">
<Value>idAgent</Value>
</Value>
<Value name="10">
<Value>idFirm</Value>
</Value>
<Value name="11">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.PRC.FirmD</DataLocation>
<DefaultData>FirmDefaultData</DefaultData>
<IdLocation>^App.PRC.FirmD</IdLocation>
<IndexLocation>^App.PRC.FirmI</IndexLocation>
<StreamLocation>^App.PRC.FirmS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Код Производителя от Контрагента
Property Code As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z", Unique = "Z");

/// Наим.Производителя от Контрагента
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z", Unique = "Z");

/// Норм.наимен.Производителя
Property NameNorm As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Статус записи
Property Status As Lib.DataTypes.String(DISPLAYLIST = ",экспертиза,обработано,отклонено", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",1,2,3");

/// Временное поле1
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Контрагент
Property idAgent As App.PRC.Agent [ Required ];

/// Связанная Фирма-Производитель
Property idFirm As App.NSI.Firm;

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index NameNorm On NameNorm As Truncate(200) [ Type = bitmap ];

Index Status On Status As Truncate(200) [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

Index idAgent On idAgent [ Type = bitmap ];

Index idFirm On idFirm [ Type = bitmap ];

ForeignKey fkidAgent(idAgent) References App.PRC.Agent();

ForeignKey fkidFirm(idFirm) References App.NSI.Firm();

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

