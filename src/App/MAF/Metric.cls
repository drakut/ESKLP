/// Класс различных метрик для стравнения строк и т.д.
Class App.MAF.Metric Extends %Persistent
{

Parameter XMLTYPE = "App-MAF-Metric";

/// Обработка ошибки
ClassMethod ErrorDetect(ByRef exp) As %String
{
	s err=""
	if exp.Code'=999{
		d exp.Log()
		if exp.Name["<PROTECT>" {s err="У пользователя "_$USERNAME_" нет прав на создание, изменение, удаление данных."}
		elseif exp.%IsA("%Exception.SystemException") {s err="Ошибка : "_$ZCVT(exp.Name,"O","HTML")_". Адрес : "_exp.Location_". Код : "}
		elseif exp.%IsA("%Exception.SQL") {s err="Ошибка SQL. Код : "}
		elseif exp.%IsA("%Exception.StatusException") {s err="Статус : "_$SYSTEM.Status.DisplayError($SYSTEM.Status.Error(exp.Code,exp.Data)) return}
		elseif exp.%IsA("%Exception.General") {s err="Глобальная ошибка : "_$ZCVT(exp.Name,"O","HTML")_". Код : "}
		else {s err="Неизвестная ошибка." return}
		//s st=$STACK($ST,"PLACE")
		//s st="" for i=0:1:$STACK(-1) {s st=st_$STACK(i,"PLACE")_", "}
		s:exp.Name'["<PROTECT>" err=err_exp.Code_". Строка : "_exp.Data //_". Стек : <br>"_st
	}
	else{s err=exp.Data}
	q err
}

/// Получение метрики схожести методом N-грамм
/// Вход:
/// 	str1 =	{				
/// 				"valueList"	: "ШИНА ЛЕГКОВОГО АВТОМОБИЛЯ"	- строка, полученная путем вычислений паттернов метрики
/// 				"useInKeywords" : "no"						- как использовать результирующую строку метрики: no,all,shortest,longest
/// 			}
/// 	str2 =	{				
/// 				"valueList"	: "ШИНА ЛЕГКОВОГО АВТОМОБИЛЯ"	- строка, полученная путем вычислений паттернов метрики
/// 				"useInKeywords" : "no"						- как использовать результирующую строку метрики: no,all,shortest,longest
/// 			}
/// 	str2 = "ШИНА СЕЛЬСКОХОЗЯЙСТВЕННОЙ    МАШИНЫ«»~`!@#№$;%:^?&*()_-=+/\|{[}]:;'"",<.>/?®™"
/// 	params = строка JSON вида {"grammLength":"3"}, не объект, со свойством grammLength - длина граммы
/// 
ClassMethod nGramm(str1, str2, params, out)
{
	try{
		; w ##class(App.MAF.Metric).nGramm(str1, str2, grammsLength)
		
		s str1 = str1.valueList
		s:$ISO(str2) str2=str2.valueList
		s N = 2	; длинна граммы
		s result = 0
		
		s:($G(params)'="")&&('$ISO(params)) params = {}.%FromJSON(params)
		s:'$ISO(params)&&(params.%IsDefined("grammLength")) N = params.grammLength 
		
		s:$L(str1)<$L(str2) buf = str1, str1 = str2, str2 = buf
		s lengthSource = $L(str1)
		s lengthWord = $L(str2)
		s str2 = str2_" "
		
		f i=1:1:lengthSource-N+1 {
			s grammaSource = $E(str1, i, i+N-1)
			s:(i+N-1)>lengthSource grammaSource=grammaSource_" "

			f j=1:1:lengthWord-N+1 {
				s grammaWord = $E(str2, j, j+N-1)
				s:(j+N-1)>lengthWord grammaWord=grammaWord_" "
				i grammaWord=grammaSource {
					s result = result + 1
					q
				}
			}
		}
		s result = $NORMALIZE(   ( (result*2) / (lengthWord-N+1 + lengthSource-N+1) ), 2 )
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s ^CacheTempError($I(^CacheTempError),"nGramm","fatal") = err
	}
	
	q result
}

/// Метод возвращает процент совпавших чисел из первой строки (source) с числами из второй строки (word)
/// В обеих строках заменяются "," на "."
/// Не числовые значения не сравниваются
/// Вход:
/// 	source	- {				
/// 				"valueList"	: "знач1"					- строка, полученная путем вычислений паттернов метрики
/// 				"useInKeywords" : "no"					- как использовать результирующую строку метрики: no,all,shortest,longest
/// 		  	  }
/// 	word	- строка с числами, разделенных пробелами
/// Выход:
/// 		equalPercent
/// w ##class(App.AGS.Germes).MeasurablePropsSimilarity(source,word)
ClassMethod SimpleSimula(source, word, params, out)
{
	s equalPercent = 0
	s equalNumbers = 0
	s countSourceNums = 0
	
	s source = source.valueList
	i $ISO(word) {
		s word = word.valueList
	}
	i (source="")||(word="") {
		s equalPercent = -1
		q equalPercent
	}
	
	s list1 = $LFS(source, " ")
	s list2 = $LFS(word, " ")
			
	f i=1:1:$LL(list1) {
		s sourceNum = $LG(list1,i)			;w !,"sourceNum="_sourceNum
		continue:'$ISVALIDNUM(sourceNum)	;w " is valid num"
		i $I(countSourceNums)
		
		f j=1:1:$LL(list2) {
			s wordNum = $LG(list2,j)		;w !,"wordNum=",wordNum
			;s:(wordNum["x")&&(wordNum["x")&&(wordNum["x")&&(wordNum["x") wordNum=$P(wordNum,"")
			
			continue:'$ISVALIDNUM(wordNum)	;w " is valid num"
			i +sourceNum=+wordNum {			;w !,sourceNum,"=",wordNum," : ",+sourceNum=+wordNum
				i $I(equalNumbers)
				s $LI(list2,j)=""				
				q
			}
		}
	}
	;w !
	s:countSourceNums>0 equalPercent =  $NORMALIZE(equalNumbers/countSourceNums,2)
	q equalPercent
}

/// Метод возвращает вероятность совпадения 2 поданных штрихкодов
/// Вход:
/// 	str1 - строка 1
/// 		str2 - строка 2
/// Выход:
/// 	-1, 0, 1	
/// w ##class(App.MAF.Metric).BarcodeSimilarity(12345678, 12345678)
ClassMethod BarcodeSimilarity(str1 = "", str2 = "")
{
	s barcode1 = ""
	s matcher = ##class(%Regex.Matcher).%New("(\d{13}|\d{8})", str1)
	while matcher.Locate() {		s barcode1 = barcode1_" "_matcher.Group	}
	s barcode1 = $ZSTRIP(barcode1, "<=>W",,)
	
	s barcode2 = ""
	s matcher = ##class(%Regex.Matcher).%New("(\d{13}|\d{8})", str2)
	while matcher.Locate() {		s barcode2 = barcode2_" "_matcher.Group	}
	s barcode2 = $ZSTRIP(barcode2, "<=>W",,)
	
	s n1 = +barcode1
	s n2 = +barcode2
	q:(n1=0)||(n2=0) -1  ; если хоть один пуст - то вероятность совпадения ЗШК -1 и дальше не учитываем
	i (n1=n2) {
		q 1
	} 
	else {
		q 0
	}
}

/// Метод возвращает равенство и (или нет) двух строк
/// Вход:
/// 	str1	- {				
/// 				"valueList"	: "знач1"					- строка, полученная путем вычислений паттернов метрики
/// 				"useInKeywords" : "no"					- как использовать результирующую строку метрики: no,all,shortest,longest
/// 			  }
/// 	str2	- строка 2
/// Выход:
/// 	-1, 0, 1	
/// w ##class(App.MAF.Metric).BarcodeSimilarity(12345678, 12345678)
ClassMethod WordSimil(str1 = "", str2 = "", params, out)
{
	s str1 = str1.valueList
	i $ISO(str2) {
		s str2 = str2.valueList
	}
	q:(str1 = "")!(str2 = "") -1
	i (str1 = str2) {
		q 1
	} 
	else {
		q 0
	}
}

ClassMethod Simula(str1, str2, params, out)
{
	q:(str1.valueList="")||(str2="") -1
	
	s result	= 0
	s sourEqual	= 0
	s candEqual = 0
	s sourList 	= $LFS(str1.valueList, " ")
	i $ISO(str2){
		s candList = $LFS(str2.valueList, " ")
	}
	else {
		s candList = $LFS(str2, " ")
	}
		
	f i=1:1:$LL(sourList) {
		s word = $LG(sourList, i)			;w !,"sourceNum="_sourceNum
		continue:word=""
		s:$LF(candList, word) sourEqual=sourEqual+1
	}
	
	f i=1:1:$LL(candList) {
		s word = $LG(candList, i)			;w !,"sourceNum="_sourceNum
		continue:word=""
		s:$LF(sourList, word) candEqual=candEqual+1
	}
	s sourVal = 0
	s:$LL(sourList)>0 sourVal = sourEqual/$LL(sourList)
	
	s candVal = 0
	s:$LL(candList)>0 candVal = candEqual/$LL(candList)
	
	s result = ( sourVal + candVal )/2
	s result = $NORMALIZE(result, 2)
	q result
}

Storage Default
{
<Data name="MetricDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Vers</Value>
</Value>
<Value name="5">
<Value>GUID</Value>
</Value>
<Value name="6">
<Value>MethodName</Value>
</Value>
<Value name="7">
<Value>DictClassName</Value>
</Value>
<Value name="8">
<Value>DictFieldName</Value>
</Value>
<Value name="9">
<Value>SourseSys</Value>
</Value>
<Value name="10">
<Value>SourceSys</Value>
</Value>
<Value name="11">
<Value>Weight</Value>
</Value>
<Value name="12">
<Value>Params</Value>
</Value>
</Data>
<DataLocation>^App.MAF.MetricD</DataLocation>
<DefaultData>MetricDefaultData</DefaultData>
<IdLocation>^App.MAF.MetricD</IdLocation>
<IndexLocation>^App.MAF.MetricI</IndexLocation>
<StreamLocation>^App.MAF.MetricS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// Class App.MAF.Metric Extends %Persistent
Property Description As %Library.String(MAXLEN = 1024);

/// Класс таблицы словаря
Property DictClassName As %Library.String(MAXLEN = 1024);

/// Поле таблицы словаря со значением
Property DictFieldName As %Library.String(MAXLEN = 1024);

/// Наименование метода для обработки
Property MethodName As %Library.String(MAXLEN = 1024);

/// Наименование метрики
Property Name As %Library.String(MAXLEN = 1024);

/// Параметры выполнения метода, массив JSON
Property Params As %Library.String(MAXLEN = 32000);

/// Вес метрики
Property Weight As %Library.Double;

Index Description On Description As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

}

