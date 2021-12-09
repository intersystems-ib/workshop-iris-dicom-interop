Class DICOM.BP.MoveProcess Extends EnsLib.DICOM.Process
{

/// This parameter names the operation used to provide storage
Parameter SETTINGS = "OperationDuplexName";

/// This keeps track of the OriginatingMessageID
Property OriginatingMessageID As %Integer;

/// This is the incoming document from the business Sservice
Property DocumentFromService As EnsLib.DICOM.Document;

/// This keeps track of the current state of the process
Property CurrentState As %String [ InitialExpression = "OperationNotConnected" ];

/// This is the name of the operation providing storage
Property OperationDuplexName;

/// Messages received here are instances of EnsLib.DICOM.Document sent to this
/// process by the service or operation config items. In this demo, the process is ever
/// in one of two states, the Operation is connected or not.
Method OnMessage(pSourceConfigName As %String, pInput As %Library.Persistent) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tMsgType As %String
	#dim tFindRequest As EnsLib.DICOM.Document
	
	#; Do not process any other incoming messages rather than DICOM documents
	if $IsObject(pInput),'pInput.%IsA("EnsLib.DICOM.Document") Quit $$$OK
	
	do {
 		#; If its a document sent from the service
 		If pSourceConfigName'=..OperationDuplexName {
	 		
	 		#; If the operation has not been connected yet
	 		If ..CurrentState="OperationNotConnected" {
		 		#; We are in the process of establishing the connection to the operation,
				#; Keep hold of the incoming document
				set ..DocumentFromService=pInput
				set tSC=..EstablishAssociation(..OperationDuplexName)
 			} elseif ..CurrentState="OperationConnected" {
	 			#; We can forward the document to the operation
	 			do ..DocumentFromService.SetValueAt(..%SessionId,"CommandSet.MessageID")
	 			set tSC=..SendRequestAsync(..OperationDuplexName,..DocumentFromService,0) 
 			}
 		} elseif pSourceConfigName=..OperationDuplexName {
	 		#; We have received a document from the operation
			Set tMsgType=pInput.GetValueAt("CommandSet.CommandField",,.tSC)
			If $$$ISERR(tSC) Quit
			
			#; Should only EVER get a C-MOVE-RSP
			$$$ASSERT(tMsgType="C-MOVE-RSP")
		
			#; If Status = 0 we are done
			if pInput.GetValueAt("CommandSet.Status",,.tSC)=0 {
				set tSC=..ReleaseAssociation(..OperationDuplexName)
				

                /// TODO: AFT! 
                quit
                /*
				#; C-MOVE completed, process stored files
				set tDocReceivedMsg = ##class(epat.Msg.DocReceivedReq).%New()
				set tDocReceivedMsg.MessageId = ..%SessionId
				do tDocReceivedMsg.%Save()
				do ..SendRequestAsync("DocReceivedProcess",tDocReceivedMsg)
				quit
                */
			}
 		}
	} while (0)
	
	Quit tSC
}

/// This method is called by the framework on successful establishment of an association
Method OnAssociationEstablished(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Established) As %Status
{
	#dim tSC As %Status = $$$OK
	
	If pSourceConfigName=..OperationDuplexName {
		
		#; The association with the operation has been completed, operation is now connected
		Set ..CurrentState="OperationConnected"
		Set tSC=..OnMessage(..ServiceDuplexName,"")
		
	} else {
		
		#; Need to establish an associaton with the operation (we will be called back here at 
		#; OnAssociationEstablished()
		Set tSC=..EstablishAssociation(..OperationDuplexName)
	}
	
	Quit tSC
}

Method OnAssociationReleased(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Released) As %Status
{
	#dim tSC As %Status = $$$OK
		
		#; The association between this process and the operation has been released, so we are now
		#; not connected to the operation
		Set ..CurrentState="OperationNotConnected"
	
	Quit tSC
}

/// This callback is called by the framework when an Association is rejected
Method OnAssociationRejected(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Rejected) As %Status [ Final ]
{
 
	
	Quit $$$ERROR($$$EnsDICOMPeerRejectedAssociation)
}

/// This callback is called by the framework when an association encounters an error
Method OnAssociationErrored(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Errored) As %Status [ Final ]
{
	
	
	Quit pInput.Status
}

/// This callback is called by the framework when an association is aborted
Method OnAssociationAborted(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Aborted) As %Status [ Final ]
{

	Quit $$$ERROR($$$EnsDICOMPeerRequestedAbort)
}

/// This method is called when any error occurs. Returning the same error will cause the BusinessProcess to set its
/// status to error and close down
Method OnError(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, pErrorStatus As %Status, pCompletionKey As %String) As %Status
{

	
	#; If we are in conversation with the operation, we neet to tell the operation to ABORT its association
	If ..CurrentState="OperationConnected" {
		
		#; Form an abort message
		Set tCommandAbort=##class(EnsLib.DICOM.Command.Abort).%New($$$ABORTSOURCESERVICEUSER,$$$ABORTREASONNOTSPECIFIED)
		
		#; Send it to the operation
		Do ..AbortAssociation(..OperationDuplexName,tCommandAbort)
	}
	Quit pErrorStatus
}

Storage Default
{
<Data name="MoveProcessDefaultData">
<Subscript>"MoveProcess"</Subscript>
<Value name="1">
<Value>OriginatingMessageID</Value>
</Value>
<Value name="2">
<Value>DocumentFromService</Value>
</Value>
<Value name="3">
<Value>CurrentState</Value>
</Value>
<Value name="4">
<Value>OperationDuplexName</Value>
</Value>
</Data>
<DefaultData>MoveProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
