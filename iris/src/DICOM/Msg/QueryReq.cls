Include EnsDICOM

Class DICOM.Msg.QueryReq Extends Ens.Request
{

Property PatientID As %String;

Property PatientName As %String;

Property StudyInstanceUID As %String;

Property StudyDate As %String;

Property StudyDescription As %String;

Property Modality As %String;

Property SeriesInstanceUID As %String;

Property SeriesNumber As %String;

Property SeriesDescription As %String;

Property NumberOfSeriesRelatedInstances As %String;

/// Create Find Request
Method CreateFindRequest(pDocOut As EnsLib.DICOM.Document) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tTemp,tAffectedSOPClassUID As %String
	try {
		kill %objlasterror 
		set pDocOut=##class(EnsLib.DICOM.Document).%New()
		if '$IsObject(pDocOut) set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.DICOM.Document")) quit
		
		// StudyRootQuery - FIND
		;set tAffectedSOPClassUID="1.2.840.10008.5.1.4.1.2.2.1"
		// PatientRootQuery - FIND
		set tAffectedSOPClassUID="1.2.840.10008.5.1.4.1.2.1.1"
		
		$$$THROWONERROR(tSC, pDocOut.SetValueAt(tAffectedSOPClassUID,"CommandSet.AffectedSOPClassUID"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt($$$Str2MsgTyp("C-FIND-RQ"),"CommandSet.CommandField"))
		
		;$$$THROWONERROR(tSC, pDocOut.SetValueAt("SERIES","DataSet.QueryRetrieveLevel"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt("STUDY","DataSet.QueryRetrieveLevel"))
		
		$$$THROWONERROR(tSC, pDocOut.SetValueAt(..PatientID, "DataSet.PatientID"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt(..PatientName, "DataSet.PatientName"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt(..StudyDate, "DataSet.StudyDate"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt(..StudyInstanceUID, "DataSet.StudyInstanceUID"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt("", "DataSet.Modality"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt("", "DataSet.SeriesNumber"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt("", "DataSet.SeriesInstanceUID"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt("", "DataSet.NumberOfSeriesRelatedInstances"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt("", "DataSet.SeriesDescription"))
		$$$THROWONERROR(tSC, pDocOut.SetValueAt("", "DataSet.StudyDescription"))

	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

Storage Default
{
<Data name="QueryReqDefaultData">
<Subscript>"QueryReq"</Subscript>
<Value name="1">
<Value>PatientID</Value>
</Value>
<Value name="2">
<Value>PatientName</Value>
</Value>
<Value name="3">
<Value>StudyInstanceUID</Value>
</Value>
<Value name="4">
<Value>StudyDate</Value>
</Value>
<Value name="5">
<Value>StudyDescription</Value>
</Value>
<Value name="6">
<Value>Modality</Value>
</Value>
<Value name="7">
<Value>SeriesInstanceUID</Value>
</Value>
<Value name="8">
<Value>SeriesNumber</Value>
</Value>
<Value name="9">
<Value>SeriesDescription</Value>
</Value>
<Value name="10">
<Value>NumberOfSeriesRelatedInstances</Value>
</Value>
</Data>
<DefaultData>QueryReqDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
