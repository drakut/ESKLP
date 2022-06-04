/// МАК-Штрих-коды
Class App.MAK.BarCode Extends (%Persistent, Lib.Abstract.StorableTablesCode) [ Inheritance = right, Not ProcedureBlock ]
{

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

/// Изменить стиль ячейки
Method addStyleCell(ByRef in, ByRef out)
{
	// На входе :
	//		in.form -> Имя формы
	//		in.type -> Тип ("grid" - таблица, "xlsx" - выгрузка в XLSX и т.д.)
	//		in.field -> Имя поля формы
	//		..ИмяПоля -> Поле из тела записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//		out.style -> Стиль ячейки в виде :
	//					s out.style={"CodeStyle":(КодСтиля)}  или
	//					s out.style={"NameStyle":(ИмяСтиля)}  или
	//					s out.style={"Align":"left","BgColor":"#cc0000","Bold":1,"FontColor":"#ffffff","Italic":0}
	// Примеры :
	//	s id=..%Id()
	s out.style=""
	try {
		;=== Маркировать колонки "Наименование" и "Актуальность"
		if in.form="AppMAKBarCode"
			{if (in.field="gridMakNomName")!(in.field="gridAct") s:..Act=0 out.style={"CodeStyle":"27"}  ; Неактуально. Код стиля = 27 
			}
		
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Загрузка App.MAK.BarCode по макету ФЭ
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
 		s Code		=str.impCode		; Код записи	
  		s ZHK		=str.impZHK			; Штрих-код	
  		s MakNomCode=str.impMakNomCode	; Код МакНоменклатуры	
  		s MakNomName=str.impMakNomName	; Наименование МакНоменклатуры	
  		s Act		=str.impAct			; Актуальность (true,false)	-> (0=Неактуально,1=Актуально)

		;=== Проверки и получение ID'ов по кодам
		;  1. Код записи
 		i Code="" s out.error="Не задан Код записи." q   ; Ошибка. Выход
 		;  2. Штрих-код
 		i ZHK="" s out.error="Не задан Штрих-код." q   ; Ошибка. Выход
 		;  3. Код МакНоменклатуры	
 		i MakNomCode="" s out.error="Не задан Код МакНоменклатуры. " q   ; Ошибка. Выход
 		s idMakNom=##class(App.MAK.Nomen).GetIdByCode(MakNomCode) i idMakNom="" s out.error="Нет МакНоменклатуры с код="_MakNomCode q     ; Ошибка. Выход


        ;-- Поиск существующей записи по ее коду
        s id=..GetIdByCode(Code)
     	i id'="" s obj=..%OpenId(id)    ; Открыть существующий
		e        s obj=..%New()         ; Создать новый.

		;-- Заполнение полей
 		s obj.Code	=Code					; Код записи
		d obj.idMakNomSetObjectId(idMakNom)	; МакНоменклатура. Присвоили ссылку, указав ID без загрузки ссылочного объекта
        s obj.ZHK	=ZHK					; Штрих-код	
		;   Актуальность (true,false) транслируем в (0=Неактуально,1=Актуально)
        s obj.Act=0                ; 0=Неактуально
		i Act="true" s obj.Act=1   ; 1=Актуально

 		;-- Транзакция записи
        d obj.%Save(0) s out.error=obj.ObjError() if out.error'="" q  ; Ошибка. Выход
	} // try
	
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Терминальная загрузка App.MAK.BarCode по макету ФЭ txt-файла
/// !!! TXT-файл должен быть на Cache-сервере  и сохранен в "Unicode" или UTF8.
/// Т.к. в общем инструменте пок нет txt-загрузки
/// 
/// k  d ##class(App.MAK.BarCode).ImportTxtFile("C:\InterSystems\Cache\CSP\maf\LoadFromFE\", "МАК-ЗШК (utf8).txt", 2)
/// 
ClassMethod ImportTxtFile(Dir As %String, FileTxt As %String, StartLine As %String)
{
 ; 
 ;       Dir -> Путь к директори на Cache-сервере  "C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 ;   FileTxt -> Имя TXT-файл       "МАК-ЗШК (utf8).txt"
 ; StartLine -> Номера тхт-строки, с которой начинается загрузка (пропустить заголовок)

 s (in,out)={}
 ;-- НУ по умолчанию
 i $g(Dir)="" s Dir="C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 i $g(FileTxt)="" s FileTxt="МАК-ЗШК (utf8).txt"
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
 		 	
 		 	s in.source.impCode			=$p(line,sep,1)	  ;Код	
  			s in.source.impZHK			=$p(line,sep,2)	  ;Штрих-код	
  			s in.source.impMakNomCode	=$p(line,sep,3)	  ;Код МакНоменклатуры	
  			s in.source.impMakNomName	=$p(line,sep,4)	  ;Наименование МакНоменклатуры	
  			s in.source.impAct			=$p(line,sep,5)	  ;Актуальность (true,false)	-> (0=Неактуально,1=Актуально)

 		 	
 		 	;-- Индикация
 		 	w !,"num=",num,$c(9),in.source.impCode,$c(9),in.source.impZHK,$c(9),in.source.impMakNomName
 		 	
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
/// d ##class(App.MAK.BarCode).ReSaveFiltr()
/// k ^App.MAK.BarCodeD1 m ^App.MAK.BarCodeD1=^App.CTL.ClassClassListD
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
/// d ##class(App.MAK.BarCode).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
 		{d ..ReSaveOne(id)}    ; Пересохранение одной записи
 		
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.MAK.BarCode).ReSaveOne(12153)
/// Переиндексация:  k ^App.MAK.BarCodeI d ##class(App.MAK.BarCode).%BuildIndices()
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
/// k  d ##class(App.MAK.BarCode).ReDelOne(12153)
/// Переиндексация:  k ^App.MAK.BarCodeI d ##class(App.MAK.BarCode).%BuildIndices()
/// k ^App.MAK.BarCodeD,^App.MAK.BarCodeI
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

Parameter XMLTYPE = "App-MAK-BarCode";

/// Актуальность
Property Act As Lib.DataTypes.String(DISPLAYLIST = ",Неактуально,Актуально", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",0,1") [ Required ];

/// Код
Property Code As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z", Unique = "Z") [ Required ];

/// Штрих-код
Property ZHK As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z") [ Required ];

/// Временное поле1
Property Temp1 As Lib.DataTypes.String(IndexValue = 1);

/// Мак-Номенклатура
Property idMakNom As App.MAK.Nomen [ Required ];

Index Act On Act As Truncate(200) [ Type = bitmap ];

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index ZHK On ZHK As Truncate(200) [ Type = bitmap ];

Index idMakNom On idMakNom [ Type = bitmap ];

ForeignKey fkidMakNom(idMakNom) References App.MAK.Nomen();

Storage Default
{
<Data name="BarCodeDefaultData">
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
<Value>Act</Value>
</Value>
<Value name="5">
<Value>Code</Value>
</Value>
<Value name="6">
<Value>ZHK</Value>
</Value>
<Value name="7">
<Value>idMakNom</Value>
</Value>
<Value name="8">
<Value>SourseSys</Value>
</Value>
<Value name="9">
<Value>SourceSys</Value>
</Value>
<Value name="10">
<Value>Temp1</Value>
</Value>
</Data>
<DataLocation>^App.MAK.BarCodeD</DataLocation>
<DefaultData>BarCodeDefaultData</DefaultData>
<IdLocation>^App.MAK.BarCodeD</IdLocation>
<IndexLocation>^App.MAK.BarCodeI</IndexLocation>
<StreamLocation>^App.MAK.BarCodeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

