/// Номенклатура кабинета с импортом из ФЕ
Class App.MAF.MakNomen Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// D ##class(App.MAF.MakNomen).SetCodeFromIdCabinet()
ClassMethod SetCodeFromIdCabinet()
{
	k ind,ptr,id
	s f=[{"field":"IdCabinet","type":">","data":"0"}]
	w f.%ToJSON()
	s err = ..Filter(.f,.ind)
	i err'="" w err q
	while ..indNEXT(.ind,.ptr,.id) {
		w !,id
		s o=..%OpenId(id)
		s o.Code = o.IdCabinet
		d o.%Save()
	}
}

/// d ##class(App.MAF.MakNomen).SetMakId()
ClassMethod SetMakId()
{
	try {
		s dsn = "cab-map"
		s user = "root"
		s pwd = "system001"
		s timeout = 5
		
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
		
		s count = 0
		k ind,ptr,id
		s filter = [{"field":"CodeMAK","type":">","data":"0"}]
		s err = ..Filter(filter,.ind)
		while ..indNEXT(.ind,.ptr,.id) {
			i $I(count)
			;q:count>1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			s makNomen = ..%OpenId(id)
			//Prepare statement for execution
			s pQuery =	"SELECT id,name "_$C(13,10)_
						"from nomenclature "_$C(13,10)_
						"where fe_import_uniqcode = "_makNomen.CodeMAK
			w !,pQuery
			
			s status = connection.Prepare(hstmt,pQuery) 
			q:$$$ISERR(status)
			
			//Execute statement
			s status = connection.Execute(hstmt)
			q:$$$ISERR(status)
			
			//Get list of columns returned by query
			s status = connection.DescribeColumns(hstmt, .columnlist) 
			q:$$$ISERR(status)
			s numcols=$listlength(columnlist)-1
			
			s status = connection.Fetch(hstmt)
			q:$$$ISERR(status)
			s rownum=1
			while((connection.sqlcode'=100)) {
				;q:rownum>100
				
				s (id) = ""
				s status = connection.GetData(hstmt, 1, 1, .id)
				s status = connection.GetData(hstmt, 2, 1, .name)
				;s status = connection.GetData(hstmt, 3, 1, .makCode)
				
				;s id = $ZCVT(id,"i","CP1251")
				;s name = $ZCVT(name,"o","UTF8")
				;s makCode =  $ZCVT(makCode,"i","CP1251")
				w makNomen.Name_" <-> "_makNomen.CodeMAK_" <-> "_name_" <-> "_id,!!
				s makNomen.IdCabinet = id
				s status = makNomen.%Save()
				d:$$$ISERR(status) ..ReportImportError(price,"Ошибка сохранения строки прайса")
				
				
		      	i $I(rownum)
		 		s status = connection.Fetch(hstmt)
		  	}
		    
		  	//Close cursor and then disconnect
			//set status=connection.CloseCursor(hstmt)
			q:$$$ISERR(status)
		}
	}
	catch exp {
		s err = ##class(Lib.Adam).ErrorDetect(.exp)
		d ..ReportImportError("",err)
		w !,"ERROR: ",err
	}
	
	w:$$$ISERR(status) "Status error:",$system.Status.GetErrorText(status)
}

/// D ##class(App.MAF.MakNomen).SetActual()
ClassMethod SetActual()
{
	s status = $$$OK
	try {
		; перебор мак-номенклатур в ФЭ
		s count = 0
		s class = "App.SOAP.FE.makNOMEN"		
		s outSOAP={}, inSOAP={},makNomenFE=""
		s ptrSOAP = ""
		k %objlasterror
		s inSOAP.filter = [{"field":"Code","type":">","data":"0"}]
		;s inSOAP.filter = [{"field":"IdNomen","type":">","data":"0"}]
		while ($CLASSMETHOD(class,"soapNEXT",.inSOAP,.outSOAP,.ptrSOAP,.makNomenFE))&&(outSOAP.error="") {
			/* makNomenFE
			+----------------- attribute values ------------------
			|                Act = "true"
			|               Code = 111708
			|              GNVLS = 0
			|           HashDubl = ""
			|              HashP = ""
			|                 ID = 111886
			|          IdDublNom = ""
			|             IdFirm = 13102
			|             IdLand = 172
			|         IdMainDubl = ""
			|              IdMnn = ""
			|              IdMsr = 14
			|            IdNomen = 68890
			|          IdProduct = ""
			|                Kol = ""
			|                NDS = 10
			|               Name = "Шпатель деревян. стерильн."
			|                 OA = 0
			|             ShName = "Шпатель  деревян. стерильн."
			|          TypeHashP = 1
			+-----------------------------------------------------
			*/
			
			/// For Debug /////////////////////////////////////////////
			w !,"outSOAP.error = ",outSOAP.error
			i $I(count)
			;q:count>10
			;zw makNomenFE
			w !,count
			;w !,inSOAP.SessionCookie
			///////////////////////////////////////////////////////////
			
			k ind,ptr,idNom	; если ном-ра с таким кодом уже есть - открываем, нет - создаем
			s nom = ""
			s filter = [{"field":"CodeMAK","type":"=","data":(makNomenFE.Code)}]
			s err = ..Filter(filter,.ind)
			i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
			while ..indNEXT(.ind,.ptr,.idNom) {
				s nom = ..%OpenId(idNom)
				
				;zw nom
				;w !
				
				s nom.SourceSys	= "FE"
				i makNomenFE.Act'="true" {
					d ..%DeleteId(.idNom)
					w !,"Deleted: ",nom.Name
				}
				else {
					s nom.Actual = 1
					s status = nom.%Save()
				}
			}
			
		}
		
		i $G(%objlasterror,"")'="" {
			d $System.Status.DecomposeStatus(%objlasterror,.list)
			w !,"Decomposed status : ",list(1)
		}
		
		;w !!!,"=======================",!,count,!,"======================="
		;s:outSOAP.err'="" status=$$$ERROR(outSOAP.err),out.error=outSOAP.err
	
	}
	catch exp {
		s err = ..ErrorDetect(exp)
		w "Fatal error:",err
		s status = $$$ERROR(err)
		d ..ReportImportError(makNomenFE,err)
	}
	q status
}

