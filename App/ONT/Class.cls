/// Классы
Class App.ONT.Class Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

/// Перед удалением.
/// Если по удаляемому классу нет КаталНомен ("App.CTN.Nomen")
/// удаляем подчиненные таблицы (пока только "App.ONT.Pattern")
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
		;-- Можно ли удалять ?  Проверки ...
		;   Можно удалять, если отсутствует номенклатура "App.CTN.Nomen" с удаляемым классом 
		s filter=[{"field":"idClass","type":"равно","data":(..%Id())}]				
	    s out.error=##class(App.CTN.Nomen).Filter(.filter,.ind) q:out.error'=""
        if ..indCOUNT(.ind)'=0 s out.error="Нельзя удалять класс. Уже есть Каталожная номенклатура." q    ;
        ; ...
		
		;-- Удаление всех подчиненных объектов. Сам объект там не удаляется.
		d ..DelSubTab(..%Id(),.out) i out.error'="" q     ; Корректное удаление всех подчиненных объектов.
	
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Корректное удаление всех подчиненных объектов. Сам объект там не удаляется !!!
/// 
/// k  s out={"error":""} d ##class(App.ONT.Class).DelSubTab(12,.out) w !,out.error
ClassMethod DelSubTab(id As %Integer, ByRef out)
{
 ;         id -> id-Удаляемой записи
 ;  out.error <- Сообщение об ошибке или пусто
 ;
 s out={"error":""}
 try {
 ; SWT. Получить описание свойств класса и описание параметров класса с учётом предков класса
 s err=$CLASSMETHOD($This,"GetAllProperties",.p,.c)   ; это -> d ..GetAllProperties(.p,.c) 
 ;   .p  - json. Инфо о свойствах полей этого класса
 ;   .c  - json. Инфо о параметрах класса
 ;-- Проход по Классам-Реципиентам
 for i=0:1:c.Donor.%Size()-1 
		{s NameSubClass=c.Donor.%Get(i).class   ; Имя класса-реципиента  
		 ;w !,"Класс-реципиент : ",NameSubClass
		 s NameFlf=c.Donor.%Get(i).field        ; Имя поля ссылки на донора в классе-реципиенте  ;w " Свойство-реципиент : ",NameFlf
	     ;-- Сбор подчиненных записей в классе-реципиенте 
	     k ind s filter=[{"field":(NameFlf),"type":"равно","data":(id)}]				
         s out.error=$CLASSMETHOD(NameSubClass,"Filter",.filter,.ind) q:out.error'=""   
         ;w $c(9),"cnt=",..indCOUNT(.ind)
 		 
 		 ; Проход по подчиненным
 		 s ptr="" while ..indNEXT(.ind,.ptr,.idRef)
 		  	 	   {;w !,$c(9),NameSubClass," id=",idRef                           ; 
 				    d $CLASSMETHOD(NameSubClass,"%DeleteId",idRef)     ; Удалить запись подчиненной таблицы  ...
 				    s out.error=..ObjError() if out.error'="" q 
 				   }	 				  		
		}
   }
 catch exp {d ..ErrorDetect(.exp)} // catch 	
 q
}

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.ONT.Class).%OpenId(1) d obj.addCheckSet({},{})  ; Запуск из терминала
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
		 if in.type="new" s ..Code=..CounterCode     ; Хотя запись и новая, но счетчик ..CounterCode уже присвоен !!!

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
        if in.form="AppONTClass"           ;-- Для формы "AppONTClass"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)    ; Поле "Кол-во свойств"
			if in.field="gridCntNomen" s out.value=..GetCntNomen(.out)  ; Поле "Кол-во номенклатуры"
           }
		
		//=== 2. и т.д.
		//  .....
		
		// Конец. 
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// "Кол-во свойств"
/// k  s out="",obj=##class(App.ONT.Class).%OpenId(2) w !, obj.GetCntUsed(.out)
Method GetCntUsed(ByRef out) As %String
{
	; На входе  :  текущий объект
	; На выходе :  val <- Значение
    s val=""
	try {
		
		;-- Кол-во свойств
		s filter=[{"field":"idClass", "type":"равно", "data":(..%Id())}]     ; все "App..." с id..
	    d ##class(App.ONT.Pattern).Filter(.filter,.ind)       ;
		s val=..indCOUNT(.ind)                                 			; Кол-во записей App.ONT.Pattern
		s:val=0 val=""
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Кол-во номенклатуры
/// k  s out="",obj=##class(App.ONT.Class).%OpenId(2) w !, obj.GetCntNomen(.out)
Method GetCntNomen(ByRef out) As %String
{
	; На входе :
	;   id -> id записи "App..."
	; На выходе :
	;   val <- Значение
	s val=""
	try {
		;-- Кол-во номенклатуры
		s filter=[{"field":"idClass", "type":"равно", "data":(..%Id())}]     ; все "App..." с id..
	    s out.error=##class(App.CTN.Nomen).Filter(.filter,.ind)         ;
		s val=..indCOUNT(.ind)                                 			; Кол-во записей App.CTN.Nomen
		;-- по триадам
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Вызов функции с клиента
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
	//	       in.data.idclass -> Здесь это idClass1 из поисковой формы для запуска метода ##class(App.ONT.Pattern).CopyPattern(idClass1,idClass2,.out)
	//		     	 			 {"caption":"Копировать свойства к текущий класс от другого класса","idclass":"7"}
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//	  out.typejob -> Метод исполнения задачи ("fast" - задача исполняется быстро, не в фоне, "job" - задача исполняется медленно, в фоне)
	//	  out.message -> Сообщение для клиента (выводится в модальном окне)
	// Примеры : (см. также в Lib.App.ImportError)
	// if (TotCnt<100) {s out.typejob="fast" d ..Process()}
	// else			  {s out.typejob="job"  j ..Process()}
    s out={"error":""}
	try {
		
	   // !!! Здесь писать свой код
   	    ;== Запуск "Копировать свойства к текущий класс от другого класса"
	    if in.namecall="CopyPattern" 
		    {s out.typejob="fast"	      ; Задача исполняется НЕ фоне
			 s idClass2=in.actualid       ; ID-Класса2 - приемника
			 s idClass1=in.data.idclass   ; ID-Класса1 - источника
			 i idClass1'="" d ##class(App.ONT.Pattern).CopyPattern(idClass1,idClass2,.out) q:out.error'=""    ; Запуск процедуры копирования
			 s out.refresh=1              ; Обновить экран после транзакции
		    }

	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Вызов обработки события на клиенте с сервера					</br>
/// Вход:	in = {} - входные параметры для получения инструкций для манипуляций с формой</br>
/// 		in.event	->	событие, которое вызвало обработку		</br>
/// 		in.construct->	имя конструкции							</br>
/// 		in.form		->	имя формы								</br>
/// 		in.type		->	тип секции: toolbar, grid,...			</br>
/// 		in.idrecord	->	id записи								</br>
/// 		in.idparent	->	id родительской записи					</br>	
/// Выход:	out = {} - содержит с каким элементом какой секции что сделать
/// 		out.form	->	имя формы								</br>
/// 		out.type	->	тип секции: toolbar, grid,...			</br>
/// 		out.element	->	id элемента секции						</br>
/// 		out.action	->	действие: enable, disable,...			</br>
/// 		out.data	-> JSON, TODO, задел на будущее, например, новые данные для списка</br>
/// 		out.error	-> ошибки</br>
/// 		
///    В секции "grid" описания формы нужен параметр 	"events":{"onSelectRow":"$$"},
ClassMethod addEvent(ByRef in, ByRef out)
{
	s err = ""
	try {
		// !!! Здесь пишем свой код
		s out={"error":""} 
		s out.form = in.form
		s out.type = in.type

	if in.construct="AppONTPattern"	          ; Имя конструкции
		{i in.event = "SelectRow"  	          ; Cобытие: "Выбор строки"
		     {s commands	 = []			  ; НУ. Будущий массив действий над формой
			  ;s clientAction = "enable"	  ; НУ. Все управляемые элементы в состоянии "Включено"
			  s clientAction = "disable"	  ; НУ. Все управляемые элементы в состоянии "Выключено"
		      
		      ;-- Анализ текущей строки верхней формы конструктора
		      ;     Выключаем кнопку "Копировать .." на строках классов с набором свойств
		      ;   и Включаем на классах без свойств
	 	      s idClass=in.idrecord
			  
			  i idClass'=""
			  		{;-- Проверка Класса на отсутсвие строк-свойств
    		  		 ;   Поиск в Шаблоне по idClass
              		 k ind s filter=[{"field":"idClass","type":"равно","data":(idClass)}]				
	          		 s out.error=##class(App.ONT.Pattern).Filter(.filter,.ind) q:out.error'=""
              		 i ..indCOUNT(.ind)=0 s clientAction="enable"   ; Включить
		     		}
              
              ;-- Отключение перечисленных кнопок на верхней форме "AppONTClass"
              f button="CopyPattern"       ; Перечень оключаемых кнопок. Пока одна ...
            		{s command			= {}
	            	 s command.form		= in.form
				 	 s command.type		= "toolbar"
				 	 s command.element	= button
				 	 s command.action	= clientAction			
				 	 d commands.%Push(command)
	            	}
		     }
		;-- Финал
		s out.commands = commands
		}

	}
	catch exp {s err=..ErrorDetect(.exp),out.error=err}
	q
}

/// Пересохранение по фильтру
/// d ##class(App.ONT.Class).ReSaveFiltr()
/// k ^App.ONT.ClassD1 m ^App.ONT.ClassD1=^App.CTL.ClassClassListD
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
/// d ##class(App.ONT.Class).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s Max=0
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
 
 		{;d ..ReSaveOne(id)    ; Пересохранение одной записи
 		 ; Ищем максимальное кол-во строк в шаблоне
 		 k ind1
 		 s filter=[{"field":"IdClass","type":"равно","data":(id)}]
 		 s error=##class(App.CTL.Pattern).Filter(.filter,.ind1) q:error'=""
 		 s cnt=##class(App.CTL.Pattern).indCOUNT(.ind1)
         w !,id,$c(9),cnt
         i cnt>Max s Max=cnt w $c(9),Max 
 		}
 w !!,Max
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.ONT.Class).ReSaveOne(12153)
/// Переиндексация:  k ^App.ONT.ClassI d ##class(App.ONT.Class).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 w !,"IdClass=",obj.IdClass.%Id()
 
 ; --- Здесь что-то  ..
 ;s filter=[{"field":"IdClass","type":"равно","data":(id)}]
 ;s error=##class(App.CTL.Pattern).Filter(.filter,.ind) q:error'=""
 ;s cnt=##class(App.CTL.Pattern).indCOUNT(.ind)

 ;--- и пересохраняем
 ;d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Удаление одной записи
/// k  d ##class(App.ONT.Class).ReDelOne(12153)
/// Переиндексация:  k ^App.ONT.ClassI d ##class(App.ONT.Class).%BuildIndices()
/// k ^App.ONT.ClassD,^App.ONT.ClassI,^App.ONT.ClassC
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
Parameter Related = 0;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-ONT-Class";

Storage Default
{
<CounterLocation>^App.ONT.ClassC</CounterLocation>
<Data name="ClassDefaultData">
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
<Value>CounterCode</Value>
</Value>
<Value name="7">
<Value>Def</Value>
</Value>
<Value name="8">
<Value>Name</Value>
</Value>
<Value name="9">
<Value>ShName</Value>
</Value>
<Value name="10">
<Value>Temp1</Value>
</Value>
<Value name="11">
<Value>SourseSys</Value>
</Value>
<Value name="12">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.ONT.ClassD</DataLocation>
<DefaultData>ClassDefaultData</DefaultData>
<IdLocation>^App.ONT.ClassD</IdLocation>
<IndexLocation>^App.ONT.ClassI</IndexLocation>
<StreamLocation>^App.ONT.ClassS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// Счетчик для кода
Property CounterCode As %Library.Counter;

/// Описание
Property Def As Lib.DataTypes.String(MAXLEN = 1024);

/// Краткое наименование
Property ShName As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Временное поле
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CounterCode On CounterCode [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index ShName On ShName As Truncate(200) [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

