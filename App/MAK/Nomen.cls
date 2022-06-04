/// Мак-Номенклатура
Class App.MAK.Nomen Extends (%Persistent, Lib.Abstract.StorableTablesCode) [ Inheritance = right, Not ProcedureBlock ]
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.MAK.Nomen).%OpenId(11) d obj.addCheckSet({},{})  ; Запуск из терминала
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
	s out= {"error":""}
	try {
		;--- Всегда. Заполнение полей объекта при его создании или редактировании. Всякие контроли там.
		;!!! противоречит макету загрузки из ФЭ d ..makeObj(.in, .out) q:out.error'=""
		;
		} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Логические проверки и Заполнение полей объекта
/// 
Method makeObj(ByRef in, ByRef out)
{
	// На входе  : объект и ...	см. in.ххх
	// На выходе : out.error -> Сообщение об ошибке или пусто
	//		
	s out= {"error":""}
	try {
	    ;---- !!! Надо решить, какие атрибуты можно трогать при new и edit
	    ;  При edit нельзя менять:
	    ;	..Code 			; 	Код
		;	..idCtnNomen 	; 	Каталожная Номенклатура
		;   ..idFirm 		;  	Фирма-производитель
		;  но можно переустановить атрибуты, полученные от idCtnNomen и idCtnNomen
	    ;
        
        ;-- Запретить создание нового объекта при существовании с такими же idCtnNomen и ..idFirm
        i in.type="new"
        	{;-- Поиск существующей МАК-Номенклатуры по idCtnNomen и ..idFirm
	         k ind s filter=[{"field":"idCtnNomen",  "type":"равно", "data":(..idCtnNomen.%Id())}, {"oper":"AND"},
		    	             {"field":"idFirm", "type":"равно", "data":(..idFirm.%Id())}]
	    	 d ..Filter(.filter,.ind) 
	    	 s ptr="" d ..indNEXT(.ind,.ptr,.id) i id'=""
				 {s obj=..%OpenId(id) 
				  s out.error="Уже существует МАК-Номенклатура с кодом="_obj.Code_", образованная от Каталожной номенклатуры с кодом="_..idCtnNomen.Code_" и Фирмы-производителя с кодом="_..idFirm.Code q
				 }
        	}	
        
        ;-- Запретить изменение idCtnNomen и idCtnNomen при "edit"
        i in.type="edit" 
        	{i in.oldRec.Code      '=..Code             s out.error="Нельзя код МАК-Номенклатуры ее при редактировании." q
        	 i in.oldRec.idCtnNomen'=..idCtnNomen.%Id() s out.error="Нельзя менять Каталожную номенклатуру при редактировании МАК-Номенклатуры." q
	         i in.oldRec.idFirm    '=..idFirm.%Id()     s out.error="Нельзя менять фирму-производителя при редактировании МАК-Номенклатуры." q
	        }
       
	    ;-- Заполнение атрибутов при создании нового обекта
	    i in.type="new"
	       {s ..idLand = ..idFirm.idLand		;  	Страна фирмы-производителя
			s ..Name   = ..idCtnNomen.Name		;  	Наименование
			s ..ShName = ..idCtnNomen.ShName 	;  	Краткое наименование
			}
        ;-- Всегда переустанавливать атритуты, зависимые от idCtnNomen и idCtnNomen
			s:..Act="" ..Act=1 				    ; 	Актуальность записи (0=Неактуально,1=Актуально)
			;-- !! Писать методы получения ..getXXX
			;s ..NDS 							;..getNDS() 		НДС
			;s ..idMeasure 						;..getidMeasure() 	Единица отпуска
			;s ..idMnn 							;..getidMnn()  		МНН
			s:..OA="" ..OA=0					;..getOA() 			Обязательный ассортимент  (0=нет,1=да)
			s:..GNVLS="" ..GNVLS=0				;..getGNVLS() 		Группа ЖНВЛС/НПЛС/ (0=нет,1=ЖНВЛС,2=НПЛС)
			
			;-- Здесь Признак Отеч/Имп (1=Отеч,2=Имп) транслируется с конвертацией из App.NSI.Land (0=Отеч,1=Имп)
			s ..Import=2                               ; по умолчанию 2=Имп
			i ..idFirm.idLand.Import=0 s ..Import=1    ;        иначе 1=Отеч
	}	
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
		if in.form="AppMAKNomen"
			{if (in.field="gridName")!(in.field="gridAct") s:..Act=0 out.style={"CodeStyle":"27"}  ; Неактуально. Код стиля = 27 
			}
		
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Дополнительная функция при загрузке объекта, переопределяемая при использовании нестандартного алгоритма импорта</br>
/// </br>
/// Вход: </br>
/// 	in.form			- Имя формы																		</br>
/// 	in.namesection	- Имя секции-формата загрузки													</br>
/// 	in.filetype		- Тип файла ("txt","xlsx","xml","dbf")											</br>
/// 	in.regim		- Режим 1 - корректировка, 2 - дозапись											</br>
/// 	in.quote		- Удалять кавычки																</br>
/// 	in.space		- Удалять лишние пробелы														</br>
/// 	in.numrow		- Номер строки в файле															</br>
/// 	in.source		- Объект JSON с данными для сохранения (и определенные данные и неопределенные в одном) </br>
/// 	in.parentid		- ID родителя для ракурса														</br>
/// 	in.fieldparent	- Поле для ID родителя для ракурса												</br>
/// 	in.undefImpProps- Объект JSON с неопределенными в секции импорта данными, например {"undefImpProp1":"value1",...}
/// </br>
/// Выход: </br>	
/// 	out.error		- Сообщение об ошибке или пусто													</br>
/// 	out.continue	- Если 1, то в методе addImport руками переформировать строку до описанной в секции загрузки и вернуть ее в стандартный инструмент транзакции.</br>
/// 						  если 0, то строка не будет сохранена стандартным инструментом транзакции. Транзакцию обеспечить самостоятельно.</br>
ClassMethod addImport(ByRef in, ByRef out)
{
	s err=""
	try {
		s out.continue=0,out.error=""

		// !!! Здесь писать свой код
		;--1. Загрузка App.MAK.Nomen по макету ФЭ из форм:
		;    - "AppMAKNomen" -"Пакетная загрузка MAK.Nomen"
		if (in.form="AppMAKNomen")&&(in.namesection="Sec-ImpFE-XLSX")&&(in.filetype="xlsx")	{d ..addImportFE(.in,.out)}  ; 
		
		; !! Загрузки TXT еще нет. Ее временно замещает терминальный вариант ..ImportTxtFile
		;if (in.form="AppMAKNomen")&&(in.namesection="Sec-ImpFE-TXT")&&(in.filetype="txt")	{d ..addImportFE(.in,.out)}  ; 
		; 
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Загрузка App.MAK.Nomen по макету ФЭ
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
 		s Code         =str.impCode 		;Код МАК-Номенклатуры
 		s MainDubl     =str.impMainDubl		;Код лидера
 		s Name         =str.impName 		;Наименование
 		s ShName       =str.impShName 		;Краткое наименование
 		s FirmCode     =str.impFirmCode 	;Код Производителя
 		s FirmName     =str.impFirmName		;    Производитель
 		s LandCode     =str.impLandCode		;Код Страны
 		s LandName     =str.impLandName		;    Страна
 		s Import       =str.impImport		;Признак Отеч/Имп
 		s NDS          =str.impNDS			;НДС
 		s MeasureCode  =str.impMeasureCode	;Код Единица отпуска
 		s MeasureName  =str.impMeasureName	;    Единица отпуска
 		s MnnCode      =str.impMnnCode 		;Код МНН
 		s MnnName      =str.impMnnName		;    МНН
 		s OA           =str.impOA			;Обязательный ассортимент
 		s GNVLS        =str.impGNVLS		;Группа ЖНВЛС/НПЛС/
 		s CtnNomenCode =str.impCtnNomenCode	;Код Кат.Номен.
 		s Act          =str.impAct			;Актуальность записи
        
		;=== Проверки и получение ID'ов по кодам
		s (idMainDubl,idMeasure,idMnn)=""   ; НУ   
		;    1. Код Производителя
 		i FirmCode="" s out.error="Не задан Код Производителя. " q   ; Ошибка. Выход
 		s idFirm=##class(App.NSI.Firm).GetIdByCode(FirmCode) i idFirm="" s out.error="Нет Производителя с код="_FirmCode q     ; Ошибка. Выход
		;    2. Код Страны
 		i LandCode="" s out.error="Не задан Код Страны. " q   ; Ошибка. Выход
 		s idLand=##class(App.NSI.Land).GetIdByCode(LandCode) i idLand="" s out.error="Нет Страны с код="_LandCode q   ; Ошибка. Выход
		;    3. Код лидера
 		i MainDubl'="" s idMainDubl=..GetIdByCode(MainDubl) i idMainDubl="" s out.error="Нет Мак-Лидера дублей с код="_MainDubl q  ; Ошибка. Выход
		;    4. Код Единица отпуска
 		i MeasureCode'="" s idMeasure=##class(App.NSI.Measure).GetIdByCode(MeasureCode) i idMeasure="" s out.error="Нет Единицы отпуска с код="_MeasureCode q  ; Ошибка. Выход
		;    5. Код МНН
 		i MnnCode'="" s idMnn=##class(App.NSI.Mnn).GetIdByCode(MnnCode) i idMnn="" s out.error="Нет МНН с код="_MnnCode q  ; Ошибка. Выход
		;    6. Код Кат.Номен.
 		i CtnNomenCode="" s out.error="Не задан Код Каталожной номенклатуры." q   ; Ошибка. Выход
 		s idCtnNomen=##class(App.CTN.Nomen).GetIdByCode(CtnNomenCode) i idCtnNomen="" s out.error="Нет Каталожной номенклатуры с код="_CtnNomenCode q    ; Ошибка. Выход

        ;-- Поиск существующей Мак-Номенклатуры по ее коду
        s idMakNomen=..GetIdByCode(Code)
     	i idMakNomen'="" s obj=..%OpenId(idMakNomen)    ; Открыть существующий
		e                s obj=..%New()                 ; Создать новый.
		
		;-- Заполнение полей Мак-Номенклатуры
		s obj.Code=Code 	                                      ; Код
		;-- Каталожная Номенклатура.
		d obj.idCtnNomenSetObjectId(idCtnNomen)                   ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
		;-- Фирма-производитель.
		d obj.idFirmSetObjectId(idFirm) 	                      ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
		;-- Страна фирмы-производителя.
		d obj.idLandSetObjectId(idLand) 	                      ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
        ;-- Единица отпуска.
        i idMeasure'="" d obj.idMeasureSetObjectId(idMeasure)     ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
		e               s obj.idMeasure="" 	                      ; или пусто
	    ;-- МНН.
        i idMnn'="" d obj.idMnnSetObjectId(idMnn) 	              ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
		e           s obj.idMnn="" 	                              ;
        ;-- Лидер МАК-Номенклатура в пачке дублей
   	    i idMainDubl'="" d obj.IdMainDublSetObjectId(idMainDubl)  ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
		e                s obj.IdMainDubl="" 	                  ; 
        ;--
		s obj.Name    = Name 	   ; Наименование
		s obj.ShName  = ShName 	   ; Краткое наименование
		s obj.NDS     = NDS 	   ; НДС
		s obj.OA      = OA 	       ; Обязательный ассортимент (0=нет,1=да)
		s obj.GNVLS   = GNVLS 	   ; Группа ЖНВЛС/НПЛС/ …(0=нет,1=ЖНВЛС,2= НПЛС)
		s obj.Import  = Import 	   ; Признак Отеч/Имп (1=Отеч,2=Имп)
		;-- Актуальность записи (false,true) - так в строке файла
		;   транслируем в =0 или =1
        s obj.Act=0                ; 0=Неактуально
		i Act="true" s obj.Act=1   ; 1=Актуально
 		
 		;-- Транзакция App.MAK.Nomen
        d obj.%Save(0) s out.error=obj.ObjError() if out.error'="" q  ; Ошибка. Выход
	} // try
	
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Терминальная загрузка App.MAK.Nomen по макету ФЭ txt-файла
/// !!! TXT-файл должен быть на Cache-сервере  и сохранен в "Unicode" или UTF8.
/// Т.к. в общем инструменте пок нет txt-загрузки
/// 
/// 
/// k  d ##class(App.MAK.Nomen).ImportTxtFile("C:\InterSystems\Cache\CSP\maf\LoadFromFE\", "МАК-НОМ весь и в Юникод.txt", 2)
/// k  d ##class(App.MAK.Nomen).ImportTxtFile("C:\InterSystems\Cache\CSP\maf\LoadFromFE\", "МАК-НОМ проба(Юникод).txt", 2)
/// 
ClassMethod ImportTxtFile(Dir As %String, FileTxt As %String, StartLine As %String)
{
 ; 
 ;       Dir -> Путь к директори на Cache-сервере  "C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 ;   FileTxt -> Имя TXT-файл       "МАК-НОМ проба(Юникод).txt"
 ; StartLine -> Номера тхт-строки, с которой начинается загрузка (пропустить заголовок)

 s (in,out)={}
 ;-- НУ по умолчанию
 i $g(Dir)="" s Dir="C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 i $g(FileTxt)="" s FileTxt="МАК-НОМ проба(Юникод).txt"
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
	 	 	;s (in,out)={}
	 	 	s in.source={}
	 	 	s in.source.impCode 		=$p(line,sep,1)	;Код МАК-Номенклатуры
 		 	s in.source.impMainDubl		=$p(line,sep,2)	;Код лидера
 		 	s in.source.impName 		=$p(line,sep,3)	;Наименование
 		 	s in.source.impShName 		=$p(line,sep,4)	;Краткое наименование
 		 	s in.source.impFirmCode 	=$p(line,sep,5)	;Код Производителя
 		 	s in.source.impFirmName		=$p(line,sep,6)	;    Производитель
 		 	s in.source.impLandCode		=$p(line,sep,7)	; Код Страны
 		 	s in.source.impLandName		=$p(line,sep,8)	;     Страна
 		 	s in.source.impImport		=$p(line,sep,9)	;Признак Отеч/Имп
 		 	s in.source.impNDS			=$p(line,sep,10)	;НДС
 		 	s in.source.impMeasureCode	=$p(line,sep,11)	;Код Единица отпуска
 		 	s in.source.impMeasureName	=$p(line,sep,12)	;    Единица отпуска
 		 	s in.source.impMnnCode 		=$p(line,sep,13)	;Код МНН
 		 	s in.source.impMnnName		=$p(line,sep,14)	;    МНН
 		 	s in.source.impOA			=$p(line,sep,15)	;Обязательный ассортимент
 		 	s in.source.impGNVLS		=$p(line,sep,16)	;Группа ЖНВЛС/НПЛС/
 		 	s in.source.impCtnNomenCode	=$p(line,sep,17)	;Код Кат.Номен.
 		 	s in.source.impAct			=$p(line,sep,18)	;Актуальность записи 
 		 	
 		 	;-- Индикация
 		 	w !,"num=",num,$c(9),in.source.impCode,$c(9),in.source.impName
 		 	
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
/// d ##class(App.MAK.Nomen).ReSaveFiltr()
/// k ^App.MAK.NomenD1 m ^App.MAK.NomenD1=^App.CTL.ClassClassListD
ClassMethod ReSaveFiltr()
{
 try {
 	;-- Записи по фильтру
	; .. 
    k ind s filter=[{"field":"IdClass", "type":"равно","data":"8254"}]
	s err=..Filter(.filter,.ind)  if err'="" w $c(9),err q
    w !,"cnt=",..indCOUNT(.ind)
   ;-- Проход по записям
   s ptr="" while ..indNEXT(.ind,.ptr,.id) 
 		{s err=""
	 	 w !,"id=",id
	 	 ;d ..ReSaveOne(id) s err=..ObjError()    ;
	 	 ;d ..%DeleteId(id) s err=..ObjError()
		 ;if err'="" w $c(9),err q    
 		 ;else       w $c(9),"...исправлено" 
 		 ;else       w $c(9),"...удалено" 
 		}
 		
    	}
 catch exp {d ..ErrorDetect(.exp)} // catch 	
 q
}

/// Пересохранение всех записей
/// d ##class(App.MAK.Nomen).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s Max=0
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
  		{d ..ReSaveOne(id)    ; Пересохранение одной записи
 
 		}
 w !!,Max
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.MAK.Nomen).ReSaveOne(1)
/// Переиндексация:  k ^App.MAK.NomenI d ##class(App.MAK.Nomen).%BuildIndices()
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
/// k  d ##class(App.MAK.Nomen).ReDelOne(12153)
/// Переиндексация:  k ^App.MAK.NomenI d ##class(App.MAK.Nomen).%BuildIndices()
/// k ^App.MAK.NomenD,^App.MAK.NomenI,^App.MAK.NomenC
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

Parameter XMLTYPE = "App-MAK-Nomen";

Storage Default
{
<Data name="NomenDefaultData">
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
<Value>GNVLS</Value>
</Value>
<Value name="7">
<Value>HashDubl</Value>
</Value>
<Value name="8">
<Value>IdMainDubl</Value>
</Value>
<Value name="9">
<Value>Import</Value>
</Value>
<Value name="10">
<Value>Kol</Value>
</Value>
<Value name="11">
<Value>NDS</Value>
</Value>
<Value name="12">
<Value>Name</Value>
</Value>
<Value name="13">
<Value>OA</Value>
</Value>
<Value name="14">
<Value>ShName</Value>
</Value>
<Value name="15">
<Value>idCtnNomen</Value>
</Value>
<Value name="16">
<Value>idDublCtnNom</Value>
</Value>
<Value name="17">
<Value>idFirm</Value>
</Value>
<Value name="18">
<Value>idLand</Value>
</Value>
<Value name="19">
<Value>idMeasure</Value>
</Value>
<Value name="20">
<Value>idMnn</Value>
</Value>
<Value name="21">
<Value>SourseSys</Value>
</Value>
<Value name="22">
<Value>SourceSys</Value>
</Value>
<Value name="23">
<Value>Temp1</Value>
</Value>
<Value name="24">
<Value>SpecName</Value>
</Value>
<Value name="25">
<Value>CabCode</Value>
</Value>
</Data>
<DataLocation>^App.MAK.NomenD</DataLocation>
<DefaultData>NomenDefaultData</DefaultData>
<IdLocation>^App.MAK.NomenD</IdLocation>
<IndexLocation>^App.MAK.NomenI</IndexLocation>
<StreamLocation>^App.MAK.NomenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Актуальность записи
Property Act As Lib.DataTypes.String(DISPLAYLIST = ",Неактуально,Актуально", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",0,1");

/// Код
Property Code As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z", Unique = "Z") [ Required ];

/// Группа ЖНВЛС/НПЛС/
Property GNVLS As Lib.DataTypes.String(DISPLAYLIST = ",нет,ЖНВЛС, НПЛС", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",0,1,2");

/// ХЭШ для дублей МАК-Номенклатуры
Property HashDubl As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// МАК-Номен. лидер в пачке дублей
Property IdMainDubl As App.MAK.Nomen;

/// Признак Отеч/Имп
Property Import As Lib.DataTypes.String(DISPLAYLIST = ",Отеч,Имп", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",1,2");

/// Количество в упаковке
Property Kol As Lib.DataTypes.String(MAXLEN = 1024);

/// НДС
Property NDS As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Наименование
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P") [ Required ];

/// Обязательный ассортимент
Property OA As Lib.DataTypes.String(DISPLAYLIST = ",нет,да", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",0,1");

/// Краткое наименование
Property ShName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P") [ Required ];

/// Временное поле (id-перенесенной ФЭ-записи)
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Каталожная Номенклатура
Property idCtnNomen As App.CTN.Nomen [ Required ];

/// Замененный ID-Катал.Позиции
Property idDublCtnNom As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Производитель
Property idFirm As App.NSI.Firm [ Required ];

/// Страна производителя
Property idLand As App.NSI.Land;

/// Единица отпуска
Property idMeasure As App.NSI.Measure;

/// МНН
Property idMnn As App.NSI.Mnn;

/// Код кабинета = id в таблице nomenclature кабинета
/// Kalinin A.M. Для задачи Alliance-781 Сопоставить товары
/// !!! НЕ УДАЛЯТЬ !!!
Property CabCode As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Kalinin A.M.
/// Для поиска аналогов позициям прайса <br>
/// !!! НЕ УДАЛЯТЬ !!!
Property SpecName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Kalinin A.M.
/// Метод формирования описания для поиска и сравнения
/// !!! НЕ УДАЛЯТЬ !!!
/// s n=##class(App.MAK.Nomen).%OpenId(4792)  d n.setSpecName()
Method setSpecName()
{
	try {
		s err = ""
		
		s specName = ..Name_" "_..idFirm.Name_" "_..idLand.Name
		s specName = $ZSTRIP(specName,"=W")
		;w !,specName
		
		s matcher = ##class(%Regex.Matcher).%New("(?<=\D)\.(?=\d)",specName)
		s specName = matcher.ReplaceAll(". ") 								; сокращения с точками отделяем пробелами от чисел, "шамп.280 Пит.,укреп." => "шамп. 280 Пит.,укреп."
		;w !,specName
		
		s specName = ##class(App.SPR.Synonym).OriginaliseStringV3(specName)	; Замена синонимов оригиналами
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
/// d ##class(App.MAK.Nomen).SetAllSpecName()
ClassMethod SetAllSpecName()
{
	s ts1 = $ZTS
	s id = ""
	&SQL(DECLARE cur CURSOR FOR
		SELECT id INTO :id
		FROM App_MAK.Nomen
		WHERE specname IS NULL
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

Index CabCode On CabCode As Truncate(200) [ Type = bitmap ];

Index SpecName On SpecName As Truncate(200) [ Type = bitmap ];

ForeignKey fkIdMainDubl(IdMainDubl) References App.MAK.Nomen();

ForeignKey fkidCtnNomen(idCtnNomen) References App.CTN.Nomen();

ForeignKey fkidFirm(idFirm) References App.NSI.Firm();

ForeignKey fkidLand(idLand) References App.NSI.Land();

ForeignKey fkidMeasure(idMeasure) References App.NSI.Measure();

ForeignKey fkidMnn(idMnn) References App.NSI.Mnn();

Index Act On Act As Truncate(200) [ Type = bitmap ];

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index GNVLS On GNVLS As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index HashDubl On HashDubl As Truncate(200) [ Type = bitmap ];

Index IdMainDubl On IdMainDubl [ Type = bitmap ];

Index Import On Import As Truncate(200) [ Type = bitmap ];

Index NDS On NDS As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index OA On OA As Truncate(200) [ Type = bitmap ];

Index ShName On ShName As Truncate(200) [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

Index idCtnNomen On idCtnNomen [ Type = bitmap ];

Index idDublCtnNom On idDublCtnNom As Truncate(200) [ Type = bitmap ];

Index idFirm On idFirm [ Type = bitmap ];

Index idLand On idLand [ Type = bitmap ];

Index idMeasure On idMeasure [ Type = bitmap ];

Index idMnn On idMnn [ Type = bitmap ];

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

