/// МНН
Class App.NSI.Mnn Extends (%Persistent, Lib.Abstract.StorableTablesCode)
{

/// !!! При создании записи такая же создается или изменяется в App.ONT.VolProp
/// 
/// 
/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.NSI.Mnn).%OpenId(11) d obj.addCheckSet({},{})  ; Запуск из терминала
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
 		 ;  ... и т.д
         ;
		} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// После сохранения
Method addAfterSave(ByRef in, ByRef out)
{
	// На входе :
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование)
	//			  in.parentid -> ID главной записи для записи ракурса 
	//			    in.jobnum -> Номер задания для фоновых задач
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=..%Id()
	//	s name=..Name			// Получить поле из Нового тела записи
	s out={"error":""}
	try {
        d ..SincroVolProp(.out) q:out.error'=""    ; Синхронизировать только-что сохраненную запись с "App.ONT.VolProp"
		
		} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Синхронизировать только-что сохраненную запись "App.NSI.Mnn" с "App.ONT.VolProp"
/// k  s out="",obj=##class(App.NSI.Mnn).%OpenId(7) d obj.SincroVolProp(.out) w
/// 
Method SincroVolProp(ByRef out)
{
		;-- Синхронизировать с "App.ONT.VolProp"
		;   По местному атрибуту "..NrName - Нормализ. наименование (идентификатор при синхронизации с App.ONT.VolProp)"
		;   найти запись в "App.ONT.VolProp" по ее атрибуту "NrFulVol -Нормализованное Значение полное"
		;   - нет записи  в "App.ONT.VolProp" - создать ее
		;   - есть запись в "App.ONT.VolProp" - корректировать ее
	    ;
	s out={"error":""}
	try {
         ;-- Искать запись в "App.ONT.VolProp"
		 s filter=[{"field":"NrFulVol", "type":"=", "data":(..NrName)}]  ;
	     d ##class(App.ONT.VolProp).Filter(.filter,.ind)                 ;
	     s ptr="" d ..indNEXT(.ind,.ptr,.idVol)  ; Первый найденный idVol записи App.ONT.VolProp по = "Нормализованное Значение полное"
	     ;
	     i idVol="" {s objVolProp=##class(App.ONT.VolProp).%New()}          ; Новый объект
	     else       {s objVolProp=##class(App.ONT.VolProp).%OpenId(idVol)}  ; Найденный

		 ;-- Заполнение полей "App.ONT.VolProp"
		 s objVolProp.FulVol=..Name        ; Значение полное                  = Наименование
		 s objVolProp.LngVol=..AltName     ; Значение на альтернативном языке = Наименование латинское
		
		 ;-- Транзакция "App.ONT.VolProp"
		 d objVolProp.%Save(0) s out.error=..ObjError() i out.error'="" q   ; Выход по ошибке
		
		} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Построение/снос дополнительных индексов
Method addIndex(ByRef in, ByRef out)
{
	// На входе :
	//		in.oldRec.ИмяПоля -> Поле из старого тело записи
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование,"delete"-удаление,"reindex"- переиндексация записи) При "delete" in.oldRec совпадает с текущим объектом
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s name=in.oldRec.Name	// Получить поле из Старого тела записи
	//	s name=..Name			// Получить поле из Нового тела записи
	s out={"error":""}
	try {
		// !!! Здесь писать свой код

	;===== Построение
	if (in.type'="delete")  ;
		{
 		 ;--- Доп.индексы типа "idХХХ-used" по используемым idХХХ. 
 		 ;    Для программно-управляемых Фильтров при поиске через поисковые формы, в которые будут подаваться только используемые IDы справочников
 		 ;    Добавлять список полей, подлежащих индексации, по мере надобности
		 f NameFld="Temp1"   ;"idClass","idProp","idPatt"        ; {d ..indUsedINSERT(##this, NameFld)}
		 	{s Val=$PROPERTY(##this,NameFld)                ; Получить значение полей "idХХХ" ;"idClass","idProp","idPatt"
		 	 s id="" 
		 	 ;-- Для атрибута "Temp1" своя обработка
		 	 i NameFld="Temp1" s:Val'="" id=Val   ; при Temp1 берем его значение в качестве id 
		 	 e  s:Val'="" id=Val.%Id()            ; иначе id берем как свойство объекта
		 	 ;--
		 	 i id'="" d ..indINSERT([(NameFld_"-used")],id) ; Строим индекс по этому ID
		 	}
        }

    ;======= Снос. !!! К этому моменту все основные индексы по записи снесены
	if in.type="delete" ; Редактирование или удаление. Снести индекс
	    {	
 		 ;--- Доп.индексы по используемым idХХХ. Для Фильтров при поиске через поисковые формы
 		 ;    Добавлять список полей, подлежащих сносу или индексации, по мере надобности
 		 f NameFld="Temp1"   ;"idClass","idProp","idPatt"        ; {d ..indUsedINSERT(##this, NameFld)}
 		 	{s id=in.oldRec.%Get(NameFld)   ; Получить значение полей "idХХХ" ;"idClass","idProp","idPatt" из in.oldRec
 		     k ind
 		     i id'="" {s filter=[{"field":(NameFld),"type":"равно","data":(id)}]
	    	 		   s out.error=..Filter(.filter,.ind) q:out.error'=""
			           i ..indCOUNT(.ind)=0 {d ..indDELETE([(NameFld_"-used")],id)}  ;  Если нет записей c id, тогда сносить. Иначе, ничего не делать
 		 	          }
 		 	}
	    }
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)}
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
        if in.form="AppNSIMnn"   ;-- Для формы "AppNSIMnn"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)    ; Кол-во использования
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
/// Кол-во использования
/// k  s out="",obj=##class(App.NSI.Mnn).%OpenId(12) w !, obj.GetCntUsed(.out)
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
		;s filter=[{"field":"idAgent",  "type":"равно", "data":(..idAgent.%Id())}, {"oper":"AND"},
		;          {"field":"NameNorm", "type":"равно", "data":(..NameNorm)}]
	    ;d ..Filter(.filter,.ind)        ;
		;s val=..indCOUNT(.ind)                                              ; Кол-во записей App... по id..
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

Parameter XMLTYPE = "App-NSI-Mnn";

Storage Default
{
<Data name="MnnDefaultData">
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
<Value>AltName</Value>
</Value>
<Value name="5">
<Value>Code</Value>
</Value>
<Value name="6">
<Value>Name</Value>
</Value>
<Value name="7">
<Value>Temp1</Value>
</Value>
<Value name="8">
<Value>NrName</Value>
</Value>
<Value name="9">
<Value>SourseSys</Value>
</Value>
<Value name="10">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.NSI.MnnD</DataLocation>
<DefaultData>MnnDefaultData</DefaultData>
<IdLocation>^App.NSI.MnnD</IdLocation>
<IndexLocation>^App.NSI.MnnI</IndexLocation>
<StreamLocation>^App.NSI.MnnS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Наименование латинское
Property AltName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Код
Property Code As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z", Unique = "Z") [ Required ];

/// Наименование
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z") [ Required ];

/// Нормализованное наименование
Property NrName As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Временное поле (id-перенесенной ФЭ-записи)
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

Index AltName On AltName As Truncate(200) [ Type = bitmap ];

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index NrName On NrName As Truncate(200) [ Type = bitmap ];

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

