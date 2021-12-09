Include (Ensemble, EnsDICOM)

Class DICOM.Util Extends %RegisteredObject
{

/// 
/// Modified version of EnsLib.DICOM.Util.AssociationContext:CreateAssociation that allows you to create only association types specified in pTypeList
/// This is useful for simulators that fails when too many associations are specified
ClassMethod CreateAssociation(pCallingAET As %String, pCalledAET As %String, pTransferSyntaxes As %List = {$ListBuild($$$IMPLICITVRLETRANSFERSYNTAX)}, pTypeList As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tAC As EnsLib.DICOM.Util.AssociationContext
	#dim tPC As EnsLib.DICOM.Util.PresentationContext
	#dim tUID,tData As %String
	#dim tI As %Integer
	
	Do  {
		
		#; Delete the pre-existing instance
		If ##class(EnsLib.DICOM.Util.AssociationContext).AETExists(pCallingAET,pCalledAET) {
			Set tSC=##class(EnsLib.DICOM.Util.AssociationContext).AETDelete(pCallingAET,pCalledAET) If $$$ISERR(tSC) Quit
		}

	 	#; Create a new association context
		Kill %objlasterror Set tAC=##class(EnsLib.DICOM.Util.AssociationContext).%New(pCallingAET,pCalledAET)
	 	If '$IsObject(tAC) Set tSC=$Get(%objlasterror,$$$EnsError($$$FailedToNewClass,"EnsLib.DICOM.Util.AssociationContext")) Quit

		#; For every SOP in the dictionary
		Set tUID="" For {
			
			Set tUID=$Order(^EnsDICOM.Dictionary("as","u",tUID),1,tData) If tUID="" Quit
			
			#; Only want those SOP classes for GET,FIND,STORAGE and MOVE
			//If (tData["GET")||(tData["FIND")||(tData["Storage")||(tData["MOVE")||(tData["Verification") {
			for i=1:1:$ll(pTypeList) {
				set type = $lg(pTypeList, i)
				If (tData[type) {
					Kill %objlasterror Set tPC=##class(EnsLib.DICOM.Util.PresentationContext).%New(tUID)
					If '$IsObject(tPC) Set tSC=$Get(%objlasterror,$$$EnsError($$$FailedToNewClass,"EnsLib.DICOM.Util.PresentationContext")) Quit
				
					For tI=1:1:$ListLength(pTransferSyntaxes) {
						Set tSC=tPC.TransferSyntaxes.Insert($List(pTransferSyntaxes,tI)) If $$$ISERR(tSC) Quit
					}
				
					Set tSC=tAC.PresentationContexts.Insert(tPC) If $$$ISERR(tSC) Quit
				}
			}
		}

		Set tSC=tAC.%Save() If $$$ISERR(tSC) Quit
 
	} while (0)
	
	Quit tSC
}

}
