/// Предприятия
Class App.NSI.Producer Extends (%Persistent, Lib.Abstract.StorableTablesCodeName)
{

/// Проверки и Установки полей перед сохранением
///  s obj=##class(App.NSI.Producer).%OpenId(1) d obj.addCheckSet({},{})  ; Запуск из терминала
Method addCheckSet(ByRef in, ByRef out)
{
	// На входе :
	//		in.oldRec.ИмяПоля -> Поле из старого тела записи
	//				in.edited -> Признак изменения записи (1 - изменена, 0 - не изменена)
	//				  in.type -> Тип транзакции ("new"-новая,"edit"-редактирование,"delete"-удаление,"reindex"- переиндексация записи)
	//				..ИмяПоля -> Поле из нового тело записи
	// На выходе :
	//		out.error -> Сообщение об ошибке или пусто
	// Примеры :
	//	s id=s id=..%Id()
	//	s name=in.oldRec.Name	// Получить поле из Старого тела записи
	//	s name=..Name			// Получить поле из Нового тела записи
	s err=""
	try {
		
		 // !!! Здесь писать свой код
         ;-- Проверки         
         ;i что-то не так s out.error="Нестандартная ЕИ короче 3-х символов" q  ; Ошибка
         ;  ... и т.д
         ; 
         ;-- Преобразования.
         s ..FinWords=##class(Lib.Util.Str).NormKitWords(..FinWords)   ; Нормализация набора поисковых слов 
 		 ;  ... и т.д
         ;
		} // try
	catch exp {
		s out.error=..ErrorDetect(.exp)
	} // catch
	q
}

/// По словам текста str возвращает набор Поисковых слов по Производителям App.NSI.Producer через пробел
/// Каждое слово текста подрезается справа по одному символу 
/// и огрызок проверяется на существование в индексе ^App.NSI.ProducerI("FinWords-w",word_" ")
/// 
/// s LiFr=##class(Lib.Util.Str).LiFinWordsProducer(str)    ;	Набор через пробел найденных Поисковых слов
/// k  s LiFr=##class(App.NSI.Producer).LiFinWordsProducer("ADAMCZEWSKI ELEKTRONISCHE MESSTECHNIK") w
///     
ClassMethod LiFinWordsProducer(str As %String) As %String
{
 ;  Проход по нормализованным словам текста
 ;  1.Проверяем слово на существование в индексе ^App.NSI.ProducerI("FinWords-w",word_" ")
 ;    есть - фиксируем его в списке найденных, переходим к следующему слову.
 ;     нет - отрезаем у слова последний символ, 
 ;     длина стала < MinLong - переходим к следующему слову. 
 ;                       нет - повторяем п.1
 s NumAndSimbAndSpace=##class(Lib.Abstract.Tables).#NumAndSimbAndSpace   ; Для "как в строке оставить буквы, цифры и пробелы"
 s Txt=$tr(str,NumAndSimbAndSpace,"")   ; строка из букв, цифр и пробелов
 s Txt=$ZCONVERT(Txt,"L")               ; в нижнем регистре
 s LiFr=""
 s MinLong=2
 ; Проход по нормализованным словам текста
 f n=1:1:$l(Txt) 
    {s word=$p(Txt," ",n)
     i $l(word)<MinLong continue       ; слово короче MinLong. Переходим к следующему слову.
     i $d(^App.NSI.ProducerI("FinWords-w",word_" ")) s LiFr=LiFr_word_" " continue   ; нашли все слово в словаре. Переходим к следующему слову.
     f i=1:1 {q:$l(word)<MinLong
             s word=$e(word,1,($l(word)-1))       ; обрезаем слово справа
             q:$l(word)<MinLong                   ; обрезок слова стал меньше 3-х символов. Переходим к следующему слову.
		     i $d(^App.NSI.ProducerI("FinWords-w",word_" ")) s LiFr=LiFr_word_" " q   ; нашли обрезанное слово в словаре. Переходим к следующему слову
	        }
    } 
 s LiFr=$zstrip(LiFr,"<>w")
 q LiFr
}

/// По списку ПС найти записи App.NSI.Producer и сформировать:
/// Возвращает список кодов через пробел 
///   и еще ...
///   <- .список наименований через /
///   <- .bitIndex
///   
/// k  s LiCode=##class(App.NSI.Producer).LiCodeProducerByWindWords(LiWords,.LiName,.ind)   ; Вызов метода
/// k  s LiCode=##class(App.NSI.Producer).LiCodeProducerByWindWords("ижевский Инженерный экологический",.LiName,.ind) w  ;
/// 
ClassMethod LiCodeProducerByWindWords(LiWords As %String, LiName As %String, ByRef bitIndex) As %String
{
 ;     LiWords ->
 ;     .LiName <-
 ;   .bitIndex <-
 ;
 s (LiCode,LiName)="",sep=" / "    ; НУ. sep - это символы разделения наименований
 s LiWords=$ZCONVERT(LiWords,"L")    ; Понизить весь текст сразу на всякий случай
 ;  Проход по словам списка
 f n=1:1:$l(LiWords," ") 	
    {s Wrd=$p(LiWords," ",n) i Wrd="" continue
 	 d ##class(App.NSI.Producer).indOR2(.bitIndex,["FinWords-w",(Wrd_" ")])   ; накопление ind по текущему поисковому слову
 	}
 ;w !,"cnt=",##class(App.NSI.Producer).indCOUNT(.ind)	
 ;-- Проход по собранному индексу. Формирование списка кодов
 s ptr="" while ##class(App.NSI.Producer).indNEXT(.bitIndex,.ptr,.id)	
     {  
	 s obj=##class(App.NSI.Producer).%OpenId(id)      ; Загрузка существующего объекта c id в память
	 ;w !,obj.Code,$c(9),obj.Name                     ; Значение поля "Код" и "Наименование"
	 s LiCode=LiCode_obj.Code_" "
	 s LiName=LiName_sep_obj.Name
     }
 s LiCode=$zstrip(LiCode,"<>w")
 i LiName'=sep s LiName=$e(LiName,$l(sep),$l(LiName))     ; отрезаем первый sep = " / "
 q LiCode
}

/// Пересохранение всех записей класса
/// d ##class(App.NSI.Producer).ReSaveAll()
ClassMethod ReSaveAll()
{
 ;-- Проход по всем записям класса
 s ptr="" while ..indNEXT([(..#indAll)],.ptr,.id) {d ..ReSaveOne(id)}   ; Пересохранение одной записи
 q
}

/// Пересохранение одной записи класса
/// d ##class(App.NSI.Producer).ReSaveOne(id)
ClassMethod ReSaveOne(id As %Integer)
{
 s obj=..%OpenId(id)  ; Загрузка объекта в память
 w !,"ID=",obj.%Id()
 ; --- Здесь что-то исправляем ..
 ;s obj.RepDubl1=11      ;
 ;s obj.RepDubl2=28      ;
 ;s obj.RepDubl3=17      ;
 ;  ...
 ;
 ;--- и пересохраняем
 s status=obj.%Save(0)         ; Транзакция
 if status'=$$$OK              ; Обработка ошибки сохранения
 	 {s err="Ошибка при сохранении записи App.AGS.Custom"
       throw ##class(%Exception.General).%New("<ERROR>","999",,err)
   	  w !,$c(9),err
     }
	q
}

Index idLand On idLand [ Type = bitmap ];

ForeignKey fgidLand(idLand) References App.NSI.Land();

/// ID-страны
Property idLand As Land;

Index ShName On ShName [ Type = bitmap ];

/// Наименование краткое
Property ShName As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1);

Index AltName On AltName [ Type = bitmap ];

/// Наименование альтернативное
Property AltName As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1);

Index FinWords On FinWords [ Type = bitmap ];

/// Набор поисковых слов
Property FinWords As Lib.DataTypes.String(IndexSpecWord = 1, IndexValue = 1, IndexWord = 1);

/// Примечание
Property Com As Lib.DataTypes.String;

Storage Default
{
<Data name="ProducerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Vers</Value>
</Value>
<Value name="3">
<Value>Code</Value>
</Value>
<Value name="4">
<Value>idLand</Value>
</Value>
<Value name="5">
<Value>Name</Value>
</Value>
<Value name="6">
<Value>%Edited</Value>
</Value>
<Value name="7">
<Value>ShName</Value>
</Value>
<Value name="8">
<Value>AltName</Value>
</Value>
<Value name="9">
<Value>FinWords</Value>
</Value>
<Value name="10">
<Value>Com</Value>
</Value>
<Value name="11">
<Value>GUID</Value>
</Value>
<Value name="12">
<Value>SourseSys</Value>
</Value>
<Value name="13">
<Value>SourceSys</Value>
</Value>
</Data>
<DataLocation>^App.NSI.ProducerD</DataLocation>
<DefaultData>ProducerDefaultData</DefaultData>
<IdLocation>^App.NSI.ProducerD</IdLocation>
<IndexLocation>^App.NSI.ProducerI</IndexLocation>
<StreamLocation>^App.NSI.ProducerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

Method Test()
{
	w !,$g(r%idLand)
	w !,$g(r%Com)
}

/// ; Переиндексация 
/// k ^App.NSI.ProducerI d ##class(App.NSI.Producer).%BuildIndices()
Parameter XMLTYPE = "App-NSI-Producer";

/// FE, MAF, Portal, Kabinet - для идентификации системы-источника записи, используется при синхронизхации данных с FE
Property SourceSys As Lib.DataTypes.String(IndexValue = 1);

}

