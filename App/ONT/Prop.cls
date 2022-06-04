/// Свойства
Class App.ONT.Prop Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.ONT.Prop).%OpenId(1) d obj.addCheckSet({},{})  ; Запуск из терминала
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
		 if in.type="new" {s ..Code=..CounterCode     ; Хотя запись и новая, но счетчик ..CounterCode уже присвоен !!!
		 				   }
         ;
         ;-- Проверки         
         
         ;  ... и т.д
         ; 
         ;-- Преобразования
         ;s ..Name  =$ZCONVERT(..Name,"S")          ; Наименование - Первая буква текста - ВЕРХНЯЯ
         ;s ..ShName=$ZCONVERT(..ShName,"S")        ; Краткое наименование - Первая буква текста - ВЕРХНЯЯ
         ;s ..FinWords=##class(Lib.Util.Str).NormKitWords(..FinWords)   ; Нормализация набора поисковых слов 
         ;  ... и т.д
         
         ;-- Тихая замена значения настройки, если изменяемый код свойства используется в каких-либо настройках
         i in.type="edit"
         	{i ..Code'=in.oldRec.Code          ; Новый и старый коды не совпадают. Проверим, значится ли старый код в настройках
         	 	{; проход списку возможных настройкам, тихое изменение значения настройки
         	 	 ; Если такие настройки собраны под родительской, то можно их собрать автоматом. См.##class(Lib.App.Setup).MirTest()
         	 	 ;  
	         	 f NameSetUp="PropAppName","PropCntOneUpac","PropArticul"     ; Список настроек. Расширять по мере надобности. 
         	 	 	{s err=##class(Lib.App.Setup).GetSetup(NameSetUp,"","",.CodeSetUp,.idSetUp)  ;  Получить значение настройки и ее ID
 		     	     i (CodeSetUp'="")&&(CodeSetUp=in.oldRec.Code) 
 		     	        {s SetUp=##class(Lib.App.Setup).%OpenId(idSetUp)                    ; Загрузить настройку
 					 	 s SetUp.%FieldNoSave={"LibAppSetupValue":(..Code)}                 ; Заменить значение настройки. Пока через жопу ...
 					 	 d SetUp.%Save(0) s out.error=SetUp.ObjError() if out.error'="" q   ; и пересохраняем 
 		     	        }
	         	 	}
         	 	}
	         }



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
		
		;q:('in.edited)&&(in.type="edit")	        // При редактировании изменений нет. Выхожу
		
		;=== Снос индексов
		if in.type="delete"	    ; Редактирование или удаление. Снести индекс
 		     {;-- Проход по $lb(списку) Temp1
              s LiAbbr=in.oldRec.Temp1 f n=1:1:$ll(LiAbbr) 
              		{s Abbr=$lg(LiAbbr,n) i Abbr'="" d ..indDELETE(["Temp1-Abbr",(Abbr)],..%Id())}      ; Доп. индекс ("Temp1-Abbr",Abbr, ...)
		     }
		;=== Построить доп. индекс
		if (in.type'="delete") 
		    {;-- Проход по $lb(списку) Temp1
             s LiAbbr=..Temp1 f n=1:1:$ll(LiAbbr) 
               	{s Abbr=$lg(LiAbbr,n) i Abbr'="" d ..indINSERT(["Temp1-Abbr",(Abbr)],..%Id())}      ; Доп. индекс ("Temp1-Abbr",Abbr, ...)
		    }
  		
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
        if in.form="AppONTProp"                                            ;-- Для формы "AppONTProp"
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)    ; Поле "Кол-во классов"
			if in.field="gridCntNomen" s out.value=..GetCntNomen(.out)  ; Поле "Кол-во номенклатуры"  App.CTN.NomenVol
           
           }
		//=== 2. и т.д.
		//  .....
		
		// Конец. 
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// 
/// Кол-во использований в Классах
/// k  s val=##class(App.ONT.Prop).GetCntUsed(1) w !,val
Method GetCntUsed(ByRef out) As %String
{
	; На входе :
	;   id -> id записи "App.ONT.Prop"
	; На выходе :
	;   val <- Значение

	s val=""
	try {
		
		;-- Кол-во Классов (шаблонов)
		s filter=[{"field":"idProp", "type":"равно", "data":(..%Id())}]   ; все "App..." с id..
	    s out.error=##class(App.ONT.Pattern).Filter(.filter,.ind)    ;
		s val=..indCOUNT(.ind)                                       ; Кол-во записей App...
		s:val=0 val=""
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Кол-во номенклатуры
/// k  s val=##class(App.ONT.Class).GetCntNomen(1) w !,val
Method GetCntNomen(ByRef out) As %String
{
	; На входе :

	; На выходе :
	;   val <- Значение
	s val=""
	try {
		
		;-- Кол-во значений в номенклатуре
		s filter=[{"field":"idProp", "type":"равно", "data":(..%Id())}]      ; все "App..." с id..
	    s out.error=##class(App.CTN.NomenVol).Filter(.filter,.ind)      ;
		s val=..indCOUNT(.ind)                                 			; Кол-во записей App...
		;-- по триадам
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Пересохранение по фильтру
/// d ##class(App.ONT.Prop).ReSaveFiltr()
/// k ^App.ONT.PropD1 m ^App.ONT.PropD1=^App.CTL.ClassClassListD
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
/// d ##class(App.ONT.Prop).ReSaveAll()
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
/// k  d ##class(App.ONT.Prop).ReSaveOne(21)
/// Переиндексация:  k ^App.ONT.PropI d ##class(App.ONT.Prop).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
  
 ; --- Здесь что-то  ..
 ; 
 ;--- и пересохраняем
 d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Удаление одной записи
/// k  d ##class(App.ONT.Prop).ReDelOne(12153)
/// Переиндексация:  k ^App.ONT.PropI d ##class(App.ONT.Prop).%BuildIndices()
/// k ^App.ONT.PropD,^App.ONT.PropI,^App.ONT.PropC
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

Parameter XMLTYPE = "App-ONT-Prop";

Storage Default
{
<CounterLocation>^App.ONT.PropC</CounterLocation>
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
<Value>Group</Value>
</Value>
<Value name="12">
<Value>MethVol</Value>
</Value>
<Value name="13">
<Value>ReqEI</Value>
</Value>
<Value name="14">
<Value>TypeData</Value>
</Value>
<Value name="15">
<Value>idPropDet</Value>
</Value>
<Value name="16">
<Value>SourseSys</Value>
</Value>
<Value name="17">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.ONT.PropD</DataLocation>
<DefaultData>ClassDefaultData</DefaultData>
<IdLocation>^App.ONT.PropD</IdLocation>
<IndexLocation>^App.ONT.PropI</IndexLocation>
<StreamLocation>^App.ONT.PropS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Список уникальных ссылочных полей
Parameter listUnique;

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// Счетчик для кода
Property CounterCode As %Library.Counter;

/// Описание
Property Def As Lib.DataTypes.String(MAXLEN = 1024);

/// Группа
Property Group As Lib.DataTypes.String(DISPLAYLIST = ",Общая,МАЛ,ЕМИАС", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",all,mal,emias") [ Required ];

/// Способ заполнения значения по умолчанию
Property MethVol As Lib.DataTypes.String(DISPLAYLIST = ",из справочника,ручной ввод,расчетное,обобщенное", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",S,H,C,G") [ Required ];

/// Наличие ЕИ по умолчанию
Property ReqEI As Lib.DataTypes.String(DISPLAYLIST = ",обязательно,необязательно,запрещено", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",1,0,2") [ Required ];

/// Краткое наименование
Property ShName As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Временное поле
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Тип данных по умолчанию
Property TypeData As Lib.DataTypes.String(DISPLAYLIST = ",Строка,Действительное число,Целое число", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",str,car,int") [ Required ];

/// Детальное свойство по умолчанию для обобщенного
Property idPropDet As App.ONT.Prop;

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CounterCode On CounterCode [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Group On Group As Truncate(200) [ Type = bitmap ];

Index MethVol On MethVol As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index ReqEI On ReqEI As Truncate(200) [ Type = bitmap ];

Index ShName On ShName As Truncate(200) [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

Index TypeData On TypeData As Truncate(200) [ Type = bitmap ];

Index idPropDet On idPropDet [ Type = bitmap ];

ForeignKey fkidPropDet(idPropDet) References App.ONT.Prop();

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

