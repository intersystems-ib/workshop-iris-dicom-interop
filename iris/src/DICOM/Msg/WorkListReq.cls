Class DICOM.Msg.WorkListReq Extends Ens.Request
{

Property ScheduledDate As %Date;

Property Modality As %String;

Storage Default
{
<Data name="WorkListReqDefaultData">
<Subscript>"WorkListReq"</Subscript>
<Value name="1">
<Value>ScheduledDate</Value>
</Value>
<Value name="2">
<Value>Modality</Value>
</Value>
</Data>
<DefaultData>WorkListReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
