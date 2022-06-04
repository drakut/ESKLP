/// Поиск и связываение классов номенклатуры
Class App.MAF.Linker Extends Lib.Abstract.VirtualTables
{

/// Наиенование
Property Name As Lib.DataTypes.String;

/// Id подобранной каталожной номенклатуры
Property Id As Lib.DataTypes.Integer;

/// Код подобранного каталожной номенклатуры
Property Code As Lib.DataTypes.String;

/// Общий коэфициент сходимости
Property CommonValue As Lib.DataTypes.Double;

/// Информация о сравнении
Property Info As Lib.DataTypes.String;

/// Код кнопки привязки/отвязки
Property LinkUnlinkButtonCode As Lib.DataTypes.String;

/// Операция (логирование)
Property Oper As Lib.DataTypes.String;

/// Результат (логирование)
Property Result As Lib.DataTypes.String;

ClassMethod SetSessionVariable(ByRef in, ByRef out)
{
	try {
		s data = in.data
		s itr = data.%GetIterator()
		while itr.%GetNext(.key, .value){
			i key = "classNameR" {
				s classDefinition	= ##class(%Dictionary.ClassDefinition).%OpenId(value)	; Проверка на пригодность класса с аналогами
				s properties		= classDefinition.Properties
				s flSpecIndexExists = 0
				f i=1:1:properties.Count(){
					s property		= properties.GetAt(i)
					s propertyName	= property.Name
					s:propertyName="SpecName" flSpecIndexExists = 1
				}
				i 'flSpecIndexExists {
					s out.error = "Нет свойства 'SpecName' в классе "_value_". Создайте поле и проиндексируйте класс или выберите другой."
					continue
				}
			}
			s %session.Data(key) = value
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s ^CacheTempError($I(^CacheTempError),"SetSessionVariable","fatal") = err
	}
	q
}

/// Вызов функции с клиента
/// 	На входе :
/// 		in.form -> Имя формы
/// 	  in.filter -> фильтр для поиска
/// 	in.typecall -> Источник вызова ("toolbar" - кнопка на панели задач и т.д.)
/// 	in.namecall -> Имя действия (Для "toolbar" - имя кнопки и т.д.)
/// 	in.actualid -> ID текущей строки в форме
/// 		in.data -> Дополнительные данные для задачи (определяются клиентом)
/// На выходе :
/// 	  out.error -> Сообщение об ошибке или пусто
/// 	out.typejob -> Метод исполнения задачи ("fast" - задача исполняется быстро, не в фоне, "job" - задача исполняется медленно, в фоне)
/// 	out.message -> Сообщение для клиента (выводится в модальном окне)
/// 	 out.jobnum -> Номер задания для фоновых задач
ClassMethod CallClient(ByRef in, ByRef out)
{
	s err=""
	try {
		d:in.namecall="LinkButtonClick" ..SetLink(.in, .out)
		d:in.namecall="UnlinkButtonClick" ..UnLink(.in, .out)
	} // try
	catch exp {
		s err=..ErrorDetect(.exp) //, out.error=err
	}
	s out.error = err
	q err
}

/// Для привязок к каталожной ном-ре:
/// 	in.clientProductCode
/// 	in.feProductCode
/// 	in.contrCode
/// 	in.classNameL
/// 	in.idLeft
/// 	in.classNameR
/// 	in.idRight
/// 		in.idLink
/// Для привязок к прочим:
/// 	in.classNameL
/// 	in.idLeft
/// 	in.classNameR
/// 	in.idRight
/// 	in.idLink
/// Сообщение об ошибке должно быть в out.message, тогда появится alert на клиенте
ClassMethod SetLink(ByRef in, ByRef out)
{
	s status = $$$OK
	try {
		s out.typejob="fast"
		s out.refresh = 1
		
		i in.classNameR = "App.CTN.Nomen" { ; с ФЭ вяжем и по SOAP
			s (inSOAP,outSOAP) = {}
			s inSOAP.codePrcRec = in.data.clientProductCode
			s inSOAP.codeCtlNomen = in.data.feProductCode
			s inSOAP.codeContr = in.data.contrCode
			d ..CallSOAPSetCtlToPrc(inSOAP, outSOAP)
			s out.message = outSOAP.error
			
			q:outSOAP.error'=""	; если в ФЭ не связалось (outSOAP.error'="") - то у себя тут ничо не вяжем!
		}
		
		k ind, ptr, id, link
		s filter =	[{"field":"%%ID", "type":"=", "data":(in.data.idLink)}]
		s err = ##class(App.MAF.Link).Filter(filter, .ind)
		i err'="" {throw ##class(%Exception.General).%New("<ERROR>", 999, , err)}
		while ##class(App.MAF.Link).indNEXT(.ind, .ptr, .id) {
			s link = ##class(App.MAF.Link).%OpenId(id)
			q:('$ISO(link))
			s link.Linked = 1
			s status = link.%Save()
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q status
}

/// Для привязок к каталожной ном-ре:
/// 	in.clientProductCode
/// 	in.feProductCode
/// 	in.contrCode
/// 	in.classNameL
/// 	in.idLeft
/// 	in.classNameR
/// 	in.idRight
/// 		in.idLink
/// Для привязок к прочим:
/// 	in.classNameL
/// 	in.idLeft
/// 	in.classNameR
/// 	in.idRight
/// 	in.idLink
ClassMethod UnLink(ByRef in, ByRef out)
{
	s status = $$$OK
	try {
		s out.typejob="fast"
		s out.refresh = 1

		i in.classNameR = "App.CTN.Nomen" { ; с ФЭ вяжем и по SOAP
			s (inSOAP,outSOAP) = {}
			s inSOAP.codePrcRec = in.data.clientProductCode
			s inSOAP.codeCtlNomen = in.data.feProductCode
			s inSOAP.codeContr = in.data.contrCode
			d ..CallSOAPDelCtlToPrc(inSOAP,outSOAP)
			s out.message = outSOAP.error ;
			
			q:outSOAP.error'=""	; если в ФЭ не связалось (outSOAP.error'="") - то у себя тут ничо не вяжем!
		}
		
		k ind, ptr, id, link
		s filter =	[{"field":"%%ID","type":"=","data":(in.data.idLink)}]
		s err = ##class(App.MAF.Link).Filter(filter, .ind)
		i err'="" {throw ##class(%Exception.General).%New("<ERROR>", 999, , err)}
		while ##class(App.MAF.Link).indNEXT(.ind, .ptr, .id) {
			s link = ##class(App.MAF.Link).%OpenId(id)
			q:('$ISO(link))
			s link.Linked = 0
			s status = link.%Save()
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q status
}

/// Cохранения связи строки прайса и катал-й ном-ры в ФЭ через SOAP
/// Вход:
/// 	in.codePrcRec		- code строки прайса
/// 	in.codeCtlNomen		- code каталожной позиции
/// 	in.codeContr		- code контрагента, от которого прайс
/// Выход:
/// 	out.error		- возможные ошибки
/// 
ClassMethod CallSOAPSetCtlToPrc(in, out)
{
	try {
		s out.error = ""
		s %objlasterror = ""
		s service = ##class(App.SOAP.FE.mapCONTRNOMlink).%New()
		d ##class(Lib.App.Setup).GetSetup("SOAPFEserver",,,.server),##class(Lib.App.Setup).GetSetup("SOAPFEport",,,.port)
		i (server="")||(port="") {
			s (err,out.error)="Отсутствуют настройки для WEB-клиента СКМТР" q
		}
		s service.Location=$replace(service.Location,"~server~",server)	// Сервер
		s service.Location=$replace(service.Location,"~port~",port)		// Порт
		s service.Timeout = 15
		s status = service.SetmapCONTRNOMlink(in.codePrcRec, in.codeCtlNomen, in.codeContr)
		i $D(%objlasterror) {
			d $System.Status.DecomposeStatus(%objlasterror,.list)
			s out.error = list(1)_$C(13,10)
			q
		}
		s out.error = status.VALUE
	}
	catch exp {
		d $System.Status.DecomposeStatus(%objlasterror,.list)
		s out.error = ..ErrorDetect(.exp)_$C(13,10)_list(1)
	}
	q out.error
}

/// Удаление связи строки прайса и катал-й ном-ры в ФЭ через SOAP
/// Вход:
/// 	in.codePrcRec		- code строки прайса
/// 	in.codeCtlNomen		- code каталожной позиции
/// 	in.codeContr		- code контрагента, от которого прайс
/// Выход:
/// 	out.error		- возможные ошибки
/// 
ClassMethod CallSOAPDelCtlToPrc(in, out)
{
	try{
		s out.error = ""
		s %objlasterror = ""
		s service = ##class(App.SOAP.FE.mapCONTRNOMlink).%New()
		d ##class(Lib.App.Setup).GetSetup("SOAPFEserver",,,.server),##class(Lib.App.Setup).GetSetup("SOAPFEport",,,.port)
		i (server="")||(port="") {
			s (err,out.error)="Отсутствуют настройки для WEB-клиента СКМТР" q
		}
		s service.Location=$replace(service.Location,"~server~",server)	// Сервер
		s service.Location=$replace(service.Location,"~port~",port)		// Порт
		s service.Timeout = 15
		s status = service.DelmapCONTRNOMlink(in.codePrcRec, in.codeCtlNomen, in.codeContr)
		i $D(%objlasterror) {
			d $System.Status.DecomposeStatus(%objlasterror,.list)
			s out.error = list(1)
			q
		}
		s out.error = status.VALUE
	}
	catch exp{
		d $System.Status.DecomposeStatus(%objlasterror,.list)
		s out.error = ..ErrorDetect(.exp)_$C(13,10)_list(1)
	}
	q out.error
}

/// Тест сохранения связи строки прайса и катал-й ном-ры в ФЭ через SOAP
/// s codePrcRec = 75777, idCtlNomen = 48918, codeContr = 189
/// w ##class(App.MAF.Linker).TestSOAPSetCtlToPrc(codePrcRec, codeCtlNomen, codeContr)
ClassMethod TestSOAPSetCtlToPrc(codePrcRec, codeCtlNomen, codeContr)
{
	s service = ##class(App.SOAP.FE.mapCONTRNOMlink).%New()
	d ##class(Lib.App.Setup).GetSetup("SOAPFEserver",,,.server),##class(Lib.App.Setup).GetSetup("SOAPFEport",,,.port)
	i (server="")||(port="") {
		s (err,out.error)="Отсутствуют настройки для WEB-клиента СКМТР" q
	}
	s service.Location=$replace(service.Location,"~server~",server)	// Сервер
	s service.Location=$replace(service.Location,"~port~",port)		// Порт
	s service.Timeout = 15
	s status = service.SetmapCONTRNOMlink(codePrcRec, codeCtlNomen,codeContr)
	i $D(%objlasterror) {
		d $System.Status.DecomposeStatus(%objlasterror,.list)  w list(1)
	}
	w !,"SOAP operation status : ",status.VALUE,!
	q ""
}

/// Тест удаления связи строки прайса и катал-й ном-ры в ФЭ через SOAP
/// s codePrcRec = 75777, idCtlNomen = 48918, codeContr = 189
/// w ##class(App.MAF.Linker).TestSOAPDelCtlToPrc(idPrcRec, idCtlNomen)
ClassMethod TestSOAPDelCtlToPrc(codePrcRec, codeCtlNomen, codeContr)
{
	s service = ##class(App.SOAP.FE.mapCONTRNOMlink).%New()
	d ##class(Lib.App.Setup).GetSetup("SOAPFEserver",,,.server),##class(Lib.App.Setup).GetSetup("SOAPFEport",,,.port)
	i (server="")||(port="") {
		s (err,out.error)="Отсутствуют настройки для WEB-клиента СКМТР" q
	}
	s service.Location=$replace(service.Location,"~server~",server)	// Сервер
	s service.Location=$replace(service.Location,"~port~",port)		// Порт
	s service.Timeout = 15
	s status = service.DelmapCONTRNOMlink(codePrcRec, codeCtlNomen,codeContr)
	i $D(%objlasterror) {
		d $System.Status.DecomposeStatus(%objlasterror,.list)  w list(1)
	}
	w !,"SOAP operation status : ",status.VALUE,!
	q ""
}

/// Рапорт об ошибке импорта в протокол ошибок импорта
ClassMethod ReportImportError(obj, errText)
{
	s status = $$$OK
	try {
		s objErr		= ##class(Lib.App.ImportError).%New()
		s objErr.Date	= $p($h, ",", 1)												; Дата события
		s objErr.Time	= $p($h, ",", 2)												; Время события
		s objErr.Error	= errText														; Ошибка
		d ##class(Lib.App.User).GetIdByName($USERNAME, .idUser)
		s objErr.User	= $case(idUser, "":"", :##class(Lib.App.User).%OpenId(idUser))	; Пользователь
		s objErr.Value	= ##class(Lib.Util.JSON).ObjToJSON(obj).%ToJSON()		; Данные объекта, на импорте которого возникла ошибка
		s status = objErr.%Save()
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err)
	}
	q status
}

ClassMethod QueryLog(in, out)
{
	try {
		s err="", row="", out.error="", out.rows=""
		i $D(%log) {
			s out.rows = %log
			s:$ISO(%log) out.cntAll = %log.%Size()
		}
	} // try
	catch exp {s err=..ErrorDetect(.exp),out.error=err}
	q err
}

/// Получить данные
/// На входе
/// 		 in.start  - > Номер записи, с которой стартую
/// 		 in.count  - > Количество записей на отдачу
/// 		  in.sort  - > Имя поля для сортировки
/// 		in.direct  - > Направление сортировки (1 - по возрастанию, -1 по убыванию)
/// 		in.fields  - > Массив полей для отдачи в виде [<ИмяПоля1>,...,<ИмяПоляM>]
/// 		in.filter  - > фильтр для поиска. См. описание метода Filter
/// На выходе
/// 		    out.error  - > Сообщение об ошибке или пусто
/// 		    out.total  - > Количество страниц
/// 		     out.page  - > Текущая страница
/// 		 out.allcount  - > Количество строк всего
/// 		  out.records  - > Количество найденных строк
/// 		     out.rows  - > Массив записей в виде :
/// 				[
/// 					...
/// 					{"id":<IdЗаписиN>, "cell":[<ЗначениеПоля1>,...,<ЗначениеПоляM>]},
/// 					...
/// 				]
ClassMethod query(ByRef in, ByRef out) As %String
{
	s err="", out.error="", out.data={}, rows=[], cntAll=0, cnt=0
	try {
		i in.form = "App.MAF.LinkerCandidates" {
			s in.idPlan			= %session.Get("idPlan", "")				
			s in.classNameR		= %session.Get("classNameR", "")
			s in.setAutoLink	= %session.Get("setAutoLink", 0)
			s in.stemming		= %session.Get("stemming", 1)
			s in.idAgent		= %session.Get("idAgent", "")
			s err = ..QueryCandidates(in, out)
			s rows = out.rows
			s cntAll = out.cntAll
		}
		i in.form = "App.MAF.LinkerLog" {
			s rows = %log
			s cntAll = %log.%Size()
		}
		
		// Код метода после комментария стандартный, не трогать
		s out.data.rows=[]
		q:'$ISO(rows)
		q:rows.%Size()<1
		
		s cnt=0
		s iterator=rows.%GetIterator() k key,value
		while iterator.%GetNext(.key,.value) {
			s cnt=cnt+1
			s objJSON={"id":(value.id)} // JSON массив с полями
			// Секции из формы
			s err=##class(Lib.App.Form).GetSectionByType(in.form,$case((in.id'="")&&(in.id=value.id),1:"editpanel",:"grid"),.section)
			// Проход по заказанным полям
			s iterator2=section.section.%GetIterator() k key2,value2
			while iterator2.%GetNext(.key2,.value2) { // Запихнуть значения полей в JSON массив
				s valProp=value.%Get(value2.field)
				d objJSON.%Set(value2.name,valProp)
			} // while iterator
			//q:cnt>=(in.count+in.start-1)
			d out.data.rows.%Push(objJSON) // Добавить JSON объект в JSON массив
		} // while iterator
		s out.data.allcount=cntAll,out.data.records=cntAll
		;s out.refresh = 0
		
	} // try
	catch exp {
		s err=..ErrorDetect(.exp),out.error=err
		s ^CacheTempError($I(^CacheTempError),"query","fatal") = err
		}
	q err
}

/// Показ кандидатов
ClassMethod QueryCandidates(in, out)
{
	try {	
		/*s ^kam($I(^kam),"in") = in.%ToJSON()*/
			
		s out.rows = [], out.cntAll = 0, err="", %log=[]
		; ===================================================================
		; Проверки перед подбором
		; ===================================================================
		i ('in.%IsDefined("idPlan")) || ('in.%IsDefined("classNameR")) || (in.idPlan = "") || (in.classNameR = "") { ; Проверка заданы ли настройки
			s err = "Не задан план сравнения и/или источник аналогов. Нажмите ""Настройки"" и укажите эти параметры."
			i in.jobnum = "" {
				d out.rows.%Push({"Name":(err)})
				d %log.%Push({ "Oper":(err)})
			}
			else {
				d ..SetTempParam(in.jobnum,"error", err)
				d ..SetTempParam(in.jobnum,"stop", 1)		; Обновить
				d ..SetTempParam(in.jobnum,"end", 1)		; конец
			}
			q
		}
		; ===========
		i (in.classNameR = "App.PRC.Nomen") && (in.idAgent = "") { ; Проверка заданы ли настройки
			s err = "Для подбора аналогов из App.PRC.Nomen необходимо выбрать контрагента из доступных к выбору."
			i in.jobnum = "" {
				d out.rows.%Push({"Name":(err)})
				d %log.%Push({ "Oper":(err)})
			}
			else {
				d ..SetTempParam(in.jobnum,"error", err)
				d ..SetTempParam(in.jobnum,"stop", 1)		; Обновить
				d ..SetTempParam(in.jobnum,"end", 1)		; конец
			}
			q
		}
		; ===========
		k key, value 
		s idMain = "", iterator = in.filter.%GetIterator()	; Получить ID основной записи из фильтра и отрыть объект, к нему будем подбирать эталоны
		while iterator.%GetNext(.key,.filterPart) {
			s:filterPart.field="id" idMain=filterPart.data
		}
		i idMain = "" {s out.error = "Должeн быть id основной записи в фильтре" return out.error}
		; ===========
		s:'in.%IsDefined("log") in.log = 1
		s:'in.%IsDefined("reCalc") in.reCalc=0
		s in.sessionGUID= $System.Util.CreateGUID()			; s in.sessionGUID = %session.Get("SessDescr_GUID")
		s in.idLeft		= idMain							; id исходного объекта
		s in.classNameL = "App.PRC.Nomen"					; Наименование класса исходного объекта
		
		; ===================================================================
		; Вычисляем или берем готовых кандидатов
		; ===================================================================
		i in.reCalc {
			k ind,ptr,id
			s flt = [
						{"field":"ClassNameLeft","type":"=","data":(in.classNameL)},
						{"oper":"AND"},
						{"field":"IdLeft","type":"=","data":(in.idLeft)},
						{"oper":"AND"},
						{"field":"ClassNameRight","type":"=","data":(in.classNameR)},
						{"oper":"AND"},
						{"field":"Mark","type":"'=","data":"import"}
					]
			s err = ##class(App.MAF.Link).Filter(.flt,.ind)
			while ##class(App.MAF.Link).indNEXT(.ind, .ptr, .id) {
				d ##class(App.MAF.Link).%DeleteId(id)
			}
		}
		d ..CalcCandidates(in, out)
		
		; ===================================================================
		; Вывод кандидатов
		; ===================================================================
		d ..GetViewCandidates(in, out)
	}
	catch exp {
		s err=..ErrorDetect(.exp), out.error=err
		s ^CacheTempError($I(^CacheTempError),"QueryCandidates","fatal") = err
	}
	q err
}

ClassMethod GetViewCandidates(in, out)
{
	try {
		i out.%IsDefined("rows"){
			s rows	=	out.rows
		}
		else {
			s rows = []
		}
		s query	=	"SELECT id "_
					" FROM App_MAF.Link "_
					" WHERE ClassNameLeft = '"_in.classNameL_"' "_
					" AND ClassNameRight = '"_in.classNameR_"' "_
					" AND IdLeft = "_in.idLeft_
					" AND Plan = "_in.idPlan_
					" ORDER BY CommonValue DESC"
		s statement	= ##class(%SQL.Statement).%New()
		s status	= statement.%Prepare(.query)
		i status'=$$$OK {
			s err = $SYSTEM.Status.GetErrorText(status)
			q
		}
		s resultSet = statement.%Execute()
		while resultSet.%Next() {
			s idLink = resultSet.%Get("id")
			s link = ##class(App.MAF.Link).%OpenId(idLink)
			
			d rows.%Push({	
							"id":					(link.%Id()),
							"Name":					(link.GetCandidateName()),
							"Id":					(link.IdRight),
							"Code":					(link.GetCandidateCode()),
							"CommonValue":			(link.CommonValue),
							"Info": 				(link.GetLinkInfo()),
							"LinkUnlinkButtonCode":	(link.GetLinkUnlinkButtonCode(in, out))
						})
		}
		s out.cntAll = resultSet.%ROWCOUNT	; !!! %ROWCOUNT заполняется после перебора результата запроса !!!
		i out.cntAll<=0 {
			d rows.%Push({ "Name": ("Аналоги не найдены или кандидатов больше 500...")})
		}
		s out.rows = rows
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		s ^CacheTempError($I(^CacheTempError),"GetViewCandidates","fatal") = err
	}
	q 1
}

/// Применение к строке обработок, привязанных к плану сравнения
/// Вход:
/// 	in.sourceStr	- строка для преобразования
/// 	in.idPlan	- id плана сравнения
/// 	in.log		- 1 / 0 : вкл/выкл логирования в ракурсе лога формы
/// Выход:
/// 	out.error		- текст ошибки
/// s out={}  s in={"log":1,"sourceStr":"Натурелла еж.прок.Calendula Single 20ш","data":{"idPlan":1}}  w ##class(App.MAF.Linker).PreparePlanString(in,out)
ClassMethod PreparePlanString(in, out) As Lib.DataTypes.String
{
	try {
		s str = in.sourceStr
		s query = 	"SELECT sp.id "_
					"FROM App_MAF.Plan plan "_
					"LEFT JOIN app_maf.planstrpat link ON plan.id = link.plan "_
					"LEFT JOIN app_maf.stringpattern sp ON link.StrPattern = sp.id "_
					"WHERE plan.id = "_in.idPlan_
					" AND link.active = 1"_
					" ORDER BY link.order"
		s statement	= ##class(%SQL.Statement).%New()
		s statement.%SelectMode = 1
		s status = statement.%Prepare(query)
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		s resultSet = statement.%Execute()
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		d:in.log %log.%Push({"Oper":"<b>Начало обработок строки, привязанных к плану:</b>","Result":""})
		while resultSet.%Next() {
			s pattern = ##class(App.MAF.StringPattern).%OpenId(resultSet.%Get("id"))
			s str = pattern.Apply(str, in.log, out)
			q:out.error'=""
	    }
	    d:in.log %log.%Push({"Oper":"<b>Финиш обработок плана:</b>","Result":(str)})
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s ^CacheTempError($I(^CacheTempError),"App.MAF.Linker","PreparePlanString","fatal") = err
		s out.error = err
	}
	q str
}

/// Подготовка параметров из исходной строки для каждой метрики плана
/// Вход:
/// 	in.sourceStr	- строка для преобразования
/// 	in.idPlan	- id плана сравнения
/// 	in.log		- 1 / 0 : вкл/выкл логирования в ракурсе лога формы
/// Выход:
/// 	out.prepSour	= {
/// 						"1" : "string-1",							- Строка string-1, полученная из sourceStr с применением паттернов метрики с id = 1, где метрика не словарная
/// 						"2" : {										- Динамический объект для словарной метрики
/// 								"idList"	: "1,2,3", 					- список id объектов словаря, значения которых совпали со словами исходной строки
/// 								"valueList"	: "знач1,знач2,знач3"		- список слов из sourceStr, совпаших с значениями словаря
/// 								"useInKeywords" : "no"					- как использовать результирующую строку метрики: no,all,shortest,longest
/// 							  }
/// 						"3" : {										- Динамический объект для другой метрики
/// 								"valueList"	: "знач1,знач2,знач3"		- строка прайса после обработок плана и метрики
/// 								"useInKeywords" : "all"					- как использовать результирующую строку метрики: no,all,shortest,longest
/// 							  }
/// 					  }	
/// 	out.error 		- ошибка, текст
ClassMethod PrepareMetricsStrings(in, out) As %Status
{
	; s out={},in={"sourceStr":"Натурелла еж.прок.Calendula Single 20ш","data":{"idPlan":"1"}}  d ##class(App.MAF.Linker).PrepareMetricsStrings(in,out)  w out.%ToJSON()  w !!,%log.%ToJSON()
	try {
		s result = {}
		s string = in.sourceStr
		s status = $$$OK
		s plan = ##class(App.MAF.Plan).%OpenId(in.idPlan)
		s query = 	"SELECT m.id, "_
					"	link.UseInKeywords As UseInKeywords, "_
					"	link.Order As Ord "_
					"FROM App_MAF.Plan plan "_
					"LEFT JOIN app_maf.PlanMetric link ON plan.id = link.plan "_
					"LEFT JOIN app_maf.Metric m ON link.Metric = m.id "_
					"WHERE plan.id = "_in.idPlan_
					" AND link.active = 1 "_
					" ORDER BY Ord"
		s statement	= ##class(%SQL.Statement).%New()
		s statement.%SelectMode = 1
		s status = statement.%Prepare(query)
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		s resultSet = statement.%Execute()
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		while resultSet.%Next() {
			s id = resultSet.%Get("id")
			s useInKeywords = resultSet.%Get("UseInKeywords")
			s metric = ##class(App.MAF.Metric).%OpenId(id)
			
			s metricStr = metric.ApplyPatterns(string, in.log, out)
			
			i metric.MethodName = "DictSimil" {					; для словарных метрик сразу посчитаем id-ы значений
				s outMetric			= {}
				s objMetricParams	= {}.%FromJSON(metric.Params)
				s inMetric			= {"str":(metricStr), "propertyId":(objMetricParams.idNomenProp)}
				d ##class(App.MAF.Metric).GetDictValIdsCaesar(inMetric, outMetric)
				s idList			= $LTS(outMetric.idList)
				s valuseList		= $LTS(outMetric.valueList)
				d:in.log %log.%Push({"Oper":"Словарные значения в строке :", "Result":(valuseList)})
				s resObj			= {"idList":(idList), "valueList":(valuseList), "useInKeywords":(useInKeywords)}
				d result.%Set(id, resObj)
			}
			elseif metric.MethodName = "AnyDictSimil" {			; для словарных метрик сразу посчитаем id-ы значений
				s outMetric			= {}
				s objMetricParams	= {}.%FromJSON(metric.Params)
				s inMetric			= {"str":(metricStr), "tableName":(objMetricParams.tableName), "propName":(objMetricParams.propName)}
				d ##class(App.MAF.Metric).GetTblValIdsCaesar(inMetric, outMetric)
				s idList			= $LTS(outMetric.idList)
				s valuseList		= $LTS(outMetric.valueList)
				d:in.log %log.%Push({"Oper":"Словарные значения в строке :", "Result":(valuseList)})
				s resObj			= {"idList":(idList), "valueList":(valuseList), "useInKeywords":(useInKeywords)}
				d result.%Set(id, resObj)
			}
			else {												; для других метрик просто преобразованныая строка
				
				; TODO сделать однообразные списки при сравнении
				;s metricStr			= $LTS($LFS(metricStr," "))
				
				s resObj			= {"valueList":(metricStr), "useInKeywords":(useInKeywords)}
				d result.%Set(id, resObj)
			}
			q:out.error'=""
	    }
	    s out.prepSour = result
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		s status = $$$ERROR(err)
		s ^CacheTempError($I(^CacheTempError),"App.MAF.Linker","PrepareMetricsStrings","fatal") = err
	}
	q status
}

/// Метод подбора лучших кандидатов многопоточный, ускорение в 4 раза по стравнению с одноопоточным
/// Вход:
/// 		in.data = {}
/// 		in.reCalc		- 1 / 0 : посчитать кандидатов заново / не выполнять пересчет
/// 		in.log			- 1 / 0 : вкл/выкл логирования в ракурсе лога формы
/// 		in.setAutoLink	- 1 / 0 : записывать в поле прайса idNomenAuto ссылку на лучшего кандидата/ не записывать 
/// 		in.classNameL 	- класс исходных строк
/// 		in.idLeft 		- id исходной строки
/// 		in.classNameR 	- класс, с которым устанавливаем связки
/// 		in.idPlan		- id плана сравнения
ClassMethod CalcCandidates(in, out)
{
	try {
		s startTimeStamp = $ZTS
		s processGUID = in.sessionGUID
		s err = ""
		
		s nomToRecognize = $CLASSMETHOD(in.classNameL, "%OpenId", in.idLeft)	; Получение строки для сравнения
		s ^CacheTempLinker(processGUID, "current sourse id") = in.idLeft
		i '$ISO(nomToRecognize){
			d:in.log %log.%Push({ "Oper" : ("<b>Error:</b>"), "Result" : "Строки для распознавания уже не существует в базе данных потому что, скорее всего, уже был удален. Обновите экран." })
			q
		}
		
		s strToRecognize = nomToRecognize.GetString(in, out)
		q:out.error'="" 
		s in.sourceStr = strToRecognize
		
		s in.sourceStr = ..PreparePlanString(in, out)	; Очистка строки обработками плана
		q:out.error'=""
		
		d ..PrepareMetricsStrings(in, out)				; Подготовка строк для метрик
		s in.prepSour = out.prepSour
		q:out.error'=""
		
		s in.stem = 1 									; Выделение ключевых слов и стемминг
		d ..GetStemKeywordList(in, out)
		q:(out.error'="")!($LL(out.keywordList)<1)
		
		k indRepres										; Получение представительной выборки для сравнения с исходной строкой
		s in.keywordList = out.keywordList
		d ..GetRepresInd(in, out, .indRepres)
		
		i (out.error'="")!(out.count=0)!(out.count>500)!(in.reCalc=0){
			s finishTimeStamp = $ZTS
			s time = ##class(Lib.Util.DateTime).DeltaMS(startTimeStamp,finishTimeStamp)
			d:in.log %log.%Push({ "Oper" : ("<b>Время без обсчета кандидатов:</b>"), "Result" : (time) })
			d:in.log %log.%Push({ "Oper" : ("<b>Error:</b>"), "Result" : (out.error) })
			q
		}
		
		; Распределение вычислений между ядрами процессора =========================
		m ^CacheTempLinker(processGUID, "ind") = indRepres						; Мержим индекс в темповую глобаль для использования в джобе
		s CPUinfo = ##class(%SYSTEM.CPU).%New()
		s flowsCount = CPUinfo.nCores											d:in.log %log.%Push({ "Oper" : ("<b>Кол-во потоков</b>"), "Result" : (flowsCount) })
		s limitPerCore = $NORMALIZE( ((out.count / flowsCount) + 0.4), 0 )		d:in.log %log.%Push({ "Oper" : ("<b>Кол-во на 1 ядро</b>"), "Result" : (limitPerCore) })
		s ^CacheTempLinker(processGUID, "count") = out.count	
		d ..SetTempParam(processGUID, "start", $h)
		d ..SetTempParam(processGUID, "user", $USERNAME)
		s out.jobnum = processGUID
		s out.typejob = "job"
		s in.limitPerCore = limitPerCore										; Лимит обрабатываемых записей для каждого ядра
		s in.startPos = 1														; Стартовая запись для обработки для каждого ядра будет своя
		f coreCounter = 1:1:flowsCount {
			s in.coreNum = coreCounter											; Номер занимаего ядра передадим в джоб
			s in4Job = in.%ToJSON()												; В фоновый процесс можно передавать только без ссылки, поэтому преводим все в строку
			s ^CacheTempLinker(processGUID, "jobfinish", in.coreNum) = 0						; Обнуление флага финиша выполнения джоба
			j ..CalcCandidatesPack(in4Job)										; Запуск джоба
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
		i jobError'="" {
			d ..SetTempParam(processGUID,"end",1) 
			s out.error = jobError
			s %log = [{"Info":"Pay attention!"}] ;out.log
			q
		}
		s finishTimeStamp = $ZTS
		
		; Если включена автораспознавание - назначаем связкам =======================
		i in.setAutoLink {
			; TODO
		}
		
		
		;k ^CacheTempLinker(processGUID)
		s time = ##class(Lib.Util.DateTime).DeltaMS(startTimeStamp,finishTimeStamp)
		d:in.log %log.%Push({ "Oper" : ("<b>Время:</b>"), "Result" : (time) })
	}
	catch exp {
		s err = ..ErrorDetect(.exp), out.error = err
		;d ..SetTempParam(processGUID, "error", err)  
		;d ..SetTempParam(processGUID, "end", 1) 
		s ^CacheTempError($I(^CacheTempError),"CalcCandidates","fatal") = err
	}
	q err
}

ClassMethod SetAnalog(in, out)
{
	try {
		s plan = ##class(App.MAF.Plan).%OpenId(in.idPlan)
			s query	=	"SELECT id "_
						" FROM App_MAF.Link "_
						" WHERE ClassNameLeft = '"_in.classNameL_"' "_
						" AND ClassNameRight = '"_in.classNameR_"' "_
						" AND IdLeft = "_in.idLeft_
						" AND Plan = "_in.idPlan_
						" AND CommonValue >= "_plan.MinCoef_
						" ORDER BY CommonValue DESC"
			s statement	= ##class(%SQL.Statement).%New()
			s status	= statement.%Prepare(.query)
			i status'=$$$OK {
				s err = $SYSTEM.Status.GetErrorText(status)
				q
			}
			s resultSet = statement.%Execute()
			
			while resultSet.%Next() {
				s idLink = resultSet.%Get("id")
				s link = ##class(App.MAF.Link).%OpenId(idLink)
				s link.Linked = 1
				d link.%Save()
			}
	}
	catch exp{
		s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q
}

ClassMethod CalcCandidatesPack(in)
{
	try {
		s in = {}.%FromJSON(in)		
		s ^CacheTempLinker(in.sessionGUID,"jobnum") = $J
		s err = "", out = {}, recCounter = 0
		
		k ind
		m ind = ^CacheTempLinker(in.sessionGUID,"ind")											; Забираем индекс из временной глобали
		while $CLASSMETHOD( in.classNameR,
							"indNEXTsort", 
							.ind, 
							"", 
							1, 
							in.startPos, 
							.ptr,
							.id ) 
						&& ( recCounter < in.limitPerCore ) {
			s err = ..GetTempParam(in.jobnum, "stop", .stop)
			q:stop
			s nomToCompare = $CLASSMETHOD(in.classNameR, "%OpenId", id)
			
			s compareStr = nomToCompare.SpecName											; Конкатенация свойств номенклатуры в строку в соответствии с настройками метрики
			s:compareStr="" compareStr = nomToCompare.GetString() 
			
			s compareStrSour = compareStr
			s in.idRight = id
			
			i in.classNameR = "App.CTN.Nomen" {
				s nomWasProcessed = 0
				k indFirm, ptrFirm, idFirm													; У одной каталожной позиции можеть быть несколько стран и EAN- расхлопываем их в несколько каталожных позиций
				s filterFirm = [{"field":"idNomen","type":"=","data":(id)}]					; А может быть ни одного такого свойства, тогда сравнение проведем без учета свойств
				s err = ##class(App.CTN.NomenVolFirm).Filter(filterFirm, .indFirm)
				i err'="" {throw ##class(%Exception.General).%New("<ERROR>", 999,, err)}
				while ##class(App.CTN.NomenVolFirm).indNEXT(.indFirm, .ptrFirm, .idFirm){
					s err = ..GetTempParam(in.jobnum, "stop", .stop)
					q:stop
					
					s objVal = ##class(App.CTN.NomenVolFirm).%OpenId(idFirm)
					s prop = objVal.idProp
					s value = ""
					s:(prop.Code=1) value = objVal.VolHand_" "_
											objVal.idFirm.ShName_" "_ ;objVal.idFirm.Name_" "_											
											objVal.idFirm.idLand.Name						; по свойству EAN возмем страну и фирму и ЗШК
					s:(value="")&&(prop.Code=4) value = objVal.idFirm.ShName_" "_ ;objVal.idFirm.Name_" "_														
														objVal.idFirm.idLand.Name			; если такого свойства не нашлось - возмем страну и фирму
					
					s compareStr = compareStrSour_" "_value
					
					s in.compareStr = compareStr
					s status = ..CalcMetrics(in, out)
					s nomWasProcessed = 1
					q:out.error'=""
				}
				i 'nomWasProcessed {
					s in.compareStr = compareStr
					s status = ..CalcMetrics(in, out)
					q:out.error'=""
				}
				;s ^kam($I(^kam),"compareStr")=compareStr
			}
			else {
				s in.compareStr = compareStr
				s status = ..CalcMetrics(in, out)
				q:out.error'=""
			}
			
			i $I(recCounter)
		}
		
		d:out.error'="" ..SetTempParam(in.sessionGUID, "error", err)
		s ^CacheTempLinker(in.sessionGUID,"jobfinish", in.coreNum) = 1
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		;d ..SetTempParam(in.sessionGUID, "error", err)
		s ^CacheTempError($I(^CacheTempError),"CalcCandidatesPack","fatal") = err
		s ^CacheTempLinker(in.sessionGUID,"jobfinish", in.coreNum) = 1
	}
	q err
}

