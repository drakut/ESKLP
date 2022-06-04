/// Номенклатура контрагентов (прайсы)
Class App.PRC.Nomen Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Перед сохранением
Method addCheckSet(ByRef in, ByRef out)
{
	// На входе :
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование)
	//			  in.parentid -> ID главной записи для записи ракурса 
	//			    in.jobnum -> Номер задания для фоновых задач
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=..%Id()
	//	s name=..Name			// Получить поле из Нового тела записи
	s out={"error":""}
	try {
		d ..setSpecName()
		// !!! Здесь писать свой код
		;s ^mir("addCheckSet")=in.%ToJSON()
		
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

/// После сохранения
Method addAfterSave(ByRef in, ByRef out)
{
	// На входе :
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование)
	//			  in.parentid -> ID главной записи для записи ракурса 
	//			    in.jobnum -> Номер задания для фоновых задач
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=..%Id()
	//	s name=..Name			// Получить поле из Нового тела записи
	s out={"error":""}
	try {
		
		// !!! Здесь писать свой код
		;s ^mir("AfterSave")=in.%ToJSON()
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
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
		s:((in.field="gridMakNomenCodeName")||(in.field="expMakNomenCodeName"))&&($ISO(..idMakNomen)) out.value=..idMakNomen.Name_" "_..idMakNomen.idFirm.Name
		if in.field="gridNomenCodeName" s out.value=..GetNomenCodeName(..%Id())    ; Связанная КП в виде "[Код] Наименование"
		if in.field="gridNomenAutoCodeName" {s:$ISO(..idNomenAuto) out.value="["_..idNomenAuto.Code_"]"_..idNomenAuto.Name}
        
        if in.field = "expMakNomenName" {
			k ind,ptr,id
			s filter = [{"field":"Code","type":"=","data":(..idMakNomen)}]
			s err = ##class(App.MAF.MakNomen).Filter(filter,.ind)
			while ##class(App.MAF.MakNomen).indNEXT(.ind, .ptr, .id) {
				s oldMakNomen = ##class(App.MAF.MakNomen).%OpenId(id) 
				s:$ISO(oldMakNomen) out.value = $ZSTRIP(oldMakNomen.Name_"["_oldMakNomen.ProducerName_"]", "*C")
			}
		}
        
        ;==
        if in.form="AppPRCNomen_LinkCTN"  ; Закладка связь прайсов с КП в конструкторе КП
           {if in.field="hintIndicZHK" s out.value=..getHintIndicZHK(..%Id())    ; Хинт на ячейке "ЗШК" - предложение занести ЗШК в текущую КП
            if in.field="hintIndicFirm" s out.value=..getHintIndicFirm(..%Id())  ; Хинт на ячейке "Связанная фирма" -собщение об отсутсвии Фирмы в свойствах по фирмам текущей КП
            ;
            if in.field="editRuFirm" s out.value=..getInfoRU(..%Id())      ;Инфо о существующем РУ. Может быть перехвачено перед сохранением прайса и записано в свойства КП по фирмам
            if in.field="editArtic" s out.value="эмуляция существующего Арикула"  ; Артикул будет перехвачено перед сохранением прайса и записано в свойства КП         
           }
		//=== 2. и т.д.
		//  .....
		
		i in.form = "AppPRCNomenLinker" {
			s:in.field="expCodeAMTO" out.value=##class(App.MAF.Nomen).OpenCode(..Code).CodeAMTO
		}
		
		// Конец. 
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

/// Поиск существующего РУ по Связанной фирме в свойствах "App.CTN.NomenVolFirm" текущей КП
/// k  s val=##class(App.PRC.Nomen).getInfoRU(1632322) w !,val
/// 
ClassMethod getInfoRU(id As %Integer) As %String
{
  	;  На входе: ID-текущего Прайса с непустой Связанной Фирмой
  	;           	
  	s out={"error":""},val=""
  	try {
 	 	s objPrc=##Class(App.PRC.Nomen).%OpenId(id)   ; объект - Прайс
 	 	;-- Проверки
 	 	i '$ISOBJECT(objPrc.idNomen) q   ; В прайсе нет ссылки на КП. Выход
 	 	i '$ISOBJECT(objPrc.IdFirm) q    ; В прайсе нет ссылки на Фирму. Выход
        s NameSetUp="PropFirmRU"
        s out.error=##class(Lib.App.Setup).GetSetup(NameSetUp,"","",.CodeProp,.idSetUp) q:out.error'=""  ;  Получить значение настройки и ее ID
		i CodeProp="" s out.error="Отсутсвует настройка 'Код свойства Упаковщик по Фирмам'" q
        ;-- Получить idProp по его коду
  	 	s idProp=##class(App.ONT.PropFirm).GetIdByCode(CodeProp) i idProp="" s out.error="В справочнике Свойств Фирм нет записи с кодом="_CodeProp q
        ;-- ОК 	 	
 	 	s idNomen=objPrc.idNomen.%Id()   ; ID- КП не пустой
 	 	s idFirm=objPrc.IdFirm.%Id()     ; ID- Фирмы не пустой
	    ;-- Поиск в App.CTN.NomenVolFirm РУ по ID-Фирма AND текущая ID-КП AND ID-свойство РУ
		s filter=[{"field":"idNomen","type":"равно", "data":(idNomen)},{"oper":"AND"},   ; idNomen	Каталожная номенклатура
				  {"field":"idFirm", "type":"равно", "data":(idFirm)},{"oper":"AND"},    ; idFirm 	Фирма
				  {"field":"idProp", "type":"равно", "data":(idProp)}]                   ; idProp свойства "РУ"
	    d ##class(App.CTN.NomenVolFirm).Filter(.filter,.ind)                             ;
	    s ptr="" d ..indNEXT(.ind,.ptr,.idVol) q:idVol=""
	    s val=##class(App.CTN.NomenVolFirm).%OpenId(idVol).VolHand    ; Значение РУ
 	 	} // try
  	catch exp {s out.error=..ErrorDetect(.exp)} // catch
  	q val
}

/// Хинт на Связанной фирме об отсутсвии Фирмы в свойствах "App.CTN.NomenVolFirm" текущей КП
/// k  s val=##class(App.PRC.Nomen).getHintIndicFirm(5633) w !,val
/// 
ClassMethod getHintIndicFirm(id As %Integer) As %String
{
  	;  На входе: ID-текущего Прайса с непустой Связанной Фирмой
  	;           	
  	s out={"error":""},val=""
  	try {
 	 	s objPrc=##Class(App.PRC.Nomen).%OpenId(id)   ; объект - Прайс
 	 	i '$ISOBJECT(objPrc.idNomen) q   ; В прайсе нет ссылки на КП. Выход
 	 	i '$ISOBJECT(objPrc.IdFirm) q    ; В прайсе нет ссылки на Фирму. Выход
        ; 	 	
 	 	s idNomen=objPrc.idNomen.%Id()   ; ID- КП не пустой
 	 	s idFirm=objPrc.IdFirm.%Id()     ; ID- Фирмы не пустой
	    ;-- Поиск Фирмы по текущей КП в App.CTN.NomenVolFirm
		s filter=[{"field":"idNomen","type":"равно", "data":(idNomen)},{"oper":"AND"},   ; idNomen	Каталожная номенклатура
				  {"field":"idFirm", "type":"равно", "data":(idFirm)}]                   ; idFirm 	Фирма
	    d ##class(App.CTN.NomenVolFirm).Filter(.filter,.ind)                             ;
        i ..indCOUNT(.ind)=0 s val="Фирмы нет в свойствах по фирмам текущей КП"

 	 	} // try
  	catch exp {s out.error=..ErrorDetect(.exp)} // catch
  	q val
}

/// Хинт на ЗШК с предложением занести ЗШК в App.CTN.NomenBarCode текущей КП
/// k  s val=##class(App.PRC.Nomen).getHintIndicZHK(965780) w !,val
/// 
ClassMethod getHintIndicZHK(id As %Integer) As %String
{
  	;  На входе: ID-текущего Прайса с непустой КП, Связанной Фирмой и ЗШК
  	;           	
  	s out={"error":""},val=""
  	try {
 	 	s objPrc=##Class(App.PRC.Nomen).%OpenId(id)   ; объект - Прайс
 	 	i '$ISOBJECT(objPrc.idNomen) q   ; В прайсе нет ссылки на КП. Выход
 	 	i '$ISOBJECT(objPrc.IdFirm) q    ; В прайсе нет ссылки на Фирму. Выход
 	 	i objPrc.ZHK="" q                ; В прайсе ЗШК пуст. Выход
        ; 	 	
 	 	s idNomen=objPrc.idNomen.%Id()   ; ID- КП не пустой
 	 	s idFirm=objPrc.IdFirm.%Id()     ; ID- Фирмы не пустой
	    ;-- Поиск ЗШК по текущей КП в App.CTN.NomenBarCode
		s filter=[{"field":"idNomen","type":"равно", "data":(idNomen)},{"oper":"AND"},   ; idNomen	Каталожная номенклатура
				  {"field":"idFirm", "type":"равно", "data":(idFirm)}, {"oper":"AND"},   ; idFirm	Фирма
				  {"field":"ZHK",    "type":"равно", "data":(objPrc.ZHK)}]                ; ZHK 	Штрих-код      
	    d ##class(App.CTN.NomenBarCode).Filter(.filter,.ind)                    ;
        i ..indCOUNT(.ind)=0 s val="Можно занести ЗШК в КП"

 	 	} // try
  	catch exp {s out.error=..ErrorDetect(.exp)} // catch
  	q val
}

/// 
///  Связанная КП в виде "Код Наименование"
/// k  s val=##class(App.PRC.Nomen).GetNomenCodeName(851365) w !,val
ClassMethod GetNomenCodeName(id As %Integer) As %String
{
	; На входе :
	;   id -> id записи "App.PRC.Nomen"

	; На выходе :
	;   val <- Значение

	s out={"error":""}
	try {
		s val=""
		s obj=##Class(App.PRC.Nomen).%OpenId(id)
		i obj.idNomen'="" s val="["_obj.idNomen.Code_"] "_obj.idNomen.Name     ; Связанная КП в виде "[Код] Наименование"
	}
	catch exp {s out.error=..ErrorDetect(.exp)} // catch 	
	q val
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
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//	  out.typejob -> Метод исполнения задачи ("fast" - задача исполняется быстро, не в фоне, "job" - задача исполняется медленно, в фоне)
	//	  out.refresh -> 1 - Обновлять экран после выполнения действия
	//	  out.message -> Сообщение для клиента. Выводится после исполнения прцедуры по желанию (выводится в модальном окне)
	// Примеры : (см. также в Lib.App.ImportError)
	// if (count<100) {s out.typejob="fast" d ..Process()}
	// else			  {s out.typejob="job"  j ..Process()}
	s err=""
	try {
		s out.error=""
		
		// !!! Здесь писать свой код
		;== Запись ЗШК из текущей строки Прайса в "App.CTN.NomenBarCode" из формы:"AppPRCNomen_LinkCTN", секции "Sec-Toolbar" по кнопке:"SaveZHKinNomenBarCode"
		if in.namecall="SaveZHKinNomenBarCode" 
		    {s out.typejob="fast"	             ; Задача исполняется НЕ фоне
			 s idPrc=in.actualid
			 i idPrc'="" d ..doSaveZHKinNomenBarCode(idPrc, .out)   ; Тихая Запись ЗШК в "App.CTN.NomenBarCode"
			 s out.refresh=1                                        ; Обновить экран после транзакции
		    }

		;== Запись Производитель=Связанная Фирма из текущей строки Прайса в "App.CTN.NomenVolFirm" из формы:"AppPRCNomen_LinkCTN", секции "Sec-Toolbar" по кнопке:"SaveProducerinNomenPropFirm"
		if in.namecall="SaveProducerinNomenPropFirm" 
		    {s out.typejob="fast"	             ; Задача исполняется НЕ фоне
			 s idPrc=in.actualid
			 i idPrc'="" d ..doSaveProducerinNomenPropFirm(idPrc, .out)   ; Тихая Запись связанной Фирмы, как Производителя в "App.CTN.NomenVolFirm"
			 s out.refresh=1                                              ; Обновить экран после транзакции
		    }
		
		;== Запись Упаковщик=Связанная Фирма из текущей строки Прайса в "App.CTN.NomenVolFirm" из формы:"AppPRCNomen_LinkCTN", секции "Sec-Toolbar" по кнопке:"SaveUpackinNomenPropFirm"
		if in.namecall="SaveUpackinNomenPropFirm" 
		    {s out.typejob="fast"	             ; Задача исполняется НЕ фоне
			 s idPrc=in.actualid
			 i idPrc'="" d ..doSaveUpackinNomenPropFirm(idPrc, .out)   ; Тихая Запись связанной Фирмы, как Упаковщик в "App.CTN.NomenVolFirm"
			 s out.refresh=1                                              ; Обновить экран после транзакции
		    }

		i in.namecall="AutoSetAnalog" {
			s out.typejob	= "job"
			s in.setAutoLink= %session.Get("setAutoLink", 1)
			s in.classNameR	= %session.Get("classNameR", "")
			s in.idPlan		= %session.Get("idPlan", "")
			s in.stem		= %session.Get("stemming", 1)
			s in.idAgent	= %session.Get("idAgent", "")
			s in.log		= 0
			s in.reCalc		= 1
			
			s inLinker		= in.%ToJSON()
			j ##class(App.MAF.Linker).AutoSetAnalog(inLinker)
		}
		
		i in.namecall="SetSessionVariable" {
			s out.typejob	= "fast"
			d ##class(App.MAF.Linker).SetSessionVariable(.in, .out)
		}
		
		i in.namecall="DelAgentNomsAndLinks"{
			s out.typejob	= "job"
			s out.refresh	= 0
			s inLinker		= in.%ToJSON()
			j ##class(App.MAF.Linker).DelAgentNomsAndLinks(inLinker)
			
		}
		
		i in.namecall="ReCalc"{
			s out.typejob	= "fast"
			s in.setAutoLink= %session.Get("setAutoLink", 0)
			s in.classNameR	= %session.Get("classNameR", "")
			s in.idPlan		= %session.Get("idPlan", "")
			s in.stem		= %session.Get("stemming", 1)
			s in.idAgent	= %session.Get("idAgent", "")
			s in.reCalc 	= 1
			s in.log		= 1
			d ##class(App.MAF.Linker).ReCalc(in, out)
		}
		
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// Тихая Запись связанной Фирмы, как Упаковщика в "App.CTN.NomenVolFirm"
/// k  s out={} d ##class(App.PRC.Nomen).doSaveUpackinNomenPropFirm(965780, .out) w !,out.error
/// 
ClassMethod doSaveUpackinNomenPropFirm(idPrc As %String, ByRef out)
{
  	;  На входе: idPrc -> ID-Прайса
  	;           	
  	s out={"error":""}
 	try {
 	 	s NameSetUp="PropFirmUpac"       ; Настройка - Код свойства по Фирмам 'Упаковщик'.
 	 	s out.error=##class(Lib.App.Setup).GetSetup(NameSetUp,"","",.CodeProp,.idSetUp)  ;  Получить значение настройки и ее ID
 	    i CodeProp="" s out.error="Отсутсвует настройка 'Код свойства Упаковщик по Фирмам'" q
 	 	s objPrc=..%OpenId(idPrc)        ; Загрузка прайса
 	 	i '$ISOBJECT(objPrc.idNomen) q   ; В прайсе нет ссылки на КП. Выход
 	 	i '$ISOBJECT(objPrc.IdFirm) q    ; В прайсе нет ссылки на Фирму. Выход
        ; 	 	
 	 	s idNomen=objPrc.idNomen.%Id()   ; ID- КП не пустой
 	 	s idFirm=objPrc.IdFirm.%Id()     ; ID- Фирмы не пустой
 	 	;-- Изготовить или найти существующую запись App.CTN.NomenVolFirm. Возвращает id-записи
	    s idVal=##class(App.CTN.NomenVolFirm).doMakeRec(idNomen,idFirm,CodeProp, .out) q:out.error'=""
 	 	;w !,"idVal=",idVal
 	 	} // try
  	catch exp {s out.error=..ErrorDetect(.exp)} // catch
  	q
}

/// Тихая Запись связанной Фирмы, как Производителя в "App.CTN.NomenVolFirm"
/// k  s out={} d ##class(App.PRC.Nomen).doSaveProducerinNomenPropFirm(965780, .out) w !,out.error
/// 
ClassMethod doSaveProducerinNomenPropFirm(idPrc As %String, ByRef out)
{
  	;  На входе: idPrc -> ID-Прайса
  	;           	
  	s out={"error":""}
 	try {
 	 	s NameSetUp="PropFirmProducer"   ; Настройка - Код свойства по Фирмам 'Производитель'.
 	 	s out.error=##class(Lib.App.Setup).GetSetup(NameSetUp,"","",.CodeProp,.idSetUp)  ;  Получить значение настройки и ее ID
 	    i CodeProp="" s out.error="Отсутсвует настройка 'Код свойства Производитель по Фирмам'" q
 	 	s objPrc=..%OpenId(idPrc)        ; Загрузка прайса
 	 	i '$ISOBJECT(objPrc.idNomen) q   ; В прайсе нет ссылки на КП. Выход
 	 	i '$ISOBJECT(objPrc.IdFirm) q    ; В прайсе нет ссылки на Фирму. Выход
        ; 	 	
 	 	s idNomen=objPrc.idNomen.%Id()   ; ID- КП не пустой
 	 	s idFirm=objPrc.IdFirm.%Id()     ; ID- Фирмы не пустой
 	 	;-- Изготовить или найти существующую запись App.CTN.NomenVolFirm. Возвращает id-записи
	    s idVal=##class(App.CTN.NomenVolFirm).doMakeRec(idNomen,idFirm,CodeProp, .out) q:out.error'=""
 	 	;w !,"idVal=",idVal
 	 	} // try
  	catch exp {s out.error=..ErrorDetect(.exp)} // catch
  	q
}

/// Тихая Запись ЗШК в "App.CTN.NomenBarCode"
/// k  s out={} d ##class(App.PRC.Nomen).doSaveZHKinNomenBarCode(906169, .out) w !,out.error
/// 
ClassMethod doSaveZHKinNomenBarCode(idPrc As %String, ByRef out)
{
  	;  На входе: idPrc -> ID-Прайса
  	;           	
  	s out={"error":""}
 	try {
 	 	s objPrc=..%OpenId(idPrc)   ; Загрузка прайса
 	 	i '$ISOBJECT(objPrc.idNomen) q   ; В прайсе нет ссылки на КП. Выход
 	 	i '$ISOBJECT(objPrc.IdFirm) q    ; В прайсе нет ссылки на Фирму. Выход
 	 	i objPrc.ZHK="" q                ; В прайсе ЗШК пуст. Выход
        ; 	 	
 	 	s idNomen=objPrc.idNomen.%Id()   ; ID- КП не пустой
 	 	s idFirm=objPrc.IdFirm.%Id()     ; ID- Фирмы не пустой
 	 	;-- Изготовить или найти существующую запись App.CTN.NomenBarCode. Возвращает id-записи
 	 	s idBarCode=##class(App.CTN.NomenBarCode).doMakeRec(idNomen,idFirm,objPrc.ZHK, .out) q:out.error'=""
 	 	;w !,"idBarCode=",idBarCode
 	 	} // try
  	catch exp {s out.error=..ErrorDetect(.exp)} // catch
  	q
}

/// Получить стиль ячейки
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
	s err=""
	s out.style=""
	try {
		;=== Маркировать колонки    "name":"gridZHK", если есть предложение занести ЗШК в КП
		if in.form="AppPRCNomen_LinkCTN"
			{    if in.field="gridZHK" {s:..getHintIndicZHK(..%Id())'="" out.style={"CodeStyle":"26"}}  ; Текст Предложения не пуст. Код стиля = 26 
			 elseif in.field="gridIdFirm" {s:..getHintIndicFirm(..%Id())'="" out.style={"CodeStyle":"26"}}  ; Текст Сообщения не пуст. Код стиля = 26 
			}

		
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

/// !!! Головной метод addImport здесь пока не нужен. Временно TXT грузим через терминал
///  
/// Заполнение в прайсе App.PRC.Nomen полей "Кат.номен" и "Мак-номен" по макету ФЭ
/// Только корректировка этих полей. Строка прайса должна существовать
/// 
ClassMethod addImportCtnMakFE(ByRef in, ByRef out)
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
 		 s str=in.source                     ; Строка с данными из файла в виде динамобекта
 		
 		 ;=== Разборка полей строки файла
	 	 s AgentCode 	=str.impAgentCode	; Код Контрагента
		 s AgentName 	=str.impAgentName	; Наименование Контрагента
		 s PrcCode 		=str.impPrcCode	    ; Код Прайса
		 s PrcName 		=str.impPrcName	    ; Наименование Прайса
		 s CtnNomCode	=str.impCtnNomCode	; Код связанной Каталожной номенклатуры или пусто
		 s MakNomCode	=str.impMakNomCode	; Код связанной Мак-Номенклатуры или пусто
		 s NomName 		=str.impNomName	    ; Наименование связанных Номенклатур

		 ;=== Проверки и получение ID'ов по кодам
		 s (idNomen,idMakNomen)=""   ; НУ   
		 ;    1. Код Контрагента
 		 i AgentCode="" s out.error="Не задан Код Контрагента. " q   ; Ошибка. Выход
 		 s idAgent=##class(App.PRC.Agent).GetIdByCode(AgentCode) i idAgent="" s out.error="Нет Контрагента с код="_Agent q   ; Ошибка. Выход
		 ;    2. Код Прайса
 		 i PrcCode="" s out.error="Не задан Код Прайса." q   ; Ошибка. Выход
		 ;    3. Код связанной Каталожной номенклатуры или пусто
 		 i CtnNomCode'="" s idNomen=##class(App.CTN.Nomen).GetIdByCode(CtnNomCode) i idNomen="" s out.error="Нет связанной Каталожной номенклатуры с код="_CtnNomCode q   ; Ошибка. Выход
		 ;    4. Код связанной  Мак-Номенклатуры или пусто
 		 i MakNomCode'="" s idMakNomen=##class(App.MAK.Nomen).GetIdByCode(MakNomCode) i idMakNomen="" s out.error="Нет связанной Мак-Номенклатуры с код="_MakNomCode q   ; Ошибка. Выход
         
         i PrcCode=52228 s out.error="Эмуляция ошибки." q   ; Ошибка. Выход
         
         
	     ;-- Поиск существующей PRC-Номенклатуры
		 k ind
		 s filter=[{"field":"idAgent","type":"равно", "data":(idAgent)},{"oper":"AND"},   ; idAgent	Контрагента
		 		   {"field":"Code",   "type":"равно", "data":(PrcCode)}]                  ; Код Прайса
	     d ..Filter(.filter,.ind)
	     s ptr="" d ..indNEXT(.ind,.ptr,.idPrc) i idPrc="" s out.error="У Контрагента с код="_AgentCode_" нет строки Прайса с код="_PrcCode q   ; Ошибка. Выход
     	
     	 ;--- Загрузить найденный
     	 s obj=..%OpenId(idPrc)
     	
     	 ;-- Заполнение полей
         ;   Каталожная номенклатура
         i idNomen'="" d obj.idNomenSetObjectId(idNomen)       ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
		 e             s obj.idNomen="" 	                      ; или пусто
         ;   Мак-Номенклатуры
         i idMakNomen'="" d obj.idMakNomenSetObjectId(idMakNomen)     ; Присвоили ссылку, указав ID без загрузки ссылочного объекта
		 e                s obj.idMakNomen="" 	                  ; или пусто
	  	
	  	 ;-- Транзакция App.PRC.Nomen
    	 d obj.%Save(0) s out.error=obj.ObjError() if out.error'="" q   ; Ошибка. Выход
		}
 catch exp {d ..ErrorDetect(.exp)} // catch 	
 q
}

/// Терминальная загрузка связи App.PRC.Nomen с КП и МАК (заполнение полей "Кат.номен" и "Мак-номен") по макету ФЭ txt-файла
///  
/// !!! TXT-файл должен быть на Cache-сервере  и сохранен в "Unicode" или UTF8.
/// Т.к. в общем инструменте пока нет txt-загрузки
/// Здесь только чтение строк TXT-файла, преобразование их в динамобъект и вызов метода сохранения строки прайса d ..addImportFE(.in,.out)
/// 
/// 
/// k  d ##class(App.PRC.Nomen).ImportTxtFile("C:\InterSystems\Cache\CSP\maf\LoadFromFE\", "Прайсы-КП-МАК все (utf8).txt", 2)
/// k  d ##class(App.PRC.Nomen).ImportTxtFile("C:\InterSystems\Cache\CSP\maf\LoadFromFE\", "Прайсы-КП-МАК(utf8).txt", 2)
/// 
ClassMethod ImportTxtFile(Dir As %String, FileTxt As %String, StartLine As %String)
{
 ; 
 ;       Dir -> Путь к директори на Cache-сервере  "C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 ;   FileTxt -> Имя TXT-файл       "Прайсы проба.txt"
 ; StartLine -> Номера тхт-строки, с которой начинается загрузка (пропустить заголовок)

 s (in,out)={}
 ;-- НУ по умолчанию
 i $g(Dir)="" s Dir="C:\InterSystems\Cache\CSP\maf\LoadFromFE\"
 i $g(FileTxt)="" s FileTxt="Прайсы проба.txt"
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
	 	 	;s (in,out)={}
	 	 	s in.source={}
	 	 	;-- Строку файла преобразуем в динамобъект.
 		 	s in.source.impAgentCode 	=$p(line,sep,1)	; Код Контрагента
			s in.source.impAgentName 	=$p(line,sep,2)	; Наименование Контрагента
			s in.source.impPrcCode 		=$p(line,sep,3)	; Код Прайса
			s in.source.impPrcName 		=$p(line,sep,4)	; Наименование Прайса
			s in.source.impCtnNomCode	=$p(line,sep,5)	; Код связанной Каталожной номенклатуры или пусто
			s in.source.impMakNomCode	=$p(line,sep,6)	; Код связанной Мак-Номенклатуры или пусто
			s in.source.impNomName 		=$p(line,sep,7)	; Наименование связанных Номенклатур
			
			;-- Индикация
			w !,"num=",num,$c(9),in.source.impPrcCode,$c(9),in.source.impPrcName
		 	
		 	;--- Транзакция тхт-строки
 		 	d ..addImportCtnMakFE(.in,.out)
 		 	i out.error'="" 
 		 		{w !,$c(9,9),"Ошибка. "_out.error_" См. Протокол ошибок загрузки."   ; писать в журнал ошибок импорта
				 ;-- заполнение пременной части сообщения об ошибке импорта
				 s inErr.TxtError = out.error   ; это мой текст ошибки
				 s inErr.Regime   = 1	    	; Режим (1=Корректировка,2=Дозапись) = режим
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
/// d ##class(App.PRC.Nomen).ReSaveFiltr()
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
/// d ##class(App.PRC.Nomen).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) 
  		{d ..ReSaveOne(id)    ; Пересохранение одной записи
 
 		}
 q
}

/// Пересохранение одной записи
/// k  d ##class(App.PRC.Nomen).ReSaveOne(1)
/// Переиндексация:  k ^App.PRC.NomenI d ##class(App.PRC.Nomen).%BuildIndices()
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 
 ; --- Здесь что-то  ..
 s obj.idNomenAuto=""  ; очистка поля
 
 ;--- и пересохраняем
 d obj.%Save(0) s err=..ObjError() if err'="" w !,$c(9),err q   ; Выход по ошибке
 q
}

/// Может Быть родителем
Parameter CanParent = 0;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-PRC-Nomen";

/// Список уникальных ссылочных полей
Parameter listUnique = ",idAgent";

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
<Value>Code</Value>
</Value>
<Value name="5">
<Value>CodeFirm</Value>
</Value>
<Value name="6">
<Value>CodeLand</Value>
</Value>
<Value name="7">
<Value>Com</Value>
</Value>
<Value name="8">
<Value>GID</Value>
</Value>
<Value name="9">
<Value>IdFirm</Value>
</Value>
<Value name="10">
<Value>LastDatePrc</Value>
</Value>
<Value name="11">
<Value>Name</Value>
</Value>
<Value name="12">
<Value>NameFirm</Value>
</Value>
<Value name="13">
<Value>NameLand</Value>
</Value>
<Value name="14">
<Value>NrName</Value>
</Value>
<Value name="15">
<Value>SouGID</Value>
</Value>
<Value name="16">
<Value>Status</Value>
</Value>
<Value name="17">
<Value>Temp1</Value>
</Value>
<Value name="18">
<Value>ZHK</Value>
</Value>
<Value name="19">
<Value>idAgent</Value>
</Value>
<Value name="20">
<Value>idNomen</Value>
</Value>
<Value name="21">
<Value>idNomenAuto</Value>
</Value>
<Value name="22">
<Value>idMakNomen</Value>
</Value>
<Value name="23">
<Value>SourseSys</Value>
</Value>
<Value name="24">
<Value>SourceSys</Value>
</Value>
<Value name="25">
<Value>TempIdMakNomen</Value>
</Value>
<Value name="26">
<Value>TempCabCode</Value>
</Value>
<Value name="27">
<Value>TempIdMakNomenAuto</Value>
</Value>
<Value name="28">
<Value>TempLinkTrue</Value>
</Value>
<Value name="29">
<Value>TempProcessed</Value>
</Value>
<Value name="30">
<Value>TempKoefMakImp</Value>
</Value>
<Value name="31">
<Value>CreationLabel</Value>
</Value>
<Value name="32">
<Value>TempCategory</Value>
</Value>
<Value name="33">
<Value>TempSPE</Value>
</Value>
<Value name="34">
<Value>TempCodeAP</Value>
</Value>
<Value name="35">
<Value>TempCodePharmacy</Value>
</Value>
<Value name="36">
<Value>TempMNN</Value>
</Value>
<Value name="37">
<Value>TempIdSKMTRAuto</Value>
</Value>
<Value name="38">
<Value>SpecName</Value>
</Value>
</Data>
<DataLocation>^App.PRC.NomenD</DataLocation>
<DefaultData>NomenDefaultData</DefaultData>
<IdLocation>^App.PRC.NomenD</IdLocation>
<IndexLocation>^App.PRC.NomenI</IndexLocation>
<StreamLocation>^App.PRC.NomenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Код номенклатуры
Property Code As Lib.DataTypes.String(IndexSpecValue = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "Z", Unique = "Z") [ Required ];

/// Код производителя из прайса
Property CodeFirm As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Код страны из прайса
Property CodeLand As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// ГИД
Property GID As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Связанная Фирма
Property IdFirm As App.NSI.Firm;

/// Дата последнего Прайса
Property LastDatePrc As Lib.DataTypes.Date(IndexValue = 1, SortingType = "Z");

/// Наименование номенклатуры
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P") [ Required ];

/// Наименование производителя из Прайса
Property NameFirm As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Наименование страны из Прайса
Property NameLand As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, SortingType = "P");

/// Нормализованное наименование
Property NrName As Lib.DataTypes.String(IndexSpecWord = 1, MAXLEN = 1024);

/// Источник ГИД
Property SouGID As Lib.DataTypes.String(DISPLAYLIST = ",ФармСМ,КроссМаркет", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",1,2");

/// Статус
Property Status As Lib.DataTypes.String(DISPLAYLIST = ",экспертиза,обработано,отклонено", IndexValue = 1, MAXLEN = 1024, SortingType = "Z", VALUELIST = ",1,2,3");

/// Временное поле для id-записи ФЭ-Прайса, перенесенной SOAP'ом
Property Temp1 As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// 
/// 
/// 
/// Штрих-код
Property ZHK As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024, SortingType = "Z");

/// Контрагент
Property idAgent As App.PRC.Agent [ Required ];

/// Связанная МАК-номенклатура
Property idMakNomen As App.MAK.Nomen;

/// Связанная Каталожная номенклатура
Property idNomen As App.CTN.Nomen;

/// Связанная Каталожная номенклатура, назначенная автоматически. Назначается вызовом метода и заполнено только у тех, у которых ручное значение не совпадает с автоматически-назначенным
Property idNomenAuto As App.CTN.Nomen;

/// Каким образом связка образовалась в портальной номенклатуре - ручной, по штрихкоду и т.д.
Property CreationLabel As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// SpecName
Property SpecName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, MAXLEN = 1024);

Index CreationLabel On CreationLabel As Truncate(200) [ Type = bitmap ];

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CodeFirm On CodeFirm As Truncate(200) [ Type = bitmap ];

Index CodeLand On CodeLand As Truncate(200) [ Type = bitmap ];

Index GID On GID As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index IdFirm On IdFirm [ Type = bitmap ];

Index LastDatePrc On LastDatePrc [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index NameFirm On NameFirm As Truncate(200) [ Type = bitmap ];

Index NameLand On NameLand As Truncate(200) [ Type = bitmap ];

Index SouGID On SouGID As Truncate(200) [ Type = bitmap ];

Index Status On Status As Truncate(200) [ Type = bitmap ];

Index ZHK On ZHK As Truncate(200) [ Type = bitmap ];

Index idAgent On idAgent [ Type = bitmap ];

Index idMakNomen On idMakNomen [ Type = bitmap ];

Index idNomen On idNomen [ Type = bitmap ];

Index idNomenAuto On idNomenAuto [ Type = bitmap ];

Index SpecName On SpecName As Truncate(1024) [ Type = bitmap ];

ForeignKey fkIdFirm(IdFirm) References App.NSI.Firm();

ForeignKey fkidAgent(idAgent) References App.PRC.Agent();

ForeignKey fkidMakNomen(idMakNomen) References App.MAK.Nomen();

ForeignKey fkidNomen(idNomen) References App.CTN.Nomen();

ForeignKey fkidNomenAuto(idNomenAuto) References App.CTN.Nomen();

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

/// Метод получения строки для сравнения из свойств класса
/// !!! НЕ УДАЛЯТЬ !!!
Method GetString(in, out)
{
	try {
		s str = ..Name_" "_..NameLand_" "_..NameFirm

		d:in.data.log %log.%Push({"Oper":"<strong>Начало обработок строки, привязанных к контрагенту:</strong>","Result":("<strong>"_str_"</strong>")})
		k ind,ptr,id 	; применение паттернов оработки, привязанных к контрагенту прайса
		s filter = [{"field":"Agent","type":"=","data":(..idAgent.%Id())}]
		s err = ##class(App.MAF.StringPattern).Filter(filter,.ind)
		i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
		while ##class(App.MAF.StringPattern).indNEXT(.ind,.ptr,.id) {
			s pattern = ##class(App.MAF.StringPattern).%OpenId(id)
			s str = pattern.Apply(str, in.data.log, out)
			q:out.error'=""
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		s status = $$$ERROR(err)	
	}
	q str
}

/// Метод формирования описания для поиска и сравнения
/// !!! НЕ УДАЛЯТЬ !!!
/// s n=##class(App.MAK.Nomen).%OpenId(4792)  d n.setSpecName()
Method setSpecName()
{
	try {
		s err = ""
		k str
		s (in,out) = {}, in.data={}, in.data.log = 0
		s str = ..GetString(in, out)
		s ..SpecName = str
		q:out.error'=""
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		w err
	}
	q err
}

/// Метод открытия строки прайса по коду
/// !!! НЕ УДАЛЯТЬ !!!
ClassMethod OpenByCodeAndAgent(Code As Lib.DataTypes.String = "", AgentCode As Lib.DataTypes.String = "")
{
	s res = ""
	q:(Code="")||(AgentCode="") res
	
	k ind, ptr, id
	s filter = [
				{"field":"Code","type":"=","data":(Code)},{"oper":"AND"},
				{"field":"idAgent.Code","type":"=","data":(AgentCode)}
			   ]
	d ..Filter(.filter, .ind)
	q:..indCOUNT(.ind)=0
	while ..indNEXT(.ind, .ptr, .id) {
		s:(id'="")&&('$ISO(res)) res=..%OpenId(id)
	}	
	q res
}

}