/// Метод импорта МАК-ноенклатуры из ФЭ
/// W $system.Status.GetErrorText( ##class(App.MAF.MakNomen).ImportMakNomenFromFE() )
ClassMethod ImportMakNomenFromFE()
{
	k
	s status = $$$OK
	try {
		; перебор мак-номенклатур
		s count = 0
		s class = "App.SOAP.FE.makNOMEN"		
		s outSOAP={}, ptrSOAP="",inSOAP={},makNomenFE=""
		s inSOAP.filter = 	[
								{"field":"Code","type":"=","data":"111708"}
							]
		;s inSOAP.filter = [{"field":"Code","type":"=","data":"771"}]
		while ($CLASSMETHOD(class,"soapNEXT",.inSOAP,.outSOAP,.ptrSOAP,.makNomenFE))&&(outSOAP.error="") {
			/* makNomenFE
			+----------------- attribute values ------------------
			|                Act = "true"
			|               Code = 111708
			|              GNVLS = 0
			|           HashDubl = ""
			|              HashP = ""
			|                 ID = 111886
			|          IdDublNom = ""
			|             IdFirm = 13102
			|             IdLand = 172
			|         IdMainDubl = ""
			|              IdMnn = ""
			|              IdMsr = 14
			|            IdNomen = 68890
			|          IdProduct = ""
			|                Kol = ""
			|                NDS = 10
			|               Name = "Шпатель деревян. стерильн."
			|                 OA = 0
			|             ShName = "Шпатель  деревян. стерильн."
			|          TypeHashP = 1
			+-----------------------------------------------------
			*/
			
			/// For Debug /////////////////////////////////////////////
			i $I(count)
			q:count>1
			zw makNomenFE
			w !,count
			
			;w !,inSOAP.SessionCookie
			
			///////////////////////////////////////////////////////////
			
			k ind,ptr,idNom	; если ном-ра с таким кодом уже есть - открываем, нет - создаем
			s nom = ""
			s filter = [{"field":"CodeMAK","type":"=","data":(makNomenFE.Code)}]
			s err = ..Filter(filter,.ind)
			i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
			while ..indNEXT(.ind,.ptr,.idNom) {
				s nom = ..%OpenId(idNom)
			}
			i '$ISO(nom) {
				s nom = ..%New()
			}
			
			s nom.CodeMAK		= makNomenFE.Code
			s nom.Name			= makNomenFE.Name
			s nom.CountryCode	= makNomenFE.IdLand
			s nom.ProducerCode	= makNomenFE.IdFirm
			s nom.CodeCatalogFE	= makNomenFE.IdNomen
			
			
			i 'nom.SetCountryName(makNomenFE,inSOAP.SessionCookie) {
				s errText = "Ошибка при присваивании страны"
				d ..ReportImportError(makNomenFE,errText)
			}
			
			i 'nom.SetProducerName(makNomenFE,inSOAP.SessionCookie) {
				s errText = "Ошибка при присваивании наименования производителя"
				d ..ReportImportError(makNomenFE,errText)
			}
			
			i 'nom.SetBarcode(makNomenFE,inSOAP.SessionCookie){
				s errText = "Ошибка при присваивании штрихкода"
				d ..ReportImportError(makNomenFE,errText)
			}
			
			s status = nom.%Save()
		}
		
		i $G(%objlasterror,"")'="" {
			d $System.Status.DecomposeStatus(%objlasterror,.list)
			w !,"Decomposed status : ",list(1)
		}
		
		;w !!!,"=======================",!,count,!,"======================="
		;s:outSOAP.err'="" status=$$$ERROR(outSOAP.err),out.error=outSOAP.err
	
	}
	catch exp {
		s err = ..ErrorDetect(exp)
		s status = $$$ERROR(err)
		d ..ReportImportError(makNomenFE,err)
	}
	q status
}

