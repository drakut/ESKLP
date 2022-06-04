Class App.MAF.Utils Extends %RegisteredObject
{

/// Метод получения индекса представительной выборки из эталонных номенклатур для сравнения с исходной строкой прайса.
/// Алгоритм:
/// 	1. Если задан штриход, то искать эталоны по нему, остальные способы не выполняются если найден. 
/// 	2. Если по штрихкоду не найдено - то поиск по ключевым словам. 
/// 	3. Если по ключевым не нашлось - то поиск по первому слову из списка ключевых слов
/// Первая стади с поиском по штрихкоду сделана для ускорения поиска аналогов для позиций с штрихкодом
/// Вход:
/// 	in.keywordList			- список ключевых слов
/// 	in.barStrToRecognize	- штрихкод
/// 	in.data.classname		- класс данных с которыми связывать
/// Выход:
/// 		out.error		- ошибки
/// 		ind				- индекс
ClassMethod GetRepresIndOLD(in, out, ByRef ind)
{
	/*
	s status = $$$OK
	try {
		k ind
		s out.count = 0
		i ( in.%IsDefined("barStrToRecognize") ) & ( in.barStrToRecognize'="" ){					; Если задан штрихкод, то будем искать эталоны только по нему.
			
			i in.data.classNameL = "App.CTN.Nomen" {
				k indFirm,ptrFirm,idFirm															; У одной каталожной позиции можеть быть несколько стран и EAN- расхлопываем их в несколько каталожных позиций
				s filterFirm = [{"field":"VolHand","type":"=","data":(in.barStrToRecognize)}]
				s err = ##class(App.CTN.NomenVolFirm).Filter(filterFirm,.indFirm)
				while ##class(App.CTN.NomenVolFirm).indNEXT(.indFirm,.ptrFirm,.idFirm){
					s objVal = ##class(App.CTN.NomenVolFirm).%OpenId(idFirm)
					d ##class(App.CTN.Nomen).indINSERT(.ind,objVal.idNomen.%Id())
				}
				s out.count = ##class(App.CTN.Nomen).indCOUNT(.ind)
			}
			else {
				;k ptr,id																			; У одной каталожной позиции можеть быть несколько стран и EAN- расхлопываем их в несколько каталожных позиций
				;s filter = [{"field":"Barcode","type":"=","data":(in.barStrToRecognize)}]
				;s out.filter = filter
				;s err = $CLASSMETHOD(in.data.classname, "Filter", filter, .ind)
				;i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
				;s count = $CLASSMETHOD(in.data.classname, "indCOUNT", .ind)
			}
		}

		i out.count = 0 {
			s filter = []
			d ..GetKeyWordFilterV3(in, out)
			q:out.error'=""
			d:in.data.classNameR="App.MAK.Nomen" ##class(Lib.Util.Filter).ExtendFilter(out.filter,{"field":"Act","type":"=","data":"1"},.out)
			k ind
			s err = $CLASSMETHOD(in.data.classNameR, "Filter", out.filter, .ind)
			i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
			s out.count = $CLASSMETHOD(in.data.classNameR, "indCOUNT", .ind)
		}
		
		i out.count = 0 {
			d ..GetKeyWordFilterV2(in, out)
			q:out.error'=""
			d:in.data.classNameR="App.MAK.Nomen" ##class(Lib.Util.Filter).ExtendFilter(out.filter,{"field":"Act","type":"=","data":"1"},.out)
			
			k ind
			s err = $CLASSMETHOD(in.data.classNameR, "Filter", out.filter, .ind)
			i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
			s out.count = $CLASSMETHOD(in.data.classNameR, "indCOUNT", .ind)
		}	
		
		; если ничего не нашлось или слишком много - то поищем по 1му ключевому слову
		i (out.count = 0)!(out.count>500) {
			s out.filter = [{"field":"SpecName","type":"содержит","data":($LG(in.keywordList,1))}]
			d:in.data.classNameR="App.MAK.Nomen" ##class(Lib.Util.Filter).ExtendFilter(out.filter,{"field":"Act","type":"=","data":"1"},.out)
			
			k ind
			s err = $CLASSMETHOD(in.data.classNameR, "Filter", out.filter, .ind)
			i err'="" {
				s ^CacheTempError($I(^CacheTempError),"GetRepresIndV2","fatal") = err
				throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
			s out.count = $CLASSMETHOD(in.data.classNameR, "indCOUNT", .ind)
		}
		
		d:(in.data.log)&(out.%IsDefined("filter")) %log.%Push({"Oper":"<b>Фильтр : </b>", "Result":( out.filter.%ToJSON() )})
		d:in.data.log %log.%Push({"Oper": "<b>Количество кандидатов : </b>", "Result":(out.count) })
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
		s ^CacheTempError($I(^CacheTempError),"GetRepresIndV2","fatal") = err
	}
	q status
	*/
}

/// Метод получения фильтра для получения выборки для сравнения
/// Слова менее 3х символов игнорируются
/// Вход:
/// 	in.keywordList 	- список $LB() из слов, из которых все варианты пар по условию И будут объединены по условию ИЛИ. 
/// 					  Набор слов в каждой паре уникален, то есть ("раз", "два")=("два", "раз")
/// Выход:
/// 	out.filter		- фильтр
/// 
/// s (out,in)={}, in.keywordList=$LB("раз","два","три")
/// d ##class(App.MAF.Linker).GetKeyWordFilter(in,out)  w out.filter.%ToJSON()
/// 
ClassMethod GetKeyWordFilterV2(in, out)
{
	/*
	try {
		s filter = ""
		f i=1:1:$LL(in.keywordList){
			s word1 = $LG(in.keywordList,i)
			continue:$L(word1)<3
			
			f j=i+1:1:$LL(in.keywordList) {
				s word2 = $LG(in.keywordList,j)
				continue:$L(word2)<3
				
				i filter="" {
					s filter = [
								{"filter":[
											{"field":"SpecName","type":"содержит","data":(word1)}, 
											{"oper":"AND"}, 
											{"field":"SpecName","type":"содержит","data":(word2)}
										  ] 
								}
							   ]
				}
				else {
					s condition = [
									{"field":"SpecName","type":"содержит","data":(word1)},
								   	{"oper":"AND"},
								  	{"field":"SpecName","type":"содержит","data":(word2)}
							      ]
					s err = ##class(Lib.Util.Filter).ExtendFilterByOr(filter,condition,out)
				}
			}
			
			s:filter="" filter=[{   "filter":[{"field":"SpecName","type":"содержит","data":(word1)}]	}]
											
			
		}
		s out.filter = filter		
	}
	catch exp {
		s err =..ErrorDetect(.exp)
		s out.error = err
		s ^CacheTempError($I(^CacheTempError),"GetKeyWordFilterV3","fatal") = err
	}
	q
	*/
}

/// Метод получения фильтра класса App.CTN.Nomen для получения выборки для сравнения
/// Слова менее 3х символов игнорируются
/// Вход:
/// 	in.keywordList 	- список $LB() из слов, из которых все варианты триад по условию И будут объединены по условию ИЛИ. 
/// 					  Набор слов в каждой паре уникален, то есть ("раз", "два")=("два", "раз")
/// Выход:
/// 	out.filter		- фильтр
/// 
/// s (out,in)={}, in.keywordList=$LB("раз","два","три")
/// d ##class(App.MAF.Linker).GetKeyWordFilterV3(in,out)  w out.filter.%ToJSON()
/// 
ClassMethod GetKeyWordFilterV3(in, out)
{
	/*
	try {
		s filter = ""
		f i=1:1:$LL(in.keywordList){
			s word1 = $LG(in.keywordList,i)
			continue:$L(word1)<3
			
			f j=i+1:1:$LL(in.keywordList) {
				s word2 = $LG(in.keywordList,j)
				continue:$L(word2)<3
				
				f b=j+1:1:$LL(in.keywordList) {
					s word3 = $LG(in.keywordList,b)
					continue:$L(word3)<3
					
					i filter="" {
						s filter = [
									{"filter":[
												{"field":"SpecName","type":"содержит","data":(word1)}, 
												{"oper":"AND"}, 
												{"field":"SpecName","type":"содержит","data":(word2)},
												{"oper":"AND"}, 
												{"field":"SpecName","type":"содержит","data":(word3)}
											  ] 
									}
								   ]
					}
					else {
						s condition = [
										{"field":"SpecName","type":"содержит","data":(word1)},
									   	{"oper":"AND"},
									  	{"field":"SpecName","type":"содержит","data":(word2)},
									  	{"oper":"AND"},
									  	{"field":"SpecName","type":"содержит","data":(word3)}
								      ]
						s err = ##class(Lib.Util.Filter).ExtendFilterByOr(filter,condition,out)
					}
				}
				i filter="" {																; если 3-го слова не оказалось - делаем фильтр из 2х слов
					s filter = [
								{"filter":[
											{"field":"SpecName","type":"содержит","data":(word1)}, 
											{"oper":"AND"}, 
											{"field":"SpecName","type":"содержит","data":(word2)}
										  ] 
								}
							   ]
				}
			}
			i filter="" {																; если 2-го слова не оказалось - делаем фильтр из 1 слова
				s filter = [
							{"filter":[
										{"field":"SpecName","type":"содержит","data":(word1)}
									  ] 
							}
						   ]
			}
		}
		s out.filter = filter		
	}
	catch exp {
		s err =..ErrorDetect(.exp)
		s out.error = err
		s ^CacheTempError($I(^CacheTempError),"GetKeyWordFilterV3","fatal") = err
	}
	q
	*/
}

/// d ##class(App.MAF.Linker).SetImpKoef()
ClassMethod SetImpKoef()
{
	/*
	try {
		s count = 0
		
		k ind,ptr,id
		s var = ""
		s flt = [
					{"field":"idAgent","type":"=","data":"223"}
					,{"oper":"and"}
					,{"field":"TempKoefMakImp","type":"=","data":"null"}
				]
		
		s flt = [{"field":"idAgent","type":"=","data":"223"}]
		
		s err = ##class(App.PRC.Nomen).Filter(flt,.ind)				w !,##class(App.PRC.Nomen).indCOUNT(.ind)
		q:err'=""
		
		
		while ##class(App.PRC.Nomen).indNEXT(.ind,.ptr,.id) {
			s koef = 0
			i $I(count)
			;q:count>10
			
			s price = ##class(App.PRC.Nomen).%OpenId(id)
			;continue:price.TempKoefMakImp>0
			;w $C(13),count," id=",id
			w !,count," id=",id,"  code=",price.Code
			
			;k ind2,ptr2,id2
			;s flt2 = [{"field":"IdCabinet","type":"=","data":(price.TempIdMakNomen)}]
			;s err =  ##class(App.MAF.MakNomen).Filter(flt2,.ind2)	
			;q:err'=""
			;while ##class(App.MAF.MakNomen).indNEXT(.ind2,.ptr2,.id2) {
			;	s makNomen = ##class(App.MAF.MakNomen).%OpenId(id2)
			;}
			;i '$ISO(makNomen) {
			;	s price.TempKoefMakImp = 0
			;	d price.%Save()
			;	continue
			;}
			
			s makNomen = price.idMakNomen
			i '$ISO(makNomen) {
				s price.TempKoefMakImp = -1
				d price.%Save()
				continue
			}
			
			s (in,out) = {}
			s in.id = id
			s in.sessionGUID = $System.Util.CreateGUID()
			k ^CacheTemp(in.sessionGUID)
			
			s nGgramMetric = ##class(App.MAF.Metric).%OpenId(1)										; Открываем метрики
			s numMetric = ##class(App.MAF.Metric).%OpenId(2)
			s brandMetric = ##class(App.MAF.Metric).%OpenId(5)
			
			
			s (nGrammKoef,numKoef,barKoef,dictKoef,prodNameKoef,brandKoef,countryKoef,lekFormKoef)=-1
			
			
			; Прайс --------------------------------------------------------------------------------
			s nomToRecognize = price
			s in.objToGetString = nomToRecognize, strToRecognize = nGgramMetric.GetString(in, out)	; Получение строки для сравнения TODO - вынести метод в соответствующие классы номенклатуры и прайса
			
				s strToRecognize = $ZCVT(strToRecognize,"L")											; Переводим в нижний регистр
				s matcher = ##class(%Regex.Matcher).%New("(?<=\D)\.(?=\d)",strToRecognize)
				s strToRecognize = matcher.ReplaceAll(". ") 											; сокращения с точками отделяем пробелами от чисел, "шамп.280 Пит.,укреп." => "шамп. 280 Пит.,укреп."
				s matcher = ##class(%Regex.Matcher).%New("(?<=\D)\.(?=\D)",strToRecognize) 				; отделяем сокращения ТБЛ.ПРОЛОНГ от впереди соящего слова ТБЛ. ПРОЛОНГ
				s strToRecognize = matcher.ReplaceAll(". ")
				s strToRecognize = ##class(App.SPR.Synonym).OriginaliseStringV3(strToRecognize)			; Замена синонимов оригиналами
			
			s in.str = strToRecognize, ngrammStrToRecognize = nGgramMetric.ApplyPatterns(in, out)	; Получение очищенной строки строки для метрики n-Gramm
			s numStrToRecognize = numMetric.ApplyPatterns(in, out)									; Получение очищенной строки для метрики числовой сходимости
			s ngStrToRecognizeNoDbl = ..DeleteDublicateWords(ngrammStrToRecognize,out)				; Удаление дубликатов слов
			; МАК-номенклатура ---------------------------------------------------------------------
			s nomToCompare = makNomen
			s in.objToGetString = nomToCompare,	strToCompare = nGgramMetric.GetString(in, out)
			s in.str = strToCompare, ngrammStrToCompare = nGgramMetric.ApplyPatterns(in, out)		; Конкатенация свойств номенклатуры в строку в соответствии с настройками метрики
			s numStrToCompare = numMetric.ApplyPatterns(in, out)									; Получение очищенной строки для метрики числовой сходимости
			
			w !,$C(9),ngrammStrToRecognize
			w !,$C(9),ngrammStrToCompare
			
			s nGrammKoef = ##class(App.MAF.Metric).nGramm(ngrammStrToRecognize, ngrammStrToCompare, 3)					; Вычисление коэфициента ngramm
			s numKoef = ##class(App.MAF.Metric).MeasurablePropsSimilarity(numStrToRecognize, numStrToCompare)
			s brandKoef = brandMetric.DictSimil(ngrammStrToRecognize, ngrammStrToCompare)
			
			s summKoef = 0
			s numOfMetrics = 0
			i nGrammKoef>0 {
				s nGrammKoef = nGgramMetric.Weight * nGrammKoef
				i $I(numOfMetrics)
				s summKoef = summKoef + nGrammKoef
			}
			i numKoef'=-1 {
				s numKoef = numMetric.Weight * numKoef
				i $I(numOfMetrics)
				s summKoef = summKoef + numKoef
			}
			i brandKoef'=-1 {
				s brandKoef = brandMetric.Weight * brandKoef
				i $I(numOfMetrics)
				s summKoef = summKoef + brandKoef
			}
			
			i numOfMetrics'=0 {
				s commonKoef = $NORMALIZE( ( summKoef / numOfMetrics  ) * 100, 2)
			}
			else {
				s commonKoef = 0
			}
			
			s price.TempKoefMakImp = commonKoef
			d price.%Save()
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		w !,"Fatal error: ",err
	}
	q 1
	*/
}

/// d ##class(App.MAF.Linker).SetOneImpKoef(4450332)
ClassMethod SetOneImpKoef(id)
{
	/*
	try {
		s koef = 0
		s price = ##class(App.PRC.Nomen).%OpenId(id)
		
		; s makNomen = price.idMakNomen - так было на 1й проверке, а тперь проверяем корректность связки по ЗШК
		s makBarcode = ""
		k ind,ptr,idMakBarcode
		s filter = [{"field":"ZHK","type":"=","data":(price.ZHK)}]
		s err = ##class(App.MAK.BarCode).Filter(.filter,.ind)
		while ##class(App.MAK.BarCode).indNEXT(.ind,.ptr,.idMakBarcode) {
			s makBarcode = ##class(App.MAK.BarCode).%OpenId(idMakBarcode )
		}
		i '$ISO(makBarcode) {
			s counter = $I(^kam)
			;s ^kam(counter,"SetOneImpKoef","no barcode","prise ZHK") = price.ZHK
			;s ^kam(counter,"SetOneImpKoef","no barcode","prise idLink") = price.Code
			q
		}
		
		s makNomen = makBarcode.idMakNom
		i '$ISO(makNomen) {
			s price.TempKoefMakImp = -1
			d price.%Save()
		}
		
		s (in,out) = {}
		s in.id = id
		
		s nGgramMetric = ##class(App.MAF.Metric).%OpenId(1)										; Открываем метрики
		s numMetric = ##class(App.MAF.Metric).%OpenId(2)
		s prodNameMetric = ##class(App.MAF.Metric).%OpenId(4)
		s brandMetric = ##class(App.MAF.Metric).%OpenId(5)
		s lekFormMetric = ##class(App.MAF.Metric).%OpenId(6)
		
		s (nGrammKoef,numKoef,barKoef,dictKoef,prodNameKoef,brandKoef,countryKoef,lekFormKoef)=-1
		
		; Прайс --------------------------------------------------------------------------------
		s nomToRecognize = price
		s in.objToGetString = nomToRecognize, strToRecognize = nGgramMetric.GetString(in, out)	; Получение строки для сравнения TODO - вынести метод в соответствующие классы номенклатуры и прайса
		
			s strToRecognize = $ZCVT(strToRecognize,"L")											; Переводим в нижний регистр
			s matcher = ##class(%Regex.Matcher).%New("(?<=\D)\.(?=\d)",strToRecognize)
			s strToRecognize = matcher.ReplaceAll(". ") 											; сокращения с точками отделяем пробелами от чисел, "шамп.280 Пит.,укреп." => "шамп. 280 Пит.,укреп."
			s matcher = ##class(%Regex.Matcher).%New("(?<=\D)\.(?=\D)",strToRecognize) 				; отделяем сокращения ТБЛ.ПРОЛОНГ от впереди соящего слова ТБЛ. ПРОЛОНГ
			s strToRecognize = matcher.ReplaceAll(". ")
			s strToRecognize = ##class(App.SPR.Synonym).OriginaliseStringV3(strToRecognize)			; Замена синонимов оригиналами
		
		s in.str = strToRecognize, ngrammStrToRecognize = nGgramMetric.ApplyPatterns(in, out)	; Получение очищенной строки строки для метрики n-Gramm
		s numStrToRecognize = numMetric.ApplyPatterns(in, out)									; Получение очищенной строки для метрики числовой сходимости
		s ngrammStrToRecognize = ..DeleteDublicateWords(ngrammStrToRecognize,out)				; Удаление дубликатов слов
		; МАК-номенклатура ---------------------------------------------------------------------
		s nomToCompare = makNomen
		s in.objToGetString = nomToCompare,	strToCompare = nGgramMetric.GetString(in, out)
		s in.str = strToCompare, ngrammStrToCompare = nGgramMetric.ApplyPatterns(in, out)		; Конкатенация свойств номенклатуры в строку в соответствии с настройками метрики
		s numStrToCompare = numMetric.ApplyPatterns(in, out)									; Получение очищенной строки для метрики числовой сходимости
		
		w !,$C(9),ngrammStrToRecognize
		w !,$C(9),ngrammStrToCompare
		
		s nGrammKoef = ##class(App.MAF.Metric).nGramm(ngrammStrToRecognize, ngrammStrToCompare, 3)					; Вычисление коэфициента ngramm
		s numKoef = ##class(App.MAF.Metric).MeasurablePropsSimilarity(numStrToRecognize, numStrToCompare)
		s brandKoef = brandMetric.DictSimil(ngrammStrToRecognize, ngrammStrToCompare)
		s prodNameKoef = prodNameMetric.DictSimil(ngrammStrToRecognize, ngrammStrToCompare)
		s lekFormKoef = lekFormMetric.DictSimil(ngrammStrToRecognize, ngrammStrToCompare)
		
		s summKoef = 0
		s numOfMetrics = 0
		i nGrammKoef>0 {
			s nGrammKoef = nGgramMetric.Weight * nGrammKoef
			i $I(numOfMetrics)
			s summKoef = summKoef + nGrammKoef
		}
		i numKoef'=-1 {
			s numKoef = numMetric.Weight * numKoef
			i $I(numOfMetrics)
			s summKoef = summKoef + numKoef
		}
		i brandKoef'=-1 {
			s brandKoef = brandMetric.Weight * brandKoef
			i $I(numOfMetrics)
			s summKoef = summKoef + brandKoef
		}
		i prodNameKoef'=-1 {
			s barKoef = prodNameMetric.Weight * prodNameKoef
			i $I(numOfMetrics)
			s summKoef = summKoef + prodNameKoef
		}
		i lekFormKoef'=-1 {
			s lekFormKoef = lekFormMetric.Weight * lekFormKoef
			i $I(numOfMetrics)
			s summKoef = summKoef + lekFormKoef
		}
		
		i numOfMetrics'=0 {
			s commonKoef = $NORMALIZE( ( summKoef / numOfMetrics  ) * 100, 2)
		}
		else {
			s commonKoef = 0
		}
		
		s price.TempKoefMakImp = commonKoef
		d price.%Save()
			
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		;s ^kam($I(^kam),"SetOneImpKoef","fatal error") = err
	}
	q
	*/
}

/// D ##class(App.MAF.Linker).SetImpKoefPack()
ClassMethod SetImpKoefPack(limit, offset, numCore, idPRMContragent)
{
	/*
	try {
		;s ^kam($I(^kam),"numCore")=numCore
		s ^TempVerification(numCore) = 0
		s ^TempVerification(numCore,"numProc") = $J
				
		s:$G(limit)="" limit=0
		s:$G(offset)="" offset=0
		s query =	"SELECT id "_
					"FROM App_PRC.Nomen "_
					"WHERE idAgent = "_idPRMContragent_" "_
					"AND TempKoefMakImp IS NULL "_
					"ORDER BY id "_$C(13,10)
		s ^TempVerification(numCore,"query") = query
		
		s statement	= ##class(%SQL.Statement).%New()
		s status	= statement.%Prepare(query)
		i status'=$$$OK {
			s ^kam($I(^kam),"SetImpKoefPack","Error %Prepare") = $SYSTEM.Status.GetErrorText(status)
			;s ^TempVerification(numCore) = 1
			q
		}
		s resultSet = statement.%Execute()
		
		////////////////////////////////////////////////////////////////////////////////////
		;HANG 10
		;S ^TempVerification(numCore) = 1
		;Q
		///////////////////////////////////////////////////////////////////////////////////
		
		s count = 0
		s offsetCount = 0
		WHILE resultSet.%Next() {
			i $I(offsetCount)
			continue:(offset>0)&&(offsetCount<offset)
			i $I(count)
			q:count>limit
						
			s id = resultSet.%Get("id")
			d ##class(App.MAF.Linker).SetOneImpKoef(id)
			
			i $I(^TempVerification("full"))
		}
		
		s ^TempVerification(numCore) = 1
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s ^kam($I(^kam),"SetImpKoefPack","fatal error") = err
		;s ^TempVerification(numCore) = 1
	}
	q 1
	*/
}

/// d ##class(App.MAF.Linker).SetImpKoefParallel()
ClassMethod SetImpKoefParallel(idParamonContragent)
{
	/*
	try {
		i $G(idParamonContragent)=""{
			w !,"Не задан id контрагента в Парамоне."
			q
		}
		
		s ts1 = $ZTS
		s count = 0
		
		k ind,ptr,id
		s var = ""
		s flt = [{"field":"idAgent","type":"=","data":(idParamonContragent)},{"oper":"AND"},{"field":"TempKoefMakImp","type":"пусто","data":""}]
		
		s err = ##class(App.PRC.Nomen).Filter(flt,.ind)
		s rowCount = ##class(App.PRC.Nomen).indCOUNT(.ind)						w !,"rowCount = ",rowCount
		q:err'=""
		
		;s rowCount = 500
		
		s CPUinfo = ##class(%SYSTEM.CPU).%New()
		s flowsCount = CPUinfo.nCores											; Количество потоков
		s limitPerCore = $NORMALIZE( ((rowCount / flowsCount) + 0.4), 0 )
		w !,"limitPerCore =",limitPerCore
		s offset = 0
		f numCore = 1:1:flowsCount {
			w !,"offset = ",offset
			j ..SetImpKoefPack(limitPerCore,offset,numCore,idParamonContragent)	; Запуск джоба
			s offset = (limitPerCore * numCore) + 1								; Передвигаем стартовую позицию обработки для следующего джоба
		}
		
		w !!
		k ^TempVerification
		s ^TempVerification("full") = 0
		s allJobsFinished = 0, jobError = ""									; Следим за финишем выполнения всех джобов
		while allJobsFinished = 0 {
			f numCore=1:1:flowsCount {											; Перебираем флаги финиша обработки в темповой глобали
				s allJobsFinished = $G( ^TempVerification(numCore),0 )
				q:allJobsFinished=0												; Если хоть один не закончил - ждем дальше
			}
			HANG 0.5
			w $C(13),$G(^TempVerification("full"))
		}
		
		s ts2 = $ZTS
		w !,"Time elapsed:", ##class(Lib.Util.DateTime).DeltaMS(ts1,ts2)
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		w !,"Fatal error: ",err
	}
	q 1
	*/
}

/// Метод импорта номенклатуры портала вместе с прявязками к мак-номенклатуре из БД портала по ODBC
/// Ном-ра портала представляется как один большой прайс
/// d ##class(App.MAF.Linker).GetPortalNmByODBC() 
ClassMethod GetPortalNmByODBC(limit, offset, coreNum, idLink, idParamonContragent)
{
	
	/*
	try {
		s ^CacheTempPortalImport(coreNum,"numProc") = $J
		s ^CacheTempPortalImport(coreNum) = 0
		
		s status = $$$OK
		s ts1 = $ZTS
		
		s dsn = "portal"
		s user = "portal"
		s pwd = "system001"
		s timeout = 10
		s contragent = ##class(App.PRC.Agent).%OpenId(idParamonContragent) ; Задаем конрагента
		i '$ISO(contragent){
			d ..ReportImportError("","Ошибка открытия контрагента в Парамоне с id = "_idParamonContragent)
			s ^CacheTempPortalImport(coreNum) = 1
			q
		}
		
		s connection = ##Class(%SQLGatewayConnection).%New()
		
		s:$G(limit)="" limit=1
		s:$G(offset)="" offset=0
		
		s status = connection.Connect(dsn,user,pwd,timeout)
		i $$$ISERR(status) {
			d ..ReportImportError("","Ошибка Connect в job: "_$system.Status.GetErrorText(status))
			s ^CacheTempPortalImport(coreNum) = 1
			q
		}
		
		s status=connection.AllocateStatement(.hstmt) 
		i $$$ISERR(status) {
			d ..ReportImportError("","Ошибка Connect в job: "_$system.Status.GetErrorText(status))
			s ^CacheTempPortalImport(coreNum) = 1
			q
		}
		
		//Prepare statement for execution
		; Исходный запрос для перекачки всей номенклатуры портала - торговые площадки, аптеки и т.д. без штрихкода
		s pQuery =	"select mnt.map_nomenclature_name, "_
						"nm.code_ctl 	As FeCode, "_
						"nm.code_mak 	As MakCode, "_
						"nm.src_code 	As CabCode, "_
						"mnt.id			As linkId, "_
						"tg.name		As NameSpace, "_
						"creation_label As creationLabel"_
					"from map_nomenclature_translation mnt "_
					"left join translation_grouping tg ON (tg.id = mnt.translation_grouping_id) "_
					"left join nomenclature nm ON (nm.id = mnt.nomenclature_id) "_
					"where mnt.map_nomenclature_code is not null "_
						"and mnt.map_nomenclature_name is not null "_
						"and mnt.map_nomenclature_name<>' [   ]' "_
						"and mnt.nomenclature_id is not null "_
					"order by mnt.id "
		
		
		; запрос переделан для задачи https://yt.esc.ru/issue/Alliance-1026 
		; добавлено условие and mnt.translation_grouping_id = 102 для перекачки номенклатуры только от Торговая_площадка:_АналитФармация
		s pQuery =	"select mnt.map_nomenclature_name, "_
						"nm.code_ctl 	As FeCode, "_
						"nm.code_mak 	As MakCode, "_
						"nm.src_code 	As CabCode, "_
						"mnt.id			As linkId, "_
						"tg.name		As NameSpace, "_
						"creation_label As creationLabel"_
					"from map_nomenclature_translation mnt "_
					"left join translation_grouping tg ON (tg.id = mnt.translation_grouping_id) "_
					"left join nomenclature nm ON (nm.id = mnt.nomenclature_id) "_
					"where mnt.map_nomenclature_code is not null "_
						"and mnt.map_nomenclature_name is not null "_
						"and mnt.map_nomenclature_name<>' [   ]' "_
						"and mnt.nomenclature_id is not null "_
						"and mnt.translation_grouping_id = 102"_ ; добавлено условие для перекачки номенклатуры только от Торговая_площадка:_АналитФармация
					"order by mnt.id "
		
		
		; запрос переделан для задачи https://yt.esc.ru/issue/Alliance-1026 
		; добавлено условие and mnt.translation_grouping_id = 102 для перекачки номенклатуры только от Торговая_площадка:_АналитФармация
		; добавлена перекаычка штрихкода
		s pQuery = "select mnt.map_nomenclature_name, "_
						"nm.code_ctl As FeCode, "_
						"nm.code_mak As MakCode, "_
						"nm.src_code As CabCode, "_
						"mnt.id      As linkId, "_
						"tg.name     As NameSpace, "_
						"creation_label As creationLabel, "_
						"barcodes.barcode AS barcode "_
					"from map_nomenclature_translation mnt "_
						"left join translation_grouping tg ON (tg.id = mnt.translation_grouping_id) "_
						"left join nomenclature nm ON (nm.id = mnt.nomenclature_id) "_
						"left join (select nomenclature_id, map_nomenclature_code barcode "_
									"from map_nomenclature_translation "_
									"where translation_grouping_id = 99) barcodes on barcodes.nomenclature_id = nm.id "_
						"where mnt.map_nomenclature_code is not null "_
						"and mnt.map_nomenclature_name is not null "_
						"and mnt.map_nomenclature_name <> ' [   ]' "_
						"and mnt.nomenclature_id is not null "_
						"and mnt.translation_grouping_id = "_idLink_" "_
					"order by mnt.id "
		
		
		s:limit>0 pQuery = pQuery_" limit "_limit
		s:offset>0 pQuery = pQuery_" offset "_offset
		s ^CacheTempPortalImport(coreNum,"query") = pQuery
		
		s status = connection.Prepare(hstmt,pQuery) 
		i $$$ISERR(status) {
			d ..ReportImportError("","Ошибка Prepare в job: "_$system.Status.GetErrorText(status))
			s ^CacheTempPortalImport(coreNum) = 1
			q
		}
		
		//Execute statement
		s status = connection.Execute(hstmt)
		i $$$ISERR(status) {
			d ..ReportImportError("","Ошибка Execute в job: "_$system.Status.GetErrorText(status))
			s ^CacheTempPortalImport(coreNum) = 1
			q
		}
		
		//Get list of columns returned by query
		s status = connection.DescribeColumns(hstmt, .columnlist) 
		i $$$ISERR(status) {
			d ..ReportImportError("","Ошибка DescribeColumns в job: "_$system.Status.GetErrorText(status))
			s ^CacheTempPortalImport(coreNum) = 1
			q
		}
		s numcols=$listlength(columnlist)-1
		
		s status = connection.Fetch(hstmt)
		i $$$ISERR(status) {
			d ..ReportImportError("","Ошибка Fetch в job: "_$system.Status.GetErrorText(status))
			s ^CacheTempPortalImport(coreNum) = 1
			q
		}
		
		while((connection.sqlcode'=100)) {
			s (name,feCode,barcode,codeCtl,mapNomCode,transGroupId,creationLabel,feNonem,makNomen,barcode) = ""
			s status = connection.GetData(hstmt, 1, 1, .name)
			s status = connection.GetData(hstmt, 2, 1, .feCode)
			s status = connection.GetData(hstmt, 3, 1, .makCode)
			s status = connection.GetData(hstmt, 4, 1, .cabCode)
			s status = connection.GetData(hstmt, 5, 1, .linkId)
			s status = connection.GetData(hstmt, 6, 1, .nameSpace)
			s status = connection.GetData(hstmt, 7, 1, .creationLabel)
			s status = connection.GetData(hstmt, 8, 1, .barcode)
			
			s name = $ZSTRIP($ZCVT(name,"i","CP1251"),"*C")
			s feCode = $ZSTRIP($ZCVT(feCode,"i","CP1251"),"*C")
			s makCode =  $ZSTRIP($ZCVT(makCode,"i","CP1251"),"*C")
			s cabCode =  $ZSTRIP($ZCVT(cabCode,"i","CP1251"),"*C")
			s linkId =  $ZSTRIP($ZCVT(linkId,"i","CP1251"),"*C")
			s nameSpace =  $ZSTRIP($ZCVT(nameSpace,"i","CP1251"),"*C")
			s creationLabel =  $ZSTRIP($ZCVT(creationLabel,"i","CP1251"),"*C")
			s:creationLabel="" creationLabel="hand"
			
			s str = name_" <-> "_feCode_" <-> "_makCode_" <-> "_cabCode_" <-> "_linkId_" <-> "_nameSpace_" <-> "_creationLabel_" <-> "_barcode

			s feNonem		= ##class(App.CTN.Nomen).OpenCode(feCode)
			d:'$ISO(feNonem) ..ReportImportError(price,"Нет каталожной номенклатуры с кодом "_feCode_" для ном-ры портала "_name_" id="_linkId)
			s makNomen 		= ##class(App.MAK.Nomen).OpenCode(makCode)
			d:'$ISO(makNomen) ..ReportImportError(price,"Нет МАК-номенклатуры с кодом "_makCode_" для ном-ры портала "_name_" id="_linkId)
						
			k ind,ptr,idNom
			s price = ""
						
			; идентификатор связки linkId - не гарантия уникальной позиции, поэтому присабачим штрихкод через тире
			s filter = [{"field":"Code","type":"=","data":(linkId_"-"_barcode)}]
			s err = ##class(App.PRC.Nomen).Filter(filter,.ind)
			i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
			while ##class(App.PRC.Nomen).indNEXT(.ind,.ptr,.idNom) {
				s price 	= ##class(App.PRC.Nomen).%OpenId(idNom)
				d ..ReportImportError("","Повторный linkId : "_str)
			}
			i '$ISO(price) {
				s price 	= ##class(App.PRC.Nomen).%New()
				s price.Code= linkId_"-"_barcode

			}
			
			s price.Name			= name
			s price.NameFirm		= nameSpace
			s price.TempIdMakNomen	= makCode
			s price.TempCabCode		= cabCode
			s price.idAgent			= contragent
			s price.SourceSys		= "Portal"
			s price.CreationLabel	= creationLabel
			s price.ZHK				= barcode
			s:$ISO(feNonem) price.idNomen = feNonem
			s:$ISO(makNomen) price.idMakNomen = makNomen
			s status = price.%Save()
			i $$$ISERR(status) {
				d ..ReportImportError(price,"Ошибка сохранения строки прайса с кодом "_makCode_" для ном-ры портала "_name_" id="_linkId)
			}
			
			i $I(^CacheTempPortalImport("full"))
	 		s status = connection.Fetch(hstmt)
	 		i $$$ISERR(status) {
				d ..ReportImportError("","Ошибка Fetch в job: "_$system.Status.GetErrorText(status))
			}
	  	}
	    
	    s ^CacheTempPortalImport(coreNum) = 1
	    
	  	//Close cursor and then disconnect
		set status=connection.CloseCursor(hstmt)
		i $$$ISERR(status) {
			d ..ReportImportError(price,"Ошибка разрыва соединения из job")
		}
	}
	catch exp {
		s ^CacheTempPortalImport(coreNum) = 1
		s err = ##class(Lib.Adam).ErrorDetect(.exp)
		d ..ReportImportError("",err)
	}
	
	w:$$$ISERR(status) "Status error:",$system.Status.GetErrorText(status)
	s ts2 = $ZTS
	w !,"Time elapsed:", ##class(Lib.Util.DateTime).DeltaMS(ts1,ts2)
	*/
}

/// Метод перекачивания номенклатуры из портала
/// Нужен запущенный SSH-тунель
/// idLink - id связок из таблицы соответствий на портале, идентификатор связок конкретного поставщика
/// w ##class(App.MAF.Linker).GetPortalNmByODBCParallel()
ClassMethod GetPortalNmByODBCParallel(idLink, idParamonContragent)
{
	/*
	i $G(idLink)="" {
		w !,"Укажите id связок из таблицы соответствий на портале"
		q
	}
	i $G(idParamonContragent)="" {
		w !,"Укажите id контрагента в Парамоне - владелец номенклатуры"
		q
	}
	
	s ts1 = $ZTS
 	s dsn = "portal"
	s user = "portal"
	s pwd = "system001"
	s timeout = 5
	
	k ^CacheTempPortalImport
	
	s connection = ##Class(%SQLGatewayConnection).%New()
	
	s status = connection.Connect(dsn,user,pwd,timeout)
	i $$$ISERR(status) {
		w $system.Status.GetErrorText(status)
		q
	}
	
	s status=connection.AllocateStatement(.hstmt) 
	i $$$ISERR(status) {
		w $system.Status.GetErrorText(status)
		q
	}
	
	//Prepare statement for execution
	// получение количества перекачиваемых номенклатур, всех, но без привязки к штрихкоду.
	// с привязкой к штриху будет больше
	s pQuery =	"select count(mnt.id) As rowcount "_
				"from map_nomenclature_translation mnt "_
				"where mnt.map_nomenclature_code is not null "_
				"and mnt.map_nomenclature_name is not null "_
				"and mnt.map_nomenclature_name<>' [   ]' "_
				"and mnt.nomenclature_id is not null "_
				"and mnt.translation_grouping_id = "_idLink
	
	// получение количества перекачиваемых номенклатур, всех, с привязкой к штриху		
	s pQuery =	"select count(foo.linkid) As rowcount "_$C(13,10)_
				"from (select mnt.map_nomenclature_name, "_$C(13,10)_
				             "nm.code_ctl      As FeCode, "_$C(13,10)_
				             "nm.code_mak      As MakCode, "_$C(13,10)_
				             "nm.src_code      As CabCode, "_$C(13,10)_
				             "mnt.id           As linkId, "_$C(13,10)_
				             "tg.name          As NameSpace, "_$C(13,10)_
				             "barcodes.barcode AS barcode "_$C(13,10)_
				      "from map_nomenclature_translation mnt "_$C(13,10)_
				             "left join translation_grouping tg ON (tg.id = mnt.translation_grouping_id) "_$C(13,10)_
				             "left join nomenclature nm ON (nm.id = mnt.nomenclature_id) "_$C(13,10)_
				             "left join (select nomenclature_id, map_nomenclature_code barcode "_$C(13,10)_
				                        "from map_nomenclature_translation "_$C(13,10)_
				                        "where translation_grouping_id = 99) barcodes on barcodes.nomenclature_id = nm.id "_$C(13,10)_
				      "where mnt.map_nomenclature_code is not null "_$C(13,10)_
				        "and mnt.map_nomenclature_name is not null "_$C(13,10)_
				        "and mnt.map_nomenclature_name <> ' [   ]' "_$C(13,10)_
				        "and mnt.nomenclature_id is not null "_$C(13,10)_
				        "and mnt.translation_grouping_id = "_idLink_") foo"
	w !,pQuery
	
	s status = connection.Prepare(hstmt,pQuery)
	i $$$ISERR(status) {
		w !,"Error Prepare", $system.Status.GetErrorText(status)
		q
	}
	s status = connection.Execute(hstmt) 
	i $$$ISERR(status) {
		w !,"Error Execute", $system.Status.GetErrorText(status)
		q
	}
	
	w !
	
	s rowCount = 0
	;w !,"rowCount = ",rowCount
	while((connection.Fetch(hstmt)) & (connection.sqlcode'=100)) {
		s status = connection.GetData(hstmt, 1, 1, .rowCount)
		w !,"status = ",status
		w !,"rowCount = ",rowCount
	}
	s status=connection.CloseCursor(hstmt)
	w !,"rowCount = ",rowCount
	s CPUinfo = ##class(%SYSTEM.CPU).%New()
	s flowsCount = CPUinfo.nCores * 2										; Количество потоков
	s limitPerCore = $NORMALIZE( ((rowCount / flowsCount) + 0.4), 0 )
	w !,"limitPerCore =",limitPerCore
	
	w !
			
	s offset = 0
	f coreCounter = 1:1:flowsCount {
		j ..GetPortalNmByODBC(limitPerCore,offset,coreCounter,idLink,idParamonContragent)		; Запуск джоба
		s offset = (limitPerCore * coreCounter) + 1							; Передвигаем стартовую позицию обработки для следующего джоба
		w !,"offset = ",offset
	}
	
	w !!
	
	s allJobsFinished = 0, jobError = ""									; Следим за финишем выполнения всех джобов
	while allJobsFinished = 0 {
		f coreNum=1:1:flowsCount {											; Перебираем флаги финиша обработки в темповой глобали
			s allJobsFinished = $G( ^CacheTempPortalImport(coreNum) )
			q:allJobsFinished=0												; Если хоть один не закончил - ждем дальше
		}
		HANG 0.1
		w $C(13),$G(^CacheTempPortalImport("full"))
	}
	
	s ts2 = $ZTS
	w !,"Time elapsed:", ##class(Lib.Util.DateTime).DeltaMS(ts1,ts2)
	q 1
	*/
}

/// Метод вычисления контрольной суммы для штрихкода без неё
/// w ##class(App.AGS.BarcodeLinker).NormalizeBarcode("0061 8414 3572")
ClassMethod NormalizeBarcode(ByRef barcode As Lib.DataTypes.String)
{
	/*
	s status = $$$OK
	try {
		;s barcode = ##class(App.MAF.StringPattern).regexp(barcode,"\D+","")
		s:$l(barcode)<6 status=$$$ERROR("Длина ЗШК="_barcode_" меньше 6-ти знаков.")
		s:$l(barcode)>13 status=$$$ERROR("Длина ЗШК="_barcode_" ,больше 12-ти знаков.")
		s:$l(barcode)=8 status=$$$ERROR("Длина ЗШК="_barcode_" ,равна 8-ти знаков.")
		s:(barcode'?.N) status=$$$ERROR("ЗШК="_barcode_" содержит не только цифры")
		q:$$$ISERR(status)
		
		q:$L(barcode)=13
		
		s evenSumm = 0	; сумма четных
		s oddSumm = 0	; сумма нечетных
		s summ = 0
		s barcodeWithCheckSumm = ""
		
		f i=1:1:$L(barcode){
			s:i#2=0 evenSumm = evenSumm+$E(barcode,i)
			s:i#2=1 oddSumm = oddSumm+$E(barcode,i)
		}
		
		s summ = (oddSumm) + (evenSumm*3)
		;s controlSumm = 10 - $E(summ,$L(summ)) - не правильный расчет Kalinin, 05/06/2018
		s controlSumm = (10-summ)#10
		s barcode = barcode_controlSumm
				
		i $l(barcode)=6  s barcode="00"_barcode		; ШК имеет 6 символов
		i $l(barcode)=7  s barcode="0"_barcode		; ШК имеет 7 символов
		i $l(barcode)=9  s barcode="0000"_barcode	; ШК имеет 9 символов
		i $l(barcode)=10 s barcode="000"_barcode	; ШК имеет 10 символов
		i $l(barcode)=11 s barcode="00"_barcode		; ШК имеет 11 символов
		i $l(barcode)=12 s barcode="0"_barcode		; ШК имеет 12 символов
	}
	catch exp {
		s status = $$$ERROR(..ErrorDetect(.exp))
	}
	q status
	*/
}

/// Метод получения ID словарных значений из одного словаря на основании строки
/// Вход:
/// 	in.str  		- строка 
/// 	in.propertyId	- id свойства онтологии, со значениями которого будем сравнивать слова из строки
/// Выход:
/// 	out.result 		= [{"dictValId":"1","value":"салфетки"},], где dictValId - id значения в словаре
ClassMethod GetDictValues(in, out)
{
	/*
	try {
		s out.result = []
		s err = ""
		s startTime = $ZTS
		s string = in.str
		s list = $LFS(string, " ")
		s propertyId = in.propertyId
		s:$ISO(propertyId) propertyId=propertyId.%Id()
		
		; Генерируем запрос ====================================================================
		s query = ""
		s query =	"SELECT idValue, value "_
					"FROM "_
					"( "
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->FulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->FulVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->ShrVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->ShrVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->NrFulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->NrFulVol) %STARTSWITH '"_word_"' OR "
			}
		}		
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL " 
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->LngVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->LngVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		
		s query = query_") ORDER BY $LENGTH(value) DESC"			
		
		;w !!,query,!!
		
		; Конец генерации запроса ==============================================================
		
		
		s statement	= ##class(%SQL.Statement).%New()
		s status	= statement.%Prepare(query)
		i status=$$$OK {
			s resultSet = statement.%Execute()
			WHILE resultSet.%Next() {
				s dictValLowCase = $ZCVT(resultSet.%Get("value"),"L")
				s dictValId		 = resultSet.%Get("idValue")
				;w !,string," [ ",dictValLowCase," = ",string[(dictValLowCase)
				
				i string[(dictValLowCase) {
					s string = $REPLACE(string, dictValLowCase, " ")
					d out.result.%Push({"idValue":(dictValId),"value":(dictValLowCase)}) ; result_resultSet.%Get("idValue")_","
				}
			}
		}
		else {
			;w !,"Error:",$system.Status.GetErrorText(status)
		}
		s finishTime = $ZTS
		
		;w ##class(Lib.Util.DateTime).DeltaMS(startTime,finishTime)
	}
	catch exp{
		s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q err
	*/
}

/// Метод возвращает строку из тех свойств номенклатуры, которые участвуют в метрике
/// Вход:
/// 		in.objToGetString	- объект, для которого необходимо получить строку
/// Выход:
/// 		resultString
/// 		out.error
Method GetString(in, out) As Lib.DataTypes.String
{
	/*
	/// k  s nom = ##Class(App.SPR.Nomenclature).%OpenId(161017),  metric = ##class(App.MAF.Metric).%OpenId(1)
	/// d metric.GetString(nom, out)

	s resultString = ""
	try {
		s nom = in.objToGetString
		i '$ISO(nom) {
			s out.error = "Empty object to recognize"
			q
		}
		d:in.log %log.%Push({"Info" : "<b>Get string to recognize :</b>"})
		
		; Хард для получения строки из прайса
		i nom.%ClassName(1)="App.PRC.Nomen" {
			s resultString = ..GetStringPRCNomen(in, out)
			q
		}
		else {
			s nom = in.objToGetString
			s resultString = resultString_" "_nom.SpecName
			d:in.log %log.%Push({"Info" : (resultString)})
		}
		
		; Хард для получения строки из номенклатуры
		i nom.%ClassName(1)="App.CTN.Nomen" {
			s resultString = ..GetStringCTNNomen(in, out)
			q
		}
		
		i nom.%ClassName(1)'="App.SPR.Nomenclature" {
			s out.error = "Class "_nom.%ClassName(1)_" is not currently supported."
			q
		}
		
		; ===============================================================
		; Код ниже на будущее
		; ===============================================================
		
		; Сначала выберем все значения свойств номенклатуры и занесем в индексированную переменную вида npv(id)=value, 
		; где id - идентификатор онтологического свойства App.SPR.NomProperty
		k indPropsVals, ptr,id, npv
		s npv = ""
		s filter = [{"field":"Nomenclature","type":"=","data":(nom.%Id())}]
		s err = ##Class(App.SPR.NomPropVal).Filter(filter,.indPropsVals)
		i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
		while ##class(App.SPR.NomPropVal).indNEXT(.indPropsVals,.ptr,.id) {
			s nomPropVal = ##class(App.SPR.NomPropVal).%OpenId(id)
			s npv(nomPropVal.NomProperty.%Id()) = nomPropVal.Value
		}
		; Теперь выберем онтологические свойства, присущие метрике, преберем их по OrderNum
		; и возмем значения этих свойств от номенклатуры из npv (выше)
		s:log out.log = out.log_$C(13,10)_"Get metric values of nomen properties:"_$C(13,10)
		s strListId = ""
		k indMetricProps, ptr, id
		s filter = [{"field":"Metric","type":"=","data":(..%Id())}]
		s err = ##Class(App.MAF.MetricNomProp).Filter(filter,.indMetricProps)
		i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
		while ##class(App.MAF.MetricNomProp).indNEXTsort(.indMetricProps,"OrderNum",1,1,.ptr,.id) {
			s metricProp = ##class(App.MAF.MetricNomProp).%OpenId(id)
			s:log out.log = out.log_$C(13,10)_metricProp.NomProperty.Name_" = "_$G(npv(metricProp.NomProperty.%Id()),"")
			s value = $G(npv(metricProp.NomProperty.%Id()),"")	
			s:value'="" resultString = resultString_" "_value
		}
		
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q resultString
	*/
}

/// Метод получения строки для сравнения из свойств номенклатуры класса App.CTN.Nomen
/// Вход:
/// 		in.objToGetString	- объект, для которого необходимо получить строку
ClassMethod GetStringCTNNomen(in, out)
{
	s resultString = ""
	try {
		s nom = in.objToGetString
		s resultString = resultString_" "_nom.SpecName ;_" "_nom.NameFirm_" "_nom.NameLand
		s:in.log out.log = out.log_resultString_$C(13,10)
	}
	catch exp {
		;s err = ..ErrorDetect(.exp)
		s out.error = err
		s status = $$$ERROR(err)	
	}
	q resultString
}

/// Метод получения ID словарных значений из одного словаря на основании строки
/// Вход:
/// 	in.str  		- строка 
/// 	in.propertyId	- id свойства онтологии, со значениями которого будем сравнивать слова из строки
/// Выход:
/// 	out.result 		= $LB(idval1,idval2...), где idval- id значения в словаре
ClassMethod GetListDictValIdsSQL(in, out)
{
	/*
	k q  s (in,out)={} 
	s in.str="уценка зоэли табл. п о мг n ср год organon v ирландия салфетки гель таблетки президент"
	s in.propertyId=44
	w ##class(App.MAF.Metric).GetDictValIds(in,out)
	*/
	try {
		s out.result = ""
		s result = ""
		s err = ""
		s startTime = $ZTS
		s string = in.str
		s list = $LFS(string, " ")
		s propertyId = in.propertyId
		s:$ISO(propertyId) propertyId=propertyId.%Id()
		
		; Генерируем запрос ====================================================================
		s query = ""
		s query =	"SELECT idValue, value "_
					"FROM "_
					"( "
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->FulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->FulVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->ShrVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->ShrVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->NrFulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->NrFulVol) %STARTSWITH '"_word_"' OR "
			}
		}		
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL " 
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->LngVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->LngVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		
		s query = query_") ORDER BY $LENGTH(value) DESC"			
		
		w !!,query,!!
		
		; Конец генерации запроса ==============================================================
		
		
		s statement	= ##class(%SQL.Statement).%New()
		s status	= statement.%Prepare(query)
		i status=$$$OK {
			s resultSet = statement.%Execute()
			WHILE resultSet.%Next() {
				s dictValLowCase = $ZCVT(resultSet.%Get("value"),"L")
				s dictValId		 = resultSet.%Get("idValue")
				
				w !,string," [ ",dictValLowCase," = ",string[(dictValLowCase)
				
				i string[(dictValLowCase) {
					s string = $REPLACE(string, dictValLowCase, " ")
					w !,"dictValId=",dictValId
					s $LI(result,*+1)=dictValId
				}
			}
		}
		else {
			;w !,"Error:",$system.Status.GetErrorText(status)
		}
		s out.result = result
		s finishTime = $ZTS
		
		w !,##class(Lib.Util.DateTime).DeltaMS(startTime,finishTime)
	}
	catch exp{
		;s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q err
}

/// Метод получения ID словарных значений на осовании строки
/// Вход:
/// 	in.str  	- строка 
/// 	in.property	- id свойства онтологии, со значениями которого будем сравнивать слова из строки
/// Выход:
/// 	строка из совпавших id через заапятую
/// s (in,out)={}  s in.str="уценка зоэли табл п о мг n ср год organon v ирландия"  s in.property=42  d ##class(App.MAF.Linker).GetDictValIds(in,out)
/// s (in,out)={}  s in.str="валерианы экстракт мг табл п о фармстандарт томскхимфарм,оао россия"  s in.property=42  d ##class(App.MAF.Linker).GetDictValIds(in,out)
ClassMethod GetStrDictValIdsSQL(in, out)
{
	try {
		k result
		s err = ""
		s string = in.str
		s list = $LFS(string, " ")
		s propertyId = in.property
		s:$ISO(propertyId) propertyId=propertyId.%Id()
		
		; Генерируем запрос ====================================================================
		s query = ""
		s query =	"SELECT idValue, value "_
					"FROM "_
					"( "
		s query = query_" SELECT DISTINCT idVol AS idValue, "_ ;================================
					"		idVol->FulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->FulVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		s query = query_" SELECT DISTINCT idVol AS idValue, "_ ;================================
					"		idVol->ShrVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->ShrVol) %STARTSWITH '"_word_"' OR "
			}
		}
		
		
		
		s query = $E(query,1,$L(query)-3)
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		s query = query_" SELECT DISTINCT idVol AS idValue, "_ ;================================
					"		idVol->NrFulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->NrFulVol) %STARTSWITH '"_word_"' OR "
			}
		}
		
		
		
		s query = $E(query,1,$L(query)-3)
		s query = query_") "
		s query = query_"UNION %PARALLEL " 
		s query = query_" SELECT DISTINCT idVol AS idValue, "_ ;================================
					"		idVol->LngVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->LngVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)
		s query = query_") "
		s query = query_") ORDER BY $LENGTH(value) DESC"			w !!,query,!!
		; Конец генерации запроса ==============================================================
		
		
		s statement	= ##class(%SQL.Statement).%New()
		s status	= statement.%Prepare(query)
		i status=$$$OK {
			s resultSet = statement.%Execute()
			WHILE resultSet.%Next() {
				s dictValLowCase = $ZCVT(resultSet.%Get("value"),"L")
				
				w !,string," [ ",dictValLowCase," = ",string[dictValLowCase
				
				i string[dictValLowCase {
					w !,"dictValLowCase =",dictValLowCase
					s string = $REPLACE(string, dictValLowCase, " ")
					s result = result_resultSet.%Get("idValue")_","
				}
			}
		}
		else {
			w !,"Error:",$system.Status.GetErrorText(status)
		}
		
		
	}
	catch exp{
		;s err = ..ErrorDetect(.exp)
	}
	q err
}

