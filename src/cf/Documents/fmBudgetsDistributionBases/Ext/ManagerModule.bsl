
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region ProgramInterface

Function DefaultDocumentTime() Export
	
	Return New Structure("Hours, Minutes", 20, 0);
	
EndFunction

#EndRegion

#EndIf
