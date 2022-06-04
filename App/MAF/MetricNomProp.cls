/// Связь свойств онтологии классов и метрик
Class App.MAF.MetricNomProp Extends (%Persistent, Lib.Abstract.StorableTables)
{

/// Метрика, к которой относится свойство
Property Metric As App.MAF.Metric [ Required ];

/// Свойство онтологии
/// Property NomProperty As App.SPR.NomProperty [ Required ];
Property NomProperty As App.ONT.Prop [ Required ];

/// Порядок следования при составлении строки для сравнения
Property OrderNum As Lib.DataTypes.Integer(IndexValue = 1);

Index OrderNum On OrderNum [ Type = bitmap ];

Parameter XMLTYPE = "App-MAF-MetricNomProp";

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
		i in.namecall["Move" {					; если команда на перестановку объекта
			s in2=in							; задаем параметры для метода перемещения
			s out.typejob="fast"
			s item=..%OpenId(in.actualid)
			s in2.className = $CLASSNAME()
			s in2.filter = []
			s in2.numField ="OrderNum"
			s in2.direction=$CASE(in2.namecall,"MoveUp":"u","MoveDown":"d","MoveToFirst":"f","MoveToLast":"l")	; определяем направление движения
			d ##class(Lib.Util.Table).MoveItem(.in2,.out)
			s out.refresh=1
		}
	} // try
	catch exp {
		s err =..ErrorDetect(.exp)
		s out.error = err
	} // catch
	q err
}

/// Не использовать. Времяночка для назначения строчных свойств метрике n-грамм
ClassMethod SetPropToMetric()
{
	k ind,ptr,id
	s flt = [{"field":"Metric","type":"'=","data":""}]
	s err = ##class(App.SPR.NomProperty).Filter(flt,.ind)
	i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
	s maxOrderNum = 0
	while ##class(App.SPR.NomProperty).indNEXT(.ind,.ptr,.id){
		s metricProp = ..%OpenId(id)
		s:maxOrderNum<metricProp.OrderNum maxOrderNum=metricProp.OrderNum
	}
}

/// Проверки и установки перед сохранением
Method addCheckSet(ByRef in, ByRef out)
{
	// На входе :
	//		in.oldRec.ИмяПоля -> Поле из старого тело записи
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//			  in.parentid -> ID главной записи для записи ракурса 
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование,"delete"-удаление,"reindex"- переиндексация записи)
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=..%Id()
	//	s name=in.oldRec.Name	// Получить поле из Старого тела записи
	//	s name=..Name			// Получить поле из Нового тела записи
	s out={"error":""}
	try {
		
		// !!! Здесь писать свой код
		i ..OrderNum=""{
			k ind,ptr,id
			s flt = [{"field":"Metric","type":"'=","data":""}]
			s err = ..Filter(flt,.ind)
			i err'="" {throw ##class(%Exception.General).%New("<ERROR>",999,,err)}
			s maxOrderNum = 0
			while ..indNEXT(.ind,.ptr,.id){
				s metricProp = ..%OpenId(id)
				s:maxOrderNum<metricProp.OrderNum maxOrderNum=metricProp.OrderNum
			}
			
			s ..OrderNum = maxOrderNum+1
		}		
		
	} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

Storage Default
{
<Data name="MetricNomPropDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Metric</Value>
</Value>
<Value name="3">
<Value>NomProperty</Value>
</Value>
<Value name="4">
<Value>OrderNum</Value>
</Value>
<Value name="5">
<Value>Vers</Value>
</Value>
<Value name="6">
<Value>GUID</Value>
</Value>
<Value name="7">
<Value>SourseSys</Value>
</Value>
<Value name="8">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.MAF.MetricNomPropD</DataLocation>
<DefaultData>MetricNomPropDefaultData</DefaultData>
<IdLocation>^App.MAF.MetricNomPropD</IdLocation>
<IndexLocation>^App.MAF.MetricNomPropI</IndexLocation>
<StreamLocation>^App.MAF.MetricNomPropS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