/// Метод получения ID словарных значений из одного словаря на основании строки
/// Вход:
/// 	in.str  		- строка 
/// 	in.propertyId	- id свойства онтологии, со значениями которого будем сравнивать слова из строки
/// Выход:
/// 	out.result 		= [{"dictValId":"1","value":"салфетки"},], где dictValId - id значения в словаре
ClassMethod GetArrDictValues(in, out)
{
	try {
		s out.result = []
		s err = ""
		s startTime = $ZTS
		s string = in.str
		s list = $LFS(string, " ")
		s propertyId = in.propertyId
		s:$ISO(propertyId) propertyId=propertyId.%Id()
		
		; Генерируем запрос ====================================================================
		s query = ""
		s query =	"SELECT idValue, value "_
					"FROM "_
					"( "
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->FulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->FulVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->ShrVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->ShrVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL "
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->NrFulVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->NrFulVol) %STARTSWITH '"_word_"' OR "
			}
		}		
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		s query = query_"UNION %PARALLEL " 
		
		s query = query_" SELECT DISTINCT idVol AS idValue, "_
					"		idVol->LngVol AS value "_
					"FROM App_CTN.NomenVol "_
					"WHERE idProp="_propertyId_" "_
					"AND ("
		f i=1:1:$LL(list){
			s word = $LG(list,i)
			i (word'="")&&(word'=" ")&&($L(word)>2) {
				s query = query_"LCASE(idVol->LngVol) %STARTSWITH '"_word_"' OR "
			}
		}
		s query = $E(query,1,$L(query)-3)						;================================
		s query = query_") "
		
		s query = query_") ORDER BY $LENGTH(value) DESC"			
		
		;w !!,query,!!
		
		; Конец генерации запроса ==============================================================
		
		
		s statement	= ##class(%SQL.Statement).%New()
		s status	= statement.%Prepare(query)
		i status=$$$OK {
			s resultSet = statement.%Execute()
			WHILE resultSet.%Next() {
				s dictValLowCase = $ZCVT(resultSet.%Get("value"),"L")
				s dictValId		 = resultSet.%Get("idValue")
				;w !,string," [ ",dictValLowCase," = ",string[(dictValLowCase)
				
				i string[(dictValLowCase) {
					s string = $REPLACE(string, dictValLowCase, " ")
					d out.result.%Push({"idValue":(dictValId),"value":(dictValLowCase)}) ; result_resultSet.%Get("idValue")_","
				}
			}
		}
		else {
			;w !,"Error:",$system.Status.GetErrorText(status)
		}
		s finishTime = $ZTS
		
		;w ##class(Lib.Util.DateTime).DeltaMS(startTime,finishTime)
	}
	catch exp{
		;s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q err
}

}

