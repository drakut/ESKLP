/// Производители Контрагента
Class App.MAK.Firm Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.MAK.Firm).%OpenId(11) d obj.addCheckSet({},{})  ; Запуск из терминала
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
/// k  s out="",obj=##class(App.MAK.Firm).%OpenId(12) w !, obj.GetCntUsed(.out)
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

/// Загрузка App.MAK.Firm по макету ФЭ
/// !!! головного метода ..addImport пока нет.
/// 
ClassMethod addImportFE(ByRef in, ByRef out)
{
	; Вход:
	; 	in.form	         : Имя формы	
	; 	in.namesection	 : Имя секции-формата загрузки	
	; 	in.filetype	     : Тип файла ("txt","xlsx","xml","dbf")	
	; 	in.regim	     : Режим 1 - корректировка, 2 - дозапись	
	; 	in.quote	     : Удалять кавычки	
	; 	in.space	     : Удалять лишние пробелы	
	; 	in.numrow	     : Номер строки в файле	
	; 	in.source	     : Объект JSON с данными для сохранения (и определенные данные и неопределенные в одном) 
	; 	in.parentid	     : ID родителя для ракурса	
	; 	in.fieldparent	 : Поле для ID родителя для ракурса	
	; 	in.undefImpProps : Объект JSON с неопределенными в секции импорта данными, например {"undefImpProp1":"value1",...} 
	; Выход: 
	; 	out.error	  : Сообщение об ошибке или пусто	
	; 	out.continue  : Если 1, то в методе addImport руками переформировать строку до описанной в секции загрузки и вернуть ее в стандартный инструмент транзакции.
	; 					если 0, то строка не будет сохранена стандартным инструментом транзакции. Транзакцию обеспечить самостоятельно.
	; 
	try {
		s out.continue=0,out.error=""   ; значения по умолчанию
		;=== Начало работы со строкой
 		s str=in.source                     ; Строка с данными из файла
 		;=== Разборка полей строки файла
 		s AgentCode		=str.impAgentCode	; Код Контрагента	
  		s AgentName		=str.impAgentName	; 	-не используется: Наименование Контрагента	
		s FirmCode		=str.impFirmCode	; Код связанной Фирмы или пусто
		s FirmName		=str.impFirmName	; 	-не используется: Наименование связанной Фирмы
		s Code			=str.impCode		; Код производителя из прайса  или пусто	
		s Name			=str.impName		; Наименование производителя из прайса или пусто	
		s Status		=str.impStatus		; Статус записи	(1=экспертиза~2=обработано~3=отклонено) или пусто
		s CntUsed		=str.impCntUsed		; 	-не используется: Кол-во использования	
		s CntLinkFirm	=str.impCntLinkFirm	; 	-не используется: Кол-во привязанных Фирм ФЭ

		;=== Проверки и получение ID'ов по кодам
		s (idAgent,idFirm)=""   ; НУ   
		;  1. Код Контрагента
 		i AgentCode="" s out.error="Не задан Код Контрагента. " q   ; Ошибка. Выход
 		s idAgent=##class(App.PRC.Agent).GetIdByCode(AgentCode) i idAgent="" s out.error="Нет Контрагента с код="_AgentCode q   ; Ошибка. Выход
		;  2. Код связанной Фирмы
 		i FirmCode'="" s idFirm=##class(App.NSI.Firm).GetIdByCode(FirmCode) i idFirm="" s out.error="Нет связанной Фирмы с код="_FirmCode q     ; Ошибка. Выход
 		;  3. Одновременно пусты Код и Наименование производителя из прайса
 		i (Code="")&(Name="") s out.error="Одновременно пусты Код и Наименование производителя от Контрагента" q   ; Ошибка. Выход

        ;-- Поиск существующей записи по:
    	k ind s filter=[{"field":"idAgent","type":"равно","data":(idAgent)},{"oper":"AND"},  ; idAgent	-Контрагент
    					{"field":"Code",   "type":"равно","data":(Code)},{"oper":"AND"},     ; Code		-Код Производителя от Контрагента
    					{"field":"Name",   "type":"равно","data":(Name)}]                    ; Name		-Наименование Производителя от Контрагента
		d ..Filter(.filter,.ind)
 		s ptr="" d ..indNEXT(.ind,.ptr,.id) 
     	;
     	i id'="" s obj=..%OpenId(id)    ; Открыть существующий
		e        s obj=..%New()         ; Создать новый.
		
		;-- Заполнение полей
		d obj.idAgentSetObjectId(idAgent)                   ;Контрагент. Присвоили ссылку, указав ID без загрузки ссылочного объекта
		i idFirm'="" d obj.idFirmSetObjectId(idFirm)        ;Связанная Фирма. Присвоили ссылку, указав ID без загрузки ссылочного объекта
 		e            s obj.idFirm="" 	                    ; 
 		s obj.Code	=Code       							; Код производителя из прайса или пусто
        s obj.Name	=Name									; Наименование производителя из прайса или пусто
 		s obj.Status=Status									; Статус записи (1=экспертиза~2=обработано~3=отклонено) или пусто

 		;-- Транзакция записи
        d obj.%Save(0) s out.error=obj.ObjError() if out.error'="" q  ; Ошибка. Выход
	} // try
	
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Терминальная загрузка App.MAK.Firm по макету ФЭ txt-файла
/// !!! TXT-файл должен быть на Cache-сервере  и сохранен в "Unicode" или UTF8.
/// Т.к. в общем инструменте пок нет txt-загрузки
/// 
/// k  d ##class(App.MAK.Firm).ImportTxtFile("C:\InterSystems\Cache\CSP\maf\LoadFromFE\", "Фирмы контрагентов (utf8).txt", 2)
/// 
ClassMethod ImportTxtFile(Dir As %String, FileTxt As %String, StartLine As %String)
{
 ; 
 ;       Dir -> Путь к директори на Cache-сервере  "C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 ;   FileTxt -> Имя TXT-файл       "Фирмы контрагентов (utf8).txt"
 ; StartLine -> Номера тхт-строки, с которой начинается загрузка (пропустить заголовок)

 s (in,out)={}
 ;-- НУ по умолчанию
 i $g(Dir)="" s Dir="C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 i $g(FileTxt)="" s FileTxt="Фирмы контрагентов (utf8).txt"
 i $g(StartLine)="" s StartLine=2 
 s sep=$c(9)   ; Разделитей полей тхт-строки
 
 try {
 		s NameFile=Dir_FileTxt                             ; Полный путь
		Set stream=##class(%Stream.FileCharacter).%New()   ;
		Set sc=stream.LinkToFile(NameFile)
		s num=0          ; НУ
		;-- Заготовка постоянной части сообщения ошибки импорта  
 		s inErr={}
 		s inErr.File     = NameFile      ; полное имя файла
 		s inErr.NameForm = "Терминал"    ; имя формы запуска
		
		;-- Цикл по строкам файла
		While 'stream.AtEnd 
			{s num=num+1
	 	 	Set line=stream.ReadLine()    ; надо .ReadLine(). Нельзя .Read()
	 	 	i num<StartLine continue      ; пропуск строк заголовка
	 	 	;-- Строку с данными из файла преобразуем в динамобъект
	 	 	s in.source={}
 		 	s in.source.impAgentCode	=$p(line,sep,1)		  ; Код Контрагента	
  			s in.source.impAgentName	=$p(line,sep,2)		  ; Наименование Контрагента	
			s in.source.impFirmCode		=$p(line,sep,3)		  ; Код связанной Фирмы
			s in.source.impFirmName		=$p(line,sep,4)		  ; Наименование связанной Фирмы
			s in.source.impCode			=$p(line,sep,5)		  ; Код производителя из прайса	
			s in.source.impName			=$p(line,sep,6)		  ; Наименование производителя из прайса	
			s in.source.impStatus		=$p(line,sep,7)		  ; Статус записи	
			s in.source.impCntUsed		=$p(line,sep,8)		  ; Кол-во использования	
			s in.source.impCntLinkFirm	=$p(line,sep,9)		  ; Кол-во привязанных Фирм ФЭ
 		 	
 		 	;-- Индикация
 		 	w !,"num=",num,$c(9),in.source.impAgentCode,$c(9),in.source.impName
 		 	
 		 	;--- Транзакция тхт-строки
 		 	d ..addImportFE(.in,.out)
 		 	i out.error'="" 
 		 		{w !,$c(9,9),"Ошибка. "_out.error_" См. Протокол ошибок загрузки."   ; писать в журнал ошибок импорта
				 ;-- заполнение пременной части сообщения об ошибке импорта
				 s inErr.TxtError = out.error   ; это мой текст ошибки
				 s inErr.Regime   = 1	    	; Режим (1=Корректировка,2=Дозапись,3=Универсально) = режим
				 s inErr.Row      = num			; Номер строки файла
				 s inErr.StrData  = line		; Данные строки файла
	 			 d ##class(Lib.App.ImportError).doCreateErr(.inErr, .out)
	 			}
			}
    	}
 catch exp {d ..ErrorDetect(.exp)} // catch 	
 q
}

/// Пересохранение по фильтру
/// d ##class(App.MAK.Firm).ReSaveFiltr()
/// k ^App.MAK.FirmD1 m ^App.MAK.FirmD1=^App.CTL.ClassClassListD
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
/// d ##class(App.MAK.Firm).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
 		{d ..ReSaveOne(id)}    ; Пересохранение одной записи
 		
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.MAK.Firm).ReSaveOne(12153)
/// Переиндексация:  k ^App.MAK.FirmI d ##class(App.MAK.Firm).%BuildIndices()
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
/// k  d ##class(App.MAK.Firm).ReDelOne(12153)
/// Переиндексация:  k ^App.MAK.FirmI d ##class(App.MAK.Firm).%BuildIndices()
/// k ^App.MAK.FirmD,^App.MAK.FirmI
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

Parameter XMLTYPE = "App-MAK-Firm";

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
<Value>SourseSys</Value>
</Value>
<Value name="12">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.MAK.FirmD</DataLocation>
<DefaultData>FirmDefaultData</DefaultData>
<IdLocation>^App.MAK.FirmD</IdLocation>
<IndexLocation>^App.MAK.FirmI</IndexLocation>
<StreamLocation>^App.MAK.FirmS</StreamLocation>
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

