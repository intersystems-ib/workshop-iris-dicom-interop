Class DICOM.Messages.SaveReport Extends Ens.Request
{

Property File As %Stream.GlobalBinary;

Property PatientNo As %String;

Property PatientName As %String(MAXLEN = "");

Property StudyDate As %String;

Property StudyTime As %String;

Storage Default
{
<Data name="SaveReportDefaultData">
<Subscript>"SaveReport"</Subscript>
<Value name="1">
<Value>File</Value>
</Value>
<Value name="2">
<Value>PatientNo</Value>
</Value>
<Value name="3">
<Value>PatientName</Value>
</Value>
<Value name="4">
<Value>StudyDate</Value>
</Value>
<Value name="5">
<Value>StudyTime</Value>
</Value>
</Data>
<DefaultData>SaveReportDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
