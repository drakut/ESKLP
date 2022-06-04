/// Связки
Class App.MAF.Link Extends (%Persistent, Lib.Abstract.StorableTables)
{

Parameter XMLTYPE = "App-MAF-Link";

Storage Default
{
<Data name="LinkDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Plan</Value>
</Value>
<Value name="3">
<Value>ClassNameLeft</Value>
</Value>
<Value name="4">
<Value>IdLeft</Value>
</Value>
<Value name="5">
<Value>ClassNameRight</Value>
</Value>
<Value name="6">
<Value>IdRight</Value>
</Value>
<Value name="7">
<Value>Linked</Value>
</Value>
<Value name="8">
<Value>Info</Value>
</Value>
<Value name="9">
<Value>NGrammValue</Value>
</Value>
<Value name="10">
<Value>MeasValue</Value>
</Value>
<Value name="11">
<Value>BarcodeValue</Value>
</Value>
<Value name="12">
<Value>CommonValue</Value>
</Value>
<Value name="13">
<Value>NGramString</Value>
</Value>
<Value name="14">
<Value>MeasString</Value>
</Value>
<Value name="15">
<Value>BarcodeString</Value>
</Value>
<Value name="16">
<Value>DictValue</Value>
</Value>
<Value name="17">
<Value>ProdNameValue</Value>
</Value>
<Value name="18">
<Value>BrandValue</Value>
</Value>
<Value name="19">
<Value>CountryValue</Value>
</Value>
<Value name="20">
<Value>LekFormValue</Value>
</Value>
<Value name="21">
<Value>GUID</Value>
</Value>
<Value name="22">
<Value>SourceSys</Value>
</Value>
<Value name="23">
<Value>Vers</Value>
</Value>
<Value name="24">
<Value>Order</Value>
</Value>
<Value name="25">
<Value>Mark</Value>
</Value>
<Value name="26">
<Value>Code</Value>
</Value>
<Value name="27">
<Value>CodeLeft</Value>
</Value>
<Value name="28">
<Value>CodeRight</Value>
</Value>
<Value name="29">
<Value>AgentLeft</Value>
</Value>
<Value name="30">
<Value>AgentCodeLeft</Value>
</Value>
<Value name="31">
<Value>AgentCodeRight</Value>
</Value>
</Data>
<DataLocation>^App.MAF.LinkD</DataLocation>
<DefaultData>LinkDefaultData</DefaultData>
<IdLocation>^App.MAF.LinkD</IdLocation>
<IndexLocation>^App.MAF.LinkI</IndexLocation>
<StreamLocation>^App.MAF.LinkS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// ВАыгрузка связок в файл. Для каждой строки прайса выбираются лучшие связи с одинаковым максимальным коэфициентом.
/// d ##class(App.MAF.Link).ExpToFile()
ClassMethod ExpToFile()
{
	try {
		s err = ""
		
		s file = ##class(%Stream.FileCharacter).%New()
		s file.Filename = "C:\Temp\fe_and_esclp_2.txt"
		
		s query = 	" SELECT code AS Code , "_
							" prc.name AS Name, "_
							" prc.nameland AS Country, "_
							" prc.namefirm AS Firm, "_
							" esclp.CodeCLP AS ESCLP_code, "_
							" esclp.specname AS ESCLP_name, "_
							" RegName AS ESCLP_regname, "_
							" CommonValue AS coeff"_
					" FROM app_prc.nomen prc"_
					" JOIN app_maf.link link ON prc.id = link.IdLeft"_
					" JOIN app_spr.esclp esclp ON esclp.id = link.IdRight"_
					" WHERE prc.idagent = 260"_
					" AND CommonValue > 89"_
					" AND commonvalue = ("_
  					" 					SELECT max(CommonValue) "_
  					" 					FROM app_maf.link link "_
  					" 					WHERE link.idLeft = prc.id "_
  					" 					)"
  		s statement	= ##class(%SQL.Statement).%New()
		s statement.%SelectMode = 1
		s status = statement.%Prepare(query)
		i status '= $$$OK {
			s err = $SYSTEM.Status.GetErrorText(status)
			q
		}
		s resultSet = statement.%Execute()
		i status '= $$$OK {
			s err = $SYSTEM.Status.GetErrorText(status)
			q
		}
		
		s line = "Код ФЭ;Наим-е ФЭ;Страна ФЭ;Наим-е фирмы ФЭ;Код ЕСКЛП;Наим-е ЕСКЛП;Наименование владельца рег-го удостоверения;Коэфициент"
		d file.WriteLine(line)
		
		while resultSet.%Next() {			
			s line = 	resultSet.%Get("Code")_";"_
						resultSet.%Get("Name")_";"_
						resultSet.%Get("Country")_";"_
						resultSet.%Get("Firm")_";"_
						resultSet.%Get("ESCLP_code")_";"_
						resultSet.%Get("ESCLP_name")_";"_
						resultSet.%Get("ESCLP_regname")_";"_
						resultSet.%Get("coeff")
			d file.WriteLine(line)
		}
		d file.%Save()
		
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
	}
	q err
}

