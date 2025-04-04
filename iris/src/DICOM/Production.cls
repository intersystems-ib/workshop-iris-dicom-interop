Include (Ensemble, EnsDICOM)

Class DICOM.Production Extends Ens.Production
{

Parameter SETTINGS = "ShutdownTimeout,UpdateTimeout,StorageLocation";

Property StorageLocation As %String;

/// Create DICOM associations when starting production
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
  if '##class(EnsLib.DICOM.Util.AssociationContext).AETExists("DCM_PDF_SCP","IRIS_PDF_SCU") {
		do ##class(DICOM.Util).CreateAssociation("DCM_PDF_SCP","IRIS_PDF_SCU",$lb($$$IMPLICITVRLETRANSFERSYNTAX),$lb("Storage"))
	}

  if '##class(EnsLib.DICOM.Util.AssociationContext).AETExists("IRIS_QRY_SCU","DCM_QRY_SCP") {
		do ##class(DICOM.Util).CreateAssociation("IRIS_QRY_SCU","DCM_QRY_SCP",$lb($$$IMPLICITVRLETRANSFERSYNTAX),$lb("FIND", "MOVE"))
	}
  	
	if '##class(EnsLib.DICOM.Util.AssociationContext).AETExists("IRIS_STORE_SCP","DCM_QRY_SCP") {
		do ##class(DICOM.Util).CreateAssociation("IRIS_STORE_SCP","DCM_QRY_SCP",$ListBuild($$$IMPLICITVRLETRANSFERSYNTAX,$$$RAWDATAEXPLICITVRLTLENDIAN), $lb("Storage"))
	}
	
  if '##class(EnsLib.DICOM.Util.AssociationContext).AETExists("DCM_QRY_SCP","IRIS_STORE_SCP") {
		do ##class(DICOM.Util).CreateAssociation("DCM_QRY_SCP","IRIS_STORE_SCP",$ListBuild($$$IMPLICITVRLETRANSFERSYNTAX,$$$RAWDATAEXPLICITVRLTLENDIAN), $lb("Storage"))
	}

  if '##class(EnsLib.DICOM.Util.AssociationContext).AETExists("DCM_WL","IRIS_WL") {
		do ##class(DICOM.Util).CreateAssociation("DCM_WL","IRIS_WL",$ListBuild($$$IMPLICITVRLETRANSFERSYNTAX), $lb("FIND"))
	}
	
  quit $$$OK
}

