Include EnsDICOM

Class DICOM.BS.QueryService Extends Ens.BusinessService [ ProcedureBlock ]
{

Method OnProcessInput(pInput As DICOM.Msg.QueryReq, Output pOutput As Ens.StringContainer) As %Status
{
    set tSC = pInput.CreateFindRequest(.pDocOut)
    If $$$ISERR(tSC) Quit
    
    set tSC = ..SendRequestSync("DICOM Query Process",pDocOut)
	If $$$ISERR(tSC) Quit
	
    set pOutput = ##class(Ens.StringContainer).%New()
    set pOutput.StringValue =..%SessionId
	
	Quit tSC
}

/// do ##class(DICOM.BS.QueryService).TestFind()
ClassMethod TestFind() As %Status
{
	set tSC = ##class(Ens.Director).CreateBusinessService("QueryService",.tService)
	if $$$ISERR(tSC) quit tSC
	set pInput = ##class(DICOM.Msg.QueryReq).%New()
	set pInput.PatientID = "SC-I1"
	do tService.OnProcessInput(pInput,.test)
	
	quit tSC
}

}
