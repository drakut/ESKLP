/// Каталожная номенклатура
Class App.CTN.Nomen Extends (%Persistent, Lib.Abstract.StorableTablesCode)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.CTN.Nomen).%OpenId(1) d obj.addCheckSet({},{})  ; Запуск из терминала
/// 
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
	//	s id=..%Id()
	//	s name=in.oldRec.Name	// Получить поле из Старого тела записи
	//	s name=..Name			// Получить поле из Нового тела записи
	s err="",out.error=""
	try {

       	 ;-- На новой записи Формирование Кода=  ..CounterCode
		 ;включить перед началом эксплуатации if in.type="new" s ..Code=..CounterCode     ; Хотя запись и новая, но счетчик ..CounterCode уже присвоен !!!
         s ..shrLong=$l(..ShName)   ;	Количество символов краткой нотации

         ;
         ;-- Проверки         
         
         ;  ... и т.д
         ; 
         ;-- Преобразования
         
         ;s ..Name  =$ZCONVERT(..Name,"S")          ; Наименование - Первая буква текста - ВЕРХНЯЯ
         ;s ..ShName=$ZCONVERT(..ShName,"S")        ; Краткое наименование - Первая буква текста - ВЕРХНЯЯ
         ;s ..FinWords=##class(Lib.Util.Str).NormKitWords(..FinWords)   ; Нормализация набора поисковых слов 
         ;  ... и т.д
         ;
		} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Перед удалением..
