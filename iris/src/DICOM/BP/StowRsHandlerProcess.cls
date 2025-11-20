/// DICOM BP to handle STOW-RS requests
/// This Business Process receives DICOM documents from the REST Service Business Service
/// process each document by sending it to a DICOM Operation that provides storage (C-STORE)
Class DICOM.BP.StowRsHandlerProcess Extends EnsLib.DICOM.Process
{

/// This parameter names the operation used to provide storage
Parameter SETTINGS = "OperationDuplexName";

/// This is the name of the DICOM TCP Business Operation that will handle C-STORE requests
Property OperationDuplexName;

/// Current state of the association with the duplex operation
Property CurrentState As %String [ InitialExpression = "NotConnected" ];

/// Current DICOM document being processed
Property CurrentDocument As EnsLib.DICOM.Document;

/// Initial request message containing the list of DICOM documents to be stored
Property StowRsReq As DICOM.Msg.StowRsReq;

/// Response message to be sent back when all documents have been processed
Property StowRsRsp As DICOM.Msg.StowRsRsp;

/// Key of the current document being processed from the StowRsReq message
Property CurrentDocumentKey As %String;

/// Messages received here are primarily instances of EnsLib.DICOM.Document sent to this
/// process by the RouterDispatcher Process or RouterFiler config items.
Method OnMessage(pSourceConfigName As %String, pInput As %Library.Persistent) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tMsgType As %String
	#dim tStoreStatus As %Integer
	do {
		// ----
		// StowRsReq message received
		if pInput.%Extends("DICOM.Msg.StowRsReq") {

			if pInput.DICOMDocumentIdList.Size < 1 {
				$$$ThrowStatus($$$ERROR($$$GeneralError, "No DICOM documents to process"))
			}

			// save initial StowRsReq request and instantiate response
			set ..StowRsReq = pInput
			set ..StowRsRsp = ##class(DICOM.Msg.StowRsRsp).%New()
			
			// initilize processing of first document
			set ..CurrentDocumentKey=""
			do ..ProcessNextDocument()
		}

		// ---
		// DICOM document received
		elseIf (pInput.%Extends("EnsLib.DICOM.Document")) {

			// DICOM received is NOT coming from duplex operation
			if (pSourceConfigName'=..OperationDuplexName) {
				
				// Operation not connected, need to establish DICOM association first
				If ..CurrentState="NotConnected" {
					// save current DICOM document
					Set ..CurrentDocument=pInput
					// establish association, OnAssociationEstablished will be called when done
					Set tSC = ..EstablishAssociation(..OperationDuplexName)
				
				// Operation connected, forward the document to the operation
				}  elseif ..CurrentState="OperationConnected" {
		 			// get the CommandField from DICOM document
					Set tMsgType=$$$MsgTyp2Str(pInput.GetValueAt("CommandSet.CommandField",,.tSC))
					If $$$ISERR(tSC) Quit
		
					// check that we have a C-STORE request
					$$$ASSERT(tMsgType="C-STORE-RQ")
		
		 			// forward the document to the duplex operation
					Set tSC = ..SendRequestAsync(..OperationDuplexName, pInput, 0)
	 			}
			} 
			// DICOM received coming from duplex operation
			else {
				// extract CommandField
				Set tMsgType=$$$MsgTyp2Str(pInput.GetValueAt("CommandSet.CommandField",,.tSC))
				If $$$ISERR(tSC) Quit
			
				// check that we have a C-STORE response
				$$$ASSERT(tMsgType="C-STORE-RSP")
				
				// get the status of the C-STORE response
				Set tStoreStatus=pInput.GetValueAt("CommandSet.Status",,.tSC)
				If $$$ISERR(tSC) Quit
				
				// if C-STORE response status is OK
				If tStoreStatus=0 {
					// mark current document as successfully stored
					do ..StowRsRsp.DICOMDocumentIdResult.SetAt("OK", ..CurrentDocumentKey)
					// process next DICOM document
					do ..ProcessNextDocument()
				}
			}
		} else {
			$$$ASSERT(0)
		}
	} while (0)
	
	Quit tSC
}

// Process the next DICOM document in the StowRsReq message

