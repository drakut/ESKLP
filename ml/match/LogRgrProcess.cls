/// Using Python to get logistic predictions
Class ml.match.LogRgrProcess Extends (Ens.BusinessProcessBPL, isc.py.ens.ProcessUtils)
{

/// Plan id to update coef weights
/// If not specified default query in BPL would be used
Property PlanId As %Integer [ InitialExpression = 1 ];

Parameter SETTINGS = "PlanId:Basic";

XData EmptyCall
{
<xml>
<call name='' target='isc.py.ens.Operation' async='1'>
<annotation><![CDATA[
]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("")' action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
<sync name='Wait for ' calls='' type='all' />

<call name='' target='isc.py.ens.Operation' async='1'>
<annotation><![CDATA[]]></annotation>
<request type='isc.py.msg.QueryRequest' >
<assign property="callrequest.Query" value='process.GetAnnotation("")' action="set" />
<assign property="callrequest.Variable" value='""' action="set" />
<assign property="callrequest.Type" value='"list"' action="set" />
</request>
<response type='Ens.Response' />
</call>
<sync name='Wait for ' calls='' type='any'/>

</xml>
}

Storage Default
{
<Data name="LogRgrProcessDefaultData">
<Subscript>"LogRgrProcess"</Subscript>
<Value name="1">
<Value>PlanId</Value>
</Value>
</Data>
<DefaultData>LogRgrProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.Request' response='Ens.Response' height='2100' width='2000' >
<context>
<property name='score' type='%VarString' instantiate='0' />
<property name='intercept' type='%VarString' instantiate='0' />
<property name='coef' type='%VarString' instantiate='0' />
<property name='predictions' type='%VarString' instantiate='0' />
<property name='cm' type='%VarString' instantiate='0' />
</context>
<sequence xend='200' yend='1050' >
<call name='Import' target='isc.py.ens.Operation' async='1' xpos='200' ypos='250' >
<annotation><![CDATA[
# Load modules

from sklearn.linear_model import LogisticRegression
from sklearn import preprocessing
from sklearn.model_selection import train_test_split
from sklearn import metrics

]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Import&quot;)" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
<sync name='Wait for Import' calls='Import' type='all' xpos='200' ypos='350' />
<call name='Load Data' target='isc.py.ens.Operation' async='1' xpos='200' ypos='450' >
<annotation><![CDATA[SELECT CodeLeft, CodeRight, Country, "Decimal", LekForm, ManufName, Ngramm, Nomer, ProdName, Simber, Translit, Trigram, BarcodeSimilarity, Linked FROM App_MAF.LinkML ORDER BY ID]]></annotation>
<request type='isc.py.msg.QueryRequest' >
<assign property="callrequest.Query" value="process.GetAnnotation(&quot;Load Data&quot;)" action="set" />
<assign property="callrequest.Variable" value="&quot;df&quot;" action="set" />
<assign property="callrequest.Type" value="&quot;dataframe&quot;" action="set" />
</request>
<response type='Ens.Response' />
</call>
<sync name='Wait for data' calls='Load Data' type='any' xpos='200' ypos='550' />
<call name='Logistic regression' target='isc.py.ens.Operation' async='1' xpos='200' ypos='650' >
<annotation><![CDATA[

# Extract Y
Y = df.Linked

# Dropping unneeded variables from trainig data
X = df.drop(columns=['CodeLeft', 'CodeRight', 'Linked'])
del df

x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size=0.3, train_size=0.7, random_state=0)

# _________________
# Train model 

# Create empty Logistic Regression model
logRegr = LogisticRegression()

# Train it
logRegr.fit(x_train, y_train)

# __________________
# Test model

predictions = logRegr.predict(x_test)

# Use score method to get accuracy of model
score = logRegr.score(x_test, y_test)

# Confusion Matrix for model accuracy
cm = metrics.confusion_matrix(y_test, predictions)
]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Logistic regression&quot;)" action="set" />
<assign property="callrequest.Variables" value="&quot;score,predictions,cm&quot;" action="set" />
<assign property="callrequest.Serialization" value="&quot;JSON&quot;" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' >
<assign property="context.score" value="callresponse.Variables.GetAt(&quot;score&quot;)" action="set" />
<assign property="context.predictions" value="callresponse.Variables.GetAt(&quot;predictions&quot;)" action="set" />
<assign property="context.cm" value="callresponse.Variables.GetAt(&quot;cm&quot;)" action="set" />
</response>
</call>
<sync name='Wait for Logistic regression' calls='Logistic regression' type='all' xpos='200' ypos='750' />
<trace name='Results' value='"score: " _ context.score _ ", coef: " _ context.coef _", predictions: "_ context.predictions _ ", confusion matrix: " _ context.cm' xpos='200' ypos='850' />
<assign name="Save results" property="status" value="##class(App.MAF.Plan).PrintResults(process.PlanId, context.score, context.predictions, context.cm)" action="set" xpos='200' ypos='950' />
</sequence>
</process>
}

}

