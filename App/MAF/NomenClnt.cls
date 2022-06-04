/// Временный класс с номенеклатурой клиентов
Class App.MAF.NomenClnt Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// проверка названия по штрихкоду
/// d $system.Status.GetErrorText(##class(App.MAF.NomenClnt).CheckByODBC())
ClassMethod CheckByODBC()
{
	try{
		s dsn = "Portal"
		s user = ""
		s pwd = ""
		s timeout = 5
		
		s connection = ##Class(%SQLGatewayConnection).%New()
		
		s status = connection.Connect(dsn,user,pwd,timeout)
		i $$$ISERR(status) {
			w !,"Error Connect : ",$system.Status.GetErrorText(status)
			q
		}
		
		s status=connection.AllocateStatement(.hstmt) 
		i $$$ISERR(status) {
			w !,"Error AllocateStatement : ",$system.Status.GetErrorText(status)
			q
		}
		
		//Prepare statement for execution
		s pQuery =	"SELECT "_
						"name, "_
						"barcode, "_
					"FROM nomenclature "_
					"LIMIT 100"
		w !,"pQuery = ",pQuery
		
		s status = connection.Prepare(hstmt,pQuery) 
		i $$$ISERR(status) {
			w !,"Error Prepare : ",$system.Status.GetErrorText(status)
			q
		}
		
		//Execute statement
		s status = connection.Execute(hstmt)
		i $$$ISERR(status) {
			w !,"Error Execute : ",$system.Status.GetErrorText(status)
			q
		}
		
		//Get list of columns returned by query
		s status = connection.DescribeColumns(hstmt, .columnlist) 
		i $$$ISERR(status) {
			w !,"Error DescribeColumns : ",$system.Status.GetErrorText(status)
			q
		}
		s numcols=$listlength(columnlist)-1
		
		s status = connection.Fetch(hstmt)
		q:$$$ISERR(status)
		s rownum=1
		while((connection.sqlcode'=100)) {
			
			s (code,name,barcode,codeCtl,mapNomCode,transGroupId) = ""
			
			s status = connection.GetData(hstmt, 2, 1, .name)
			s status = connection.GetData(hstmt, 3, 1, .barcode)
			s name = $ZCVT(name,"i","CP1251")
			s barcode =  $ZCVT(barcode,"i","CP1251")
			w !!,name_" <-> "_barcode
			
		}
		
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
	}
	q
}

/// d ##class(App.MAF.NomenClnt).Repair()
ClassMethod Repair()
{
	k ind,ptr,id
	s f = [{"field":"Name","type":"'=","data":""},
		   {"oper":"AND"},
		   {"field":"NewNomenCode","type":"'=","data":""}
		  ]
	s err = ..Filter(f,.ind)
	i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
	while ..indNEXT(.ind,.prt,.id){
		s nom = ..%OpenId(id)
		d nom.GetCabinetNomenName()
	}
}

Method GetCabinetNomenName()
{
	k ind,ptr,id
	s f = [{"field":"CabinetCode","type":"=","data":(..NewNomenCode)}]
	s err = ##class(App.MAF.Nomen).Filter(f,.ind)
	i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
	while ..indNEXT(.ind,.prt,.id){
		s nom = ##class(App.MAF.Nomen).%OpenId(id)
		s ..NewNomenName = nom.Notation
		d ..%Save()
	}
}

/// d ##class(App.MAF.NomenClnt).MarkBadNomen()
Method Check()
{
	try {
		k ind2,ptr2,id2
		s flt2 = [{"field":"CabinetCode","type":"=","data":(..CabinetCode)}]
		s err = ##class(App.MAF.Nomen).Filter(flt2,.ind2)
		i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
		i ..indCOUNT(.ind2)=0 {
			s ..ProblemFl=1			
			d ..%Save()
		}
		else {
			s ..ProblemFl=0			
			d ..%Save()
		}
	}
	catch exp {
		s error = ##class(Lib.Adam).ErrorDetect(.exp)
		w "Error : ",error
	}
	q $$$OK
}

/// d ##class(App.MAF.NomenClnt).GetNewNomenCode()
ClassMethod GetNewNomenCode()
{
	k ind,ptr,id
	s count = 0
	s flt = [{"field":"ProblemFl","type":"=","data":"1"},
			{"oper":"AND"},
			{"field":"NewNomenCode","type":"пусто","data":""}
			]
	s err = ..Filter(flt,.ind)
	s fullCount = ..indCOUNT(.ind)
	i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
	while ..indNEXT(.ind, .ptr, .id) {
		i $I(count)
		w !,count," of ",fullCount," "
		;q:count>10
		s (in,out)={}
		s nomen = ..%OpenId(id)
		d nomen.GetEtalon(.in,.out)
	}
}

/// d ##class(App.MAF.NomenClnt).CheckAll()
ClassMethod CheckAll()
{
	k ind,ptr,id
	s count = 0
	s flt = [{"field":"ProblemFl","type":"=","data":"1"},
			{"oper":"и"},
			{"field":"NewNomenCode","type":"пусто","data":""}
			]
	s err = ..Filter(flt,.ind)
	s fullCount = ..indCOUNT(.ind)
	i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
	while ..indNEXT(.ind, .ptr, .id) {
		i $I(count)
		w !,count," of ",fullCount," "
		;q:count>10
		s (in,out)={}
		s nomen = ..%OpenId(id)
		d nomen.Check()
	}
}

/// d ##class(App.MAF.NomenClnt).GenerateFromTempGlob()
ClassMethod GenerateFromTempGlob()
{
	s status = $$$OK
	try {
		
		s count = 0
		
		s nomen = ""
		d {
			s nomen = $O( ^CacheTemp102("map-actions1","action1","nomenclatures1", nomen) )
			q:nomen=""
			
			;i $I(count)
			;q:count>10
			
			w !,nomen
			
			
			; =========================================================================================
			s (name, cabinetProductCode, cabinetCode, country, barcode, clientRange) = ""
			s clientRange = 1
			s prop=""
			d {
				s prop = $O( ^CacheTemp102("map-actions1","action1","nomenclatures1", nomen, prop) )
				q:prop=""
				
				s value = $G(^CacheTemp102("map-actions1","action1","nomenclatures1", nomen, prop))
				
				s:prop["name" name = value
				i prop["barcode" {
					s barcode = value
					d ##class(App.AGS.BarcodeLinker).NormalizeBarcode(.barcode)
					s:$L(barcode)<7 barcode=""
				}
				
				s:prop["fe-id" cabinetCode = value
				i prop["product" {
					w !,"Product code:"
					s helperIndex = ""
					d {
						s helperIndex = $O( ^CacheTemp102("map-actions1","action1","nomenclatures1", nomen, prop, helperIndex) )
						q:helperIndex=""
						
						;w !,$C(9),"helperIndex = ",helperIndex
						i helperIndex["fe-id" {
							s cabinetProductCode = $G(^CacheTemp102("map-actions1","action1","nomenclatures1", nomen, prop, helperIndex))
							w !,$C(9),"cabinetProductCode = ",cabinetProductCode
						}
						
					}
					while helperIndex'=""	
				}
				
				i prop["country"{
					w !,"Country:"
					s helperIndex = ""
					d {
						s helperIndex = $O( ^CacheTemp102("map-actions1","action1","nomenclatures1", nomen, prop, helperIndex) )
						q:helperIndex=""
						
						;w !,$C(9),"helperIndex = ",helperIndex
						i helperIndex["name_short" {
							s country = $G(^CacheTemp102("map-actions1","action1","nomenclatures1", nomen, prop, helperIndex))
							w !,$C(9),"country = ",country
						}
					}
					while helperIndex'=""	
				}
				
				i prop["map-id" {
					s mapId = $G(^CacheTempBatches("map-actions1","action1","nomenclatures1", nomen, prop) )
				}
				
				i prop["is_client_range"{
					s value = $ZCVT(value, "L")
					i value["false" {
						s clientRange=0
						
					}else {
						w !,nomen
						w !,prop
						r *key
					}
					
				}
				
				;w !,$C(9),prop," = ",value
			}	
			while prop'=""


			; ========================================================================================
			k ind,ptr,id				
			s filter =	[
							{"field":"CabinetCode","type":"=","data":(cabinetCode)},
							{"oper":"AND"},
							{"field":"CabinetProductCode","type":"=","data":(cabinetProductCode)}
						]
			s err = ..Filter(filter,.ind)
			i err'=""  {
				s status = $$$ERROR(err)
				q
			}
			i (..indCOUNT(.ind)=0) { 							; Создаем только если такой позици нет
				
				w !,$C(9),name," code=",cabinetCode," prodCode=",cabinetProductCode," country=",country
			
				s nomenclature = ..%New()			
				s nomenclature.Name = name
				s nomenclature.Barcode = barcode
				s nomenclature.CabinetCode = cabinetCode
				s nomenclature.CabinetProductCode = cabinetProductCode
				s nomenclature.Country = country
				s nomenclature.MapId = mapId
				s nomenclature.ClientRange  =clientRange
				s status = nomenclature.%Save()
				d nomenclature.Check()
				q:'status
			}
		} while nomen'="" && $$$ISOK(status)		
	}
	catch exp {
		s error = ##class(Lib.Adam).ErrorDetect(.exp)
		w "Error:",error
	}
	w:$$$ISERR(status) $system.Status.GetErrorText(status)
	q status
}

Method GetNotation()
{
	i $L(..Notation) <5 {
		s ..Notation = ..Name_" "_..Country_" "_..Barcode
		d ..%Save()
	}
	q ..Notation
}

/// Метод подбора лучших кандидатов многопоточный, ускорение в 4 раза по стравнению с многопоточным
Method GetEtalon(in, out)
{
	try {
		s ..NewNomenCode = ""
		d ..%Save()
		
		s err="", row="", out.error="", out.data={}, cntAll = 0, cnt = 0, rows = [], log = [], in.log = 1, %log=""
		s startTimeStamp = $ZTS
		
		s in.sessionGUID = ..%Id() ;$System.Util.CreateGUID()
		
		s nomToRecognize = $this ;##class(App.PRC.Nomen).%OpenId(idMain)
		
		s nGgramMetric = ##class(App.MAF.Metric).%OpenId(1)															; Открываем метрики
		s numMetric = ##class(App.MAF.Metric).%OpenId(2)
		s barcodeMetric = ##class(App.MAF.Metric).%OpenId(3)														; TODO сделать сущность "план сравнения" который включает метрики

		d ..GetNotation()																							; Получение строки для сравнения
		s strToRecognize = $ZCVT(..Notation,"L")																	; Переводим в нижний регистр
		
		w strToRecognize,!
		
		s strToRecognize = ##class(App.SPR.Synonym).OriginaliseStringV2(strToRecognize)								; Замена синонимов оригиналами
		q:out.error'=""
		
		s out.log = "", in.str = strToRecognize, ngrammStrToRecognize = nGgramMetric.ApplyPatterns(in, out)			; Получение очищенной строки строки для метрики n-Gramm
		q:out.error'=""
		
		s in.str = strToRecognize, numStrToRecognize = numMetric.ApplyPatterns(in, out)								; Получение очищенной строки для метрики числовой сходимости
		q:out.error'=""
		
		s in.str = strToRecognize, barStrToRecognize = barcodeMetric.ApplyPatterns(in, out)							; Получение очищенной строки для метрики штрихкода
		q:out.error'=""
		
		w !,$C(9),"barcode client: ",barStrToRecognize
		
		s ngStrToRecognizeNoDbl = ##class(App.MAF.Linker).DeleteDublicateWords(ngrammStrToRecognize,out)			; Удаление дубликатов слов
		q:out.error'="" 
		
		s in.sourceString = ngStrToRecognizeNoDbl, in.stem = 1 														; Выделение ключевых слов и стемминг
		d ##class(App.MAF.Linker).GetStemKeywordList(in,out)
		q:out.error'="" 
		
		s in.keywordList = out.keywordList 																			; Получение представительной выборки для сравнения с исходной строкой
		d ##class(App.MAF.Nomen).GetRepresIndV2(in,out,.indRepres)
		q:out.error'=""
		
		w !,$C(9),"Candidates count:",out.count
		
		; Распределение вычислений между ядрами процессора =========================================================
		
		s:'in.%IsDefined("sessionGUID") in.sessionGUID = $System.Util.CreateGUID()									; Если уникальный идентификатор отсутствует в данных сессии - создадим
		k ^CacheTemp(in.sessionGUID)																				; Во временной глобали под индексом идентификатора, уникального для сессии, разместятся все результаты
		m ^CacheTemp(in.sessionGUID,"ind") = indRepres																; Мержим индекс в темповую глобаль для использования в джобе
		d ..SetTempParam(in.sessionGUID, "error", "")
		
		s jobnum = in.sessionGUID
		s CPUinfo = ##class(%SYSTEM.CPU).%New()
		s flowsCount = CPUinfo.nCores * 2																			; Количество потоков
		s limitPerCore = $NORMALIZE( ((out.count / flowsCount) + 0.4), 0 )
		d ..SetTempParam(jobnum,"start",$h)
		d ..SetTempParam(jobnum,"user",$USERNAME)
		s out.jobnum = jobnum
		s out.typejob = "job"
		s in.limitPerCore = limitPerCore																			; Лимит обрабатываемых записей для каждого ядра
		s in.startPos = 1																							; Стартовая запись для обработки для каждого ядра будет своя
		
		s in.ngrammStrToRecognize = ngrammStrToRecognize
		s in.numStrToRecognize = numStrToRecognize
		s in.barStrToRecognize = barStrToRecognize
		f coreCounter = 1:1:flowsCount {
			; continue:coreCounter>1	
			s in.coreNum = coreCounter																				; Номер занимаего ядра передадим в джоб
			s in4Job = in.%ToJSON()																					; В фоновый процесс можно передавать только без ссылки, поэтому преводим все в строку
			s ^CacheTemp(in.sessionGUID,"jobfinish",in.coreNum) = 0													; Обнуление флага финиша выполнения джоба
			j ..CalcCandidates(in4Job)																				; Запуск джоба
			
			s in.startPos = (limitPerCore * coreCounter) + 1														; Передвигаем стартовую позицию обработки для следующего джоба
		}
		
		; Конец распределения, начинаем следить за выполнением =====================================================
		
		s allJobsFinished = 0, jobError = ""																		; Следим за финишем выполнения всех джобов
		while allJobsFinished = 0 {
			f coreNum=1:1:flowsCount {																				; Перебираем флаги финиша обработки в темповой глобали
				s allJobsFinished = $G( ^CacheTemp(in.sessionGUID,"jobfinish",coreNum) )
				q:allJobsFinished=0																					; Если хоть один не закончил - ждем дальше
			}
			HANG 0.1
			s err = ..GetTempParam(in.sessionGUID, "error", .jobError)												; Если есть ошибки - заканчиваем
			s err = ..GetTempParam(in.jobnum,"stop",.stop)			
			s:jobError'="" allJobsFinished = 1
			s:stop=1 allJobsFinished=1
		}
		
		i jobError'="" {
			d ..SetTempParam(in.jobnum,"end",1) 
			s out.error = jobError
			q
		}		
		
		d ..SetTempParam(in.jobnum,"end",1) 
		
		; Конец основных вычислений ================================================================================
		
		s finishTimeStamp = $ZTS
		s time = ##class(Lib.Util.DateTime).DeltaMS(startTimeStamp,finishTimeStamp)
		d:in.log log.%Push({"Info": ( "<b>Time : </b>"_$C(13,10)_time )})
		
		
		s info = "Oooops, no analog"
		s maxCanditades = 1																						; показ кандидатов
		s countCandidates = 0
		
		s commonKoef = $O(^CacheTemp(in.sessionGUID, "candidates", ""), -1)
		while (commonKoef '= "") && (countCandidates < maxCanditades) {			
		
			s id =  $O(^CacheTemp(in.sessionGUID, "candidates", commonKoef, ""))
			while (id '= "") && (countCandidates < maxCanditades) {

				i $I(countCandidates)
				
				; сортировка по общему коэфициенту
				s nGrammKoef			= $G(^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "nGrammKoef"))
				s numKoef				= $G(^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "numKoef"))
				s barKoef				= $G(^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "barKoef"))
				s ngrammStrToCompare	= $G(^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "ngrammStrToCompare"))
				s numStrToCompare 		= $G(^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "numStrToCompare"))
				s barStrToCompare		= $G(^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "barStrToCompare"))
				
				s nomen = ##class(App.MAF.Nomen).%OpenId(id)
				
				w !,$C(9),"finded new nomen: ",nomen.Name," ",nomen.Barcode," "
				w !,$C(9),"code: ",nomen.CabinetCode
				w !,$C(9),"common coeficient: ",commonKoef
				w !,$C(9),"barcode cabinet: ",barStrToCompare
				
				i (commonKoef>80) {
					i (..CabinetProductCode = nomen.CabinetProductCode){
						s ..NewNomenCode = nomen.CabinetCode
					}
					else {
						s ..NewNomenCode = nomen.CabinetCode
						s ..ErrLink = 1
					}
				}
				s:nGrammKoef<85 ..ClientRange = 1
				
				d ..%Save()

				s cntAll=cntAll+1,cnt=cnt+1
				s id = $O(^CacheTemp(in.sessionGUID, "candidates", commonKoef, id))
			}
			
			s commonKoef = $O(^CacheTemp(in.sessionGUID, "candidates", commonKoef), -1)
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q err
}

ClassMethod CalcCandidates(in)
{
	try {
		s allAnalogInfo = ""
		k candidates
		s in = {}.%FromJSON(in)
		s out = {}
		s recCounter = 0
		
		s nGgramMetric = ##class(App.MAF.Metric).%OpenId(1)														; Открываем метрики
		s numMetric = ##class(App.MAF.Metric).%OpenId(2)
		s barMetric = ##class(App.MAF.Metric).%OpenId(3)
		
		s ngrammStrToRecognize = in.ngrammStrToRecognize
		s numStrToRecognize = in.numStrToRecognize
		s barStrToRecognize = in.barStrToRecognize
		
		s ^CacheTemp(in.sessionGUID, "source", "ngrammStrToRecognize")= ngrammStrToRecognize
		s ^CacheTemp(in.sessionGUID, "source", "numStrToRecognize")	= numStrToRecognize 
		s ^CacheTemp(in.sessionGUID, "source", "barStrToRecognize")	= barStrToRecognize 
		
		m ind = ^CacheTemp(in.sessionGUID,"ind")																; Забираем индекс из временной глобали
		while ##class(App.MAF.Nomen).indNEXTsort(.ind, "CabinetCode", 1, in.startPos, .ptr, .id) && (recCounter < in.limitPerCore){ 	; Перебор номенклатур и сравнение каждой с исходной позицией
			s err = ..GetTempParam(in.jobnum,"stop",.stop)
			q:stop
			
			s nomToCompare = ##class(App.MAF.Nomen).%OpenId(id)
			s in.objToGetString = nomToCompare
			s strToCompare = nomToCompare.Notation																; Конкатенация свойств номенклатуры в строку в соответствии с настройками метрики
			s strToCompareSource = strToCompare
			q:out.error'=""
			
			s in.str = strToCompare, barStrToCompare = barMetric.ApplyPatterns(in, out)							; Применение паттернов обработки метрики
			q:out.error'=""
			
			w !,$C(9),"barcodes : ",barStrToRecognize," ",barStrToCompare
			
			s barKoef = $NORMALIZE( ##class(App.MAF.Metric).BarcodeSimilarity(barStrToRecognize, barStrToCompare), 2)/100
			continue:barKoef=0
			
			
			s in.str = strToCompare, ngrammStrToCompare = nGgramMetric.ApplyPatterns(in, out)					; Применение паттернов метрики 
			q:out.error'=""
			
			s in.str = strToCompare, numStrToCompare = numMetric.ApplyPatterns(in, out)							; Применение паттернов метрики
			q:out.error'=""
			
			s ngrammStrToCompare = ##class(App.MAF.Linker).DeleteDublicateWords(ngrammStrToCompare,out)			; Удаление дубликатов слов
			q:out.error'="" 
			
			s (nGrammKoef,numKoef)=0
			s nGrammKoef = ##class(App.MAF.Metric).nGramm(ngrammStrToRecognize, ngrammStrToCompare, 3)/100		; Вычисление коэфициентов
			s numKoef = $NORMALIZE( ##class(App.MAF.Metric).MeasurablePropsSimilarity(numStrToRecognize, numStrToCompare), 2)/100
						
			i barKoef = 0.5 {
				s numOfMetrics = 2
				s wNG 	= 1																						; Весы коэфициентов метрик. Изначально каждый равен 1, и их сумма равна количеству коэфициентов
				s wNum	= 1
				s commonKoef = ( ( (nGrammKoef*wNG) + (numKoef*wNum)) / numOfMetrics  ) * 100
			}
			i barKoef > 0.5 {
				s numOfMetrics = 3
				s wNG 	= 1.2																					; Весы коэфициентов метрик. Изначально каждый равен 1, и их сумма равна количеству коэфициентов
				s wNum	= 0.6
				s wBar	= 1.2
				s commonKoef = ( ( (nGrammKoef*wNG) + (numKoef*wNum) + (barKoef*wBar) ) / numOfMetrics  ) * 100
			}
			
			; сортировка по общему коэфициенту 
			s ^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "nGrammKoef")		= nGrammKoef		; Запоминаем все про этого кандидата. В индексированную переменную для простоты сортировки лучших
			s ^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "numKoef")			= numKoef
			s ^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "barKoef")			= barKoef
			s ^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "ngrammStrToCompare")= ngrammStrToCompare
			s ^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "numStrToCompare")	= numStrToCompare 
			s ^CacheTemp(in.sessionGUID, "candidates", commonKoef, id, "barStrToCompare")	= barStrToCompare 
			
			i $I(recCounter)
		}
		s ^CacheTemp(in.sessionGUID,"jobfinish",in.coreNum) = 1
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		d ..SetTempParam(in.sessionGUID, "error", err)
		s ^CacheTemp(in.sessionGUID,"jobfinish",in.coreNum) = 1
	}
	q err
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

/// Штрихкод
Property Barcode As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Наименование
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Страна
Property Country As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Код позиции в кабинете
Property CabinetCode As Lib.DataTypes.Integer(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1);

/// Код товара в кабинете
Property CabinetProductCode As Lib.DataTypes.Integer(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1);

/// Идентификатор в МАП
Property MapId As Lib.DataTypes.Integer(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1);

/// Признак проблемной позиции
Property ProblemFl As Lib.DataTypes.Boolean(IndexValue = 1);

/// Нотация
Property Notation As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Код номенклатуры кабинета, найденный по названию
Property NewNomenCode As Lib.DataTypes.Integer(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1);

/// Ошибка связки
Property ErrLink As Lib.DataTypes.Boolean(IndexValue = 1) [ InitialExpression = 0 ];

/// Признак клиентского диапазона
Property ClientRange As Lib.DataTypes.Boolean(IndexValue = 1) [ InitialExpression = 0 ];

/// Наименование номенклатуры кабинета, найденной по названию
Property NewNomenName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

Index NewNomenName On NewNomenName As Truncate(200) [ Type = bitmap ];

Index ClientRange On ClientRange As Truncate(200) [ Type = bitmap ];

Index ErrLink On ErrLink As Truncate(200) [ Type = bitmap ];

Index NewNomenCode On NewNomenCode As Truncate(200) [ Type = bitmap ];

Index Notation On Notation As Truncate(200) [ Type = bitmap ];

Index ProblemFl On ProblemFl As Truncate(200) [ Type = bitmap ];

Index MapId On MapId As Truncate(200) [ Type = bitmap ];

Index Country On Country As Truncate(200) [ Type = bitmap ];

Index Barcode On Barcode As Truncate(200) [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index CabinetCode On CabinetCode As Truncate(200) [ Type = bitmap ];

Index CabinetProductCode On CabinetProductCode As Truncate(200) [ Type = bitmap ];

Parameter XMLTYPE = "App-MAF-NomenClnt";

Storage Default
{
<Data name="NomenClntDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Barcode</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>CabinetCode</Value>
</Value>
<Value name="5">
<Value>CabinetProductCode</Value>
</Value>
<Value name="6">
<Value>Vers</Value>
</Value>
<Value name="7">
<Value>GUID</Value>
</Value>
<Value name="8">
<Value>Country</Value>
</Value>
<Value name="9">
<Value>MapId</Value>
</Value>
<Value name="10">
<Value>ProblemFl</Value>
</Value>
<Value name="11">
<Value>Notation</Value>
</Value>
<Value name="12">
<Value>NewNomenCode</Value>
</Value>
<Value name="13">
<Value>ErrLink</Value>
</Value>
<Value name="14">
<Value>ClientRange</Value>
</Value>
<Value name="15">
<Value>NewNomenName</Value>
</Value>
<Value name="16">
<Value>SourseSys</Value>
</Value>
<Value name="17">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.MAF.NomenClntD</DataLocation>
<DefaultData>NomenClntDefaultData</DefaultData>
<IdLocation>^App.MAF.NomenClntD</IdLocation>
<IndexLocation>^App.MAF.NomenClntI</IndexLocation>
<StreamLocation>^App.MAF.NomenClntS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

