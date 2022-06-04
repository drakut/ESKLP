/// Шаблоны классов
Class App.ONT.Pattern Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.ONT.Pattern).%OpenId(1) d obj.addCheckSet({},{})  ; Запуск из терминала
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
       	 ;-- На новой записи Формирование
         ;
         s idClass=..idClass.%Id()        ; idClass
         
         ;-- На новой записи: 
         i in.type ="new"
         	{;   забрать из "App.ONT.Prop" эти поля, если они пусты:
         	 i ..TypeData="" s ..TypeData =..idProp.TypeData	; Тип данных (str=Строка, car=Действительное число, int=Целое число)
         	 i ..MethVol=""  s ..MethVol  =..idProp.MethVol		; Способ заполнения значения (S=Из справочника, H=Ручной ввод, C=Расчетное,G=обобщенное)
         	 i ..ReqEI=""    s ..ReqEI    =..idProp.ReqEI		; Наличие единицы измерения  (1=обязательно, 0=необязательно, 2=запрещено)
         	 i ..Weight=""   s ..Weight   = 0.5                 ; Весовой коэффициент при распозновании, по умолчанию =0.5
		 	 
		 	 ;  если новое свойство- обобщенное, то
		 	 ;  записать в новую обобщающую строку шаблон ссылку на возможное детальное свойство по умолчанию
		 	 ;  и возможно по-тихому создать строку шаблона детального свойства.
		 	 ;  В любом случае будет получен idPattDet - строки шаблона детального свойства
		 	 i ..idProp.MethVol="G" 
		 	 	{s ..idPropDet=..idProp.idPropDet	  ; Детальное свойство по умолчанию для обобщенного
			     i ..idPropDet="" s out.error="Для обобщающего свойства '"_..idProp.Name_"' не указано детальное." q			     
			     s idPropDet=..idProp.idPropDet.%Id() ; его ID 
			     ;  Возвращает ID созданной или существующей записи детального свойства в текущем шаблоне
			     s out.error=..doMakePatt(idClass, idPropDet,.idPattDet) q:out.error'=""  ;ID созданной или существующей записи детального свойства в текущем шаблоне
			     ;  ссылка на Детальную строку шаблона для обобщающего
			     d ..idPattDetSetObjectId(idPattDet)  ; Присвоение ссылки на объект, указав ID без загрузки ссылочного объекта
		 	 	}
		 	 
		 	 ;   и установить эти: 	
			 s ..ReqPr    =$case(..ReqPr,   1 :1,   "Да":1,   "да":1,  "Y":1,"y":1,:0  )    ; Обязательность заполнения значения свойства   (1=Да,0=Нет)
			 s ..UsDisF   =$case(..UsDisF,  1 :1,   "Да":1,   "да":1,  "Y":1,"y":1,:0  )    ; Использование свойства в полном описании	    (1=Да,0=Нет)
			 s ..UsDisS   =$case(..UsDisS,  1 :1,   "Да":1,   "да":1,  "Y":1,"y":1,:0  )    ; Использование свойства в коротком описании    (1=Да,0=Нет)
			 s ..LoValF   =$case(..LoValF, "S":"S", "s" :"S", "f" :"F",            :"F")    ; Вид значения свойства для полного описания    (F=полное,S=краткое,L=латинское)
			 s ..LoValS   =$case(..LoValS, "s":"S", "f" :"F", "F" :"F",            :"S")    ; Вид значения свойства для короткого описания  (F=полное,S=краткое,L=латинское)
			} 
         
         ;-- Всегда. Для обобщенной строки шаблона наследуем ссылку на детальное свойство.
         ;           или стираем ссылку на детальное свойство
         i ..idPattDet'="" {s ..idPropDet=..idProp.idPropDet,..MethVol="G"}  ; Есть ссылка на детальную строку шаблона. Подтвердим Детальное свойство по умолчанию для обобщенного
         i ..idPattDet=""  {s ..idPropDet=""}  				                 ; Нет ссылки на детальную строку шаблона. Затрем Детальное свойство по умолчанию для обобщенного
         
         ; 1.Сформировать всякие номера следования, если они 0. +10 от последнего существующего или 10, если он самый первый
		 ;   Cоберем индекс Строк Шаблона класса, если хотя бы один номер следования ноль
		 i (+..Npp=0)!(+..NumF=0)!(+..NumS=0) {s filter=[{"field":"idClass", "type":"равно","data":(idClass)}] s out.error=..Filter(.filter,.ind) if out.error'="" q}
		 ;   № следования в шаблоне
	 	 i +..Npp=0 {s ptr="" d ..indNEXTsort(.ind,"Npp",-1,1,.ptr,.idMaxNpp)                          ; Запись с последним (максимальным) Npp в пределах Шаблона класса
			    	     if idMaxNpp'="" {s objMaxNpp=..%OpenId(idMaxNpp) s ..Npp=objMaxNpp.Npp+10}    ; Автоинкремент +10 от последнего
					 elseif idMaxNpp=""  {s ..Npp=10}                                                  ; Первый раз
	 			    }
  		 ;  № следования свойства в полном описании
	 	 i +..NumF=0 {s ptr="" d ..indNEXTsort(.ind,"NumF",-1,1,.ptr,.idMaxNpp)                           ; Запись с последним (максимальным) NumF в пределах Шаблона класса
			    	      if idMaxNpp'="" {s objMaxNpp=..%OpenId(idMaxNpp) s ..NumF=objMaxNpp.NumF+10}    ; Автоинкремент +10 от последнего
					  elseif idMaxNpp=""  {s ..NumF=10}                                                   ; Первый раз
	 			     }
		 ;  № следования свойства в коротком описании или 0	
	 	 i +..NumS=0 {s ptr="" d ..indNEXTsort(.ind,"NumS",-1,1,.ptr,.idMaxNpp)                           ; Запись с последним (максимальным) NumS в пределах Шаблона класса
			    	      if idMaxNpp'="" {s objMaxNpp=..%OpenId(idMaxNpp) s ..NumS=objMaxNpp.NumS+10}    ; Автоинкремент +10 от последнего
					  elseif idMaxNpp=""  {s ..NumS=10}                                                   ; Первый раз
	 			     }
         ;

         ;== Проверки         
         ;/*
         ;  !!1 Исследовать разные случаи
         ;  1. Запрет изменения "Способ заполнения (MethVol)" (S=Из справочника, H=Ручной ввод, C=Расчетное,G=обобщенное), если уже есть значения "App.CTN.NomenVol"
 		 	i (in.type="edit")&&(..MethVol'=in.oldRec.MethVol)&&(..idPattDet="")  ; только на редактировании и при несовпадении нового и старого метода MethVol
   				{s filter=[{"field":"idProp","type":"равно","data":(in.oldRec.idProp)}]   ; все App.CTN.NomenVol c idProp.
	    		 s out.error=##class(App.CTN.NomenVol).Filter(.filter,.ind)               ;
 				 i ..indCOUNT(.ind)'=0 
 				 	  {s ..MethVol=in.oldRec.MethVol                  ; подмена нового MethVol на старый в текущем объекте, чтобы дисплеить старое значение
 				 	   s Met=..MethVolLogicalToDisplay(..MethVol)     ; Дисплей-значение поля objOld.MethVol
 	 				   s out.error="Нельзя менять способ заполнения значения='"_Met_"'. Уже есть значения свойства='"_..idProp.Name_"' каталожной номенклатуры, заполненных этим способом." q
	 				  }
   			}
         ;*/
         ;
         ;s objOld = in.oldRec
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

/// Перед удалением
/// k  s out={},obj=##class(App.ONT.Pattern).%OpenId(2) d obj.addBeforeDelete({},.out) w !,out.error
/// 
Method addBeforeDelete(ByRef in, ByRef out)
{
	// На входе :
	//				..ИмяПоля -> Поле из удаляемой записи
	//			    in.jobnum -> Номер задания для фоновых задач
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=..%Id()
	//	s name=..Name			// Получить поле удаляемой записи
	s out={"error":""}
 try {
	  ;-- 1. Запретить удалять, если есть значения свойств КП (App.CTN.NomenVol) по текущей строке шаблона
	  k ind s filter=[{"field":"idPatt","type":"равно","data":(..%Id())}]				
	  s out.error=##class(App.CTN.NomenVol).Filter(.filter,.ind) q:out.error'=""
      if ..indCOUNT(.ind)'=0 s out.error="Нельзя удалять строку шаблона: Класс='"_..idClass.Name_"', Свойство='"_..idProp.Name_"'. Есть значения Каталожных номенклатур." q    ;
	  ;   Далее, тихо удалить все App.ONT.PatternVol, где текущий idPatt содержится в полях:
	  ;       -idPattDet	Детальная строка шаблона
	  ;   или -idPattGen	Обобщенная строка шаблона
	  k ind s filter=[{"field":"idPattDet","type":"равно","data":(..%Id())},{"oper":"OR"},
	                  {"field":"idPattGen","type":"равно","data":(..%Id())}]				
	  s out.error=##class(App.ONT.PatternVol).Filter(.filter,.ind) q:out.error'=""
      ;   Массовое удаление в App.ONT.PatternVol, где найдены ссылки на текущий idPatt
      s ptr="" while ..indNEXT(.ind,.ptr,.idDel) 
               {;w !,"idDel=",idDel 
	            d ##class(App.ONT.PatternVol).%DeleteId(idDel) s out.error=..ObjError() i out.error'="" q  ; Удаление связи детального и обобщенного значений
               }   	    
	  ;--
	  ; ... и т.д.
	 } // try
 catch exp {s out.error=..ErrorDetect(.exp)} // catch
 q
}

/// 
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
		;=== Маркировать колонку  "name":"gridUsDisS","field":"UsDisS","caption":"Включение в описание", "style":23 или "style":26 - Используется в полномо описании
		if in.form="AppONTPattern_FullDef"   ; Форма настройки полного описания
			{if in.field="gridUsDisF" s out.style={"CodeStyle":"23"} s:..UsDisF=1 out.style={"CodeStyle":"26"}  ; Используется/не используется в полном описании
			}
		;=== Маркировать колонку  "name":"gridUsDisS","field":"UsDisS","caption":"Включение в описание", "style":23 или "style":26 - Используется в кратком описании
		if in.form="AppONTPattern_ShortDef"   ; Форма настройки краткого описания
			{if in.field="gridUsDisS" s out.style={"CodeStyle":"23"} s:..UsDisS=1 out.style={"CodeStyle":"26"}  ; Используется/не используется в кратком описании

			}

		
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Создать запись строки шаблона если ее нет.
/// Возвращает ID созданной или существующей записи
/// k  s err=##class(App.ONT.Pattern).doMakePatt(idClass, idProp,.idPatt) w
Method doMakePatt(idClass As %String, idProp As %String, idPatt As %String)
{
	// На входе :
	//	   idClass -> ID- Класса
	//	    idProp -> ID- Свойства
	// На выходе :
	//		.idPatt <- ID созданной или существующей строки шаблона
	//	 out.error <- Сообщение об ошибке или пусто
	s out={"error":""},(err,idPatt)=""
	try {
    	;--
    	s filter=[{"field":"idClass","type":"равно","data":(idClass)},{"oper":"AND"},
    	          {"field":"idProp","type":"равно","data":(idProp)}]				
		k ind s err=..Filter(.filter,.ind) q:err'=""
    	s ptr="" d ..indNEXT(.ind,.ptr,.idPatt)
    	; Нет строки шаблона. Создаем
    	i idPatt="" {s objPatt=..%New()                                ; НУ. Новый объект строки шаблона
    			 	 s objProp=##class(App.ONT.Prop).%OpenId(idProp)   ; Загрузить объект App.ONT.Prop
         	 		 ;-- установка полей по умолчанию новой App.ONT.Pattern от App.ONT.Prop 
         	 		 d objPatt.idClassSetObjectId(idClass)  ; Присвоение ссылки на объект, указав ID без загрузки ссылочного объекта
         	 		 d objPatt.idPropSetObjectId(idProp)    ; Присвоение ссылки на объект, указав ID без загрузки ссылочного объекта
         	 		 s objPatt.TypeData =objProp.TypeData	; Тип данных (str=Строка, car=Действительное число, int=Целое число)
         	 		 s objPatt.MethVol  =objProp.MethVol	; Способ заполнения значения (S=Из справочника, H=Ручной ввод, C=Расчетное,G=обобщенное)
         	 		 s objPatt.ReqEI    =objProp.ReqEI		; Наличие единицы измерения  (1=обязательно, 0=необязательно, 2=запрещено)
				     ;--- Транзакция
 					 d objPatt.%Save(0) s err=..ObjError() if err'="" q   ; Выход по ошибке
				     s idPatt=objPatt.%Id()    ; ID сохраненой строки шаблона
	    			}
	} // try
	catch exp {s (err,out.error)=..ErrorDetect(.exp)} // catch
	q err
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
        if (in.form="AppONTPattern")!(in.form="AppONTPattern_Tab")!(in.form="AppONTPattern_Find")   ;-- Для форм "AppONTPattern..."
           {if in.field="gridCntUsed" s out.value=..GetCntUsed(.out)   ; Кол-во использований
			if in.field="gridPropG"   s out.value=..GetPropG(.out)     ; Список обобщенных свойств через запятую для детального свойства

			; ...           
           }		
		//=== 2. и т.д.
		//  .....
		
		// Конец. 
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Список обобщенных свойств через запятую для детального свойства
/// k  s val=##class(App.ONT.Pattern).GetPropG(43) w !,val
Method GetPropG(id As %Integer) As %String
{
	; На входе :
	;   id -> id записи "App.ONT.Pattern"

	; На выходе :
	;   val <- Значение

	s out={"error":""}
	try {
		s val=""
		;-- Кол-во значений в номенклатуре		
		s filter=[{"field":"idPattDet", "type":"равно", "data":(..%Id())}]       ; все "App..." с id..
	    s out.error=..Filter(.filter,.ind)          ;
        s ptr="" while ..indNEXT(.ind,.ptr,.idPatt)
        	{s obj=..%OpenId(idPatt)        ; объект "App.ONT.Pattern"
        	 s val=val_obj.idProp.Name_", "
        	}

	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Кол-во использований
/// k  s val=##class(App.ONT.Pattern).GetCntUsed(1) w !,val
Method GetCntUsed(ByRef out) As %String
{
	; На входе :

	; На выходе :
	;   val <- Значение

	s val=""
	try {
		
		;-- Кол-во значений в номенклатуре		
		s filter=[{"field":"idPatt", "type":"равно", "data":(..%Id())}]          ; все "App..." с id..
	    s out.error=##class(App.CTN.NomenVol).Filter(.filter,.ind)          ;
		s val=..indCOUNT(.ind)                                              ; Кол-во записей App.CTN.NomenVol по id..
	 	if val'=0  {s point=0,sep=" ",val=$tr($fn(val,",",point),",",sep)}  ; Целое число (point=0) по триадам, через разделитель "sep"=пробел
 		else       {s val=""}
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
}

/// Поиск по функции. Формирование ind для поисковых форм
ClassMethod addFind(ByRef in, ByRef out, ByRef ind)
{
	// На входе :
	//			   in.form -> Имя формы
	//		  in.formfield -> Имя поля формы
	//		   in.typefind -> Тип поиска ("равно", "не равно", "совпадение", "не совпадение", "содержит", "не содержит", 
	//									"начинается", "не начинается", "меньше", "больше", "пусто", "не пусто", "диапазон")
	//		   in.datafind -> Поисковый фрагмент
	//	  in.add.currentid -> id текущей записи в текущей таблице
	//		 in.add.editid -> Если поиск в поисковой форме из панели редактирования, то id редактируемой записи
	//	   in.add.parentid -> id-мастер записи
	//	 in.add.parentform -> Имя формы, откуда осуществляется вызов поисковой формы (если форма не поисковая, то пусто)
	//	in.add.parentfield -> Имя поля формы, из которого осуществляется вызов поисковой формы (если форма не поисковая, то пусто)
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//		      ind -> Результирующий бит-индекс
	// Примеры :
	s err=""
	try {
		s out.value=""  
		
		;--!! ОБЯЗАТЕЛЬНО. Тупо собрать весь индекс, чтобы все работало без переопределения правил формирования индекса
		d ##class(App.ONT.Pattern).indOR2(.ind,[(..#indAll)])		

		if in.form="AppONTPattern_Find"       ; Поисковая Форма
		   {; Вызов поисковой формы осуществляется из секции редактирования форм "AppCTNNomenVol.."
		    ; В этом случае в поисковую форму отдать индекс еще не введенных значений свойств 
		    ; Т.е. не все Строки Шаблонов, а только отсутствующие в записях "App.CTN.NomenVol"
		    if (in.add.parentform="AppCTNNomenVol")!(in.add.parentform="AppCTNNomenVol_Tab")    ; Это формы из которых будет вызвана поисковая форма
		  		{if in.add.parentfield="editidPatt"                 ; Это имя поля формы редактирования из которого вызывается поисковая форма
		  	       {s idNomen=in.add.parentid                       ; id-мастер записи.
			  	    s obj=##class(App.CTN.Nomen).%OpenId(idNomen)   ; Объект КП
			  	    s idClass=obj.idClass.%Id()                     ; ID-Класс из КП   
			        ;-- все строки шаблона Класса ("App.ONT.Pattern") текущей КП
			        k ind s filter=[{"field":"idClass","type":"=","data":(idClass)}]
			        s err=..Filter(.filter,.ind)  if err'="" q
					;-- занятые строки шаблона Класса текущей КП
					k indNom s filter=[{"field":"idNomen","type":"=","data":(idNomen)}]
			        s err=##class(App.CTN.NomenVol).Filter(.filter,.indNom)  if err'="" q
			        ;-- проход по занятым значениям свойств КП ("App.CTN.NomenVol"). 
			        ;   Из общего ind будем удалять занятые idPatt. Получит разрешенные для ввода или пусто
			        s ptr="" while ..indNEXT(.indNom,.ptr,.idVol)
			        	{s objNom=##class(App.CTN.NomenVol).%OpenId(idVol)   ; объект "App.CTN.NomenVol"
			        	 s idPatt=objNom.idPatt.%Id()                        ;
			        	 d ..indDELETE(.ind,(idPatt))                        ; все МИНУС занятые = разрешенные для ввода
				        }
		 		   } 	; 
		 		}
		   
		    ; Вызов поисковой формы осуществляется из секции редактирования формы "AppONTPattern_Tab"
		    ; Ввод детального свойства для обобщенного.
		    ; В этом случае в поисковую форму отдать индекс строк шаблона текущего класса.
		    ; Строки только способа "S".
		    if (in.add.parentform="AppONTPattern_Tab")!((in.add.parentform="AppONTPattern"))    ; Это форма из которой будет вызвана поисковая форма
		   		{if in.add.parentfield="editPattDet"      ; Это имя поля формы редактирования из которого вызывается поисковая форма
		   		 	{s id=in.add.editid                   ; id редактируемой записи или пусто
			   		 ;s ^mir("currentid=")=in.add.editid
			   		 i id'=""    ; Формируем индекс только при редактировании, иначе не известен Класс
			   		 	{s obj    =..%OpenId(id)       ; Объект App.ONT.Pattern
			  	    	 s idClass=obj.idClass.%Id()   ; ID-Класс
				   		 ;s ^mir("idClass=")=idClass
				   		 ;-- все строки шаблона Класса ("App.ONT.Pattern") 
			             k ind s filter=[{"field":"idClass","type":"=","data":(idClass)},{"oper":"AND"},
			                             {"field":"MethVol","type":"=","data":"S"}
			                             ]
			             s err=..Filter(.filter,.ind)  if err'="" q
				    	}
			   		}
		   		}
		   }			   	
     	   ;====
     	   ; Вызов поисковой формы осуществляется из формы "AppONTPatternVol_Tab" - Детальные и Обобщенные значения, табличный вид
           ; Формировать индекс по обощающим строкам шаблонов
	       if in.add.parentform="AppONTPatternVol_Tab"          ; Это форма из которой будет вызвана поисковая форма
	       		; Секция поиска или Секция редактирования. Поля "Обобщенная строка шаблона"
	       		{if (in.add.parentfield="findidPattGen")!(in.add.parentfield="editidPattGen")          
		       		{k ind s filter=[{"field":"MethVol","type":"=","data":"G"}]  ; Способ заполнения значения  (S=Из справочника, H=Ручной ввод, C=Расчетное, G=Обобщенное)
		             s err=..Filter(.filter,.ind)  if err'="" q
			       	}
		       	; Секция поиска или Секция редактирования. Поля "Детальная строка шаблона". 
		       	; Соберем строки шаблонов, которые используются как детальные
	       		 if (in.add.parentfield="findidPattDet")!(in.add.parentfield="editidPattDet")          
		       		{
		       		 ; .. собрать сначала строки у которых idPattDet не пусто. Это будут обобщающие
        			 k ind1 s filter=[{"field":"idPattDet","type":"не пусто","data":1}]	           
			       	 s err=..Filter(.filter,.ind1) if err'="" q
      			     ; .. пройти по обобщающим, вытащить из них ссылку на детальное и построить индекс по idPattDet.%Id()
      			     k ind s ptr="" while ..indNEXT(.ind1,.ptr,.id) 
      			     		{s obj=..%OpenId(id)
      			     		 i $ISOBJECT(obj.idPattDet) d ..indINSERT(.ind, obj.idPattDet.%Id())
      			     		 }
			       	}
		       	
		       	
		       	}
           ; ... и т.д.

	 } // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Вызов функции с клиента
ClassMethod addCallClient(ByRef in, ByRef out)
{
	// На входе :
	//				   in.form -> Имя формы
	//			   in.typecall -> Источник вызова ("toolbar" - кнопка на панели задач и т.д.)
	//			   in.namecall -> Имя действия (Для "toolbar" - имя кнопки и т.д.)
	//			   in.actualid -> ID текущей строки в форме
	//				 in.jobnum -> Номер задания для фоновых задач
	//				 in.filter -> фильтр для поиска
	//				   in.data -> Дополнительные данные для задачи (определяются клиентом)
	// 		in.multiselect.all -> Если 1, то выбор всех примультиселекте
	//  in.multiselect.records -> Если in.in.multiselect.all=1, то динамический массив ID, которые отменены, Если in.in.multiselect.all=0, то динамический массив ID, которые отмечены
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//	  out.typejob -> Метод исполнения задачи ("fast" - задача исполняется быстро, не в фоне, "job" - задача исполняется медленно, в фоне)
	//	  out.refresh -> 1 - Обновлять экран после выполнения действия
	//	  out.message -> Сообщение для клиента. Выводится после исполнения прцедуры по желанию (выводится в модальном окне)
	// Примеры : (см. также в Lib.App.ImportError)
	// if (count<100) {s out.typejob="fast" d ..Process()}
	// else			  {s out.typejob="job"  j ..Process()}
	// 
	s err="",out={"error":""}
	try {
		;-- Перемещение строк на закладках ...
		i in.namecall["Move"                            ; команда на перестановку строк 
			    {s in2         =in                      ; готовим динам-параметр in2 для метода перемещения строк 
				 s out.typejob ="fast"                  ; перемещение будет не в фоне
				 s item        =..%OpenId(in2.actualid) ; загрузка родительского объекта
				 s ParentFld   ="idClass"               ; имя поля родительского ID в перемещаемой строке          
				 s ParentId    =item.idClass.%Id()      ; сам родительский ID в перемещаемой строке
				 ;-- Перемещение строк на закладках "AppONTPattern...". Настройки
				     if in.form="AppONTPattern"          {s ChangFld="Npp"}   ;Имя поля номера следования "Npp"
				 elseif in.form="AppONTPattern_FullDef"  {s ChangFld="NumF"}  ;Имя поля номера следования "NumF"
				 elseif in.form="AppONTPattern_ShortDef" {s ChangFld="NumS"}  ;Имя поля номера следования "NumF"
				 ; .. т.д.
				 ;-- Формирование динам-параметра in2 для метода перемещения строк 
				 s in2.className =$CLASSNAME(##this)	                                  ; имя местного перемещаемого класса
				 s in2.filter    =[{"field":(ParentFld),"type":"=","data":(ParentId)}]    ; фильтр перемещаемого класса: Имя поля родительского ID("IdClass") и сам родительский ID(item.IdClass.%Id())
				 s in2.numField  =ChangFld                                                ; имя поля номера следования перемещаемого класса
				 s in2.direction =$CASE(in2.namecall,"MoveUp":"u","MoveDown":"d","MoveToFirst":"f","MoveToLast":"l")	; определяем направление движения
				 d ##class(Lib.Util.Table).MoveItem(.in2,.out) i out.error'="" q          ; транзакция двух записей, обменявшихся номерами следования
				 s out.refresh=1                                                          ; обновление экранной формы после исполнения метода
				}
		} // try
	catch exp {s out.error=..ErrorDetect(.exp) s out.error=err} // catch
	q
}

/// Копировать шаблон Класса1 в Класс2. 
/// Класс2 уже должен существовать и в своем шаблоне НЕ иметь ни одной строки-свойства!!
/// 
/// k  d ##class(App.ONT.Pattern).CopyPattern(7,8,.out) w out.error
ClassMethod CopyPattern(idClass1 As %Integer, idClass2 As %Integer, ByRef out)
{
    ; Вход:
    ; idClass1 -> ID-Класса1 "App.ONT.Class"
    ; idClass2 -> ID-Класса2 "App.ONT.Class"
    ;
    ; Выход:
    ;	out.error -> Сообщение об ошибке или пусто
 s out={"error":""} 
 try {
	;-- Проверки параметров
	i idClass1="" s out.error="Не задан ID-Класса1" q          ; ID-Класса "App.ONT.Class"
    i '##class(App.ONT.Class).%ExistsId(idClass1) s out.error="Нет записи 'App.ONT.Class' с ID1="_idClass1 q     ;
	i idClass2="" s out.error="Не задан ID-Класса2" q          ; ID-Класса "App.ONT.Class"
    i '##class(App.ONT.Class).%ExistsId(idClass2) s out.error="Нет записи 'App.ONT.Class' с ID2="_idClass2 q     ;
    s objClass2=##class(App.ONT.Class).%OpenId(idClass2)       ; Загрузка Класса2
    
    ;-- Проверка Класса2 на отсутствие строк-свойств
    ;   Поиск в Шаблоне2 по idClass2
    s filter=[{"field":"idClass","type":"равно","data":(idClass2)}]				
	s out.error=..Filter(.filter,.ind) q:out.error'=""
    i ..indCOUNT(.ind)'=0 s out.error="В классе '"_objClass2.idClass.Name_"' уже есть ранее введенные свойства."  q
    
    ;-- Все ОК. Прдолжаем ...
    ;   Проход по строкам шаблона1. Копируем его строки в шаблон2.
    s filter=[{"field":"idClass","type":"равно","data":(idClass1)}]				
	k ind s out.error=..Filter(.filter,.ind) q:out.error'=""
    s ptr="" while ..indNEXT(.ind,.ptr,.idPatt1)
    		{s objPatt1=..%OpenId(idPatt1)            ; Загрузка текущей строки шаблона1
	    	 s objPatt2=..%New()            	      ; Новый объект строки шаблона2
	    	 
	    	 s objPatt2=objPatt1.%ConstructClone()    ; Копирование полей строки1 в строку2
	         d objPatt2.idClassSetObjectId(idClass2)  ; Класс2. Присвоили ссылку, указав ID без загрузки ссылочного объекта
             ;w !," =",objPatt2.IdProp.Name

             ;--- Транзакция
             d objPatt2.%Save(0) s out.error=objPatt2.ObjError() if out.error'="" q   // Выход по ошибке
	    	 ;w $c(9),"создано"
	    	 ;
	    	}
	} // try
   catch exp {s out.error=..ErrorDetect(.exp)} // catch
 q
}

/// Пересохранение по фильтру
/// d ##class(App.ONT.Pattern).ReSaveFiltr()
/// k ^App.ONT.PatternD1 m ^App.ONT.PatternD1=^App.CTL.ClassClassListD
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
/// d ##class(App.ONT.Pattern).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
 		{d ..ReSaveOne(id)    ; Пересохранение одной записи
 		}
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.ONT.Pattern).ReSaveOne(12)
/// Переиндексация:  k ^App.ONT.PatternI d ##class(App.ONT.Pattern).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
  
 ; --- Здесь что-то  ..
 i obj.Weight="" s obj.Weight=0.5   ;Весовой коэффициент при распозновании по умолчанию (=0,5)
 ;--- и пересохраняем
 d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Удаление одной записи
/// k  d ##class(App.ONT.Pattern).ReDelOne(12153)
/// Переиндексация:  k ^App.ONT.PatternI d ##class(App.ONT.Pattern).%BuildIndices()
/// k ^App.ONT.PatternD,^App.ONT.PatternI
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

Parameter XMLTYPE = "App-ONT-Pattern";

/// Список уникальных ссылочных полей
Parameter listUnique = ",idClass,idProp";

Storage Default
{
<Data name="PatternDefaultData">
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
<Value>LoValF</Value>
</Value>
<Value name="6">
<Value>LoValS</Value>
</Value>
<Value name="7">
<Value>MethVol</Value>
</Value>
<Value name="8">
<Value>Npp</Value>
</Value>
<Value name="9">
<Value>NumF</Value>
</Value>
<Value name="10">
<Value>NumS</Value>
</Value>
<Value name="11">
<Value>ReqEI</Value>
</Value>
<Value name="12">
<Value>ReqPr</Value>
</Value>
<Value name="13">
<Value>SiLF</Value>
</Value>
<Value name="14">
<Value>SiLS</Value>
</Value>
<Value name="15">
<Value>SiRF</Value>
</Value>
<Value name="16">
<Value>SiRS</Value>
</Value>
<Value name="17">
<Value>Temp1</Value>
</Value>
<Value name="18">
<Value>TypeData</Value>
</Value>
<Value name="19">
<Value>UsDisF</Value>
</Value>
<Value name="20">
<Value>UsDisS</Value>
</Value>
<Value name="21">
<Value>idClass</Value>
</Value>
<Value name="22">
<Value>idProp</Value>
</Value>
<Value name="23">
<Value>idPattDet</Value>
</Value>
<Value name="24">
<Value>idPropDet</Value>
</Value>
<Value name="25">
<Value>Weight</Value>
</Value>
<Value name="26">
<Value>SourseSys</Value>
</Value>
<Value name="27">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.ONT.PatternD</DataLocation>
<DefaultData>PatternDefaultData</DefaultData>
<IdLocation>^App.ONT.PatternD</IdLocation>
<IndexLocation>^App.ONT.PatternI</IndexLocation>
<StreamLocation>^App.ONT.PatternS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// Весовой коэффициент при распозновании
Property Weight As Lib.DataTypes.Double;

/// Вид значения свойства в полном описании
Property LoValF As Lib.DataTypes.String(DISPLAYLIST = ",полное,краткое,латинское", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",F,S,L");

/// Вид значения свойства в кратком описании
Property LoValS As Lib.DataTypes.String(DISPLAYLIST = ",полное,краткое,латинское", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",F,S,L");

/// Способ заполнения значения
Property MethVol As Lib.DataTypes.String(DISPLAYLIST = ",из справочника,ручной ввод,расчетное,обобщенное", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",S,H,C,G") [ Required ];

/// №пп в шаблоне
Property Npp As Lib.DataTypes.Integer(IndexValue = 1, SortingType = "Z") [ Required ];

/// №пп свойства в полном описании
Property NumF As Lib.DataTypes.Integer(IndexValue = 1, SortingType = "Z");

/// №пп свойства в кратком описании
Property NumS As Lib.DataTypes.Integer(IndexValue = 1, SortingType = "Z");

/// Наличие ЕИ при заполнении значения
Property ReqEI As Lib.DataTypes.String(DISPLAYLIST = ",обязательно,необязательно,запрещено", MAXLEN = 1024, VALUELIST = ",1,0,2") [ Required ];

/// Обязат.заполнения значения свойства
Property ReqPr As Lib.DataTypes.String(DISPLAYLIST = ",обязательно,не обязательно", MAXLEN = 1024, VALUELIST = ",1,0") [ Required ];

/// Доп.симв.слева в полном описании
Property SiLF As Lib.DataTypes.String(MAXLEN = 1024);

/// Доп.симв.слева в кратком описании
Property SiLS As Lib.DataTypes.String(MAXLEN = 1024);

/// Доп.симв.справа в полном описании
Property SiRF As Lib.DataTypes.String(MAXLEN = 1024);

/// Доп.симв.справа в кратком описании
Property SiRS As Lib.DataTypes.String(MAXLEN = 1024);

/// Временное поле
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Тип данных значения
Property TypeData As Lib.DataTypes.String(DISPLAYLIST = ",строка,действ.число,целое число", MAXLEN = 1024, VALUELIST = ",str,car,int") [ Required ];

/// Использование свойства в полном описании
Property UsDisF As Lib.DataTypes.String(DISPLAYLIST = ",Да,Нет", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",1,0");

/// Использование свойства в кратком описании
Property UsDisS As Lib.DataTypes.String(DISPLAYLIST = ",Да,Нет", IndexValue = 1, MAXLEN = 1024, VALUELIST = ",1,0");

/// Класс
Property idClass As App.ONT.Class [ Required ];

/// Детальная строка шаблона для обобщающего
Property idPattDet As App.ONT.Pattern;

/// Свойство
Property idProp As App.ONT.Prop [ Required ];

/// Детальное свойство
Property idPropDet As App.ONT.Prop;

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index LoValF On LoValF As Truncate(200) [ Type = bitmap ];

Index LoValS On LoValS As Truncate(200) [ Type = bitmap ];

Index MethVol On MethVol As Truncate(200) [ Type = bitmap ];

Index Npp On Npp [ Type = bitmap ];

Index NumF On NumF [ Type = bitmap ];

Index NumS On NumS [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

Index UsDisF On UsDisF As Truncate(200) [ Type = bitmap ];

Index UsDisS On UsDisS As Truncate(200) [ Type = bitmap ];

Index idClass On idClass [ Type = bitmap ];

Index idPattDet On idPattDet [ Type = bitmap ];

Index idProp On idProp [ Type = bitmap ];

Index idPropDet On idPropDet [ Type = bitmap ];

ForeignKey fkidClass(idClass) References App.ONT.Class();

ForeignKey fkidPattDet(idPattDet) References App.ONT.Pattern();

ForeignKey fkidProp(idProp) References App.ONT.Prop();

ForeignKey fkidPropDet(idPropDet) References App.ONT.Prop();

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

