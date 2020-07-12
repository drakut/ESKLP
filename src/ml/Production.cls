Class ml.Production Extends Ens.Production
{

/// Register callout lib system-wide
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
	set sc = ##class(isc.py.Callout).Setup()
	quit sc
}

XData ProductionDefinition
{
<Production Name="ml.Production" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="ml.match.RgrCoefProcess" Category="Match" ClassName="ml.match.RgrCoefProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
  <Item Name="isc.py.ens.Operation" Category="Engine,Match" ClassName="isc.py.ens.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="PythonLib">libpython3.6m.so</Setting>
  </Item>
</Production>
}

}

