Class DICOM.BP.PDFProcess Extends EnsLib.DICOM.Process
{

/// Messages received here are instances of EnsLib.DICOM.Document sent to this
/// process by the service. The received DICOM file will be sent to the operation for persisting
/// in the file system. If all is well a C-STORE-RSP is sent to the service to indicate to the DICOM
/// peer that the storage was successful. If an error occurs the Association with the DICOM peer will
/// be aborted, indicating that the storage was not successful.
Method OnMessage(pSourceConfigName As %String, pInput As %Library.Persistent) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tMsgType,tMsgId As %String
	#dim tOutput As EnsLib.DICOM.Document
	Try {
		
		#; We should only ever see DICOM Documents here
		$$$ASSERT(pInput.%Extends("EnsLib.DICOM.Document"))
		
		#; We only ever get DICOM Documents from the Service
		$$$ASSERT(pSourceConfigName=..ServiceDuplexName)
		
 		#; Get the CommandField, it contains the type of request, it should ALWAYS be present
		Set tMsgType=$$$MsgTyp2Str(pInput.GetValueAt("CommandSet.CommandField",,.tSC))
		If $$$ISERR(tSC) Quit

		#; We are only handling Storage Requests
		$$$ASSERT(tMsgType="C-STORE-RQ")

		// extract embedded report 
		set tSC = ..getEncapsulatedDocument(pInput, .file)
        $$$ThrowOnError(tSC)
		
        // build request containing metadata & embedded report
        set report = ##class(DICOM.Msg.SaveReport).%New()
		set report.File = file
		set report.PatientName = pInput.GetValueAt("DataSet.PatientName")
		set report.PatientNo = pInput.GetValueAt("DataSet.PatientID")
		set report.StudyDate = pInput.GetValueAt("DataSet.StudyDate")
		set report.StudyTime = pInput.GetValueAt("DataSet.StudyTime")
		
        // send request to save report to a Business Operation
        Set tSC = ..SendRequestAsync("PDF Save Report", report)
		$$$ThrowOnError(tSC)
		
		#; We need to send a reply to the service in all cases, so create an appropriate response
		Set tSC=..CreateStorageResponse(pInput,.tOutput)
		$$$ThrowOnError(tSC)
		
		#; Send the reply back to the service ( don't want a response )
		Set tSC=..SendRequestAsync(..ServiceDuplexName,tOutput,0)
		$$$ThrowOnError(tSC)
		
		#; Stop the private session to ensure each message gets its own session				
		Set tSC=..StopPrivateSession(..ServiceDuplexName)
		$$$ThrowOnError(tSC)
		
	} catch (e) {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

/// Create a storage response DICOM message
Method CreateStorageResponse(pDocIn As EnsLib.DICOM.Document, Output pDocOut As EnsLib.DICOM.Document) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tTemp As %String
	
	try {
		
		#; Get the current storage location
		Set tStorageLocation=..GetProductionSettingValue("StorageLocation",.tSC)
		If $$$ISERR(tSC) Quit
		#; Create an instance of a DICOM Document to form the response
		Kill %objlasterror Set pDocOut=##class(EnsLib.DICOM.Document).%New(tStorageLocation)
		If '$IsObject(pDocOut) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.DICOM.Document")) Quit
		#; Need to copy over the AffectedSOPClassUID (mandatory field)
		Set tTemp=pDocIn.GetValueAt("CommandSet.AffectedSOPClassUID",,.tSC)
		$$$ASSERT('$$$ISERR(tSC))
		Set tSC=pDocOut.SetValueAt(tTemp,"CommandSet.AffectedSOPClassUID") If $$$ISERR(tSC) Quit
		If $$$ISERR(tSC) Quit
		#; Set the CommandField, this is a Storage Response
		Set tSC=pDocOut.SetValueAt($$$Str2MsgTyp("C-STORE-RSP"),"CommandSet.CommandField")
		If $$$ISERR(tSC) Quit
		#; And indicate the message id being responded to by copying over the originating message id
		Set tTemp=pDocIn.GetValueAt("CommandSet.MessageID",,.tSC)
		$$$ASSERT('$$$ISERR(tSC))
		Set tSC=pDocOut.SetValueAt(tTemp,"CommandSet.MessageIDBeingRespondedTo") If $$$ISERR(tSC) Quit
		If $$$ISERR(tSC) Quit
		#; Need to copy over the affected SOP instance id
		Set tTemp=pDocIn.GetValueAt("CommandSet.AffectedSOPInstanceUID",,.tSC)
		$$$ASSERT('$$$ISERR(tSC))
		Set tSC=pDocOut.SetValueAt(tTemp,"CommandSet.AffectedSOPInstanceUID") If $$$ISERR(tSC) Quit
		If $$$ISERR(tSC) Quit
		#; Need to copy over the transfer syntax
		Set pDocOut.DataSet.TransferSyntax=pDocIn.DataSet.TransferSyntax
		#; Finally set a success status
		Set tSC=pDocOut.SetValueAt(0,"CommandSet.Status") If $$$ISERR(tSC) Quit
		If $$$ISERR(tSC) Quit
	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

/// This method is called when an error response is received
/// Returning the same error will cause the BusinessProcess to set its status to error and close down
/// Returning $$$OK from this method causes the BusinessProcess to recover from this error
Method OnError(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, pErrorStatus As %Status, pCompletionKey As %String) As %Status
{
	#; Form an abort command
	Set tCommandAbort=##class(EnsLib.DICOM.Command.Abort).%New($$$ABORTSOURCESERVICEPROVIDER,$$$ABORTREASONNOTSPECIFIED)
		
	#; Send it to the service, this tells the peer that the storage was not successful
	Do ..AbortAssociation(..ServiceDuplexName,tCommandAbort)
	
	#; Want to continue offering the service, even if this instance failed
	Quit $$$OK
}

Method getEncapsulatedDocument(pDocument As EnsLib.DICOM.Document, Output pPDFOut As %GlobalBinaryStream) As %Status
{
	set pPDFOut=##class(%GlobalBinaryStream).%New()
	Set temp=##class(%GlobalBinaryStream).%New()
	set EncData = pDocument.GetValueAt("DataSet.EncapsulatedDocument") do temp.CopyFrom(EncData)
	
	set tStart = temp.FindAt(1,"%PDF")
 	set tEnd = temp.FindAt(tStart,"%%EOF")+5
 	set tOffset = tEnd - tStart
 	do temp.MoveTo(tStart)
 	
 	set i=0
 	While i<=tOffset
 	{
		set i=i+32000
		If (i>tOffset) { set line = temp.Read(tOffset,.sc) }
		Else { set line = temp.Read(32000,.sc)}
		if ($LOCATE(line, "%%EOF")>0) set line= $EXTRACT(line,1,$LOCATE(line, "%%EOF")-1+5)
		do pPDFOut.Write(line)
 	}
 	do pPDFOut.Rewind()
 	quit $$$OK
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
