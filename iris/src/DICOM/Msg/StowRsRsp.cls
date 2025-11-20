/// Response message class for STOW-RS response that contains the list of DICOM document Ids
Class DICOM.Msg.StowRsRsp Extends Ens.Response
{

/// Array of DICOM Document Ids and results for each DICOM document processed
Property DICOMDocumentIdResult As array Of %String;

Storage Default
{
<Data name="DICOMDocumentIdResult">
<Attribute>DICOMDocumentIdResult</Attribute>
<Structure>subnode</Structure>
<Subscript>"DICOM.Msg.StowRsReq.DICOMDocumentIdResult"</Subscript>
</Data>
<Data name="StowRsReqDefaultData">
<Subscript>"StowRsReq"</Subscript>
<Value name="1">
<Value>SessionId</Value>
</Value>
<Value name="2">
<Value>DICOMDocumentIdList</Value>
</Value>
</Data>
<DefaultData>StowRsReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
