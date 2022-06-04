/// Класс паттернов обработки тектовой строки
Class App.MAF.StringPattern Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Виртуальный
Parameter Virtual = 0;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Название выражения
Property Name As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024) [ Required ];

/// Класс номенклатуры
/// Property NomenClass As App.AGS.ClassList;
Property NomenClass As %String;

/// Контрагент, поставщик прайса
Property Agent As App.PRC.Agent;

/// Способ выражения для преобразования строки
Property CodeType As Lib.DataTypes.String(DISPLAYLIST = ",Регулярное выражение,Cache $ZSTRIP,Cache $ZCVT,Cache $REPLACE,Cache $TRANSLATE,Метод класса", IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024, VALUELIST = ",regexp,zstrip,zcvt,replace,translate,classMethod") [ Required ];

/// Регулярное выражение, только для паттернов типа regexp
Property Expression As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, MAXLEN = 1024);

/// Строка или символ, на который необходимо произвести замену, только для регулярного выражения
Property Substitution As Lib.DataTypes.String;

/// 1 - режим замены совпадений регулярному выражению на строку-заменитель. 0 - режим возврата подстроки удовлетворяющей регулярному выражению
Property Replacer As Lib.DataTypes.Boolean(IndexValue = 1);

/// Режим конвертации, только для паттернов типа zstrip см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzstrip
Property Action As Lib.DataTypes.String;

/// Символы на удаление, только для паттернов типа zstrip см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzstrip
Property Remchar As Lib.DataTypes.String;

/// Символы, которые нужно оставить, только для паттернов типа zstrip см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzstrip
Property Keepchar As Lib.DataTypes.String;

/// Код режима конвертации, только для паттернов типа zcvt, см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzconvert
Property Mode As Lib.DataTypes.String;

/// Таблица трансляции,  только для паттернов типа zcvt, см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzconvert
Property Trantable As Lib.DataTypes.String;

/// Параметр handle содержит оставшуюся часть строки, которая не может быть преобразована в конце $ZCONVERT, и передает эту оставшуюся часть в следующий вызов $ZCONVERT, только для паттернов типа zcvt, см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzconvert
Property Handle As Lib.DataTypes.String;

/// Примечание
Property Com As Lib.DataTypes.String(MAXLEN = 1024);

/// Подстрока замещаемая, только для паттернов типа replace, см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_freplace
Property Oldsub As Lib.DataTypes.String;

/// Подстрока замещающая, только для паттернов типа replace, см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_freplace
Property Newsub As Lib.DataTypes.String;

/// Символы замещаемые, только для паттернов типа translate, см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_ftranslate
Property Identifier As Lib.DataTypes.String;

/// Символы замещающие, только для паттернов типа translate, см. http://mir-test/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_ftranslate
Property Associator As Lib.DataTypes.String;

/// Класс, только для обработки типа "метод класса" (без ".cls")
Property ClassName As Lib.DataTypes.String(MAXLEN = 1024);

/// Метод класса, только для обработки типа "метод класса"
Property MethodName As Lib.DataTypes.String(MAXLEN = 1024);

Index NomenClass On NomenClass [ Type = bitmap ];

Index Name On Name [ Type = bitmap ];

Index Expression On Expression [ Type = bitmap ];

Index CodeType On CodeType [ Type = bitmap ];

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
		s out.value=""
		i (in.section="grid") && (in.field="Expression"){
			i ..CodeType="regexp" {
				s out.value = "Expression: "_..Expression_"</br>"
				s out.value = out.value_"Substitution: '"_..Substitution_"'"
			}
			i ..CodeType="zstrip" {
				s out.value = out.value_"Маска выражения: "_..Action_"</br>"
				s out.value = out.value_"Удалить символы: '"_..Remchar_"'</br>"
				s out.value = out.value_"Оставить символы: '"_..Keepchar_"'"
			}
			i ..CodeType="zcvt" {
				s out.value = out.value_"Маска (U,L,T,W,S,I,O): "_..Mode_"</br>"
				;s out.value = out.value_"Trantable (UTF8,JSON,URL,XML,HTML): '"_..Trantable_"'</br>"
				;s out.value = out.value_"Handle: '"_..Handle_"'"
			}
			i ..CodeType="replace" {
				s out.value = out.value_"Замена подстроки '"_..Oldsub_"'</br>"
				s out.value = out.value_"На подстроку '"_..Newsub_"'"
			}
			i ..CodeType="translate" {
				s out.value = out.value_"Каждый из заменяемых символов в '"_..Identifier_"'</br>"
				s out.value = out.value_"по № следования заменятся на '"_..Associator_"'"
			}
			i ..CodeType="classMethod" {
				s out.value = "Метод: "_..MethodName_" класса: "_..ClassName
				s class=##class(%ClassDefinition).%OpenId(..ClassName)
				i $ISO(class) {
					f i=1:1:class.Methods.Count(){
						s method = class.Methods.GetAt(i)
						i $ISO(method)&&(method.Name = ..MethodName) {
							s out.value = out.value_"</br>"_method.Description
						}
					}
				}
				
			}
		}
		// !!! Здесь писать свой код
		
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

