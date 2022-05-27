Class DICOM.Msg.MoveRsp Extends Ens.Response
{

Property DocumentID As %String;

Property PatientID As %String;

Property StudyInstanceUID As %String(MAXLEN = "");

Property SeriesInstanceUID As %String(MAXLEN = "");

Property MoveOriginatorMessageID As %String(MAXLEN = "");

Storage Default
{
<Data name="MoveRspDefaultData">
<Subscript>"MoveRsp"</Subscript>
<Value name="1">
<Value>DocumentID</Value>
</Value>
<Value name="2">
<Value>PatientID</Value>
</Value>
<Value name="3">
<Value>StudyInstanceUID</Value>
</Value>
<Value name="4">
<Value>SeriesInstanceUID</Value>
</Value>
<Value name="5">
<Value>MoveOriginatorMessageID</Value>
</Value>
</Data>
<DefaultData>MoveRspDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
