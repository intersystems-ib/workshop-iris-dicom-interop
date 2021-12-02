Include EnsDICOM

Class DICOM.BS.MoveService Extends Ens.BusinessService [ ProcedureBlock ]
{

Method OnProcessInput(pInput As DICOM.Msg.MoveReq, pOutput As %RegisteredObject) As %Status
{
    set tSC = ..CreateMoveReq(pInput,.pDocOut)
    If $$$ISERR(tSC) Quit
    
	set tSC = ..SendRequestSync("DICOM Move Process",pDocOut)
	If $$$ISERR(tSC) Quit
	
	Quit tSC
}

Method CreateMoveReq(pInput As DICOM.Msg.MoveReq, pDocOut As EnsLib.DICOM.Document) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim tTemp,tAffectedSOPClassUID As %String
	try {
		// Create an instance of a DICOM Document to form the response
		Kill %objlasterror Set pDocOut=##class(EnsLib.DICOM.Document).%New()
		If '$IsObject(pDocOut) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.DICOM.Document")) Quit
		
		// Command Set
		set tSC=pDocOut.SetValueAt($$$Str2MsgTyp("C-MOVE-RQ"),"CommandSet.CommandField") if $$$ISERR(tSC) quit 
		set tSC=pDocOut.SetValueAt("1.2.840.10008.5.1.4.1.2.2.2","CommandSet.AffectedSOPClassUID") if $$$ISERR(tSC) quit 
		set tSC=pDocOut.SetValueAt("1","CommandSet.MessageID") if $$$ISERR(tSC) quit 
		set tSC=pDocOut.SetValueAt("IRIS_STORE_SCP","CommandSet.MoveDestination") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt("0","CommandSet.Priority") if $$$ISERR(tSC) quit
		// Data Set
		set tSC=pDocOut.SetValueAt("STUDY","DataSet.QueryRetrieveLevel") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt(pInput.StudyInstanceUID,"DataSet.StudyInstanceUID") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt(pInput.PatientName,"DataSet.PatientName") if $$$ISERR(tSC) quit
		set tSC=pDocOut.SetValueAt(pInput.PatientID,"DataSet.PatientID") if $$$ISERR(tSC) quit
	}
	catch {
		Set tSC=$$$EnsSystemError
	}
	quit tSC
}

/// do ##class(DICOM.BS.MoveService).TestMove()
ClassMethod TestMove() As %Status
{
	set tSC = ##class(Ens.Director).CreateBusinessService("MoveService",.tService)
	if $$$ISERR(tSC) quit tSC
	set pInput = ##class(DICOM.Msg.MoveReq).%New()
	set pInput.StudyInstanceUID = "100.118.116.2005.2.1.1132055943.796.3"
	set pInput.PatientID = "SC-I1"
	set pInput.PatientName =""
	do tService.OnProcessInput(pInput,.test)
	
	quit tSC
}

}
