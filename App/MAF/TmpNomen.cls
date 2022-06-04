/// Временный класс для проверки правильности привязок номенклатур из партий и номенклатуры кабинета
Class App.MAF.TmpNomen Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Код аптеки
Property PrtPharmacyCode As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Штрихкод в партии
Property PrtBarcode As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Наименование в партии
Property PrtName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Штрихкод из кабинета
Property CabBarcode As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Наименование из кабинета
Property CabName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Производитель из кабиента
Property CabProducer As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Признак неверной связки
Property LinkError As Lib.DataTypes.Boolean(IndexValue = 1);

/// Сходимость по n-gramm
Property Ngramm As Lib.DataTypes.Double(IndexValue = 1, IndexWord = 1);

/// Сходимость по числам
Property Meas As Lib.DataTypes.Double(IndexValue = 1, IndexWord = 1);

/// Сходимость по штриху
Property BarSimil As Lib.DataTypes.Double(IndexValue = 1, IndexWord = 1);

/// Общий коэфициент
Property CommonKoef As Lib.DataTypes.Double(IndexValue = 1, IndexWord = 1);

Index PrtPharmacyCode On PrtPharmacyCode As Truncate(200) [ Type = bitmap ];

Index PrtBarcode On PrtBarcode As Truncate(200) [ Type = bitmap ];

Index PrtName On PrtName As Truncate(200) [ Type = bitmap ];

Index CabBarcode On CabBarcode As Truncate(200) [ Type = bitmap ];

Index CabName On CabName As Truncate(200) [ Type = bitmap ];

Index CabProducer On CabProducer As Truncate(200) [ Type = bitmap ];

Index LinkError On LinkError As Truncate(200) [ Type = bitmap ];

Index Ngramm On Ngramm As Truncate(200) [ Type = bitmap ];

Index Meas On Meas As Truncate(200) [ Type = bitmap ];

Index CommonKoef On CommonKoef As Truncate(200) [ Type = bitmap ];

Parameter XMLTYPE = "App-MAF-TmpNomen";

/// d ##class(App.MAF.TmpNomen).Check()
ClassMethod Check()
{
	try {
		s recCount = 0
		s out = {}
		k ind,ptr,id
		s filter = 	[
						{"field":"PrtPharmacyCode","type":"'=","data":""}
					]
		s err = ..Filter(filter,.ind)
		i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
		while ..indNEXT(.ind,.ptr,.id){
			i $I(recCount)
			;q:recCount>10
			
			s rec = ..%OpenId(id)
			/*
			s strToRecognize = ##class(App.SPR.Synonym).OriginaliseStringV3(rec.PrtName)
			s strToCompare = ##class(App.SPR.Synonym).OriginaliseStringV3($REPLACE(rec.CabName,rec.CabProducer,""))
			
			s nGgramMetric = ##class(App.MAF.Metric).%OpenId(1)									; Открываем метрики
			s in = {}, in.str = strToRecognize, ngrammStrToRecognize = nGgramMetric.ApplyPatterns(in, out)
			s in = {}, in.str = strToCompare, ngrammStrToCompare = nGgramMetric.ApplyPatterns(in, out)
			s ngStrToRecognizeNoDbl = ##class(App.MAF.Linker).DeleteDublicateWords(ngrammStrToRecognize,out)
			s ngStrToCompareNoDbl = ##class(App.MAF.Linker).DeleteDublicateWords(ngrammStrToCompare,out)
			s nGrammKoef = ##class(App.MAF.Metric).nGramm(ngStrToRecognizeNoDbl, ngStrToCompareNoDbl, 3)/100
			
			s numMetric = ##class(App.MAF.Metric).%OpenId(2)
			s in = {}, in.str = strToRecognize, numStrToRecognize = numMetric.ApplyPatterns(in, out)
			s in = {}, in.str = strToCompare, numStrToCompare = numMetric.ApplyPatterns(in, out)
			s numKoef = $NORMALIZE( ##class(App.MAF.Metric).MeasurablePropsSimilarity(numStrToRecognize, numStrToCompare), 2)/100
			
			s:(rec.CabBarcode'="")&&(rec.PrtBarcode'="")&&(rec.CabBarcode[rec.PrtBarcode) barKoef=1
			s:(rec.CabBarcode="")!(rec.PrtBarcode="") barKoef = 0.5
			s:(rec.CabBarcode'="")&&(rec.PrtBarcode'="")&&'(rec.CabBarcode[rec.PrtBarcode) barKoef=0
			
			s numOfMetrics = 3
			s wNG 	= 1.4																							; Весы коэфициентов метрик. Изначально каждый равен 1, и их сумма равна количеству коэфициентов
			s wNum	= 0.8
			s wBar	= 0.8
			s commonKoef = $NORMALIZE( ( ( (nGrammKoef*wNG) + (numKoef*wNum) + (barKoef*wBar) ) / numOfMetrics  ) * 100, 2)
			
			s rec.BarSimil = barKoef
			s rec.Meas = numKoef
			s rec.Ngramm = nGrammKoef
			s rec.CommonKoef = commonKoef
			s rec.LinkError = 0
			*/
			s rec.LinkError=0
			s:rec.CommonKoef<68 rec.LinkError=1
			s status = rec.%Save()
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		w "Error:",err
		
	}
	q
}

Storage Default
{
<Data name="TmpNomenDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PrtPharmacyCode</Value>
</Value>
<Value name="3">
<Value>PrtBarcode</Value>
</Value>
<Value name="4">
<Value>PrtName</Value>
</Value>
<Value name="5">
<Value>CabBarcode</Value>
</Value>
<Value name="6">
<Value>CabName</Value>
</Value>
<Value name="7">
<Value>CabProducer</Value>
</Value>
<Value name="8">
<Value>Vers</Value>
</Value>
<Value name="9">
<Value>GUID</Value>
</Value>
<Value name="10">
<Value>LinkError</Value>
</Value>
<Value name="11">
<Value>Ngramm</Value>
</Value>
<Value name="12">
<Value>Meas</Value>
</Value>
<Value name="13">
<Value>BarSimil</Value>
</Value>
<Value name="14">
<Value>CommonKoef</Value>
</Value>
<Value name="15">
<Value>SourseSys</Value>
</Value>
<Value name="16">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.MAF.TmpNomenD</DataLocation>
<DefaultData>TmpNomenDefaultData</DefaultData>
<IdLocation>^App.MAF.TmpNomenD</IdLocation>
<IndexLocation>^App.MAF.TmpNomenI</IndexLocation>
<StreamLocation>^App.MAF.TmpNomenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

