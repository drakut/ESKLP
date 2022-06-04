/// Словарь значений свойств
Class App.ONT.VolProp Extends (%Persistent, Lib.Abstract.StorableTablesCode)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.ONT.VolProp).%OpenId(1) d obj.addCheckSet({},{})  ; Запуск из терминала
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
         s ..NrFulVol=##class(Lib.Util.Str).NormKitWordsFE(..FulVol)   ; Нормализованное Значение полное по правилам ФЭ !!
         
         ;----------------
         ;s ..Name  =$ZCONVERT(..Name,"S")          ; Наименование - Первая буква текста - ВЕРХНЯЯ
         ;s ..ShName=$ZCONVERT(..ShName,"S")        ; Краткое наименование - Первая буква текста - ВЕРХНЯЯ
         ;s ..FinWords=##class(Lib.Util.Str).NormKitWords(..FinWords)   ; Нормализация набора поисковых слов 
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
		
		;q:('in.edited)&&(in.type="edit")	        // При редактировании изменений нет. Выхожу
		
		;=== Снос индексов
		if in.type="delete"	    ; Редактирование или удаление. Снести индекс
 		     {;-- Проход по $lb(списку Кодов значений) Temp1
              s Li=in.oldRec.Temp1 f n=1:1:$ll(Li) {s Val=$lg(Li,n) i Val'="" d ..indDELETE(["Temp1-Code",(Val)],..%Id())}   ; Доп. индекс ("Temp1-Code",CodeFE, ...)
		      ;-- Проход по $lb(списку ID-значений) Temp2
              s Li=in.oldRec.Temp2 f n=1:1:$ll(Li) {s Val=$lg(Li,n) i Val'="" d ..indDELETE(["Temp2-idFE",(Val)],..%Id())}   ; Доп. индекс ("Temp2-idFE",idFE, ...)
		     }
		;=== Построить доп. индекс
		if (in.type'="delete") 
		    {;-- Проход по $lb(списку Кодов значений) Temp1
             s Li=..Temp1 f n=1:1:$ll(Li) {s Val=$lg(Li,n) i Val'="" d ..indINSERT(["Temp1-Code",(Val)],..%Id())}   ; Доп. индекс ("Temp1-Code",CodeFE, ...)
 			 ;-- Проход по $lb(списку ID-значений) Temp2
             s Li=..Temp2 f n=1:1:$ll(Li) {s Val=$lg(Li,n) i Val'="" d ..indINSERT(["Temp2-idFE",(Val)],..%Id())}   ; Доп. индекс ("Temp2-idFE",idFE, ...)
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
		;=== Для форм AppONTVolProp...
        if (in.form="AppONTVolProp")!(in.form="AppONTVolProp_Tab")
           {    if in.field="gridCntUsed" {s out.value=..GetCntUsed(.out)}  ; Кол-во использований в катал.номенклатуре
			elseif in.field="gridCntDet"  {s out.value=..GetCntDet(.out)}   ; Кол-во привязанных детальных значений
			elseif in.field="gridCntGen"  {s out.value=..GetCntGen(.out)}   ; Кол-во привязанных обобщенных значений
			elseif in.field="gridCntDubl" {s out.value=..GetCntDubl(.out)}	; Кол-во дублей по NrFulVol-Нормализованное Значение полное
            elseif in.field="gridVolG"    {i $ISOBJECT(..idVol) s out.value="["_..idVol.Code_"] "_..idVol.FulVol}   ; [Код] и Наименование обобщенного значения
           }		
		
		//=== 2. и т.д.
		//  .....
		
		// Конец. 
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Кол-во дублей по NrFulVol-Нормализованное Значение полное
/// k  s val=##class(App.ONT.VolProp).GetCntDubl(1) w !,val
Method GetCntDubl(ByRef out) As %String
{
	; На входе :
	;   id -> id записи "App.ONT.VolProp"

	; На выходе :
	;   val <- Значение
	s val=""
	try {
		s filter=[{"field":"NrFulVol", "type":"равно", "data":(..NrFulVol)}]
	    d ..Filter(.filter,.ind)     ;
		s val=..indCOUNT(.ind)                                             ; Кол-во по Нормализованное Значение полное
	 	if val>1  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else      {s val=""}
	   }
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Кол-во привязанных обобщенных значений
/// k  s val=##class(App.ONT.VolProp).GetCntGen(1) w !,val
Method GetCntGen(ByRef out) As %String
{
	; На входе :
	;   id -> id записи "App.ONT.VolProp"

	; На выходе :
	;   val <- Значение
	s val=""
	try {
		s filter=[{"field":"idVolGen", "type":"равно", "data":(..%Id())}]     ; все "App..." с id..
	    s out.error=##class(App.ONT.PatternVol).Filter(.filter,.ind)     ;
		s val=..indCOUNT(.ind)                                           ; Кол-во привязанных обобщенных значений
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	   }
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Кол-во привязанных детальных значений
/// k  s val=##class(App.ONT.VolProp).GetCntDet(1) w !,val
Method GetCntDet(ByRef out) As %String
{
	; На входе :
	;   id -> id записи "App.ONT.VolProp"

	; На выходе :
	;   val <- Значение
    s val=""
	try {
		;-- Кол-во детальных значений
		s filter=[{"field":"idVolDet", "type":"равно", "data":(..%Id())}]     ; все "App..." с id..
	    s out.error=##class(App.ONT.PatternVol).Filter(.filter,.ind)     ;
		s val=..indCOUNT(.ind)                                           ; Кол-во привязанных детальных значений
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// 
/// Кол-во использований в катал.номенклатуре
/// k  s val=##class(App.ONT.VolProp).GetCntUsed(1) w !,val
Method GetCntUsed(ByRef out) As %String
{
	; На входе :
	; На выходе :
	;   val <- Значение
	s val=""
	try {
		;s val="не работает"
		;-- Кол-во значений в номенклатуре		
		s filter=[{"field":"idVol", "type":"равно", "data":(..%Id())}]      ; все "App..." с id..
	    s out.error=##class(App.CTN.NomenVol).Filter(.filter,.ind)     ;
		s val=..indCOUNT(.ind)                                         ; Кол-во записей App.CTN.NomenVol по id..
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Получить id записи "App.NSI.Measure- Единицы отпуска(упаковки)" или пусто 
/// по местному атрибуту "NrFulVol-Нормализованное Значение полное"
/// Для превращения id-значения свойства КП "Упаковка" в поле для мак-Номенклатуры id- App.NSI.Measure
/// 
/// k  s out={},obj=##class(App.ONT.VolProp).%OpenId(9) w !,"id=",obj.getIdMeasure(.out)  ; Запуск из терминала
Method getIdMeasure(ByRef out) As %String
{
	; На входе  : 
	; На выходе : id <- Первый найденный id записи "App.NSI.Measure- Единицы отпуска(упаковки)" или пусто
	;   
	s id=""
	try {
		 ;-- Поиск в App.NSI.Measure по = "Нормализованное Значение полное"
		 s filter=[{"field":"NrName", "type":"=", "data":(..NrFulVol)}]  ;
	     d ##class(App.NSI.Measure).Filter(.filter,.ind)                 ;
	     s ptr="" d ..indNEXT(.ind,.ptr,.id)  ; Первый найденный id записи App.NSI.Measure по = "Нормализованное Значение полное"
	    }
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q id
}

/// Получить id записи "App.NSI.Mnn- МНН" или пусто 
/// по местному атрибуту "NrFulVol-Нормализованное Значение полное"
/// Для превращения id-значения свойства КП "МНН" в поле для мак-Номенклатуры id- App.NSI.Mnn
/// 
/// k  s out={},obj=##class(App.ONT.VolProp).%OpenId(19582) w !,"id=",obj.getIdMnn(.out) 
Method getIdMnn(ByRef out) As %String
{
	; На входе  : 
	; На выходе : id <- Первый найденный id записи "App.NSI.MNN- МНН" или пусто
	;   
	s id=""
	try {
		 ;-- Поиск в App.NSI.Mnn по = "Нормализованное Значение полное"
		 k ind
		 s filter=[{"field":"NrName", "type":"=", "data":(..NrFulVol)}]  ;
	     d ##class(App.NSI.Mnn).Filter(.filter,.ind)                 ;
	     s ptr="" d ..indNEXT(.ind,.ptr,.id)  ; Первый найденный id записи App.NSI.Mnn по = "Нормализованное Значение полное"
	    }
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q id
}

/// Пересохранение по фильтру
/// d ##class(App.ONT.VolProp).ReSaveFiltr()
/// k ^App.ONT.VolPropD1 m ^App.ONT.VolPropD1=^App.CTL.ClassClassListD
ClassMethod ReSaveFiltr()
{
 try {
 	;-- Записи по фильтру
	; .. 
    
    ; !!! так работает
    k ind d ..indOR2(.ind,["FulVol-v","подарок"])
    w !,"1-cnt=",..indCOUNT(.ind)
    
    ; !!! так не работает
    k ind s filter=[{"field":"FulVol", "type":"=","data":"подарок"}]
	s err=..Filter(.filter,.ind)  if err'="" w $c(9),err q
    w !,"2-cnt=",..indCOUNT(.ind)
    
    q 
 	
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
/// d ##class(App.ONT.VolProp).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s Max=0
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
 		{d ..ReSaveOne(id)    ; Пересохранение одной записи
 		}
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.ONT.VolProp).ReSaveOne(1)
/// Переиндексация:  k ^App.ONT.VolPropI d ##class(App.ONT.VolProp).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 ;w !,"IdClass=",obj.IdClass.%Id()
 
 ; --- Здесь что-то  ..
 ;s filter=[{"field":"IdClass","type":"равно","data":(id)}]
 ;s error=##class(App.CTL.Pattern).Filter(.filter,.ind) q:error'=""
 ;s cnt=##class(App.CTL.Pattern).indCOUNT(.ind)

 ;--- и пересохраняем
 d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Удаление одной записи
/// k  d ##class(App.ONT.VolProp).ReDelOne(12153)
/// Переиндексация:  k ^App.ONT.VolPropI d ##class(App.ONT.VolProp).%BuildIndices()
/// k ^App.ONT.VolPropD,^App.ONT.VolPropI,^App.ONT.VolPropC
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

Parameter XMLTYPE = "App-ONT-VolProp";

Storage Default
{
<CounterLocation>^App.ONT.VolPropC</CounterLocation>
<Data name="VolPropDefaultData">
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
<Value>FinWords</Value>
</Value>
<Value name="7">
<Value>FulVol</Value>
</Value>
<Value name="8">
<Value>LngVol</Value>
</Value>
<Value name="9">
<Value>ShrVol</Value>
</Value>
<Value name="10">
<Value>Temp1</Value>
</Value>
<Value name="11">
<Value>idVol</Value>
</Value>
<Value name="12">
<Value>Temp2</Value>
</Value>
<Value name="13">
<Value>NrFulVol</Value>
</Value>
<Value name="14">
<Value>SourseSys</Value>
</Value>
<Value name="15">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.ONT.VolPropD</DataLocation>
<DefaultData>VolPropDefaultData</DefaultData>
<IdLocation>^App.ONT.VolPropD</IdLocation>
<IndexLocation>^App.ONT.VolPropI</IndexLocation>
<StreamLocation>^App.ONT.VolPropS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Счетчик для кода
Property CounterCode As %Library.Counter;

/// Набор поисковых фрагментов
Property FinWords As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Значение полное
Property FulVol As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P") [ Required ];

/// Значение на альтернативном языке
Property LngVol As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Нормализ. значение полное
Property NrFulVol As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Значение краткое
Property ShrVol As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Временное поле 1
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Временное поле 2
Property Temp2 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// не используется
Property idVol As Lib.DataTypes.String(MAXLEN = 1024);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CounterCode On CounterCode [ Type = bitmap ];

Index FinWords On FinWords As Truncate(200) [ Type = bitmap ];

Index FulVol On FulVol As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index LngVol On LngVol As Truncate(200) [ Type = bitmap ];

Index NrFulVol On NrFulVol As Truncate(200) [ Type = bitmap ];

Index ShrVol On ShrVol As Truncate(200) [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

