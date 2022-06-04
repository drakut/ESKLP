/// Список МАК-Контрагентов
Class App.MAK.Supplier Extends (%Persistent, Lib.Abstract.StorableTables)
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
        if in.form="AppMAKSupplier"          ;-- Форма ..
           {;-- вычисление всего и сразу в массиве $g(%tempCell(in.field))    
               if in.field="gridCntPrc-Tot"      {d ..getAllValCell(.in,.out)               ; на первой ячейке вычисляеми ВСЕ остальные в массиве $g(%tempCell(in.field))
                                                  s out.value=$g(%tempCell(in.field))}      ; и Поле "Кол-во прайсов всего"
            elseif in.field="gridCntPrc-Ctn"     {s out.value=$g(%tempCell(in.field))}    	; Поле "в т.ч. связанных и их %"
            elseif in.field="gridCntPrc-CtnNot"  {s out.value=$g(%tempCell(in.field))}    	; Поле "в т.ч. НЕ связанных"
            elseif in.field="gridCntPrc-Status2" {s out.value=$g(%tempCell(in.field))}    	; Поле "обработано и их %"
            elseif in.field="gridCntPrc-Status3" {s out.value=$g(%tempCell(in.field))}    	; Поле "отклонено"
            elseif in.field="gridCntPrc-NotFirm" {s out.value=$g(%tempCell(in.field))}   	; Поле "Кол-во позиций без связанной фирмы",
		    elseif in.field="gridCntMak" 	     {s out.value=$g(%tempCell(in.field))}    	; Поле "Кол-во МАК-Номенклатуры",
	        elseif in.field="gridCntTransFirm"   {s out.value=$g(%tempCell(in.field))}    	; Поле "Таблицы трансляции (кол-во / в т.ч. нераспознано) - Производители",
			elseif in.field="gridCntTransLand"   {s out.value=$g(%tempCell(in.field))}    	; Поле "Таблицы трансляции (кол-во / в т.ч. нераспознано) - Страны",
			; ...      

           }		
		//=== 2. и т.д.
		//  .....
		
		// Конец. 
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Получить значения ВСЕХ вычисляемых ячеек строки таблицы в массиве $g(%tempCell(in.field))
///  k  s (in,out)={},obj=##class(App.MAK.Supplier).%OpenId(10) d obj.getAllValCell(.in, .out) zw %tempCell
/// 
Method getAllValCell(ByRef in, ByRef out) As %String
{
	; На входе  : in.
	; На выходе :
	;   $g(%tempCell(in.field)) <- Значения ячеек
	;        out. <-
	try {
		k %tempCell
        ;==1. Поле "Кол-во прайсов всего"
		s val="" 
		k ind s filter=[{"field":"idAgent", "type":"равно", "data":(..idAgent.%Id())}]    ; все "App..." с idEi
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)        ;
		s (val,Tot)=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
        s %tempCell("gridCntPrc-Tot")=val

        ;==2. Поле "в т.ч. связанных и их %"
		s val="",Proc="" k ind
		; Кол-во связанных
		k ind s filter=[{"field":"idAgent", "type":"равно",    "data":(..idAgent.%Id())},{"oper":"AND"},
		                 {"field":"idNomen", "type":"не пусто", "data":1}]
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)        ;
		s (val,Link)=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
 		i Tot'=0 s Proc=($j(((Link/Tot)*100),0,1))_"%"    ; % связанных 
 		s val=val_" ("_Proc_")"                           ; кол-во и %
        s %tempCell("gridCntPrc-Ctn")=val
        
        ;==3.  Поле "в т.ч. НЕ связанных"
		s val=""
		k ind s filter=[{"field":"idAgent", "type":"равно",    "data":(..idAgent.%Id())},{"oper":"AND"},
		                {"field":"idNomen", "type":"пусто", "data":1}]
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)        ;
		s val=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}        
        s %tempCell("gridCntPrc-CtnNot")=val
        
        ;==4. Поле "обработано и их %"
		s val="",Proc=""   ; НУ
		;-- Обработано
		k ind s filter=[{"field":"idAgent","type":"равно", "data":(..idAgent.%Id())},{"oper":"AND"},
		                {"field":"Status", "type":"равно", "data":2}]   ;Status	Статус записи (1=экспертиза, 2=обработано, 3=отклонено)
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)
		s (val,Stat)=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
 		i Tot'=0 s Proc=($j(((Stat/Tot)*100),0,1))_"%"    ; % обработанных 
 		s val=val_" ("_Proc_")"                           ; кол-во и %        
        s %tempCell("gridCntPrc-Status2")=val
        
        ;==5. Поле "отклонено"
		s val=""
		k ind s filter=[{"field":"idAgent","type":"равно", "data":(..idAgent.%Id())},{"oper":"AND"},
		                {"field":"Status", "type":"равно", "data":3}]   ;Status	Статус записи (1=экспертиза, 2=обработано, 3=отклонено)
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)
		s val=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}        
        s %tempCell("gridCntPrc-Status3")	=val
        
        ;==6. Поле "Кол-во позиций без связанной фирмы",
		s val=""
		k ind s filter=[{"field":"idAgent", "type":"равно", "data":(..idAgent.%Id())},{"oper":"AND"},
		                {"field":"IdFirm",  "type":"пусто", "data":1}]
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)        ;
		s val=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
        s %tempCell("gridCntPrc-NotFirm")=val
		
		;==7. Поле "Кол-во МАК-Номенклатуры",
		s val="",Proc=""
		;--- Кол-во связанных
		k ind s filter=[{"field":"idAgent",   "type":"равно",   "data":(..idAgent.%Id())},{"oper":"AND"},
		                {"field":"idMakNomen","type":"не пусто","data":1}]
	    d ##class(App.PRC.Nomen).Filter(.filter,.ind)        ;
		s (val,Link)=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
		s %tempCell("gridCntMak")=val
	    
	    ;==8. Поле "Таблицы трансляции (кол-во / в т.ч. нераспознано) - Производители",
		s val=""
		;--- Кол-во трансляций всего
		k ind s filter=[{"field":"idAgent","type":"равно","data":(..idAgent.%Id())}]
	    d ##class(App.MAK.Firm).Filter(.filter,.ind)        ;
		s (val,Tot)=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
		;--- Кол-во трансляций распознано
		k ind s filter=[{"field":"idAgent","type":"равно",    "data":(..idAgent.%Id())},{"oper":"AND"},
		                {"field":"idFirm", "type":"не пусто", "data":1}]
	    d ##class(App.MAK.Firm).Filter(.filter,.ind)        ;
		s (val,Link)=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
 		i Tot'=0 s val=Tot_" / "_Link	    
	    s %tempCell("gridCntTransFirm")=val
		
		;==9. Поле "Таблицы трансляции (кол-во / в т.ч. нераспознано) - Страны",
		s val=""
		;--- Кол-во трансляций всего
		k ind s filter=[{"field":"idAgent","type":"равно",    "data":(..idAgent.%Id())}]
	    d ##class(App.MAK.Country).Filter(.filter,.ind)        ;
		s (val,Tot)=..indCOUNT(.ind)
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
		;--- Кол-во трансляций распознано
		k ind s filter=[{"field":"idAgent","type":"равно",    "data":(..idAgent.%Id())},{"oper":"AND"},
		                {"field":"idLand", "type":"не пусто", "data":1}]
	    d ##class(App.MAK.Country).Filter(.filter,.ind)        ;
		s (val,Link)=..indCOUNT(.ind)
	 		if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 			else       {s val=""}
 		i Tot'=0 s val=Tot_" / "_Link
		s %tempCell("gridCntTransLand")=val
		
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Пересохранение по фильтру
/// d ##class(App.MAK.Supplier).ReSaveFiltr()
/// k ^App.MAK.Supplier1 m ^App.MAK.Supplier1=^App.MAK.Supplier
ClassMethod ReSaveFiltr()
{
 try {
 	;-- Записи по фильтру
	; .. 
    k ind s filter=[{"field":"IdClass", "type":"равно","data":"8254"}]
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
/// d ##class(App.MAK.Supplier).ReSaveAll()
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
/// k  d ##class(App.MAK.Supplier).ReSaveOne(12)
/// Переиндексация:  k ^App.MAK.SupplierI d ##class(App.MAK.Supplier).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 
 ; --- Здесь что-то  ..
 ;s obj.TimeLastPrc=+$h   ; отладка дат         ;$tr($zd(date,4,,4),"/",".")}
 ;s obj.TimeStart = $tr($ZD($H,4),"/",".")_" "_$ZT($p($H,",",2))    ; через жопу ...  12.10.2018 13:59:27

 ;--- и пересохраняем
 d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Удаление одной записи
/// k  d ##class(App.MAK.Supplier).ReDelOne(12153)
/// Переиндексация:  k ^App.MAK.SupplierI d ##class(App.MAK.Supplier).%BuildIndices()
/// k ^App.MAK.SupplierD,^App.MAK.SupplierI,^App.MAK.SupplierC
ClassMethod ReDelOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 ;-- Удаление
 d obj.%DeleteId(id) s err=obj.ObjError() if err'="" w !,$c(9),err q   // Выход по ошибке
 q
}

