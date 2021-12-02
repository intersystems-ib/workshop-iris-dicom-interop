Class DICOM.Production Extends Ens.Production
{

Parameter SETTINGS = "ShutdownTimeout,UpdateTimeout,StorageLocation";

Property StorageLocation As %String;

XData ProductionDefinition
{
<Production Name="DICOM.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Setting Target="Production" Name="ShutdownTimeout">120</Setting>
  <Setting Target="Production" Name="UpdateTimeout">10</Setting>
  <Setting Target="Production" Name="StorageLocation">/usr/irissys/mgr/stream</Setting>
  <Item Name="PDF DICOM In" Category="" ClassName="EnsLib.DICOM.Service.TCP" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
    <Setting Target="Host" Name="DuplexTargetConfigName">PDF DICOM Process</Setting>
    <Setting Target="Adapter" Name="LocalAET">IRISPDFSCU</Setting>
    <Setting Target="Adapter" Name="RemoteAET">DCMPDFSCP</Setting>
    <Setting Target="Adapter" Name="TraceVerbosity">2</Setting>
    <Setting Target="Adapter" Name="JobPerConnection">0</Setting>
    <Setting Target="Adapter" Name="IPPort">2010</Setting>
    <Setting Target="Adapter" Name="CallInterval">1</Setting>
    <Setting Target="Host" Name="ArchiveIO">0</Setting>
  </Item>
  <Item Name="PDF DICOM Process" Category="" ClassName="DICOM.BP.PDFProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
  </Item>
  <Item Name="PDF Save Report" Category="" ClassName="EnsLib.File.PassthroughOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
