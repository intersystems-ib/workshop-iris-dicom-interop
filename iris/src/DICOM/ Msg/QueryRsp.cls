Class DICOM.Msg.QueryRsp Extends Ens.Response
{

Property session As %String;

Property PatientID As %String;

Property PatientName As %String;

Property StudyInstanceUID As %String(MAXLEN = "");

Property StudyDate As %String;

Property StudyDescription As %String(MAXLEN = "");

Property Modality As %String;

Property SeriesInstanceUID As %String(MAXLEN = "");

Property SeriesNumber As %String;

Property SeriesDescription As %String(MAXLEN = "");

Property NumberOfSeriesRelatedInstances As %String;

Storage Default
{
<Data name="QueryRspDefaultData">
<Subscript>"QueryRsp"</Subscript>
<Value name="1">
<Value>session</Value>
</Value>
<Value name="2">
<Value>PatientID</Value>
</Value>
<Value name="3">
<Value>PatientName</Value>
</Value>
<Value name="4">
<Value>StudyInstanceUID</Value>
</Value>
<Value name="5">
<Value>StudyDate</Value>
</Value>
<Value name="6">
<Value>StudyDescription</Value>
</Value>
<Value name="7">
<Value>Modality</Value>
</Value>
<Value name="8">
<Value>SeriesInstanceUID</Value>
</Value>
<Value name="9">
<Value>SeriesNumber</Value>
</Value>
<Value name="10">
<Value>SeriesDescription</Value>
</Value>
<Value name="11">
<Value>NumberOfSeriesRelatedInstances</Value>
</Value>
</Data>
<DefaultData>QueryRspDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