Method GetLinkUnlinkButtonCode(in, out)
{
	s buttonCode = ""
	i ..Linked {
		s event = "UnlinkButtonClick"
		s caption = "Отвязать"
		s btnClass = "btnunlink"
	}
	else {
		s event = "LinkButtonClick"
		s caption = "Привязать"
		s btnClass = "btnlink"
	}
	
	i ..ClassNameRight= "App.CTN.Nomen" {
		s sourNom = $CLASSMETHOD(..ClassNameLeft, "%OpenId", ..IdLeft)
		s compNom = $CLASSMETHOD(..ClassNameRight, "%OpenId", ..IdRight)
		q:('$ISO(sourNom))||('$ISO(compNom))
		
		s sript =	"var formId=findForm('"_in.idComponent_"');"_
					"if ((formId)&&(aegFormsAll[formId])&&(aegFormsAll[formId].dataset)) {"_
					"	var data = {"_
										"clientProductCode : '"_sourNom.Code_			"', "_
										"feProductCode : '"_	compNom.Code_			"', "_
										"contrCode : '"_		sourNom.idAgent.Code_	"', "_
										"classNameL : '"_		..ClassNameLeft_		"', "_
										"idLeft : '"_			..IdLeft_				"', "_
										"classNameR : '"_		..ClassNameRight_		"', "_
										"idRight : '"_			..IdRight_				"', "_
										"idLink : '"_			..%Id()_				"'"_
								"};"_
					"	aegFormsAll[formId].dataset.callserver(false, 'toolbar', '"_event_"', data);"_
					"}"_
					"else {alert('Собщение о том, что чего-то не хватает !');}"
		
		s buttonCode =  "<button class="""_btnClass_""" onclick="""_sript_""">"_caption_"</button>"
	}
	else {
		s sript =	"var formId=findForm('"_in.idComponent_"');"_
					"if ((formId)&&(aegFormsAll[formId])&&(aegFormsAll[formId].dataset)) {"_
					"	var data = {"_
										"classNameL : '"_	..ClassNameLeft_	"', "_
										"idLeft : '"_		..IdLeft_			"', "_
										"classNameR :'"_	..ClassNameRight_	"', "_
										"idRight : '"_		..IdRight_			"', "_
										"idLink : '"_		..%Id()_			"'"_
									"};"_
					"	aegFormsAll[formId].dataset.callserver(false, 'toolbar', '"_event_"', data);"_
					"}"_
					"else {alert('Собщение о том, что чего-то не хватает !');}"
		
		s buttonCode =  "<button class="""_btnClass_""" onclick="""_sript_""">"_caption_"</button>"
	}
	
	q buttonCode
}

Method GetLinkInfo()
{
	s linkInfo = ""
	
	s linkInfoObj = [].%FromJSON(..Info)
	s itr = linkInfoObj.%GetIterator()
	while itr.%GetNext(.metricKey, .metricObj){
		s sourInf = metricObj.sourInf
		s candInf = metricObj.candInf
		i (metricObj.name = "N-gramm")!(metricObj.name = "Trigram")!(metricObj.name = "Translit")!(metricObj.name = "LekForm") {
			s sourInf = ""
			s candInf = ""
		}
		s linkInfo = linkInfo_
					"<div class='calcInfo'>"_
						"<div class='calcInfoHeader'>"_metricObj.name_" : "_metricObj.value_"</div>"_
						sourInf_"</br></br>"_
						candInf_
					"</div>"
	}
	
	q linkInfo
}

Method GetCandidateName()
{
	s name = ""
	
	s compNom = $CLASSMETHOD(..ClassNameRight, "%OpenId", ..IdRight)
	q:'$ISO(compNom)
	
	i ..ClassNameRight = "App.SPR.ESCLP" {
		s name = compNom.SpecName
	}
	else {
		s name = compNom.Name
	}
	
	q name
}

Method GetCandidateCode()
{
	s code = ""
	
	s compNom = $CLASSMETHOD(..ClassNameRight, "%OpenId", ..IdRight)
	q:'$ISO(compNom)
	
	i ..ClassNameRight = "App.SPR.ESCLP" {
		s code = compNom.CodeCLP
	}
	else {
		s code = compNom.Code
	}
	
	q code
}

/// d ##class(App.SPR.ESCLP).SetAllSpecName()
ClassMethod VerificateFiltered(in)
{
	try {
		s startTimeStamp = $ZTS
		
		s:'$ISOBJECT(in) in={}.%FromJSON(in)
		s processGUID	= in.jobnum 		; $System.Util.CreateGUID()	
		s in.sessionGUID= in.jobnum
			
		s filter = []
		s formFilterSize = in.filter.%Size() 									; последнее условие фильтра из формы показывают %Id() строчку таблицы в фокусе, и нам дальше не понадобятся
		s iter = in.filter.%GetIterator()
		while iter.%GetNext(.key, .value) & (key<( formFilterSize-2)) {
			d value.%Remove("add")
			d filter.%Push(value)
		}
		s extension = {"field":"Mark", "type":"=", "data":"import"}				; оставляем только импортирвоанные связи
		s out = {}
		d ##class(Lib.Util.Filter).ExtendFilter(filter, extension, out)
		q:out.error'=""
		
		s count = 0
		s recCount = 0
		k ind,ptr,id
		s err = ..Filter(filter, .ind)
		i err'="" {
			d ..SetTempParam(in.jobnum, "error", err)
			d ..SetTempParam(in.jobnum, "end", 1) 			; конец	
			throw ##class(%Exception.General).%New("<ERROR>", 999,, err)
		}
		s recCount = ..indCOUNT(.ind)
		d ..SetTempParam(in.jobnum, "allrecords", recCount)

		; Распределение вычислений между ядрами процессора =========================
		m ^CacheTempLinker(processGUID, "ind") = ind
		s CPUinfo = ##class(%SYSTEM.CPU).%New()
		s flowsCount = CPUinfo.nCores											d:in.log %log.%Push({ "Oper" : ("<b>Кол-во потоков</b>"), "Result" : (flowsCount) })
		s limitPerCore = $NORMALIZE( ((recCount / flowsCount) + 0.4), 0 )		d:in.log %log.%Push({ "Oper" : ("<b>Кол-во на 1 ядро</b>"), "Result" : (limitPerCore) })
		s ^CacheTempLinker(processGUID, "count") = recCount	
		d ..SetTempParam(processGUID, "start", $h)
		d ..SetTempParam(processGUID, "user", $USERNAME)

		s in.limitPerCore = limitPerCore										; Лимит обрабатываемых записей для каждого ядра
		s in.startPos = 1														; Стартовая запись для обработки для каждого ядра будет своя
		f coreCounter = 1:1:flowsCount {
			s in.coreNum = coreCounter											; Номер занимаего ядра передадим в джоб
			s in4Job = in.%ToJSON()												; В фоновый процесс можно передавать только без ссылки, поэтому преводим все в строку
			s ^CacheTempLinker(processGUID, "jobfinish", in.coreNum) = 0		; Обнуление флага финиша выполнения джоба
			j ..VerificatePack(in4Job)											; Запуск джоба
			s in.startPos = (limitPerCore * coreCounter) + 1					; Передвигаем стартовую позицию обработки для следующего джоба
		}
		
		; Конец распределения, начинаем следить за выполнением =====================
		s allJobsFinished = 0, jobError = ""									; Следим за финишем выполнения всех джобов
		while allJobsFinished = 0 {
			f coreNum=1:1:flowsCount {											; Перебираем флаги финиша обработки в темповой глобали
				s allJobsFinished = $G(^CacheTempLinker(processGUID,"jobfinish",coreNum))
				q:allJobsFinished=0												; Если хоть один не закончил - ждем дальше
			}
			HANG 0.01
			s err = ..GetTempParam(processGUID, "error", .jobError)				; Если есть ошибки - заканчиваем
			s err = ..GetTempParam(processGUID, "stop", .stop)
			
			i jobError'="" {
				s allJobsFinished = 1
				d:in.log %log.%Push({ "Oper" : ("<b>ОШИБКА :</b>"), "Result" : (jobError) })
			}
			s:stop=1 allJobsFinished=1
		}
		k ^CacheTempLinker
		i jobError'="" {
			d ..SetTempParam(processGUID,"end",1) 
			s out.error = jobError
			s %log = [{"Info":"Pay attention!"}] ;out.log
			q
		}
		s finishTimeStamp = $ZTS
		d ..SetTempParam(processGUID, "finish", $h)
		d ..SetTempParam(in.jobnum, "end", 1) 			; конец	
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		d ..SetTempParam(in.jobnum, "error", err)
		d ..SetTempParam(in.jobnum, "stop", 1)			; Обновить
		d ..SetTempParam(in.jobnum, "end", 1) 			; конец	
		s ^CacheTempError($I(^CacheTempError), "App.MAF.Linker", "AutoSetAnalog", "err") = err
	}
	q
}

ClassMethod VerificatePack(in)
{
	try {
		s in = {}.%FromJSON(in)		
		s ^CacheTempLinker(in.sessionGUID, "jobnum") = $J
		s err = "", out = {}, recCounter = 0
		
		k ind
		m ind = ^CacheTempLinker(in.sessionGUID, "ind")											; Забираем индекс из временной глобали
		while ..indNEXTsort( 
							.ind, 
							"", 
							1, 
							in.startPos, 
							.ptr,
							.id ) 
						&& ( recCounter < in.limitPerCore ) {
			s err = ..GetTempParam(in.jobnum, "stop", .stop)
			q:stop
	
			s link = ..%OpenId(id)
			d link.verificate()
			d ..IncTakt(in.sessionGUID)
			i $I(recCounter)
		}
		
		d:out.error'="" ..SetTempParam(in.sessionGUID, "error", err)
		s ^CacheTempLinker(in.sessionGUID, "jobfinish", in.coreNum) = 1
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		;d ..SetTempParam(in.sessionGUID, "error", err)
		s ^CacheTempError($I(^CacheTempError), "CalcCandidatesPack", "fatal") = err
		s ^CacheTempLinker(in.sessionGUID, "jobfinish", in.coreNum) = 1
	}
	q err
}

Method verificate()
{
	try {
		s err = ""
		i '$ISO(..Plan) {
			s out.error = "Не задан план"
			q
		}
		
		s nomToRecognize = $CLASSMETHOD("App.PRC.Nomen", "OpenByCodeAndAgent", ..CodeLeft, ..AgentCodeLeft)	; Открываем ресурс 
		s nomToCompare	= $CLASSMETHOD("App.PRC.Nomen", "OpenByCodeAndAgent", ..CodeRight, ..AgentCodeRight)	; Открываем аналог
		
		i '$ISO(nomToRecognize) ! '$ISO(nomToCompare) {
			s out.error = "No obj"
			q
		}
		
		s inSour = {}
		s outSour = {}
		s inSour.sourceStr	= nomToRecognize.GetString(inSour, outSour)						; Получение строки для сравнения
		s inSour.log		= 0
		s inSour.idPlan		= ..Plan.%Id()
		s inSour.sourceStr	= ##class(App.MAF.Linker).PreparePlanString(inSour, outSour)	; Очистка строки ресурса обработками плана
		q:outSour.error'=""
		d ##class(App.MAF.Linker).PrepareMetricsStrings(inSour, outSour)					; Подготовка строк ресурса для метрик
		q:outSour.error'=""
		
		
		s inComp = {}
		s outComp = {}
		s inComp.sourceStr	= nomToCompare.GetString(inComp, outComp)						; Получение строки для сравнения
		s inComp.log 		= 0
		s inComp.idPlan		= ..Plan.%Id()
		s inComp.sourceStr	= ##class(App.MAF.Linker).PreparePlanString(inComp, outComp)	; Очистка строки аналога обработками плана
		q:outComp.error'=""
		d ##class(App.MAF.Linker).PrepareMetricsStrings(inComp, outComp)					; Подготовка строк аналога для метрик
		q:outComp.error'=""
		
		
		s outCalc = {}
		s inCalc = {}
		s inCalc.prepSour = outSour.prepSour
		s inCalc.prepComp = outComp.prepSour
		s inCalc.idPlan = ..Plan.%Id()
		
		
		d ##class(App.MAF.Linker).CalcMetrics2(inCalc, outCalc)
		i outCalc.error'="" {
			w !,"Error CalcMetrics2 = ",outCalc.error
		}
		
		s ..Info = outCalc.info.%ToJSON()
		s ..CommonValue = outCalc.commonCoef
		i ..AgentCodeRight'="" {
			s ..ClassNameLeft = $CLASSNAME(nomToRecognize)
			s ..ClassNameRight =  $CLASSNAME(nomToCompare)
			s ..IdLeft = nomToRecognize.%Id()
			s ..IdRight = nomToCompare.%Id()
		}
		d ..%Save()
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		w !,"Fatal: ",err,!
	}
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
		i in.namecall="VerificateFiltered" {
			s out.refresh=1
			s out.typejob	= "job"
			s in.setAutoLink= 0 ;%session.Get("setAutoLink", 0)
			;s in.classNameR	= %session.Get("classNameR", "")
			;s in.idPlan		= %session.Get("idPlan", "")
			s in.stem		= 1 ;%session.Get("stemming", 1)
			s in.log		= 0
			s in.reCalc		= 0
			
			s inLinker		= in.%ToJSON()
			j ..VerificateFiltered(inLinker)
		}
		
		
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)} // catch
	q
}

/// d ##class(App.MAF.Link).Temp()
ClassMethod Temp()
{
	k ind, ptr, id
	s filter = [
			{
				"field": "AgentCodeLeft",
				"type": "=",
				"data": "UNISERP"
			}
			]
	s err = ..Filter(filter, .ind)
	i err'="" {
		w err
		q
	}
	while ..indNEXT(.ind, .ptr, .id){
		s link = ..%OpenId(id)
		d link.verifyByAgentAndCode()
	}
}

/// Получить вычислимое поле
Method addCalcField(ByRef in, ByRef out)
{
	// На входе :
	//		   in.form -> Имя формы
	//		in.section -> Тип секции ("findpanel" - панель поиска, "grid" - таблица, "editpanel" - панель редактирования)
	//		  in.field -> Имя поля
	//		 ..ИмяПоля -> Поле из тела записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	//		out.value -> Вычисленное значение
	// Примеры :
	//	s id=..%Id()
	//	s name=..Name			// Получить поле из Нового тела записи
	s err=""
	try {
		s out.value = ""
		i in.form = "App.MAF.Link" {
			i in.field="expNameLeft" {
					s sourObj = $CLASSMETHOD(..ClassNameLeft, "%OpenId", ..IdLeft)
					s out.value = sourObj.Name
			}
			i in.field="expNameRight" {
					s candObj = $CLASSMETHOD(..ClassNameRight, "%OpenId", ..IdRight)
					s out.value = candObj.Name
			}
		}
		
		// !!! Здесь писать свой код
		
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
		s out.value = out.error
	} // catch
	q
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

/// Контрагент левой стороны
Property AgentCodeLeft As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Контрагент правой стороны
Property AgentCodeRight As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Имя класса левой стороны связки
Property ClassNameLeft As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Имя класса правой стороны связки
Property ClassNameRight As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Код связки
Property Code As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Код левой стороны
Property CodeLeft As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Код правой стороны
Property CodeRight As Lib.DataTypes.String(IndexValue = 1, MAXLEN = 1024);

/// Общий коэфициент сходимости
Property CommonValue As Lib.DataTypes.Double(IndexValue = 1);

/// ID объекта левой стороны связки
Property IdLeft As Lib.DataTypes.Integer(IndexValue = 1);

/// ID объекта правой стороны связки
Property IdRight As Lib.DataTypes.Integer(IndexValue = 1);

/// Информация
Property Info As Lib.DataTypes.String(MAXLEN = 30000);

/// Признак установленной связи для номенклатуры и аналога
Property Linked As Lib.DataTypes.Boolean(IndexValue = 1);

/// Пометка связки верная, исправленная, неверно
Property Mark As Lib.DataTypes.String(DISPLAYLIST = ",верно,исправлено,неверно,импорт", IndexValue = 1, VALUELIST = ",right,fixed,wrong,import");

/// План (метод), по которому проводилось сравнение
Property Plan As App.MAF.Plan [ Required ];

Index AgentCodeLeft On AgentCodeLeft As Truncate(200) [ Type = bitmap ];

Index AgentCodeRight On AgentCodeRight As Truncate(200) [ Type = bitmap ];

Index ClassNameLeft On ClassNameLeft As Truncate(200) [ Type = bitmap ];

Index ClassNameRight On ClassNameRight As Truncate(200) [ Type = bitmap ];

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CodeLeft On CodeLeft As Truncate(200) [ Type = bitmap ];

Index CodeRight On CodeRight As Truncate(200) [ Type = bitmap ];

Index CommonValue On CommonValue [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index IdLeft On IdLeft [ Type = bitmap ];

Index IdRight On IdRight [ Type = bitmap ];

Index Linked On Linked [ Type = bitmap ];

Index Mark On Mark [ Type = bitmap ];

Index Plan On Plan [ Type = bitmap ];

ForeignKey fkPlan(Plan) References App.MAF.Plan();

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
		s out.continue=1, out.error=""
		// !!! Здесь писать свой код		
		
		i in.command = "import" {			; Импортируемые помечаем принудительно как "import"
			s in.source.impMark = "import"
		}
	}
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

/// d ##class(App.MAF.Link).RepairLinked()
ClassMethod RepairLinked()
{
	
	s query = 	"SELECT "_
				"		b.id As id, "_
				" 		b.IdLeft, "_
				" 		b.IdRight, "_
				" 		b.CommonValue, "_
				"		b.ClassNameRight"_
				" FROM "_
				" 		APP_MAF.Link b "_
				" INNER JOIN "_
				"			(SELECT "_
				"             		max(CommonValue) as CommonValue, "_
				"					IdRight, "_
				"					IdLeft "_
				"      		FROM  "_
				"					APP_MAF.Link  "_
				"     		WHERE CommonValue > 89  "_
				"			AND ClassNameRight = 'App.SPR.ESCLP'"_
				"     		GROUP BY IdLeft "_
				"    		) a ON a.Idleft = b.IdLeft AND a.CommonValue = b.CommonValue "_
				" WHERE  b.ClassNameRight = 'App.SPR.ESCLP'"_
				" GROUP BY b.IdLeft"
	w !,query
	
	s statement	= ##class(%SQL.Statement).%New()
	s statement.%SelectMode = 1
	s status = statement.%Prepare(query)
	i status '= $$$OK {
		w !,$SYSTEM.Status.GetErrorText(status)
		q
	}
	s resultSet = statement.%Execute()
	i status '= $$$OK {
		w !,$SYSTEM.Status.GetErrorText(status)
		q
	}
	
	s count = 0
	while resultSet.%Next() {	
		;i $i(count)
		;q:count>10		
		s id = 	resultSet.%Get("id")
		s link = ##Class(App.MAF.Link).%OpenId(id)
		
		s resObj = $CLASSMETHOD(link.ClassNameLeft, "%OpenId", link.IdLeft)
		s anObj = $CLASSMETHOD(link.ClassNameRight, "%OpenId", link.IdRight)
		s link.Linked = 1
		w link.%Save()
	}
}

/// d ##class(App.MAF.Link).RepairCodeAgent()
ClassMethod RepairCodeAgent()
{
	
	k ind, ptr, id
	s flt = [{"field":"ClassNameRight","type":"=","data":"App.SPR.ESCLP"}]
	s err = ##class(App.MAF.Link).Filter(flt, .ind)
	w !,"Count = ",##class(App.MAF.Link).indCOUNT(.ind)
	s count = 0
	q:err'=""
	while ##class(App.MAF.Link).indNEXT(.ind, .ptr, .id) {
		;i $i(count)
		;q:count>20
		
		;w !,"id = ",id
		s link = ..%OpenId(id)
		
		s resObj = $CLASSMETHOD(link.ClassNameLeft, "%OpenId", link.IdLeft)
		s anObj = $CLASSMETHOD(link.ClassNameRight, "%OpenId", link.IdRight)
		s link.CodeLeft = resObj.Code
		s link.CodeRight = anObj.CodeCLP
		s link.AgentCodeLeft = "FE"
		s link.AgentCodeRight = "ESCLP"
		
		;s link.Linked = 1
		w link.%Save()
	}
}

/// d ##class(App.MAF.Link).RepairLinkedMark()
ClassMethod RepairLinkedMark()
{
	
	k ind, ptr, id
	s flt = [{"field":"ClassNameRight","type":"=","data":"App.SPR.ESCLP"}]
	s err = ..Filter(flt, .ind)
	w !,"Count = ",..indCOUNT(.ind)
	s count = 0
	q:err'=""
	while ..indNEXT(.ind, .ptr, .id) {
		;i $i(count)
		;q:count>20
		w !,"id = ",id
		
		s link = ..%OpenId(id)
		
		k ind2, ptr2, id2
		s flt2 = [{"field":"CodeFE","type":"=","data":(link.CodeLeft)},
				{"oper":"И"},
				{"field":"CodeESCLP","type":"=","data":(link.CodeRight)}]
		s err = ##class(Test.WrongLinks).Filter(flt2, .ind2)
		w !,"err:",err
		i ##class(Test.WrongLinks).indCOUNT(.ind2)>0 {
			w !,link.CodeRight," fixed"
			s link.Linked=0,link.Mark="fixed"
			d link.%Save()
		}
	}
}

}