/// Метод запрашивает в ФЭ краткое название страны по коду и присваивает свойству CountryName
Method SetCountryName(makNomenFE, sessionCookie)
{
	s status = $$$OK
	try {
		/*	makCountry
		+----------------- attribute values ------------------
		|               Code = 643
		|                 ID = 172
		|             IdSour = 172
		|             Import = "false"
		|               Name = "РОССИЙСКАЯ ФЕДЕРАЦИЯ"
		|            NameLat = ""
		|          NameLatSh = "RUS"
		|             NameSh = "РОССИЯ"
		|               OKSM = 643
		+-----------------------------------------------------
		*/
		s method = "soapNEXT"
		s class = "App.SOAP.FE.makCOUNTRY"
		s (in,out) = {}, ptr = "", makCountry=""
		s in.SessionCookie = sessionCookie
		s in.filter = [{"field":"IdSour", "type":"=", "data":(makNomenFE.IdLand)}]
		while ($CLASSMETHOD(class, method, .in, .out, .ptr, .makCountry))&&(out.error="") {
			s ..CountryName = makCountry.NameSh
		}
	}
	catch exp {
		d:$G(%objlasterror,"")'="" $System.Status.DecomposeStatus(%objlasterror,.list)
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err_list(1))
	}
	q status
}

/// Метод запрашивает в ФЭ краткое название производителя по коду и присваивает свойству ProducerName
Method SetProducerName(makNomenFE, sessionCookie)
{
	s status = $$$OK
	try{
		/*	makManufId
		+----------------- attribute values ------------------
		|               Code = 13233
		|                 ID = 12703
		|             IdLand = 172
		|             IdSour = 13102
		|             Import = "false"
		|               Name = "Ирбис ООО"
		|            NameLat = ""
		|          NameLatSh = ""
		|             NameSh = "Ирбис"
		+-----------------------------------------------------
		*/
		s method = "soapNEXT"
		s class = "App.SOAP.FE.makPRODUCER"
		s (in,out) = {}, ptr = "", makPoducer=""
		s in.SessionCookie = sessionCookie
		s in.filter = [{"field":"IdSour", "type":"=", "data":(makNomenFE.IdFirm)}]
		while ($CLASSMETHOD(class, method, .in, .out, .ptr, .makPoducer))&&(out.error="") {
			s ..ProducerName = makPoducer.NameSh
		}
	}
	catch exp{
		d:$G(%objlasterror,"")'="" $System.Status.DecomposeStatus(%objlasterror,.list)
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err_list(1))
	}
	q status
}

