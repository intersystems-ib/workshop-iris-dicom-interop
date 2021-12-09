Class DICOM.BP.StoreProcess Extends EnsLib.DICOM.Process
{

/// Messages received here are instances of EnsLib.DICOM.Document sent to this
/// process by the service or operation config items. In this demo, the process is ever
/// in one of two states, the Operation is connected or not.
Method OnMessage(pSourceConfigName As %String, pInput As EnsLib.DICOM.Document) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tCounter As %Integer
	#dim tMsgType,tFilerName As %String
	#dim tOutput As EnsLib.DICOM.Document
	do {
		
		#; We should only ever see DICOM Documents here
		$$$ASSERT(pInput.%Extends("EnsLib.DICOM.Document"))
		
 		#; If its a document sent from the service
 		If pSourceConfigName=..ServiceDuplexName {
	 		
	 		If pInput.%Extends("EnsLib.DICOM.Document") {
	 		
				#; Get the CommandField, it contains the type of request and should ALWAYS be present
				Set tMsgType=$$$MsgTyp2Str(pInput.GetValueAt("CommandSet.CommandField",,.tSC))
				If $$$ISERR(tSC) Quit	
				
				#; We should only ever see DICOM store requests here
				$$$ASSERT(tMsgType="C-STORE-RQ")

				#; We need to create a C-STORE-RSP and send to the modality
				Set tSC=..CreateStorageResponse(pInput,.tOutput)
				If $$$ISERR(tSC) Quit
				
				#; We HAVE created an output object
				$$$ASSERT($IsObject(tOutput))
				
				#; Send the reply back to the service ( don't want a response )
				Set tSC=..SendRequestAsync(..ServiceDuplexName,tOutput,0)
				If $$$ISERR(tSC) Quit
				
				#; Stop the private session to ensure each message gets its own session				
				Set tSC=..StopPrivateSession(..ServiceDuplexName)
				If $$$ISERR(tSC) Quit

				#; Save relevant fields to a table so that we can find this message in MoveProcess
				set MoveRsp = ##class(DICOM.Msg.MoveRsp).%New()
				set MoveRsp.MoveOriginatorMessageID = pInput.GetValueAt("CommandSet.MoveOriginatorMessageID",,.tsc) if $$$ISERR(tSC) quit
				set MoveRsp.PatientID = pInput.GetValueAt("DataSet.PatientID",,.tSC) if $$$ISERR(tSC) quit
		 		set MoveRsp.StudyInstanceUID= pInput.GetValueAt("DataSet.StudyInstanceUID",,.tsc) if $$$ISERR(tSC) quit
		 		set MoveRsp.SeriesInstanceUID= pInput.GetValueAt("DataSet.SeriesInstanceUID",,.tsc) if $$$ISERR(tSC) quit
		 		set MoveRsp.DocumentID = pInput.%Id()
		 		set tSC = MoveRsp.%Save()  if $$$ISERR(tSC) quit
			}
		} 
	 		
	} while (0)
	
	Quit tSC
}

/// Create a storage response DICOM message
Method CreateStorageResponse(pDocIn As EnsLib.DICOM.Document, Output pDocOut As EnsLib.DICOM.Document) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tTemp As %String
	try {
		
		#; Create an instance of a DICOM Document to form the response
		Kill %objlasterror Set pDocOut=##class(EnsLib.DICOM.Document).%New()
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
		
		#; Finally set a success status
		Set tSC=pDocOut.SetValueAt(0,"CommandSet.Status") If $$$ISERR(tSC) Quit
		If $$$ISERR(tSC) Quit
		
	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	#dim tIndex,tSetting,tOneName As %String
	#dim tI As %Integer
	Do pItem.PopulateModifiedSettings()
	Set tIndex="" For {
		Set tSetting = pItem.ModifiedSettings.GetNext(.tIndex) Quit:tIndex=""
		If tSetting.Name="FilerConfigNames" {
			
			For tI=1:1:$Length(tSetting.Value,",") {
				Set tOneName=$Piece(tSetting.Value,",",tI)
				If tOneName'="" Set pArray(tOneName)=""
			}
		}
	}
	Quit
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
