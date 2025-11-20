/// Message class for STOW-RS request that contains the list of DICOM documents
Class DICOM.Msg.StowRsReq Extends Ens.Request
{

/// List of DICOM Document Ids created from the received DICOM files
Property DICOMDocumentIdList As list Of %String;

/// Cleanup associated DICOM documents when message is deleted
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
   
    set id = $$$oidPrimary(oid)     
    set obj = ..%OpenId(id)
    for i=1:1:obj.DICOMDocumentIdList.Size {
        set docId = obj.DICOMDocumentIdList.GetAt(i)
        do ##class(EnsLib.DICOM.Document).%DeleteId(docId)
    }
    quit $$$OK
}

Storage Default
{
<Data name="StowRsReqDefaultData">
<Subscript>"StowRsReq"</Subscript>
<Value name="1">
<Value>DICOMDocumentIdList</Value>
</Value>
</Data>
<DefaultData>StowRsReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
