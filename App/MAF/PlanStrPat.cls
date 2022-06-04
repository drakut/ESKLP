/// Обработки строк плана
Class App.MAF.PlanStrPat Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// План сравнения
Property Plan As App.MAF.Plan;

/// Обработка строки
Property StrPattern As App.MAF.StringPattern;

/// Порядок следования
Property Order As Lib.DataTypes.Integer(IndexValue = 1);

/// Активность
Property Active As Lib.DataTypes.Boolean(IndexValue = 1);

Index Active On Active;

Index Order On Order;

Parameter XMLTYPE = "App-MAF-PlanStrPat";

Storage Default
{
<Data name="PlanStrPatDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Plan</Value>
</Value>
<Value name="3">
<Value>StrPattern</Value>
</Value>
<Value name="4">
<Value>Active</Value>
</Value>
<Value name="5">
<Value>Vers</Value>
</Value>
<Value name="6">
<Value>GUID</Value>
</Value>
<Value name="7">
<Value>Order</Value>
</Value>
</Data>
<DataLocation>^App.MAF.PlanStrPatD</DataLocation>
<DefaultData>PlanStrPatDefaultData</DefaultData>
<IdLocation>^App.MAF.PlanStrPatD</IdLocation>
<IndexLocation>^App.MAF.PlanStrPatI</IndexLocation>
<StreamLocation>^App.MAF.PlanStrPatS</StreamLocation>
<Type>%Storage.Persistent</Type>
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
		s out.value=""
		i (in.section="grid") && (in.field="Expression"){
			i ..StrPattern.CodeType="regexp" {
				s out.value = "Expression: "_..StrPattern.Expression_"</br>"
				s out.value = out.value_"Substitution: '"_..StrPattern.Substitution_"'"
			}
			i ..StrPattern.CodeType="zstrip" {
				s out.value = out.value_"Action: "_..StrPattern.Action_"</br>"
				s out.value = out.value_"Remchar: '"_..StrPattern.Remchar_"'</br>"
				s out.value = out.value_"Keepchar: '"_..StrPattern.Keepchar_"'"
			}
			i ..StrPattern.CodeType="zcvt" {
				s out.value = out.value_"Mode: "_..StrPattern.Mode_"</br>"
				s out.value = out.value_"Trantable: '"_..StrPattern.Trantable_"'</br>"
				s out.value = out.value_"Handle: '"_..StrPattern.Handle_"'"
			}
			i ..StrPattern.CodeType="replace" {
				s out.value = out.value_"Oldsub: '"_..StrPattern.Oldsub_"'</br>"
				s out.value = out.value_"Newsub: '"_..StrPattern.Newsub_"'"
			}
			i ..StrPattern.CodeType="translate" {
				s out.value = out.value_"Identifier: '"_..StrPattern.Identifier_"'</br>"
				s out.value = out.value_"Associator: '"_..StrPattern.Associator_"'"
			}
			i ..StrPattern.CodeType="classMethod" {
				s out.value = "Метод: "_..StrPattern.MethodName_" класса: "_..StrPattern.ClassName
				s class=##class(%ClassDefinition).%OpenId(..StrPattern.ClassName)
				i $ISO(class) {
					f i=1:1:class.Methods.Count(){
						s method = class.Methods.GetAt(i)
						i $ISO(method)&&(method.Name = ..StrPattern.MethodName) {
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
	// 		in.multiselect.all  - > Если 1, то выбор всех примультиселекте
	//  in.multiselect.records  - > Если in.in.multiselect.all=1, то динамический массив ID, которые отменены, Если in.in.multiselect.all=0, то динамический массив ID, которые отмечены
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
		i in.namecall["Move" {	 																				; если команда на перестановку объекта
			s in2=in																							; задаем параметры для метода перемещения
			s out.typejob="fast"
			s item=..%OpenId(in2.actualid)
			s in2.className = $CLASSNAME()
			s in2.filter = [{"field":"Order","type":">","data":0}]
			s in2.numField ="Order"
			s in2.direction=$CASE(in2.namecall,"MoveUp":"u","MoveDown":"d","MoveToFirst":"f","MoveToLast":"l")	; определяем направление движения
			d ##class(Lib.Util.Table).MoveItem(.in2,.out)
			s out.refresh=1
		}
		i in.namecall="Copy" {																					; если команда скопировать пункт меню
			s out.typejob="fast"
			s item = ..%OpenId(in.actualid)
			d item.Copy(.in,.out)
			s out.refresh=1
		}
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
		s out.error = err
	} // catch
	q err
}

}