Method SetBarcode(makNomenFE, sessionCookie)
{
	s status = $$$OK
	try{
		s method = "soapNEXT"
		s class = "App.SOAP.FE.makBARCODE"
		s (in,out) = {}, ptr = "", barcode = ""
		s in.SessionCookie = sessionCookie
		s in.filter = [{"field":"IdMakNom", "type":"=", "data":(makNomenFE.ID)}]
		while ($CLASSMETHOD(class, method, .in, .out, .ptr, .barcode))&&(out.error="") {
			s:$ISO(barcode) ..Barcode = barcode.ZHK
		}
		;s:out.err'="" status=$$$ERROR(out.err)
	}
	catch exp{
		d:$G(%objlasterror,"")'="" $System.Status.DecomposeStatus(%objlasterror,.list)
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err_list(1))
	}
	q status
}

/// Рапорт об ошибке импорта в протокол ошибок импорта
ClassMethod ReportImportError(makNomenFE, errText)
{
	s status = $$$OK
	try {
		s objErr		= ##class(Lib.App.ImportError).%New()
		s objErr.Date	= $p($h, ",", 1)												; Дата события
		s objErr.Time	= $p($h, ",", 2)												; Время события
		s objErr.Error	= errText														; Ошибка
		d ##class(Lib.App.User).GetIdByName($USERNAME, .idUser)
		s objErr.User	= $case(idUser, "":"", :##class(Lib.App.User).%OpenId(idUser))	; Пользователь
		s objErr.Value	= ##class(Lib.Util.JSON).ObjToJSON(makNomenFE).%ToJSON()		; Данные объекта, на импорте которого возникла ошибка
		s status = objErr.%Save()
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err)
	}
	q status
}

/// Kalinin A.M.
/// Для поиска аналогов позициям прайса <br>
/// !!! НЕ УДАЛЯТЬ !!!
Property SpecName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Kalinin A.M.
/// Метод формирования описания для поиска и сравнения
/// !!! НЕ УДАЛЯТЬ !!!
/// s n=##class(App.MAF.MakNomen).%OpenId(4792)  d n.setSpecName()
Method setSpecName()
{
	try {
		s err = ""
		
		s specName = ..Barcode_" "_..Name_" "_..ProducerName_" "_..CountryName
		s specName = $ZSTRIP(specName,"=W")
		;w !,specName
		
		s matcher = ##class(%Regex.Matcher).%New("(?<=\D)\.(?=\d)",specName)
		s specName = matcher.ReplaceAll(". ") 								; сокращения с точками отделяем пробелами от чисел, "шамп.280 Пит.,укреп." => "шамп. 280 Пит.,укреп."
		;w !,specName
		
		s specName = ##class(App.SPR.Synonym).OriginaliseStringV3(specName)	; Замена синонимов оригиналами
		;w !,specName
		
		s out = {}
		s ..SpecName = ##class(App.MAF.Linker).DeleteDublicateWords(specName, out) ; удаление повторяющихся пробелов
		;w !,..SpecName
		
		d ..%Save()
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		w err
	}
	q err
}