/// Вычислениме метрик согласно плану
/// Вход:
/// 	in.sourceStr	- 	исходная строка
/// 	in.compareStr	-	строка кандидата
/// 	in.data			=	{
/// 							"idPlan" : 1									-	id плана сравнения
/// 							"log"	 : 1									-	1 / 0 : вкл/выкл логирования в ракурсе лога формы
/// 						}
/// 	in.prepSourStr	=	{													- динамический объект, не массив, а объект
/// 							"1" : "string-1",								- строка, полученная из sourceStr с применением паттернов метрики с id = 1
/// 							"2" : {											- когда метрика словарная
/// 									"idList"	: "1,2,3", 						- список id объектов словаря, значения которых совпали со словами исходной строки
/// 									"valueList"	: "знач1,знач2,знач3"			- список слов из sourceStr, совпаших с значениями словаря
/// 									"useInKeywords" : "no"						- как использовать результирующую строку метрики: no,all,shortest,longest
/// 								  }					
/// 							"3" : {				
/// 									"valueList"	: "знач1"					- строка, полученная путем вычислений паттернов метрики с id = 3 
/// 									"useInKeywords" : "no"					- как использовать результирующую строку метрики: no,all,shortest,longest
/// 								  }
/// 						} 
/// Выход:
/// 	out.coeff		=	{
/// 							1 : 0.568,			- коэфициент метрики с id = 1
/// 							2 : 0.994			- коэфициент метрики с id = 2
/// 						}
/// 	out.prepCompStr	=	{
/// 							1 : "string-3",		- строка, полученная из compareStr с применением паттернов метрики с id = 1
/// 							2 : "string-4"		- строка, полученная из compareStr с применением паттернов метрики с id = 2
/// 						}
ClassMethod CalcMetrics(in, out)
{
	try {
		s (coeff, compStr) = {}
		s status = $$$OK
		s summ = 0
		s commonCoef = 0
		s in.log = 0
		
		s plan = ##class(App.MAF.Plan).%OpenId(in.idPlan)
		s query = 	"SELECT m.id, "_
					"	link.Weight AS w, "_
					"	link.Strong AS strong, "_
					"	link.Order As Ord "_
					"FROM App_MAF.Plan plan "_
					"LEFT JOIN app_maf.PlanMetric link ON plan.id = link.plan "_
					"LEFT JOIN app_maf.Metric m ON link.Metric = m.id "_
					"WHERE plan.id = "_in.idPlan_
					" AND link.active = 1 "_
					" ORDER BY Ord "
		s statement	= ##class(%SQL.Statement).%New()
		s statement.%SelectMode = 1
		s status = statement.%Prepare(query)
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		s resultSet = statement.%Execute()
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		
		s linkInfo = []
		s metricValue = -1
		s (sourInf,candInf) = ""
		s metricCount = 0
		s strong = 0
		while resultSet.%Next() {
			s id = resultSet.%Get("id")
			s weight = resultSet.%Get("w")
			s strong = resultSet.%Get("strong")
			s metric = ##class(App.MAF.Metric).%OpenId(id)
			s prepCompStr = metric.ApplyPatterns(in.compareStr, in.log, out)
			
			s prepSour = in.prepSour.%Get(id)
			
			s metricValue = $CLASSMETHOD("App.MAF.Metric", metric.MethodName, prepSour, prepCompStr, metric.Params, out)
			d coeff.%Set(id, metricValue)
			d compStr.%Set(id, prepCompStr)
			
			;s:(strong)&&(metricValue<0) metricValue = 0
			
			;i metricValue>=0 ! strong {					; считаем метрику, только если её значение больше нуля или если метрика со строгим сравнением
				s summ = summ + (metricValue*100 * weight)	; строгое сравнение - когда даёт ноль, даже если во второй строке пусто
			;	s metricCount = metricCount + 1
			;}
			
			; Информация о сравнении ==============================================================
			i (metric.MethodName = "DictSimil") !( metric.MethodName = "AnyDictSimil") {
				s sourInf = prepSour.valueList
				s candInf = out.valueList2
			}
			else {
				s sourInf = prepSour.valueList
				s candInf = prepCompStr
			}
			s metricInfo = {}
			d metricInfo.%Set("name", metric.Name)
			d metricInfo.%Set("value", metricValue)
			d metricInfo.%Set("sourInf", sourInf)
			d metricInfo.%Set("candInf", candInf)
			d linkInfo.%Push(metricInfo)
	    }
	    
		;s metricCount = resultSet.%ROWCOUNT 	; Kalinin 11.02.2020 : закоментироано, потому что не сработавшие метрики не должны ухудшать общую картину
		;s commonCoef = $NORMALIZE( ( summ / metricCount  ) * 100, 2)
		s commonCoef = $NORMALIZE( ( summ + plan.Intercept  ), 2)
		
		s link					= ##class(App.MAF.Link).%New()
		s link.Plan				= plan
		s link.ClassNameLeft	= in.classNameL
		s link.IdLeft			= in.idLeft
		s link.ClassNameRight	= in.classNameR
		s link.IdRight			= in.idRight
		s link.Linked			= 0 ;----------------------------
		s link.Info				= linkInfo.%ToJSON()
		s link.CommonValue		= commonCoef
		s status 				= link.%Save()
		i $$$ISERR(status) {
			s ^CacheTempError($I(^CacheTempError),"err saving link","fatal") = $SYSTEM.Status.GetErrorText(status)
		}
	}
	catch exp {
		s err =  ..ErrorDetect(.exp)
		s out.error = err
		s status = $$$ERROR(err)
		s ^CacheTempError($I(^CacheTempError),"CalcMetrics","fatal") = err
	}
	q status
}