/// Может Быть родителем
Parameter CanParent = 0;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-MAK-Supplier";

/// Список уникальных ссылочных полей
Parameter listUnique = ",idAgent";

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// Временное поле1
Property Temp1 As Lib.DataTypes.String(IndexValue = 1);

/// $H Дата формирования МАК-номенклатуры
Property hDateMakLast As Lib.DataTypes.String(IndexValue = 1);

/// $H Дата последнего обновления Прайса
Property hDatePrcLast As Lib.DataTypes.String(IndexValue = 1);

/// Контрагент
Property idAgent As App.PRC.Agent [ Required ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index hDateMakLast On hDateMakLast As Truncate(200) [ Type = bitmap ];

Index hDatePrcLast On hDatePrcLast As Truncate(200) [ Type = bitmap ];

Index idAgent On idAgent [ Type = bitmap ];

ForeignKey fkidAgent(idAgent) References App.PRC.Agent();

Storage Default
{
<Data name="SupplierDefaultData">
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
<Value>Com</Value>
</Value>
<Value name="5">
<Value>hDatePrcLast</Value>
</Value>
<Value name="6">
<Value>hDateMakLast</Value>
</Value>
<Value name="7">
<Value>idAgent</Value>
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
<DataLocation>^App.MAK.SupplierD</DataLocation>
<DefaultData>SupplierDefaultData</DefaultData>
<IdLocation>^App.MAK.SupplierD</IdLocation>
<IndexLocation>^App.MAK.SupplierI</IndexLocation>
<StreamLocation>^App.MAK.SupplierS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