XData ProductionDefinition
{
<Production Name="DICOM.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Setting Target="Production" Name="ShutdownTimeout">120</Setting>
  <Setting Target="Production" Name="UpdateTimeout">10</Setting>
  <Setting Target="Production" Name="StorageLocation">/usr/irissys/mgr/stream</Setting>
  <Item Name="DICOM PDF In" Category="PDF" ClassName="EnsLib.DICOM.Service.TCP" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
    <Setting Target="Host" Name="DuplexTargetConfigName">DICOM PDF Process</Setting>
    <Setting Target="Adapter" Name="LocalAET">IRIS_PDF_SCU</Setting>
    <Setting Target="Adapter" Name="RemoteAET">DCM_PDF_SCP</Setting>
    <Setting Target="Adapter" Name="TraceVerbosity">2</Setting>
    <Setting Target="Adapter" Name="JobPerConnection">0</Setting>
    <Setting Target="Adapter" Name="IPPort">2010</Setting>
    <Setting Target="Adapter" Name="CallInterval">1</Setting>
    <Setting Target="Host" Name="ArchiveIO">0</Setting>
  </Item>
  <Item Name="DICOM PDF Process" Category="PDF" ClassName="DICOM.BP.PDFProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
  </Item>
  <Item Name="PDF Save Report" Category="PDF" ClassName="EnsLib.File.PassthroughOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="DICOM TCP Out" Category="QueryRetrieve" ClassName="EnsLib.DICOM.Operation.TCP" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
    <Setting Target="Host" Name="DuplexTargetConfigName">DICOM Query Process</Setting>
    <Setting Target="Adapter" Name="LocalAET">IRIS_QRY_SCU</Setting>
    <Setting Target="Adapter" Name="RemoteAET">DCM_QRY_SCP</Setting>
    <Setting Target="Adapter" Name="TraceVerbosity">2</Setting>
    <Setting Target="Adapter" Name="JobPerConnection">0</Setting>
    <Setting Target="Adapter" Name="IPPort">3010</Setting>
    <Setting Target="Adapter" Name="IPAddress">tools</Setting>
  </Item>
  <Item Name="QueryService" Category="QueryRetrieve" ClassName="DICOM.BS.QueryService" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="DICOM Query Process" Category="QueryRetrieve" ClassName="DICOM.BP.QueryProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="OperationDuplexName">DICOM TCP Out</Setting>
  </Item>
  <Item Name="MoveService" Category="QueryRetrieve" ClassName="DICOM.BS.MoveService" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="DICOM Move Process" Category="QueryRetrieve" ClassName="DICOM.BP.MoveProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="OperationDuplexName">DICOM TCP Out</Setting>
  </Item>
  <Item Name="DICOM Store In" Category="QueryRetrieve" ClassName="EnsLib.DICOM.Service.TCP" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="IPAddress"></Setting>
    <Setting Target="Adapter" Name="IPPort">2020</Setting>
    <Setting Target="Adapter" Name="LocalAET">IRIS_STORE_SCP</Setting>
    <Setting Target="Adapter" Name="RemoteAET">DCM_QRY_SCP</Setting>
    <Setting Target="Host" Name="DuplexTargetConfigName">DICOM Store Process</Setting>
  </Item>
  <Item Name="DICOM Store Process" Category="QueryRetrieve" ClassName="DICOM.BP.StoreProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="JavaGateway" Category="" ClassName="EnsLib.JavaGateway.Service" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="ClassPath">/shared/install/mysql-connector-j-8.4.0.jar</Setting>
  </Item>
  <Item Name="DICOM WL Find In" Category="WorkList" ClassName="EnsLib.DICOM.Service.TCP" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
    <Setting Target="Host" Name="DuplexTargetConfigName">DICOM WorkList Process</Setting>
    <Setting Target="Adapter" Name="LocalAET">IRIS_WL</Setting>
    <Setting Target="Adapter" Name="RemoteAET">DCM_WL</Setting>
    <Setting Target="Adapter" Name="TraceVerbosity">2</Setting>
    <Setting Target="Adapter" Name="JobPerConnection">0</Setting>
    <Setting Target="Adapter" Name="IPPort">1112</Setting>
    <Setting Target="Adapter" Name="CallInterval">1</Setting>
  </Item>
  <Item Name="DICOM WorkList Process" Category="WorkList" ClassName="DICOM.BP.WorkListProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="InactivityTimeout">0</Setting>
  </Item>
  <Item Name="HIS WorkList Query" Category="WorkList" ClassName="EnsLib.SQL.Operation.GenericOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="Credentials">MySQL_User</Setting>
    <Setting Target="Adapter" Name="DSN">jdbc:mysql://mysql:3306/testdb</Setting>
    <Setting Target="Adapter" Name="JDBCDriver">com.mysql.jdbc.Driver</Setting>
    <Setting Target="Adapter" Name="JGService">JavaGateway</Setting>
    <Setting Target="Host" Name="RequestClass">DICOM.Msg.WorkListReq</Setting>
    <Setting Target="Host" Name="InputParameters">*ScheduledDate</Setting>
    <Setting Target="Host" Name="Query">select PatientID,PatientName,Modality,ScheduledDate,ScheduledTime from WorkList where ScheduledDate = ?</Setting>
    <Setting Target="Host" Name="ParamSQLTypes"></Setting>
    <Setting Target="Host" Name="ResponseClass"></Setting>
  </Item>
</Production>
}

}