/// Вычислениме метрик согласно плану
/// Вход:
/// 	in.sourceStr	- 	исходная строка
/// 	in.compareStr	-	строка кандидата
/// 	in.idPlan		-	id плана сравнения
/// 	in.log			-	1 / 0 : вкл/выкл логирования в ракурсе лога формы
/// 						}
/// 	in.prepSour	=	{													- динамический объект, не массив, а объект
/// 							"1" : "string-1",								- строка, полученная из sourceStr с применением паттернов метрики с id = 1
/// 							"2" : {											- когда метрика словарная
/// 									"idList"	: "1,2,3", 						- список id объектов словаря, значения которых совпали со словами исходной строки
/// 									"valueList"	: "знач1,знач2,знач3"			- список слов из sourceStr, совпаших с значениями словаря
/// 									"useInKeywords" : "no"						- как использовать результирующую строку метрики: no,all,shortest,longest
/// 								  }					
/// 							"3" : {				
/// 									"valueList"	: "знач1"					- строка, полученная путем вычислений паттернов метрики с id = 3 
/// 									"useInKeywords" : "no"					- как использовать результирующую строку метрики: no,all,shortest,longest
/// 								  }
/// 						} 
/// 	in.prepComp	=	{} --------------------------------------------------- аналогично in.prepSourStr
/// Выход:
/// 	out.info	=	[{
/// 						"name"		: "Simula"
/// 						"sourInf"	: prepSour.valueList, 		- список id объектов словаря, значения которых совпали со словами исходной строки
/// 						"candInf"	: prepComp.valueList,		- список слов из sourceStr, совпаших с значениями словаря
/// 						"value" 	:
/// 					}]
ClassMethod CalcMetrics2(in, out)
{
	try {
		s (coeff, compStr) = {}
		s status = $$$OK
		s summ = 0
		s commonCoef = 0
		s in.log = 0
		
		s plan = ##class(App.MAF.Plan).%OpenId(in.idPlan)
		s query = 	"SELECT m.id, "_
					"	link.Weight AS w, "_
					"	link.Strong AS strong, "_
					"	link.Order As Ord "_
					"FROM App_MAF.Plan plan "_
					"LEFT JOIN app_maf.PlanMetric link ON plan.id = link.plan "_
					"LEFT JOIN app_maf.Metric m ON link.Metric = m.id "_
					"WHERE plan.id = "_in.idPlan_
					" AND link.active = 1 "_
					" ORDER BY Ord "
		s statement	= ##class(%SQL.Statement).%New()
		s statement.%SelectMode = 1
		s status = statement.%Prepare(query)
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		s resultSet = statement.%Execute()
		i status '= $$$OK {
			s out.error = $SYSTEM.Status.GetErrorText(status)
			q
		}
		
		s linkInfo = []
		s metricValue = -1
		s metricCount = 0
		s strong = 0
		while resultSet.%Next() {
			s id = resultSet.%Get("id")
			s weight = resultSet.%Get("w")
			s strong = resultSet.%Get("strong")
			s metric = ##class(App.MAF.Metric).%OpenId(id)
			
			s prepSour = in.prepSour.%Get(id)
			s prepComp = in.prepComp.%Get(id)
			s metricValue = $CLASSMETHOD("App.MAF.Metric", metric.MethodName, prepSour, prepComp, metric.Params, out)
			;s:(strong)&&(metricValue<0) metricValue = 0
			;i metricValue>=0 ! strong {												; считаем метрику, только если её значение больше нули или если метрика со строгим сравнением
				s summ = summ + (metricValue * weight)		; строгое сравнение - когда даёт ноль, даже если во второй строке пусто
				s metricCount = metricCount + 1
			;}
			
			s metricInfo = {}
			d metricInfo.%Set("name", metric.Name)
			d metricInfo.%Set("value", metricValue)
			d metricInfo.%Set("sourInf", prepSour.valueList)
			d metricInfo.%Set("candInf", prepComp.valueList)
			d linkInfo.%Push(metricInfo)
	    }
		;s metricCount = resultSet.%ROWCOUNT 	; Kalinin 11.02.2020 : закоментироано, потому что не сработавшие метрики не должны ухудшать общую картину
		s commonCoef = $NORMALIZE( ( summ / metricCount  ) * 100, 2)
		
		/*
		s link					= ##class(App.MAF.Link).%New()
		s link.Plan				= plan
		s link.ClassNameLeft	= in.classNameL
		s link.IdLeft			= in.idLeft
		s link.ClassNameRight	= in.classNameR
		s link.IdRight			= in.idRight
		s link.Linked			= 0 ;----------------------------
		s link.Info				= linkInfo.%ToJSON()
		s link.CommonValue		= commonCoef
		s status 				= link.%Save()
		i $$$ISERR(status) {
			s ^CacheTempError($I(^CacheTempError),"err saving link","fatal") = $SYSTEM.Status.GetErrorText(status)
		}
		*/
		
		s out.info = linkInfo
		s out.commonCoef = commonCoef
	}
	catch exp {
		s err =  ..ErrorDetect(.exp)
		s out.error = err
		s status = $$$ERROR(err)
		s ^CacheTempError($I(^CacheTempError),"CalcMetrics","fatal") = err
	}
	q status
}