///  Получатели ссылки (реципиенты):
///  	App.CTN.NomenBarCode -> idNomen, 
///  	App.CTN.NomenVol	 -> idNomen,   !! здесь засада с детальными и обобщенн 
///  	App.CTN.NomenVolFirm -> idNomen, 
///  	App.PRC.Nomen		 -> idNomen, 
///  	App.PRC.Nomen		 -> idNomenAuto
/// 
/// s obj=##class(App.CTN.Nomen).%OpenId(13) d obj.addBeforeDelete({},{}) w  ; Запуск из терминала
/// 
Method addBeforeDelete(ByRef in, ByRef out)
{
	// На входе :
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=..%Id()
	//	s name=..Name			// Получить поле из Нового тела записи
	s out={"error":""}
	try {
        s ClassName=$CLASSNAME($This)    ; Имя класса текущего объекта
		;-- Удаление всех подчиненных объектов. Сам объект не удаляется.
		;
		;   Проверки ...
		;s h=$zh
		;-- 1. Можно удалять, если отсутствуют Прайсы (там два ссылочных атрибута) с удаляемой КП:
		;     App.PRC.Nomen->idNomen, 
		s filter=[{"field":"idNomen","type":"равно","data":(..%Id())}]				
	    s out.error=##class(App.PRC.Nomen).Filter(.filter,.ind) q:out.error'=""
        if ..indCOUNT(.ind)'=0 s out.error="Нельзя удалять КП с код="_..Code_". Уже есть Прайсы, с ней связанные по ссылочному атрибуту 'idNomen'" q    ;
 		;      App.PRC.Nomen->idNomenAuto		
		s filter=[{"field":"idNomenAuto","type":"равно","data":(..%Id())}]				
	    s out.error=##class(App.PRC.Nomen).Filter(.filter,.ind) q:out.error'=""
        if ..indCOUNT(.ind)'=0 s out.error="Нельзя удалять КП с код="_..Code_". Уже есть Прайсы, с ней связанные по ссылочному атрибуту 'idNomenAuto'" q    ;

        ;-- 2. Можно удалять, если отсутствует МакНоменклатура "App.MAK.Nomen"->idNomen
		s filter=[{"field":"idCtnNomen","type":"равно","data":(..%Id())}]				
	    s out.error=##class(App.MAK.Nomen).Filter(.filter,.ind) q:out.error'=""
        if ..indCOUNT(.ind)'=0 s out.error="Нельзя удалять КП с код="_..Code_". Уже есть МакНоменклатура, с ней связанная" q    ;
		;w !!,"time1=",$zh-h 

		;-- 3. Корректное удаление пакета значений свойств текущей КП, т.к. нельзя удалять обобщенные значения раньше детальных
		d ..DelPropVolAll(.out) q:out.error'=""    ;

		;   Теперь запустить типовое каскадное удаление
		;-- Корректное ТИПОВОЕ удаление всех подчиненных объектов текущего объекта. Общий метод
		; !! Во всех подчиненных объектах, которые сами дают ссылки нижестоящим объектам, добавить этот метод .addBeforeDelete
		s out.error=##class(Lib.Util.Table).DelRecSubTab(ClassName,..%Id()) i out.error'="" q  
		;w !!,"time3=",$zh-h 
		;   
		
	
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Корректно удалить всю пачку значений свойств по текущей КП.  Метод объекта КП
/// 	По текущей КП получить пакет значений свойств
/// 	Из этого пакета удалять только не обобщенные. Обобщенные удалятся вместе с детальными автоматически
/// 	
/// k  s obj=##class(App.CTN.Nomen).%OpenId(10) d obj.DelPropVolAll({}) w  ; Запуск из терминала
Method DelPropVolAll(ByRef out)
{
	// На входе :
	//				Объект текущей КП
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто

 try {
        ;s h=$zh
        s idNomen=..%Id()    ; ID- КП
		;--  Получить массив значений свойств по Каталожной позиции
		d ##class(App.CTN.NomenVol).getArrVolPropNomen(idNomen,.arrVol,.out) q:out.error'=""   ;
		;    .arrVol("ID",idVolProp)    =objVolProp     ; массив объектов значений по id
		;    .arrVol("Code",КодСвойства)=objVolProp     ; массив объектов значений по кодам свойств 
        ;w !! zw arrVol
        
        ;-- Проход по значениям свойств КП
        s idVolProp="" 
        f  {s idVolProp=$o(arrVol("ID",idVolProp)) q:out.error'=""  q:idVolProp=""
            s obj=arrVol("ID",idVolProp)      ; объект "App.CTN.NomenVol"
            i '$ISOBJECT(obj.idVol) 
        			{ ; Текущее значение не словарное.Удаляем его смело
                      d ##class(App.CTN.NomenVol).%DeleteId(idVolProp) s out.error=..ObjError() q:out.error'="" 
                      continue   ;  Следующий.       
        			}
            ;-- Проверяем текущее значение свойства на обобщенность. 
            ;   Такое значение удалять не будем. 
            ;   Оно удалится автоматически при удалении детального
            ;   
            s idPattGen =obj.idPatt.%Id()     ; ID-Шаблон
		    s idVolGen  =obj.idVol.%Id()      ; ID-Словарное значение                      			
            ;w !,"idVolProp=",idVolProp
            ;continue
            
            ;-- Ищем в "App.ONT.PatternVol"-обобщенные значения
            ;		idPattDet	Детальная строка шаблона		App.ONT.Pattern
            ;		idVolDet	Детальное значение свойства		App.ONT.VolProp
            ;		idPattGen	Обобщенная строка шаблона		App.ONT.Pattern
            ;		idVolGen	Обобщенное значение свойства	App.ONT.VolProp
            k ind s filter=[{"field":"idPattGen", "type":"=","data":(idPattGen)},{"oper":"AND"},
                            {"field":"idVolGen",  "type":"=","data":(idVolGen)}]
            d ##class(App.ONT.PatternVol).Filter(.filter,.ind)
            i ..indCOUNT(.ind)'=0 continue    ; Текущее значение является обобщенным. Не удаляем его. Следующий ...
            ;-- В руках не обобщенное значение.            
            ;   Удаляем его. Обобщенные удалятся вместе с детальными автоматически
            ;s h=$zh
            d ##class(App.CTN.NomenVol).%DeleteId(idVolProp) s out.error=..ObjError() q:out.error'="" 
            ;w $c(9),"time=",$zh-h   
          }
     ;w !!,"time=",$zh-h   
     }
 
 catch exp {s out.error=..ErrorDetect(.exp)}
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
		;=== Маркировать колонку "name":"gridName", "caption":"Описание полное", "style":77, - Предупреждение не пусто
		if in.form="AppCTNNomen"
			{if in.field="gridName" s:..getWarning(.in, .out)'="" out.style={"CodeStyle":"77"}  ; Текст Предупреждения не пуст. Код стиля = 77 
			}
		
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Получить текст предупреждения по текущей КП 
/// k  s obj=##class(App.CTN.Nomen).%OpenId(1) w !,obj.getWarning(.in, .out)
/// 
/// s out.value=..getWarning(.in,.out)
/// 
Method getWarning(ByRef in, ByRef out) As %String
{
	; 
	; На входе  : объект текущей КП
	; На выходе : Warning и out.Warning  - Текст предупреждения или пусто
	; 
	s Warning=""
	try {
	    ;-- Не совпадают полные описания
	    d ..GetDescriptionProp(..%Id(),.Name,.ShName)	      ; Получить полное  и краткое  описания
	    i ..Name'=Name     s Warning="Несовпадение сохраненного и сформированного Полного описания='"_Name_"'"              ; Описание полное
		i ..ShName'=ShName s Warning=Warning_$c(13,10)_"Несовпадение сохраненного и сформированного Краткого описания='"_ShName_"'"     ; Описание краткое
        ;w !,"Полное"
        ;w !,..Name,!,Name 
        ;w !,"Краткое"
        ;w !,..ShName,!,ShName w !
	    
	    ;-- Неполный набор обязательных свойств
	    ;  ??
		
	    }	
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q Warning
}

/// Вызов функции с клиента
/// 
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
	// else			  {s out.typejob="job"  j ..Process()}
    s out={"error":""}
	try {
		;== Запуск формирования описаний по ! ОДНОЙ "App.CTN.Nomen" из формы:"AppCTNNomen", секции редактирования:"Sec-Toolbar-Edit" по кнопке:"MakeDescriptionOne"
		if in.namecall="MakeDescriptionOne" 
		    {s out.typejob="fast"	             ; Задача исполняется НЕ фоне
			 s idNomen=in.actualid
			 i idNomen'="" d ..doDescription(idNomen, "rProp", "rFirm", .out)   ; Занести полное, краткое и по Фирмам описание в Катал.Позицию
			 s out.refresh=1                     ; Обновить экран после транзакции
		    }
		;== Запуск формирования описаний по ! МНОГИМ "App.CTN.Nomen" из формы:"AppCTNNomen", секции кнопок :"Sec-Toolbar" по кнопке:"MakeDescriptionAll"
		elseif in.namecall="MakeDescriptionAll" 
		    {s out.typejob="job"	              ; Задача исполняется В фоне
			 ;s ^mir($i(^mir))=in.filter.%ToJSON()
			 ;s ^mir($i(^mir))=in.%ToJSON()
			 ;  Динамический объект .in передаем через преобразование его в JSON-строку
			 j ..doDescriptionAll(in.%ToJSON())   ; Запуск формирования описаний "App.CTN.Nomen" по фильтру
			 s out.refresh=1                      ; Обновить экран после транзакции
		    }
	    ;== Запуск ....
	    ;

	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Массовая Транзакция сформированных описаний в МНОГО КП
/// Запускается в фоне из местного .addCallClient
/// 
/// k  s out={"error":""},in={} d ##class(App.CTN.Nomen).doDescriptionAll(.in,.out) w !,"out.error=",out.error
ClassMethod doDescriptionAll(ByRef in, ByRef out)
{
	// На входе :
	//		   in.form -> Имя формы
	//	   in.typecall -> Источник вызова ("toolbar" - кнопка на панели задач и т.д.)
	//	   in.namecall -> Имя действия (Для "toolbar" - имя кнопки и т.д.)
	//	   in.actualid -> ID текущей строки в форме
	//		 in.jobnum -> Номер задания для фоновых задач
	//		 in.filter -> фильтр для поиска
	//		   in.data -> Дополнительные данные для задачи (определяются клиентом)
  
  s out={"error":""}
  try {
        s in=[].%FromJSON(in)     ; Восстанавливаем динамический обект in из JSON-строки
 		; !!! Отдадка
 		;s in.jobnum=22 d ..indOR2(.ind,[(..#indAll)])   ; Все
	
		;--- Анонс этапа/процесса
	    s msg="Формирование описаний" d ..SetTempParam(in.jobnum,"message",msg)

        s filter=in.filter 		
 		s out.error=##class(App.CTN.Nomen).Filter(.filter,.ind) q:out.error'=""
		
		;--  Количество записей всего
        s TotCnt=..indCOUNT(.ind),Cnt=0 d ..SetTempParam(in.jobnum,"allrecords",TotCnt)

		;-- Проход по фильтру
 		s ptr="" while ..indNEXT(.ind,.ptr,.idNomen)			
			{;w !,idNomen
	     	 ;s ^tempmir(idNomen)=""
	     	 ;  ...
 		 	 d ..GetTempParam(in.jobnum,"stop",.stop) i stop=1 d ..SetTempParam(in.jobnum,"end",1) q   ; Остановиться, если клиент дал команду stop
         	 ;-- Запуск единичной транзакции по КП
         	 ;   Индикация ошибки единичной транзакции. Выход
 	     	 d ..doDescription(idNomen, "rProp", "rFirm", .out) i out.error'="" {d ..SetTempParam(in.jobnum,"error",out.error) q}   ; Запуск 
 	     	 ;-- Тик. Индикация процесса
		 	 s Cnt=Cnt+1 d ..SetTempParam(in.jobnum,"taktrecords",Cnt)   ; Количество обработаных записей         
		 	 d ..SetTempParam(in.jobnum,"message","Обработано "_Cnt)     ; Индикация
			}      
    ;-- Финал фона общий
    d ..SetTempParam(in.jobnum,"end",1)             ; сигнал конца
    d ..SetTempParam(in.jobnum,"refresh",1)         ; сигнал на обновление экрана из фона
    d ..SetTempParam(in.jobnum,"error",out.error)   ; Сообщить клиенту об ошибке.
    }
 catch exp {s out.error=..ErrorDetect(.exp)} // catch
 q
}

/// Единичная Транзакция сформированных описаний. Занести полное, краткое или по Фирмам описание в Катал.Позицию
/// k   d ##class(App.CTN.Nomen).doDescription(1, "rProp", "rFirm", .out) w
/// 
ClassMethod doDescription(id As %Integer, rProp As %String, rFirm As %String, ByRef out)
{
	; На входе :
	;             id  -> id записи "App.CTN.Nomen"
	;  rProp ="rProp" -> Занести "Описание полное" и "Описание краткое"
	;  rFirm ="rFirm" -> Занести "Описание по Фирмам"
	;	
	s out={"error":""}
	try {
        s save=0             ; НУ
        s obj=..%OpenId(id)  ; Загрузка Катал.Позиции в память
		
		;-- Изнение "Описание полное" и "Описание краткое"
		i rProp ="rProp" 
			{s out.error=..GetDescriptionProp(id,.Name,.ShName) q:out.error'=""  ; Получить полное и краткое описание по КП
			 i obj.Name  '=Name   s obj.Name=Name,save=1      ;w !,"полное"      ; изменилось полное описание
			 i obj.ShName'=ShName s obj.ShName=ShName,save=1  ;w !,"краткое"     ; изменилось краткое описание
			}
		;-- Изменение описание по Фирмам по КП
		i rFirm ="rFirm" 
			{s out.error=..GetDescriptionFirm(id,.DescFirm) q:out.error'=""  ; Получить описание по Фирмам по КП
			 i obj.DescFirm'=DescFirm s obj.DescFirm=DescFirm,save=1   ;w !,"фирмы"  ; изменилось описание по Фирмам по КП
			}
		
		;-- Изменился ХЭШ-код по свойствам ??
		;
		
		;-- Транзакция в случае любого изменения
		i save=1 d obj.%Save(0) s out.error=..ObjError() i out.error'="" q   ; Выход по ошибке		
		;w !,"save=",save 
		} // try
	
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Получить тексты полного и краткого описание по катал.позиции
/// k  s err=##class(App.CTN.Nomen).GetDescriptionProp(3,.Name,.ShName) w
ClassMethod GetDescriptionProp(id As %Integer, Name As %String, ShName As %String)
{
	; На входе :
	;       id -> id записи "App.CTN.Nomen"
	;     Name <- Описание полное
	;	ShName <- Описание краткое
	;	
	s out={"error":""},err=""
	try {
		s (Name,ShName)=""   ; НУ
	    ;-- Код свойства "Количество в упаковке" из настройки
	    s err=##class(Lib.App.Setup).GetSetup("PropCntOneUpac","","",.CodePropCntOneUpac,.idSetUp) q:err'=""  ;  Получить значение настройки и ее ID (здесь не нужен)
	    i CodePropCntOneUpac="" s (err,out.error)="Нет настройки 'Код свойства 'Количество в упаковке''" q
	    
	    ;-- Все значения свойств текущей номенкл.позиции
		k ind s filter=[{"field":"idNomen", "type":"равно", "data":(id)}] ; все App.CTN.NomenVol с id
	    s out.error=##class(App.CTN.NomenVol).Filter(.filter,.ind) i out.error'="" s err=out.error q   ;
		i ..indCOUNT(.ind)=0 q                                            ; Текущая номенкл.позиция не имеет ни одного заполненного свойства. Выход.
		;w !,"cnt=",..indCOUNT(.ind)
		;-- проход по значениям свойств
		s ptr="" while ..indNEXT(.ind,.ptr,.idVol)
				{s objVol=##class(App.CTN.NomenVol).%OpenId(idVol)  ; Загрузка значения свойства в память
				 ;w !,"idVol=",idVol
				 s CodeProp = objVol.idProp.Code	        ; Код Свойства
				 s MethVol  = objVol.idPatt.MethVol	        ; Способ заполнения значения  (S=Из справочника, H=Ручной ввод, C=Расчетное)
			     ;-- Цикл по полному и краткому описанию
				 for n="F","S" 
				   {s Val="" ; НУ
					i n="F" s fUsDis="UsDisF",fNum="NumF",fLoVal="LoValF",fSiL="SiLF",fSiR="SiRF"  ; Настройка полей для полного описания
				    i n="S" s fUsDis="UsDisS",fNum="NumS",fLoVal="LoValS",fSiL="SiLS",fSiR="SiRS"  ; Настройка полей для краткого описания
				    ;-- Поля правил из Шаблона
				    s UsDis = $PROPERTY(objVol.idPatt,fUsDis)	 ; Использование свойства в .. описании  (1=Да,0=Нет)
				    s Num   = $PROPERTY(objVol.idPatt,fNum)	     ; Номер следования свойства в .. описании
				    s LoVal = $PROPERTY(objVol.idPatt,fLoVal)	 ; Вид значения свойства в .. описании (F=полное,S=краткое,L=латинское)
				    s SiL   = $PROPERTY(objVol.idPatt,fSiL)	     ; Доп. символы слева в .. описании
				    s SiR   = $PROPERTY(objVol.idPatt,fSiR)	     ; Доп. символы справа в .. описании			
                    ;-- Исполнение правил
 					i UsDis =1   ; Свойство участвует в описании
 						{;-- Значение из словаря
 						 i (MethVol="S")!((MethVol="G"))             ; S=Из справочника или G=обобщенное
 							{;-- Если назначено краткое словарное значение, а оно пустое, то используется полное словарное значение
 					 	 	 s Val=objVol.idVol.FulVol                ; всегда берем F=Словарное полное
 					 	 	 i (LoVal="S")&&(objVol.idVol.ShrVol'="") s Val=objVol.idVol.ShrVol   ; S=Словарное краткое, если оно не пустое. Иначе Val остается с полным значением
 					 	 	 i LoVal="L" s Val=objVol.idVol.LngVol    ; L=Словарное латинское
 							}
 						 ;-- Ручной ввод или вычисляемый 
 						 i (MethVol="H")!(MethVol="C")               ;H=Ручной ввод
 							{i LoVal="F" s Val=objVol.fullVolHand    ;F=Ручное значение полное
 					 	 	 i LoVal="S" s Val=objVol.shortVolHand   ;S=Ручное значение краткое
 				     	 	 i LoVal="L" s Val=objVol.altVolHand     ;L=Ручное значение латинское
				   			} 				     
 						 ;-- ЕИ
 						 i objVol.idEi'="" s Val=Val_objVol.idEi.Iden1   ; Подклеиваем ЕИ - Обозначение1 строчными
			 			 ;-- Символы слева/справа
 						 ;   На свойстве(код=22) "Количество в упаковке" =1. Затираем левый символ и значение ("N1"). Оставляем правый символ
						 i (CodeProp=CodePropCntOneUpac)&(Val=1) s (Val,SiL)=""  
			 			 s Val=SiL_Val_SiR                       ; Подклеиваем символы слева/справа
			 			 s arr(n,Num)=Val         ; Массив значений в нужном порядке для полного описани("F",Num) и краткого("S",Num)
 						}  ; конец Исполнение правил
 					}      ; конец Цикл по полному и краткому описанию
 				}          ; конец Проход по значениям свойств

    ;-- Финал. Сборка описаний.
 	;   Проход по arr("F",Num) и arr("S",Num)
	s n="" f i=1:1  s n=$o(arr("F",n)) q:n=""  s Name  =Name_arr("F",n)_" " 
	s n="" f i=1:1  s n=$o(arr("S",n)) q:n=""  s ShName=ShName_arr("S",n)_" "
	s Name  =$zstrip(Name,"<>w")     ; Удаление ведущих и хвостовых пробелов
	s ShName=$zstrip(ShName,"<>w")   ; Удаление ведущих и хвостовых пробелов
	;-- Сделать ТОЛЬКО первый символ в верхнем регистре $ZCONVERT(string,"S")  - Первая буква текста - ВЕРХНЯЯ
	s Name=$ZCONVERT($e(Name,1),"S")_$e(Name,2,$l(Name))
	s ShName=$ZCONVERT($e(ShName,1),"S")_$e(ShName,2,$l(ShName))
	;
	
	;w !	zw arr
	}
	catch exp {s (err,out.error)=..ErrorDetect(.exp)} // catch 	
	q err
}

/// Получить текст описания по Фирмам по КП
/// k  s err=##class(App.CTN.Nomen).GetDescriptionFirm(1,.DescFirm) w
ClassMethod GetDescriptionFirm(id As %Integer, DescFirm As %String)
{
	; На входе :
	;          id -> id записи "App.CTN.Nomen"
	;    DescFirm <- Описание по Фирмам
	;	
	s out={"error":""},err=""
	try {
		s (DescFirm,txtFirm,txtLand)=""   ; НУ
	    ;-- Все значения свойств по Фирмам текущей катал.позиции
		k ind s filter=[{"field":"idNomen", "type":"равно", "data":(id)}] ; все App.CTN.NomenVol с id
	    s out.error=##class(App.CTN.NomenVolFirm).Filter(.filter,.ind) i out.error'="" s err=out.error q   ;
		i ..indCOUNT(.ind)=0 q                                   ; Текущая катал.позиция не имеет ни одного заполненного свойства. Выход.
		;w !,"cnt=",..indCOUNT(.ind)
		;-- проход по значениям свойств
		s ptr="" while ..indNEXT(.ind,.ptr,.idVol)
				{s objVol=##class(App.CTN.NomenVolFirm).%OpenId(idVol)  ; Загрузка значения свойства в память
				 s NameFirm ="" i $ISOBJECT(objVol.idFirm) s NameFirm = objVol.idFirm.ShName     ; Наименование Фирмы для нотации или пусто
				 s NameLand="" i objVol.idFirm.idLand'="" s NameLand=objVol.idFirm.idLand.Name   ; Наименование страны из фирмы или пусто
				 ;-- Набираем список неповторяющихся названий фирм и стран
                 i (NameFirm'="")&&('$d(arr("F",NameFirm))) s txtFirm=txtFirm_NameFirm_",",arr("F",NameFirm)=""
                 i (NameLand'="")&&('$d(arr("L",NameLand))) s txtLand=txtLand_NameLand_"/",arr("L",NameLand)=""   
				}
 		;-- Финал
 		i txtFirm'="" s txtFirm=$e(txtFirm,1,($l(txtFirm)-1))_" "  ; Отрежем последнюю "," и подклеим пробел к списку Фирм
 		s DescFirm=txtFirm_txtLand
 		i DescFirm'="" s DescFirm=$e(DescFirm,1,($l(DescFirm)-1))  ; Отрежем последний "/"
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q err
}

/// Получить ХЭШ-код значений свойств текущей КП
/// k  s obj=##Class(App.CTN.Nomen).%OpenId(2),HCode=obj.getHashCodeP(.out)
/// 
Method getHashCodeP(ByRef out)
{
  ;  На входе: текущая КП - объект
  ;  На выходе: 
  ;     HashCode <- ХЭШ-код значений свойств текущей КП
  ;         .out <- 
 s out={"error":""},(HCode,HLine)=""
 try {
  	 s idNomen=..%Id()   ; ID-КП
  	 ;-- Получить массив значений свойств Каталожной позиции
	 d ##class(App.CTN.NomenVol).getArrVolPropNomen(idNomen, .ArrVolNomen, .out)
	 ;	 .ArrVolNomen <- ArrVolNomen=idNomen 
	 ;	            	 ArrVolNomen("Code",КодСвойства)=objVolProp        ; массив значений по кодам свойств 
	 ;	                 ArrVolNomen("ID",idЗначенияСвойства)=objVolProp   ; массив значений по ID-значений свойств
  	 ;-- Проход по значениям свойств
 	 s CodeProp="" 
 	 f  {s CodeProp=$o(ArrVolNomen("Code",CodeProp)) q:CodeProp=""
 	 	 s objVol=ArrVolNomen("Code",CodeProp)     ; Объект значения "App.CTN.NomenVol"
 	 	 ; пропустить обобщенные и расчетные свойства, они не участвуют в ХЭШировании
	 	 i (objVol.idPatt.MethVol="C")!(objVol.idPatt.MethVol="G") continue  ; Свойство расчетное или Свойство обобщенное. Следущий ..
 		 ; -- ОК, дальше ...
 		 s SubLine=objVol.getSubLine(.out)  ;Получить нормализованную ХЭШ-подстроку по "App.CTN.NomenVol"
 		 s HLine=HLine_SubLine_"~"   ;
 	 	}
 	 ;-- Финал
 	 i HLine'="" s HLine=$e(HLine,1,($l(HLine)-1))    ; Подрезка строки
 	 s HCode=$SYSTEM.Encryption.MD5Encode(HLine)      ; Получить ХЭШ-код
 	 ;w !!,HLine
  	} // try

 catch exp {s out.error=..ErrorDetect(.exp)} // catch
 q HCode
}

/// Получить ХЭШ-код значений свойств Фирм текущей КП
/// k  s obj=##Class(App.CTN.Nomen).%OpenId(2),HCode=obj.getHashCodeF(.out)
/// 
Method getHashCodeF(ByRef out)
{
  ;  На входе: текущая КП - объект
  ;  На выходе: 
  ;     HashCode <- ХЭШ-код значений свойств Фирм текущей КП
  ;         .out <- 
 s out={"error":""},(HCode,HLine)=""
 try {
  	 s idNomen=..%Id()   ; ID-КП
  	 /*  ; Переделать для Фирм
  	 ;-- Получить массив значений свойств Каталожной позиции
	 d ##class(App.CTN.NomenVol).getArrVolPropNomen(idNomen, .ArrVolNomen, .out)
	 ;	 .ArrVolNomen <- ArrVolNomen=idNomen 
	 ;	            	 ArrVolNomen("Code",КодСвойства)=objVolProp        ; массив значений по кодам свойств 
	 ;	                 ArrVolNomen("ID",idЗначенияСвойства)=objVolProp   ; массив значений по ID-значений свойств
  	 ;-- Проход по значениям свойств
 	 s CodeProp="" 
 	 f  {s CodeProp=$o(ArrVolNomen("Code",CodeProp)) q:CodeProp=""
 	 	 s objVol=ArrVolNomen("Code",CodeProp)     ; Объект значения "App.CTN.NomenVol"
 	 	 ; пропустить обобщенные и расчетные свойства, они не участвуют в ХЭШировании
	 	 i (objVol.idPatt.MethVol="C")!(objVol.idPatt.MethVol="G") continue  ; Свойство расчетное или Свойство обобщенное. Следущий ..
 		 ; -- ОК, дальше ...
 		 s SubLine=objVol.getSubLine(.out)  ;Получить нормализованную ХЭШ-подстроку по "App.CTN.NomenVol"
 		 s HLine=HLine_SubLine_"~"   ;
 	 	}
 	 ;-- Финал
 	 i HLine'="" s HLine=$e(HLine,1,($l(HLine)-1))    ; Подрезка строки
 	 s HCode=$SYSTEM.Encryption.MD5Encode(HLine)      ; Получить ХЭШ-код
 	 ;w !!,HLine
  	*/
  	} // try

 catch exp {s out.error=..ErrorDetect(.exp)} // catch
 q HCode
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
	s out.value=""
	try {
        ;=== 1. Для формы "AppCTNNomen"
        if (in.form="AppCTNNomen")&&(in.field="gridCntUsed")   ; .. пока не используется Поле "Кол-во использований"
        	{s out.value=..GetCntUsed(..%Id())}                  ; Кол-во использований
		
      	;===2. Хинт. Текст предупреждения для КП. 
 		if (in.form="AppCTNNomen")&&(in.field="hintWarning") {s out.value=..getWarning(.in,.out)}
		
		//=== . и т.д.
		//  .....
		
	} // try
	catch exp {s (err,out.error)=..ErrorDetect(.exp)} // catch
	q
}

/// 
/// Кол-во использований
/// .. пока не используется
/// k  s val=##class(App.CTN.Nomen).GetCntUsed(1) w !,val
ClassMethod GetCntUsed(id As %Integer) As %String
{
	; На входе :
	;   id -> id записи "App.CTN.Nomen"

	; На выходе :
	;   val <- Значение

	s out={"error":""}
	try {
		s val=""
		s val="доделать"
		
		;s filter=[{"field":"idLand", "type":"равно", "data":(id)}]       ; все "App..." с idEi
	    ;s out.error=##class(App.NSI.Firm).Filter(.filter,.ind)     ;
		;s val=..indCOUNT(.ind)                                 ; Кол-во записей App.CTN.NomenVol по idEi
		
		s:val=0 val=""
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Переформирование Каталожной Позиции. 
/// - обновляются поля описаний КП
/// - обновляются поля ХЭШ-кодов КП
/// 
/// k   d ##class(App.CTN.Nomen).doReformation(5, .out) w
ClassMethod doReformation(id As %Integer, ByRef out)
{
 ;	       id -> Id-каталожной позиции (КП)
 ;	out.error <- Текст ошибки
 ;	
 s out={"error":""}
 try {
	  s Reform=0    ; НУ. Флаг изнениения че-нить 

        s obj=..%OpenId(id)  ; Загрузка Катал.Позиции в память
		
		;-- Изнение "Описание полное" и "Описание краткое"
		s out.error=..GetDescriptionProp(id,.Name,.ShName) q:out.error'=""    ; Получить полное и краткое описание по КП
		i obj.Name  '=Name   s obj.Name=Name,Reform=1      ;w !,"полное"      ; изменилось полное описание
		i obj.ShName'=ShName s obj.ShName=ShName,Reform=1  ;w !,"краткое"     ; изменилось краткое описание
		
		;-- Изменение описание по Фирмам по КП
		s out.error=..GetDescriptionFirm(id,.DescFirm) q:out.error'=""            ; Получить описание по Фирмам по КП
		i obj.DescFirm'=DescFirm s obj.DescFirm=DescFirm,Reform=1   ;w !,"фирмы"  ; изменилось описание по Фирмам по КП
		
		;-- Изменился ХЭШ-код по свойствам
		i obj.HashP'=obj.getHashCodeP(.out) s obj.HashP=obj.getHashCodeP(.out),Reform=1   ;w !,"ХЭШ-код" ; 
		
		;-- Изменился ХЭШ-код по свойствам Фирм
		;i obj.HashF'=obj.getHash???(.out) s obj.HashF=obj.getHash???(.out),Reform=1  ;
		
		
		;-- Транзакция в случае любого изменения
		i Reform=1 d obj.%Save(0) s out.error=..ObjError() i out.error'="" q   ; Выход по ошибке		
	 
	 
 	 } // try
 catch exp {s out.error=..ErrorDetect(.exp)} // catch
 q
}

/// Пересохранение по фильтру
/// d ##class(App.CTN.Nomen).ReSaveFiltr()
/// k ^App.CTN.NomenD1 m ^App.CTN.NomenD1=^App.CTL.ClassClassListD
ClassMethod ReSaveFiltr()
{
 try {
 	;-- Записи по фильтру
	; .. 
    k ind s filter=[{"field":"Code", "type":"не пусто","data":1}]
	d ..Filter(.filter,.ind)
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
/// d ##class(App.CTN.Nomen).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
  		{;d ..ReSaveOne(id)    ; Пересохранение одной записи
        
        q:id>100
        ;-- Показать КП не входящие в Прайсы
        k ind s filter=[{"field":"idNomen", "type":"равно","data":(id)}]
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)
        s cnt=..indCOUNT(.ind)
        i cnt=0 
        	{s obj=..%OpenId(id)  ; Загрузка объекта в память
        	 w !,"id=",id," код=",obj.Code
        	}
  		
  		/*
  		;-- Перенос из ФЭ в MAF каталожных позиций, которые потеряли значения свойств при предыдущем их переносе
        k ind s filter=[{"field":"idNomen", "type":"равно","data":(id)}]
	    d ##class(App.CTN.NomenVol).Filter(.filter,.ind)
        s cnt=..indCOUNT(.ind)
        i cnt=0 
        	{;-- Зачистить ссылку на КП в Прайсе
        	 k ind1 s filter1=[{"field":"idNomen", "type":"равно","data":(id)}]
	    	 d ##class(App.PRC.Nomen).Filter(.filter1,.ind1)
	    	 s ptr="" while ..indNEXT(.ind1,.ptr,.idPrc) 
	    		{s objPrc=##class(App.PRC.Nomen).%OpenId(idPrc)
	    		 s objPrc.idNomen=""
	    		 d objPrc.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err continue
	    		}	
	         
	    ; .. продолжаем
	         s obj=..%OpenId(id)  ; Загрузка объекта MAF в память
	         w !,"idNomen=",id," code=",obj.Code
        	 s (in,out)={},idMAF=##class(App.SOAP.ImportFE).TransOneCTNNomen(obj.Code,.in,.out)
        	 ;-- Удаление
        	 i idMAF="" 
        	 		{d obj.%DeleteId(id) s err=obj.ObjError() 
        	 		 i err="" w $c(9),"удалено" continue
        	 		 i err'="" w !,$c(9),err continue
        	 		}
        	 i out.error="" w $c(9),"пересено" continue
        	 i out.error'="" w !,$c(9),out.error continue
        	 
        	}
    */
 		}

 q
}

/// Пересохранение одной записи
/// k  d ##class(App.CTN.Nomen).ReSaveOne(1)
/// Переиндексация:  k ^App.CTN.NomenI d ##class(App.CTN.Nomen).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 
 ; --- Здесь что-то  ..
 s obj.Temp1="" 

 ;--- и пересохраняем
 d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Удаление одной записи
/// k  d ##class(App.CTN.Nomen).ReDelOne(10)
/// 
/// Переиндексация:  k ^App.CTN.NomenI d ##class(App.CTN.Nomen).%BuildIndices()
/// k ^App.CTN.NomenD,^App.CTN.NomenI,^App.CTN.NomenC
ClassMethod ReDelOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 ;-- Удаление
 d obj.%DeleteId(id) s err=obj.ObjError() if err'="" w !,$c(9),err q   // Выход по ошибке
 q
}

/// Kalinin A.M.
/// Метод формирования описания для поиска и сравнения
/// !!! НЕ УДАЛЯТЬ !!!
/// s n=##class(App.CTN.Nomen).%OpenId(33945)  d n.setSpecName()
Method setSpecName()
{
	try {
		s err = ""
		k query
		s query = 1
		s query(1) ="SELECT "_
					"	nomenvol.Npp,"_
					"	pattern.NumF,"_
					"	CASE "_
					"		WHEN prop.id=43 ! prop.id=44 ! prop.id=50 ! prop.id=55"_
					"		THEN STRING( COALESCE(FulVol,''),' ',COALESCE(LngVol,''), ' ', COALESCE(altVolHand,''),' ',COALESCE(fullVolHand,'') ) "_
					"		ELSE STRING( COALESCE(SiLF,''), COALESCE(fullVolHand,''), COALESCE(nomenvol.idEi->Iden1,''), COALESCE(FulVol,'') ) "_
					"	END AS notationpart "_
					"FROM App_CTN.NomenVol as nomenvol "_
					"LEFT JOIN App_ONT.Prop AS prop ON nomenvol.idProp = prop.id "_
					"LEFT JOIN App_ONT.VolProp AS volprop ON nomenvol.idVol = volprop.id "_
					"LEFT JOIN App_ONT.Pattern AS pattern ON nomenvol.idpatt = pattern.id "_
					"WHERE idNomen = "_..%Id()_
					" AND UsDisF = 1 "_
					"ORDER BY pattern.NumF"
		s statement	= ##class(%SQL.Statement).%New()
		s status	= statement.%Prepare(.query)
		i status'=$$$OK {
			s err = $SYSTEM.Status.GetErrorText(status)
			q
		}
		s resultSet = statement.%Execute()
		s specName = ""
		while resultSet.%Next() {
			s specName = specName_resultSet.%Get("notationpart")_" "
		}
		s specName = $E(specName,1,$L(specName)-1)
		s out = {}
		s specName = $ZSTRIP(specName,"=W")
		s ..SpecName = ##class(App.MAF.Linker).DeleteDublicateWords(specName, out) ; удаление повторяющихся пробелов
		d ..%Save()
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
	}
	q err
}

/// Установка специального наименования для поиска у всех каталожных позиций
/// d ##class(App.CTN.Nomen).SetAllSpecName()
ClassMethod SetAllSpecName()
{
	s ts1 = $ZTS
	
	k ptr,id
	s count = 0
	while ..indNEXT([(..#indAll)],.ptr,.id) {
		i $I(count)
		q:count>100
		w !,id
		s nomen = ..%OpenId(id)
		d nomen.setSpecName()
		w $C(9),nomen.SpecName
	}
	s ts2 = $ZTS
	w "Time elapsed:", ##class(Lib.Util.DateTime).DeltaMS(ts1,ts2)
}

/// Лабораторная работа. Получить список idVol
/// d ##class(App.CTN.Nomen).MirLab("ТАЙСС",2)
/// d ##class(App.CTN.Nomen).MirLab("ФОРМУЛА",2)
/// d ##class(App.CTN.Nomen).MirLab("формула",2)
ClassMethod MirLab(word As %String, idProp As %Integer) As %String
{
  ;  На входе:
   ;   word -> строка значения свойства
   ; idProp -> Id-Свойства
   ;  На выходе: 
   ; LiIdVol <- Список через запятую idVol ("App.ONT.VolProp"), содержащих значение свойства и используемое как значение свойства с idProp

	s ts1 = $ZH
	s LiIdVol=""
    ;
    ;FulVol		Значение полное
    ;NrFulVol	Нормализованное Значение полное
    ;ShrVol		Значение краткое
    ;LngVol		Значение на альтернативном языке
    
    ;-- Поиск word в словаре "App.ONT.VolProp"
    s filter=[{"field":"FulVol","type":"содержит","data":(word)},{"oper":"OR"},
              {"field":"NrFulVol","type":"содержит","data":(word)},{"oper":"OR"}, 
              {"field":"ShrVol","type":"содержит","data":(word)},{"oper":"OR"}, 
              {"field":"LngVol","type":"содержит","data":(word)},{"oper":"OR"}                   
               ]				
    
	k ind d ##class(App.ONT.VolProp).Filter(.filter,.ind)
	w !,"кол-во всего записей с фрагментом '"_word_"' в едином словаре=",..indCOUNT(.ind)
	
	;== Поиск word как используемого значения свойства idProp
	;-- Используемый значения свойства idProp
	;   ("idVol-Prop",idProp, ..) -> все idVol по Свойству idProp 
	k indUsed d ##class(App.CTN.NomenVol).indOR2(.indUsed,["idVol-Prop",(idProp)])
	w !,"кол-во всяких значений свойства idProp, используемых в Каталожных позициях =",..indCOUNT(.indUsed)
    
    ;-- Используемый значения свойства idProp, содерщащие фрагмент word
    k indRez d ##class(App.CTN.NomenVol).indAND(.indRez,.indUsed,.ind)
	w !,"кол-во записей в словаре с фрагментом '"_word_"' и используемых в свойстве idProp =",..indCOUNT(.indRez)
	
	;-- Формирование списка через запятую idVol ("App.ONT.VolProp")
	k ptr while ..indNEXT(.indRez,.ptr,.idVol) {s LiIdVol=LiIdVol_","_idVol}
    
    ;-- Финал.
	w !,"Time=",$zh-ts1
 q LiIdVol
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 0;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-CTN-Nomen";

/// Список уникальных ссылочных полей
Parameter listUnique = ",idClass";

Storage Default
{
<CounterLocation>^App.CTN.NomenC</CounterLocation>
<Data name="NomenDefaultData">
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
<Value>CounterCode</Value>
</Value>
<Value name="6">
<Value>DescFirm</Value>
</Value>
<Value name="7">
<Value>HashF</Value>
</Value>
<Value name="8">
<Value>HashP</Value>
</Value>
<Value name="9">
<Value>Name</Value>
</Value>
<Value name="10">
<Value>ShName</Value>
</Value>
<Value name="11">
<Value>Temp1</Value>
</Value>
<Value name="12">
<Value>Temp2</Value>
</Value>
<Value name="13">
<Value>shrLong</Value>
</Value>
<Value name="14">
<Value>idClass</Value>
</Value>
<Value name="15">
<Value>SpecName</Value>
</Value>
<Value name="16">
<Value>SourseSys</Value>
</Value>
<Value name="17">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.CTN.NomenD</DataLocation>
<DefaultData>NomenDefaultData</DefaultData>
<IdLocation>^App.CTN.NomenD</IdLocation>
<IndexLocation>^App.CTN.NomenI</IndexLocation>
<StreamLocation>^App.CTN.NomenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Счетчик для кода
Property CounterCode As %Library.Counter [ Required ];

/// Описание по Фирмам
Property DescFirm As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// ХЭШ-код уникальности свойств по предприятиям
Property HashF As Lib.DataTypes.String(MAXLEN = 1024);

/// ХЭШ-код уникальности потребительских свойств
Property HashP As Lib.DataTypes.String(MAXLEN = 1024);

/// Описание полное
Property Name As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Описание краткое
Property ShName As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Временное поле1
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Временное поле2
Property Temp2 As Lib.DataTypes.String(MAXLEN = 1024);

/// Класс
Property idClass As App.ONT.Class [ Required ];

/// Кол-во символов краткого описания
Property shrLong As Lib.DataTypes.Integer(IndexValue = 1);

/// Kalinin A.M.
/// Для поиска аналогов позициям прайса <br>
/// !!! НЕ УДАЛЯТЬ !!!
Property SpecName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CounterCode On CounterCode [ Type = bitmap ];

Index DescFirm On DescFirm As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index ShName On ShName As Truncate(200) [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

Index idClass On idClass [ Type = bitmap ];

Index shrLong On shrLong [ Type = bitmap ];

ForeignKey fkidClass(idClass) References App.ONT.Class();

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

