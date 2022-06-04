/// Единицы измерения
Class App.NSI.Ei Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

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
        if in.form="AppNSIEi"                                              ;-- Для формы "AppNSIEi"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)    ; Поле "Кол-во использований в значениях свойств номенклатуры"
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
/// Кол-во использований ЕИ
/// k  s val=##class(App.NSI.Ei).GetCntUsed(7) w !,val
Method GetCntUsed(ByRef out) As %String
{
	; На входе :

	; На выходе :
	;   val <- Значение

	s val=""
	try {
		
		;-- Кол-во значений в номенклатуре		
		s filter=[{"field":"idEi", "type":"равно", "data":(..%Id())}]       ; все "App..." с idEi
	    s out.error=##class(App.CTN.NomenVol).Filter(.filter,.ind)     ;
		s val=..indCOUNT(.ind)                                 ; Кол-во записей App.CTN.NomenVol по idEi
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}

	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Пакетный SOAP-перенос из ФЭ
/// k  d ##class(App.NSI.Ei).SOAPImportFromFE("show")
/// 
ClassMethod SOAPImportFromFE(show As %String)
{
	; На входе :
	;   show = "show" или пусто
		
	s:$g(show)="" show=""   
	s out={"error":""}
	try {
		;-- Настройка
		s classDonor = "App.SOAP.FE.FESE"   ; Абстрактный класс-донор.
		s FldCode    = "FESEcode"           ; Имя поля Кода
		s ptrSOAP = "",inSOAP = {}, objSOAP = ""
		s inSOAP.filter = [{"field":(FldCode),"type":"'=","data":""}]   ; Фильтр для ФЭ в именах полей ФЭ
		
		;-- Перебор записей в ФЭ
		while ($CLASSMETHOD(classDonor, "soapNEXT", .inSOAP, .out, .ptrSOAP, .objSOAP))&&(out.error="") 
			{ ;continue:$G(objSOAP)=""  пока отключим
			 s id = ..GetIdByCode(objSOAP.FESEcode)	                  ; Проверка ранее перенесенной записи по коду
			 i id = "" {s obj = ..%New(),reg="новая"}                 ; Новая запись
			 else      {s obj = ..%OpenId(id),reg="редактирование"}   ; Редактирование существующей
			 
			 ;-- Заполнение полей местного объекта
		     d obj.SetFromObjSOAP(objSOAP,.out)
		     	if out.error'="" i show="show" w !,out.error   ; Индикация ошибки.
		     	if out.error'="" q                             ; Выход
 		     i show="show" w !,"SOAP-ID=",obj.Temp1," Code=",obj.Code,$c(9),obj.Name,$c(9),reg
 		     
 		     ;-- Транзакция  местного объекта
		     d obj.%Save(0) s out.error=obj.ObjError()
		     	if out.error'="" i show="show" w !,out.error   ; Индикация ошибки.
		     	if out.error'="" q                             ; Выход
			}
	}
		catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Заполнение свойств местного объекта из объекта, пришедшего по SOAP
///   k  s obj=##class(App.NSI.Ei).%OpenId(4) d obj.SetFromObjSOAP("",.out) w !,out.error
/// 
Method SetFromObjSOAP(objSOAP, ByRef out)
{
	; На входе :
	;   objSOAP -> Объект SOAP
	; На выходе :
	;   out.error <- Ошибка
	;   
	s out={"error":""}
	try {
	 	;-- s местный.атрибут = objSOAP.атрибут	
 		s ..Code      = objSOAP.FESEcode    ; Код
 		s ..Group     = objSOAP.FESEgrup    ; Группа
 		s ..Iden1     = objSOAP.FESEiden1   ; Обозначение 1 строчными
 		s ..Iden2     = objSOAP.FESEiden2   ; Обозначение 2 заглавным
 		s ..InterCode = ""                  ; Международный идентификатор
 		s ..Name      = objSOAP.FESEname    ; Наименование
 		s ..PeriodUse = objSOAP.FESEmain    ; Частота использования
 		s ..Prec      = objSOAP.FESEprec    ; Кол-во знаков дробной части
 		s ..Source    = objSOAP.FESENsour   ; Источник
 		s ..Temp1      = objSOAP.ID          ; Временное поле - ID записи ФЭ
	   }
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

Storage Default
{
<Data name="EiDefaultData">
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
<Value>Group</Value>
</Value>
<Value name="5">
<Value>PeriodUse</Value>
</Value>
<Value name="6">
<Value>Iden1</Value>
</Value>
<Value name="7">
<Value>Iden2</Value>
</Value>
<Value name="8">
<Value>Prec</Value>
</Value>
<Value name="9">
<Value>Source</Value>
</Value>
<Value name="10">
<Value>Name</Value>
</Value>
<Value name="11">
<Value>%Edited</Value>
</Value>
<Value name="12">
<Value>InterCode</Value>
</Value>
<Value name="13">
<Value>GUID</Value>
</Value>
<Value name="14">
<Value>Temp</Value>
</Value>
<Value name="15">
<Value>Temp1</Value>
</Value>
<Value name="16">
<Value>SourseSys</Value>
</Value>
<Value name="17">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.NSI.EiD</DataLocation>
<DefaultData>EiDefaultData</DefaultData>
<IdLocation>^App.NSI.EiD</IdLocation>
<IndexLocation>^App.NSI.EiI</IndexLocation>
<StreamLocation>^App.NSI.EiS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Сохранение в протокол (1 - да, 0 - Нет)
Parameter SaveProtocol = 1;

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

/// Дополнительная функция перед началом экспорта, переопределяемая при необходимости изменить состав полей или название файла
/// Вход:
/// 	in.jobnum		- Номер задания
/// 	in.form			- Имя формы
/// 	in.filetype		- Тип файла
/// 	in.sendmail		- Отправка по почте
/// 	in.delim		- Разделитель
/// 	in.codepage		- Кодировка
/// 	in.row			- ??
/// 	in.sort			- Сортировка
/// 	in.filter		- Фильтр для поиска
/// 	in.command		- Команда, "export"
/// 	in.namesection	- Имя секции, например "LibAppUser-Export-XLSX"
/// 	in.idComponent	- id компонента формы, вызвавшего экспорт
/// 	in.header		- Показывать/не показывать заголовки (шапку)
/// 	in.id			- id выделенного (активного) элемента в таблице
/// 	in.cspapp		- CSP-директория приложения , например "/csp/gss/"
/// 	in.docCaption	- Название файла
/// 	in.reportDir	- Директория сохранения файла
/// 	in.userName		- Имя пользователя
/// 	in.section		- Описание секции выгрузки
/// 		section.name	- имя секции выгрузки, не обязательно
/// 		section.caption	- заголовок секции выгрузки
/// 		section.type	- тип секции, export
/// 		section.mode	- расширение файла для выгрузки
/// 		section.section = [
/// 			{"name"	 : "LibAppUserName",	- имя свойства в форме
/// 			"field"  : "Name",				- свойство выгружаемого объекта
/// 			"caption": "Логин",				- заголовок столбца
/// 			"width"  : 20,					- ширина столбца
/// 			"visible": 1					- выгружать/не выгружать
/// 			"style"	 : 8					- код стиля из таблицы стилей						
/// 				},
/// 			...
/// 		]
/// Выход: 
/// 	out				- изначально КЛОН in, динамический объект
/// 
ClassMethod addBeforeExport(ByRef in, ByRef out)
{
	s err=""
	try {
		
		; Изменяем название файла
		s out.docCaption = "ВыгрузкаКакХочу"
		
		s element = {
			"name":"PROPERTY_NAME",
			"field": "PROPERTY_FIELD",
			"caption": "PROPERTY_CAPTION",
			"width": 40,
			"dalign": "left",
			"visible": 1,
			"sortable": 1,
			"dynamic": 1
		}
		d out.section.section.%Push(element)
		; Тестирнуем ошибку подготовки выгрузки
		s error="Тест ошибки, прерывающей выгрузку"
		;s err=..SetTempParam(in.jobnum, "error", error)
		
		
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

/// Дополнительная функция при выгрузке, переопределяемая при использовании нестандартного алгоритма экспорта одной строки </br>
/// </br>
/// Вход:
/// 	in.command		- Команда export
/// 	in.idComponent	- Id компонента, Item76-2_Main
/// 	in.form			- Название формы
/// 	in.filetype		- Расширение файла xlsx
/// 	in.sendmail		- false
/// 	in.delim		- Разделитель
/// 	in.codepage		- Кодировка
/// 	in.header		- Показывать заголовки, true
/// 	in.sort			- Поле для сортировки? false
/// 	in.namesection	- Название секции выгрузки, отдаем сразу чтобы не искать на каждой итерации DesignForms-Export-OneXLSX
/// 	in.id			- 10
/// 	in.jobnum		- Номер джоба 1E75C20A-6BD8-443E-AF55-91DD2F752CE1
/// 	in.filter		- Фильтр данных []
/// 	in.cspapp		- CSP-директория приложения /csp/rzd/
/// 	in.start		- 1
/// 	in.direct		- 1
/// 	in.data			- Объект JSON для экспорта, названия полей в соответствии со свойствами ..Fields. Набор самих полей можно переопределить в addBeforeExport
/// 	in.styles		- Стили для каждого поля
/// 	in.objId		- ID объекта, который выгружается
/// Выход: 
/// 	out				- изначально КЛОН in, динамический объект
/// 	out.error		- Ошибки
/// 	out.data		- Объект JSON для экспорта
/// 	out.styles		- Стили для каждого поля
ClassMethod addExport(ByRef in, ByRef out)
{
	s err=""
	try {
		s out.error=""
		// !!! Здесь писать свой код
		
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

Parameter XMLTYPE = "App-NSI-Ei";

/// Группа
Property Group As Lib.DataTypes.String(DISPLAYLIST = ",Универсальная,Единицы длины,Единицы площади,Единицы объема,Единицы массы,Технические единицы,Единицы времени,Экономические единицы,Единицы концентрации РЛС,Единицы действия РЛС", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",A,L,S,V,M,H,T,E,rlsC,rlsA") [ Required ];

/// Обозначение 1 строчными
Property Iden1 As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024) [ Required ];

/// Обозначение 2 заглавным
Property Iden2 As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Международный идентификатор
Property InterCode As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Частота использования
Property PeriodUse As Lib.DataTypes.String(DISPLAYLIST = ",Часто,Редко", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",B,N") [ Required ];

/// Кол-во знаков дробной части
Property Prec As Lib.DataTypes.Integer(IndexValue = 1);

/// Источник
Property Source As Lib.DataTypes.String(DISPLAYLIST = ",ОКЕИ,РЛС,Прочие,PLG", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",ОКЕИ,РЛС,ПРЧ,PLG") [ Required ];

/// Временное поле
Property Temp1 As Lib.DataTypes.String(MAXLEN = 1024);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Group On Group As Truncate(200) [ Type = bitmap ];

Index Iden1 On Iden1 As Truncate(200) [ Type = bitmap ];

Index Iden2 On Iden2 As Truncate(200) [ Type = bitmap ];

Index InterCode On InterCode As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index PeriodUse On PeriodUse As Truncate(200) [ Type = bitmap ];

Index Prec On Prec [ Type = bitmap ];

Index Source On Source As Truncate(200) [ Type = bitmap ];

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

