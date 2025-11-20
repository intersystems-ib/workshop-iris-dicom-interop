Include EnsDICOM

/// Example of REST service that receives DICOM files as MIME attachments
Class DICOM.BS.RESTService Extends (Ens.BusinessService, %CSP.REST)
{

XData UrlMap
{
<Routes>
    <Route Url="/studies" Method="POST" Call="NewStudy"/>
</Routes>
}

ClassMethod NewStudy() As %Status
{
    set ret = $$$OK

    try {
        // instatiate Business Service
        $$$ThrowOnError(##class(Ens.Director).CreateBusinessService("DICOM REST Service", .service))
        
        // instantiate message to send to Business Process
        // this message will contain the list of DICOM documents created from the received DICOM files
        set msg = ##class(DICOM.Msg.StowRsReq).%New()

        // for each mime data
        set mimeName = %request.NextMimeData("")
        while (mimeName'="") {
            // retrieve mime data
            set mimeData = %request.GetMimeData(mimeName)

            // get some attributes
            set contentType = mimeData.Attributes("ContentType")

            // handle mime data
            if (contentType = "application/dicom") {
                // create DICOM document from mime data
                set sc = ##class(EnsLib.DICOM.Document).CreateFromDicomFileStream(mimeData, .dicom)
                $$$ThrowOnError(sc)

                // set dicom as a C-STORE request
                do dicom.SetValueAt($$$Str2MsgTyp("C-STORE-RQ"),"CommandSet.CommandField")
                do dicom.%Save()

                // add to message that will be sent later to Business Process
                do msg.DICOMDocumentIdList.Insert(dicom.%Id())
            }

            // next mime data
            set mimeName = %request.NextMimeData(mimeName)            
        }

        // send message to Business Process for processing
        $$$ThrowOnError(service.OnProcessInput(msg))

        // respond with 202 Accepted as DICOM files are being processed asynchronously
        set %response.Status = ..#HTTP202ACCEPTED 

    } catch ex {
        // error handling
        set %response.Status = ..#HTTP500INTERNALSERVERERROR
        set ret = ex.AsStatus()
        $$$LOGERROR(ex.DisplayString())
    }
    quit ret
}

/// Override this method to process incoming data. Do not call SendRequestSync/Async() from outside this method (e.g. in a SOAP Service or a CSP page).
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	set ret = $$$OK
    try {
        $$$ThrowOnError(..SendRequestAsync("DICOM StowRs Handler", pInput))

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

}
