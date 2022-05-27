Include EnsDICOM

Class DICOM.Msg.MoveReq Extends Ens.Request
{

Property PatientID As %String;

Property PatientName As %String;

Property StudyInstanceUID As %String(MAXLEN = "");

Property SeriesInstanceUID As %String(MAXLEN = "");

Property Session As %String;

Property Filename As %String;

Property RxItemID As %String;

Method CreateMoveReq(pDocOut As EnsLib.DICOM.Document) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tTemp,tAffectedSOPClassUID As %String
	try {
		#; Create an instance of a DICOM Document to form the response
		kill %objlasterror Set pDocOut=##class(EnsLib.DICOM.Document).%New()
		if '$IsObject(pDocOut) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.DICOM.Document")) Quit
		
		// Command Set
		set tSC=pDocOut.SetValueAt($$$Str2MsgTyp("C-MOVE-RQ"),"CommandSet.CommandField") if $$$ISERR(tSC) quit 
		set tSC=pDocOut.SetValueAt("1.2.840.10008.5.1.4.1.2.2.2","CommandSet.AffectedSOPClassUID") if $$$ISERR(tSC) quit 
		set tSC=pDocOut.SetValueAt("1","CommandSet.MessageID") if $$$ISERR(tSC) quit 
		set tSC=pDocOut.SetValueAt("StorageSCP","CommandSet.MoveDestination") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt("0","CommandSet.Priority") if $$$ISERR(tSC) quit
		// Data Set
		set tSC=pDocOut.SetValueAt("SERIES","DataSet.QueryRetrieveLevel") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt(..StudyInstanceUID,"DataSet.StudyInstanceUID") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt(..SeriesInstanceUID,"DataSet.SeriesInstanceUID") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt(..PatientName,"DataSet.PatientName") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt(..PatientID,"DataSet.PatientID") if $$$ISERR(tSC) quit
	} catch errObj {
		Set tSC=$$$EnsSystemError
	}
	quit tSC
}

Storage Default
{
<Data name="MoveReqDefaultData">
<Subscript>"MoveReq"</Subscript>
<Value name="1">
<Value>PatientID</Value>
</Value>
<Value name="2">
<Value>PatientName</Value>
</Value>
<Value name="3">
<Value>StudyInstanceUID</Value>
</Value>
<Value name="4">
<Value>SeriesInstanceUID</Value>
</Value>
<Value name="5">
<Value>Session</Value>
</Value>
<Value name="6">
<Value>Filename</Value>
</Value>
<Value name="7">
<Value>RxItemID</Value>
</Value>
</Data>
<DefaultData>MoveReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
