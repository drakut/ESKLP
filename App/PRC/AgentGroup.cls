/// Группы Контрагентов и клиентов
Class App.PRC.AgentGroup Extends (%Persistent, Lib.Abstract.StorableTablesCode) [ Inheritance = right, Not ProcedureBlock ]
{

/// Построение/снос дополнительных индексов
Method addIndex(ByRef in, ByRef out)
{
	// На входе :
	//		in.oldRec.ИмяПоля -> Поле из старого тело записи
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование,"delete"-удаление,"reindex"- переиндексация записи) При "delete" in.oldRec совпадает с текущим объектом
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s name=in.oldRec.Name	// Получить поле из Старого тела записи
	//	s name=..Name			// Получить поле из Нового тела записи
	s out={"error":""}
	try {
		// !!! Здесь писать свой код

	;===== Построение
	if (in.type'="delete")  ;
		{
 		 ;--- Доп.индексы типа "idХХХ-used" по используемым idХХХ. 
 		 ;    Для программно-управляемых Фильтров при поиске через поисковые формы, в которые будут подаваться только используемые IDы справочников
 		 ;    Добавлять список полей, подлежащих индексации, по мере надобности
		 f NameFld="Temp1"   ;"idClass","idProp","idPatt"        ; {d ..indUsedINSERT(##this, NameFld)}
		 	{s Val=$PROPERTY(##this,NameFld)                ; Получить значение полей "idХХХ" ;"idClass","idProp","idPatt"
		 	 s id="" 
		 	 ;-- Для атрибута "Temp1" своя обработка
		 	 i NameFld="Temp1" s:Val'="" id=Val   ; при Temp1 берем его значение в качестве id 
		 	 e  s:Val'="" id=Val.%Id()            ; иначе id берем как свойство объекта
		 	 ;--
		 	 i id'="" d ..indINSERT([(NameFld_"-used")],id) ; Строим индекс по этому ID
		 	}
        }

    ;======= Снос. !!! К этому моменту все основные индексы по записи снесены
	if in.type="delete" ; Редактирование или удаление. Снести индекс
	    {	
 		 ;--- Доп.индексы по используемым idХХХ. Для Фильтров при поиске через поисковые формы
 		 ;    Добавлять список полей, подлежащих сносу или индексации, по мере надобности
 		 f NameFld="Temp1"   ;"idClass","idProp","idPatt"        ; {d ..indUsedINSERT(##this, NameFld)}
 		 	{s id=in.oldRec.%Get(NameFld)   ; Получить значение полей "idХХХ" ;"idClass","idProp","idPatt" из in.oldRec
 		     k ind
 		     i id'="" {s filter=[{"field":(NameFld),"type":"равно","data":(id)}]
	    	 		   s out.error=..Filter(.filter,.ind) q:out.error'=""
			           i ..indCOUNT(.ind)=0 {d ..indDELETE([(NameFld_"-used")],id)}  ;  Если нет записей c id, тогда сносить. Иначе, ничего не делать
 		 	          }
 		 	}
	    }
	} // try
	catch exp {s out.error=..ErrorDetect(.exp)}
	q
}

/// Может Быть родителем
Parameter CanParent = 1;

/// Сохранение связанных объектов
Parameter Related = 1;

/// Виртуальный
Parameter Virtual = 0;

Parameter XMLTYPE = "App-PRC-AgentGroup";

/// Счетчик для кода
Property CounterCode As %Library.Counter [ Required ];

/// Наименование
Property Name As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, SortingType = "Z");

/// Временное поле1
Property Temp1 As Lib.DataTypes.String(IndexValue = 1);

Index Code On Code As Truncate(200) [ Type = bitmap ];

Index CounterCode On CounterCode [ Type = bitmap ];

Index GUID On GUID As Truncate(200) [ Type = bitmap ];

Index Name On Name As Truncate(200) [ Type = bitmap ];

Index Temp1 On Temp1 As Truncate(200) [ Type = bitmap ];

Storage Default
{
<CounterLocation>^App.PRC.AgentGroupC</CounterLocation>
<Data name="AgentGroupDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Code</Value>
</Value>
<Value name="3">
<Value>Vers</Value>
</Value>
<Value name="4">
<Value>GUID</Value>
</Value>
<Value name="5">
<Value>CounterCode</Value>
</Value>
<Value name="6">
<Value>Name</Value>
</Value>
<Value name="7">
<Value>Temp1</Value>
</Value>
<Value name="8">
<Value>SourseSys</Value>
</Value>
<Value name="9">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.PRC.AgentGroupD</DataLocation>
<DefaultData>AgentGroupDefaultData</DefaultData>
<IdLocation>^App.PRC.AgentGroupD</IdLocation>
<IndexLocation>^App.PRC.AgentGroupI</IndexLocation>
<StreamLocation>^App.PRC.AgentGroupS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

