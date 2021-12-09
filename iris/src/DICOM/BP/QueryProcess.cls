Class DICOM.BP.QueryProcess Extends EnsLib.DICOM.Process [ ClassType = persistent, ProcedureBlock ]
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
	do {
 		#; If its a document sent from the service
 		If pSourceConfigName'=..OperationDuplexName {
	 		
	 		#; If the operation has not been connected yet
	 		If ..CurrentState="OperationNotConnected" {
		 		#; We are in the process of establishing the connection to the operation,
				#; Keep hold of the incoming document
				Set ..DocumentFromService=pInput
	 			
				Set tSC=..EstablishAssociation(..OperationDuplexName)
				
 			} elseif ..CurrentState="OperationConnected" {
	 			
	 			
	 			#; We can forward the document to the operation
				Set tSC=..SendRequestAsync(..OperationDuplexName,..DocumentFromService,0) 
 			}
 			
 		} elseif pSourceConfigName=..OperationDuplexName {
	 		
	 		#; We have received a document from the operation
			Set tMsgType=pInput.GetValueAt("CommandSet.CommandField",,.tSC)
			If $$$ISERR(tSC) Quit
			
			#; Should only EVER get a C-FIND-RSP
			$$$ASSERT(tMsgType="C-FIND-RSP")
		
			#; TODO: Do Something With the Find Response(s)
			
			
			if pInput.GetValueAt("CommandSet.Status",,.tSC)=0
			{
			Set tSC=..ReleaseAssociation(..OperationDuplexName)	
			quit
			}
			else
			{
				//save the responses as we get them. SessionID is stored with them so we can
				//return all the responses associated with the session executing the C-FIND-RQ
			set QueryRsp = ##class(DICOM.Msg.QueryRsp).%New()
			set QueryRsp.PatientID =pInput.GetValueAt("DataSet.PatientID",,.tSC) if $$$ISERR(tSC) quit
			set QueryRsp.PatientName = pInput.GetValueAt("DataSet.PatientName",,.tSC) if $$$ISERR(tSC) quit		 
			set QueryRsp.StudyInstanceUID = pInput.GetValueAt("DataSet.StudyInstanceUID",,.tsc) if $$$ISERR(tSC) quit
			set QueryRsp.StudyDate =  pInput.GetValueAt("DataSet.StudyDate",,.tSC) if $$$ISERR(tSC) quit
			set QueryRsp.SeriesInstanceUID = pInput.GetValueAt("DataSet.SeriesInstanceUID",,.tSC) if $$$ISERR(tSC) quit
			set QueryRsp.Modality = pInput.GetValueAt("DataSet.Modality",,.tSC) if $$$ISERR(tSC) quit
			set QueryRsp.StudyDescription = pInput.GetValueAt("DataSet.StudyDescription",,.tSC) if $$$ISERR(tSC) quit
			set QueryRsp.NumberOfSeriesRelatedInstances = pInput.GetValueAt("DataSet.NumberOfSeriesRelatedInstances",.tSC) if $$$ISERR(tSC) quit
			set QueryRsp.session=..%SessionId
		    set tSC = QueryRsp.%Save()  if $$$ISERR(tSC) quit
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
<Data name="QueryDefaultData">
<Subscript>"Query"</Subscript>
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
<DefaultData>QueryDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