/// Стемминг слова
/// w ##class(App.MAF.Linker).Stemming("прекрасный")
ClassMethod Stemming(word)
{
	s res = word
	s twoSymbolEndWordsList = $LB("ый","ий", "ые","ие", "ая","яя", "ое","ее","ой", "ым","ом","ам")
	;s oneSymbolEndWordsList = $LB("а","я", "о","е", "ы","и")
	s oneSymbolEndWordsList = $LB("а","я", "е", "ы","и", "у")
	
	s twoSymbolEndWord=$e(word,($l(word)-1),$l(word))		; последние ДВА символа текущего слова
	;w !,"twoSymbolEndWord = ",twoSymbolEndWord
	i $LF(twoSymbolEndWordsList,twoSymbolEndWord)>0 {
		s res = $e(word, 1, ($l(word)-2))
		q res
	}
	
	s oneSymbolEndWord=$e(word,$l(word),$l(word))			; последний ОДИН символ текущего слова
	;w !,"oneSymbolEndWord = ",oneSymbolEndWord
	i $LF(oneSymbolEndWordsList,oneSymbolEndWord)>0 {
		s res = $e(word, 1, $l(word)-1)
		q res
	}
	q res
}

/// Метод получения списка $LB ключевых слов из строки. За ключевое слово принимается любое, состоящее из 3 и более символов. Повторы слов пропускаются
/// Вход:
/// 	in.stem			- флаг, нужно ли проводить стемминг слов
/// 	in.sourceStr 	- исходная строка
/// 	in."prepSour":	{	- дин. объект, подготовленные строки для метрик
/// 						"2": "125 125 100",
/// 						"3": "",
/// 						"8": "l-тироксин берлин-хеми таблетки мкг блистер n германия berlin-chemie ag",
/// 						"12" : {									- когда метрика словарная
/// 								"idList"	: "1,2,3", 				- список id объектов словаря, значения которых совпали со словами исходной строки
/// 								"valueList"	: "знач1,знач2,знач3"	- список слов из sourceStr, совпаших с значениями словаря
/// 								"useInKeywords" : "no"				- как использовать результирующую строку метрики: no,all,shortest,longest
/// 							  }	
/// 						"12" : {									- когда метрика обычная
/// 								"idList"	: "1,2,3", 				- список id объектов словаря, значения которых совпали со словами исходной строки
/// 								"valueList"	: "знач1,знач2,знач3"	- список слов из sourceStr, совпаших с значениями словаря
/// 								"useInKeywords" : "no"				- как использовать результирующую строку метрики: no,all,shortest,longest
/// 							  }	
/// 					}
/// Выход:
/// 	out.keywordList	- $LB("keyword1","keyword2")
/// 
/// s str = "вс весна гель для умыв дегтярный мл весна весна", out={}, in={}, in.sourceString=str, in.stem=1
/// d ##class(App.MAF.Linker).GetStemKeywordList(in,out) zw out.keywordList
ClassMethod GetStemKeywordList(in, out)
{
	try {
		s result = "", out.keywordList = "", status = $$$OK
		s:'in.%IsDefined("stem")!(in.stem="") in.stem=0
		
		i in.%IsDefined("prepSour") {	; Если есть метрики плана, результат которых можно использовать для ключевых слов
			s prepSour = in.prepSour
			s itr = prepSour.%GetIterator()
			while itr.%GetNext(.key , .obj ) {
				s str = ""
				s valueList = $LFS(obj.valueList)
				
				i obj.useInKeywords = "shortest" {
					s str = $LG(valueList,1)
					f i=1:1:$LL(valueList){
						s valueListWord = $LG(valueList,i)
						s:$L(str)>$L(valueListWord) str = valueListWord
					}
					s:in.stem str=..Stemming(str)
					s:(str'="")&&('$LF(result,str)) $LI(result,*+1)=str
				}
				elseif obj.useInKeywords = "longest" {
					s str = $LG(valueList,1)
					f i=1:1:$LL(valueList){
						s valueListWord = $LG(valueList,i)
						s:$L(str)<$L(valueListWord) str = valueListWord
					}
					s:in.stem str=..Stemming(str)
					s:(str'="")&&('$LF(result,str)) $LI(result,*+1)=str
				}
				elseif obj.useInKeywords = "all" {
					i in.stem {
						f i=1:1:$LL(valueList){
							s valueListWord = $LG(valueList,i)
							s valueListWord=..Stemming(valueListWord)
							s $LI(valueList,i) = valueListWord
						}
					}
					s result = result_valueList
				}
			}
		}
		i ('in.%IsDefined("prepSour")) || (result = ""){
			f i=1:1:$L(in.sourceStr," ") {
				s word = $P(in.sourceStr, " ", i)
				s:in.stem word=..Stemming(word)
				continue:$L(word)<3
				s:('$LF(result,word)) $LI(result,*+1)=word
			}
		}		
		s out.keywordList = result
		d:in.log %log.%Push(  {"Oper": "<b>Ключевые слова для поиска : </b>", "Result":( $LTS(out.keywordList,",") )}  )
	}
	catch exp {
		s err =..ErrorDetect(.exp)
		s out.error = err
		s ^CacheTempError($I(^CacheTempError),"GetStemKeywordList","fatal") = err
	}
	q status
}

/// Метод генерации фильтра для получения представительной выборки
/// Вход:
/// 	in.keywordList 			- список $LB() ключевых слов
/// 	in.skipCountEndWords	- сколько слов от конца пропускать
/// Выход:
/// 	out.filter					- фильтр
/// 
/// s (out,in)={}, in.keywordList=$LB("раз","два","три")
/// d ##class(App.MAF.Linker).GetFilter(in,out)  w out.filter.%ToJSON()
/// 
ClassMethod GetFilter(in, out)
{
	s ^kam($I(^kam),"GetFilter","in")=in.classNameR
	try{
		s filter = []
		f i=1:1:($LL(in.keywordList) - in.skipCountEndWords){
			s word = $LG(in.keywordList, i)
			continue:($L(word)<3)&&('$ISVALIDNUM(word)) ; пропускаем только слова короче 3х символов, числа оставляем
			s condition = {"field":"SpecName", "type":"содержит", "data":(word)}
			s err = ##class(Lib.Util.Filter).ExtendFilter(filter, condition, out)
		}
		i in.classNameR="App.PRC.Nomen" {
			s condition = {"field":"idAgent", "type":"=", "data":(in.idAgent)}
			s err = ##class(Lib.Util.Filter).ExtendFilter(filter, condition, out)
		}
		
		s out.filter = filter
	}
	catch exp {
		s out.error = ..ErrorDetect(.exp)
	}
	q filter
}

/// Метод получения индекса представительной выборки из эталонных номенклатур для сравнения с исходной строкой прайса.
/// Алгоритм:
/// 	1. Если задан штриход, то искать эталоны по нему, остальные способы не выполняются если найден. 
/// 	2. Если по штрихкоду не найдено - то поиск по ключевым словам. 
/// 	3. Если по ключевым не нашлось - то поиск по первому слову из списка ключевых слов
/// Первая стади с поиском по штрихкоду сделана для ускорения поиска аналогов для позиций с штрихкодом
/// Вход:
/// 	in.keywordList		- список ключевых слов
/// 	in.classNameR		- класс данных с которыми связывать
/// Выход:
/// 		out.error		- ошибки
/// 		ind				- индекс
ClassMethod GetRepresInd(in, out, ByRef ind)
{
	s status = $$$OK
	try {
		k ind
		s count = 0
		s filter = []
		s skipCountEndWords = 0
		d {
			s in.skipCountEndWords = skipCountEndWords
			s filter = ..GetFilter(in, out)
			i $I(skipCountEndWords)
			k ind
			s err = $CLASSMETHOD(in.classNameR, "Filter", filter, .ind)
			i err'="" {throw ##class(%Exception.General).%New("<ERROR>", 999,, err)}
			s count = $CLASSMETHOD(in.classNameR, "indCOUNT", .ind)
		} while (count=0)&&(skipCountEndWords<$LL(in.keywordList))
		s out.count = count
		q:out.error'=""
		d:in.classNameR="App.MAK.Nomen" ##class(Lib.Util.Filter).ExtendFilter(filter,{"field":"Act", "type":"=", "data":"1"},.out)
		
		d:(in.log)&(out.%IsDefined("filter")) %log.%Push({"Oper":"<b>Фильтр : </b>", "Result":( filter.%ToJSON() )})
		d:in.log %log.%Push({"Oper": "<b>Количество кандидатов : </b>", "Result":(count) })
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		s ^CacheTempError($I(^CacheTempError),"GetRepresInd","fatal") = err
	}
	q status
}

/// Метод удаления из строки дубликатов слов
ClassMethod DeleteDublicateWords(string)
{
	; w ##class(App.MAF.Linker).DeleteDublicateWords("рецепты бабушки агафьи маска бабушки 150+25% питание д/ломких бабушки ")
	s newWordList = ""
	s wordList = $LFS(string, " ")
	f i=1:1:$LL(wordList){
		s word = $LI(wordList, i)
		s:'$LF(newWordList, word) $LI(newWordList, *+1)=word
	}
	s newString = $LTS(newWordList, " ")
	q newString
}

ClassMethod ReCalc(in, out)
{
	try {
		s:'$ISO(in) in={}.%FromJSON(in)
		s idMain = ""
		s formFilterSize = in.filter.%Size()
		s itr = in.filter.%GetIterator()
		while itr.%GetNext(.key, .filterPart) {
			s:filterPart.field="%%ID" idMain= filterPart.data
		}
		q:idMain=""
	
		s filter = [{"field":"id", "type":"=", "data":(idMain)}]
		s in.filter = [{"field": "id", "type": "=",	"data": (idMain)}]
		s out2 = {} ; если подать входной out - то в методе CalcCandidates out.typejob=job, и зависнет всплывающее окно на клиенте
		d ..QueryCandidates(in, out2)
		s out.error = out2.error
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		s ^CacheTempError($I(^CacheTempError), "App.MAF.Linker", "ReCalc", "err") = err
	}
	q
}

ClassMethod AutoSetAnalog(in)
{
	try {
		s:'$ISO(in) in={}.%FromJSON(in)		
		s filter = []
		s formFilterSize = in.filter.%Size() ; последние 2 предиката фильтра из формы показывают %Id() строчку таблицы в фокусе, и нам дальше не понадобятся
		s iter = in.filter.%GetIterator()
		while iter.%GetNext(.key, .value) & (key<( formFilterSize-2)) {
			d filter.%Push(value)
		}
		i filter.%Size() = 0 {
			s err = "Примените фильтр, чтобы в обработку попала только нужная часть данных."
			d ..SetTempParam(in.jobnum, "error", err)
			d ..SetTempParam(in.jobnum, "end", 1)
			throw ##class(%Exception.General).%New("<ERROR>", 999,, err)
		}
		
		
		s count = 0
		s recCount = 0
		k ind,ptr,id
		s err = $CLASSMETHOD("App.PRC.Nomen", "Filter", filter, .ind)
		i err'="" {
			d ..SetTempParam(in.jobnum, "error", err)
			d ..SetTempParam(in.jobnum, "end", 1) 			; конец	
			throw ##class(%Exception.General).%New("<ERROR>", 999,, err)
		}
		s recCount = $CLASSMETHOD("App.PRC.Nomen", "indCOUNT", .ind)
		d ..SetTempParam(in.jobnum, "allrecords", recCount)
		
		while $CLASSMETHOD("App.PRC.Nomen", "indNEXT", .ind, .ptr, .id){	
			s err = ..GetTempParam(in.jobnum, "stop", .stop)
			q:stop
			s out = {}
			i $I(count)
			d ..SetTempParam(in.jobnum, "taktrecords", count)
			s in.filter= [{"field":"id", "type":"=", "data":(id)}]
			d ..QueryCandidates(in, out)
		}
		s ^kam($I(^kam),"finish") = $ZTS
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

/// D ##class(App.MAF.Linker).DelAgentNomsAndLinks({})
ClassMethod DelAgentNomsAndLinks(in)
{
	s:'$ISO(in) in={}.%FromJSON(in)
	try {		
		s filter = []
		s formFilterSize = in.filter.%Size() ; последние 2 предиката фильтра из формы показывают %Id() строчку таблицы в фокусе, и нам дальше не понадобятся
		s iter = in.filter.%GetIterator()
		while iter.%GetNext(.key , .filterPart) & (key<( formFilterSize-2)) {
			d:filterPart.field["idAgent" filter.%Push(filterPart)
		}
		i filter.%Size()=0 {
			d ..SetTempParam(in.jobnum, "error", "Не задан контрагент в фильтре")
			d ..SetTempParam(in.jobnum, "end", 1) 			; конец	
		}
		s idList = ""
		s count = 0
		s recCount = 0
		s className = "App.PRC.Nomen"
		k ind, ptr, id
		s err = $CLASSMETHOD("App.PRC.Nomen", "Filter", filter, .ind)
		i err'="" {
			d ..SetTempParam(in.jobnum,"error",err)
			d ..SetTempParam(in.jobnum,"end",1) 			; конец	
			throw ##class(%Exception.General).%New("<ERROR>", 999,, err)
		}
		s recCount = $CLASSMETHOD(className, "indCOUNT", .ind)
		d ..SetTempParam(in.jobnum, "allrecords", recCount)
		
		while $CLASSMETHOD(className, "indNEXT", .ind, .ptr, .id){	
			s err = ..GetTempParam(in.jobnum, "stop", .stop)
			q:stop
			i $I(count)
			d ..SetTempParam(in.jobnum, "taktrecords", count)
			s status = $CLASSMETHOD(className, "%DeleteId", id)
			
			s $LI(idList,*+1)=id
			
			i $$$ISERR(status){
				s err = $SYSTEM.Status.GetErrorText(status)
				d ..SetTempParam(in.jobnum, "error", err)
				d ..SetTempParam(in.jobnum, "end", 1) 
				s ^CacheTempError($I(^CacheTempError),"App.MAF.Linker","DelAgentNomsAndLinks","err ##class(App.PRC.Nomen).%DeleteId(idLink)") = $system.Status.GetErrorText(status)
				q
			}
		}
		
		; Удаление связей ========================================
		i $LL(idList)>0 {
			s query		=	"SELECT id "_
							" FROM App_MAF.Link "_
							" WHERE ClassNameLeft = '"_className_"' "_
							" AND IdLeft in ("_$LTS(idList)_")"
			s statement	= ##class(%SQL.Statement).%New()
			s status	= statement.%Prepare(.query)
			i status'=$$$OK {
				s err = $SYSTEM.Status.GetErrorText(status)
				d ..SetTempParam(in.jobnum, "error", err)
				d ..SetTempParam(in.jobnum,"end",1) 
				s ^CacheTempError($I(^CacheTempError),"App.MAF.Linker","DelAgentNomsAndLinks","err statement.%Prepare(.query)") = err
				q
			}
			s resultSet = statement.%Execute()
			while resultSet.%Next() {
				s idLink = resultSet.%Get("id")
				s status = ##class(App.MAF.Link).%DeleteId(idLink)
				i $$$ISERR(status){
					s err = $SYSTEM.Status.GetErrorText(status)
					d ..SetTempParam(in.jobnum, "error", err)
					d ..SetTempParam(in.jobnum,"end",1) 
					s ^CacheTempError($I(^CacheTempError),"App.MAF.Linker","DelAgentNomsAndLinks","err ##class(App.MAF.Link).%DeleteId(idLink)") = err
					q
				}
			}
		}
		
		d ..SetTempParam(in.jobnum,"end",1) 			; конец	
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		d ..SetTempParam(in.jobnum,"error",err)
		d ..SetTempParam(in.jobnum,"end",1) 			; конец	
		s ^CacheTempError($I(^CacheTempError),"App.MAF.Linker","DelAgentNomsAndLinks","err") = err
	}
	q
}

}