/// Метод применения паттерна обработки строки к строке str
/// Вход:
/// 		sourceStr- строка для преобразования
/// 		log		- делать логирование (1) или нет (0)
/// Выход:
/// 		out.error	- ошибки
/// 		result		- результат преобразования строк
Method Apply(sourceStr As Lib.DataTypes.String = "", log As Lib.DataTypes.Boolean = 0, out) As Lib.DataTypes.String
{
	/// s out={},sp=##class(App.MAF.StringPattern).%OpenId(102)  d sp.Apply("ERGOFORMA UP р.1 №2 /II ст.компр., черн./EU 322/ Гольфы Эргоформа 2 класс компрес.закр.нос. черн р.3 [EU-322]",1,out)
	try {
		s result = sourceStr
		q:result=""
		s:'$D(%log) %log = []
		
		i ..CodeType="replace" {
			s result = $REPLACE(sourceStr, ..Oldsub, ..Newsub)
		}
		elseif ..CodeType="zcvt" {
			s result = $ZCVT(sourceStr, ..Mode)
		}
		elseif ..CodeType="zstrip" {
			s result = $ZSTRIP(sourceStr, ..Action, ..Remchar, ..Keepchar)
		}
		elseif ..CodeType="translate" {
			s result = $TRANSLATE(sourceStr, ..Identifier, ..Associator)
		}
		elseif ..CodeType="regexp" {
			i ..Replacer {
				s matcher = ##class(%Regex.Matcher).%New(..Expression, sourceStr)
				s result = matcher.ReplaceAll(..Substitution)
			}
			else {
				s result = ""
				s matcher = ##class(%Regex.Matcher).%New(..Expression, sourceStr)
				;s:matcher.Locate() result = $E(sourceStr, matcher.Start, matcher.End)
				while matcher.Locate() {
					s result = result_" "_matcher.Group
				}
			}
		}
		elseif ..CodeType="classMethod" {
			s result = $CLASSMETHOD(..ClassName, ..MethodName, sourceStr)
		}
		d:log %log.%Push({"Oper":(..Name_" (id="_..%Id()_") : "),"Result":(result)})
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s out.error = err
	}
	q result
}

/// Метод применения регулярного выражения к строке
/// Вход:
/// 	string	- строка для преобразования
/// 	regexp	- регулярное выражение
/// 	newsub	- подстрока, на которую произойдет замена подстрок в исходной строке, удовлетворяющих регулярному выражению. В случае "" произойдет удаление этих подстрок
/// Выход:
/// 		string - преобразованная строка
/// w ##class(App.MAF.StringPattern).regexp(str,regexp,newsub)
ClassMethod regexp(string = " ", regexp = " ", replacement = " ") As Lib.DataTypes.String
{
	s matcher = ##class(%Regex.Matcher).%New(regexp,string)
	q matcher.ReplaceAll(replacement)
}