/// Установка специального наименования для поиска у всех каталожных позиций
/// d ##class(App.MAF.MakNomen).SetAllSpecName()
ClassMethod SetAllSpecName()
{
	s ts1 = $ZTS
	
	k ptr,id
	s count = 0
	while ..indNEXT([(..#indAll)],.ptr,.id) {
		i $I(count)
		;q:count>10
		w !,id
		s nomen = ..%OpenId(id)
		d nomen.setSpecName()
		w $C(9),nomen.SpecName
	}
	s ts2 = $ZTS
	w "Time elapsed:", ##class(Lib.Util.DateTime).DeltaMS(ts1,ts2)
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 0;

/// Виртуальный
Parameter Virtual = 0;

/// Наименование
Property Name As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Код
Property Code As Lib.DataTypes.Integer(IndexValue = 1);

/// Каталожный код из ФЭ
Property CodeCatalogFE As Lib.DataTypes.Integer(IndexValue = 1);

/// Код МАК, присвоенный в ФЭ
Property CodeMAK As Lib.DataTypes.Integer(IndexValue = 1);

/// Код позиции в кабинете
Property CodeCabinet As Lib.DataTypes.Integer(IndexValue = 1);

/// Id позиции в кабинете
Property IdCabinet As Lib.DataTypes.Integer(IndexValue = 1);

/// Штрихкод
Property Barcode As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Код товара в кабинете
Property CodeCabinetProduct As Lib.DataTypes.Integer(IndexValue = 1);

/// Название страны
Property CountryName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Код страны из ФЭ
Property CountryCode As Lib.DataTypes.Integer(IndexValue = 1);

/// Наименование производителя
Property ProducerName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Код производителя из ФЭ
Property ProducerCode As Lib.DataTypes.Integer(IndexValue = 1);

/// Наименовние контрагента
Property ContragentName As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

/// Актуальность позиции
Property Actual As Lib.DataTypes.String(IndexSpecValue = 1, IndexSpecWord = 1, IndexValue = 1, IndexWord = 1, MAXLEN = 1024);

Index Actual On Actual As Truncate(200) [ Type = bitmap ];

Index IdCabinet On IdCabinet As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CodeCatalogFE On CodeCatalogFE As Truncate(200) [ Type = bitmap ];

Index CodeMAK On CodeMAK As Truncate(200) [ Type = bitmap ];

Index CodeCabinet On CodeCabinet As Truncate(200) [ Type = bitmap ];

Index Barcode On Barcode As Truncate(200) [ Type = bitmap ];

Index CodeCabinetProduct On CodeCabinetProduct As Truncate(200) [ Type = bitmap ];

Index CountryName On CountryName As Truncate(200) [ Type = bitmap ];

Index ProducerName On ProducerName As Truncate(200) [ Type = bitmap ];

Index ContragentName On ContragentName As Truncate(200) [ Type = bitmap ];

Index ProducerCode On ProducerCode As Truncate(200) [ Type = bitmap ];

Index CountryCode On CountryCode As Truncate(200) [ Type = bitmap ];

Parameter XMLTYPE = "App-MAF-MakNomen";

Storage Default
{
<Data name="MakNomenDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>CodeCatalogFE</Value>
</Value>
<Value name="4">
<Value>CodeMAK</Value>
</Value>
<Value name="5">
<Value>CodeCabinet</Value>
</Value>
<Value name="6">
<Value>Barcode</Value>
</Value>
<Value name="7">
<Value>CodeCabinetProduct</Value>
</Value>
<Value name="8">
<Value>CountryName</Value>
</Value>
<Value name="9">
<Value>ProducerName</Value>
</Value>
<Value name="10">
<Value>GUID</Value>
</Value>
<Value name="11">
<Value>Vers</Value>
</Value>
<Value name="12">
<Value>ContragentName</Value>
</Value>
<Value name="13">
<Value>CountryCode</Value>
</Value>
<Value name="14">
<Value>ProducerCode</Value>
</Value>
<Value name="15">
<Value>SourceSys</Value>
</Value>
<Value name="16">
<Value>SpecName</Value>
</Value>
<Value name="17">
<Value>IdCabinet</Value>
</Value>
<Value name="18">
<Value>Code</Value>
</Value>
<Value name="19">
<Value>Actual</Value>
</Value>
</Data>
<DataLocation>^App.MAF.MakNomenD</DataLocation>
<DefaultData>MakNomenDefaultData</DefaultData>
<IdLocation>^App.MAF.MakNomenD</IdLocation>
<IndexLocation>^App.MAF.MakNomenI</IndexLocation>
<StreamLocation>^App.MAF.MakNomenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