Method ProcessNextDocument() As %Status
{
	set ret = $$$OK
	try {
			// get next DICOM document from StowRsReq
			set key = ..CurrentDocumentKey
			set dicomDocId = ..StowRsReq.DICOMDocumentIdList.GetNext(.key)
			set ..CurrentDocumentKey = key
			set ..CurrentDocument = ##class(EnsLib.DICOM.Document).%OpenId(dicomDocId)

			$$$TRACE("CurrentDocumentKey="_..CurrentDocumentKey)

			// if we have a document to process
			if ..CurrentDocumentKey'="" {
				// initialize response
				do ..StowRsRsp.DICOMDocumentIdResult.SetAt("", ..CurrentDocumentKey)
				// process document
				$$$ThrowOnError(..OnMessage(..ServiceDuplexName, ..CurrentDocument))
			} 
			// no more documents to process
			else {
				// release association with operation
				$$$ThrowOnError(..ReleaseAssociation(..OperationDuplexName))
				// reply with StowRsRsp (if needed)
				$$$ThrowOnError(..Reply(..StowRsRsp))
			}
	} catch ex {
		set ret = ex.AsStatus()
		$$$LOGERROR(ex.DisplayString())
	}
	quit ret
}

/// This method is called when any error occurs. Returning the same error will cause the BusinessProcess to set its
/// status to error and close down
Method OnError(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, pErrorStatus As %Status, pCompletionKey As %String) As %Status
{
    // If we are in conversation with the operation, we neet to tell the operation to ABORT its association
    If ..CurrentState="OperationConnected" {
        // Form an abort message
        Set tCommandAbort=##class(EnsLib.DICOM.Command.Abort).%New($$$ABORTSOURCESERVICEUSER,$$$ABORTREASONNOTSPECIFIED)
        // Send it to the operation
        Do ..AbortAssociation(..OperationDuplexName,tCommandAbort)
    }

	$$$LOGERROR("OnError!")

    Quit pErrorStatus
}

/// This callback is called by the framework when an assocation encounters an error
Method OnAssociationErrored(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Errored) As %Status
{
	// Don't ignore the error, this will cause the BP to terminate
	Quit pInput.Status
}

/// This callback is called by the framework when an Association is rejected
Method OnAssociationRejected(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Rejected) As %Status
{
	Set ..CurrentState="NotConnected"
	Quit $$$ERROR($$$EnsDICOMPeerRejectedAssociation)
}

/// This call back is called by the framework when an Association is established
Method OnAssociationEstablished(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Established) As %Status
{
	#dim tSC As %Status = $$$OK
	If pSourceConfigName=..OperationDuplexName {
		
		// The association with the operation has been completed, operation is now connected
		Set ..CurrentState="OperationConnected"
	
		// Call the OnMessage() with the saved document ( if we have it )
		if ($IsObject(..CurrentDocument)) {
			Set tSC=..OnMessage(..ServiceDuplexName,..CurrentDocument)
		}	
	} 
	Quit tSC
}

/// This callback is called by the framework when an association is aborted
Method OnAssociationAborted(pSourceConfigName As %String, pInput As EnsLib.DICOM.Notify.Aborted) As %Status
{
	Set ..CurrentState="NotConnected"
	Quit $$$ERROR($$$EnsDICOMPeerRequestedAbort)
}

/// This callback permits the transfer syntax to be overriden
Method OnDetermineTransferSyntax(Output pTransferSyntax) As %Status
{
	$$$ASSERT($IsObject(..CurrentDocument))
	Set pTransferSyntax=..CurrentDocument.DataSet.TransferSyntax
	Quit $$$OK
}

Storage Default
{
<Data name="STOWRSProcessDefaultData">
<Subscript>"STOWRSProcess"</Subscript>
<Value name="1">
<Value>OperationDuplexName</Value>
</Value>
<Value name="2">
<Value>CurrentState</Value>
</Value>
<Value name="3">
<Value>CurrentDocument</Value>
</Value>
<Value name="4">
<Value>StowRsReq</Value>
</Value>
<Value name="5">
<Value>CurrentDocumentIndex</Value>
</Value>
<Value name="6">
<Value>CurrentDocumentKey</Value>
</Value>
<Value name="7">
<Value>StowRsRsp</Value>
</Value>
</Data>
<DefaultData>STOWRSProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