/// Метод поиска активных паттернов
/// 	активных 
/// 	привязанных к номенклатуре, если nomen задан
/// 	начинающихся с patternNameBegin
/// Вход:
/// 	nomen			- номенклатура
/// 	patternNameBegin- начало названия паттерна
/// 	результат в ind - индекс найденных паттернов
/// Выход:
/// 	ind	- индекс найденных паттернов
/// s nomen=##class(App.AGS.Nomen).%OpenId(48583)
/// d $SYSTEM.Status.GetErrorText(##class(App.MAF.StringPattern).getPatterns(,"nGramm",.ind))
/// ClassMethod getPatterns(nomen As App.AGS.Nomen = "", patternNameBegin As Lib.DataTypes.String = "", ByRef ind)
ClassMethod getPatterns(nomen, patternNameBegin As Lib.DataTypes.String = "", ByRef ind)
{
	s status = $$$OK
	try {
		s out = {}
		
		; Построение фильтра выборки паттернов обработки ----------------------------------------------------------------------------------
		s filter = []
		; Если подали patternNameBegin - плюсуем такие активных паттерны, названия которых начинаются с patternNameBegin
		i $G(patternNameBegin)'="" {
			s filterExtension = [{"field":"Name","type":"начинается","data":(patternNameBegin)},
								{"oper":"AND"},
								{"field":"Active","type":"=","data":1}]
			d ##class(Lib.Util.Filter).ExtendFilterByOr(.filter,filterExtension,.out)
			i out.error'="" {
				s status = $$$ERROR(out.error)
				q
			}
		}
		
		; Если подали nomen - плюсуем паттерны, относящиеся к свойству (пока не сделано) номенклатуре, и/или её классу, и/или её владельцу
		i $ISOBJECT(nomen) {
			; подфильтр для активных паттернов, привязанных к классу номенклатуры
			i $ISOBJECT(nomen.IdClass) {
				s filterExtension = [{"field":"NomenClass","type":"=","data":(nomen.IdClassCustom.%Id())},
									{"oper":"AND"},
									{"field":"Active","type":"=","data":1}]
				d ##class(Lib.Util.Filter).ExtendFilterByOr(.filter,filterExtension,.out)
				i out.error'="" {
					s status = $$$ERROR(out.error)
					q
				}
			}
			; подфильтр для активных паттернов, привязанных к заказчику номенклатуры
			i $ISOBJECT(nomen.idCustom) {
				s filterExtension = [{"field":"Customer","type":"=","data":(nomen.idCustom.%Id())},
									{"oper":"AND"},
									{"field":"Active","type":"=","data":1}]
				d ##class(Lib.Util.Filter).ExtendFilterByOr(.filter,filterExtension,.out)
				i out.error'="" {
					s status = $$$ERROR(out.error)
					q
				}
			}
			; подфильтр для активных паттернов, привязанных к свойствам шаблона класса
			i $ISOBJECT(nomen) {
				; TODO
				; пройтись по свойствам шаблона класса номенклатуры
			}
		}
		
		; Выборка паттернов обработки -----------------------------------------------------------------------------------------------------
		k ind
		s err = ..Filter(filter, .ind)
		i err'="" {
			s status = $$$ERROR(err)
			q
		}
	}
	catch exp {
		s err = ..ErrorDetect(.exp)
		s status = $$$ERROR(err)
	}
	q status
}

Parameter XMLTYPE = "App-MAF-StringPattern";

Storage Default
{
<Data name="StringPatternDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Active</Value>
</Value>
<Value name="4">
<Value>NomenClass</Value>
</Value>
<Value name="5">
<Value>Type</Value>
</Value>
<Value name="6">
<Value>Customer</Value>
</Value>
<Value name="7">
<Value>CodeType</Value>
</Value>
<Value name="8">
<Value>Expression</Value>
</Value>
<Value name="9">
<Value>Substitution</Value>
</Value>
<Value name="10">
<Value>Action</Value>
</Value>
<Value name="11">
<Value>Remchar</Value>
</Value>
<Value name="12">
<Value>Keepchar</Value>
</Value>
<Value name="13">
<Value>Mode</Value>
</Value>
<Value name="14">
<Value>GUID</Value>
</Value>
<Value name="15">
<Value>Handle</Value>
</Value>
<Value name="16">
<Value>Com</Value>
</Value>
<Value name="17">
<Value>NumInQueue</Value>
</Value>
<Value name="18">
<Value>Oldsub</Value>
</Value>
<Value name="19">
<Value>Newsub</Value>
</Value>
<Value name="20">
<Value>Identifier</Value>
</Value>
<Value name="21">
<Value>Associator</Value>
</Value>
<Value name="22">
<Value>Trantable</Value>
</Value>
<Value name="23">
<Value>Vers</Value>
</Value>
<Value name="24">
<Value>Agent</Value>
</Value>
<Value name="26">
<Value>Replacer</Value>
</Value>
<Value name="27">
<Value>SourseSys</Value>
</Value>
<Value name="28">
<Value>SourceSys</Value>
</Value>
<Value name="29">
<Value>ClassName</Value>
</Value>
<Value name="30">
<Value>MethodName</Value>
</Value>
</Data>
<DataLocation>^App.MAF.StringPatternD</DataLocation>
<DefaultData>StringPatternDefaultData</DefaultData>
<IdLocation>^App.MAF.StringPatternD</IdLocation>
<IndexLocation>^App.MAF.StringPatternI</IndexLocation>
<StreamLocation>^App.MAF.StringPatternS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

